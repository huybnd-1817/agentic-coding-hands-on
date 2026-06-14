import SwiftUI

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
/// `AuthSessionStore` state.
///
/// Gate order (encoded once in `activeRoute(for:)`):
///   1. `isRestoring` → spinner (prevents Login flash on relaunch with valid token)
///   2. `state != nil` → HomeView
///   3. else          → LoginViewContainer
///
/// Covers: TC_LOGIN_ACC_001, TC_LOGIN_ACC_002, TC_LOGIN_FUN_007,
///         TC_LOGIN_FUN_012, TC_LOGIN_FUN_013, TC_LOGIN_FUN_014.
struct AppRouter: View {

    @EnvironmentObject private var authSession: AuthSessionStore

    /// Composition root owns the VM so its state can be pre-populated for UI tests
    /// before the first frame renders. AppRouter just passes it through to the
    /// LoginViewContainer when the login branch is mounted.
    let loginViewModel: LoginViewModel
    let signOutUseCase: SignOutUseCase

    /// Pure mapping from `AuthSessionStore` state → which branch `body` will mount.
    /// Single source of truth for routing — tests assert against this same
    /// expression rather than reimplementing the guard order.
    static func activeRoute(for store: AuthSessionStore) -> AppRoute {
        if store.isRestoring { return .spinner }
        if store.state != nil { return .home }
        return .login
    }

    var body: some View {
        Group {
            switch Self.activeRoute(for: authSession) {
            case .spinner:
                ProgressView()
                    .progressViewStyle(.circular)
                    .accessibilityIdentifier("router.spinner")
            case .home:
                HomeView(signOutUseCase: signOutUseCase)
                    .accessibilityIdentifier("router.home")
            case .login:
                LoginViewContainer(viewModel: loginViewModel)
                    .accessibilityIdentifier("router.login")
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authSession.state?.userID)
        .animation(.easeInOut(duration: 0.25), value: authSession.isRestoring)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Restoring") {
    let store = AuthSessionStore()
    store.injectState(state: nil, isRestoring: true)
    let repo = NoopAuthRepository()
    let google = NoopGoogleSignInService()
    let signOutUseCase = SignOutUseCase(repository: repo, googleService: google, store: store)
    let vm = LoginViewModel(
        signInUseCase: SignInWithGoogleUseCase(
            repository: repo, googleService: google, nonceGenerator: Nonce.default),
        store: store)
    return AppRouter(loginViewModel: vm, signOutUseCase: signOutUseCase)
    .environmentObject(store)
    .environmentObject(LanguagePreference())
}

#Preview("Signed In") {
    let store = AuthSessionStore()
    store.injectState(state: .preview, isRestoring: false)
    let repo = NoopAuthRepository()
    let google = NoopGoogleSignInService()
    let signOutUseCase = SignOutUseCase(repository: repo, googleService: google, store: store)
    let vm = LoginViewModel(
        signInUseCase: SignInWithGoogleUseCase(
            repository: repo, googleService: google, nonceGenerator: Nonce.default),
        store: store)
    return AppRouter(loginViewModel: vm, signOutUseCase: signOutUseCase)
    .environmentObject(store)
    .environmentObject(LanguagePreference())
}

#Preview("Signed Out") {
    let store = AuthSessionStore()
    store.injectState(state: nil, isRestoring: false)
    let repo = NoopAuthRepository()
    let google = NoopGoogleSignInService()
    let signOutUseCase = SignOutUseCase(repository: repo, googleService: google, store: store)
    let vm = LoginViewModel(
        signInUseCase: SignInWithGoogleUseCase(
            repository: repo, googleService: google, nonceGenerator: Nonce.default),
        store: store)
    return AppRouter(loginViewModel: vm, signOutUseCase: signOutUseCase)
    .environmentObject(store)
    .environmentObject(LanguagePreference())
}
#endif
