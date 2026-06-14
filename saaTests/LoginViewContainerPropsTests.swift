import XCTest
@testable import saa

// MARK: - LoginViewContainerPropsTests
//
// Tests `LoginViewContainer.makeProps(viewModel:)` — the pure, static prop-derivation
// helper that maps `LoginViewModel` state → `LoginViewContainer.Props`.
//
// No UIKit hosting is required: the helper is a pure Swift function that maps
// view model state → Props without touching the SwiftUI view hierarchy.
//
// All tests run on @MainActor because LoginViewModel is @MainActor-isolated and
// injectState() must be called on the actor it isolates.
//
// Fakes: minimal private AuthRepositoryProtocol / GoogleSignInServiceProtocol
// conformances are defined at the bottom of this file. They are intentionally
// bare-minimum — Phase 05 will replace them with proper test doubles.

@MainActor
final class LoginViewContainerPropsTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a `LoginViewModel` backed by no-op fakes, then injects the supplied
    /// state synchronously before returning.
    private func makeViewModel(
        isLoading: Bool = false,
        errorMessage: String? = nil
    ) -> LoginViewModel {
        let store = AuthSessionStore()
        let vm = LoginViewModel(
            signInUseCase: SignInWithGoogleUseCase(
                repository: PropsTestStubRepository(),
                googleService: PropsTestStubGoogleService(),
                nonceGenerator: Nonce.default
            ),
            store: store
        )
        vm.injectState(isLoading: isLoading, errorMessage: errorMessage)
        return vm
    }

    // MARK: - Loading state

    /// When the view model is loading (sign-in in flight), props must reflect isLoading == true.
    func testPropsReflectLoading() async {
        let vm = makeViewModel(isLoading: true)
        let props = LoginViewContainer.makeProps(viewModel: vm)

        XCTAssertTrue(props.isLoading, "isLoading must be true when viewModel.isLoading == true")
        XCTAssertNil(props.errorMessage, "errorMessage must be nil when no error is set")
    }

    // MARK: - Error message keys

    /// `.networkUnavailable` must surface the catalog key "login.error.network".
    func testPropsReflectErrorMessageKey() async {
        let vm = makeViewModel(errorMessage: AuthError.networkUnavailable.messageKey)
        let props = LoginViewContainer.makeProps(viewModel: vm)

        XCTAssertFalse(props.isLoading, "isLoading should be false when only error is set")
        XCTAssertEqual(
            props.errorMessage,
            "login.error.network",
            "errorMessage must equal 'login.error.network' for .networkUnavailable"
        )
    }

    /// `.userCancelled` maps to nil messageKey — UI stays silent per clarifications.md.
    func testUserCancelledErrorYieldsNilMessage() async {
        let vm = makeViewModel(errorMessage: AuthError.userCancelled.messageKey)
        let props = LoginViewContainer.makeProps(viewModel: vm)

        XCTAssertNil(
            props.errorMessage,
            "errorMessage must be nil for .userCancelled (silent dismissal per spec)"
        )
    }

    /// `.notAuthorized` must surface the catalog key "login.error.notAuthorized".
    func testNotAuthorizedYieldsCorrectKey() async {
        let vm = makeViewModel(errorMessage: AuthError.notAuthorized.messageKey)
        let props = LoginViewContainer.makeProps(viewModel: vm)

        XCTAssertEqual(
            props.errorMessage,
            "login.error.notAuthorized",
            "errorMessage must equal 'login.error.notAuthorized' for .notAuthorized"
        )
    }

    /// `.unknown` must surface the catalog key "login.error.unknown".
    func testUnknownYieldsCorrectKey() async {
        let vm = makeViewModel(
            errorMessage: AuthError.unknown(underlying: NSError(domain: "test", code: 0)).messageKey
        )
        let props = LoginViewContainer.makeProps(viewModel: vm)

        XCTAssertEqual(
            props.errorMessage,
            "login.error.unknown",
            "errorMessage must equal 'login.error.unknown' for .unknown"
        )
    }

    /// Idle state (signed out, no error, not loading) yields both props at their zero values.
    func testIdleStateYieldsNoLoadingNoError() async {
        let vm = makeViewModel()
        let props = LoginViewContainer.makeProps(viewModel: vm)

        XCTAssertFalse(props.isLoading, "isLoading must be false in idle/signed-out state")
        XCTAssertNil(props.errorMessage, "errorMessage must be nil in idle/signed-out state")
    }
}

// MARK: - Private test fakes
// Minimal Phase-04-local stubs. Phase 05 will replace with proper test doubles.

private struct PropsTestStubRepository: AuthRepositoryProtocol {
    func restoreSession() async throws -> UserSession? { nil }
    func signIn(idToken: String, rawNonce: String) async throws -> UserSession {
        throw AuthError.unknown(underlying: NSError(domain: "stub", code: -1))
    }
    func signOut() async throws {}
}

private struct PropsTestStubGoogleService: GoogleSignInServiceProtocol {
    @MainActor
    func obtainIDToken(presenting vc: UIViewController, hashedNonce: String) async throws -> String {
        throw AuthError.unknown(underlying: NSError(domain: "stub", code: -1))
    }
    @MainActor
    func clearLocalGoogleSession() {}
}
