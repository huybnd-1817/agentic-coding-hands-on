import Foundation

// MARK: - UserStatsMapper

/// Lifts a `UserStatsDTO` (Data) into a `UserStats` (Domain).
enum UserStatsMapper {

    static func from(_ dto: UserStatsDTO) -> UserStats {
        UserStats(
            userId: dto.user_id,
            kudosReceivedCount: dto.kudos_received_count,
            kudosSentCount: dto.kudos_sent_count,
            kudosHeartsReceived: dto.kudos_hearts_received,
            secretBoxesOpened: dto.secret_boxes_opened,
            secretBoxesUnopened: dto.secret_boxes_unopened,
            updatedAt: dto.updated_at
        )
    }
}
