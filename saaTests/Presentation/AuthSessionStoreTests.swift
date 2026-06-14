import XCTest
@testable import saa

// MARK: - AuthSessionStoreTests
//
// Covers `AuthSessionStore` mutation semantics:
//   - initial state
//   - setState / setRestoring / clear
//   - AuthSessionClearable protocol conformance
//
// All tests are `async` because `AuthSessionStore` is `@MainActor`-isolated and
// its dealloc is enqueued to the main actor. Synchronous test methods exit before
// the dealloc runs, causing a SIGABRT race. Using `async` keeps the store alive
// for the full async test lifetime. (Same pattern documented in agent-memory:
// swiftui-testing-patterns, Rule 1.)

@MainActor
final class AuthSessionStoreTests: XCTestCase {

    // MARK: - Initial state

    func test_init_state_is_restoring_with_nil_state() async {
        let store = AuthSessionStore()
        XCTAssertTrue(store.isRestoring, "isRestoring must be true immediately after init")
        XCTAssertNil(store.state, "state must be nil before any session is set")
    }

    // MARK: - Mutations

    func test_setState_updates_state() async {
        let store = AuthSessionStore()
        store.setState(.preview)
        XCTAssertNotNil(store.state)
        XCTAssertEqual(store.state?.userID, UserSession.preview.userID)
    }

    func test_setState_nil_clears_state() async {
        let store = AuthSessionStore()
        store.setState(.preview)
        store.setState(nil)
        XCTAssertNil(store.state, "setState(nil) must clear the session")
    }

    func test_setRestoring_false_clears_flag() async {
        let store = AuthSessionStore()
        store.setRestoring(false)
        XCTAssertFalse(store.isRestoring)
    }

    func test_setRestoring_true_sets_flag() async {
        let store = AuthSessionStore()
        store.setRestoring(false)
        store.setRestoring(true)
        XCTAssertTrue(store.isRestoring)
    }

    func test_clear_resets_state_to_nil() async {
        let store = AuthSessionStore()
        store.setState(.preview)
        XCTAssertNotNil(store.state, "Pre-condition: state must be set before clear()")
        store.clear()
        XCTAssertNil(store.state, "clear() must set state to nil")
    }

    // MARK: - AuthSessionClearable conformance

    func test_AuthSessionStore_conforms_to_AuthSessionClearable() async {
        let store = AuthSessionStore()
        store.setState(.preview)
        let clearable: AuthSessionClearable = store   // compile-time conformance check
        clearable.clear()
        XCTAssertNil(store.state, "AuthSessionClearable.clear() must reset state")
    }
}
