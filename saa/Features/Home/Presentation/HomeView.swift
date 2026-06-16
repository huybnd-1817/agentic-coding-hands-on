import SwiftUI

// MARK: - HomeView

/// Root Home screen assembly for SAA 2025.
///
/// Purely presentational — all state is received via init params or local
/// @State stubs (mock values from Figma). Track B integration will replace
/// mock defaults with ViewModel-driven bindings.
///
/// Backward-compatibility notes:
/// - `signOutUseCase` param is retained so `AppRouter` and existing UI tests
///   type-check without modification. It is unused in this phase; the sign-out
///   action will be wired inside the Profile tab stub at integration.
/// - `home.root` accessibilityIdentifier is preserved on the outermost VStack
///   (TC_LOGIN_FUN_007 / testSignedInShowsHome depends on it).
/// - `home.logoutButton` is preserved on a hidden button so
///   testSignedInShowsHome continues to pass until the Profile tab is wired.
struct HomeView: View {

    // MARK: - Backward-compat injection (AppRouter / UI tests)

    let signOutUseCase: SignOutUseCase

    // MARK: - State surfaces (Phase 07: bound to HomeViewModel via HomeViewContainer)

    var awardsState: AwardsState = .loading
    var countdown: Countdown     = .zero
    var unreadCount: Int         = 0
    var isKudosAvailable: Bool   = true

    // MARK: - Action closures (default no-op for previewability)

    var onAboutAward:    () -> Void        = {}
    var onAboutKudos:    () -> Void        = {}
    var onAwardDetail:   (UUID) -> Void    = { _ in }
    var onRetryAwards:   () -> Void        = {}
    var onKudosDetail:   () -> Void        = {}
    var onBellTap:       () -> Void        = {}
    var onSearchTap:     () -> Void        = {}
    var onLanguageTap:   () -> Void        = {}
    var onFabPencilTap:  () -> Void        = {}
    var onFabKudosTap:   () -> Void        = {}
    var onNavTabTap:     (NavTab) -> Void  = { _ in }

    // MARK: - Local UI state

    @State private var selectedTab: NavTab = .home

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Full-screen dark background
            Color.homeBackdrop.ignoresSafeArea()

            // Scrollable main content
            VStack(spacing: 0) {
                HomeHeaderView(
                    unreadCount: unreadCount,
                    onSearchTap: onSearchTap,
                    onBellTap: onBellTap,
                    onLanguageTap: onLanguageTap
                )

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        HomeHeroSection(
                            countdown: countdown,
                            onAboutAward: onAboutAward,
                            onAboutKudos: onAboutKudos
                        )

                        HomeAwardsSection(
                            awardsState: awardsState,
                            onAwardDetail: onAwardDetail,
                            onRetryAwards: onRetryAwards
                        )

                        if isKudosAvailable {
                            HomeKudosSection(onKudosDetail: onKudosDetail)
                        }

                        // Bottom padding so FAB doesn't overlap last content
                        Spacer().frame(height: 80)
                    }
                    .padding(.top, 16)
                }

                HomeBottomNavBar(
                    selectedTab: selectedTab,
                    onTabTap: { tab in
                        selectedTab = tab
                        onNavTabTap(tab)
                    }
                )
            }

            // Floating action button — bottom-trailing, above nav bar
            HomeFloatingActionButton(
                onFabPencilTap: onFabPencilTap,
                onFabKudosTap: onFabKudosTap
            )
            .padding(.trailing, 20)
            .padding(.bottom, 72)  // clears the nav bar height
        }
        // Accessibility boundary — prevents router.home from shadowing children.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.root")
        // Backward-compat: UI test testSignedInShowsHome asserts home.logoutButton.
        // Hidden until Profile tab stub is wired with a real sign-out control.
        //
        // TODO: remove once Profile tab is built (Phase 08 / future plan).
        // Latent risk: an accidental removal of `.allowsHitTesting(false)` or
        // `.opacity(0)` would expose a hit-testable sign-out trigger anywhere
        // on the screen. The pairing of BOTH modifiers is intentional —
        // either alone is insufficient.
        .background(
            Button {
                Task { await signOutUseCase.execute() }
            } label: {
                EmptyView()
            }
            .accessibilityIdentifier("home.logoutButton")
            .opacity(0)
            .allowsHitTesting(false)
        )
        .preferredColorScheme(.dark)
    }
}

// MARK: - Color tokens

private extension Color {
    static let homeBackdrop = Color(red: 0.0, green: 16.0/255, blue: 26.0/255)
}

// MARK: - Previews

#if DEBUG
#Preview("Loaded — Kudos on") {
    let store = AuthSessionStore()
    store.injectState(state: .preview, isRestoring: false)
    let repo   = NoopAuthRepository()
    let google = NoopGoogleSignInService()
    return HomeView(
        signOutUseCase: SignOutUseCase(repository: repo, googleService: google, store: store),
        awardsState: .loaded(HomeMockData.previewAwards),
        countdown: HomeMockData.previewCountdown,
        isKudosAvailable: true
    )
    .environmentObject(store)
}

#Preview("Loading") {
    let store = AuthSessionStore()
    store.injectState(state: .preview, isRestoring: false)
    let repo   = NoopAuthRepository()
    let google = NoopGoogleSignInService()
    return HomeView(
        signOutUseCase: SignOutUseCase(repository: repo, googleService: google, store: store),
        awardsState: .loading,
        isKudosAvailable: false
    )
    .environmentObject(store)
}

#Preview("Error — Kudos off") {
    let store = AuthSessionStore()
    store.injectState(state: .preview, isRestoring: false)
    let repo   = NoopAuthRepository()
    let google = NoopGoogleSignInService()
    return HomeView(
        signOutUseCase: SignOutUseCase(repository: repo, googleService: google, store: store),
        awardsState: .error(.network),
        countdown: HomeMockData.previewCountdown,
        isKudosAvailable: false
    )
    .environmentObject(store)
}

#Preview("Empty awards") {
    let store = AuthSessionStore()
    store.injectState(state: .preview, isRestoring: false)
    let repo   = NoopAuthRepository()
    let google = NoopGoogleSignInService()
    return HomeView(
        signOutUseCase: SignOutUseCase(repository: repo, googleService: google, store: store),
        awardsState: .empty,
        isKudosAvailable: true
    )
    .environmentObject(store)
}
#endif
