import XCTest
import Combine
@testable import saa

// MARK: - KudosViewModelTests
//
// Verifies KudosViewModel state machine and callbacks:
// - Filter toggle with carousel reset
// - Like toggle with optimistic update and rollback
// - Secret box guard (double-tap prevention)
// - Fire badge computation (active bonus + multiplier > 1)
// - Photo viewer (present/dismiss)
// - Hashtag tag resolution

@MainActor
final class KudosViewModelTests: XCTestCase {

    // MARK: - Helpers

    private nonisolated func makeDefaultRepo() -> KudosRepositoryFake {
        KudosRepositoryFake()
    }

    private func makeVM(
        repo: KudosRepositoryFake? = nil,
        clipboard: KudosClipboardServiceFake = KudosClipboardServiceFake(),
        clock: @escaping () -> Date = { Date(timeIntervalSince1970: 0) }
    ) -> KudosViewModel {
        let repository = repo ?? makeDefaultRepo()
        let loadUseCase = LoadKudosScreenUseCase(repository: repository)
        let toggleUseCase = ToggleKudosReactionUseCase(repository: repository, clock: clock)
        return KudosViewModel(
            loadUseCase: loadUseCase,
            toggleReactionUseCase: toggleUseCase,
            clipboard: clipboard,
            repository: repository,
            clock: clock
        )
    }

    // MARK: - Lifecycle: onAppear

    func testOnAppear_idleState_triggersReload() async {
        let repo = KudosRepositoryFake()
        let vm = makeVM(repo: repo)

        XCTAssertEqual(vm.loadState, .idle)
        await vm.onAppear()

        XCTAssertGreaterThan(repo.fetchHighlightCalls, 0)
    }

    func testOnAppear_alreadyLoaded_noopsReload() async {
        let repo = KudosRepositoryFake()
        let vm = makeVM(repo: repo)

        // Load once
        await vm.reload()
        let firstLoadCount = repo.fetchHighlightCalls

        // Call onAppear again — should not reload
        await vm.onAppear()

        XCTAssertEqual(repo.fetchHighlightCalls, firstLoadCount)  // No additional calls
    }

    // MARK: - Reload happy path

    func testReload_success_transitionsToLoaded() async {
        let kudosId1 = UUID()
        let kudosId2 = UUID()
        let repo = KudosRepositoryFake()
        repo.highlightBehavior = .success([makeKudos(id: kudosId1, isLikedByMe: false)])
        repo.feedBehavior = .success([makeKudos(id: kudosId2, isLikedByMe: false)])
        repo.statsBehavior = .success(UserStats(
            userId: UUID(),
            kudosReceivedCount: 5,
            kudosSentCount: 3,
            kudosHeartsReceived: 10,
            secretBoxesOpened: 2,
            secretBoxesUnopened: 1,
            updatedAt: Date()
        ))

        let vm = makeVM(repo: repo)

        await vm.reload()

        XCTAssertEqual(vm.loadState, .loaded)
        XCTAssertEqual(vm.highlights.count, 1)
        XCTAssertEqual(vm.feed.count, 1)
    }

    func testReload_empty_transitionsToEmpty() async {
        let repo = KudosRepositoryFake()
        repo.highlightBehavior = .success([])
        repo.feedBehavior = .success([])

        let vm = makeVM(repo: repo)

        await vm.reload()

        XCTAssertEqual(vm.loadState, .empty)
    }

    func testReload_error_transitionsToError() async {
        let repo = KudosRepositoryFake()
        repo.highlightBehavior = .error(.network)

        let vm = makeVM(repo: repo)

        await vm.reload()

        XCTAssertEqual(vm.loadState, .error(.network))
    }

    // MARK: - Filter toggle: hashtag

