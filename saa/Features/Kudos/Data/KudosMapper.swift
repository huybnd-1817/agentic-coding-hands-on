import Foundation

// MARK: - KudosMapper

/// Lifts a `KudosDTO` (Data) into a `Kudos` (Domain), applying anonymous
/// sender masking when the current user is not the sender.
///
/// Anonymous masking rule (clarifications.md, phase-06 lines 66-78):
/// When `is_anonymous == true` AND `sender_id != currentUserId`, strip all
/// sender identity fields: `userId = nil`, `displayName = anonymous_nickname ?? "Ẩn danh"`,
/// `employeeCode = nil`, `avatarURL = nil`, `departmentId = nil`.
/// The raw fallback `"Ẩn danh"` is a placeholder; the view layer should
/// replace it with a `LocalizedStringKey` resolution for i18n.
///
/// This is the ONLY place anonymous masking is applied — never in Domain,
/// never in the repository itself.
enum KudosMapper {

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

    // MARK: - Primary mapping

    /// Maps a `KudosDTO` to a `Kudos` domain entity.
    ///
    /// - Parameters:
    ///   - dto: The raw DTO decoded from Supabase.
    ///   - currentUserId: The authenticated user's UUID. Nil when unauthenticated
    ///     (fallback: treat all anonymous kudos as masked).
    ///   - isLikedByMe: Whether the current user has reacted — resolved by the
    ///     repository after fetching reaction user_ids for the batch.
    static func from(
        _ dto: KudosDTO,
        currentUserId: UUID?,
        isLikedByMe: Bool
    ) -> Kudos {
        // Build sender — apply masking when anonymous and not self-authored.
        let sender: KudosAuthor
        if dto.is_anonymous, dto.sender_id != currentUserId {
            sender = anonymousAuthor(nickname: dto.anonymous_nickname)
        } else if let profile = dto.sender {
            sender = author(from: profile)
        } else {
            // Sender profile missing from join — degrade gracefully.
            sender = KudosAuthor(
                userId: dto.sender_id,
                displayName: dto.anonymous_nickname ?? "Ẩn danh",
                employeeCode: nil,
                avatarURL: nil,
                departmentId: nil,
                kudosReceivedCount: 0
            )
        }

        // Build recipient — always fully visible.
        let recipient: KudosAuthor
        if let profile = dto.recipient {
            recipient = author(from: profile)
        } else {
            recipient = KudosAuthor(
                userId: dto.recipient_id,
                displayName: "",
                employeeCode: nil,
                avatarURL: nil,
                departmentId: nil,
                kudosReceivedCount: 0
            )
        }

        let hashtags = (dto.kudos_hashtags ?? []).map { HashtagMapper.from($0.hashtag) }

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
            photoURL: dto.photo_url.flatMap(URL.init(string:)),
            heartCount: dto.heartCount,
            isLikedByMe: isLikedByMe,
            canLike: canLike,
            shareURL: nil,  // Deep-link URL generation deferred to phase-07
            createdAt: dto.created_at
        )
    }
}
