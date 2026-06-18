import XCTest
@testable import saa

// MARK: - HomeViewModelTests
//
// Verifies the state machine + countdown integration of HomeViewModel.
// Uses `AwardsRepositoryFake` from saaTests/Doubles/ as the repo seam.
// Routing concerns (401 / 403 dispatch) are NOT in the VM — they live in
// the container — so the VM tests stop at "state is .error(.unauthorized)".

@MainActor
final class HomeViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeVM(
        repo: AwardsRepositoryFake = AwardsRepositoryFake(),
        notifications: NotificationStubStore? = nil,
        clock: @escaping () -> Date = { Date(timeIntervalSince1970: 0) }
    ) -> HomeViewModel {
        HomeViewModel(
            repository: repo,
            notificationStore: notifications ?? NotificationStubStore(unreadCount: 3),
            isKudosAvailable: true,
            eventDate: Date(timeIntervalSince1970: 86_400),  // 1 day after the clock baseline
            clock: clock
        )
    }

    // MARK: - Awards happy path

    func testLoadAwards_transitionsLoadingToLoaded() async {
        let repo = AwardsRepositoryFake()  // defaults to 3 fixture awards
        let vm = makeVM(repo: repo)

        await vm.loadAwards()

        guard case let .loaded(awards) = vm.state else {
            XCTFail("Expected .loaded, got \(vm.state)")
            return
        }
        XCTAssertEqual(awards.count, 3)
        XCTAssertEqual(repo.fetchCalls, 1)
    }

    func testLoadAwards_emptyArrayBecomesEmptyState() async {
        let repo = AwardsRepositoryFake()
        repo.fetchBehavior = .success([])
        let vm = makeVM(repo: repo)

        await vm.loadAwards()

        XCTAssertEqual(vm.state, .empty)
    }

    // MARK: - Awards error paths

    func testLoadAwards_unauthorizedPropagatesAsState() async {
        let repo = AwardsRepositoryFake()
        repo.fetchBehavior = .error(AwardsError.unauthorized)
        let vm = makeVM(repo: repo)

        await vm.loadAwards()

        XCTAssertEqual(vm.state, .error(.unauthorized))
    }

    func testLoadAwards_forbiddenPropagatesAsState() async {
        let repo = AwardsRepositoryFake()
        repo.fetchBehavior = .error(AwardsError.forbidden)
        let vm = makeVM(repo: repo)

        await vm.loadAwards()

        XCTAssertEqual(vm.state, .error(.forbidden))
    }

    func testLoadAwards_nonAwardsErrorWrappedAsUnknown() async {
        struct BoomError: Error {}
        let repo = AwardsRepositoryFake()
        repo.fetchBehavior = .error(BoomError())
        let vm = makeVM(repo: repo)

        await vm.loadAwards()

        XCTAssertEqual(vm.state, .error(.unknown(underlying: BoomError())))
    }

    // MARK: - Retry

    func testRetryAwards_resetsToLoadingThenLoaded() async {
        let repo = AwardsRepositoryFake()
        repo.fetchBehavior = .error(AwardsError.network)
        let vm = makeVM(repo: repo)

        await vm.loadAwards()
        XCTAssertEqual(vm.state, .error(.network))

        repo.fetchBehavior = .success(AwardsRepositoryFake.defaultAwards)
        await vm.retryAwards()

        guard case .loaded = vm.state else {
            XCTFail("Expected .loaded after retry, got \(vm.state)")
            return
        }
        XCTAssertEqual(repo.fetchCalls, 2)
    }

    // MARK: - Countdown

    // NOTE: async test methods required even though the assertions are sync.
    // Sync test methods on a `@MainActor` `XCTestCase` running an iOS 16
    // deployment target trigger `swift_task_deinitOnExecutorMainActorBackDeploy`
    // when the `@MainActor` HomeViewModel + its retained NotificationStubStore
    // deinit at scope exit — that back-deploy path crashes inside libmalloc
    // (___BUG_IN_CLIENT_OF_LIBMALLOC_POINTER_BEING_FREED_WAS_NOT_ALLOCATED).
    // Marking the methods async puts them in a Task context which lets the
    // deinit chain run via the normal executor handoff. The pattern is
    // already used by every other test in this file.

    func testCountdown_initialValueComputedFromInjectedClock() async {
        let vm = makeVM(clock: { Date(timeIntervalSince1970: 0) })
        // Event is 86_400s ahead → exactly 1 day, 0 hours, 0 minutes.
        XCTAssertEqual(vm.countdown, Countdown(days: 1, hours: 0, minutes: 0))
    }

    func testCountdown_postEventClampsToZero() async {
        // Event in the past relative to clock → countdown clamps to zero.
        let vm = makeVM(clock: { Date(timeIntervalSince1970: 1_000_000) })
        XCTAssertEqual(vm.countdown, .zero)
    }

    // MARK: - Notification mirror

    func testUnreadCount_mirrorsStorePublisher() async {
        let store = NotificationStubStore(unreadCount: 5)
        let vm = makeVM(notifications: store)
        XCTAssertEqual(vm.unreadCount, 5)

        store.unreadCount = 0
        // Allow the Combine sink to fire on the main run loop.
        await Task.yield()
        XCTAssertEqual(vm.unreadCount, 0)
    }
}
