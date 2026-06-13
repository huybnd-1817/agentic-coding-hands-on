import XCTest
import Supabase
@testable import saa

// MARK: - AppRouterRoutingTests
//
// Verifies that `AppRouter` mounts the correct child view for each `AuthService`
// state. Tests consume `AppRouter.activeRoute(for:)` — the same expression
// `AppRouter.body` switches on. Any change to the routing logic must touch that
// function, which the tests assert against.
//
// Why not UIHostingController + accessibilityIdentifier traversal?
//   Tried first; failed. SwiftUI's accessibility commit pass does not run
//   synchronously in a unit-test host process (no active CADisplayLink), so
//   `.accessibilityIdentifier` is not visible on the UIKit backing tree.
//   Phase 04's XCUITest E2E suite exercises the live a11y IDs.

// MARK: - AppRouterRoutingTests

@MainActor
final class AppRouterRoutingTests: XCTestCase {

    // MARK: - Helpers: service factories

    private func makeRestoringService() -> AuthService {
        let s = AuthService(client: StubSupabase.makeUnreachable())
        s.injectState(session: nil, isLoading: false, isRestoringSession: true)
        return s
    }

    private func makeSignedInService() -> AuthService {
        let s = AuthService(client: StubSupabase.makeUnreachable())
        s.injectState(session: makePreviewSession(), isLoading: false, isRestoringSession: false)
        return s
    }

    private func makeSignedOutService() -> AuthService {
        let s = AuthService(client: StubSupabase.makeUnreachable())
        s.injectState(session: nil, isLoading: false, isRestoringSession: false)
        return s
    }

    // MARK: - Test cases

    /// While `isRestoringSession == true`, AppRouter must take the spinner branch.
    func testRouterShowsSpinnerWhileRestoring() async {
        let service = makeRestoringService()
        XCTAssertEqual(
            AppRouter.activeRoute(for: service),
            .spinner,
            "Expected .spinner route when isRestoringSession == true"
        )
    }

    /// When a valid session exists and restore is complete, AppRouter must take the home branch.
    func testRouterShowsHomeWhenSessionPresent() async {
        let service = makeSignedInService()
        XCTAssertEqual(
            AppRouter.activeRoute(for: service),
            .home,
            "Expected .home route when session != nil && !isRestoringSession"
        )
    }

    /// When signed out (no session, not restoring), AppRouter must take the login branch.
    func testRouterShowsLoginWhenSignedOut() async {
        let service = makeSignedOutService()
        XCTAssertEqual(
            AppRouter.activeRoute(for: service),
            .login,
            "Expected .login route when session == nil && !isRestoringSession"
        )
    }

    // MARK: - Session fixture

    private func makePreviewSession() -> Session {
        let json = """
        {
          "access_token": "test.access.token",
          "token_type": "bearer",
          "expires_in": 3600,
          "expires_at": 9999999999,
          "refresh_token": "test-refresh-token",
          "user": {
            "id": "00000000-0000-0000-0000-000000000003",
            "aud": "authenticated",
            "role": "authenticated",
            "email": "router-test@example.com",
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z",
            "app_metadata": {},
            "user_metadata": {}
          }
        }
        """.data(using: .utf8)!
        // swiftlint:disable:next force_try
        return try! AuthClient.Configuration.jsonDecoder.decode(Session.self, from: json)
    }
}
