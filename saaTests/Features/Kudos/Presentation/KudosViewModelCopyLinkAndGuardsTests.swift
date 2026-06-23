import XCTest
@testable import saa

// MARK: - KudosViewModelCopyLinkAndGuardsTests
//
// Fills the gaps left by `KudosViewModelTests`:
//   - copyLink finds the kudos in `highlights` first, then `feed`, then nil.
//   - copyLink writes `shareURL.absoluteString` to the clipboard when present;
//     when absent it MUST NOT call `clipboard.copy` (no empty-string side effect)
//     but MUST still emit the `.linkCopied` toast — the toast is a UX confirmation
//     that the user's tap was registered, independent of the URL availability.
//   - toggleLike no-ops cleanly when the id is unknown, or when `canLike == false`
//     (TC_FUN_008 — own-kudos guard).

@MainActor
final class KudosViewModelCopyLinkAndGuardsTests: XCTestCase {

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
            hashtags: [], photoURL: nil,
            heartCount: heartCount, isLikedByMe: isLikedByMe, canLike: canLike,
            shareURL: shareURL, createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    // MARK: - copyLink

    func testCopyLink_findsInHighlights_writesAbsoluteString() async {
        let (vm, _, clip) = makeVM()
        let url = URL(string: "https://saa.example.com/kudos/abc")!
        let kudos = makeKudos(shareURL: url)
        vm.highlights = [kudos]

        vm.copyLink(kudos.id)

        XCTAssertEqual(clip.copiedTexts, [url.absoluteString])
        XCTAssertEqual(vm.currentToast, .linkCopied)
    }

    func testCopyLink_findsInFeed_writesAbsoluteString() async {
        let (vm, _, clip) = makeVM()
        let url = URL(string: "https://saa.example.com/kudos/xyz")!
        let kudos = makeKudos(shareURL: url)
        vm.feed = [kudos]

        vm.copyLink(kudos.id)

        XCTAssertEqual(clip.copiedTexts, [url.absoluteString])
        XCTAssertEqual(vm.currentToast, .linkCopied)
    }

    func testCopyLink_nilShareURL_doesNotWriteButStillEmitsToast() async {
        let (vm, _, clip) = makeVM()
        let kudos = makeKudos(shareURL: nil)
        vm.highlights = [kudos]

        vm.copyLink(kudos.id)

        XCTAssertEqual(clip.copiedTexts, [], "No clipboard write when shareURL is nil")
        XCTAssertEqual(vm.currentToast, .linkCopied, "Toast must still confirm the tap was registered")
    }

    func testCopyLink_unknownId_doesNotWriteButStillEmitsToast() async {
        let (vm, _, clip) = makeVM()
        vm.highlights = []
        vm.feed = []

        vm.copyLink(UUID())

        XCTAssertEqual(clip.copiedTexts, [])
        XCTAssertEqual(vm.currentToast, .linkCopied)
    }

    // MARK: - toggleLike guards

    func testToggleLike_unknownId_noopsRepoUntouched() async {
        let (vm, repo, _) = makeVM()
        vm.highlights = []
        vm.feed = []

        await vm.toggleLike(UUID())

        XCTAssertEqual(repo.likeCalls,   0)
        XCTAssertEqual(repo.unlikeCalls, 0)
        XCTAssertNil(vm.currentToast)
    }

    func testToggleLike_canLikeFalse_noopsRepoUntouched() async {
        // Self-authored kudos: canLike == false. The optimistic mutation, the
        // network call, and the rollback path all MUST be skipped.
        let (vm, repo, _) = makeVM()
        let kudos = makeKudos(canLike: false, heartCount: 3, isLikedByMe: false)
        vm.highlights = [kudos]

        await vm.toggleLike(kudos.id)

        XCTAssertEqual(repo.likeCalls, 0, "Self-likes must not even reach the repository")
        XCTAssertEqual(vm.highlights.first?.heartCount, 3, "No optimistic mutation when canLike == false")
        XCTAssertFalse(vm.highlights.first?.isLikedByMe ?? true)
        XCTAssertNil(vm.currentToast)
    }

    // MARK: - emitToast replacement semantics

    func testEmitToast_replacesPriorToastWithoutCancellingTheUiState() async {
        // KudosViewModel.emitToast cancels the prior auto-dismiss Task and
        // assigns the new toast. Two sequential emissions must leave the
        // most-recent toast as the live one.
        let (vm, _, _) = makeVM()

        vm.copyLink(UUID())                  // first → .linkCopied
        XCTAssertEqual(vm.currentToast, .linkCopied)

        vm.openSecretBox()                   // second → .comingSoon
        XCTAssertEqual(vm.currentToast, .comingSoon, "Second toast must replace the first")
    }
}
