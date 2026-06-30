import SwiftUI

// MARK: - AllKudosViewContainer

/// Hosts `AllKudosView` against the shared `KudosViewModel`. `@ObservedObject`
/// (not `@StateObject`) keeps `vm.feed` and `vm.allFeed` in sync across screens.
///
/// `.task` calls the idempotent `loadAllFeedInitial()` — re-appearing after a
/// detail-pop is a no-op so scroll position survives. No `.onDisappear` reset
/// (the user pulls to refresh for fresh data). Back nav uses the injected
/// callback because the project's `Environment` enum shadows SwiftUI's
/// `@Environment` property wrapper.
struct AllKudosViewContainer: View {

    // MARK: - Shared ViewModel

    @ObservedObject var vm: KudosViewModel

    // MARK: - Navigation callbacks (injected by KudosViewContainer)

    let onBack: () -> Void
    /// Push detail. Card-id → Kudos resolution happens here against `vm.allFeed`.
    let onPushDetail: (Kudos) -> Void
    /// Parent pops to Kudos tab root and applies the matching hashtag filter.
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
