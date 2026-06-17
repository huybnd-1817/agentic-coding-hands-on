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
            nameVI: "TOP TALENT",
            descriptionEN: "All-rounded outstanding individuals",
            descriptionVI: "Cá nhân xuất sắc toàn diện",
            thumbnailURL: nil,
            sortOrder: 1
        ),
        Award(
            id: UUID(),
            code: "top_project",
            nameEN: "TOP PROJECT",
            nameVI: "TOP PROJECT",
            descriptionEN: "Project teams with business results beyond expectations",
            descriptionVI: "Tập thể dự án xuất sắc vượt kỳ vọng",
            thumbnailURL: nil,
            sortOrder: 2
        ),
        Award(
            id: UUID(),
            code: "top_project_leader",
            nameEN: "TOP PROJECT LEADER",
            nameVI: "TOP PROJECT LEADER",
            descriptionEN: "Outstanding project managers — Aim High, Be Agile",
            descriptionVI: "Nhà quản lý dự án xuất sắc — Aim High, Be Agile",
            thumbnailURL: nil,
            sortOrder: 3
        ),
        Award(
            id: UUID(),
            code: "best_manager",
            nameEN: "BEST MANAGER",
            nameVI: "BEST MANAGER",
            descriptionEN: "Exemplary leaders driving sustainable growth",
            descriptionVI: "Nhà lãnh đạo tiêu biểu dẫn dắt phát triển bền vững",
            thumbnailURL: nil,
            sortOrder: 4
        ),
        Award(
            id: UUID(),
            code: "signature_2026_creator",
            nameEN: "SIGNATURE 2026 - CREATOR",
            nameVI: "SIGNATURE 2026 - CREATOR",
            descriptionEN: "Generative mindset shaping new standards",
            descriptionVI: "Tư duy kiến tạo, định hình chuẩn mực mới",
            thumbnailURL: nil,
            sortOrder: 5
        ),
        Award(
            id: UUID(),
            code: "mvp",
            nameEN: "MVP",
            nameVI: "MVP",
            descriptionEN: "Most outstanding individual of the year",
            descriptionVI: "Cá nhân xuất sắc nhất năm",
            thumbnailURL: nil,
            sortOrder: 6
        ),
    ]

    static let previewCountdown = Countdown(days: 20, hours: 20, minutes: 20)
}
#endif
