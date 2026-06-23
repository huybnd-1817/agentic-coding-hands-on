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

    // MARK: - Published (read-only)

    // `highlights` and `feed` are `internal` (not `private`) rather than
    // `private(set)` because `KudosViewModel+Likes` (a separate file extension)
    // must write optimistic like/unlike mutations into these arrays directly.
    // Swift's `private` is file-scoped, so a cross-file extension cannot see
    // `private(set)` setters even within the same module.
    //
    // Consolidating `+Likes` back into this file would keep access narrow but
    // would push `KudosViewModel.swift` to ~310 LOC — exceeding the 200-LOC
    // file-size guideline. The widened access is intentional and documented
    // here so future reviewers do not treat it as a gap.
    //
    // Phase 09 reviewer note: if the file-size guideline is relaxed in a future
    // clean-up pass, consolidation is straightforward — move all of
    // `KudosViewModel+Likes.swift` into this file and restore `private(set)`.
    @Published private(set) var loadState: LoadState = .idle
    @Published var highlights: [Kudos] = []
    @Published var feed: [Kudos] = []
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

    // `toggleReactionUseCase` and `clipboard` are `internal` (not `private`)
    // for the same cross-file extension reason documented above on `highlights`/`feed`.
    // `loadUseCase` is only called from this file so it remains `private`.
    private let loadUseCase: LoadKudosScreenUseCase
    let toggleReactionUseCase: ToggleKudosReactionUseCase
    let clipboard: any KudosClipboardServicing
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
        clock: @escaping () -> Date = { Date() }
    ) {
        self.loadUseCase = loadUseCase
        self.toggleReactionUseCase = toggleReactionUseCase
        self.clipboard = clipboard
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

    /// Selects or clears the hashtag filter. Selecting the same id twice clears it (re-tap-to-clear).
    /// Resets carousel to card 1 per TC_FUN_005 (1-based index — see `carouselIndex` doc).
    func setHashtagFilter(_ id: HashtagID?) async {
        let next: HashtagID? = (id == selectedHashtagId) ? nil : id
        selectedHashtagId = next
        carouselIndex = 1
        await reload()
    }

    /// Selects or clears the department filter. Selecting the same id twice clears it.
    /// Resets carousel to card 1 per TC_FUN_005.
    func setDepartmentFilter(_ id: DepartmentID?) async {
        let next: DepartmentID? = (id == selectedDepartmentId) ? nil : id
        selectedDepartmentId = next
        carouselIndex = 1
        await reload()
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
        if let url = kudos?.shareURL {
            clipboard.copy(url.absoluteString)
        }
        emitToast(.linkCopied)
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
