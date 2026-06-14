import Foundation
import Supabase

// MARK: - SupabaseAuthRepository

/// Data-layer implementation of `AuthRepositoryProtocol` backed by the Supabase SDK.
///
/// All SDK auth calls (`client.auth.*`) are confined to this file, satisfying Gate #4.
/// The default `SupabaseClient` is resolved inside the initialiser body rather than at
/// the call site, so `SupabaseClientProvider.shared` is touched only after the type-level
/// `static let` is safe to read.
struct SupabaseAuthRepository: AuthRepositoryProtocol {

    // MARK: - Properties

    let client: SupabaseClient

    // MARK: - Init

    init(client: SupabaseClient? = nil) {
        self.client = client ?? SupabaseClientProvider.shared
    }
}

// MARK: - AuthRepositoryProtocol

extension SupabaseAuthRepository {

    /// Reads the persisted JWT from Keychain via the Supabase SDK.
    ///
    /// Returns `nil` — rather than throwing — when no valid session exists (expired
    /// or absent token), so callers route the user to Login without surfacing an error.
    func restoreSession() async throws -> UserSession? {
        do {
            let session = try await client.auth.session
            return UserSessionMapper.toDomain(session)
        } catch {
            // No valid session — return nil so the caller routes to Login.
            return nil
        }
    }

    /// Exchanges a Google ID token + raw nonce for a Supabase `UserSession`.
    func signIn(idToken: String, rawNonce: String) async throws -> UserSession {
        let credentials = OpenIDConnectCredentials(
            provider: .google,
            idToken: idToken,
            nonce: rawNonce
        )
        let response = try await client.auth.signInWithIdToken(credentials: credentials)
        return UserSessionMapper.toDomain(response)
    }

    /// Invalidates the current Supabase session on the server and in Keychain.
    func signOut() async throws {
        try await client.auth.signOut()
    }
}
