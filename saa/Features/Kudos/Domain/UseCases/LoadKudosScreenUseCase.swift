import Foundation

// MARK: - KudosScreenSnapshot

/// A complete, immutable snapshot of all data needed to render the Kudos tab.
///
/// Produced by `LoadKudosScreenUseCase.execute(...)` via parallel fetches and
/// consumed by `KudosViewModel` to drive the entire screen in a single state
/// assignment. Equatable so the VM can skip redundant view updates.
struct KudosScreenSnapshot: Sendable, Equatable {
    /// Up to 5 top kudos by heart count for the highlight carousel.
    let highlights: [Kudos]
    /// First page of the filtered kudos feed (reverse-chronological).
    let feed: [Kudos]
    /// All available hashtags for the filter sheet.
    let hashtags: [Hashtag]
    /// All departments for the filter sheet.
    let departments: [Department]
    /// Aggregated stats for the authenticated user.
    let stats: UserStats
    /// Top 10 gift recipients for the spotlight section (may be empty — D.3 stub).
    let topRecipients: [KudosAuthor]
    /// Currently active event bonus, or nil when no window is open.
    let activeBonus: EventBonus?
}

// MARK: - LoadKudosScreenUseCase

/// Parallelises all initial Kudos screen fetches into a single `KudosScreenSnapshot`.
///
/// Justified as a UseCase (per `code-standards.md` Rule #3) because it orchestrates
/// seven independent repository calls via `async let`, reducing VM noise to a single
/// `try await` call. If any fetch fails the whole snapshot throws — partial-load
/// resilience is out of scope for this plan.
struct LoadKudosScreenUseCase: Sendable {

    private let repository: any KudosRepositoryProtocol

    init(repository: some KudosRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Execute

    /// Runs all screen fetches in parallel and assembles a `KudosScreenSnapshot`.
    ///
    /// - Parameters:
    ///   - filter: Active hashtag / department filter passed to highlight and feed fetches.
    ///   - feedPage: Zero-based page index for the feed (default `0` for initial load).
    ///   - feedPageSize: Number of feed items per page (default `20`).
    ///   - now: Reference timestamp for event-bonus window comparison (injected for testability).
    /// - Returns: A fully populated `KudosScreenSnapshot`.
    /// - Throws: `KudosError` if any individual fetch fails.
    func execute(
        filter: KudosFilter,
        feedPage: Int = 0,
        feedPageSize: Int = 20,
        now: Date = Date()
    ) async throws -> KudosScreenSnapshot {
        async let highlights    = repository.fetchHighlightKudos(filter: filter)
        async let feed          = repository.fetchKudosFeed(filter: filter, page: feedPage, pageSize: feedPageSize)
        async let hashtags      = repository.fetchHashtags()
        async let departments   = repository.fetchDepartments()
        async let stats         = repository.fetchMyStats()
        async let topRecipients = repository.fetchTopGiftRecipients(limit: 10)
        async let activeBonus   = repository.fetchActiveEventBonus(now: now)

        return try await KudosScreenSnapshot(
            highlights:    highlights,
            feed:          feed,
            hashtags:      hashtags,
            departments:   departments,
            stats:         stats,
            topRecipients: topRecipients,
            activeBonus:   activeBonus
        )
    }
}
