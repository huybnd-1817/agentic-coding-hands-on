import SwiftUI

// MARK: - MainTabView

/// 4-tab root that hosts the Home screen on tab 0 and real tab roots elsewhere.
///
/// The `home` argument is injected as a generic `View` so the composition root
/// can mount `HomeViewContainer` without forcing this file to depend on the
/// real ViewModel graph.
///
/// Cross-tab navigation (Step 3): an optional `externalSelection` binding lets
/// a parent (e.g. `HomeViewContainer`) drive tab selection from the outside — e.g.
/// when the Home-banner "kudos detail" CTA should switch to the Kudos tab.
/// When `nil`, the view manages its own `@State` (standard launch and previews).
///
/// The system `TabView` is used solely for tab-switching state. Its native bar
/// is hidden (`.toolbar(.hidden, for: .tabBar)`) so a single Figma-styled
/// `HomeBottomNavBar` can be overlaid at the bottom — eliminating the prior
/// duplicate-bar regression.
///
/// IMPORTANT: this view does NOT carry an `.accessibilityElement(children: .contain)`
/// boundary — that would shadow the `home.root` identifier set inside `HomeView`,
/// breaking `LoginFlowUITests.testSignedInShowsHome`.
struct MainTabView<HomeContent: View>: View {

    let home: HomeContent

    /// Injected from `HomeViewContainer` for cross-tab nav. `nil` → use `@State`.
    var externalSelection: Binding<NavTab>?

    /// Awards tab root, fully constructed at the composition root.
    let awardsContainer: AwardsViewContainer

    /// Kudos feature ViewModel, fully constructed at the composition root.
    let kudosViewModel: KudosViewModel

    @State private var localSelection: NavTab = .home

    /// The live selection binding: external takes priority over local.
    private var selection: Binding<NavTab> {
        externalSelection ?? $localSelection
    }

    // MARK: - Init

    init(
        home: HomeContent,
        externalSelection: Binding<NavTab>? = nil,
        awardsContainer: AwardsViewContainer,
        kudosViewModel: KudosViewModel
    ) {
        self.home = home
        self.externalSelection = externalSelection
        self.awardsContainer = awardsContainer
        self.kudosViewModel = kudosViewModel
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: selection) {
                home
                    .tag(NavTab.home)
                    .toolbar(.hidden, for: .tabBar)

                awardsContainer
                    .tag(NavTab.awards)
                    .toolbar(.hidden, for: .tabBar)

                // Phase 09: KudosTabRoot replaced with real VM-backed container.
                KudosViewContainer(vm: kudosViewModel)
                    .tag(NavTab.kudos)
                    .toolbar(.hidden, for: .tabBar)

                ProfileTabStubView()
                    .tag(NavTab.profile)
                    .toolbar(.hidden, for: .tabBar)
            }

            HomeBottomNavBar(
                selectedTab: selection.wrappedValue,
                onTabTap: { tab in selection.wrappedValue = tab }
            )
        }
        .accessibilityIdentifier("home.mainTab")
    }
}

#if DEBUG
#Preview {
    let previewAwards = HomeMockData.previewAwards
    let initial = previewAwards.min(by: { $0.sortOrder < $1.sortOrder }) ?? previewAwards[0]
    return MainTabView(
        home: Color.black.overlay(Text("HomeView placeholder").foregroundStyle(.white)),
        awardsContainer: AwardsViewContainer(
            awards: previewAwards,
            activeTab: .constant(.awards),
            makeViewModel: AwardDetailViewModel(awards: previewAwards, initiallySelected: initial)
        ),
        kudosViewModel: KudosViewModel(
            loadUseCase: LoadKudosScreenUseCase(repository: MockKudosRepository()),
            toggleReactionUseCase: ToggleKudosReactionUseCase(repository: MockKudosRepository()),
            clipboard: UIKitKudosClipboardService(),
            repository: MockKudosRepository()
        )
    )
    .environmentObject(LanguagePreference())
}
#endif
