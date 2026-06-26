import Foundation

// MARK: - CreateKudoHashtagDTO

/// Wire-format body for a single row in the `kudos_hashtags` join table.
///
/// Inserted in a batch after the parent kudos row is confirmed.
/// The combination `(kudos_id, hashtag_id)` has a unique constraint; the RLS
/// INSERT policy checks `auth.uid() = (SELECT sender_id FROM kudos WHERE id = kudos_id)`.
struct CreateKudoHashtagDTO: Encodable, Sendable {

    let kudos_id: String
    let hashtag_id: String

    enum CodingKeys: String, CodingKey {
        case kudos_id
        case hashtag_id
    }
}
