import SwiftUI

// MARK: - HomeView

/// Minimal Home screen. Satisfies TC_LOGIN_FUN_007 (navigation to Home on
/// successful sign-in) and TC_LOGIN_FUN_014 (logout returns to Login).
///
/// `SignOutUseCase` is constructor-injected from `AppRouter` so the composition
/// root controls the full dependency graph. `AuthSessionStore` is read via
/// `@EnvironmentObject` for the greeting (no sign-out coupling needed here).
///
/// No styling polish — placeholder layout per Phase 06 spec.
struct HomeView: View {

    @EnvironmentObject private var authSession: AuthSessionStore
    /// Honors the `\.locale` injected in `saaApp` so the greeting follows the
    /// in-app language selection (not just the system locale).
    @SwiftUI.Environment(\.locale) private var locale

    let signOutUseCase: SignOutUseCase

    private var greetingText: String {
        let format = String(localized: "home.greeting", locale: locale)
        return String(format: format, authSession.state?.email ?? "")
    }

    var body: some View {
        // `.accessibilityElement(children: .contain)` acts as the accessibility
        // boundary, preventing the outer `router.home` identifier set by
        // `AppRouter` from propagating onto children and shadowing
        // `home.logoutButton`. The boundary owns `home.root`.
        VStack(spacing: 24) {
            Spacer()

            Text(greetingText)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Button(LocalizedStringKey("home.button.logout")) {
                Task { await signOutUseCase.execute() }
            }
            .accessibilityIdentifier("home.logoutButton")
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.root")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Signed In") {
    let store = AuthSessionStore()
    store.injectState(state: .preview, isRestoring: false)
    let repo = NoopAuthRepository()
    let google = NoopGoogleSignInService()
    return HomeView(signOutUseCase: SignOutUseCase(repository: repo, googleService: google, store: store))
        .environmentObject(store)
}

#Preview("Default") {
    let store = AuthSessionStore()
    store.injectState(state: nil, isRestoring: false)
    let repo = NoopAuthRepository()
    let google = NoopGoogleSignInService()
    return HomeView(signOutUseCase: SignOutUseCase(repository: repo, googleService: google, store: store))
        .environmentObject(store)
}
#endif
