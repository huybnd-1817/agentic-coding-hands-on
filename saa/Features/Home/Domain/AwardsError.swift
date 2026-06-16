import Foundation

// MARK: - AwardsError

/// Domain-level errors emitted by the Awards repository.
///
/// Four categories drive distinct router outcomes (see Phase 06 routing):
///   - `.unauthorized` → AppRouter clears session, lands on Login (TC_ACC_003).
///   - `.forbidden`    → AppRouter switches to Access Denied (TC_ACC_004).
///   - `.network`      → HomeViewModel surfaces retry-capable error state (TC_GUI_004 / TC_FUN_003).
///   - `.unknown`      → Same as `.network` for the UI; preserved for diagnostics.
///
/// SDK-aware mapping (`AwardsErrorMapper.from(_:)`) lives in the Data layer so
/// Supabase / Postgrest types never cross into Domain.
enum AwardsError: Error, Equatable {

    /// HTTP 401 — auth token expired or invalid.
    case unauthorized

    /// HTTP 403 — account restricted; route to Access Denied.
    case forbidden

    /// Transport-level failure (URLError, timeout). Retryable.
    case network

    /// Anything else. Carries the underlying error for `#if DEBUG` inspection.
    case unknown(underlying: Error)

    // MARK: Equatable

    /// Compares the case only — `.unknown` ignores its underlying error so that
    /// unit tests can pattern-match without the error needing to be `Equatable`.
    static func == (lhs: AwardsError, rhs: AwardsError) -> Bool {
        switch (lhs, rhs) {
        case (.unauthorized, .unauthorized): return true
        case (.forbidden,    .forbidden):    return true
        case (.network,      .network):      return true
        case (.unknown,      .unknown):      return true
        default:                             return false
        }
    }
}
