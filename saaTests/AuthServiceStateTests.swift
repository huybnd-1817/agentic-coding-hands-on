import XCTest
import Supabase
@testable import saa

// MARK: - AuthServiceStateTests
//
// Tests AuthService observable-state transitions that are reachable without UIKit.
// signInWithGoogle is intentionally excluded (requires UIViewController + Google sheet).
//
// All test methods are @MainActor because AuthService is @MainActor-isolated.

@MainActor
final class AuthServiceStateTests: XCTestCase {

    // MARK: - Init

    /// Fresh AuthService must begin with isRestoringSession == true so the splash
    /// gate in the root view blocks navigation until the first restoreSession() call.
    func testInitLeavesRestoringTrue() async {
        let service = AuthService(client: StubSupabase.makeUnreachable())
        XCTAssertTrue(service.isRestoringSession, "isRestoringSession must be true immediately after init")
        XCTAssertNil(service.session, "session must be nil before restoreSession() is called")
        XCTAssertFalse(service.isLoading, "isLoading must be false on init")
        XCTAssertNil(service.error, "error must be nil on init")
    }

    // MARK: - restoreSession failure path

    /// With an unreachable client (127.0.0.1:1) restoreSession() must:
    ///   - catch the connection error silently
    ///   - set session = nil
    ///   - set isRestoringSession = false
    /// The call must complete within 5 seconds.
    func testRestoreSessionFailureClearsSessionAndStopsRestoring() async throws {
        let service = AuthService(client: StubSupabase.makeUnreachable())

        // Confirm pre-condition: restoring starts as true.
        XCTAssertTrue(service.isRestoringSession)

        // Drive restoreSession — the unreachable client will throw, which is caught internally.
        let restoreTask = Task { await service.restoreSession() }

        // Wait with explicit 5-second deadline (acceptance gate: no test > 5s).
        let completed = await withTaskGroup(of: Bool.self) { group in
            group.addTask { await restoreTask.value; return true }
            group.addTask {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                return false
            }
            let first = await group.next()!
            group.cancelAll()
            return first
        }

        // Cancel the outer task as well — `group.cancelAll()` only reaches the
        // child tasks inside the group. Without this, if 127.0.0.1:1 hangs past
        // 5 s in CI, `restoreTask` keeps running and would mutate `service`
        // on the MainActor after this test body returns (cross-test ghost
        // mutation). restoreSession() catches CancellationError internally.
        restoreTask.cancel()

        XCTAssertTrue(completed, "restoreSession() must complete within 5 seconds against 127.0.0.1:1")
        XCTAssertNil(service.session, "session must be nil after failed restoreSession()")
        XCTAssertFalse(service.isRestoringSession, "isRestoringSession must be false after restoreSession() completes")
    }

    // MARK: - signOut clears state

    /// After injecting a session, signOut() must clear session and error regardless
    /// of whether the Supabase network call succeeds (best-effort per spec).
    func testSignOutClearsSessionAndError() async {
        let service = AuthService(client: StubSupabase.makeUnreachable())

        // Seed state via the DEBUG injection seam.
        let preloadedSession = makePreviewSession()
        service.injectState(
            session: preloadedSession,
            isLoading: false,
            isRestoringSession: false,
            error: saa.AuthError.networkUnavailable
        )

        XCTAssertNotNil(service.session, "Pre-condition: session should be set before signOut")
        XCTAssertNotNil(service.error, "Pre-condition: error should be set before signOut")

        await service.signOut()

        XCTAssertNil(service.session, "session must be nil after signOut()")
        XCTAssertNil(service.error, "error must be nil after signOut()")
    }

    // MARK: - injectState sanity (DEBUG seam)

    /// Validates that the #if DEBUG injectState seam writes through all four fields.
    /// This underpins the validity of the other tests that rely on it for state seeding.
    func testInjectStateAppliesAllFields() async {
        let service = AuthService(client: StubSupabase.makeUnreachable())
        let fakeSession = makePreviewSession()

        service.injectState(
            session: fakeSession,
            isLoading: true,
            isRestoringSession: true,
            error: saa.AuthError.notAuthorized
        )

        XCTAssertNotNil(service.session, "injectState should set session")
        XCTAssertTrue(service.isLoading, "injectState should set isLoading = true")
        XCTAssertTrue(service.isRestoringSession, "injectState should set isRestoringSession = true")
        if case .some(saa.AuthError.notAuthorized) = service.error {
            // pass
        } else {
            XCTFail("injectState should set error = .notAuthorized, got \(String(describing: service.error))")
        }
    }
}

// MARK: - Helpers

private extension AuthServiceStateTests {
    /// Minimal `Session` decoded from a JSON fixture — mirrors AuthServiceMocks.swift pattern.
    /// Not logged; contains only placeholder tokens.
    func makePreviewSession() -> Session {
        let json = """
        {
          "access_token": "test.access.token",
          "token_type": "bearer",
          "expires_in": 3600,
          "expires_at": 9999999999,
          "refresh_token": "test-refresh-token",
          "user": {
            "id": "00000000-0000-0000-0000-000000000002",
            "aud": "authenticated",
            "role": "authenticated",
            "email": "test@example.com",
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z",
            "app_metadata": {},
            "user_metadata": {}
          }
        }
        """.data(using: .utf8)!
        // Use the same decoder the SDK uses internally (convertFromSnakeCase + custom date strategy).
        // swiftlint:disable:next force_try
        return try! AuthClient.Configuration.jsonDecoder.decode(Session.self, from: json)
    }
}
