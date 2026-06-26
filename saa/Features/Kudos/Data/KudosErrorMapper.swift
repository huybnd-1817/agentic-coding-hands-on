import Foundation
import Supabase

// MARK: - KudosErrorMapper

/// Maps any thrown `Error` into one of the `KudosError` domain cases.
///
/// Lives in the Data layer so SDK types (`PostgrestError`, `StorageError`,
/// `Supabase.AuthError`, `URLError`) never cross into Domain. Mirrors the
/// pattern of `AwardsErrorMapper` and `AuthErrorMapper`.
///
/// Mapping precedence (top-wins):
///   1. Already a `KudosError` — return as-is.
///   2. `URLError` — `.network`.
///   3. `StorageError` (Supabase Storage SDK):
///        statusCode "413" → `.imageTooLarge`
///        statusCode "415" → `.unsupportedImageType`
///        statusCode "42501" → `.createDenied` (bucket RLS via PostgREST passthrough)
///        anything else    → `.attachmentUploadFailed`
///   4. `PostgrestError` code:
///        "42501" + message contains "self" → `.recipientSelfBlocked`
///        "42501"                           → pick context: like own = `.cannotLikeOwnKudos`,
///                                           create insert   = `.createDenied`
///        "23505" + message contains "kudos_reactions" → `.alreadyLiked`
///        "23505" (other)                              → `.createDenied` (duplicate kudos)
///        "PGRST116" (not found)                       → `.unknown`
///   5. Supabase `AuthError` HTTP 401 — `.notAuthenticated`.
///   6. Everything else — `.unknown(underlying:)`.
///
/// Note: Supabase Swift SDK exposes `PostgrestError.code` as a `String?`.
/// String matching is the only option without SDK changes — the fallback
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

        // 3. Supabase Storage errors.
        if let storageError = error as? StorageError {
            return mapStorageError(storageError)
        }

        // 4. PostgREST errors — inspect the Postgres error code.
        if let pgError = error as? PostgrestError {
            return mapPostgrestError(pgError)
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

    // MARK: - Private helpers

    private static func mapStorageError(_ error: StorageError) -> KudosError {
        switch error.statusCode {
        case "413":
            return .imageTooLarge
        case "415":
            return .unsupportedImageType
        case "42501":
            // Storage bucket RLS denial (object policy).
            return .createDenied
        default:
            #if DEBUG
            print("[Kudos] StorageError → \(error.statusCode ?? "nil"): \(error.message)")
            #endif
            return .attachmentUploadFailed
        }
    }

    private static func mapPostgrestError(_ error: PostgrestError) -> KudosError {
        let msg = error.message.lowercased()
        switch error.code {
        case "42501":
            // RLS insufficient_privilege.
            // "self" in the message indicates the self-recipient check function.
            if msg.contains("self") || msg.contains("recipient") {
                return .recipientSelfBlocked
            }
            // Distinguish like-own-kudos (kudos_reactions) vs create-kudos (kudos table).
            if msg.contains("reaction") {
                return .cannotLikeOwnKudos
            }
            return .createDenied
        case "23505":
            // Unique violation.
            if msg.contains("reaction") || msg.contains("kudos_reactions") {
                return .alreadyLiked
            }
            // Any other unique violation during creation.
            return .createDenied
        case "PGRST116":
            // Row not found (single() call returned no rows).
            return .unknown(underlying: error.message)
        default:
            #if DEBUG
            print("[Kudos] PostgrestError → \(error.code ?? "nil"): \(error.message)")
            #endif
            return .unknown(underlying: error.message)
        }
    }
}
