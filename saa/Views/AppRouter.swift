import SwiftUI
import Supabase

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

    @EnvironmentObject private var authService: AuthService

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
