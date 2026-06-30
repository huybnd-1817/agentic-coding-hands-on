import SwiftUI

// MARK: - AllKudosViewContainer

/// Hosts `AllKudosView` and bridges the shared `KudosViewModel` to the view's
/// prop contract.
///
/// Uses `@ObservedObject` (not `@StateObject`) because the VM is owned by the
/// parent `KudosViewContainer` — sharing the same instance is what keeps the
/// preview feed (`vm.feed`) and the All Kudos feed (`vm.allFeed`) in sync when
/// a like is toggled on either screen (see `KudosViewModel+Likes.updateKudos`).
///
/// Lifecycle:
///   - `.task` fires `loadAllFeedInitial()` on appear; the loader is idempotent
///     (guards on `allFeedLoadState == .idle`) so re-appearing after a detail
///     pop is a no-op, which preserves the scroll position.
///   - No `.onDisappear` reset — clearing the feed on transient pushes (e.g.
///     to the detail screen) was wiping `vm.allFeed`, forcing a fresh page-0
///     fetch on pop and resetting the ScrollView to top. The user pulls to
///     refresh for fresh data.
///   - Back navigation is delegated to the parent `KudosViewContainer` via the
///     injected `onBack` callback (which pops the `NavigationStack` path).
///     The project defines its own `Environment` enum that shadows SwiftUI's
///     `@Environment` property wrapper at the module level, so the dismiss
///     environment is unusable here without fully-qualifying every call —
///     a callback is simpler and equally explicit.
struct AllKudosViewContainer: View {

    // MARK: - Shared ViewModel

    @ObservedObject var vm: KudosViewModel

    // MARK: - Navigation callbacks (injected by KudosViewContainer)

    let onBack: () -> Void
    /// Pushes the detail route onto the parent `NavigationStack`. Resolution
    /// from `KudosCardID` → `Kudos` happens here against `vm.allFeed` so the
    /// caller only needs to forward the value to `navPath.append(.detail(_))`.
    let onPushDetail: (Kudos) -> Void
    /// Hashtag pill tapped on a card inside All Kudos — parent pops the stack
    /// to Kudos tab root and applies the hashtag filter (the same handler the
    /// detail screen uses). Passed in so this container stays unaware of the
    /// parent's navigation state.
    let onHashtagTap: (String) -> Void

    // MARK: - Body

    var body: some View {
        let departmentLookup = Dictionary(uniqueKeysWithValues: vm.departments.map { ($0.id, $0) })
        let cards = vm.allFeed.map { KudosCardAdapter.cardData(from: $0, departments: departmentLookup) }

        return AllKudosView(
            kudos: cards,
            isInitialLoading: vm.allFeedLoadState == .loading,
            isLoadingMore: vm.allFeedLoadState == .loadingMore,
            hasMore: vm.allFeedLoadState != .endOfList,
            onBack: onBack,
            onCardLike:       { id in Task { await vm.toggleLike(id) } },
            onCardCopyLink:   { id in vm.copyLink(id) },
            onCardViewDetail: { id in
                if let kudos = vm.allFeed.first(where: { $0.id == id }) {
                    onPushDetail(kudos)
                }
            },
            onHashtagTap:     onHashtagTap,
            onSenderTap:      { _ in },
            onRecipientTap:   { _ in },
            onReachBottom:    { Task { await vm.loadAllFeedMore() } },
            onRefresh:        { await vm.refreshAllFeed() }
        )
        .task { await vm.loadAllFeedInitial() }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    AllKudosViewContainer(
        vm: KudosViewModel(
            loadUseCase: LoadKudosScreenUseCase(repository: MockKudosRepository()),
            toggleReactionUseCase: ToggleKudosReactionUseCase(repository: MockKudosRepository()),
            clipboard: UIKitKudosClipboardService(),
            repository: MockKudosRepository()
        ),
        onBack: {},
        onPushDetail: { _ in },
        onHashtagTap: { _ in }
    )
    .preferredColorScheme(.dark)
}
#endif
