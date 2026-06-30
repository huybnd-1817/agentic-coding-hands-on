import Foundation

// MARK: - KudosRepositoryProtocol

/// Domain ↔ Data contract for Kudos. SDK-specific errors are mapped to
/// `KudosError` in the Data layer so this protocol stays Supabase-free.
/// VM uses this directly for single-op calls; multi-step orchestration goes
/// through a UseCase.
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

    /// Stub — returns `[]` until the `reward_recipients` table is provisioned (D.3).
    func fetchTopGiftRecipients(limit: Int) async throws -> [KudosAuthor]

    /// Profiles for the Create Kudo recipient picker, excluding the current user.
    /// Results cached by `CreateKudoViewModel`.
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

    /// Persists a kudos + attachments. Caller is responsible for uploading
    /// images and validating the request first. Returned `Kudos` is suitable
    /// for optimistic prepend via `kudosViewModel.prependKudos(_:)`.
    /// - Throws: `KudosError.createDenied` (RLS), `.recipientSelfBlocked`,
    ///   `.notAuthenticated`, `.network`.
    func createKudo(_ request: CreateKudoRequest) async throws -> Kudos

    /// Resolves a storage path to a loadable URL. The `kudos-images` bucket
    /// is private — implementations MUST return a signed URL for bucket-
    /// relative paths; legacy fully-qualified `http(s)://` values are returned
    /// as-is. Nil → view renders a placeholder.
    func attachmentImageURL(forStoragePath storagePath: String) async -> URL?
}
