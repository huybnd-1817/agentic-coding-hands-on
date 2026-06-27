import XCTest
@testable import saa

// MARK: - CreateKudoMapperTests
//
// Verifies `CreateKudoMapper` produces correctly structured DTOs from a
// `CreateKudoRequest`. Pure data transformation — no network I/O.

final class CreateKudoMapperTests: XCTestCase {

    // MARK: - Fixtures

    private let senderId    = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000001")!
    private let recipientId = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000002")!
    private let hashtagId1  = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000003")!
    private let hashtagId2  = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000004")!
    private let kudosId     = UUID(uuidString: "AAAAAAAA-0000-0000-0000-000000000005")!

    private func makeAttachment(sortOrder: Int) -> KudosAttachment {
        KudosAttachment(
            storagePath: "abc/file\(sortOrder).jpg",
            contentType: "image/jpeg",
            byteSize: 1024 * sortOrder + 1,
            sortOrder: sortOrder
        )
    }

    private func makeRequest(
        isAnonymous: Bool = false,
        anonymousNickname: String? = nil,
        attachments: [KudosAttachment] = []
    ) -> CreateKudoRequest {
        CreateKudoRequest(
            recipientId: recipientId,
            senderId: senderId,
            title: "Great Work",
            message: "Really awesome job.",
            hashtagIds: [hashtagId1, hashtagId2],
            attachments: attachments,
            isAnonymous: isAnonymous,
            anonymousNickname: anonymousNickname,
            multiplier: 1
        )
    }

    // MARK: - kudosDTO

    func testKudosDTO_standardFields() {
        let request = makeRequest()
        let dto = CreateKudoMapper.kudosDTO(from: request)

        XCTAssertEqual(dto.sender_id, senderId.uuidString)
        XCTAssertEqual(dto.recipient_id, recipientId.uuidString)
        XCTAssertEqual(dto.title, "Great Work")
        XCTAssertEqual(dto.message, "Really awesome job.")
        XCTAssertFalse(dto.is_anonymous)
        XCTAssertNil(dto.anonymous_nickname)
    }

    func testKudosDTO_anonymousWithNickname() {
        let request = makeRequest(isAnonymous: true, anonymousNickname: "Ghost")
        let dto = CreateKudoMapper.kudosDTO(from: request)

        XCTAssertTrue(dto.is_anonymous)
        XCTAssertEqual(dto.anonymous_nickname, "Ghost")
    }

    func testKudosDTO_nonAnonymous_nilsOutNickname() {
        // Even if a nickname was somehow set but isAnonymous=false, mapper must nil it.
        let request = makeRequest(isAnonymous: false, anonymousNickname: "Should Be Nil")
        let dto = CreateKudoMapper.kudosDTO(from: request)

        XCTAssertFalse(dto.is_anonymous)
        XCTAssertNil(dto.anonymous_nickname)
    }

    // MARK: - hashtagDTOs

    func testHashtagDTOs_count_and_ids() {
        let request = makeRequest()
        let dtos = CreateKudoMapper.hashtagDTOs(kudosId: kudosId, from: request)

        XCTAssertEqual(dtos.count, 2)
        XCTAssertTrue(dtos.allSatisfy { $0.kudos_id == kudosId.uuidString })
        let hashtagIdStrings = dtos.map(\.hashtag_id)
        XCTAssertTrue(hashtagIdStrings.contains(hashtagId1.uuidString))
        XCTAssertTrue(hashtagIdStrings.contains(hashtagId2.uuidString))
    }

    func testHashtagDTOs_empty_whenNoHashtags() {
        let request = CreateKudoRequest(
            recipientId: recipientId,
            senderId: senderId,
            title: "T",
            message: "M",
            hashtagIds: [],
            attachments: [],
            isAnonymous: false,
            anonymousNickname: nil,
            multiplier: 1
        )
        let dtos = CreateKudoMapper.hashtagDTOs(kudosId: kudosId, from: request)
        XCTAssertTrue(dtos.isEmpty)
    }

    // MARK: - attachmentDTOs

    func testAttachmentDTOs_fieldsMap_correctly() {
        let attachment = makeAttachment(sortOrder: 2)
        let request = makeRequest(attachments: [attachment])
        let dtos = CreateKudoMapper.attachmentDTOs(kudosId: kudosId, from: request)

        XCTAssertEqual(dtos.count, 1)
        let dto = dtos[0]
        XCTAssertEqual(dto.kudos_id, kudosId.uuidString)
        XCTAssertEqual(dto.storage_path, "abc/file2.jpg")
        XCTAssertEqual(dto.sort_order, 2)
        XCTAssertEqual(dto.content_type, "image/jpeg")
        XCTAssertEqual(dto.byte_size, 2049)
    }

    func testAttachmentDTOs_sortOrderPreserved() {
        let attachments = [makeAttachment(sortOrder: 0), makeAttachment(sortOrder: 1)]
        let request = makeRequest(attachments: attachments)
        let dtos = CreateKudoMapper.attachmentDTOs(kudosId: kudosId, from: request)

        XCTAssertEqual(dtos.count, 2)
        XCTAssertEqual(dtos[0].sort_order, 0)
        XCTAssertEqual(dtos[1].sort_order, 1)
    }

    func testAttachmentDTOs_empty_whenNoAttachments() {
        let request = makeRequest(attachments: [])
        let dtos = CreateKudoMapper.attachmentDTOs(kudosId: kudosId, from: request)
        XCTAssertTrue(dtos.isEmpty)
    }
}
