import XCTest
@testable import saa

// MARK: - KudosViewModelLikesAllFeedSyncTests
//
// Verifies that like/unlike mutations sync across both `feed` and `allFeed` arrays,
// ensuring like-state consistency between the Kudos tab preview and the All Kudos screen.
//
// The cross-array sync is implemented in KudosViewModel+Likes.updateKudos, which now
// walks both `feed` and `allFeed` to propagate like mutations everywhere (clarifications.md).

@MainActor
final class KudosViewModelLikesAllFeedSyncTests: XCTestCase {

    // MARK: - Helpers

    private func makeVM(
        repo: KudosRepositoryFake = KudosRepositoryFake(),
        clipboard: KudosClipboardServiceFake = KudosClipboardServiceFake()
    ) -> (vm: KudosViewModel, repo: KudosRepositoryFake, clipboard: KudosClipboardServiceFake) {
        let loadUseCase   = LoadKudosScreenUseCase(repository: repo)
        let toggleUseCase = ToggleKudosReactionUseCase(repository: repo, clock: { Date(timeIntervalSince1970: 0) })
        let vm = KudosViewModel(
            loadUseCase: loadUseCase,
            toggleReactionUseCase: toggleUseCase,
            clipboard: clipboard,
            repository: repo,
            clock: { Date(timeIntervalSince1970: 0) }
        )
        return (vm, repo, clipboard)
    }

