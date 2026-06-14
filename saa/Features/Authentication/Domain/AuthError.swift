import Foundation

// MARK: - AuthError

/// Domain-level authentication errors surfaced to the UI layer.
///
/// Three display categories (per clarifications.md):
///   - Silent      → `.userCancelled`   (UI shows nothing)
///   - Network     → `.networkUnavailable`
///   - Rejection   → `.notAuthorized`   (domain, deleted, or locked accounts)
///   - Catch-all   → `.unknown`
///
/// SDK-aware mapping (`AuthError.from(_:)`) lives in `AuthErrorMapper` in the
/// Data layer, keeping this Domain type free of GoogleSignIn and Supabase imports.
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
