import XCTest
@testable import saa

// MARK: - KudosViewModelLikeSyncDetailTests
//
// The detail screen never owns its own list — it mutates the same shared
// `Kudos` object through `vm.toggleLike(id)`. This test seeds the SAME id
// in `feed`, `allFeed`, and `highlights`, then asserts the like flips in
// all three (the invariant the detail screen relies on for back-pop sync).

@MainActor
final class KudosViewModelLikeSyncDetailTests: XCTestCase {

    // MARK: - Helpers

    private func makeVM() -> (vm: KudosViewModel, repo: KudosRepositoryFake) {
        let repo = KudosRepositoryFake()
        let loadUseCase   = LoadKudosScreenUseCase(repository: repo)
        let toggleUseCase = ToggleKudosReactionUseCase(repository: repo, clock: { Date(timeIntervalSince1970: 0) })
        let vm = KudosViewModel(
            loadUseCase: loadUseCase,
            toggleReactionUseCase: toggleUseCase,
            clipboard: KudosClipboardServiceFake(),
            repository: repo,
            clock: { Date(timeIntervalSince1970: 0) }
        )
        return (vm, repo)
    }

    private func makeKudos(id: KudosID, heartCount: Int = 0, isLikedByMe: Bool = false) -> Kudos {
        Kudos(
            id: id,
            sender:    KudosAuthor(userId: UUID(), displayName: "S", employeeCode: nil, avatarURL: nil, departmentId: nil, kudosReceivedCount: 0),
            recipient: KudosAuthor(userId: UUID(), displayName: "R", employeeCode: nil, avatarURL: nil, departmentId: nil, kudosReceivedCount: 0),
            title: "T", message: "M",
            isAnonymous: false, anonymousNickname: nil,
            hashtags: [], attachments: [],
            heartCount: heartCount, isLikedByMe: isLikedByMe, canLike: true,
            shareURL: nil, createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    // MARK: - Tri-list sync invariant

    func test_toggleLike_kudosPresentInFeedAllFeedAndHighlights_updatesAllThree() async {
        let (vm, repo) = makeVM()
        repo.likeBehavior = .success(true)

        let id = UUID()
        let kudos = makeKudos(id: id, heartCount: 7, isLikedByMe: false)
        vm.feed       = [kudos]
        vm.allFeed    = [kudos]
        vm.highlights = [kudos]

        await vm.toggleLike(id)

        XCTAssertEqual(vm.feed.first?.isLikedByMe,       true)
        XCTAssertEqual(vm.allFeed.first?.isLikedByMe,    true)
        XCTAssertEqual(vm.highlights.first?.isLikedByMe, true)
        XCTAssertEqual(vm.feed.first?.heartCount,       8)
        XCTAssertEqual(vm.allFeed.first?.heartCount,    8)
        XCTAssertEqual(vm.highlights.first?.heartCount, 8)
    }

    func test_toggleLike_rollbackOnError_restoresAllThree() async {
        let (vm, repo) = makeVM()
        repo.likeBehavior = .error(.network)

        let id = UUID()
        let kudos = makeKudos(id: id, heartCount: 3, isLikedByMe: false)
        vm.feed       = [kudos]
        vm.allFeed    = [kudos]
        vm.highlights = [kudos]

        await vm.toggleLike(id)

        XCTAssertEqual(vm.feed.first?.isLikedByMe,       false)
        XCTAssertEqual(vm.allFeed.first?.isLikedByMe,    false)
        XCTAssertEqual(vm.highlights.first?.isLikedByMe, false)
        XCTAssertEqual(vm.feed.first?.heartCount,        3)
        XCTAssertEqual(vm.allFeed.first?.heartCount,     3)
        XCTAssertEqual(vm.highlights.first?.heartCount,  3)
    }
}
