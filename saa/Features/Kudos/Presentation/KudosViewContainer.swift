import SwiftUI

// MARK: - KudosViewContainer

/// Owns the `KudosViewModel` lifecycle and adapts Domain entities to the UI structs
/// that `KudosView` consumes.
///
/// Bridging responsibility (Domain → UI structs) lives here, not in the VM, so the
/// VM stays pure-Domain and straightforward to unit-test without SwiftUI imports.
///
/// Language selection is bound to the shared `LanguagePreference` environment object
/// — the same source `saaApp` wires into `\.locale`. Using a local `@State` here
/// would update the chip visually but leave the app locale unchanged, so the
/// dropdown would silently fail to switch language. Match the pattern used by
/// `HomeViewContainer` and `LoginViewContainer`.
struct KudosViewContainer: View {

    // MARK: - Routes

    /// Navigation routes pushed from inside the Kudos tab.
    ///
    /// - `.all`     — All Kudos list screen.
    /// - `.detail`  — Detail screen for a single kudo; carries the full `Kudos`
    ///                value at push time so back/forward stack remains stable.
    ///                The destination view re-reads the latest snapshot from
    ///                the shared `KudosViewModel` so likes toggled elsewhere
    ///                (or here) stay in sync without a refetch.
    /// - `.profile` — Lightweight stub for sender/recipient tap on detail.
    enum Route: Hashable {
        case all
        case detail(Kudos)
        case profile(KudosAuthor)
    }

    // MARK: - ViewModel

    @StateObject var vm: KudosViewModel

    // MARK: - Environment

    @EnvironmentObject private var languagePreference: LanguagePreference

    // MARK: - Create Kudos presentation state

    @State private var isCreateKudosPresented = false

    // MARK: - Navigation state

