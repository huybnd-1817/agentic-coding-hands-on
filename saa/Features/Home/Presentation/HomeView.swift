import SwiftUI

// MARK: - HomeView

/// Root Home screen assembly for SAA 2025.
///
/// Purely presentational — all state is received via init params or local
/// @State stubs (mock values from Figma). Track B integration replaces mock
/// defaults with ViewModel-driven bindings via `HomeViewContainer`.
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
    var eventDateText: String    = "26/12/2026"
    var venueName: String        = "Âu Cơ Art Center"

    // MARK: - Bindings

    @Binding var selectedLanguage: AppLanguage

    // MARK: - Action closures (default no-op for previewability)

    var onAboutAward:     () -> Void               = {}
    var onAboutKudos:     () -> Void               = {}
    var onAwardDetail:    (UUID) -> Void           = { _ in }
    var onRetryAwards:    () -> Void               = {}
    var onKudosDetail:    () -> Void               = {}
    var onBellTap:        () -> Void               = {}
    var onSearchTap:      () -> Void               = {}
    var onLanguageChange: (AppLanguage) -> Void    = { _ in }
    var onFabPencilTap:   () -> Void               = {}
    var onFabKudosTap:    () -> Void               = {}

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Scrollable main content
            VStack(spacing: 0) {
                HomeHeaderView(
                    unreadCount: unreadCount,
                    selectedLanguage: $selectedLanguage,
                    onSearchTap: onSearchTap,
                    onBellTap: onBellTap,
                    onLanguageChange: onLanguageChange
                )

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        HomeHeroSection(
                            countdown: countdown,
                            eventDateText: eventDateText,
                            venueName: venueName,
                            onAboutAward: onAboutAward,
                            onAboutKudos: onAboutKudos
                        )

                        HomeNoteSection()

                        HomeAwardsSection(
                            awardsState: awardsState,
                            onAwardDetail: onAwardDetail,
                            onRetryAwards: onRetryAwards
                        )

                        if isKudosAvailable {
                            HomeKudosSection(onKudosDetail: onKudosDetail)
                        }

                        // Bottom padding clears the overlaid HomeBottomNavBar
                        // (rendered by MainTabView) + small FAB clearance.
                        Spacer().frame(height: 120)
                    }
                    .padding(.top, 16)
                }
            }

            // Floating action button — bottom-trailing, above the
            // MainTabView-owned HomeBottomNavBar (~72pt clear + safe area).
            HomeFloatingActionButton(
                onFabPencilTap: onFabPencilTap,
                onFabKudosTap: onFabKudosTap
            )
            .padding(.trailing, 20)
            .padding(.bottom, 80)
        }
        .background(backgroundLayer)
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

    // MARK: - Backdrop

    /// Dark color + keyvisual artwork (with shadow gradients baked in by Figma
    /// export) extending edge-to-edge. The exported PNG already contains the
    /// `Shadow Left` and `Shadow Bottom` linear gradients from the design
    /// group `mm_media_bg`, so no extra overlays are needed here.
    private var backgroundLayer: some View {
        ZStack {
            Color.homeBackdrop

            Image("home-bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma frame fill — #00101A.
    static let homeBackdrop = Color(red: 0.0, green: 16.0/255, blue: 26.0/255)
}

// MARK: - Previews

#if DEBUG
private struct HomePreviewHost: View {
    let awardsState: AwardsState
    let countdown: Countdown
    let isKudosAvailable: Bool

    @State private var language: AppLanguage = .vi

    var body: some View {
        let store = AuthSessionStore()
        store.injectState(state: .preview, isRestoring: false)
        let repo   = NoopAuthRepository()
        let google = NoopGoogleSignInService()
        return HomeView(
            signOutUseCase: SignOutUseCase(repository: repo, googleService: google, store: store),
            awardsState: awardsState,
            countdown: countdown,
            isKudosAvailable: isKudosAvailable,
            selectedLanguage: $language
        )
        .environmentObject(store)
    }
}

#Preview("Loaded — Kudos on") {
    HomePreviewHost(
        awardsState: .loaded(HomeMockData.previewAwards),
        countdown: HomeMockData.previewCountdown,
        isKudosAvailable: true
    )
}

#Preview("Loading") {
    HomePreviewHost(
        awardsState: .loading,
        countdown: .zero,
        isKudosAvailable: false
    )
}

#Preview("Error — Kudos off") {
    HomePreviewHost(
        awardsState: .error(.network),
        countdown: HomeMockData.previewCountdown,
        isKudosAvailable: false
    )
}

#Preview("Empty awards") {
    HomePreviewHost(
        awardsState: .empty,
        countdown: .zero,
        isKudosAvailable: true
    )
}
#endif
