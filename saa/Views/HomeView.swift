import SwiftUI
import Supabase

// MARK: - HomeView

/// Minimal Home screen. Satisfies TC_LOGIN_FUN_007 (navigation to Home on
/// successful sign-in) and TC_LOGIN_FUN_014 (logout returns to Login).
///
/// No styling polish — placeholder layout per Phase 06 spec.
struct HomeView: View {

    @EnvironmentObject private var authService: AuthService
    /// Honors the `\.locale` injected in `saaApp` so the greeting follows the
    /// in-app language selection (not just the system locale).
    @SwiftUI.Environment(\.locale) private var locale

    private var greetingText: String {
        let format = String(localized: "home.greeting", locale: locale)
        return String(format: format, authService.session?.user.email ?? "")
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(greetingText)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Button(LocalizedStringKey("home.button.logout")) {
                Task {
                    await authService.signOut()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Signed In") {
    HomeView()
        .environmentObject(AuthService.previewSignedIn())
}

#Preview("Default") {
    HomeView()
        .environmentObject(AuthService())
}
#endif
