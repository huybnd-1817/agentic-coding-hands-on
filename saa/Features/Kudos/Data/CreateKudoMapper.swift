import Foundation

// MARK: - CreateKudoMapper

/// Converts a `CreateKudoRequest` (Domain) into the set of DTOs required for the
/// three-step Supabase INSERT flow:
///   1. `CreateKudoDTO`           → `POST /kudos`
///   2. `[CreateKudoHashtagDTO]`  → `POST /kudos_hashtags` (batch)
///   3. `[CreateKudoAttachmentDTO]` → `POST /kudos_attachments` (batch, when attachments present)
///
/// Pure data transformation — no network I/O, no side-effects.
enum CreateKudoMapper {

    // MARK: - Kudos body

    /// Maps the request to the kudos INSERT body.
    ///
    /// `sender_id` is included and validated server-side against `auth.uid()` by RLS.
    static func kudosDTO(from request: CreateKudoRequest) -> CreateKudoDTO {
        CreateKudoDTO(
            sender_id: request.senderId.uuidString,
            recipient_id: request.recipientId.uuidString,
            title: request.title,
            message: request.message,
            is_anonymous: request.isAnonymous,
            anonymous_nickname: request.isAnonymous ? request.anonymousNickname : nil
        )
    }

    // MARK: - Hashtag join rows

    /// Maps the selected hashtag IDs to batch-insert rows for `kudos_hashtags`.
    ///
    /// - Parameters:
    ///   - kudosId: The UUID returned by the kudos INSERT (used as FK).
    ///   - request: The validated create-kudo request carrying `hashtagIds`.
    static func hashtagDTOs(kudosId: UUID, from request: CreateKudoRequest) -> [CreateKudoHashtagDTO] {
        request.hashtagIds.map { hashtagId in
            CreateKudoHashtagDTO(
                kudos_id: kudosId.uuidString,
                hashtag_id: hashtagId.uuidString
            )
        }
    }

    // MARK: - Attachment rows

    /// Maps uploaded `KudosAttachment` values to batch-insert rows for `kudos_attachments`.
    ///
    /// Returns an empty array when `request.attachments` is empty — the caller skips
    /// the batch insert in that case (no unnecessary network round-trip).
    ///
    /// - Parameters:
    ///   - kudosId: The UUID returned by the kudos INSERT (used as FK).
    ///   - request: The validated request carrying pre-uploaded `KudosAttachment` values.
    static func attachmentDTOs(kudosId: UUID, from request: CreateKudoRequest) -> [CreateKudoAttachmentDTO] {
        request.attachments.map { attachment in
            CreateKudoAttachmentDTO(
                kudos_id: kudosId.uuidString,
                storage_path: attachment.storagePath,
                sort_order: attachment.sortOrder,
                content_type: attachment.contentType,
                byte_size: attachment.byteSize
            )
        }
    }
}
