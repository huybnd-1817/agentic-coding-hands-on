import Foundation

// MARK: - CreateKudoAttachmentDTO

/// Wire-format body for a single row in the `kudos_attachments` table.
///
/// Inserted in a batch after the parent kudos row is confirmed.
/// `sort_order` is zero-based, matching the order images were selected by the user.
/// `content_type` must be `"image/jpeg"` or `"image/png"` (enforced by client-side
/// `CreateKudoValidator` before upload, and by Storage bucket MIME policy on the server).
struct CreateKudoAttachmentDTO: Encodable, Sendable {

    let kudos_id: String
    let storage_path: String
    let sort_order: Int
    let content_type: String
    let byte_size: Int

    enum CodingKeys: String, CodingKey {
        case kudos_id
        case storage_path
        case sort_order
        case content_type
        case byte_size
    }
}
