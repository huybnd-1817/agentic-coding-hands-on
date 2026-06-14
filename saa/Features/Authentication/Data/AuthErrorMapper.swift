import Foundation
import GoogleSignIn
import Supabase

// MARK: - AuthErrorMapper

/// Maps any thrown `Error` into one of the four `AuthError` domain cases.
///
/// Lives in the Data layer so that SDK types (`GIDSignInError`, `Supabase.AuthError`,
/// `PostgrestError`) never cross into the Domain layer. The Domain enum `AuthError`
/// itself imports only `Foundation`.
///
/// Mapping precedence (top-wins):
///   1. Already an `AuthError` — return as-is.
///   2. `URLError` — network failure.
///   3. `GIDSignInError.canceled` — user cancelled.
///   4. Supabase `AuthError` with HTTP 401 / 403 / 422 — not authorized.
///   5. `PostgrestError` with code `"42501"` or "Account not authorized" — not authorized.
///   6. Everything else — `.unknown`.
enum AuthErrorMapper {

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
