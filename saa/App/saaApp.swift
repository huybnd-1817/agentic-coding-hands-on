import SwiftUI
import GoogleSignIn

@main
struct saaApp: App {

    // UI test seam: makeAuthService() returns a preview stub when -uiTestMode is
    // present in DEBUG builds. In Release builds the #if DEBUG block is stripped
    // entirely, so production binaries never honour -uiTestMode.
    @StateObject private var authService: AuthService = saaApp.makeAuthService()
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
                    #if DEBUG
                    if saaApp.uiTestScenario() != nil { return }
                    #endif
                    await authService.restoreSession()
                }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }

    // MARK: - Private

    /// Returns a live `AuthService`, or a DEBUG-only preview stub when the
    /// `-uiTestMode <scenario>` launch argument is present. Never executed in
    /// Release builds — the entire factory body collapses to `return AuthService()`.
    private static func makeAuthService() -> AuthService {
        #if DEBUG
        if let scenario = uiTestScenario() {
            switch scenario {
            case "signedIn":      return AuthService.previewSignedIn()
            case "signedOut":     return AuthService.previewSignedOut()
            case "restoring":     return AuthService.previewRestoring()
            case "loading":       return AuthService.previewLoading()
            case "networkError":  return AuthService.previewNetworkError()
            case "notAuthorized": return AuthService.previewNotAuthorized()
            default:
                // Catch Phase 04 typos at the seam instead of falling through to
                // a live AuthService that would attempt real auth during a UI test.
                assertionFailure("Unknown uiTestMode scenario: \(scenario)")
            }
        }
        #endif
        return AuthService()
    }

    #if DEBUG
    /// Reads the scenario name that follows `-uiTestMode` in `CommandLine.arguments`.
    /// Returns `nil` when the flag is absent (i.e., in normal app launches).
    private static func uiTestScenario() -> String? {
        let args = CommandLine.arguments
        guard let idx = args.firstIndex(of: "-uiTestMode"), idx + 1 < args.count else { return nil }
        return args[idx + 1]
    }
    #endif

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
