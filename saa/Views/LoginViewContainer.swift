import SwiftUI

// MARK: - LoginViewProps

/// Pure value type capturing all state forwarded from `AuthService` to `LoginView`.
/// Extracted so the prop-derivation logic can be tested without UIKit / SwiftUI hosting.
struct LoginViewProps: Equatable {
    let isLoading: Bool
    let errorMessage: String?
}

// MARK: - LoginViewContainer

/// Bridges `AuthService` + `LanguagePreference` state into the purely-presentational
/// `LoginView`. Keeps all UIKit / async wiring out of `LoginView` itself.
struct LoginViewContainer: View {

    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var languagePreference: LanguagePreference

    // MARK: Props factory

    /// Pure function — no side effects. Maps `AuthService` state to the props
    /// `LoginView` needs. Tested directly in `LoginViewContainerPropsTests`.
    static func makeProps(authService: AuthService) -> LoginViewProps {
        LoginViewProps(
            isLoading: authService.isLoading,
            // Catalog key (e.g. "login.error.network"). LoginView wraps in LocalizedStringKey
            // so SwiftUI's \.locale environment drives the displayed language.
            // .userCancelled returns nil — stays silent per clarifications.md
            errorMessage: authService.error?.messageKey
        )
    }

    var body: some View {
        let props = Self.makeProps(authService: authService)
        LoginView(
            selectedLanguage: $languagePreference.current,
            isLoading: props.isLoading,
            errorMessage: props.errorMessage,
            onLoginTapped: {
                Task { @MainActor in
                    guard let vc = UIApplication.shared.topViewController else { return }
                    await authService.signInWithGoogle(presenting: vc)
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
    LoginViewContainer()
        .environmentObject(AuthService.previewSignedOut())
        .environmentObject(LanguagePreference())
}

#Preview("Loading") {
    LoginViewContainer()
        .environmentObject(AuthService.previewLoading())
        .environmentObject(LanguagePreference())
}

#Preview("Network Error") {
    LoginViewContainer()
        .environmentObject(AuthService.previewNetworkError())
        .environmentObject(LanguagePreference())
}
#endif
