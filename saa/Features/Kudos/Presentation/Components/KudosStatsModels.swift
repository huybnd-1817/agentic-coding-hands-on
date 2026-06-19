import Foundation

// MARK: - Personal Stats

/// Aggregated personal statistics displayed in the D.1 Personal Stats card.
///
/// All counts are non-negative integers sourced from Supabase `user_stats`.
/// Use `KudosPersonalStatsData.mock` for previews and unit tests.
struct KudosPersonalStatsData: Hashable {
    let kudosReceived: Int
    let kudosSent: Int
    let heartsReceived: Int
    let secretBoxesOpened: Int
    let secretBoxesUnopened: Int

    static let mock = KudosPersonalStatsData(
        kudosReceived: 25,
        kudosSent: 25,
        heartsReceived: 25,
        secretBoxesOpened: 25,
        secretBoxesUnopened: 25
    )
}

// MARK: - Top Recipients

/// A single entry in the D.3 "10 SUNNER NHẬN QUÀ MỚI NHẤT" list.
///
/// `avatarAssetName` is a local xcassets key (used while the user's remote
/// avatar is loading); production code will supersede it with `AsyncImage`.
/// `rewardLabel` holds the raw Vietnamese reward string, e.g. "Nhận được 1 áo phông SAA".
struct KudosRecipientData: Identifiable, Hashable {
    let id: String
    let name: String
    let avatarAssetName: String
    let rewardLabel: String

    static let mockList: [KudosRecipientData] = [
        KudosRecipientData(id: "1", name: "Huỳnh Dương Xuân",  avatarAssetName: "kudos-card-avatar-female",    rewardLabel: "Nhận được 1 áo phông SAA"),
        KudosRecipientData(id: "2", name: "Nguyễn Đức Huy",    avatarAssetName: "kudos-card-avatar-male",      rewardLabel: "Nhận được 1 áo phông SAA"),
        KudosRecipientData(id: "3", name: "Trần Thị Lan",       avatarAssetName: "kudos-card-avatar-recipient", rewardLabel: "Nhận được 1 túi vải Sun*"),
        KudosRecipientData(id: "4", name: "Lê Văn Minh",        avatarAssetName: "kudos-card-avatar-male",      rewardLabel: "Nhận được 1 áo phông SAA"),
        KudosRecipientData(id: "5", name: "Phạm Thị Hoa",       avatarAssetName: "kudos-card-avatar-female",    rewardLabel: "Nhận được 1 áo phông SAA"),
    ]
}

// MARK: - Type alias

/// Opaque identifier matching `KudosRecipientData.id`.
typealias KudosRecipientID = String
