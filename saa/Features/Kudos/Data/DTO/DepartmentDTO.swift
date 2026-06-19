import Foundation

// MARK: - DepartmentDTO

/// Wire-format mirror of the `public.departments` Postgres row.
///
/// Decoded by the Supabase SDK; never escapes the Data layer.
/// Column names match the migration `20260619104600_create_departments_table.sql`.
struct DepartmentDTO: Codable, Sendable {

    let id: UUID
    let code: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case code
        case name
    }
}
