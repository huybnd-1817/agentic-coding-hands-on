import Foundation

// MARK: - KudosError

/// Domain-level errors for the Kudos feature, surfaced to the VM and UI layer.
///
/// Mirrors the `AuthError` pattern: each case exposes a `messageKey` so
/// SwiftUI's `\.locale` environment drives the displayed copy rather than the
/// system locale. A `nil` key means the UI must stay silent.
///
/// SDK-aware mapping (`KudosErrorMapper`) lives in the Data layer; this enum
/// stays pure Foundation.
enum KudosError: LocalizedError {

    /// A network request failed or timed out.
    case network

    /// The operation requires an authenticated session that is absent or expired.
    case notAuthenticated

    /// The user attempted to like their own kudos post (enforced by RLS + domain).
    case cannotLikeOwnKudos

    /// The user has already reacted to this kudos and cannot react again.
    case alreadyLiked

    /// An unexpected error not covered by any specific case.
    ///
    /// `underlying` carries the original error description for logging; it is
    /// intentionally excluded from `Equatable` comparison so two `.unknown`
    /// values are considered equal regardless of their wrapped message.
    case unknown(underlying: String)

    // MARK: - LocalizedError

    /// Resolves against the system locale (used by OS error chains / logging).
    /// UI layer should prefer `messageKey` so the in-app language setting is honoured.
    var errorDescription: String? {
        guard let key = messageKey else { return nil }
        return String(localized: String.LocalizationValue(key))
    }

    /// Catalog key for the UI layer. Pass into `Text(LocalizedStringKey(...))` or
    /// a toast component so `\.locale` drives the language.
    var messageKey: String? {
        switch self {
        case .network:              return "kudos.error.network"
        case .notAuthenticated:     return "kudos.error.notAuthenticated"
        case .cannotLikeOwnKudos:   return "kudos.error.cannotLikeOwnKudos"
        case .alreadyLiked:         return "kudos.error.alreadyLiked"
        case .unknown:              return "kudos.error.unknown"
        }
    }
}

// MARK: - Equatable

extension KudosError: Equatable {
    static func == (lhs: KudosError, rhs: KudosError) -> Bool {
        switch (lhs, rhs) {
        case (.network, .network):                     return true
        case (.notAuthenticated, .notAuthenticated):   return true
        case (.cannotLikeOwnKudos, .cannotLikeOwnKudos): return true
        case (.alreadyLiked, .alreadyLiked):           return true
        case (.unknown, .unknown):                     return true  // ignore underlying
        default:                                       return false
        }
    }
}
