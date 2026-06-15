import Foundation
import UIKit

// MARK: - SignInWithGoogleUseCase

// MARK: UIKit import justification
// `UIViewController` appears only as a parameter type forwarded to
// `GoogleSignInServiceProtocol.obtainIDToken(presenting:)`. The Domain layer
// never constructs or subclasses UIKit types; the dependency flows through the
// injected protocol, which is faked in tests. This is a second sanctioned UIKit
// usage in Domain alongside `GoogleSignInServiceProtocol.swift`.

/// Orchestrates the full Google Sign-In → Supabase OIDC sign-in flow.
///
/// Steps:
///   1. Generate a raw nonce via `NonceGenerating`.
///   2. SHA-256-hash the nonce and pass it to `GoogleSignInServiceProtocol`.
///   3. Google embeds the hashed nonce in the returned JWT `nonce` claim.
///   4. Exchange the ID token + raw nonce with the repository to get a `UserSession`.
struct SignInWithGoogleUseCase: Sendable {

    private let repository: any AuthRepositoryProtocol
    private let googleService: any GoogleSignInServiceProtocol
    private let nonceGenerator: any NonceGenerating

    init(
        repository: some AuthRepositoryProtocol,
        googleService: some GoogleSignInServiceProtocol,
        nonceGenerator: some NonceGenerating = DefaultNonceGenerator()
    ) {
        self.repository = repository
        self.googleService = googleService
        self.nonceGenerator = nonceGenerator
    }

    /// Runs the sign-in flow and returns a `UserSession` on success.
    ///
    /// - Parameter vc: The presenting `UIViewController` for the Google sheet.
    /// - Returns: An authenticated `UserSession`.
    /// - Throws: `AuthError` on cancellation, network failure, or rejection.
    @MainActor
    func execute(presenting vc: UIViewController) async throws -> UserSession {
        let raw = nonceGenerator.random()
        let hashed = nonceGenerator.sha256(raw)
        let idToken = try await googleService.obtainIDToken(presenting: vc, hashedNonce: hashed)
        return try await repository.signIn(idToken: idToken, rawNonce: raw)
    }
}