    private func makeKudos(
        id: KudosID = UUID(),
        canLike: Bool = true,
        shareURL: URL? = nil,
        heartCount: Int = 0,
        isLikedByMe: Bool = false
    ) -> Kudos {
        Kudos(
            id: id,
            sender:    KudosAuthor(userId: UUID(), displayName: "S", employeeCode: nil, avatarURL: nil, departmentId: nil, kudosReceivedCount: 0),
            recipient: KudosAuthor(userId: UUID(), displayName: "R", employeeCode: nil, avatarURL: nil, departmentId: nil, kudosReceivedCount: 0),
            title: "T", message: "M",
            isAnonymous: false, anonymousNickname: nil,
            hashtags: [], photoURL: nil, attachments: [],
            heartCount: heartCount, isLikedByMe: isLikedByMe, canLike: canLike,
            shareURL: shareURL, createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    // MARK: - Cross-array like sync

    func test_toggleLike_onKudosPresentInBothFeedAndAllFeed_updatesBothArrays() async {
        let (vm, repo, _) = makeVM()
        repo.likeBehavior = .success(true)

        let kudosId = UUID()
        let kudos = makeKudos(id: kudosId, canLike: true, heartCount: 3, isLikedByMe: false)

        // Seed the same kudos in both arrays (simulating the kudos appearing on both tabs)
        vm.feed = [kudos]
        vm.allFeed = [kudos]

        // Toggle like
        await vm.toggleLike(kudosId)

        // Verify both arrays were updated
        guard let feedKudos = vm.feed.first else {
            XCTFail("Expected kudos in feed")
            return
        }
        guard let allFeedKudos = vm.allFeed.first else {
            XCTFail("Expected kudos in allFeed")
            return
        }

        XCTAssertTrue(feedKudos.isLikedByMe, "Feed kudos should be liked")
        XCTAssertEqual(feedKudos.heartCount, 4, "Feed kudos heart count should increment")
        XCTAssertTrue(allFeedKudos.isLikedByMe, "AllFeed kudos should be liked")
        XCTAssertEqual(allFeedKudos.heartCount, 4, "AllFeed kudos heart count should increment identically")
    }

    func test_toggleLike_onKudosOnlyInAllFeed_doesNotAffectFeed() async {
        let (vm, repo, _) = makeVM()
        repo.likeBehavior = .success(true)

        let kudosId = UUID()
        let kudos = makeKudos(id: kudosId, canLike: true, heartCount: 2, isLikedByMe: false)

        // Seed kudos only in allFeed, not in feed
        vm.feed = []
        vm.allFeed = [kudos]

        // Toggle like
        await vm.toggleLike(kudosId)

        // Verify feed is unchanged
        XCTAssertEqual(vm.feed.count, 0, "Feed should remain empty")

        // Verify allFeed was updated
        guard let allFeedKudos = vm.allFeed.first else {
            XCTFail("Expected kudos in allFeed")
            return
        }
        XCTAssertTrue(allFeedKudos.isLikedByMe, "AllFeed kudos should be liked")
        XCTAssertEqual(allFeedKudos.heartCount, 3, "AllFeed kudos heart count should increment")
    }

    func test_toggleLike_optimisticThenErrorRollback_restoresBothArrays() async {
        let (vm, repo, _) = makeVM()
        repo.likeBehavior = .error(.network)

        let kudosId = UUID()
        let kudos = makeKudos(id: kudosId, canLike: true, heartCount: 5, isLikedByMe: false)

        // Seed the same kudos in both arrays
        vm.feed = [kudos]
        vm.allFeed = [kudos]

        // Toggle like (will fail after optimistic mutation)
        await vm.toggleLike(kudosId)

        // Verify both arrays rolled back
        guard let feedKudos = vm.feed.first else {
            XCTFail("Expected kudos in feed")
            return
        }
        guard let allFeedKudos = vm.allFeed.first else {
            XCTFail("Expected kudos in allFeed")
            return
        }

        XCTAssertFalse(feedKudos.isLikedByMe, "Feed kudos should roll back to unliked")
        XCTAssertEqual(feedKudos.heartCount, 5, "Feed kudos heart count should roll back")
        XCTAssertFalse(allFeedKudos.isLikedByMe, "AllFeed kudos should roll back to unliked")
        XCTAssertEqual(allFeedKudos.heartCount, 5, "AllFeed kudos heart count should roll back identically")
        XCTAssertEqual(vm.currentToast, .likeFailed)
    }

    func test_toggleLike_unlikeOptimisticThenErrorRollback_restoresBothArrays() async {
        let (vm, repo, _) = makeVM()
        repo.unlikeBehavior = .error(.network)

        let kudosId = UUID()
        let kudos = makeKudos(id: kudosId, canLike: true, heartCount: 7, isLikedByMe: true)

        // Seed the same kudos in both arrays (already liked)
        vm.feed = [kudos]
        vm.allFeed = [kudos]

        // Toggle unlike (will fail after optimistic mutation)
        await vm.toggleLike(kudosId)

        // Verify both arrays rolled back to original state
        guard let feedKudos = vm.feed.first else {
            XCTFail("Expected kudos in feed")
            return
        }
        guard let allFeedKudos = vm.allFeed.first else {
            XCTFail("Expected kudos in allFeed")
            return
        }

        XCTAssertTrue(feedKudos.isLikedByMe, "Feed kudos should roll back to liked")
        XCTAssertEqual(feedKudos.heartCount, 7, "Feed kudos heart count should roll back")
        XCTAssertTrue(allFeedKudos.isLikedByMe, "AllFeed kudos should roll back to liked")
        XCTAssertEqual(allFeedKudos.heartCount, 7, "AllFeed kudos heart count should roll back identically")
        XCTAssertEqual(vm.currentToast, .likeFailed)
    }

    // MARK: - copyLink finds in allFeed fallback

    func test_copyLink_findsInAllFeed_asThirdFallback() async {
        let (vm, _, clip) = makeVM()
        let url = URL(string: "https://saa.example.com/kudos/allfeed")!
        let kudos = makeKudos(shareURL: url)

        // Seed only in allFeed (not highlights, not feed)
        vm.highlights = []
        vm.feed = []
        vm.allFeed = [kudos]

        vm.copyLink(kudos.id)

        XCTAssertEqual(clip.copiedTexts, [url.absoluteString])
        XCTAssertEqual(vm.currentToast, .linkCopied)
    }

    // MARK: - findKudos walks allFeed

    func test_findKudos_walksHighlights_feed_then_allFeed() async {
        let (vm, _, _) = makeVM()

        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        let kudos1 = makeKudos(id: id1)
        let kudos2 = makeKudos(id: id2)
        let kudos3 = makeKudos(id: id3)

        vm.highlights = [kudos1]
        vm.feed = [kudos2]
        vm.allFeed = [kudos3]

        // Each should be found in the correct array
        XCTAssertEqual(vm.findKudos(id: id1)?.id, id1, "Should find in highlights")
        XCTAssertEqual(vm.findKudos(id: id2)?.id, id2, "Should find in feed")
        XCTAssertEqual(vm.findKudos(id: id3)?.id, id3, "Should find in allFeed")

        // Highlights takes precedence: if same id in both arrays, highlights wins
        let sameId = UUID()
        let highlightKudos = makeKudos(id: sameId, heartCount: 100)
        let feedKudos = makeKudos(id: sameId, heartCount: 50)

        vm.highlights = [highlightKudos]
        vm.feed = [feedKudos]
        vm.allFeed = []

        let found = vm.findKudos(id: sameId)
        XCTAssertEqual(found?.heartCount, 100, "Highlights should take precedence")
    }
}
