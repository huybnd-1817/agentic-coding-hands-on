//
//  KudosCardAdapterTests.swift
//  saaTests
//
//  Unit tests for KudosCardAdapter — the pure-functional Domain → UI mapper
//  shared by KudosViewContainer (preview) and AllKudosViewContainer (paginated feed).
//
//  Tests cover:
//    - Timestamp formatting in Asia/Saigon timezone
//    - Hashtag stripping of leading '#'
//    - Department code lookup fallback
//    - Star-tier derivation from kudos-received count
//    - Avatar asset selection by user ID parity
//

import XCTest
@testable import saa

final class KudosCardAdapterTests: XCTestCase {

    // MARK: - Test Fixtures (inline, deterministic)

    private func makeAuthor(
        userId: UUID? = nil,
        displayName: String = "Test Author",
        employeeCode: String? = "EMPCODE",
        departmentId: UUID? = nil,
        kudosReceivedCount: Int = 0
    ) -> KudosAuthor {
        KudosAuthor(
            userId: userId,
            displayName: displayName,
            employeeCode: employeeCode,
            avatarURL: nil,
            departmentId: departmentId,
            kudosReceivedCount: kudosReceivedCount
        )
    }

    private func makeDepartment(
        id: UUID,
        code: String = "DEPT",
        name: String = "Test Department"
    ) -> Department {
        Department(id: id, code: code, name: name)
    }

    private func makeKudos(
        id: UUID = UUID(),
        sender: KudosAuthor? = nil,
        recipient: KudosAuthor? = nil,
        title: String = "Test Title",
        message: String = "Test message",
        hashtags: [Hashtag] = [],
        createdAt: Date = Date()
    ) -> Kudos {
        let defaultSender = sender ?? makeAuthor(displayName: "Default Sender")
        let defaultRecipient = recipient ?? makeAuthor(displayName: "Default Recipient")

        return Kudos(
            id: id,
            sender: defaultSender,
            recipient: defaultRecipient,
            title: title,
            message: message,
            isAnonymous: false,
            anonymousNickname: nil,
            hashtags: hashtags,
            photoURL: nil,
            attachments: [],
            heartCount: 0,
            isLikedByMe: false,
            canLike: true,
            shareURL: nil,
            createdAt: createdAt
        )
    }

    // MARK: - Tests

    /// Test 1: Timestamp formats correctly in Asia/Saigon timezone.
    /// UTC epoch (0) = 1970-01-01T00:00:00Z = 1970-01-01T08:00:00 in Asia/Saigon.
    func test_cardData_formatsTimestamp_inAsiaSaigon() {
        let departments: [UUID: Department] = [:]
        let sender = makeAuthor()
        let recipient = makeAuthor()
        let epochDate = Date(timeIntervalSince1970: 0)

        let kudos = makeKudos(sender: sender, recipient: recipient, createdAt: epochDate)
        let cardData = KudosCardAdapter.cardData(from: kudos, departments: departments)

        // Asia/Saigon is UTC+8; epoch 0 is 1970-01-01 08:00:00 in that zone.
        // Format string is "HH:mm - MM/dd/yyyy", so "08:00 - 01/01/1970"
        XCTAssertEqual(cardData.timestampText, "08:00 - 01/01/1970")
    }

    /// Test 2: Strips leading '#' from hashtags.
    /// Input: ["#Dedicated", "#Inspiring"] → Output: ["Dedicated", "Inspiring"]
    func test_cardData_stripsLeadingHash_fromHashtags() {
        let departments: [UUID: Department] = [:]
        let sender = makeAuthor()
        let recipient = makeAuthor()
        let hashtags = [
            Hashtag(id: UUID(), tag: "#Dedicated"),
            Hashtag(id: UUID(), tag: "#Inspiring")
        ]

        let kudos = makeKudos(sender: sender, recipient: recipient, hashtags: hashtags)
        let cardData = KudosCardAdapter.cardData(from: kudos, departments: departments)

        XCTAssertEqual(cardData.hashtags, ["Dedicated", "Inspiring"])
    }

