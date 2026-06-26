import Foundation

// MARK: - KudosRepositoryProtocol

/// Contract between the Domain layer and the Data layer for all Kudos operations.
///
/// Implementations live in the Data layer (e.g. `SupabaseKudosRepository`).
/// The VM depends on this protocol directly for single-operation calls;
/// multi-step orchestration goes through a dedicated UseCase.
///
/// All methods throw `KudosError`; SDK-specific errors are mapped in the Data
/// layer before surfacing here so this protocol remains free of Supabase types.
protocol KudosRepositoryProtocol: Sendable {

    /// Fetches the top kudos by heart count for the highlight carousel (≤5 items).
    ///
    /// - Parameter filter: Active hashtag / department filter; `.isEmpty` returns global top.
    /// - Returns: Up to 5 kudos sorted by `heartCount` descending.
    /// - Throws: `KudosError` on network or auth failure.
    func fetchHighlightKudos(filter: KudosFilter) async throws -> [Kudos]

    /// Fetches a paginated page of the kudos feed in reverse-chronological order.
    ///
    /// - Parameters:
    ///   - filter: Active hashtag / department filter.
    ///   - page: Zero-based page index.
    ///   - pageSize: Number of items per page (default 20 at call sites).
    /// - Throws: `KudosError` on network or auth failure.
    func fetchKudosFeed(filter: KudosFilter, page: Int, pageSize: Int) async throws -> [Kudos]

    /// Returns all available hashtags for the filter sheet.
    ///
    /// - Throws: `KudosError` on network or auth failure.
    func fetchHashtags() async throws -> [Hashtag]

    /// Returns all departments for the filter sheet.
    ///
    /// - Throws: `KudosError` on network or auth failure.
    func fetchDepartments() async throws -> [Department]

    /// Returns the aggregated kudos statistics for the currently authenticated user.
    ///
    /// - Throws: `KudosError.notAuthenticated` when no session exists.
    func fetchMyStats() async throws -> UserStats

    /// Returns the top-`limit` kudos gift recipients ranked by kudos received.
    ///
    /// Out-of-scope for the current plan (D.3 — reward_recipients table not yet
    /// provisioned). Implementations SHOULD return an empty array as a stub until
    /// the follow-up plan provisions the table.
    ///
    /// - Parameter limit: Maximum number of recipients to return.
    /// - Throws: `KudosError` on network or auth failure.
    func fetchTopGiftRecipients(limit: Int) async throws -> [KudosAuthor]

    /// Returns all active profiles minus the current user for the Create Kudo recipient picker.
    ///
    /// Fetches `profiles` ordered by name, excludes the current authenticated user.
    /// Results are cached in `CreateKudoViewModel` for the form lifetime.
    ///
    /// - Returns: Array of `ProfileSummary` sorted by display name.
    /// - Throws: `KudosError.notAuthenticated` when no session; `KudosError.network` on failure.
    func fetchEligibleRecipients() async throws -> [ProfileSummary]

    /// Returns the currently active event bonus, or nil when no bonus window is open.
    ///
    /// - Parameter now: The reference timestamp for window comparison (injected for testability).
    /// - Throws: `KudosError` on network or auth failure.
    func fetchActiveEventBonus(now: Date) async throws -> EventBonus?

    /// Records a heart reaction for the given kudos post.
    ///
    /// - Parameters:
    ///   - kudosId: The kudos being liked.
    ///   - multiplier: Heart multiplier from the active `EventBonus` (1 when no bonus).
    /// - Returns: The new `isLikedByMe` state (always `true` on success).
    /// - Throws: `KudosError.cannotLikeOwnKudos` when RLS rejects the request;
    ///   `KudosError.alreadyLiked` when a duplicate reaction is detected.
    func likeKudos(kudosId: KudosID, multiplier: Int) async throws -> Bool

    /// Removes the current user's heart reaction from the given kudos post.
    ///
    /// - Parameter kudosId: The kudos being unliked.
    /// - Returns: The new `isLikedByMe` state (always `false` on success).
    /// - Throws: `KudosError` on network or auth failure.
    func unlikeKudos(kudosId: KudosID) async throws -> Bool

    /// Returns the UUID of the currently authenticated user, or nil when unauthenticated.
    func currentUserId() async -> UUID?

    /// Persists a new kudos post and its attachments, then returns the created entity.
    ///
    /// The caller is responsible for:
    /// 1. Uploading images via `KudosImageUploaderProtocol` and populating
    ///    `request.attachments` with the resulting `KudosAttachment` values.
    /// 2. Passing a fully-validated `CreateKudoRequest` (via `CreateKudoValidator`).
    ///
    /// On success the returned `Kudos` is suitable for optimistic prepend into the
    /// feed via `kudosViewModel.prependKudos(_:)` (clarifications.md §post-submit).
    ///
    /// - Parameter request: Validated create-kudo payload.
    /// - Returns: The newly persisted `Kudos` entity.
    /// - Throws: `KudosError.createDenied` when RLS rejects the INSERT;
    ///   `KudosError.recipientSelfBlocked` when the server detects sender == recipient;
    ///   `KudosError.notAuthenticated` when the session has expired;
    ///   `KudosError.network` on connectivity failure.
    func createKudo(_ request: CreateKudoRequest) async throws -> Kudos
}
