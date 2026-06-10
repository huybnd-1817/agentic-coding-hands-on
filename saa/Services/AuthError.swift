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

    /// Account rejected by the domain allow-list, or account is deleted/locked.
    /// Covers Postgres trigger rejection (code 42501) and Supabase 401/403.
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
        // 422 covers the Postgres-trigger rejection path: when enforce_sun_domain raises an
        // exception, GoTrue surfaces it as HTTP 422 Unprocessable Entity on signInWithIdToken.
        // API CONFIRM: supabase-swift v2.x — `AuthError.status` is `Int?` (optional). Verify
        // the exact type name and property path against the linked package version.
        if let supabaseAuthError = error as? Supabase.AuthError,
           let status = supabaseAuthError.status,
           [401, 403, 422].contains(status) {
            return .notAuthorized
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

        return .unknown(underlying: error)
    }
}
