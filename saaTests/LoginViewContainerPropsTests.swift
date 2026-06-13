import XCTest
import Supabase
@testable import saa

// MARK: - LoginViewContainerPropsTests
//
// Tests `LoginViewContainer.makeProps(authService:)` — the pure, static prop-derivation
// helper extracted during the Phase 03 refactor of LoginViewContainer.
//
// No UIKit hosting is required: the helper is a pure Swift function that maps
// AuthService state → LoginViewProps without touching the SwiftUI view hierarchy.
//
// All tests run on @MainActor because AuthService is @MainActor-isolated and
// injectState() must be called on the actor it isolates.
//
// Implementation note: all services are created via `AuthService(client: StubSupabase.makeUnreachable())`
// rather than the `preview*` factory methods. The preview factories use a client that points to
// localhost:54321, which causes the Supabase SDK to subscribe to auth-state changes and kick off
// background async work. When that service is deallocated at the end of the test, Swift's MainActor
// dealloc trampoline can race with in-flight tasks, producing SIGABRT from libmalloc. Using the
// unreachable stub avoids all network I/O and keeps teardown deterministic.

@MainActor
final class LoginViewContainerPropsTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a fresh AuthService backed by a stub that never makes real network calls,
    /// then injects the supplied state synchronously before returning.
    private func makeService(
        session: Supabase.Session? = nil,
        isLoading: Bool = false,
        isRestoringSession: Bool = false,
        error: saa.AuthError? = nil
    ) -> AuthService {
        let service = AuthService(client: StubSupabase.makeUnreachable())
        service.injectState(
            session: session,
            isLoading: isLoading,
            isRestoringSession: isRestoringSession,
            error: error
        )
        return service
    }

    // MARK: - Loading state

    /// When the service is loading (sign-in in flight), props must reflect isLoading == true.
    func testPropsReflectLoading() async {
        let service = makeService(isLoading: true)
        let props = LoginViewContainer.makeProps(authService: service)

        XCTAssertTrue(props.isLoading, "isLoading must be true when authService.isLoading == true")
        XCTAssertNil(props.errorMessage, "errorMessage must be nil when no error is set")
    }

    // MARK: - Error message keys

    /// `.networkUnavailable` must surface the catalog key "login.error.network".
    func testPropsReflectErrorMessageKey() async {
        let service = makeService(error: .networkUnavailable)
        let props = LoginViewContainer.makeProps(authService: service)

        XCTAssertFalse(props.isLoading, "isLoading should be false when only error is set")
        XCTAssertEqual(
            props.errorMessage,
            "login.error.network",
            "errorMessage must equal 'login.error.network' for .networkUnavailable"
        )
    }

    /// `.userCancelled` must produce nil errorMessage — UI stays silent per clarifications.md.
    func testUserCancelledErrorYieldsNilMessage() async {
        let service = makeService(error: .userCancelled)
        let props = LoginViewContainer.makeProps(authService: service)

        XCTAssertNil(
            props.errorMessage,
            "errorMessage must be nil for .userCancelled (silent dismissal per spec)"
        )
    }

    /// `.notAuthorized` must surface the catalog key "login.error.notAuthorized".
    func testNotAuthorizedYieldsCorrectKey() async {
        let service = makeService(error: .notAuthorized)
        let props = LoginViewContainer.makeProps(authService: service)

        XCTAssertEqual(
            props.errorMessage,
            "login.error.notAuthorized",
            "errorMessage must equal 'login.error.notAuthorized' for .notAuthorized"
        )
    }

    /// `.unknown` must surface the catalog key "login.error.unknown".
    func testUnknownYieldsCorrectKey() async {
        let service = makeService(error: .unknown(underlying: NSError(domain: "test", code: 0)))
        let props = LoginViewContainer.makeProps(authService: service)

        XCTAssertEqual(
            props.errorMessage,
            "login.error.unknown",
            "errorMessage must equal 'login.error.unknown' for .unknown"
        )
    }

    // MARK: - Idle state

    /// Idle state (signed out, no error, not loading) yields both props at their zero values.
    func testIdleStateYieldsNoLoadingNoError() async {
        let service = makeService()  // all defaults: no session, no loading, no error
        let props = LoginViewContainer.makeProps(authService: service)

        XCTAssertFalse(props.isLoading, "isLoading must be false in idle/signed-out state")
        XCTAssertNil(props.errorMessage, "errorMessage must be nil in idle/signed-out state")
    }
}