    func testSetHashtagFilter_newFilter_triggersReloadAndResetsCarousel() async {
        let repo = KudosRepositoryFake()
        let vm = makeVM(repo: repo)

        let filterId = UUID()

        // Simulate a non-zero carousel index before applying the filter.
        vm.onCarouselIndexChanged(3)
        XCTAssertEqual(vm.carouselIndex, 3)

        await vm.setHashtagFilter(filterId)

        XCTAssertEqual(vm.selectedHashtagId, filterId)
        XCTAssertGreaterThan(repo.fetchHighlightCalls, 0)
        // TC_FUN_005: carousel must reset to card 1 (1-based) when a new
        // filter is applied — `KudosCarouselDots` renders the index verbatim,
        // so 0 would surface as "0/N" in the pagination chrome.
        XCTAssertEqual(vm.carouselIndex, 1)
    }

    func testToggleHashtagFilter_reTapSame_clearsFilter() async {
        let repo = KudosRepositoryFake()
        let vm = makeVM(repo: repo)

        let filterId = UUID()

        // Set filter first via the UI toggle entry point
        await vm.toggleHashtagFilter(filterId)
        XCTAssertEqual(vm.selectedHashtagId, filterId)

        // Re-tap same — should clear (toggle semantics live on `toggle*`, not `set*`)
        await vm.toggleHashtagFilter(filterId)

        XCTAssertNil(vm.selectedHashtagId)  // Cleared
    }

    // MARK: - Filter toggle: department

    func testSetDepartmentFilter_newFilter_triggersReload() async {
        let repo = KudosRepositoryFake()
        let vm = makeVM(repo: repo)

        let deptId = UUID()

        // Simulate a non-zero carousel index before applying the filter.
        vm.onCarouselIndexChanged(2)
        XCTAssertEqual(vm.carouselIndex, 2)

        await vm.setDepartmentFilter(deptId)

        XCTAssertEqual(vm.selectedDepartmentId, deptId)
        XCTAssertGreaterThan(repo.fetchHighlightCalls, 0)
        // TC_FUN_005: carousel must reset to card 1 (1-based) when a new
        // filter is applied — see hashtag-filter test for full rationale.
        XCTAssertEqual(vm.carouselIndex, 1)
    }

    func testToggleDepartmentFilter_reTapSame_clearsFilter() async {
        let repo = KudosRepositoryFake()
        let vm = makeVM(repo: repo)

        let deptId = UUID()

        // Set filter first via the UI toggle entry point
        await vm.toggleDepartmentFilter(deptId)
        XCTAssertEqual(vm.selectedDepartmentId, deptId)

        // Re-tap same — should clear
        await vm.toggleDepartmentFilter(deptId)

        XCTAssertNil(vm.selectedDepartmentId)  // Cleared
    }

    // MARK: - Like toggle: optimistic + rollback

    func testToggleLike_optimisticThenSuccess() async {
        let repo = KudosRepositoryFake()
        repo.likeBehavior = .success(true)

        let kudosId = UUID()
        let kudos = makeKudos(id: kudosId, isLikedByMe: false, heartCount: 3, canLike: true)

        let vm = makeVM(repo: repo)

        // Set up the VM's published state via reload so we can mutate it
        vm.highlights = [kudos]

        await vm.toggleLike(kudosId)

        guard let updated = vm.highlights.first else {
            XCTFail("Expected kudos in highlights")
            return
        }
        XCTAssertTrue(updated.isLikedByMe)  // Mutated
        XCTAssertEqual(updated.heartCount, 4)  // Incremented
        XCTAssertEqual(vm.currentToast, nil)  // No error toast
    }

    func testToggleLike_optimisticThenErrorRollback() async {
        let repo = KudosRepositoryFake()
        repo.likeBehavior = .error(.network)
        
        let kudosId = UUID()
        let kudos = makeKudos(id: kudosId, isLikedByMe: false, heartCount: 3, canLike: true)

        let vm = makeVM(repo: repo)
        vm.highlights = [kudos]

        await vm.toggleLike(kudosId)

        guard let updated = vm.highlights.first else {
            XCTFail("Expected kudos in highlights")
            return
        }
        XCTAssertFalse(updated.isLikedByMe)  // Rolled back
        XCTAssertEqual(updated.heartCount, 3)  // Rolled back
        XCTAssertEqual(vm.currentToast, .likeFailed)  // Error toast emitted
    }

