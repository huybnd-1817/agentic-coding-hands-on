import Foundation

// MARK: - ToggleKudosReactionUseCase

/// Orchestrates toggling a heart reaction on a kudos post with event-bonus multiplier support.
///
/// Justified as a UseCase (per `code-standards.md` Rule #3) because it coordinates
/// two distinct domain concerns:
///   1. Reads the active `EventBonus` to derive the heart multiplier (1 or 2).
///   2. Calls the appropriate `like` or `unlike` repository method based on current state.
///
/// The `cannotLikeOwnKudos` guard is enforced at the RLS layer; this use case
/// lets that error propagate unmodified so the VM can display the correct message.
struct ToggleKudosReactionUseCase: Sendable {

    private let repository: any KudosRepositoryProtocol
    /// Injected clock for deterministic testing; defaults to `Date.init` in production.
    private let clock: @Sendable () -> Date

    init(
        repository: some KudosRepositoryProtocol,
        clock: @Sendable @escaping () -> Date = { Date() }
    ) {
        self.repository = repository
        self.clock = clock
    }

    // MARK: - Execute

    /// Toggles the heart reaction and returns the new `isLikedByMe` state.
    ///
    /// - Parameters:
    ///   - kudosId: The kudos post to react to.
    ///   - currentlyLiked: The caller's current knowledge of the liked state; drives
    ///     the like/unlike branch without an extra round-trip.
    /// - Returns: The new `isLikedByMe` value (`true` after like, `false` after unlike).
    /// - Throws: `KudosError.cannotLikeOwnKudos` when RLS rejects a self-like;
    ///   `KudosError.alreadyLiked` on duplicate; `KudosError.network` on connectivity failure.
    func execute(kudosId: KudosID, currentlyLiked: Bool) async throws -> Bool {
        let now = clock()
        let bonus = try await repository.fetchActiveEventBonus(now: now)
        let multiplier = bonus?.isActive(now: now) == true ? (bonus?.multiplier ?? 1) : 1

        if currentlyLiked {
            return try await repository.unlikeKudos(kudosId: kudosId)
        } else {
            return try await repository.likeKudos(kudosId: kudosId, multiplier: multiplier)
        }
    }
}
