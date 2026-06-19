import Foundation

// MARK: - DepartmentID

typealias DepartmentID = UUID

// MARK: - Department

/// An organisational unit that can be used to filter the kudos feed.
///
/// `code` is the stable natural key used in analytics and URL construction
/// (e.g. `"CEV1"`). `name` is the localised display label shown in the filter
/// sheet; the data mapper sources this from the `departments.name` column.
struct Department: Identifiable, Hashable, Sendable {
    let id: DepartmentID
    /// Stable short code (e.g. `"CEV1"`). Unique across the departments table.
    let code: String
    /// Human-readable department name for display in the filter sheet.
    let name: String
}
