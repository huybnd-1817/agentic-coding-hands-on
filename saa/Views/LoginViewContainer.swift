import SwiftUI

// MARK: - LoginViewContainer

/// Bridges `AuthService` + `LanguagePreference` state into the purely-presentational
/// `LoginView`. Keeps all UIKit / async wiring out of `LoginView` itself.
struct LoginViewContainer: View {

    @Environment(AuthService.self) private var authService
    @Environment(LanguagePreference.self) private var languagePreference

    var body: some View {
        @Bindable var prefs = languagePreference
        LoginView(
            selectedLanguage: $prefs.current,
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
        .environment(AuthService.previewSignedOut())
        .environment(LanguagePreference())
}

#Preview("Loading") {
    LoginViewContainer()
        .environment(AuthService.previewLoading())
        .environment(LanguagePreference())
}

#Preview("Network Error") {
    LoginViewContainer()
        .environment(AuthService.previewNetworkError())
        .environment(LanguagePreference())
}
