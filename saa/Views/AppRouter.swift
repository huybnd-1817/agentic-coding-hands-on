import SwiftUI

// MARK: - AppRouter

/// Root router — switches between the launch spinner, Home, and Login based on
/// `AuthService` state.
///
/// Gate order:
///   1. `isRestoringSession` → spinner (prevents Login flash on relaunch with valid token)
///   2. `session != nil`     → HomeView
///   3. else                 → LoginViewContainer
///
/// Covers: TC_LOGIN_ACC_001, TC_LOGIN_ACC_002, TC_LOGIN_FUN_007,
///         TC_LOGIN_FUN_012, TC_LOGIN_FUN_013, TC_LOGIN_FUN_014.
struct AppRouter: View {

    @Environment(AuthService.self) private var authService

    var body: some View {
        Group {
            if authService.isRestoringSession {
                ProgressView()
                    .progressViewStyle(.circular)
            } else if authService.session != nil {
                HomeView()
            } else {
                LoginViewContainer()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: authService.session?.user.id)
        .animation(.easeInOut(duration: 0.25), value: authService.isRestoringSession)
    }
}

// MARK: - Previews

#Preview("Restoring") {
    AppRouter()
        .environment(AuthService.previewRestoring())
        .environment(LanguagePreference())
}

#Preview("Signed In") {
    AppRouter()
        .environment(AuthService.previewSignedIn())
        .environment(LanguagePreference())
}

#Preview("Signed Out") {
    AppRouter()
        .environment(AuthService.previewSignedOut())
        .environment(LanguagePreference())
}
