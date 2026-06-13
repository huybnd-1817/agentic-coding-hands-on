import Foundation
import GoogleSignIn
import Supabase

// MARK: - AuthError

/// Domain-level authentication errors surfaced to the UI layer.
///
/// Three display categories (per clarifications.md):
///   - Silent      → `.userCancelled`   (UI shows nothing)
///   - Network     → `.networkUnavailable`
///   - Rejection   → `.notAuthorized`   (domain, deleted, or locked accounts)
///   - Catch-all   → `.unknown`
enum AuthError: LocalizedError {

    /// User dismissed the Google sign-in sheet. UI should stay silent.
    case userCancelled

    /// No network path or a timeout occurred.
    case networkUnavailable

    /// Account is not allowed to sign in (deleted, locked, or otherwise rejected
    /// by Supabase / a Postgres policy). Covers Supabase 401/403/422.
    case notAuthorized

    /// An unexpected error that does not map to any specific category.
    case unknown(underlying: Error)

    // MARK: LocalizedError

    /// Resolves against the system locale (used by NSLog / OS error chains).
    /// UI layer should prefer `messageKey` so SwiftUI's `\.locale` environment honors the in-app language.
    var errorDescription: String? {
        guard let key = messageKey else { return nil }
        return String(localized: String.LocalizationValue(key))
    }

    /// Catalog key for the UI layer. Pass into `Text(LocalizedStringKey(...))` so
    /// the SwiftUI `\.locale` environment (set in `saaApp`) drives the displayed language.
    /// `nil` for `.userCancelled` — UI must suppress display when nil.
    var messageKey: String? {
        switch self {
        case .userCancelled:        return nil
        case .networkUnavailable:   return "login.error.network"
        case .notAuthorized:        return "login.error.notAuthorized"
        case .unknown:              return "login.error.unknown"
        }
    }
}

// MARK: - AuthError.from(_:)

extension AuthError {

    /// Maps any thrown `Error` into one of the four `AuthError` cases.
    ///
    /// Mapping precedence (top-wins):
    ///   1. Already an `AuthError` — return as-is.
    ///   2. `URLError` — network failure.
    ///   3. `GIDSignInError.canceled` — user cancelled.
    ///   4. Supabase `AuthError` with HTTP 401 / 403 — not authorized.
    ///   5. `PostgrestError` with code `"42501"` or "Account not authorized" — not authorized.
    ///   6. Everything else — `.unknown`.
    static func from(_ error: Error) -> AuthError {
        // Pass-through if already mapped.
        if let authError = error as? AuthError {
            return authError
        }

        // Network failures.
        if error is URLError {
            return .networkUnavailable
        }

        // Google SDK cancellation.
        // API CONFIRM: GIDSignInError.canceled is the documented cancel code in
        // GoogleSignIn-iOS ≥ 7.x. Verify against the actual SDK enum when resolving
        // the SPM dependency.
        if let gidError = error as? GIDSignInError,
           gidError.code == .canceled {
            return .userCancelled
        }

        // Supabase AuthError: HTTP 401 / 403 / 422.
        // 422 covers any Postgres-trigger or policy rejection: when a server-side check
        // raises an exception, GoTrue surfaces it as HTTP 422 Unprocessable Entity.
        // In supabase-swift v2.x, AuthError is an enum; HTTP status is on the .api case's response.
        if let supabaseAuthError = error as? Supabase.AuthError,
           case let .api(message, _, _, response) = supabaseAuthError {
            #if DEBUG
            // Surface server-side cause to Xcode console — otherwise these get
            // flattened into a generic "unknown" message in the UI and devs
            // have no clue why sign-in failed (e.g. "Bad ID token" from an
            // audience mismatch when GOOGLE_CLIENT_ID is misconfigured).
            print("[AuthService] Supabase \(response.statusCode): \(message)")
            #endif
            if [401, 403, 422].contains(response.statusCode) {
                return .notAuthorized
            }
        }

        // PostgrestError: RLS / trigger violation.
        // API CONFIRM: supabase-swift v2.x exposes `PostgrestError` with a `code`
        // String property and a `message` String property. Verify property names
        // against the linked package version.
        if let pgError = error as? PostgrestError {
            if pgError.code == "42501"
                || pgError.message.contains("Account not authorized") {
                return .notAuthorized
            }
        }

        #if DEBUG
        print("[AuthService] Unhandled sign-in error → \(error)")
        #endif
        return .unknown(underlying: error)
    }
}
