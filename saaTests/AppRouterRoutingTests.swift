import XCTest
@testable import saa

// MARK: - AppRouterRoutingTests
//
// Verifies that `AppRouter` mounts the correct child view for each `AuthSessionStore`
// state. Tests consume `AppRouter.activeRoute(for:)` — the same expression
// `AppRouter.body` switches on. Any change to the routing logic must touch that
// function, which the tests assert against.
//
// Why not UIHostingController + accessibilityIdentifier traversal?
//   Tried first; failed. SwiftUI's accessibility commit pass does not run
//   synchronously in a unit-test host process (no active CADisplayLink), so
//   `.accessibilityIdentifier` is not visible on the UIKit backing tree.
//   Phase 05's XCUITest E2E suite exercises the live a11y IDs.

@MainActor
final class AppRouterRoutingTests: XCTestCase {

    // MARK: - Helpers: store factories

    private func makeRestoringStore() -> AuthSessionStore {
        let store = AuthSessionStore()
        store.injectState(state: nil, isRestoring: true)
        return store
    }

    private func makeSignedInStore() -> AuthSessionStore {
        let store = AuthSessionStore()
        store.injectState(state: .preview, isRestoring: false)
        return store
    }

    private func makeSignedOutStore() -> AuthSessionStore {
        let store = AuthSessionStore()
        store.injectState(state: nil, isRestoring: false)
        return store
    }

    // MARK: - Test cases

    /// While `isRestoring == true`, AppRouter must take the spinner branch.
    func testRouterShowsSpinnerWhileRestoring() async {
        let store = makeRestoringStore()
        XCTAssertEqual(
            AppRouter.activeRoute(for: store),
            .spinner,
            "Expected .spinner route when isRestoring == true"
        )
    }

    /// When a valid session exists and restore is complete, AppRouter must take the home branch.
    func testRouterShowsHomeWhenSessionPresent() async {
        let store = makeSignedInStore()
        XCTAssertEqual(
            AppRouter.activeRoute(for: store),
            .home,
            "Expected .home route when state != nil && !isRestoring"
        )
    }

    /// When signed out (no session, not restoring), AppRouter must take the login branch.
    func testRouterShowsLoginWhenSignedOut() async {
        let store = makeSignedOutStore()
        XCTAssertEqual(
            AppRouter.activeRoute(for: store),
            .login,
            "Expected .login route when state == nil && !isRestoring"
        )
    }
}
