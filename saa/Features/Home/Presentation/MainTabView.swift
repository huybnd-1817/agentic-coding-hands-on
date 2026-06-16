import SwiftUI

// MARK: - MainTabView

/// 4-tab root that hosts the Home screen on tab 0 and stub tab roots elsewhere.
///
/// The `home` argument is injected as `AnyView` so the composition root (Phase
/// 07) can mount `HomeViewContainer` without forcing this file to depend on the
/// real ViewModel graph. Stubs are placeholders until destination screens land.
///
/// IMPORTANT: this view does NOT carry an `.accessibilityElement(children: .contain)`
/// boundary — that would shadow the `home.root` identifier set inside `HomeView`,
/// breaking `LoginFlowUITests.testSignedInShowsHome`.
struct MainTabView<HomeContent: View>: View {

    let home: HomeContent

    @State private var selection: NavTab = .home

    var body: some View {
        TabView(selection: $selection) {
            home
                .tabItem {
                    Label(LocalizedStringKey("home.nav.home"), systemImage: NavTab.home.systemImage)
                }
                .tag(NavTab.home)

            AwardsTabStubView()
                .tabItem {
                    Label(LocalizedStringKey("home.nav.awards"), systemImage: NavTab.awards.systemImage)
                }
                .tag(NavTab.awards)

            KudosTabStubView()
                .tabItem {
                    Label(LocalizedStringKey("home.nav.kudos"), systemImage: NavTab.kudos.systemImage)
                }
                .tag(NavTab.kudos)

            ProfileTabStubView()
                .tabItem {
                    Label(LocalizedStringKey("home.nav.profile"), systemImage: NavTab.profile.systemImage)
                }
                .tag(NavTab.profile)
        }
        .tint(Color(red: 244.0/255, green: 196.0/255, blue: 48.0/255))
        .accessibilityIdentifier("home.mainTab")
    }
}

#if DEBUG
#Preview {
    MainTabView(home: Color.black.overlay(Text("HomeView placeholder").foregroundStyle(.white)))
}
#endif
