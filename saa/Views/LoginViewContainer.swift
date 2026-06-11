import SwiftUI

// MARK: - LoginViewContainer

/// Bridges `AuthService` + `LanguagePreference` state into the purely-presentational
/// `LoginView`. Keeps all UIKit / async wiring out of `LoginView` itself.
struct LoginViewContainer: View {

    @EnvironmentObject private var authService: AuthService
    @EnvironmentObject private var languagePreference: LanguagePreference

    var body: some View {
        LoginView(
            selectedLanguage: $languagePreference.current,
            isLoading: authService.isLoading,
            // Catalog key (e.g. "login.error.network"). LoginView wraps in LocalizedStringKey
            // so SwiftUI's \.locale environment drives the displayed language.
            // .userCancelled returns nil — stays silent per clarifications.md
            errorMessage: authService.error?.messageKey,
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
