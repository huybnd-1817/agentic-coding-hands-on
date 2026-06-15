import Foundation
import UIKit

// MARK: - GoogleSignInServiceProtocol

// MARK: UIKit import justification
// `UIViewController` is required by `GIDSignIn.signIn(withPresenting:)` in the
// GoogleSignIn SDK. Hiding the presenter behind another Domain abstraction would
// add two layers of indirection with no testability gain — `obtainIDToken` is
// faked in unit tests regardless. This file is the single sanctioned UIKit
// exception in the Domain layer (Gate #1 allows UIKit in this file only).

/// Contract for the component that produces a Google ID token.
///
/// The implementation (`GIDSignInService` in the Data layer) calls the live
/// `GIDSignIn` SDK. Tests inject a fake that returns a deterministic token
/// without opening a browser sheet.
protocol GoogleSignInServiceProtocol: Sendable {

    /// Presents the Google account chooser and returns the resulting ID token.
    ///
    /// - Parameters:
    ///   - presenting: The `UIViewController` over which the sign-in sheet is presented.
    ///   - hashedNonce: The SHA-256 hash of the raw nonce; embedded in the JWT `nonce` claim.
    /// - Returns: The ID token string from Google's response.
    /// - Throws: `AuthError.userCancelled` if the user dismisses the sheet;
    ///   `AuthError.networkUnavailable` on connectivity failure.
    @MainActor
    func obtainIDToken(presenting: UIViewController, hashedNonce: String) async throws -> String

    /// Clears the local Google Sign-In session (in-memory token cache).
    ///
    /// Must be called during sign-out to ensure a fresh account chooser appears
    /// on the next sign-in attempt.
    @MainActor
    func clearLocalGoogleSession()
}
