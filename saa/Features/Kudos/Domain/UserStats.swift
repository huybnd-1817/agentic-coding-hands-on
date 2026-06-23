import Foundation

// MARK: - UserStats

/// Aggregated kudos statistics for the currently authenticated user.
///
/// Sourced from the `user_stats` Supabase view — a single row per user
/// that the VM polls on screen load to populate the personal stats section.
/// `.zero` is the safe placeholder before the first successful fetch, so the
/// stats section renders blank counts rather than stale or nil values.
struct UserStats: Sendable, Equatable {
    let userId: UUID
    /// Total kudos this user has received from others.
    let kudosReceivedCount: Int
    /// Total kudos this user has sent to others.
    let kudosSentCount: Int
    /// Aggregate heart-reactions received across all kudos sent to this user.
    let kudosHeartsReceived: Int
    /// Secret boxes the user has already opened.
    let secretBoxesOpened: Int
    /// Secret boxes waiting to be opened — drives the badge count on the button.
    let secretBoxesUnopened: Int
    /// Server-side timestamp of the last row update; used for cache invalidation.
    let updatedAt: Date

    // MARK: - Placeholder

    /// Safe zero-value used before the first remote fetch completes.
    ///
    /// `userId` is a sentinel value (all-zeros UUID). Callers that need to
    /// distinguish "not yet loaded" from "loaded with zeros" should check
    /// whether the VM's loading state is still `.idle` or `.loading`.
    static let zero = UserStats(
        userId: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
        kudosReceivedCount: 0,
        kudosSentCount: 0,
        kudosHeartsReceived: 0,
        secretBoxesOpened: 0,
        secretBoxesUnopened: 0,
        updatedAt: Date(timeIntervalSince1970: 0)
    )
}
