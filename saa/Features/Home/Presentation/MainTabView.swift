import SwiftUI

// MARK: - MainTabView

/// 4-tab root that hosts the Home screen on tab 0 and stub tab roots elsewhere.
///
/// The `home` argument is injected as `AnyView` so the composition root (Phase
/// 07) can mount `HomeViewContainer` without forcing this file to depend on the
/// real ViewModel graph. Stubs are placeholders until destination screens land.
///
/// The system `TabView` is used solely for tab-switching state. Its native bar
/// is hidden (`.toolbar(.hidden, for: .tabBar)`) so a single Figma-styled
/// `HomeBottomNavBar` can be overlaid at the bottom — eliminating the prior
/// duplicate-bar regression (custom bar inside HomeView + system bar at root).
///
/// IMPORTANT: this view does NOT carry an `.accessibilityElement(children: .contain)`
/// boundary — that would shadow the `home.root` identifier set inside `HomeView`,
/// breaking `LoginFlowUITests.testSignedInShowsHome`.
struct MainTabView<HomeContent: View>: View {

    let home: HomeContent

    @State private var selection: NavTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                home
                    .tag(NavTab.home)
                    .toolbar(.hidden, for: .tabBar)

                AwardsTabStubView()
                    .tag(NavTab.awards)
                    .toolbar(.hidden, for: .tabBar)

                KudosTabStubView()
                    .tag(NavTab.kudos)
                    .toolbar(.hidden, for: .tabBar)

                ProfileTabStubView()
                    .tag(NavTab.profile)
                    .toolbar(.hidden, for: .tabBar)
            }

            HomeBottomNavBar(
                selectedTab: selection,
                onTabTap: { tab in selection = tab }
            )
        }
        .accessibilityIdentifier("home.mainTab")
    }
}

#if DEBUG
#Preview {
    MainTabView(home: Color.black.overlay(Text("HomeView placeholder").foregroundStyle(.white)))
}
#endif
