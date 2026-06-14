import Combine
import Foundation
import GoogleSignIn
import Supabase

// MARK: - AuthService

/// Owns the full authentication lifecycle: session restore, Google Sign-In,
/// and sign-out. Designed to be injected into the SwiftUI environment as a
/// single source of truth for auth state.
///
/// Consumers observe `session`, `isLoading`, `error`, and `isRestoringSession`
/// to drive routing and UI state. All mutations happen on the MainActor.
@MainActor
final class AuthService: ObservableObject {

    // MARK: - Observed state

    /// Non-nil when a valid Supabase session exists.
    @Published private(set) var session: Session?

    /// `true` while a sign-in request is in flight. Used to disable the button
    /// and prevent double-taps (TC_LOGIN_FUN_008).
    @Published private(set) var isLoading: Bool = false

    /// Most recent auth error; `nil` after a successful operation or on cancellation.
    @Published private(set) var error: AuthError?

    /// `true` from init until the initial Keychain check completes at app launch
    /// (TC_LOGIN_ACC_002 / TC_LOGIN_FUN_012 / TC_LOGIN_FUN_013). Drives the
    /// splash/loading gate in the root view.
    @Published private(set) var isRestoringSession: Bool = true

    // MARK: - Private

    private let client: SupabaseClient

    // MARK: - Init

    init(client: SupabaseClient? = nil) {
        // Resolve the default inside the init body so the access to the
        // shared client happens in this MainActor-isolated context, not at
        // the (potentially nonisolated) call site.
        self.client = client ?? SupabaseClientProvider.shared
    }

    // MARK: - Session restore

    /// Call once at app launch (before presenting any navigation).
    ///
    /// Reads the persisted JWT from Keychain via the Supabase SDK. If the token
    /// is expired, the SDK silently clears it and throws — we catch that and set
    /// `session = nil` so the root router shows the Login screen.
    func restoreSession() async {
        isRestoringSession = true
        defer { isRestoringSession = false }
        do {
            // API CONFIRM: `client.auth.session` is a computed async property in
            // supabase-swift v2.x that throws if no valid session exists. Verify
            // the exact spelling against the resolved package version.
            let restored = try await client.auth.session
            self.session = restored
        } catch {
            // No valid session — show Login.
            self.session = nil
        }
    }

    // MARK: - Sign in

    /// Runs the full Google Sign-In → Supabase OIDC flow.
    ///
    /// - Parameter viewController: The presenting `UIViewController`. Typically
    ///   obtained via `UIApplication.shared.connectedScenes` in the root view
    ///   (Phase 06 wiring).
    ///
    /// Guard against concurrent taps: returns immediately if `isLoading` is
    /// already `true` (TC_LOGIN_FUN_008).
    func signInWithGoogle(presenting viewController: UIViewController) async {
        #if DEBUG
        // UI-test seam parity with saaApp.uiTestScenario():
        // when running under -uiTestMode the AuthService is already pre-populated
        // via injectState; invoking the real GIDSignIn would attempt a live Google
        // sheet in the simulator, which is non-deterministic and blocked by the
        // network-disabled smoke run. Early-return keeps the button tappable for
        // the testGoogleButtonTapDoesNotCrash assertion without calling any SDK.
        if CommandLine.arguments.contains("-uiTestMode") { return }
        #endif
        guard !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // 1. Generate nonce pair.
            let rawNonce = Nonce.random()
            let hashedNonce = Nonce.sha256(rawNonce)

            // 2. Present Google account chooser. No domain pre-filter — any Google
            //    account is accepted.
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: viewController,
                hint: nil,
                additionalScopes: nil,
                nonce: hashedNonce
            )

            // 3. Extract ID token.
            guard let idToken = result.user.idToken?.tokenString else {
                self.error = .unknown(
                    underlying: NSError(
                        domain: "AuthService",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Missing ID token from Google"]
                    )
                )
                return
            }

            // 4. Exchange ID token with Supabase.
            //
            // API CONFIRM: `OpenIDConnectCredentials` is the struct used in
            // supabase-swift v2.x for `signInWithIdToken`. Constructor signature:
            //   .init(provider: .google, idToken: String, nonce: String)
            // Verify against the resolved package; the type may be named
            // `IDTokenCredentials` or similar in some release candidates.
            let credentials = OpenIDConnectCredentials(
                provider: .google,
                idToken: idToken,
                nonce: rawNonce
            )
            let authResponse = try await client.auth.signInWithIdToken(credentials: credentials)
            self.session = authResponse

        } catch let err {
            self.error = AuthErrorMapper.from(err)
        }
    }

    // MARK: - Sign out

    /// Signs out from both Supabase and the Google SDK, then clears local state.
    ///
    /// Best-effort: even if the Supabase network call fails, local session state
    /// is cleared so the user is returned to the Login screen (TC_LOGIN_FUN_014).
    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            // Network or server error — intentionally swallowed.
            // Local state is cleared regardless (see below).
        }
        GIDSignIn.sharedInstance.signOut()
        self.session = nil
        self.error = nil
    }
}

#if DEBUG
extension AuthService {
    /// Directly sets observable properties for SwiftUI Previews and unit tests.
    /// DEBUG-only — defined in the same file as `AuthService` so it can write
    /// the `private(set)` properties without widening their production setter.
    func injectState(
        session: Session? = nil,
        isLoading: Bool = false,
        isRestoringSession: Bool = false,
        error: AuthError? = nil
    ) {
        self.session = session
        self.isLoading = isLoading
        self.isRestoringSession = isRestoringSession
        self.error = error
    }
}
#endif
