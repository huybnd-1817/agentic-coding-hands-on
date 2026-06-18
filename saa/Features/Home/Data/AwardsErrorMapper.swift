import Foundation
import Supabase

// MARK: - AwardsErrorMapper

/// Maps any thrown `Error` into one of the four `AwardsError` domain cases.
///
/// Lives in the Data layer so SDK types (`PostgrestError`, `URLError`,
/// `Supabase.AuthError`) never cross into Domain. Mirrors the style of
/// `AuthErrorMapper`.
///
/// Mapping precedence (top-wins):
///   1. Already an `AwardsError` — return as-is.
///   2. `URLError` — `.network`.
///   3. `PostgrestError` with `42501` (insufficient privilege) — `.forbidden`.
///   4. Supabase `AuthError.api` 401 — `.unauthorized`, 403 — `.forbidden`.
///   5. Anything else — `.unknown(error)`.
enum AwardsErrorMapper {

    static func from(_ error: Error) -> AwardsError {
        if let mapped = error as? AwardsError {
            return mapped
        }

        if error is URLError {
            return .network
        }

        // Postgrest RLS rejection — code 42501 = "insufficient_privilege".
        if let pgError = error as? PostgrestError,
           pgError.code == "42501" {
            return .forbidden
        }

        // Supabase auth errors carry the upstream HTTP status on `.api`.
        if let supabaseAuthError = error as? Supabase.AuthError,
           case let .api(_, _, _, response) = supabaseAuthError {
            switch response.statusCode {
            case 401: return .unauthorized
            case 403: return .forbidden
            default:  break
            }
        }

        #if DEBUG
        print("[Awards] Unhandled fetch error → \(error)")
        #endif
        return .unknown(underlying: error)
    }
}
