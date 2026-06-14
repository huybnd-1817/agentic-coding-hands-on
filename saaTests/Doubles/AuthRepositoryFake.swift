import Foundation
@testable import saa

// MARK: - AuthRepositoryFake
//
// Configurable in-memory fake implementing `AuthRepositoryProtocol`.
// Per-method behavior (success / error), call counters, and last-arg recording.
//
// @unchecked Sendable: test doubles mutate properties from the test thread without
// synchronisation — intentional for ergonomics; never used in production code.

final class AuthRepositoryFake: AuthRepositoryProtocol, @unchecked Sendable {

    enum Behavior {
        case success(UserSession?)
        case error(Error)
    }

    // MARK: - Behavior configuration

    /// Defaults yield a successful no-session restore and a successful sign-in.
    var restoreBehavior: Behavior = .success(nil)
    var signInBehavior:  Behavior = .success(.preview)
    var signOutBehavior: Behavior = .success(nil)

    // MARK: - Call tracking

    private(set) var restoreCalls = 0
    private(set) var signInCalls  = 0
    private(set) var signOutCalls = 0
    private(set) var lastSignInIdToken:   String?
    private(set) var lastSignInRawNonce:  String?

    // MARK: - AuthRepositoryProtocol

    func restoreSession() async throws -> UserSession? {
        restoreCalls += 1
        switch restoreBehavior {
        case .success(let s): return s
        case .error(let e):   throw e
        }
    }

    func signIn(idToken: String, rawNonce: String) async throws -> UserSession {
        signInCalls += 1
        lastSignInIdToken  = idToken
        lastSignInRawNonce = rawNonce
        switch signInBehavior {
        case .success(let s): return s ?? .preview
        case .error(let e):   throw e
        }
    }

    func signOut() async throws {
        signOutCalls += 1
        if case .error(let e) = signOutBehavior { throw e }
    }
}
