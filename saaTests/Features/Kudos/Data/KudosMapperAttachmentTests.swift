import XCTest
@testable import saa

// MARK: - KudosMapperAttachmentTests
//
// Verifies `KudosMapper.attachments(from:)` and the full `KudosMapper.from`
// path with respect to attachment mapping.
//
// Migration 20260630000000 dropped `kudos.photo_url` and backfilled any
// legacy URLs into `kudos_attachments` (sort_order = 0), so the mapper no
// longer has a photo_url fallback path. These tests assert the join-only
// behaviour.

final class KudosMapperAttachmentTests: XCTestCase {

    // MARK: - Fixtures

    private let senderId    = UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000001")!
    private let recipientId = UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000002")!
    private let currentId   = UUID(uuidString: "BBBBBBBB-0000-0000-0000-000000000003")!

    private func makeDTO(
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

    // MARK: - attachments(from:): nil / empty join → empty list

    func testAttachments_nilJoin_returnsEmpty() {
        let result = KudosMapper.attachments(from: makeDTO(attachments: nil))
        XCTAssertTrue(result.isEmpty)
    }

    func testAttachments_emptyJoin_returnsEmpty() {
        let result = KudosMapper.attachments(from: makeDTO(attachments: []))
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - Full KudosMapper.from: attachments field populated

    func testFullMapper_populatesAttachmentsOnKudos() {
        let dto = makeDTO(attachments: [makeAttachmentDTO(sortOrder: 0)])
        let kudos = KudosMapper.from(dto, currentUserId: currentId, isLikedByMe: false)

        XCTAssertEqual(kudos.attachments.count, 1)
        XCTAssertEqual(kudos.attachments[0].sortOrder, 0)
    }

    func testFullMapper_noAttachments_emptyList() {
        let dto = makeDTO(attachments: [])
        let kudos = KudosMapper.from(dto, currentUserId: currentId, isLikedByMe: false)
        XCTAssertTrue(kudos.attachments.isEmpty)
    }
}
