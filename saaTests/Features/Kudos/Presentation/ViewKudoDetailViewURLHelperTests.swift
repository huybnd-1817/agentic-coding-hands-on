import XCTest
@testable import saa

// MARK: - ViewKudoDetailViewURLHelperTests
//
// Repro for the kudos_id=4eae814d-d778-4b49-be2c-e9322012a7d4 bug: a legacy
// `photo_url` row backfilled into `kudos_attachments.storage_path` carries a
// fully-qualified HTTPS URL. The detail-screen gallery must render it
// immediately, without waiting for the async signed-URL resolver.

final class ViewKudoDetailViewURLHelperTests: XCTestCase {

    // MARK: - directHTTPURL fast path

    func test_directHTTPURL_https_returnsURLAsIs() {
        let path = "https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800"
        let url = ViewKudoDetailView.directHTTPURL(from: path)
        XCTAssertEqual(url?.absoluteString, path)
    }

    func test_directHTTPURL_http_returnsURLAsIs() {
        let path = "http://example.com/legacy.jpg"
        let url = ViewKudoDetailView.directHTTPURL(from: path)
        XCTAssertEqual(url?.absoluteString, path)
    }

    func test_directHTTPURL_bucketRelativePath_returnsNil() {
        // Bucket-relative storage paths must NOT short-circuit — they need a
        // signed URL produced by the repository.
        XCTAssertNil(ViewKudoDetailView.directHTTPURL(from: "2c02cda8-83ba-42fe-a10f-c8301a754edb/3EA4646F.jpg"))
        XCTAssertNil(ViewKudoDetailView.directHTTPURL(from: "kudos-images/ce11ab01-0000-0000-0000-000000000001/test-uuid.jpg"))
    }

    func test_directHTTPURL_emptyString_returnsNil() {
        XCTAssertNil(ViewKudoDetailView.directHTTPURL(from: ""))
    }
}
