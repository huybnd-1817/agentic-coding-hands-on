import XCTest
@testable import saa

// MARK: - KudosDTODecodingTests
//
// Pins KudosDTO to the exact wire shape PostgREST returns for the kudos feed
// query (see SupabaseKudosRepository.kudosSelectClause).  Catches schema /
// nullability / date-format drift between the Postgres column definitions and
// the Codable struct before it manifests at runtime as silently empty cards.
//
// The decoder configured here mirrors the Supabase Swift SDK's defaultDecoder:
// ISO 8601 with fractional seconds, falling back to without fractional seconds.

final class KudosDTODecodingTests: XCTestCase {

    /// Mirrors PostgrestClient.defaultDecoder from supabase-swift.
    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            let withFractional = ISO8601DateFormatter()
            withFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withFractional.date(from: raw) {
                return date
            }
            let plain = ISO8601DateFormatter()
            plain.formatOptions = [.withInternetDateTime]
            if let date = plain.date(from: raw) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported ISO date: \(raw)"
            )
        }
        return decoder
    }

    // MARK: - Fully populated row with joined profiles

    func testKudosDTO_decodesFullJoinedRow() throws {
        let json = """
        [{
          "id": "dccd0a4b-8d4c-489a-9e4b-e5607ecf6df1",
          "sender_id": "ce11ab01-0000-0000-0000-000000000001",
          "recipient_id": "ce11ab01-0000-0000-0000-000000000002",
          "title": "Star of the Sprint",
          "message": "Bạn đã lead technical solution cực kỳ xuất sắc.",
          "is_anonymous": false,
          "anonymous_nickname": null,
          "status": "active",
          "created_at": "2026-06-22T07:35:38.333633+00:00",
          "deleted_at": null,
          "sender":    { "id": "ce11ab01-0000-0000-0000-000000000001", "name": "Alice Lê", "email": "a@x.io", "avatar_url": null, "department_id": null, "user_stats": { "kudos_received_count": 5 } },
          "recipient": { "id": "ce11ab01-0000-0000-0000-000000000002", "name": "Bảo Trần", "email": "b@x.io", "avatar_url": null, "department_id": null, "user_stats": { "kudos_received_count": 2 } },
          "kudos_hashtags": [ { "hashtag": { "id": "c6391823-ffc2-4995-a13f-db56b6432715", "tag": "#Inspiring" } } ],
          "reactions": [ { "count": 7 } ]
        }]
        """

        let rows = try makeDecoder().decode([KudosDTO].self, from: Data(json.utf8))

        XCTAssertEqual(rows.count, 1)
        let row = try XCTUnwrap(rows.first)
        XCTAssertEqual(row.title, "Star of the Sprint")
        XCTAssertEqual(row.sender?.name, "Alice Lê")
        XCTAssertEqual(row.recipient?.name, "Bảo Trần")
        XCTAssertEqual(row.heartCount, 7)
        XCTAssertEqual(row.sender?.kudosReceivedCount, 5)
        XCTAssertEqual(row.kudos_hashtags?.first?.hashtag.tag, "#Inspiring")
    }

    // MARK: - RLS-denied profile joins arrive as null

    /// When `profiles` SELECT is restricted (the original RLS policy), PostgREST
    /// returns `sender: null` / `recipient: null` for non-self profiles.  The
    /// DTO must still decode — these fields are intentionally Optional.
    func testKudosDTO_decodesNullJoinedProfiles() throws {
        let json = """
        [{
          "id": "dccd0a4b-8d4c-489a-9e4b-e5607ecf6df1",
          "sender_id": "ce11ab01-0000-0000-0000-000000000001",
          "recipient_id": "ce11ab01-0000-0000-0000-000000000002",
          "title": "Star of the Sprint",
          "message": "hi",
          "is_anonymous": false,
          "anonymous_nickname": null,
          "status": "active",
          "created_at": "2026-06-22T07:35:38.333633+00:00",
          "deleted_at": null,
          "sender": null,
          "recipient": null,
          "kudos_hashtags": [],
          "reactions": [ { "count": 0 } ]
        }]
        """

        let rows = try makeDecoder().decode([KudosDTO].self, from: Data(json.utf8))
        let row = try XCTUnwrap(rows.first)
        XCTAssertNil(row.sender)
        XCTAssertNil(row.recipient)
        XCTAssertEqual(row.heartCount, 0)
    }

    // MARK: - Nested user_stats null while parent profile is visible

    /// Cross-user `user_stats` is denied by RLS even when `profiles` is open.
    /// The decoded profile must tolerate `user_stats: null` and fall back to a
    /// `kudosReceivedCount` of 0.
    func testKudosProfileDTO_userStatsNullFallsBackToZeroCount() throws {
        let json = """
        {
          "id": "ce11ab01-0000-0000-0000-000000000001",
          "name": "Alice Lê",
          "email": "a@x.io",
          "avatar_url": null,
          "department_id": null,
          "user_stats": null
        }
        """

        let profile = try makeDecoder().decode(KudosProfileDTO.self, from: Data(json.utf8))
        XCTAssertEqual(profile.kudosReceivedCount, 0)
    }

    // MARK: - Microsecond date precision

    /// Postgres `timestamptz` is serialised with up to six fractional digits
    /// (`.333633`).  The decoder must accept it; otherwise every row decode
    /// fails and the feed appears empty without an obvious error path.
    func testKudosDTO_acceptsMicrosecondCreatedAt() throws {
        let json = """
        [{
          "id": "dccd0a4b-8d4c-489a-9e4b-e5607ecf6df1",
          "sender_id": "ce11ab01-0000-0000-0000-000000000001",
          "recipient_id": "ce11ab01-0000-0000-0000-000000000002",
          "title": "t", "message": "m", "is_anonymous": false,
          "anonymous_nickname": null, "status": "active",
          "created_at": "2026-06-22T07:35:38.333633+00:00",
          "deleted_at": null,
          "sender": null, "recipient": null,
          "kudos_hashtags": null, "reactions": null
        }]
        """
        XCTAssertNoThrow(try makeDecoder().decode([KudosDTO].self, from: Data(json.utf8)))
    }
}
