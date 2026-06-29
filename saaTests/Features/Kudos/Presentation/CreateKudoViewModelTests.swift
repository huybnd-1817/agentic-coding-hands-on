import XCTest
@testable import saa

// MARK: - CreateKudoViewModelTests
//
// ≥15 unit test cases covering:
//   1.  Validator wiring — fieldErrors surfaced from VM
//   2.  Image upload: idle → uploading → uploaded
//   3.  Image upload: failure → .failed state + toast
//   4.  Image remove — draft removed from list
//   5.  Submit happy path — repo called, onKudosCreated fired
//   6.  Submit failure — error mapped, state resets to .idle
//   7.  Submit with validation errors — repo not called
//   8.  isDirty: clean on init
//   9.  isDirty: dirty after title change
//   10. isDirty: dirty after recipient selection
//   11. Recipient filter — excludes self
//   12. Recipient filter — query filters by name
//   13. Recipient filter — no match returns empty
//   14. Hashtag max-5 enforcement — 6th toggle is no-op
//   15. Hashtag toggle — deselects already-selected hashtag
//   16. Cancel-with-confirm: clean form → .canDismiss
//   17. Cancel-with-confirm: dirty form → .confirmFirst
//   18. prependKudos — optimistic feed prepend on KudosViewModel
//   19. Anonymous toggle — nickname cleared on toggle off
//   20. canSubmit: false while uploading, true after upload completes
//
// IMPORTANT: All test methods are `async` even if they don't await anything.
// `CreateKudoViewModel` is `@MainActor final class … ObservableObject`. Holding
// it as a local variable in a *synchronous* `@MainActor` test method causes
// SIGABRT when the deinit is enqueued to the MainActor and races with internal
// Combine tasks. Making every method `async` keeps the VM alive for the
// structured-concurrency lifetime of the test. (See agent-memory: swiftui-testing-patterns)

@MainActor
final class CreateKudoViewModelTests: XCTestCase {

    // MARK: - Fixtures

    private let senderId = UUID()
    private let recipientId = UUID()

    private func makeVM(
        repoBehavior: KudosRepositoryFake.CreateKudoBehavior = .success(Kudos.fixture()),
        uploaderBehavior: KudosImageUploaderFake.Behavior = .success(storagePath: "test/a.jpg"),
        onKudosCreated: @escaping (Kudos) -> Void = { _ in }
    ) -> (CreateKudoViewModel, KudosRepositoryFake, KudosImageUploaderFake) {
        let repo = KudosRepositoryFake()
        repo.createKudoBehavior = repoBehavior
        repo._currentUserId = senderId
        // `fetchEligibleRecipients` is now called by the VM (replaces fetchTopGiftRecipients).
        // The repo returns ProfileSummary directly, already excluding self server-side.
        // Include both Alice and self here so `filteredRecipients` (which excludes self
        // client-side by `senderId`) can still be tested for self-exclusion.
        repo.eligibleRecipientsBehavior = .success([
            ProfileSummary(
                id: recipientId,
                displayName: "Alice Smith",
                employeeCode: "EMP01",
                avatarURL: nil,
                department: nil
            ),
            ProfileSummary(
                id: senderId,                   // self — must be excluded client-side
                displayName: "Me",
                employeeCode: "EMP00",
                avatarURL: nil,
                department: nil
            )
        ])
        repo.hashtagsBehavior = .success([
            Hashtag(id: UUID(), tag: "#Teamwork"),
            Hashtag(id: UUID(), tag: "#Inspiring")
        ])
        let uploader = KudosImageUploaderFake()
        uploader.behavior = uploaderBehavior
        let vm = CreateKudoViewModel(
            repo: repo,
            uploader: uploader,
            currentUserId: senderId,
            onKudosCreated: onKudosCreated
        )
        return (vm, repo, uploader)
    }

    /// Minimal 1-byte JPEG domain draft for testing uploads.
    private func makeDomain() -> KudosImageDraft {
        KudosImageDraft(data: Data([0xFF]), contentType: "image/jpeg")
    }

    private func fillValidForm(_ vm: CreateKudoViewModel) {
        vm.selectRecipient(ProfileSummary(
            id: recipientId,
            displayName: "Alice",
            employeeCode: "EMP01",
            avatarURL: nil,
            department: nil
        ))
        vm.setTitle("Great work")
        vm.setMessage("You are amazing!")
        vm.selectedHashtags = [Hashtag(id: UUID(), tag: "#Teamwork")]
    }

    // MARK: - 1. Validator wiring

    func test_fieldErrors_emptyForm_containsAllRequiredErrors() async {
        let (vm, _, _) = makeVM()
        let errors = vm.fieldErrors
        XCTAssertTrue(errors.contains(.recipientRequired))
        XCTAssertTrue(errors.contains(.titleRequired))
        XCTAssertTrue(errors.contains(.messageRequired))
        XCTAssertTrue(errors.contains(.hashtagsRequired))
    }

