import Foundation

// MARK: - AuthRepositoryProtocol

/// Contract between the Domain layer and the Data layer for authentication operations.
///
/// Implementations live in the Data layer (e.g. `SupabaseAuthRepository`) and are
/// injected into use cases at composition time. The Domain layer never imports Supabase.
protocol AuthRepositoryProtocol: Sendable {

    /// Attempts to restore a previously persisted session from the local Keychain.
    ///
    /// - Returns: A valid `UserSession` if one exists, otherwise `nil`.
    /// - Throws: `AuthError` (or a wrapped SDK error) if the Keychain read fails.
    func restoreSession() async throws -> UserSession?

    /// Exchanges a Google ID token + raw nonce for a Supabase-backed `UserSession`.
    ///
    /// - Parameters:
    ///   - idToken: JWT returned by `GIDSignIn`.
    ///   - rawNonce: The unshashed nonce that was SHA-256-hashed before passing to Google.
    /// - Returns: A fresh `UserSession` on success.
    /// - Throws: `AuthError` on network failure, rejection, or token mismatch.
    func signIn(idToken: String, rawNonce: String) async throws -> UserSession

    /// Invalidates the current Supabase session (network + Keychain).
    ///
    /// - Throws: `AuthError` on network failure. Callers should treat this as best-effort
    ///   and clear local state regardless (see `SignOutUseCase`).
    func signOut() async throws
}
