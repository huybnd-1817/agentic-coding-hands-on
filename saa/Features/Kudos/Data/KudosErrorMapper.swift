import Foundation
import Supabase

// MARK: - KudosErrorMapper

/// Maps any thrown `Error` into one of the `KudosError` domain cases.
///
/// Lives in the Data layer so SDK types (`PostgrestError`, `Supabase.AuthError`,
/// `URLError`) never cross into Domain. Mirrors the pattern of `AwardsErrorMapper`
/// and `AuthErrorMapper`.
///
/// Mapping precedence (top-wins):
///   1. Already a `KudosError` — return as-is.
///   2. `URLError` — `.network`.
///   3. `PostgrestError` code `42501` (RLS insufficient_privilege on own-kudos like) — `.cannotLikeOwnKudos`.
///   4. `PostgrestError` code `23505` (unique violation — duplicate reaction) — `.alreadyLiked`.
///   5. Supabase `AuthError` with HTTP 401 — `.notAuthenticated`.
///   6. Everything else — `.unknown(underlying:)`.
///
/// Note: Supabase Swift SDK exposes `PostgrestError.code` as a `String?`.
/// RLS violations surface as `42501`; unique-constraint violations as `23505`.
/// String matching is fragile if Postgres error codes change — the fallback
/// to `.unknown` ensures we never crash on unexpected codes.
enum KudosErrorMapper {

    static func from(_ error: Error) -> KudosError {
        // 1. Pass-through if already mapped.
        if let kudosError = error as? KudosError {
            return kudosError
        }

        // 2. Network / transport failures.
        if error is URLError {
            return .network
        }

        // 3 & 4. Postgrest errors — inspect the Postgres error code.
        if let pgError = error as? PostgrestError {
            switch pgError.code {
            case "42501":
                // RLS insufficient_privilege: the user attempted to like their own kudos.
                return .cannotLikeOwnKudos
            case "23505":
                // Unique violation: duplicate reaction (kudos_id, user_id) pair.
                return .alreadyLiked
            default:
                break
            }
        }

        // 5. Supabase auth errors — HTTP 401 signals an absent or expired session.
        if let supabaseAuthError = error as? Supabase.AuthError,
           case let .api(_, _, _, response) = supabaseAuthError {
            if response.statusCode == 401 {
                return .notAuthenticated
            }
        }

        #if DEBUG
        print("[Kudos] Unhandled error → \(error)")
        #endif
        return .unknown(underlying: String(describing: error))
    }
}
