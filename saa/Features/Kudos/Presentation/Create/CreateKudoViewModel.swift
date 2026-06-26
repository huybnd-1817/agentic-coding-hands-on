import Foundation
import Combine

// MARK: - CancelDecision

/// Result of `CreateKudoViewModel.attemptCancel()`.
enum CancelDecision: Equatable {
    /// Form is clean — caller may dismiss immediately.
    case canDismiss
    /// Form is dirty — caller must show a confirmation dialog before dismissing.
    case confirmFirst
}

// MARK: - SubmissionState

/// Submission lifecycle for the create-kudo form.
enum SubmissionState: Equatable {
    case idle
    case submitting
    case succeeded(Kudos)
    case failed(KudosError)

    static func == (lhs: SubmissionState, rhs: SubmissionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.submitting, .submitting): return true
        case (.succeeded(let a), .succeeded(let b)):     return a == b
        case (.failed(let a), .failed(let b)):           return a == b
        default:                                          return false
        }
    }
}

// MARK: - CreateKudoViewModel

/// `@MainActor` view model for the Create Kudo flow.
///
/// Uses `ObservableObject + @Published` (iOS 16 compatible; same pattern as `KudosViewModel`).
///
/// Owns all form state, validation, image upload orchestration, submit flow,
/// recipient search cache, hashtag picker state, and cancel-with-confirm logic.
///
/// Dependency injection via initializer — no singleton references.
@MainActor
final class CreateKudoViewModel: ObservableObject {

    // MARK: - Form fields

    @Published var recipient: ProfileSummary? = nil
    @Published var title: String = ""
    @Published var message: String = ""
    @Published var selectedHashtags: [Hashtag] = []
    /// VM-internal drafts with upload state. View receives projected `[ImageDraft]` via `images`.
    @Published private(set) var imageDrafts: [ImageDraftVM] = []
    @Published var isAnonymous: Bool = false
    @Published var anonymousNickname: String = ""

    // MARK: - Recipient search

    @Published var recipientQuery: String = ""
    @Published private(set) var allRecipients: [ProfileSummary] = []
    @Published private(set) var isRecipientsLoading: Bool = false

    // MARK: - Hashtag picker

    @Published private(set) var availableHashtags: [Hashtag] = []
    @Published var isHashtagPickerOpen: Bool = false
    @Published private(set) var isHashtagsLoading: Bool = false

    // MARK: - Submission

    @Published private(set) var submissionState: SubmissionState = .idle

    // MARK: - Toast

    @Published private(set) var toastMessageKey: String? = nil

    // MARK: - Submit attempt tracking

    /// True after the user taps Send while the form has validation errors.
    /// Latched so the inline "required fields" message stays visible until the
    /// errors resolve (or until a successful submission tears the form down).
    @Published private(set) var submitAttempted: Bool = false

    // MARK: - Derived (computed)

    /// Filtered + self-excluded recipient list based on `recipientQuery`.
    var filteredRecipients: [ProfileSummary] {
        let query = recipientQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let selfExcluded = allRecipients.filter { $0.id != currentUserId }
        guard !query.isEmpty else { return selfExcluded }
        return selfExcluded.filter { profile in
            profile.displayName.lowercased().contains(query)
                || (profile.department?.lowercased().contains(query) ?? false)
                || (profile.employeeCode?.lowercased().contains(query) ?? false)
        }
    }

    /// True when hashtag max (5) is already reached.
    var isHashtagAtMax: Bool {
        selectedHashtags.count >= 5
    }

    /// Snapshot of `imageDrafts` projected as lightweight `[ImageDraft]` for the view.
    var images: [ImageDraft] {
        imageDrafts.map { ImageDraft(id: $0.id, localURL: $0.localURL) }
    }

    /// Field validation errors from `CreateKudoValidator`.
    var fieldErrors: [CreateKudoFieldError] {
        CreateKudoValidator.validate(currentDraft)
    }

