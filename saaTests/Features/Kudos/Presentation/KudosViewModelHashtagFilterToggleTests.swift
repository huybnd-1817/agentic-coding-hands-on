import XCTest
@testable import saa

// MARK: - KudosViewModelHashtagFilterToggleTests
//
// Reproduces the user-reported scenario: tap hashtag A, then tap hashtag B —
// expectation is that B becomes the active filter. The bug report says B
// stays unselected (only A clears).

@MainActor
final class KudosViewModelHashtagFilterToggleTests: XCTestCase {

    /// Seeds the VM with the given hashtags via the fake repo + `reload()`.
    /// `private(set)` blocks direct assignment, so we round-trip through the
    /// loading path that the production code uses.
    private func makeVM(with hashtags: [Hashtag]) async -> KudosViewModel {
        let repo = KudosRepositoryFake()
        repo.hashtagsBehavior = .success(hashtags)
        let loadUseCase   = LoadKudosScreenUseCase(repository: repo)
        let toggleUseCase = ToggleKudosReactionUseCase(repository: repo, clock: { Date(timeIntervalSince1970: 0) })
        let vm = KudosViewModel(
            loadUseCase: loadUseCase,
            toggleReactionUseCase: toggleUseCase,
            clipboard: KudosClipboardServiceFake(),
            repository: repo,
            clock: { Date(timeIntervalSince1970: 0) }
        )
        await vm.reload()
        return vm
    }

    func test_setHashtagFilter_tapAThenTapB_selectsB() async {
        let aId = UUID()
        let bId = UUID()
        let vm = await makeVM(with: [Hashtag(id: aId, tag: "#A"), Hashtag(id: bId, tag: "#B")])

        await vm.setHashtagFilter(aId)
        XCTAssertEqual(vm.selectedHashtagId, aId, "After first tap, A must be selected")

        await vm.setHashtagFilter(bId)
        XCTAssertEqual(vm.selectedHashtagId, bId, "After tapping B, B must be selected (was A)")
    }

    /// VM-level setter is idempotent — guards against double-fire bugs where a
    /// binding might invoke the setter twice in rapid succession with the same
    /// id. Without this guard, the second call would (under the old toggle
    /// semantics) clear the filter the user just selected.
    func test_setHashtagFilter_doubleFireSameId_idempotent() async {
        let aId = UUID()
        let vm = await makeVM(with: [Hashtag(id: aId, tag: "#A")])

        await vm.setHashtagFilter(aId)
        XCTAssertEqual(vm.selectedHashtagId, aId)

        // Second call with the same id is a no-op (the bug fix).
        await vm.setHashtagFilter(aId)
        XCTAssertEqual(vm.selectedHashtagId, aId, "Re-calling setHashtagFilter with the same id must NOT clear (idempotent)")
    }

    func test_setHashtagFilter_setThenNil_clears() async {
        let aId = UUID()
        let vm = await makeVM(with: [Hashtag(id: aId, tag: "#A")])

        await vm.setHashtagFilter(aId)
        XCTAssertEqual(vm.selectedHashtagId, aId)

        await vm.setHashtagFilter(nil)
        XCTAssertNil(vm.selectedHashtagId, "Explicit nil must clear")
    }

    // MARK: - UI toggle (dropdown re-tap-to-clear semantics)

    func test_toggleHashtagFilter_tapSameTwice_clears() async {
        let aId = UUID()
        let vm = await makeVM(with: [Hashtag(id: aId, tag: "#A")])

        await vm.toggleHashtagFilter(aId)
        XCTAssertEqual(vm.selectedHashtagId, aId)

        await vm.toggleHashtagFilter(aId)
        XCTAssertNil(vm.selectedHashtagId, "Toggling the currently-selected hashtag must clear it")
    }

    func test_toggleHashtagFilter_tapAThenTapB_selectsB() async {
        let aId = UUID()
        let bId = UUID()
        let vm = await makeVM(with: [Hashtag(id: aId, tag: "#A"), Hashtag(id: bId, tag: "#B")])

        await vm.toggleHashtagFilter(aId)
        XCTAssertEqual(vm.selectedHashtagId, aId)

        await vm.toggleHashtagFilter(bId)
        XCTAssertEqual(vm.selectedHashtagId, bId, "Toggling a DIFFERENT hashtag must switch the selection (not clear)")
    }
}