    func test_fieldErrors_validForm_isEmpty() async {
        let (vm, _, _) = makeVM()
        fillValidForm(vm)
        XCTAssertTrue(vm.fieldErrors.isEmpty)
    }

    // MARK: - 2. Image upload: uploading → uploaded

    func test_addImage_setsUploadingThenUploaded() async {
        let (vm, _, uploader) = makeVM(uploaderBehavior: .success(storagePath: "test/img.jpg"))
        let domain = makeDomain()

        vm.addImage(localURL: URL(string: "file:///tmp/a.jpg")!, domain: domain)
        XCTAssertEqual(vm.imageDrafts.first?.uploadState, .uploading)

        // Allow upload task to run.
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(uploader.uploadCalls, 1)
        XCTAssertEqual(vm.imageDrafts.first?.uploadState, .uploaded(storagePath: "test/img.jpg"))
    }

    // MARK: - 3. Image upload: failure → .failed + toast

    func test_addImage_uploaderFailure_setsFailedState() async {
        let (vm, _, _) = makeVM(uploaderBehavior: .failure(.attachmentUploadFailed))
        let domain = makeDomain()

        vm.addImage(localURL: URL(string: "file:///tmp/b.jpg")!, domain: domain)
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(vm.imageDrafts.first?.uploadState, .failed)
        XCTAssertNotNil(vm.toastMessageKey)
    }

    // MARK: - 4. Remove image — draft removed from list

    func test_removeImage_removesDraftFromList() async {
        let (vm, _, _) = makeVM()
        let domain = makeDomain()
        vm.addImage(localURL: URL(string: "file:///tmp/c.jpg")!, domain: domain)

        XCTAssertEqual(vm.imageDrafts.count, 1)
        vm.removeImage(domain.id)
        XCTAssertEqual(vm.imageDrafts.count, 0)
    }

    // MARK: - 5. Submit happy path

    func test_submit_happyPath_callsRepoAndFiresCallback() async {
        var receivedKudos: Kudos? = nil
        let (vm, repo, _) = makeVM(
            repoBehavior: .success(Kudos.fixture()),
            onKudosCreated: { k in receivedKudos = k }
        )
        fillValidForm(vm)

        await vm.submit()

        XCTAssertEqual(repo.createKudoCalls, 1)
        XCTAssertNotNil(receivedKudos)
    }

    func test_submit_happyPath_capturedRequestMatchesFields() async {
        let (vm, repo, _) = makeVM(repoBehavior: .success(Kudos.fixture()))
        fillValidForm(vm)

        await vm.submit()

        let req = repo.lastCreateKudoRequest
        XCTAssertEqual(req?.recipientId, recipientId)
        XCTAssertEqual(req?.senderId, senderId)
        XCTAssertEqual(req?.title, "Great work")
        XCTAssertEqual(req?.message, "You are amazing!")
    }

    // MARK: - 6. Submit failure — state resets to idle

    func test_submit_repoFailure_stateResetsToIdle() async {
        let (vm, _, _) = makeVM(repoBehavior: .error(.createDenied))
        fillValidForm(vm)

        await vm.submit()

        XCTAssertEqual(vm.submissionState, .idle)
        XCTAssertNotNil(vm.toastMessageKey)
    }

    // MARK: - 7. Submit with validation errors — repo not called

    func test_submit_validationErrors_repoNotCalled() async {
        let (vm, repo, _) = makeVM()
        // No fields filled — validator catches all errors.

        await vm.submit()

        XCTAssertEqual(repo.createKudoCalls, 0)
    }

    // MARK: - 8. isDirty: clean on init

    func test_isDirty_freshVM_isFalse() async {
        let (vm, _, _) = makeVM()
        XCTAssertFalse(vm.isDirty)
    }

    // MARK: - 9. isDirty: dirty after title change

    func test_isDirty_afterTitleChange_isTrue() async {
        let (vm, _, _) = makeVM()
        vm.setTitle("Hello")
        XCTAssertTrue(vm.isDirty)
    }

    // MARK: - 10. isDirty: dirty after recipient selection

    func test_isDirty_afterRecipientSelection_isTrue() async {
        let (vm, _, _) = makeVM()
        vm.selectRecipient(ProfileSummary(
            id: UUID(), displayName: "A", employeeCode: nil, avatarURL: nil, department: nil
        ))
        XCTAssertTrue(vm.isDirty)
    }

    // MARK: - 11. Recipient filter — excludes self

    func test_filteredRecipients_excludesSelf() async {
        let (vm, _, _) = makeVM()
        await vm.onAppear()

        let ids = vm.filteredRecipients.map(\.id)
        XCTAssertFalse(ids.contains(senderId), "Self must be excluded from recipient list")
    }

    // MARK: - 12. Recipient filter — query filters by name

    func test_filteredRecipients_queryMatchesDisplayName() async {
        let (vm, _, _) = makeVM()
        await vm.onAppear()

        vm.recipientQuery = "Alice"
        XCTAssertEqual(vm.filteredRecipients.count, 1)
        XCTAssertEqual(vm.filteredRecipients.first?.displayName, "Alice Smith")
    }