    /// Field errors mapped to the `FieldError` type consumed by `CreateKudoView`.
    var errors: [FieldError] {
        fieldErrors.map { $0.asFieldError }
    }

    /// Drives the inline red error banner at the bottom of the form card.
    /// Only appears after a failed submit attempt and clears reactively as the
    /// user fills in the missing fields.
    var showRequiredFieldsError: Bool {
        submitAttempted && !fieldErrors.isEmpty
    }

    /// True when no images are uploading and no submission is in flight.
    var canSubmit: Bool {
        let allUploaded = imageDrafts.isEmpty
            || imageDrafts.allSatisfy { $0.uploadState.isUploaded }
        return allUploaded && submissionState != .submitting
    }

    var isSubmitting: Bool {
        submissionState == .submitting
    }

    /// True when any field differs from the initial empty state.
    var isDirty: Bool {
        currentSnapshot != .empty
    }

    // MARK: - Private snapshot

    private var currentSnapshot: CreateKudoFormState {
        CreateKudoFormState(
            recipientId: recipient?.id,
            title: title,
            message: message,
            selectedHashtagIds: selectedHashtags.map(\.id),
            imageDraftIds: imageDrafts.map(\.id),
            isAnonymous: isAnonymous,
            anonymousNickname: anonymousNickname
        )
    }

    // MARK: - Private state

    /// In-flight upload tasks keyed by draft ID — cancelled on remove.
    // `internal` access so tests can inspect via `@testable import`; not part of public API.
    private var uploadTasks: [UUID: Task<Void, Never>] = [:]
    private var toastDismissTask: Task<Void, Never>? = nil

    // MARK: - Dependencies

    private let repo: KudosRepositoryProtocol
    private let uploader: KudosImageUploaderProtocol
    private let currentUserId: UUID
    private let onKudosCreated: (Kudos) -> Void

    // MARK: - Init

    init(
        repo: KudosRepositoryProtocol,
        uploader: KudosImageUploaderProtocol,
        currentUserId: UUID,
        onKudosCreated: @escaping (Kudos) -> Void
    ) {
        self.repo = repo
        self.uploader = uploader
        self.currentUserId = currentUserId
        self.onKudosCreated = onKudosCreated
    }

    // MARK: - Lifecycle

