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
///   - `.task` fires `loadAllFeedInitial()` once on appear.
///   - `.onDisappear` calls `resetAllFeed()` so the next push starts from page 0
///     without serving stale items.
///   - Back navigation is delegated to the parent `KudosViewContainer` via the
///     injected `onBack` callback (which pops the `NavigationStack` path).
///     The project defines its own `Environment` enum that shadows SwiftUI's
///     `@Environment` property wrapper at the module level, so the dismiss
///     environment is unusable here without fully-qualifying every call —
///     a callback is simpler and equally explicit.
struct AllKudosViewContainer: View {

    // MARK: - Shared ViewModel

    @ObservedObject var vm: KudosViewModel

    // MARK: - Navigation callback (injected by KudosViewContainer)

    let onBack: () -> Void

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
            onCardViewDetail: { _ in },
            onHashtagTap:     { _ in },
            onSenderTap:      { _ in },
            onRecipientTap:   { _ in },
            onReachBottom:    { Task { await vm.loadAllFeedMore() } },
            onRefresh:        { await vm.refreshAllFeed() }
        )
        .task { await vm.loadAllFeedInitial() }
        .onDisappear { vm.resetAllFeed() }
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
        onBack: {}
    )
    .preferredColorScheme(.dark)
}
#endif