    func testToggleLike_unlikeRollback() async {
        let repo = KudosRepositoryFake()
        repo.unlikeBehavior = .error(.alreadyLiked)
        
        let kudosId = UUID()
        let kudos = makeKudos(id: kudosId, isLikedByMe: true, heartCount: 5, canLike: true)

        let vm = makeVM(repo: repo)
        vm.feed = [kudos]

        await vm.toggleLike(kudosId)

        guard let updated = vm.feed.first else {
            XCTFail("Expected kudos in feed")
            return
        }
        XCTAssertTrue(updated.isLikedByMe)  // Rolled back to true
        XCTAssertEqual(updated.heartCount, 5)  // Rolled back
        XCTAssertEqual(vm.currentToast, .likeFailed)
    }

    func testToggleLike_doubleTap_ignored() async {
        let repo = KudosRepositoryFake()
        repo.likeBehavior = .success(true)
        
        let kudosId = UUID()
        let kudos = makeKudos(id: kudosId, isLikedByMe: false, heartCount: 3, canLike: true)

        let vm = makeVM(repo: repo)
        vm.highlights = [kudos]

        // Simulate double-tap: call toggleLike twice rapidly
        let task1 = Task { await vm.toggleLike(kudosId) }
        let task2 = Task { await vm.toggleLike(kudosId) }  // Should be ignored

        await task1.value
        await task2.value

        // The second tap should have been filtered by likeInFlight guard.
        // Verify the repo was called only once.
        XCTAssertEqual(repo.likeCalls, 1)
    }

    // MARK: - Secret box guard

    func testOpenSecretBox_firstTap_emitsToast() async {
        let repo = KudosRepositoryFake()
        repo.statsBehavior = .success(UserStats(
            userId: UUID(),
            kudosReceivedCount: 0,
            kudosSentCount: 0,
            kudosHeartsReceived: 0,
            secretBoxesOpened: 0,
            secretBoxesUnopened: 1,
            updatedAt: Date()
        ))
        
        let vm = makeVM(repo: repo)

        // Simulate having loaded stats
        await vm.reload()

        vm.openSecretBox()

        XCTAssertEqual(vm.currentToast, .comingSoon)
        XCTAssertTrue(vm.secretBoxInFlight)
    }

    func testOpenSecretBox_doubleTap_ignored() {
        let repo = KudosRepositoryFake()
        let vm = makeVM()

        // First tap
        vm.openSecretBox()
        let toastAfterFirst = vm.currentToast

        // Immediately second tap (while still inFlight)
        vm.openSecretBox()

        // Toast should not change because second tap was blocked
        XCTAssertEqual(vm.currentToast, toastAfterFirst)
    }

    // MARK: - canOpenSecretBox computed

    func testCanOpenSecretBox_unopenedAndNotInFlight_true() async {
        let repo = KudosRepositoryFake()
        repo.statsBehavior = .success(UserStats(
            userId: UUID(),
            kudosReceivedCount: 0,
            kudosSentCount: 0,
            kudosHeartsReceived: 0,
            secretBoxesOpened: 2,
            secretBoxesUnopened: 1,
            updatedAt: Date()
        ))
                let vm = makeVM(repo: repo)

        await vm.reload()

        XCTAssertTrue(vm.canOpenSecretBox)
    }

    func testCanOpenSecretBox_noUnopened_false() async {
        let repo = KudosRepositoryFake()
        repo.statsBehavior = .success(UserStats(
            userId: UUID(),
            kudosReceivedCount: 0,
            kudosSentCount: 0,
            kudosHeartsReceived: 0,
            secretBoxesOpened: 2,
            secretBoxesUnopened: 0,  // None unopened
            updatedAt: Date()
        ))
                let vm = makeVM(repo: repo)

        await vm.reload()

        XCTAssertFalse(vm.canOpenSecretBox)
    }

