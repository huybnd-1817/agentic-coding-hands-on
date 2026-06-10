import SwiftUI
import GoogleSignIn

@main
struct saaApp: App {

    @State private var authService = AuthService()
    @State private var languagePreference = LanguagePreference()

    init() {
        configureGoogleSignIn()
    }

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(authService)
                .environment(languagePreference)
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
        // hostedDomain pre-filters the Google account chooser to Sun* Workspace users.
        // Defense-in-depth only — the Postgres trigger enforce_sun_domain is the authoritative check.
        // API CONFIRM: GIDConfiguration(clientID:serverClientID:hostedDomain:) exists in GoogleSignIn-iOS v7.x.
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: clientID,
            serverClientID: nil,
            hostedDomain: "sun-asterisk.com"
        )
    }
}
