import Foundation

// MARK: - DepartmentMapper

/// Lifts a `DepartmentDTO` (Data) into a `Department` (Domain).
enum DepartmentMapper {

    static func from(_ dto: DepartmentDTO) -> Department {
        Department(id: dto.id, code: dto.code, name: dto.name)
    }
}
