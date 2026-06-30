import XCTest
@testable import saa

// MARK: - KudosViewModelAttachmentResolutionTests
//
// Gap A1: Tests `resolveAttachmentImageURLs(for:)` — a method that returns a map
// keyed by storagePath with one entry per attachment whose repository.attachmentImageURL
// returned non-nil. Verifies:
// - Returns empty map for empty input
// - Returns map keyed by storagePath (NOT by index)
// - Omits entries whose resolver returned nil
//
// The KudosRepositoryFake implements attachmentImageURL as a passthrough via
// URL(string:). For nil-coverage, this test extends the fake with a configurable
// behavior that returns nil for specific paths.

@MainActor
final class KudosViewModelAttachmentResolutionTests: XCTestCase {

    // MARK: - Helpers

    private func makeVM(with repo: KudosRepositoryFake) -> KudosViewModel {
        let loadUseCase = LoadKudosScreenUseCase(repository: repo)
        let toggleUseCase = ToggleKudosReactionUseCase(
            repository: repo,
            clock: { Date(timeIntervalSince1970: 0) }
        )
        return KudosViewModel(
            loadUseCase: loadUseCase,
            toggleReactionUseCase: toggleUseCase,
            clipboard: KudosClipboardServiceFake(),
            repository: repo,
            clock: { Date(timeIntervalSince1970: 0) }
        )
    }

    // MARK: - Empty input

    func test_resolveAttachmentImageURLs_emptyInput_returnsEmptyMap() async {
        let repo = KudosRepositoryFake()
        let vm = makeVM(with: repo)

        let result = await vm.resolveAttachmentImageURLs(for: [])
        XCTAssertTrue(result.isEmpty, "Empty attachment list must return empty map")
    }

    // MARK: - Successful resolution (all paths resolve)

    func test_resolveAttachmentImageURLs_allPathsResolve_returnsMapKeyedByStoragePath() async {
        let repo = KudosRepositoryFake()
        let vm = makeVM(with: repo)

        // Gap A1: Verify map is keyed by storagePath, not by index.
        // Using fully-qualified URLs (legacy photo_url backfill case from phase-01).
        let attachment1 = KudosAttachment(
            storagePath: "https://images.unsplash.com/photo-1.jpg?w=800",
            contentType: "image/jpeg",
            byteSize: 50000,
            sortOrder: 0
        )
        let attachment2 = KudosAttachment(
            storagePath: "https://images.unsplash.com/photo-2.jpg?w=800",
            contentType: "image/jpeg",
            byteSize: 60000,
            sortOrder: 1
        )

        let result = await vm.resolveAttachmentImageURLs(for: [attachment1, attachment2])

        XCTAssertEqual(result.count, 2, "Both attachments must resolve")
        XCTAssertNotNil(result[attachment1.storagePath], "First attachment path must be in map")
        XCTAssertNotNil(result[attachment2.storagePath], "Second attachment path must be in map")
        XCTAssertEqual(
            result[attachment1.storagePath]?.absoluteString,
            attachment1.storagePath,
            "Map must preserve resolved URL for first attachment"
        )
        XCTAssertEqual(
            result[attachment2.storagePath]?.absoluteString,
            attachment2.storagePath,
            "Map must preserve resolved URL for second attachment"
        )
    }

    // MARK: - Partial resolution (some paths fail)

    func test_resolveAttachmentImageURLs_partialResolution_omitsNilEntries() async {
        // Gap A1: Verify that entries with nil resolution are omitted.
        // Extend the fake to return nil for a specific path.
        let repo = KudosRepositoryFake()
        repo.attachmentURLResolver = { storagePath in
            // Return URL for valid paths, nil for invalid ones
            if storagePath.hasPrefix("https://") {
                return URL(string: storagePath)
            }
            return nil  // Bucket-relative paths or invalid URLs
        }
        let vm = makeVM(with: repo)

        let validAttachment = KudosAttachment(
            storagePath: "https://example.com/valid.jpg",
            contentType: "image/jpeg",
            byteSize: 50000,
            sortOrder: 0
        )
        let invalidAttachment = KudosAttachment(
            storagePath: "bucket-relative/path/invalid.jpg",
            contentType: "image/jpeg",
            byteSize: 60000,
            sortOrder: 1
        )

        let result = await vm.resolveAttachmentImageURLs(for: [validAttachment, invalidAttachment])

        XCTAssertEqual(result.count, 1, "Only the valid attachment should be in the map")
        XCTAssertNotNil(result[validAttachment.storagePath], "Valid attachment must be present")
        XCTAssertNil(result[invalidAttachment.storagePath], "Invalid attachment must be omitted")
    }

    // MARK: - All fail

    func test_resolveAttachmentImageURLs_allPathsFail_returnsEmptyMap() async {
        let repo = KudosRepositoryFake()
        repo.attachmentURLResolver = { _ in nil }  // All paths fail
        let vm = makeVM(with: repo)

        let attachment1 = KudosAttachment(
            storagePath: "invalid/path/1.jpg",
            contentType: "image/jpeg",
            byteSize: 50000,
            sortOrder: 0
        )
        let attachment2 = KudosAttachment(
            storagePath: "invalid/path/2.jpg",
            contentType: "image/jpeg",
            byteSize: 60000,
            sortOrder: 1
        )

        let result = await vm.resolveAttachmentImageURLs(for: [attachment1, attachment2])

        XCTAssertTrue(
            result.isEmpty,
            "When all paths fail to resolve, the map must be empty"
        )
    }

    // MARK: - Keying by storagePath (not index)

    func test_resolveAttachmentImageURLs_keysAreStoragePaths_notIndices() async {
        let repo = KudosRepositoryFake()
        let vm = makeVM(with: repo)

        let attachments = (0..<3).map { i in
            KudosAttachment(
                storagePath: "https://example.com/image-\(i).jpg",
                contentType: "image/jpeg",
                byteSize: 10000 * (i + 1),
                sortOrder: i
            )
        }

        let result = await vm.resolveAttachmentImageURLs(for: attachments)

        // Verify: map keys are storagePath strings, not integers (indices)
        for (i, attachment) in attachments.enumerated() {
            XCTAssertNotNil(
                result[attachment.storagePath],
                "Attachment at index \(i) must be keyed by storagePath, not index"
            )
        }
        // Ensure no numeric keys exist (confirm keying strategy)
        XCTAssertNil(result["0"], "Integer index '0' must not be a key")
        XCTAssertNil(result["1"], "Integer index '1' must not be a key")
    }
}
