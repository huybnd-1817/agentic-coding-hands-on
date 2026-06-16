import Foundation

// MARK: - AwardsRepositoryProtocol

/// Contract between the Domain layer and the Data layer for award fetching.
///
/// Implementations live in the Data layer (e.g. `SupabaseAwardsRepository`).
/// `HomeViewModel` depends on this protocol directly — no `GetAwardsUseCase`
/// is wrapped around it because that would be pure forwarding (forbidden by
/// `docs/system-architecture.md` Architectural Rule #1).
///
/// Implementations MUST:
///   - Return awards already sorted by `sortOrder` ascending.
///   - Throw `AwardsError` for known failure modes (401, 403, network).
protocol AwardsRepositoryProtocol: Sendable {

    /// Fetches the full list of award categories.
    ///
    /// - Returns: Awards sorted by `sortOrder` ascending. Empty array allowed
    ///   (drives the empty-state branch in `HomeViewModel` — TC_GUI_003).
    /// - Throws: `AwardsError` for 401 / 403 / network / unknown.
    func fetchAwards() async throws -> [Award]
}
