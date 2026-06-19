import Foundation

// MARK: - KudosFilter

/// Narrows the kudos feed to a specific hashtag and/or department.
///
/// The VM owns the mutable filter state and passes an immutable snapshot
/// into repository calls. Both fields being nil means "show all" — use
/// `isEmpty` to short-circuit any filter-chip rendering logic.
struct KudosFilter: Equatable, Sendable {
    /// When non-nil, only kudos tagged with this hashtag are returned.
    var hashtagId: HashtagID?
    /// When non-nil, only kudos where the sender belongs to this department are returned.
    var departmentId: DepartmentID?

    // MARK: - Helper

    /// True when neither dimension is active (no filter applied).
    var isEmpty: Bool {
        hashtagId == nil && departmentId == nil
    }
}
