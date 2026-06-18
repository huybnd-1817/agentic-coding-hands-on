import Foundation
import GoogleSignIn

// MARK: - saaApp setup helpers

/// Split from `saaApp.swift` to keep that file under the 80-LoC cap.
/// Contains Google Sign-In configuration and the DEBUG-only UI-test seam helpers.
extension saaApp {

    static func configureGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let clientID = dict["CLIENT_ID"] as? String else {
            #if DEBUG
            assertionFailure("GoogleService-Info.plist missing or malformed — see docs/setup-google-oauth.md")
            #endif
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    #if DEBUG
    static func uiTestScenario() -> String? {
        let args = CommandLine.arguments
        guard let idx = args.firstIndex(of: "-uiTestMode"), idx + 1 < args.count else { return nil }
        return args[idx + 1]
    }

    /// Applies the UI-test scenario to both the session store and the login view
    /// model so that the first frame matches the assertion the XCUITest expects
    /// (no taps, no async work — pure pre-injected state).
    static func applyScenario(_ scenario: String, to store: AuthSessionStore, loginViewModel: LoginViewModel) {
        switch scenario {
        case "signedIn":
            store.injectState(state: .preview, isRestoring: false)
        case "signedOut":
            store.injectState(state: nil, isRestoring: false)
        case "restoring":
            store.injectState(state: nil, isRestoring: true)
        case "loading":
            store.injectState(state: nil, isRestoring: false)
            loginViewModel.injectState(isLoading: true)
        case "networkError":
            store.injectState(state: nil, isRestoring: false)
            loginViewModel.injectState(errorMessage: "login.error.network")
        case "notAuthorized":
            store.injectState(state: nil, isRestoring: false)
            loginViewModel.injectState(errorMessage: "login.error.notAuthorized")
        case "accessDenied":
            // TC_ACC_004 — signed in + access-denied flag → AppRouter shows
            // AccessDeniedView. The container's awards fetch is skipped because
            // the route never mounts HomeView in this branch.
            store.injectState(state: .preview, isRestoring: false, isAccessDenied: true)
        case "awardsError", "awardsEmpty":
            // Signed-in session — Home mounts. The mock awards repo throws /
            // returns [] depending on the scenario (see `awardsBehavior`).
            store.injectState(state: .preview, isRestoring: false)
        default:
            assertionFailure("Unknown uiTestMode scenario: \(scenario)")
        }
    }

    /// Maps a UI-test scenario to the `MockAwardsRepository.Behavior` used in
    /// `saaApp.init`. Default = happy so existing scenarios (`signedIn`,
    /// `accessDenied`, etc.) keep loading the canned single-award roster.
    static func awardsBehavior(for scenario: String?) -> MockAwardsRepository.Behavior {
        switch scenario {
        case "awardsError": return .error
        case "awardsEmpty": return .empty
        default:            return .happy
        }
    }
    #endif
}
