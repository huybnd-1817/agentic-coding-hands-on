import XCTest
import Supabase
@testable import saa

// MARK: - KudosErrorMapperCreateTests
//
// Verifies the new error code mappings added in phase-06:
// StorageError codes → imageTooLarge / unsupportedImageType / createDenied / attachmentUploadFailed
// PostgrestError-like structs cannot be instantiated from unit tests (SDK restriction),
// so StorageError (a plain struct) and a fake-error shim are used instead.
//
// The PostgrestError path for 42501/23505 is already documented in
// KudosErrorMapperTests.swift under the NOTE comment; those paths are covered by
// integration tests. Here we cover what IS unit-testable: StorageError mapping.

final class KudosErrorMapperCreateTests: XCTestCase {

    // MARK: - StorageError → imageTooLarge (413)

    func testStorageError_413_mapsToImageTooLarge() {
        let error = StorageError(statusCode: "413", message: "Payload Too Large")
        let mapped = KudosErrorMapper.from(error)
        XCTAssertEqual(mapped, KudosError.imageTooLarge)
    }

    // MARK: - StorageError → unsupportedImageType (415)

    func testStorageError_415_mapsToUnsupportedImageType() {
        let error = StorageError(statusCode: "415", message: "Unsupported Media Type")
        let mapped = KudosErrorMapper.from(error)
        XCTAssertEqual(mapped, KudosError.unsupportedImageType)
    }

    // MARK: - StorageError → createDenied (42501 / RLS)

    func testStorageError_42501_mapsToCreateDenied() {
        let error = StorageError(statusCode: "42501", message: "insufficient_privilege")
        let mapped = KudosErrorMapper.from(error)
        XCTAssertEqual(mapped, KudosError.createDenied)
    }

    // MARK: - StorageError → attachmentUploadFailed (unknown code)

    func testStorageError_unknown_mapsToAttachmentUploadFailed() {
        let error = StorageError(statusCode: "500", message: "Internal Server Error")
        let mapped = KudosErrorMapper.from(error)
        XCTAssertEqual(mapped, KudosError.attachmentUploadFailed)
    }

    func testStorageError_nilStatusCode_mapsToAttachmentUploadFailed() {
        let error = StorageError(statusCode: nil, message: "Unknown storage failure")
        let mapped = KudosErrorMapper.from(error)
        XCTAssertEqual(mapped, KudosError.attachmentUploadFailed)
    }

    // MARK: - Pass-through: already a KudosError

    func testAlreadyKudosError_passThrough() {
        let original = KudosError.imageTooLarge
        let mapped = KudosErrorMapper.from(original)
        XCTAssertEqual(mapped, KudosError.imageTooLarge)
    }

    // MARK: - URLError still maps to network

    func testURLError_mapsToNetwork() {
        let error = URLError(.notConnectedToInternet)
        let mapped = KudosErrorMapper.from(error)
        XCTAssertEqual(mapped, KudosError.network)
    }

    // MARK: - Unknown error still wraps in unknown

    func testUnknownError_wrapsInUnknown() {
        struct RandomStorageFailure: Error {}
        let mapped = KudosErrorMapper.from(RandomStorageFailure())
        guard case .unknown = mapped else {
            XCTFail("Expected .unknown, got \(mapped)")
            return
        }
    }
}
