import SwiftUI

// MARK: - LoginViewContainer

/// Bridges `LoginViewModel` + `LanguagePreference` state into the purely-presentational
/// `LoginView`. Keeps all UIKit / async wiring out of `LoginView` itself.
///
/// `LoginViewModel` is constructor-injected (passed down from `AppRouter`) so the
/// composition root controls the full dependency graph.
struct LoginViewContainer: View {

    @StateObject var viewModel: LoginViewModel
    @EnvironmentObject private var languagePreference: LanguagePreference

    init(viewModel: LoginViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: - Props

    /// Pure value type capturing all state forwarded from `LoginViewModel` to `LoginView`.
    /// Extracted so the prop-derivation logic can be tested without UIKit / SwiftUI hosting.
    struct Props: Equatable {
        let isLoading: Bool
        let errorMessage: String?
    }

    /// Pure function — no side effects. Maps `LoginViewModel` state to the props
    /// `LoginView` needs. Tested directly in `LoginViewContainerPropsTests`.
    static func makeProps(viewModel: LoginViewModel) -> Props {
        Props(
            isLoading: viewModel.isLoading,
            // Catalog key (e.g. "login.error.network"). LoginView wraps in LocalizedStringKey
            // so SwiftUI's \.locale environment drives the displayed language.
            // .userCancelled returns nil — stays silent per clarifications.md.
            errorMessage: viewModel.errorMessage
        )
    }

    var body: some View {
        let props = Self.makeProps(viewModel: viewModel)
        LoginView(
            selectedLanguage: $languagePreference.current,
            isLoading: props.isLoading,
            errorMessage: props.errorMessage,
            onLoginTapped: {
                Task { @MainActor in
                    guard let vc = UIApplication.shared.topViewController else { return }
                    await viewModel.signIn(presenting: vc)
                }
            },
            onLanguageChange: { newLang in
                languagePreference.current = newLang
            }
        )
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Default") {
    let store = AuthSessionStore()
    store.injectState(state: nil, isRestoring: false)
    let vm = LoginViewModel(
        signInUseCase: SignInWithGoogleUseCase(
            repository: NoopAuthRepository(),
            googleService: NoopGoogleSignInService(),
            nonceGenerator: Nonce.default),
        store: store)
    return LoginViewContainer(viewModel: vm)
        .environmentObject(LanguagePreference())
}

#Preview("Loading") {
    let store = AuthSessionStore()
    let vm = LoginViewModel(
        signInUseCase: SignInWithGoogleUseCase(
            repository: NoopAuthRepository(),
            googleService: NoopGoogleSignInService(),
            nonceGenerator: Nonce.default),
        store: store)
    vm.injectState(isLoading: true)
    return LoginViewContainer(viewModel: vm)
        .environmentObject(LanguagePreference())
}

#Preview("Network Error") {
    let store = AuthSessionStore()
    let vm = LoginViewModel(
        signInUseCase: SignInWithGoogleUseCase(
            repository: NoopAuthRepository(),
            googleService: NoopGoogleSignInService(),
            nonceGenerator: Nonce.default),
        store: store)
    vm.injectState(errorMessage: "login.error.network")
    return LoginViewContainer(viewModel: vm)
        .environmentObject(LanguagePreference())
}
#endif
