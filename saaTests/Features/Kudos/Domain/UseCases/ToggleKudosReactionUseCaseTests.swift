import XCTest
@testable import saa

// MARK: - ToggleKudosReactionUseCaseTests
//
// Verifies the heart-toggle use case:
//   - currentlyLiked == false → likeKudos called with the multiplier derived
//     from the active EventBonus window (or 1 when inactive / nil / not in window).
//   - currentlyLiked == true  → unlikeKudos called (multiplier never matters).
//   - The injected clock is the reference timestamp for both the bonus fetch
//     and the `isActive(now:)` evaluation.

final class ToggleKudosReactionUseCaseTests: XCTestCase {

    // MARK: - Fixtures

    private let kudosId = UUID(uuidString: "00000000-0000-0000-0000-00000000B001")!
    private let bonusId = UUID(uuidString: "00000000-0000-0000-0000-00000000B002")!
    private let now     = Date(timeIntervalSince1970: 1_700_000_000)

    private func makeActiveBonus(multiplier: Int) -> EventBonus {
        EventBonus(
            id: bonusId,
            startsAt: now.addingTimeInterval(-10),
            endsAt:   now.addingTimeInterval(10),
            multiplier: multiplier,
            label: "Active"
        )
    }

    private func makeInactiveBonus(multiplier: Int) -> EventBonus {
        EventBonus(
            id: bonusId,
            startsAt: now.addingTimeInterval(100),
            endsAt:   now.addingTimeInterval(200),
            multiplier: multiplier,
            label: "Future"
        )
    }

    private func makeUseCase(repo: KudosRepositoryFake) -> ToggleKudosReactionUseCase {
        ToggleKudosReactionUseCase(repository: repo, clock: { self.now })
    }

    // MARK: - Like branch

    func testLike_noActiveBonus_usesMultiplierOne() async throws {
        let repo = KudosRepositoryFake()
        repo.bonusBehavior = .success(nil)
        repo.likeBehavior  = .success(true)

        let result = try await makeUseCase(repo: repo).execute(kudosId: kudosId, currentlyLiked: false)

        XCTAssertTrue(result)
        XCTAssertEqual(repo.likeCalls, 1)
        XCTAssertEqual(repo.unlikeCalls, 0)
        XCTAssertEqual(repo.lastLikeKudosId, kudosId)
        XCTAssertEqual(repo.lastLikeMultiplier, 1)
        XCTAssertEqual(repo.lastBonusNow, now)
    }

    func testLike_inactiveBonus_usesMultiplierOne() async throws {
        let repo = KudosRepositoryFake()
        repo.bonusBehavior = .success(makeInactiveBonus(multiplier: 2))
        repo.likeBehavior  = .success(true)

        _ = try await makeUseCase(repo: repo).execute(kudosId: kudosId, currentlyLiked: false)

        XCTAssertEqual(repo.lastLikeMultiplier, 1, "Inactive bonus must NOT contribute its multiplier")
    }

    func testLike_activeBonus_usesBonusMultiplier() async throws {
        let repo = KudosRepositoryFake()
        repo.bonusBehavior = .success(makeActiveBonus(multiplier: 2))
        repo.likeBehavior  = .success(true)

        _ = try await makeUseCase(repo: repo).execute(kudosId: kudosId, currentlyLiked: false)

        XCTAssertEqual(repo.lastLikeMultiplier, 2)
    }

    func testLike_repoThrows_propagates() async {
        let repo = KudosRepositoryFake()
        repo.bonusBehavior = .success(nil)
        repo.likeBehavior  = .error(.cannotLikeOwnKudos)

        do {
            _ = try await makeUseCase(repo: repo).execute(kudosId: kudosId, currentlyLiked: false)
            XCTFail("Expected throw")
        } catch let error as KudosError {
            XCTAssertEqual(error, .cannotLikeOwnKudos)
        } catch {
            XCTFail("Unexpected error type")
        }
    }

    // MARK: - Unlike branch

    func testUnlike_callsUnlikeIgnoringMultiplier() async throws {
        let repo = KudosRepositoryFake()
        repo.bonusBehavior   = .success(makeActiveBonus(multiplier: 5))
        repo.unlikeBehavior  = .success(false)

        let result = try await makeUseCase(repo: repo).execute(kudosId: kudosId, currentlyLiked: true)

        XCTAssertFalse(result)
        XCTAssertEqual(repo.unlikeCalls, 1)
        XCTAssertEqual(repo.likeCalls, 0)
        XCTAssertEqual(repo.lastUnlikeKudosId, kudosId)
    }

    func testUnlike_bonusFetchFailure_propagates() async {
        let repo = KudosRepositoryFake()
        // The use case fetches the bonus first regardless of branch, so a bonus
        // failure must surface even on the unlike path.
        repo.bonusBehavior = .error(.network)

        do {
            _ = try await makeUseCase(repo: repo).execute(kudosId: kudosId, currentlyLiked: true)
            XCTFail("Expected throw")
        } catch let error as KudosError {
            XCTAssertEqual(error, .network)
        } catch {
            XCTFail("Unexpected error type")
        }
    }
}
