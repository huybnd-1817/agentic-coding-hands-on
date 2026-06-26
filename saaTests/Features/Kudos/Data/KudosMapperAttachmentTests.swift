import XCTest
@testable import saa

// MARK: - KudosMapperAttachmentTests
//
// Verifies `KudosMapper.attachments(from:)` and the full `KudosMapper.from` path
// with respect to the attachment/photo_url back-compat strategy.

final class KudosMapperAttachmentTests: XCTestCase {

    // MARK: - Fixtures

    private let senderId    = UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000001")!
    private let recipientId = UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000002")!
    private let currentId   = UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000003")!

    private func makeDTO(
        photoURL: String? = nil,
        attachments: [KudosAttachmentDTO]? = nil
    ) -> KudosDTO {
        KudosDTO(
            id: UUID(),
            sender_id: senderId,
            recipient_id: recipientId,
            title: "T",
            message: "M",
            is_anonymous: false,
            anonymous_nickname: nil,
            photo_url: photoURL,
            status: "active",
            created_at: Date(),
            deleted_at: nil,
            sender: nil,
            recipient: nil,
            kudos_hashtags: nil,
            kudos_attachments: attachments,
            reactions: nil
        )
    }

    private func makeAttachmentDTO(sortOrder: Int) -> KudosAttachmentDTO {
        KudosAttachmentDTO(
            id: UUID(),
            storage_path: "user/file\(sortOrder).jpg",
            sort_order: sortOrder,
            content_type: "image/jpeg",
            byte_size: 1000 + sortOrder
        )
    }

    // MARK: - attachments(from:): populated join

    func testAttachments_populatedJoin_returnsMappedList() {
        let dto = makeDTO(attachments: [makeAttachmentDTO(sortOrder: 0), makeAttachmentDTO(sortOrder: 1)])
        let result = KudosMapper.attachments(from: dto)

        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].sortOrder, 0)
        XCTAssertEqual(result[0].storagePath, "user/file0.jpg")
        XCTAssertEqual(result[0].contentType, "image/jpeg")
        XCTAssertEqual(result[0].byteSize, 1000)
        XCTAssertEqual(result[1].sortOrder, 1)
    }

    func testAttachments_populatedJoin_sortedBySortOrder() {
        // Deliver in reverse order to verify mapper sorts them.
        let dto = makeDTO(attachments: [makeAttachmentDTO(sortOrder: 2), makeAttachmentDTO(sortOrder: 0), makeAttachmentDTO(sortOrder: 1)])
        let result = KudosMapper.attachments(from: dto)

        XCTAssertEqual(result.map(\.sortOrder), [0, 1, 2])
    }

    // MARK: - attachments(from:): nil join with photo_url fallback

    func testAttachments_nilJoin_withPhotoURL_returnsSyntheticAttachment() {
        let dto = makeDTO(photoURL: "https://example.com/photo.jpg", attachments: nil)
        let result = KudosMapper.attachments(from: dto)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].storagePath, "https://example.com/photo.jpg")
        XCTAssertEqual(result[0].contentType, "image/jpeg")
        XCTAssertEqual(result[0].sortOrder, 0)
        XCTAssertEqual(result[0].byteSize, 0)  // synthetic — byte size unknown
    }

    // MARK: - attachments(from:): empty join with photo_url fallback

    func testAttachments_emptyJoin_withPhotoURL_returnsSyntheticAttachment() {
        let dto = makeDTO(photoURL: "https://example.com/photo.jpg", attachments: [])
        let result = KudosMapper.attachments(from: dto)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].storagePath, "https://example.com/photo.jpg")
    }

    // MARK: - attachments(from:): nil join, nil photo_url → empty

    func testAttachments_nilJoinAndNilPhotoURL_returnsEmpty() {
        let dto = makeDTO(photoURL: nil, attachments: nil)
        let result = KudosMapper.attachments(from: dto)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - attachments(from:): empty join, nil photo_url → empty

    func testAttachments_emptyJoinAndNilPhotoURL_returnsEmpty() {
        let dto = makeDTO(photoURL: nil, attachments: [])
        let result = KudosMapper.attachments(from: dto)
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - attachments(from:): populated join takes precedence over photo_url

    func testAttachments_populatedJoin_ignoresPhotoURL() {
        // When the join has rows, photo_url back-compat must not be applied.
        let dto = makeDTO(
            photoURL: "https://example.com/legacy.jpg",
            attachments: [makeAttachmentDTO(sortOrder: 0)]
        )
        let result = KudosMapper.attachments(from: dto)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].storagePath, "user/file0.jpg")  // from join, not photo_url
    }

    // MARK: - Full KudosMapper.from: attachments field populated

    func testFullMapper_populatesAttachmentsOnKudos() {
        let dto = makeDTO(attachments: [makeAttachmentDTO(sortOrder: 0)])
        let kudos = KudosMapper.from(dto, currentUserId: currentId, isLikedByMe: false)

        XCTAssertEqual(kudos.attachments.count, 1)
        XCTAssertEqual(kudos.attachments[0].sortOrder, 0)
    }

    func testFullMapper_noAttachments_emptyList() {
        let dto = makeDTO(photoURL: nil, attachments: [])
        let kudos = KudosMapper.from(dto, currentUserId: currentId, isLikedByMe: false)
        XCTAssertTrue(kudos.attachments.isEmpty)
    }
}
