import Foundation
import GoogleSignIn
import UIKit

// MARK: - GoogleSignInService

/// Data-layer implementation of `GoogleSignInServiceProtocol` backed by the
/// GoogleSignIn SDK (`GIDSignIn`).
///
/// Both methods are `@MainActor`-isolated to satisfy the protocol contract and
/// because `GIDSignIn.sharedInstance.signIn(withPresenting:)` must be called
/// on the main thread.
struct GoogleSignInService: GoogleSignInServiceProtocol {

    // MARK: - Init

    init() {}
}

// MARK: - GoogleSignInServiceProtocol

extension GoogleSignInService {

    /// Presents the Google account chooser over `vc` and returns the resulting ID token.
    ///
    /// - Parameters:
    ///   - vc: The `UIViewController` over which the Google sign-in sheet is presented.
    ///   - hashedNonce: The SHA-256 hash of the raw nonce; embedded in the JWT `nonce` claim.
    /// - Returns: The ID token string from Google's response.
    /// - Throws: `AuthError.userCancelled` if the user dismisses the sheet;
    ///   `AuthError` wrapping the underlying SDK error on any other failure.
    @MainActor
    func obtainIDToken(presenting vc: UIViewController, hashedNonce: String) async throws -> String {
        let result = try await GIDSignIn.sharedInstance.signIn(
            withPresenting: vc,
            hint: nil,
            additionalScopes: nil,
            nonce: hashedNonce
        )
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.unknown(
                underlying: NSError(
                    domain: "GoogleSignInService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Missing ID token from Google"]
                )
            )
        }
        return idToken
    }

    /// Clears the local Google Sign-In session (in-memory token cache).
    ///
    /// Call during sign-out to ensure a fresh account chooser on the next attempt.
    @MainActor
    func clearLocalGoogleSession() {
        GIDSignIn.sharedInstance.signOut()
    }
}
