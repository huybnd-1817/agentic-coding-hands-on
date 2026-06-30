import Foundation

// MARK: - AwardsState

/// State machine for the Awards section on Home (TC_GUI_002–004, TC_FUN_003).
///
/// Replaces Track A's transient `HomeAwardsState` (which used `MockAward`).
/// The view layer is rebound to this enum at integration (Phase 07).
enum AwardsState: Equatable {

    /// Initial state + retry trigger.
    case loading

    /// Successful fetch yielding ≥1 award.
    case loaded([Award])

    /// Successful fetch yielding an empty list (TC_GUI_003).
    case empty

    /// Fetch failed (TC_GUI_004). UI surfaces a Retry button.
    case error(AwardsError)

    /// Convenience accessor — returns the loaded awards or `[]` for all other states.
    var loadedAwards: [Award] {
        if case .loaded(let awards) = self { return awards }
        return []
    }
}
