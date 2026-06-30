import Foundation

// MARK: - KudosMapper

/// Lifts `KudosDTO` → `Kudos`. Anonymous sender masking is applied here ONLY
/// (never in Domain or repository). When `is_anonymous` and the viewer is
/// not the sender, all sender identity fields are stripped; the raw "Ẩn danh"
/// fallback is a placeholder for the view layer's i18n resolution.
enum KudosMapper {

    // MARK: - Attachment mapping

    /// Maps `kudos_attachments` join rows. Migration 20260630000000 dropped
    /// `kudos.photo_url` and backfilled into this table.
    static func attachments(from dto: KudosDTO) -> [KudosAttachment] {
        (dto.kudos_attachments ?? [])
            .sorted { $0.sort_order < $1.sort_order }
            .map { row in
                KudosAttachment(
                    storagePath: row.storage_path,
                    contentType: row.content_type,
                    byteSize: row.byte_size,
                    sortOrder: row.sort_order
                )
            }
    }

    // MARK: - Author helpers

    /// Maps a `KudosProfileDTO` to a `KudosAuthor`, preserving all identity fields.
    static func author(from profile: KudosProfileDTO) -> KudosAuthor {
        KudosAuthor(
            userId: profile.id,
            displayName: profile.name ?? profile.email,
            employeeCode: nil,  // profiles table has no employee_code column (phase-05 note)
            avatarURL: profile.avatar_url.flatMap(URL.init(string:)),
            departmentId: profile.department_id,
            kudosReceivedCount: profile.kudosReceivedCount
        )
    }

    /// Returns an anonymised `KudosAuthor` for non-sender viewers.
    static func anonymousAuthor(nickname: String?) -> KudosAuthor {
        KudosAuthor(
            userId: nil,
            displayName: nickname ?? "Ẩn danh",
            employeeCode: nil,
            avatarURL: nil,
            departmentId: nil,
            kudosReceivedCount: 0
        )
    }

    /// Fallback author used when a profile join row is missing.
    /// `userId` is preserved when known so callers can still navigate; identity
    /// fields are nil/empty so the view renders a placeholder.
    private static func fallbackAuthor(userId: UUID?, displayName: String) -> KudosAuthor {
        KudosAuthor(
            userId: userId,
            displayName: displayName,
            employeeCode: nil,
            avatarURL: nil,
            departmentId: nil,
            kudosReceivedCount: 0
        )
    }

    /// Resolves the sender author with anonymous masking applied.
    /// Returns the anonymised author when the kudos is anonymous and the viewer
    /// is not the sender; otherwise the joined profile, falling back to a
    /// placeholder when the join row is missing.
    private static func senderAuthor(from dto: KudosDTO, currentUserId: UUID?) -> KudosAuthor {
        if dto.is_anonymous, dto.sender_id != currentUserId {
            return anonymousAuthor(nickname: dto.anonymous_nickname)
        }
        if let profile = dto.sender {
            return author(from: profile)
        }
        return fallbackAuthor(userId: dto.sender_id, displayName: dto.anonymous_nickname ?? "Ẩn danh")
    }

    // MARK: - Primary mapping

    /// - `currentUserId` nil → unauthenticated → all anonymous kudos are masked.
    /// - `isLikedByMe` is resolved by the repository for the whole batch.
    static func from(
        _ dto: KudosDTO,
        currentUserId: UUID?,
        isLikedByMe: Bool,
        hashtagsOverride: [Hashtag]? = nil
    ) -> Kudos {
        let sender = senderAuthor(from: dto, currentUserId: currentUserId)

        // Recipient is always fully visible; degrade gracefully when join missing.
        let recipient = dto.recipient.map(author(from:))
            ?? fallbackAuthor(userId: dto.recipient_id, displayName: "")

        // `hashtagsOverride` is supplied by the repository when an active
        // hashtag filter is in effect — the embedded `kudos_hashtags` join is
        // pruned by PostgREST in that case, so the override carries the full,
        // unpruned hashtag list fetched in a second query.
        let hashtags = hashtagsOverride
            ?? (dto.kudos_hashtags ?? []).map { HashtagMapper.from($0.hashtag) }

        // canLike: false when the current user is the sender (TC_FUN_008).
        // RLS also enforces this server-side; this flag prevents the UI from
        // even attempting the request.
        let canLike = currentUserId != nil && dto.sender_id != currentUserId

        return Kudos(
            id: dto.id,
            sender: sender,
            recipient: recipient,
            title: dto.title,
            message: dto.message,
            isAnonymous: dto.is_anonymous,
            anonymousNickname: dto.anonymous_nickname,
            hashtags: hashtags,
            attachments: attachments(from: dto),
            heartCount: dto.heartCount,
            isLikedByMe: isLikedByMe,
            canLike: canLike,
            shareURL: nil,  // Deep-link URL generation deferred to phase-07
            createdAt: dto.created_at
        )
    }
}