    /// Call once when the form appears. Fetches recipients + hashtags in parallel.
    func onAppear() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadRecipients() }
            group.addTask { await self.loadHashtags() }
        }
    }

    // MARK: - Field setters

    func selectRecipient(_ profile: ProfileSummary) {
        recipient = profile
        recipientQuery = ""
    }

    func clearRecipient() {
        recipient = nil
    }

    func setTitle(_ value: String) {
        title = value
    }

    func setMessage(_ value: String) {
        message = value
    }

    /// Inserts a markdown marker into the message.
    ///
    /// iOS `TextEditor` does not expose selection range via SwiftUI, so the
    /// simplest correct approach is used:
    /// - Wrapping markers (bold, italic, strikethrough, link): insert placeholder
    ///   at the end of the current message so the user can see the syntax and type inside it.
    /// - Line-prefix markers (orderedList, quote): prefix a new line at the end.
    func applyMarkdown(_ marker: MarkdownMarker) {
        switch marker {
        case .bold:
            message += "**bold text**"
        case .italic:
            message += "_italic text_"
        case .strikethrough:
            message += "~~strikethrough~~"
        case .link:
            message += "[link text](url)"
        case .orderedList:
            let prefix = message.isEmpty ? "" : "\n"
            message += "\(prefix)1. "
        case .quote:
            let prefix = message.isEmpty ? "" : "\n"
            message += "\(prefix)> "
        }
    }

    func toggleHashtag(_ hashtag: Hashtag) {
        if let idx = selectedHashtags.firstIndex(where: { $0.id == hashtag.id }) {
            selectedHashtags.remove(at: idx)
        } else if selectedHashtags.count < 5 {
            selectedHashtags.append(hashtag)
        }
    }

    func removeHashtag(_ hashtag: Hashtag) {
        selectedHashtags.removeAll { $0.id == hashtag.id }
    }

    func openHashtagPicker() {
        isHashtagPickerOpen = true
    }

    func dismissHashtagPicker() {
        isHashtagPickerOpen = false
    }

    func toggleAnonymous() {
        isAnonymous.toggle()
        if !isAnonymous { anonymousNickname = "" }
    }

    func setNickname(_ value: String) {
        anonymousNickname = value
    }

    // MARK: - Image upload orchestration

    /// Adds a new image draft and immediately starts the upload task.
    func addImage(localURL: URL, domain: KudosImageDraft) {
        guard imageDrafts.count < 5 else { return }

        var draft = ImageDraftVM(id: domain.id, localURL: localURL, domain: domain)
        draft.uploadState = .uploading
        imageDrafts.append(draft)

        let task = Task<Void, Never> { [weak self] in
            guard let self else { return }
            await self.performUpload(draftId: domain.id)
        }
        uploadTasks[domain.id] = task
    }

    /// Removes an image draft and cancels its in-flight upload if any.
    func removeImage(_ id: UUID) {
        uploadTasks[id]?.cancel()
        uploadTasks.removeValue(forKey: id)
        imageDrafts.removeAll { $0.id == id }
    }

    // MARK: - Submit flow

    func submit() async {
        // Validate first — computed `fieldErrors` reflects current state.
        // Latch `submitAttempted` so the inline required-fields banner appears
        // (Figma node 6885:10124) until the user clears the validation errors.
        guard fieldErrors.isEmpty, let recipient else {
            if !fieldErrors.isEmpty {
                submitAttempted = true
            }
            return
        }
        // Form is valid but uploads are still in flight. Surface a toast so
        // the user knows why Send appears unresponsive instead of silently
        // returning.
        guard canSubmit else {
            let imagesPending = imageDrafts.contains { !$0.uploadState.isUploaded }
            if imagesPending {
                emitToast("kudos.create.toast.error.imagesUploading")
            }
            return
        }

        submissionState = .submitting

        // Build attachment list from successfully uploaded drafts only,
        // preserving the draft order as the attachment sort order.
        let attachments: [KudosAttachment] = imageDrafts
            .enumerated()
            .compactMap { idx, draft in
                guard let path = draft.uploadState.storagePath else { return nil }
                return KudosAttachment(
                    storagePath: path,
                    contentType: draft.domain.contentType,
                    byteSize: draft.domain.byteSize,
                    sortOrder: idx
                )
            }

        let request = CreateKudoRequest(
            recipientId: recipient.id,
            senderId: currentUserId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            message: message.trimmingCharacters(in: .whitespacesAndNewlines),
            hashtagIds: selectedHashtags.map(\.id),
            attachments: attachments,
            isAnonymous: isAnonymous,
            anonymousNickname: isAnonymous
                ? anonymousNickname.trimmingCharacters(in: .whitespacesAndNewlines)
                : nil,
            multiplier: 1
        )

        do {
            let kudos = try await repo.createKudo(request)
            submissionState = .succeeded(kudos)
            emitToast("kudos.create.toast.success")
            onKudosCreated(kudos)
        } catch {
            let kudosError = (error as? KudosError)
                ?? .unknown(underlying: error.localizedDescription)
            emitToast(kudosError.messageKey ?? "kudos.error.unknown")
            submissionState = .idle
        }
    }

    // MARK: - Cancel with confirm

    /// Returns `.canDismiss` when the form is clean, `.confirmFirst` when dirty.
    func attemptCancel() -> CancelDecision {
        isDirty ? .confirmFirst : .canDismiss
    }

    // MARK: - Standards link

    func onTapStandards() {
        // Uses the Create-namespaced key so future copy changes here don't
        // affect the shared "coming soon" toast on the main Kudos tab.
        emitToast("kudos.create.toast.standards.coming")
    }

    // MARK: - Private helpers

    private func loadRecipients() async {
        isRecipientsLoading = true
        defer { isRecipientsLoading = false }
        do {
            // Fetches authenticated profiles from `profiles` table, excludes self.
            allRecipients = try await repo.fetchEligibleRecipients()
        } catch {
            // Non-fatal — recipient list stays empty; user can still type to search.
        }
    }

    private func loadHashtags() async {
        isHashtagsLoading = true
        defer { isHashtagsLoading = false }
        do {
            availableHashtags = try await repo.fetchHashtags()
        } catch {
            // Non-fatal — picker will show an empty list.
        }
    }

    private func performUpload(draftId: UUID) async {
        guard let idx = imageDrafts.firstIndex(where: { $0.id == draftId }) else { return }
        let domain = imageDrafts[idx].domain

        do {
            let attachment = try await uploader.upload(draft: domain)
            // Guard against cancellation (image was removed before upload finished).
            guard !Task.isCancelled,
                  let currentIdx = imageDrafts.firstIndex(where: { $0.id == draftId }) else {
                return
            }
            imageDrafts[currentIdx].uploadState = .uploaded(storagePath: attachment.storagePath)
        } catch {
            guard !Task.isCancelled,
                  let currentIdx = imageDrafts.firstIndex(where: { $0.id == draftId }) else {
                return
            }
            imageDrafts[currentIdx].uploadState = .failed
            let key = (error as? KudosError)?.messageKey ?? "kudos.error.attachmentUploadFailed"
            emitToast(key)
        }
        uploadTasks.removeValue(forKey: draftId)
    }

    /// Emits a toast with 3-second auto-dismiss. Mirrors `KudosViewModel.emitToast(_:)`.
    func emitToast(_ key: String) {
        toastDismissTask?.cancel()
        toastMessageKey = key
        toastDismissTask = Task<Void, Never> { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 3_000_000_000)
            } catch {
                return  // Task was cancelled — do not clear toast set by next caller.
            }
            self?.toastMessageKey = nil
        }
    }

    /// Builds a `CreateKudoDraft` from current field state for validator consumption.
    private var currentDraft: CreateKudoDraft {
        // Pass all drafts to the validator (count, size, type checks);
        // only uploaded ones are included in the request at submit time.
        let allDomainDrafts = imageDrafts.map(\.domain)
        return CreateKudoDraft(
            recipientId: recipient?.id,
            senderId: currentUserId,
            title: title,
            message: message,
            hashtagIds: selectedHashtags.map(\.id),
            imageDrafts: allDomainDrafts,
            isAnonymous: isAnonymous,
            anonymousNickname: isAnonymous ? anonymousNickname : nil
        )
    }
}

// MARK: - CreateKudoFieldError → FieldError bridge

private extension CreateKudoFieldError {
    /// Maps domain field errors to the UI `FieldError` type consumed by `CreateKudoView`.
    /// `localizationKey` carries the catalog key so the view can resolve it via
    /// `LocalizedStringKey` if it ever needs to render the message.
    var asFieldError: FieldError {
        FieldError(field: targetField, localizationKey: localizedKey)
    }

    /// Maps each domain error to the UI form field it should highlight.
    var targetField: FieldError.Field {
        switch self {
        case .recipientRequired, .cannotSendToSelf:
            return .recipient
        case .titleRequired, .titleTooLong:
            return .title
        case .messageRequired, .messageWhitespaceOnly, .messageTooLong:
            return .message
        case .hashtagsRequired, .hashtagsTooMany:
            return .hashtag
        case .imagesTooMany, .imageTooLarge, .unsupportedImageType:
            return .image
        case .nicknameRequired, .nicknameTooLong:
            return .nickname
        }
    }
}
