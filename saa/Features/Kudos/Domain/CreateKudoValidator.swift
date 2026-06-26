import Foundation

// MARK: - CreateKudoDraft

/// Mutable input bag consumed by `CreateKudoValidator.validate(_:)`.
///
/// Separate from `CreateKudoRequest` because the draft may be incomplete
/// (mid-form state). Validated before constructing an immutable `CreateKudoRequest`.
struct CreateKudoDraft: Sendable {

    /// Selected recipient user ID; `nil` when no recipient has been chosen.
    var recipientId: UUID?

    /// Authenticated sender user ID; injected by the VM before calling validate.
    var senderId: UUID?

    /// Raw title text as typed by the user (pre-trim).
    var title: String

    /// Raw message text as typed by the user (pre-trim).
    var message: String

    /// IDs of selected hashtags in selection order (may contain duplicates from UI).
    var hashtagIds: [HashtagID]

    /// Image drafts attached by the user, pre-upload.
    var imageDrafts: [KudosImageDraft]

    /// Whether the sender wants to hide their identity.
    var isAnonymous: Bool

    /// Raw anonymous nickname as typed by the user (pre-trim); `nil` when not set.
    var anonymousNickname: String?

    init(
        recipientId: UUID? = nil,
        senderId: UUID? = nil,
        title: String = "",
        message: String = "",
        hashtagIds: [HashtagID] = [],
        imageDrafts: [KudosImageDraft] = [],
        isAnonymous: Bool = false,
        anonymousNickname: String? = nil
    ) {
        self.recipientId = recipientId
        self.senderId = senderId
        self.title = title
        self.message = message
        self.hashtagIds = hashtagIds
        self.imageDrafts = imageDrafts
        self.isAnonymous = isAnonymous
        self.anonymousNickname = anonymousNickname
    }
}

// MARK: - CreateKudoValidator

/// Pure-functional validator for the create-kudo form.
///
/// Returns every field error found in one pass — the UI highlights ALL broken
/// fields simultaneously rather than stopping at the first failure.
///
/// Rules (from phase-05 validation table):
/// | Field              | Rule                                          | Error                   |
/// |--------------------|-----------------------------------------------|-------------------------|
/// | recipient          | required                                      | recipientRequired       |
/// | recipient          | must differ from sender                       | cannotSendToSelf        |
/// | title              | required (1+ chars trimmed)                   | titleRequired           |
/// | title              | ≤ 100 chars trimmed                           | titleTooLong            |
/// | message            | required (1+ chars trimmed)                   | messageRequired         |
/// | message            | not whitespace-only                           | messageWhitespaceOnly   |
/// | message            | ≤ 1 000 chars trimmed                         | messageTooLong          |
/// | hashtags           | ≥ 1 unique ID                                 | hashtagsRequired        |
/// | hashtags           | ≤ 5 unique IDs                                | hashtagsTooMany         |
/// | imageDrafts        | ≤ 5 total                                     | imagesTooMany           |
/// | imageDrafts        | each ≤ 5 242 880 bytes (5 MB)                 | imageTooLarge           |
/// | imageDrafts        | each "image/jpeg" or "image/png"              | unsupportedImageType    |
/// | anonymousNickname  | required + ≥ 1 char (trimmed) when anonymous  | nicknameRequired        |
/// | anonymousNickname  | ≤ 30 chars trimmed when anonymous             | nicknameTooLong         |
///
/// No I/O is performed. Safe to call on any thread.
enum CreateKudoValidator {

    // MARK: - Constants

    static let titleMaxLength = 100
    static let messageMaxLength = 1_000
    static let hashtagsMin = 1
    static let hashtagsMax = 5
    static let imagesMax = 5
    static let imageSizeLimit = 5 * 1024 * 1024   // 5 MB in bytes
    static let nicknameMaxLength = 30
    static let allowedImageTypes: Set<String> = ["image/jpeg", "image/png"]

    // MARK: - Public API

    /// Validates the given draft and returns every field error found.
    ///
    /// An empty array means the draft is valid and ready to be converted into a
    /// `CreateKudoRequest`. Errors are appended in field order (recipient →
    /// title → message → hashtags → images → nickname) so callers can present
    /// them in a predictable sequence.
    ///
    /// - Parameter draft: The mutable form state snapshot to validate.
    /// - Returns: Array of `CreateKudoFieldError` values (empty = valid).
    static func validate(_ draft: CreateKudoDraft) -> [CreateKudoFieldError] {
        var errors: [CreateKudoFieldError] = []

        // MARK: Recipient
        if let recipientId = draft.recipientId {
            if recipientId == draft.senderId {
                errors.append(.cannotSendToSelf)
            }
        } else {
            errors.append(.recipientRequired)
        }

        // MARK: Title
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            errors.append(.titleRequired)
        } else if trimmedTitle.count > titleMaxLength {
            errors.append(.titleTooLong)
        }

        // MARK: Message
        let trimmedMessage = draft.message.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedMessage.isEmpty {
            // Distinguish between truly empty input and whitespace-only input.
            errors.append(draft.message.isEmpty ? .messageRequired : .messageWhitespaceOnly)
        } else if trimmedMessage.count > messageMaxLength {
            errors.append(.messageTooLong)
        }

        // MARK: Hashtags
        let uniqueHashtags = Set(draft.hashtagIds)
        if uniqueHashtags.isEmpty {
            errors.append(.hashtagsRequired)
        } else if uniqueHashtags.count > hashtagsMax {
            errors.append(.hashtagsTooMany)
        }

        // MARK: Images
        let drafts = draft.imageDrafts
        if drafts.count > imagesMax {
            errors.append(.imagesTooMany)
        }
        // Report each violation at most once across the batch.
        if drafts.contains(where: { $0.byteSize > imageSizeLimit }) {
            errors.append(.imageTooLarge)
        }
        if drafts.contains(where: { !allowedImageTypes.contains($0.contentType) }) {
            errors.append(.unsupportedImageType)
        }

        // MARK: Anonymous nickname
        if draft.isAnonymous {
            let trimmedNickname = (draft.anonymousNickname ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedNickname.isEmpty {
                errors.append(.nicknameRequired)
            } else if trimmedNickname.count > nicknameMaxLength {
                errors.append(.nicknameTooLong)
            }
        }

        return errors
    }
}
