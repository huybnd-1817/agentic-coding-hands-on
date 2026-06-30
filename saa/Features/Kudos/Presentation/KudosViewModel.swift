import Foundation
import Combine

// MARK: - KudosViewModel

/// State machine for the Sun*Kudos tab (MoMorph screen `fO0Kt19sZZ`).
/// Pure-Domain — Domain → UI struct bridging lives in `KudosViewContainer`.
@MainActor
final class KudosViewModel: ObservableObject {

    // MARK: - Load state

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(KudosError)
    }

    // MARK: - All Feed load state (paginated infinite scroll)

    enum AllFeedLoadState: Equatable {
        case idle
        case loading        // initial page in flight
        case loaded         // at least one page loaded, more may exist
        case loadingMore    // appending next page
        case endOfList      // last page returned fewer than pageSize items
        case error(KudosError)
    }

    // MARK: - Published (read-only)

    // `highlights`, `feed`, `allFeed` (and similar fields below) are `internal`
    // because the `+Likes` / `+AllFeed` cross-file extensions must mutate them
    // directly. Swift's `private(set)` is file-scoped and unreachable from
    // cross-file extensions. Consolidating extensions back here would push the
    // file past the 200-LOC guideline.
    @Published private(set) var loadState: LoadState = .idle
    @Published var highlights: [Kudos] = []
    @Published var feed: [Kudos] = []

    // MARK: - All Feed (paginated — managed by KudosViewModel+AllFeed)

    @Published var allFeed: [Kudos] = []
    @Published var allFeedLoadState: AllFeedLoadState = .idle
    var allFeedPage: Int = 0
    let allFeedPageSize: Int = 20
    var isAllFeedFetchInFlight: Bool = false
    @Published private(set) var hashtags: [Hashtag] = []
    @Published private(set) var departments: [Department] = []
    @Published private(set) var stats: UserStats = .zero
    @Published private(set) var topRecipients: [KudosAuthor] = []

    /// 1-based — `KudosCarouselDots` displays the value verbatim, so initial /
    /// post-filter state MUST be `1` to avoid the "0/N" bug (TC_FUN_005).
    @Published private(set) var carouselIndex: Int = 1
    @Published private(set) var selectedHashtagId: HashtagID? = nil
    @Published private(set) var selectedDepartmentId: DepartmentID? = nil

    // MARK: - Published (read-write — sheets/fullScreenCover need two-way binding)

    @Published var hashtagSheetPresented: Bool = false
    @Published var departmentSheetPresented: Bool = false
    @Published var presentedPhoto: URL? = nil

    // MARK: - Toast queue (single active toast — replaces itself on new emit)

    @Published private(set) var currentToast: KudosToast? = nil

    // MARK: - In-flight guards

    var likeInFlight: Set<KudosID> = []
    var secretBoxInFlight: Bool = false
    var toastDismissTask: Task<Void, Never>? = nil

    // MARK: - Dependencies

    // `repository` is internal because `+AllFeed` calls `fetchKudosFeed` directly
    // (the LoadKudosScreenUseCase bundles 5 concurrent fetches not needed for
    // single-endpoint pagination).
    private let loadUseCase: LoadKudosScreenUseCase
    let toggleReactionUseCase: ToggleKudosReactionUseCase
    let clipboard: any KudosClipboardServicing
    let repository: any KudosRepositoryProtocol
    private let clock: () -> Date

    // MARK: - Computed

    /// True when there are unopened secret boxes and no open operation in flight.
    var canOpenSecretBox: Bool {
        stats.secretBoxesUnopened > 0 && !secretBoxInFlight
    }

    // MARK: - Init

    init(
        loadUseCase: LoadKudosScreenUseCase,
        toggleReactionUseCase: ToggleKudosReactionUseCase,
        clipboard: any KudosClipboardServicing,
        repository: any KudosRepositoryProtocol,
        clock: @escaping () -> Date = { Date() }
    ) {
        self.loadUseCase = loadUseCase
        self.toggleReactionUseCase = toggleReactionUseCase
        self.clipboard = clipboard
        self.repository = repository
        self.clock = clock
    }

    // MARK: - Lifecycle

    /// Called once when the view appears. No-ops if already loaded to avoid redundant fetches.
    func onAppear() async {
        guard loadState == .idle else { return }
        await reload()
    }

    /// Fetches all screen data with the current filter and updates published state.
    func reload() async {
        loadState = .loading
        let filter = KudosFilter(
            hashtagId: selectedHashtagId,
            departmentId: selectedDepartmentId
        )
        do {
            let snapshot = try await loadUseCase.execute(filter: filter, now: clock())
            applySnapshot(snapshot)
        } catch let error as KudosError {
            loadState = .error(error)
        } catch {
            loadState = .error(.unknown(underlying: error.localizedDescription))
        }
    }

    // MARK: - Filter setters

    /// Idempotent assignment (no-op when unchanged) so double-fires from
    /// SwiftUI bindings don't toggle the filter back off. Use
    /// `toggleHashtagFilter(_:)` for re-tap-to-clear UX. Resets carousel to 1
    /// per TC_FUN_005.
    func setHashtagFilter(_ id: HashtagID?) async {
        guard id != selectedHashtagId else { return }
        selectedHashtagId = id
        carouselIndex = 1
        await reload()
    }

    /// Tap a row to switch; tap the selected row to clear.
    func toggleHashtagFilter(_ id: HashtagID) async {
        let target: HashtagID? = (id == selectedHashtagId) ? nil : id
        await setHashtagFilter(target)
    }

    /// Idempotent — see `setHashtagFilter(_:)`.
    func setDepartmentFilter(_ id: DepartmentID?) async {
        guard id != selectedDepartmentId else { return }
        selectedDepartmentId = id
        carouselIndex = 1
        await reload()
    }

    func toggleDepartmentFilter(_ id: DepartmentID) async {
        let target: DepartmentID? = (id == selectedDepartmentId) ? nil : id
        await setDepartmentFilter(target)
    }

    func onCarouselIndexChanged(_ idx: Int) {
        carouselIndex = idx
    }

    /// Resolves the tapped hashtag tag string to a `HashtagID`, then calls `setHashtagFilter`.
    func onHashtagTagTapped(_ tag: String) async {
        let normalized = tag.hasPrefix("#") ? tag : "#\(tag)"
        guard let match = hashtags.first(where: { $0.tag == normalized }) else { return }
        await setHashtagFilter(match.id)
    }

    // MARK: - Photo viewer

    func presentPhoto(_ url: URL) {
        presentedPhoto = url
    }

    // MARK: - Attachment URL resolution

    /// Concurrently resolves each `storagePath` to a signed URL (bucket is
    /// private). Returns a path → URL map; nil resolutions are omitted so the
    /// view renders a placeholder for missing entries.
    func resolveAttachmentImageURLs(for attachments: [KudosAttachment]) async -> [String: URL] {
        guard !attachments.isEmpty else { return [:] }
        return await withTaskGroup(of: (String, URL?).self, returning: [String: URL].self) { group in
            for attachment in attachments {
                let path = attachment.storagePath
                group.addTask { [repository] in
                    (path, await repository.attachmentImageURL(forStoragePath: path))
                }
            }
            var result: [String: URL] = [:]
            for await (path, url) in group {
                if let url { result[path] = url }
            }
            return result
        }
    }

    func dismissPhoto() {
        presentedPhoto = nil
    }

    // MARK: - Secret box

    /// Emits a "Coming soon" toast. Double-tap is prevented via `secretBoxInFlight`.
    func openSecretBox() {
        guard !secretBoxInFlight else { return }
        secretBoxInFlight = true
        emitToast(.comingSoon)
        // Reset guard after toast dismiss window to allow retry.
        Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            secretBoxInFlight = false
        }
    }

    // MARK: - Copy link

    /// Writes the kudos share URL to the clipboard and emits a `.linkCopied` toast.
    /// The toast is emitted even when the id/shareURL is missing so the user gets
    /// feedback that their tap was registered.
    func copyLink(_ id: KudosID) {
        if let url = findKudos(id: id)?.shareURL {
            clipboard.copy(url.absoluteString)
        }
        emitToast(.linkCopied)
    }

    // MARK: - Optimistic feed update

    /// Prepends a newly created kudos to the feed after a successful submit.
    /// A background refresh follows to reconcile server-side ordering
    /// (clarifications.md §post-submit).
    func prependKudos(_ kudos: Kudos) {
        feed.insert(kudos, at: 0)
    }

    // MARK: - Private helpers

    private func applySnapshot(_ snapshot: KudosScreenSnapshot) {
        highlights = snapshot.highlights
        feed = snapshot.feed
        hashtags = snapshot.hashtags
        departments = snapshot.departments
        stats = snapshot.stats
        topRecipients = snapshot.topRecipients
        let total = snapshot.highlights.count + snapshot.feed.count
        loadState = total == 0 ? .empty : .loaded
    }

    /// Replaces the active toast and resets the 3-second auto-dismiss timer.
    func emitToast(_ toast: KudosToast) {
        toastDismissTask?.cancel()
        currentToast = toast
        toastDismissTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            self?.currentToast = nil
        }
    }
}
