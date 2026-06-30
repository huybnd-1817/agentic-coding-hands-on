import Combine
import Foundation

// MARK: - AwardDetailViewModel

/// Owns the currently-selected `Award` for the detail screen and exposes
/// a typed `select(_:)` action consumed by the award-selector dropdown.
///
/// Initialised from the composition root with the full awards list and an
/// initial selection. No repository call — data arrives pre-fetched from
/// `HomeViewModel` (shared store) or `AwardsViewContainer`.
@MainActor
final class AwardDetailViewModel: ObservableObject {

    // MARK: Published state

    @Published private(set) var selected: Award
    @Published private(set) var awards: [Award]

    // MARK: Init

    /// - Parameters:
    ///   - awards: Full ordered list of available awards (from the repository).
    ///   - initiallySelected: The award to highlight on first render.
    ///     Must be a member of `awards`; if not, the first element is used as fallback.
    init(awards: [Award], initiallySelected: Award) {
        self.awards = awards
        // Guard: ensure the initial selection is actually in the list.
        // If not found, fall back to the lowest-sortOrder member, then first, then
        // initiallySelected as a last resort (e.g. empty list cold-start via saaApp).
        self.selected = awards.first(where: { $0.id == initiallySelected.id })
            ?? awards.min(by: { $0.sortOrder < $1.sortOrder })
            ?? awards.first
            ?? initiallySelected
    }

    // MARK: Actions

    /// Updates `selected` to `award`. No-ops if `award` is not in `awards`.
    func select(_ award: Award) {
        guard awards.contains(where: { $0.id == award.id }) else { return }
        selected = award
    }

    /// Called by `AwardsViewContainer` when the parent's awards list changes
    /// (e.g. Home data refreshes). Updates the list and preserves the current
    /// selection when it is still present; otherwise falls back to
    /// `preferredCode` or the first item by sort order.
    func updateAwards(_ newAwards: [Award], preferredCode: String? = nil) {
        self.awards = newAwards
        // Keep existing selection if still valid.
        if let kept = newAwards.first(where: { $0.code == selected.code }) {
            self.selected = kept
            return
        }
        // Try preferred code fallback, then sort_order == 1, then first.
        if let preferred = preferredCode,
           let match = newAwards.first(where: { $0.code == preferred }) {
            self.selected = match
        } else if let first = newAwards.min(by: { $0.sortOrder < $1.sortOrder }) {
            self.selected = first
        }
    }
}
