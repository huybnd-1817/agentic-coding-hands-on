import Foundation
@testable import saa

// MARK: - AwardsRepositoryFake
//
// Configurable in-memory fake implementing `AwardsRepositoryProtocol`.
// Per-call behavior (success / error), call counter.
//
// @unchecked Sendable: test doubles mutate properties from the test thread
// without synchronisation — intentional for ergonomics; never used in
// production code. Mirrors the convention from AuthRepositoryFake.

final class AwardsRepositoryFake: AwardsRepositoryProtocol, @unchecked Sendable {

    enum Behavior {
        case success([Award])
        case error(Error)
    }

    /// Default yields three awards in sort order — enough variety for VM
    /// loaded-state tests without each test needing to assemble its own fixtures.
    var fetchBehavior: Behavior = .success(AwardsRepositoryFake.defaultAwards)

    private(set) var fetchCalls = 0

    func fetchAwards() async throws -> [Award] {
        fetchCalls += 1
        switch fetchBehavior {
        case .success(let awards): return awards
        case .error(let error):    throw error
        }
    }

    // MARK: - Fixtures

    static let defaultAwards: [Award] = [
        Award(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            code: "top_talent",
            nameEN: "Top Talent",
            nameVI: "Top Talent",
            descriptionEN: "Best individual contributors.",
            descriptionVI: "Cá nhân xuất sắc.",
            thumbnailURL: nil,
            sortOrder: 1
        ),
        Award(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            code: "top_project",
            nameEN: "Top Project",
            nameVI: "Top Project",
            descriptionEN: "Most impactful projects.",
            descriptionVI: "Dự án có tác động lớn nhất.",
            thumbnailURL: nil,
            sortOrder: 2
        ),
        Award(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            code: "top_culture_fit",
            nameEN: "Top Culture Fit",
            nameVI: "Top Culture Fit",
            descriptionEN: "Best embodiment of Sun* values.",
            descriptionVI: "Văn hoá và giá trị cốt lõi.",
            thumbnailURL: nil,
            sortOrder: 3
        )
    ]
}
