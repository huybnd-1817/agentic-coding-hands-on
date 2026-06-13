import SwiftUI
import Supabase

// MARK: - AppRoute

/// The three branches `AppRouter.body` can take. Lifted out of the body so
/// unit tests can assert the route deterministically without depending on
/// SwiftUI's accessibility commit (which does not run synchronously in a
/// unit-test host process). Both `body` below and `AppRouterRoutingTests`
/// consume `AppRouter.activeRoute(for:)` — a change to the routing logic
/// must touch this function, which is what the tests assert against.
enum AppRoute: Equatable {
    case spinner
    case home
    case login
}

// MARK: - AppRouter

/// Root router — switches between the launch spinner, Home, and Login based on
/// `AuthService` state.
///
/// Gate order (encoded once in `activeRoute(for:)`):
///   1. `isRestoringSession` → spinner (prevents Login flash on relaunch with valid token)
///   2. `session != nil`     → HomeView
///   3. else                 → LoginViewContainer
///
/// Covers: TC_LOGIN_ACC_001, TC_LOGIN_ACC_002, TC_LOGIN_FUN_007,
///         TC_LOGIN_FUN_012, TC_LOGIN_FUN_013, TC_LOGIN_FUN_014.
struct AppRouter: View {

    @EnvironmentObject private var authService: AuthService

    /// Pure mapping from `AuthService` state → which branch `body` will mount.
    /// Single source of truth for routing — tests assert against this same
    /// expression rather than reimplementing the guard order.
    static func activeRoute(for service: AuthService) -> AppRoute {
        if service.isRestoringSession { return .spinner }
        if service.session != nil { return .home }
        return .login
    }

    var body: some View {
        Group {
            switch Self.activeRoute(for: authService) {
            case .spinner:
                ProgressView()
                    .progressViewStyle(.circular)
                    .accessibilityIdentifier("router.spinner")
            case .home:
                HomeView()
                    .accessibilityIdentifier("router.home")
            case .login:
                LoginViewContainer()
                    .accessibilityIdentifier("router.login")
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authService.session?.user.id)
        .animation(.easeInOut(duration: 0.25), value: authService.isRestoringSession)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Restoring") {
    AppRouter()
        .environmentObject(AuthService.previewRestoring())
        .environmentObject(LanguagePreference())
}

#Preview("Signed In") {
    AppRouter()
        .environmentObject(AuthService.previewSignedIn())
        .environmentObject(LanguagePreference())
}

#Preview("Signed Out") {
    AppRouter()
        .environmentObject(AuthService.previewSignedOut())
        .environmentObject(LanguagePreference())
}
#endif