    @State private var navPath: [Route] = []

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navPath) {
            rootContent
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .all:
                        AllKudosViewContainer(
                            vm: vm,
                            onBack: { navPath.removeLast() },
                            onPushDetail: { kudos in navPath.append(.detail(kudos)) },
                            onHashtagTap: { tag in popToRootAndFilterHashtag(tag) }
                        )
                        .toolbar(.hidden, for: .navigationBar)
                    case .detail(let kudos):
                        KudosDetailDestination(
                            kudos: kudos,
                            vm: vm,
                            onBack: { navPath.removeLast() },
                            onPushProfile: { author in navPath.append(.profile(author)) },
                            onHashtagTap: { tag in popToRootAndFilterHashtag(tag) }
                        )
                        .toolbar(.hidden, for: .navigationBar)
                    case .profile(let author):
                        KudosAuthorProfileStubView(
                            author: author,
                            onBack: { navPath.removeLast() }
                        )
                        .toolbar(.hidden, for: .navigationBar)
                    }
                }
        }
        // Toast overlay shared across every Kudos-tab route (root, .all,
        // .detail, .profile). The VM owns the 3-second auto-dismiss in
        // `emitToast(_:)`; this view only reflects `vm.currentToast`.
        // Without this overlay `copyLink` / `likeFailed` / `comingSoon`
        // emissions update VM state but never render — the user sees no
        // feedback after tapping Copy Link.
        .overlay(alignment: .bottom) { toastOverlay }
    }

    private var toastOverlay: some View {
        // ZStack keeps the animation context attached to the toast subtree only,
        // so `vm.currentToast` transitions fade/slide without animating the
        // rest of the screen.
        ZStack {
            if let toast = vm.currentToast {
                Text(LocalizedStringKey(toast.messageKey))
                    .font(.custom("Montserrat-Regular", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .clipShape(Capsule())
                    // Lift the banner above HomeBottomNavBar (~83pt) so it sits in
                    // the safe area between the bottom of the content and the tab bar.
                    .padding(.bottom, 110)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .accessibilityIdentifier("kudos.toast")
            }
        }
        .animation(.easeInOut(duration: 0.25), value: vm.currentToast)
    }

    // MARK: - Root content (Kudos tab landing screen)

    private var rootContent: some View {
        let departmentLookup = Dictionary(uniqueKeysWithValues: vm.departments.map { ($0.id, $0) })
        return KudosView(
            highlights: vm.highlights.map { KudosCardAdapter.cardData(from: $0, departments: departmentLookup) },
            feed: vm.feed.map { KudosCardAdapter.cardData(from: $0, departments: departmentLookup) },
            hashtagOptions: vm.hashtags.map(Self.hashtagOption),
            departmentOptions: vm.departments.map(Self.departmentOption),
            stats: Self.personalStatsData(from: vm.stats),
            topRecipients: vm.topRecipients.map(Self.recipientData),
            unreadCount: 0,
            selectedLanguage: $languagePreference.current,
            carouselIndex: carouselBinding,
            selectedHashtag: selectedHashtagBinding,
            selectedDepartment: selectedDepartmentBinding,
            isHashtagSheetPresented: $vm.hashtagSheetPresented,
            isDepartmentSheetPresented: $vm.departmentSheetPresented,
            onLanguageChange: { languagePreference.current = $0 },
            onSendKudos: { isCreateKudosPresented = true },
            onCardCopyLink: { vm.copyLink($0) },
            onCardLike: { id in Task { await vm.toggleLike(id) } },
            onCardViewDetail: { id in pushDetailForCardID(id) },
            onHashtagTagTap: { tag in Task { await vm.onHashtagTagTapped(tag) } },
            onSenderTap: { _ in },
            onRecipientTap: { _ in },
            onTopRecipientTap: { _ in },
            onOpenSecretBox: { vm.openSecretBox() },
            onViewAllKudos: { navPath.append(.all) },
            onSelectHashtag: { id in Task { await vm.toggleHashtagFilter(id) } },
            onSelectDepartment: { id in Task { await vm.toggleDepartmentFilter(id) } }
        )
        .task { await vm.onAppear() }
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $isCreateKudosPresented) {
            WriteKudoFormStubView(
                onKudosCreated: { kudos in
                    vm.prependKudos(kudos)
                    isCreateKudosPresented = false
                },
                onDismiss: { isCreateKudosPresented = false }
            )
        }
    }

    // MARK: - Derived bindings

    /// Two-way binding for carousel index that routes writes through the VM method.
    private var carouselBinding: Binding<Int> {
        Binding(
            get: { vm.carouselIndex },
            set: { vm.onCarouselIndexChanged($0) }
        )
    }

    /// Converts `selectedHashtagId` → `HashtagOption?` for the view.
    /// The setter calls `setHashtagFilter` directly (no toggle) because writes
    /// arriving via the binding represent direct state assignments — not user
    /// taps. The toggle UX lives in `onSelectHashtag` for the dropdown taps.
    private var selectedHashtagBinding: Binding<HashtagOption?> {
        Binding(
            get: {
                guard let id = vm.selectedHashtagId,
                      let hashtag = vm.hashtags.first(where: { $0.id == id })
                else { return nil }
                return HashtagOption(id: hashtag.id, label: hashtag.tag)
            },
            set: { option in
                Task { await vm.setHashtagFilter(option?.id) }
            }
        )
    }

    // MARK: - Detail navigation helpers

    /// Resolve a `KudosCardID` from either `vm.feed` or `vm.highlights` (the
    /// two card surfaces visible on the Kudos tab root) and push the detail
    /// route. Silent no-op if the id is no longer in either list — guards
    /// against a tap arriving after a filter change unmounted the source card.
    private func pushDetailForCardID(_ id: KudosCardID) {
        if let kudos = vm.feed.first(where: { $0.id == id })
            ?? vm.highlights.first(where: { $0.id == id }) {
            navPath.append(.detail(kudos))
        }
    }

    /// Pop the navigation stack all the way back to the Kudos tab root, then
    /// apply the matching hashtag as the active filter. Lookup is by tag string
    /// — when no hashtag matches the tap is treated as a clear (nil filter).
    func popToRootAndFilterHashtag(_ tag: String) {
        navPath.removeAll()
        let matchingId = Self.matchingHashtagId(tag: tag, in: vm.hashtags)
        Task { await vm.setHashtagFilter(matchingId) }
    }

    /// Resolves a tapped hashtag string (with or without leading `#`) to a
    /// `Hashtag.ID` from the VM's hashtag catalogue. Extracted as `static`
    /// so unit tests can exercise the lookup without instantiating the View
    /// (which owns the `@State` `navPath`).
    static func matchingHashtagId(tag: String, in hashtags: [Hashtag]) -> Hashtag.ID? {
        let normalised = tag.hasPrefix("#") ? tag : "#\(tag)"
        return hashtags.first { $0.tag == normalised || $0.tag == tag }?.id
    }

    /// Converts `selectedDepartmentId` → `DepartmentOption?` for the view.
    ///
    /// Displays `department.code` (stable short code such as `"CEV1"`) rather than
    /// `department.name` so the dropdown labels stay compact and locale-stable.
    private var selectedDepartmentBinding: Binding<DepartmentOption?> {
        Binding(
            get: {
                guard let id = vm.selectedDepartmentId,
                      let dept = vm.departments.first(where: { $0.id == id })
                else { return nil }
                return DepartmentOption(id: dept.id, label: dept.code)
            },
            set: { option in
                Task { await vm.setDepartmentFilter(option?.id) }
            }
        )
    }
}

// MARK: - Domain → UI adapters (pure functions, no side-effects)

private extension KudosViewContainer {

    static func hashtagOption(from hashtag: Hashtag) -> HashtagOption {
        HashtagOption(id: hashtag.id, label: hashtag.tag)
    }

    /// Map a Domain `Department` to a presentation `DepartmentOption`.
    ///
    /// `label` is sourced from `department.code` (e.g. `"CEV1"`) — the short
    /// stable identifier — rather than `department.name`, which is a longer
    /// human-readable label intended for tooltips or detail views. The Kudos
    /// dropdown is a 129pt chip where the compact code fits without truncation.
    static func departmentOption(from department: Department) -> DepartmentOption {
        DepartmentOption(id: department.id, label: department.code)
    }