    // MARK: - 13. Recipient filter — no match returns empty

    func test_filteredRecipients_noMatch_returnsEmpty() async {
        let (vm, _, _) = makeVM()
        await vm.onAppear()

        vm.recipientQuery = "ZZZNOMATCH"
        XCTAssertTrue(vm.filteredRecipients.isEmpty)
    }

    // MARK: - 14. Hashtag max-5 enforcement

    func test_toggleHashtag_max5_sixthToggleIsNoop() async {
        let (vm, _, _) = makeVM()
        for i in 0..<5 {
            vm.toggleHashtag(Hashtag(id: UUID(), tag: "#Tag\(i)"))
        }
        XCTAssertEqual(vm.selectedHashtags.count, 5)
        XCTAssertTrue(vm.isHashtagAtMax)

        vm.toggleHashtag(Hashtag(id: UUID(), tag: "#SixthTag"))
        XCTAssertEqual(vm.selectedHashtags.count, 5, "6th hashtag must not be added")
    }

    // MARK: - 15. Hashtag toggle — deselects already-selected

    func test_toggleHashtag_secondToggleSameTag_deselects() async {
        let (vm, _, _) = makeVM()
        let tag = Hashtag(id: UUID(), tag: "#Teamwork")
        vm.toggleHashtag(tag)
        XCTAssertEqual(vm.selectedHashtags.count, 1)
        vm.toggleHashtag(tag)
        XCTAssertEqual(vm.selectedHashtags.count, 0)
    }

    // MARK: - 16. Cancel-with-confirm: clean → .canDismiss

    func test_attemptCancel_cleanForm_returnsCanDismiss() async {
        let (vm, _, _) = makeVM()
        XCTAssertEqual(vm.attemptCancel(), .canDismiss)
    }

    // MARK: - 17. Cancel-with-confirm: dirty → .confirmFirst

    func test_attemptCancel_dirtyForm_returnsConfirmFirst() async {
        let (vm, _, _) = makeVM()
        vm.setMessage("Hello there")
        XCTAssertEqual(vm.attemptCancel(), .confirmFirst)
    }

    // MARK: - 18. prependKudos on KudosViewModel

    func test_prependKudos_insertsAtTopOfFeed() async {
        let repo = KudosRepositoryFake()
        let loadUseCase = LoadKudosScreenUseCase(repository: repo)
        let toggleUseCase = ToggleKudosReactionUseCase(
            repository: repo,
            clock: { Date(timeIntervalSince1970: 0) }
        )
        let kudosVM = KudosViewModel(
            loadUseCase: loadUseCase,
            toggleReactionUseCase: toggleUseCase,
            clipboard: KudosClipboardServiceFake(),
            repository: repo
        )
        let existing = Kudos.fixture(id: UUID())
        kudosVM.feed = [existing]

        let newKudos = Kudos.fixture(id: UUID())
        kudosVM.prependKudos(newKudos)

        XCTAssertEqual(kudosVM.feed.count, 2)
        XCTAssertEqual(kudosVM.feed.first?.id, newKudos.id, "New kudos must be at index 0")
    }

    // MARK: - 19. Anonymous toggle — nickname cleared on toggle off

    func test_toggleAnonymous_offClearsNickname() async {
        let (vm, _, _) = makeVM()
        vm.toggleAnonymous()          // → true
        vm.setNickname("Doraemon")
        XCTAssertEqual(vm.anonymousNickname, "Doraemon")

        vm.toggleAnonymous()          // → false
        XCTAssertEqual(vm.anonymousNickname, "", "Nickname must be cleared when anonymous toggled off")
    }

    // MARK: - 20. canSubmit: false while uploading, true after uploaded

    func test_canSubmit_falseWhileUploading_trueAfterUploaded() async {
        let (vm, _, _) = makeVM(uploaderBehavior: .success(storagePath: "test/x.jpg"))
        fillValidForm(vm)
        let domain = makeDomain()

        vm.addImage(localURL: URL(string: "file:///tmp/x.jpg")!, domain: domain)
        XCTAssertFalse(vm.canSubmit, "canSubmit must be false while an upload is in progress")

        // Wait for upload to complete.
        try? await Task.sleep(nanoseconds: 150_000_000)
        XCTAssertTrue(vm.canSubmit, "canSubmit must be true once all images are uploaded")
    }
}

// MARK: - Kudos.fixture helper

private extension Kudos {
    static func fixture(id: KudosID = UUID()) -> Kudos {
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
            title: "Great job",
            message: "Well done!",
            isAnonymous: false,
            anonymousNickname: nil,
            hashtags: [],
            photoURL: nil,
            attachments: [],
            heartCount: 0,
            isLikedByMe: false,
            canLike: true,
            shareURL: nil,
            createdAt: Date(timeIntervalSince1970: 0)
        )
    }
}
