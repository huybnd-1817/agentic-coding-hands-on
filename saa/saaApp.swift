import SwiftUI
import GoogleSignIn

@main
struct saaApp: App {

    @StateObject private var authService = AuthService()
    @StateObject private var languagePreference = LanguagePreference()

    init() {
        configureGoogleSignIn()
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(authService)
                .environmentObject(languagePreference)
                .environment(\.locale, Locale(identifier: languagePreference.current.localeIdentifier))
                .task {
                    await authService.restoreSession()
                }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }

    // MARK: - Private

    /// Reads CLIENT_ID from GoogleService-Info.plist and configures the GIDSignIn
    /// shared instance. Safe to call before the view tree is built.
    ///
    /// In DEBUG builds an `assertionFailure` fires when the plist is absent so the
    /// developer notices immediately. In release builds the guard silently returns —
    /// sign-in will fail gracefully via `AuthService.signInWithGoogle`.
    private func configureGoogleSignIn() {
        guard
            let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path),
            let clientID = dict["CLIENT_ID"] as? String
        else {
            #if DEBUG
            assertionFailure("GoogleService-Info.plist missing or malformed — see docs/setup-google-oauth.md")
            #endif
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }
}