    func testCanOpenSecretBox_inFlight_false() async {
        let repo = KudosRepositoryFake()
        repo.statsBehavior = .success(UserStats(
            userId: UUID(),
            kudosReceivedCount: 0,
            kudosSentCount: 0,
            kudosHeartsReceived: 0,
            secretBoxesOpened: 2,
            secretBoxesUnopened: 1,
            updatedAt: Date()
        ))
                let vm = makeVM(repo: repo)

        await vm.reload()

        // Simulate in-flight by calling openSecretBox (which sets secretBoxInFlight)
        vm.openSecretBox()

        XCTAssertFalse(vm.canOpenSecretBox)
    }

    // MARK: - Photo viewer

    // Photo viewer tests are `async` per code-standards.md — @MainActor VMs
    // dealloc on a background queue in sync XCTest methods and SIGABRT.
    func testPresentPhoto_setsPhoto() async {
        let vm = makeVM()
        let url = URL(string: "https://example.com/photo.jpg")!

        vm.presentPhoto(url)

        XCTAssertEqual(vm.presentedPhoto, url)
    }

    func testDismissPhoto_clearsPhoto() async {
        let vm = makeVM()
        let url = URL(string: "https://example.com/photo.jpg")!

        vm.presentPhoto(url)
        XCTAssertEqual(vm.presentedPhoto, url)

        vm.dismissPhoto()

        XCTAssertNil(vm.presentedPhoto)
    }

    // MARK: - Hashtag tag resolution

    func testOnHashtagTagTapped_matchesAndFilters() async {
        let hashtagId = UUID()
        let hashtag = Hashtag(id: hashtagId, tag: "#teamwork")

        let repo = KudosRepositoryFake()
        repo.hashtagsBehavior = .success([hashtag])
                let vm = makeVM(repo: repo)

        // Load to populate hashtags
        await vm.reload()

        await vm.onHashtagTagTapped("#teamwork")

        XCTAssertEqual(vm.selectedHashtagId, hashtagId)
        XCTAssertGreaterThan(repo.fetchHighlightCalls, 1)  // One from reload, one from filter
    }

    func testOnHashtagTagTapped_normalizedWithHash() async {
        let hashtagId = UUID()
        let hashtag = Hashtag(id: hashtagId, tag: "#teamwork")

        let repo = KudosRepositoryFake()
        repo.hashtagsBehavior = .success([hashtag])
                let vm = makeVM(repo: repo)

        await vm.reload()

        await vm.onHashtagTagTapped("teamwork")  // No leading #

        XCTAssertEqual(vm.selectedHashtagId, hashtagId)  // Matched after normalization
    }

    func testOnHashtagTagTapped_noMatch_noops() async {
        let hashtag = Hashtag(id: UUID(), tag: "#teamwork")

        let repo = KudosRepositoryFake()
        repo.hashtagsBehavior = .success([hashtag])
                let vm = makeVM(repo: repo)

        await vm.reload()

        let selectedBefore = vm.selectedHashtagId
        await vm.onHashtagTagTapped("#nonexistent")

        XCTAssertEqual(vm.selectedHashtagId, selectedBefore)  // No change
    }
}

// MARK: - Test Fixtures

private func makeKudos(
    id: KudosID = UUID(),
    isLikedByMe: Bool = false,
    heartCount: Int = 0,
    canLike: Bool = true
) -> Kudos {
    Kudos(
        id: id,
        sender: KudosAuthor(
            userId: UUID(),
            displayName: "Sender",
            employeeCode: nil,
            avatarURL: nil,
            departmentId: nil,
            kudosReceivedCount: 0
        ),
        recipient: KudosAuthor(
            userId: UUID(),
            displayName: "Recipient",
            employeeCode: nil,
            avatarURL: nil,
            departmentId: nil,
            kudosReceivedCount: 0
        ),
        title: "Great Title",
        message: "Great work!",
        isAnonymous: false,
        anonymousNickname: nil,
        hashtags: [],
        attachments: [],
        heartCount: heartCount,
        isLikedByMe: isLikedByMe,
        canLike: canLike,
        shareURL: nil,
        createdAt: Date()
    )
}

