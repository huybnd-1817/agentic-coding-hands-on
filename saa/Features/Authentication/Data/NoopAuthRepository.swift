#if DEBUG
import Foundation

// MARK: - NoopAuthRepository

/// No-op `AuthRepositoryProtocol` for UI-test scenarios and SwiftUI Previews.
/// All operations either return safe defaults or throw immediately so no real
/// network calls are ever made in test/preview contexts.
struct NoopAuthRepository: AuthRepositoryProtocol {
    func restoreSession() async throws -> UserSession? { nil }

    func signIn(idToken: String, rawNonce: String) async throws -> UserSession {
        throw AuthError.unknown(underlying: NSError(domain: "NoopAuthRepository", code: -1))
    }

    func signOut() async throws {}
}
#endif
