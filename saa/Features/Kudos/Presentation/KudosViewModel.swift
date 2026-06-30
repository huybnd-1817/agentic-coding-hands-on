import Foundation
import Combine

// MARK: - KudosViewModel

/// State machine for the Sun*Kudos tab (MoMorph screen `fO0Kt19sZZ`).
///
/// All mutations happen on the main actor. The view observes published state
/// directly; callbacks from the view arrive as method calls which the container
/// dispatches via `Task { await vm.method() }`.
///
/// Bridging from Domain entities to UI structs (`KudosCardData`, `HashtagOption`,
/// etc.) is NOT done here — `KudosViewContainer` owns that translation so this VM
/// stays pure-Domain and straightforward to unit-test.
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

    // `highlights`, `feed`, and `allFeed` are `internal` (not `private`) rather than
    // `private(set)` because `KudosViewModel+Likes` and `KudosViewModel+AllFeed`
    // (separate file extensions) must write optimistic like/unlike mutations and
    // pagination results into these arrays directly.
    // Swift's `private` is file-scoped, so a cross-file extension cannot see
    // `private(set)` setters even within the same module.
    //
    // Consolidating `+Likes` / `+AllFeed` back into this file would keep access
    // narrow but would push `KudosViewModel.swift` well beyond the 200-LOC
    // file-size guideline. The widened access is intentional and documented
    // here so future reviewers do not treat it as a gap.
    //
    // Future clean-up note: if the file-size guideline is relaxed, consolidation
    // is straightforward — move the extension files into this file and restore
    // `private(set)` on all widened properties.
    @Published private(set) var loadState: LoadState = .idle
    @Published var highlights: [Kudos] = []
    @Published var feed: [Kudos] = []

    // MARK: - All Feed (paginated — managed by KudosViewModel+AllFeed)

    // `allFeed`, `allFeedPage`, `isAllFeedFetchInFlight` are `internal` for the
    // same cross-file extension reason documented above on `highlights`/`feed`.
    @Published var allFeed: [Kudos] = []
    @Published var allFeedLoadState: AllFeedLoadState = .idle
    var allFeedPage: Int = 0
    let allFeedPageSize: Int = 20
    var isAllFeedFetchInFlight: Bool = false
    @Published private(set) var hashtags: [Hashtag] = []
    @Published private(set) var departments: [Department] = []
    @Published private(set) var stats: UserStats = .zero
    @Published private(set) var topRecipients: [KudosAuthor] = []

    /// 1-based current page index for the highlight carousel.
    /// `KudosCarouselDots` displays `currentIndex/total` verbatim, so the
    /// initial state and post-filter resets MUST be `1` (not `0`) to avoid
    /// the "0/N" rendering bug after filter changes (TC_FUN_005 expects
    /// "card 1 / position đầu tiên").
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

    // `likeInFlight`, `secretBoxInFlight`, `toastDismissTask`: `internal` for
    // the same cross-file extension reason as `highlights`/`feed` above.
    var likeInFlight: Set<KudosID> = []
    var secretBoxInFlight: Bool = false
    var toastDismissTask: Task<Void, Never>? = nil

    // MARK: - Dependencies

    // `toggleReactionUseCase`, `clipboard`, and `repository` are `internal` (not `private`)
    // for the same cross-file extension reason documented above on `highlights`/`feed`.
    // `loadUseCase` is only called from this file so it remains `private`.
    // `repository` is exposed to `KudosViewModel+AllFeed` which calls `fetchKudosFeed`
    // directly (the LoadKudosScreenUseCase bundles 5 concurrent fetches not needed
    // for the single-endpoint all-feed pagination).
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

    /// Assigns the hashtag filter to `id` (or clears it when `id == nil`).
    ///
    /// IDEMPOTENT — calling twice with the same id is a no-op (no extra reload).
    /// This guards against any double-fire from SwiftUI bindings: if the
    /// dropdown's onSelect closure happens to invoke this twice in rapid
    /// succession with the same id, the filter still ends up assigned (not
    /// toggled back off).
    ///
    /// Use `toggleHashtagFilter(_:)` for the UI's re-tap-to-clear behavior.
    /// Resets carousel to card 1 per TC_FUN_005 (1-based — see `carouselIndex`).
    func setHashtagFilter(_ id: HashtagID?) async {
        guard id != selectedHashtagId else { return }
        selectedHashtagId = id
        carouselIndex = 1
        await reload()
    }

    /// UI toggle: tap a row to switch to it; tap the currently-selected row to
    /// clear. Delegates to `setHashtagFilter` so the idempotent assignment
    /// remains the single mutation path. Callers that want "tap-to-select"
    /// (without clear-on-same-tap) should use `setHashtagFilter` directly.
    func toggleHashtagFilter(_ id: HashtagID) async {
        let target: HashtagID? = (id == selectedHashtagId) ? nil : id
        await setHashtagFilter(target)
    }

    /// Assigns the department filter to `id` (or clears when nil). Idempotent —
    /// same rationale as `setHashtagFilter(_:)`. Use `toggleDepartmentFilter`
    /// for the UI's re-tap-to-clear behavior.
    func setDepartmentFilter(_ id: DepartmentID?) async {
        guard id != selectedDepartmentId else { return }
        selectedDepartmentId = id
        carouselIndex = 1
        await reload()
    }

    /// UI toggle counterpart to `setDepartmentFilter(_:)`.
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

    /// Resolves each attachment's `storagePath` to a loadable image URL via
    /// the repository. The `kudos-images` bucket is private so signed URLs
    /// are required — concurrent resolution keeps the latency bounded by the
    /// slowest single signing call, not the sum.
    ///
    /// Returns a map keyed by the original `storagePath` so the caller can
    /// look up resolved URLs without tracking index order. Entries with nil
    /// resolution (signing failed, malformed path) are omitted — the view
    /// renders a placeholder in their place.
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
    func copyLink(_ id: KudosID) {
        let kudos = highlights.first(where: { $0.id == id })
            ?? feed.first(where: { $0.id == id })
            ?? allFeed.first(where: { $0.id == id })
        if let url = kudos?.shareURL {
            clipboard.copy(url.absoluteString)
        }
        emitToast(.linkCopied)
    }

    // MARK: - Optimistic feed update

    /// Prepends a newly created kudos to the feed (top of list) after a successful submit.
    ///
    /// Called by `KudosViewContainer` via the `onKudosCreated` callback from
    /// `CreateKudoViewModel`. A background refresh follows asynchronously to
    /// reconcile server-side ordering (clarifications.md §post-submit).
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

    /// Replaces the active toast and resets its 3-second auto-dismiss timer.
    ///
    /// Internal visibility allows `KudosViewModel+Likes` to call it directly without
    /// redeclaring or duplicating the dismiss logic.
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
