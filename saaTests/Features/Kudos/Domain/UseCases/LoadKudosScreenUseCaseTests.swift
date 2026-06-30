import XCTest
@testable import saa

// MARK: - LoadKudosScreenUseCaseTests
//
// Verifies the parallel-fetch snapshot assembly:
//   - All seven repo methods are called with the provided filter / page args.
//   - The resulting `KudosScreenSnapshot` aggregates every response unchanged.
//   - The injected `now` is threaded to `fetchActiveEventBonus`.
//   - Any single repo failure surfaces as a thrown `KudosError`.

final class LoadKudosScreenUseCaseTests: XCTestCase {

    // MARK: - Fixtures

    private let kudosId   = UUID(uuidString: "00000000-0000-0000-0000-00000000A001")!
    private let hashtagId = UUID(uuidString: "00000000-0000-0000-0000-00000000A002")!
    private let deptId    = UUID(uuidString: "00000000-0000-0000-0000-00000000A003")!
    private let userId    = UUID(uuidString: "00000000-0000-0000-0000-00000000A004")!
    private let bonusId   = UUID(uuidString: "00000000-0000-0000-0000-00000000A005")!
    private let now       = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeKudos(heart: Int = 5) -> Kudos {
        Kudos(
            id: kudosId,
            sender: KudosAuthor(userId: userId, displayName: "S", employeeCode: nil, avatarURL: nil, departmentId: nil, kudosReceivedCount: 0),
            recipient: KudosAuthor(userId: UUID(), displayName: "R", employeeCode: nil, avatarURL: nil, departmentId: nil, kudosReceivedCount: 0),
            title: "T", message: "M",
            isAnonymous: false, anonymousNickname: nil,
            hashtags: [], attachments: [],
            heartCount: heart, isLikedByMe: false, canLike: true,
            shareURL: nil, createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    private func makeStats() -> UserStats {
        UserStats(
            userId: userId,
            kudosReceivedCount: 7,
            kudosSentCount: 3,
            kudosHeartsReceived: 21,
            secretBoxesOpened: 1,
            secretBoxesUnopened: 2,
            updatedAt: Date(timeIntervalSince1970: 1)
        )
    }

    private func makeBonus() -> EventBonus {
        EventBonus(
            id: bonusId,
            startsAt: now.addingTimeInterval(-100),
            endsAt: now.addingTimeInterval(100),
            multiplier: 3,
            label: "Triple"
        )
    }

    // MARK: - Happy path

    func testExecute_aggregatesAllRepoResponses() async throws {
        let repo = KudosRepositoryFake()
        let kudos = makeKudos()
        let stats = makeStats()
        let bonus = makeBonus()
        let hashtag = Hashtag(id: hashtagId, tag: "#h")
        let dept    = Department(id: deptId, code: "CEV1", name: "CEV1 - Customer")
        let recip   = KudosAuthor(userId: UUID(), displayName: "Top", employeeCode: "X", avatarURL: nil, departmentId: nil, kudosReceivedCount: 100)

        repo.highlightBehavior   = .success([kudos])
        repo.feedBehavior        = .success([kudos, kudos])
        repo.hashtagsBehavior    = .success([hashtag])
        repo.departmentsBehavior = .success([dept])
        repo.statsBehavior       = .success(stats)
        repo.recipientsBehavior  = .success([recip])
        repo.bonusBehavior       = .success(bonus)

        let useCase = LoadKudosScreenUseCase(repository: repo)
        let filter  = KudosFilter(hashtagId: hashtagId, departmentId: deptId)

        let snapshot = try await useCase.execute(filter: filter, feedPage: 2, feedPageSize: 50, now: now)

        XCTAssertEqual(snapshot.highlights.map(\.id),    [kudosId])
        XCTAssertEqual(snapshot.feed.map(\.id),          [kudosId, kudosId])
        XCTAssertEqual(snapshot.hashtags,                [hashtag])
        XCTAssertEqual(snapshot.departments,             [dept])
        XCTAssertEqual(snapshot.stats,                   stats)
        XCTAssertEqual(snapshot.topRecipients,           [recip])
        XCTAssertEqual(snapshot.activeBonus,             bonus)

        XCTAssertEqual(repo.lastHighlightFilter, filter, "Filter must thread through to highlights")
        XCTAssertEqual(repo.lastFeedFilter,      filter, "Filter must thread through to feed")
        XCTAssertEqual(repo.lastFeedPage,        2)
        XCTAssertEqual(repo.lastFeedPageSize,    50)
        XCTAssertEqual(repo.lastBonusNow,        now,    "Injected clock must be passed to active-bonus fetch")
        XCTAssertEqual(repo.lastRecipientLimit,  10,     "Top recipients limit defaults to 10 per spec")
    }

    func testExecute_defaultArguments_useZeroPageAndTwentyPageSize() async throws {
        let repo = KudosRepositoryFake()
        let useCase = LoadKudosScreenUseCase(repository: repo)

        _ = try await useCase.execute(filter: KudosFilter())

        XCTAssertEqual(repo.lastFeedPage,     0)
        XCTAssertEqual(repo.lastFeedPageSize, 20)
    }

    func testExecute_passesEmptyFilterThrough() async throws {
        let repo = KudosRepositoryFake()
        let useCase = LoadKudosScreenUseCase(repository: repo)

        _ = try await useCase.execute(filter: KudosFilter())

        XCTAssertTrue(repo.lastHighlightFilter?.isEmpty ?? false)
        XCTAssertTrue(repo.lastFeedFilter?.isEmpty ?? false)
    }

    // MARK: - Error propagation

    func testExecute_anyRepoFailure_throwsKudosError() async {
        let cases: [(label: String, mutate: (KudosRepositoryFake) -> Void)] = [
            ("highlight", { $0.highlightBehavior   = .error(.network) }),
            ("feed",      { $0.feedBehavior        = .error(.network) }),
            ("hashtags",  { $0.hashtagsBehavior    = .error(.network) }),
            ("depts",     { $0.departmentsBehavior = .error(.network) }),
            ("stats",     { $0.statsBehavior       = .error(.network) }),
            ("recips",    { $0.recipientsBehavior  = .error(.network) }),
            ("bonus",     { $0.bonusBehavior       = .error(.network) })
        ]

        for spec in cases {
            let repo = KudosRepositoryFake()
            spec.mutate(repo)

            let useCase = LoadKudosScreenUseCase(repository: repo)
            do {
                _ = try await useCase.execute(filter: KudosFilter())
                XCTFail("Expected throw when \(spec.label) errors")
            } catch let error as KudosError {
                XCTAssertEqual(error, .network, "\(spec.label) branch must surface .network")
            } catch {
                XCTFail("Unexpected error type \(error) from \(spec.label) branch")
            }
        }
    }
}
