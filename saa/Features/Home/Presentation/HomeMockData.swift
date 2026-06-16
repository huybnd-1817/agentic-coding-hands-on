import Foundation

// MARK: - HomeMockData

/// DEBUG-only fixture data used by SwiftUI Previews after Phase 07 integration.
///
/// Real `Award` / `Countdown` / `AwardsState` types replace the prior `MockAward`,
/// `MockCountdown`, and `HomeAwardsState` enums. `NavTab` was extracted to
/// `NavTab.swift` so a future cleanup of preview fixtures cannot accidentally
/// delete a production type.

#if DEBUG
enum HomeMockData {

    /// Sample awards used by SwiftUI Previews. Matches the seed in
    /// `supabase/seeds/dev/seed-awards.sql`.
    static let previewAwards: [Award] = [
        Award(
            id: UUID(),
            code: "top_talent",
            nameEN: "TOP TALENT",
            nameVI: "TÀI NĂNG NỔI BẬT",
            descriptionEN: "Outstanding individual performance",
            descriptionVI: "Cá nhân xuất sắc trong năm",
            thumbnailURL: nil,
            sortOrder: 1
        ),
        Award(
            id: UUID(),
            code: "top_project",
            nameEN: "TOP PROJECT",
            nameVI: "DỰ ÁN XUẤT SẮC",
            descriptionEN: "Best delivered project of the year",
            descriptionVI: "Dự án vận hành tốt nhất năm",
            thumbnailURL: nil,
            sortOrder: 2
        ),
        Award(
            id: UUID(),
            code: "top_culture_fit",
            nameEN: "TOP CULTURE FIT",
            nameVI: "PHÙ HỢP VĂN HÓA",
            descriptionEN: "Embodies the Sun* spirit",
            descriptionVI: "Đại diện tinh thần Sun*",
            thumbnailURL: nil,
            sortOrder: 3
        ),
        Award(
            id: UUID(),
            code: "top_new_sunner",
            nameEN: "TOP NEW SUNNER",
            nameVI: "SUNNER MỚI XUẤT SẮC",
            descriptionEN: "Top performer in their first year",
            descriptionVI: "Người mới xuất sắc nhất",
            thumbnailURL: nil,
            sortOrder: 4
        ),
    ]

    static let previewCountdown = Countdown(days: 20, hours: 20, minutes: 20)
}
#endif