    /// Test 3: Preserves hashtags that don't have a leading '#'.
    /// Input: ["Teamwork"] (no '#') → Output: ["Teamwork"] (unchanged, defensive).
    func test_cardData_preservesHashtag_whenNoLeadingHash() {
        let departments: [UUID: Department] = [:]
        let sender = makeAuthor()
        let recipient = makeAuthor()
        let hashtags = [
            Hashtag(id: UUID(), tag: "Teamwork")
        ]

        let kudos = makeKudos(sender: sender, recipient: recipient, hashtags: hashtags)
        let cardData = KudosCardAdapter.cardData(from: kudos, departments: departments)

        XCTAssertEqual(cardData.hashtags, ["Teamwork"])
    }

    /// Test 4: Propagates star tier for both sender and recipient.
    /// Sender: 25 received → 2★; Recipient: 60 received → 3★.
    func test_cardData_propagatesStarTier_forBothParties() {
        let departments: [UUID: Department] = [:]
        let sender = makeAuthor(kudosReceivedCount: 25)
        let recipient = makeAuthor(kudosReceivedCount: 60)

        let kudos = makeKudos(sender: sender, recipient: recipient)
        let cardData = KudosCardAdapter.cardData(from: kudos, departments: departments)

        XCTAssertEqual(cardData.senderStarTier, .two)
        XCTAssertEqual(cardData.recipientStarTier, .three)
    }

    /// Test 5: codeLabel returns department code when department is found.
    func test_codeLabel_returnsDepartmentCode_whenDepartmentIdMatchesLookup() {
        let deptId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let dept = makeDepartment(id: deptId, code: "CEV1")
        let departments = [deptId: dept]

        let author = makeAuthor(employeeCode: "EMPCODE", departmentId: deptId)

        let result = KudosCardAdapter.codeLabel(for: author, departments: departments)

        XCTAssertEqual(result, "CEV1")
    }

    /// Test 6: codeLabel falls back to employee code when department is not in lookup.
    func test_codeLabel_fallsBackToEmployeeCode_whenDepartmentIdNotInLookup() {
        let deptId = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let author = makeAuthor(employeeCode: "EMPCODE123", departmentId: deptId)
        let departments: [UUID: Department] = [:] // No departments

        let result = KudosCardAdapter.codeLabel(for: author, departments: departments)

        XCTAssertEqual(result, "EMPCODE123")
    }

    /// Test 7: codeLabel returns empty string when both department and employee code are missing.
    func test_codeLabel_returnsEmpty_whenBothDepartmentAndEmployeeCodeMissing() {
        let author = makeAuthor(employeeCode: nil, departmentId: nil)
        let departments: [UUID: Department] = [:]

        let result = KudosCardAdapter.codeLabel(for: author, departments: departments)

        XCTAssertEqual(result, "")
    }

    /// Test 8: avatarAsset is deterministic by user ID parity.
    /// Even last byte (e.g., UUID ending in 0x00) → "kudos-card-avatar-female".
    /// Odd last byte (e.g., UUID ending in 0x01) → "kudos-card-avatar-male".
    func test_avatarAsset_deterministicByUserIdParity() {
        // Even last byte: 0x00
        let evenUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        let authorEven = makeAuthor(userId: evenUUID)
        XCTAssertEqual(KudosCardAdapter.avatarAsset(for: authorEven), "kudos-card-avatar-female")

        // Odd last byte: 0x01
        let oddUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let authorOdd = makeAuthor(userId: oddUUID)
        XCTAssertEqual(KudosCardAdapter.avatarAsset(for: authorOdd), "kudos-card-avatar-male")
    }

    /// Test 9: avatarAsset falls back to "kudos-card-avatar-recipient" when userId is nil.
    func test_avatarAsset_anonymousFallback_whenUserIdNil() {
        let author = makeAuthor(userId: nil)

        let result = KudosCardAdapter.avatarAsset(for: author)

        XCTAssertEqual(result, "kudos-card-avatar-recipient")
    }
}