    static func personalStatsData(from stats: UserStats) -> KudosPersonalStatsData {
        KudosPersonalStatsData(
            kudosReceived: stats.kudosReceivedCount,
            kudosSent: stats.kudosSentCount,
            heartsReceived: stats.kudosHeartsReceived,
            secretBoxesOpened: stats.secretBoxesOpened,
            secretBoxesUnopened: stats.secretBoxesUnopened
        )
    }

    static func recipientData(from author: KudosAuthor) -> KudosRecipientData {
        let reward = String(localized: "kudos.recipients.reward.saaShirt")
        let rewardLabel = String(
            format: String(localized: "kudos.recipients.row.receivedItem"),
            reward
        )
        return KudosRecipientData(
            // Use a stable deterministic string when userId is nil so SwiftUI's
            // ForEach diffing doesn't treat each render as a new item.
            // Strategy: derive a fixed string from displayName so identity is
            // consistent across renders (no random UUID per call).
            id: author.userId?.uuidString ?? "anon-\(author.displayName)",
            name: author.displayName,
            avatarAssetName: KudosCardAdapter.avatarAsset(for: author),
            rewardLabel: rewardLabel
        )
    }
}

// MARK: - Detail destination subview

/// Wraps `ViewKudoDetailView` for use as a `NavigationStack` destination.
///
/// Owns the lightbox `@State` (kept local so it resets on every push). Re-reads
/// the latest `Kudos` snapshot from the shared VM on each render so a like
/// toggled on this screen, or elsewhere while this screen is on the stack,
/// flows back through. Falls back to the route-carried `kudos` when the id
/// has been removed from all three lists (defensive — should not occur).
private struct KudosDetailDestination: View {

    let kudos: Kudos
    @ObservedObject var vm: KudosViewModel
    let onBack: () -> Void
    let onPushProfile: (KudosAuthor) -> Void
    let onHashtagTap: (String) -> Void

    @State private var lightbox: LightboxSelection?
    /// Storage-path → loadable URL map, populated on `.task` from the repo's
    /// `attachmentImageURL(forStoragePath:)` resolver. The `kudos-images`
    /// bucket is private so a signed URL is required to load each attachment;
    /// see `SupabaseKudosRepository.attachmentImageURL` for the contract.
    @State private var resolvedImageURLs: [String: URL] = [:]

    var body: some View {
        let live = liveKudos
        let departmentLookup = Dictionary(uniqueKeysWithValues: vm.departments.map { ($0.id, $0) })
        ViewKudoDetailView(
            kudos: live,
            departments: departmentLookup,
            resolvedImageURLs: resolvedImageURLs,
            onBack: onBack,
            onLike: { Task { await vm.toggleLike(live.id) } },
            onCopyLink: { vm.copyLink(live.id) },
            onHashtagTap: onHashtagTap,
            onSenderTap: { onPushProfile(live.sender) },
            onRecipientTap: { onPushProfile(live.recipient) },
            onImageTap: { idx in lightbox = LightboxSelection(index: idx) }
        )
        .task(id: live.attachments.map(\.storagePath)) {
            resolvedImageURLs = await vm.resolveAttachmentImageURLs(for: live.attachments)
        }
        .fullScreenCover(item: $lightbox) { sel in
            ImageLightboxView(
                // Mirror the gallery's two-path resolution: prefer the signed
                // URL, fall back to a direct parse for legacy HTTPS rows so the
                // lightbox opens immediately for those even before the
                // async resolver completes.
                imageURLs: live.attachments.compactMap { att in
                    resolvedImageURLs[att.storagePath]
                        ?? ViewKudoDetailView.directHTTPURL(from: att.storagePath)
                },
                initialIndex: sel.index,
                onDismiss: { lightbox = nil }
            )
        }
    }

    /// Look up the latest snapshot — feed → allFeed → highlights → fallback.
    private var liveKudos: Kudos {
        if let match = vm.feed.first(where: { $0.id == kudos.id }) { return match }
        if let match = vm.allFeed.first(where: { $0.id == kudos.id }) { return match }
        if let match = vm.highlights.first(where: { $0.id == kudos.id }) { return match }
        return kudos
    }
}

/// `.fullScreenCover(item:)` requires `Identifiable`. Wrapping the integer
/// index avoids the SwiftUI gotcha of using `Int?` directly.
private struct LightboxSelection: Identifiable, Hashable {
    let index: Int
    var id: Int { index }
}

// MARK: - Preview

#if DEBUG
#Preview {
    KudosViewContainer(
        vm: KudosViewModel(
            loadUseCase: LoadKudosScreenUseCase(repository: MockKudosRepository()),
            toggleReactionUseCase: ToggleKudosReactionUseCase(repository: MockKudosRepository()),
            clipboard: UIKitKudosClipboardService(),
            repository: MockKudosRepository()
        )
    )
    .environmentObject(LanguagePreference())
    .preferredColorScheme(.dark)
}
#endif
