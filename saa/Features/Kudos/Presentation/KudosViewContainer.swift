import SwiftUI

// MARK: - KudosViewContainer

/// Owns the `KudosViewModel` lifecycle and adapts Domain entities to UI structs.
/// Domain → UI bridging lives here so the VM stays pure-Domain and SwiftUI-free.
///
/// Language uses the shared `LanguagePreference` env object (not local `@State`)
/// because `saaApp` wires the same source into `\.locale`.
struct KudosViewContainer: View {

    // MARK: - Routes

    /// `.detail` carries the full `Kudos` at push time so the back/forward stack
    /// stays stable; the destination re-reads the latest snapshot via
    /// `vm.findKudos` so likes toggled elsewhere stay in sync without a refetch.
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
        // Shared across every Kudos-tab route. The VM owns the 3-second
        // auto-dismiss; this overlay only reflects `vm.currentToast`.
        .overlay(alignment: .bottom) { toastOverlay }
    }

    private var toastOverlay: some View {
        // ZStack scopes the animation to the toast subtree only.
        ZStack {
            if let toast = vm.currentToast {
                Text(LocalizedStringKey(toast.messageKey))
                    .font(.custom("Montserrat-Regular", size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .clipShape(Capsule())
                    // Lift above HomeBottomNavBar (~83pt) into the safe area.
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

    private var carouselBinding: Binding<Int> {
        Binding(
            get: { vm.carouselIndex },
            set: { vm.onCarouselIndexChanged($0) }
        )
    }

    /// Binding setter assigns (no toggle): writes via the binding are direct
    /// state assignments, not user taps. Tap-to-toggle lives in `onSelectHashtag`.
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

    /// Push detail for a card id from feed or highlights. Silent no-op when
    /// the id is no longer present (guards against a tap arriving after a
    /// filter change unmounted the source card).
    private func pushDetailForCardID(_ id: KudosCardID) {
        if let kudos = vm.feed.first(where: { $0.id == id })
            ?? vm.highlights.first(where: { $0.id == id }) {
            navPath.append(.detail(kudos))
        }
    }

    /// Pop back to root, then apply the matching hashtag as the active filter.
    /// Unmatched tag → cleared filter (nil).
    func popToRootAndFilterHashtag(_ tag: String) {
        navPath.removeAll()
        let matchingId = Self.matchingHashtagId(tag: tag, in: vm.hashtags)
        Task { await vm.setHashtagFilter(matchingId) }
    }

    /// `static` so tests can exercise the lookup without a View instance.
    static func matchingHashtagId(tag: String, in hashtags: [Hashtag]) -> Hashtag.ID? {
        let normalised = tag.hasPrefix("#") ? tag : "#\(tag)"
        return hashtags.first { $0.tag == normalised || $0.tag == tag }?.id
    }

    /// Dropdown label uses `department.code` (stable short code, e.g. `"CEV1"`)
    /// rather than `name` so the 129pt chip doesn't truncate.
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
            // Stable id when userId is nil so SwiftUI ForEach diffing is consistent.
            id: author.userId?.uuidString ?? "anon-\(author.displayName)",
            name: author.displayName,
            avatarAssetName: KudosCardAdapter.avatarAsset(for: author),
            rewardLabel: rewardLabel
        )
    }
}

// MARK: - Detail destination subview

/// Wraps `ViewKudoDetailView` as a `NavigationStack` destination. Owns the
/// lightbox `@State` locally so it resets on every push.
private struct KudosDetailDestination: View {

    let kudos: Kudos
    @ObservedObject var vm: KudosViewModel
    let onBack: () -> Void
    let onPushProfile: (KudosAuthor) -> Void
    let onHashtagTap: (String) -> Void

    @State private var lightbox: LightboxSelection?
    /// Storage-path → signed URL map. The `kudos-images` bucket is private.
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
                // Mirror gallery's two-path resolution: prefer signed URL,
                // fall back to direct parse for legacy HTTPS rows.
                imageURLs: live.attachments.compactMap { att in
                    resolvedImageURLs[att.storagePath]
                        ?? ViewKudoDetailView.directHTTPURL(from: att.storagePath)
                },
                initialIndex: sel.index,
                onDismiss: { lightbox = nil }
            )
        }
    }

    /// Latest snapshot from VM (highlights → feed → allFeed), falling back to
    /// the route-carried `kudos` when the id has been removed from all lists.
    private var liveKudos: Kudos {
        vm.findKudos(id: kudos.id) ?? kudos
    }
}

/// `.fullScreenCover(item:)` requires `Identifiable` — wrap the Int.
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
