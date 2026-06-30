#if DEBUG
import Foundation

// MARK: - MockAwardsRepository

/// In-memory `AwardsRepositoryProtocol` for UI-test scenarios. Returns a small
/// canned roster instantly so `HomeView` reaches `.loaded` on first frame —
/// no Supabase round-trip, no `AwardsLoadingView` shimmer, no non-quiescent
/// state for XCUITest to wait on.
///
/// Mirrors the seam already used for `AuthRepositoryProtocol` via
/// `NoopAuthRepository`. Wired in `saaApp.init` when `-uiTestMode` is set —
/// see the comment block above `awardsRepository = ...` that flagged this as
/// "mock injection happens at the repository level when needed later."
///
/// Without this seam, `AwardsLoadingView`'s `repeatForever` shimmer keeps the
/// view tree non-quiescent until URLSession times out (~60s) on the CI runner,
/// which races the 3s `waitForExistence` window in HomeIntegrationUITests
/// (`testLanguagePickerOpensInlineDropdown` in particular).
struct MockAwardsRepository: AwardsRepositoryProtocol {

    /// Drives `fetchAwards()` so UI tests can exercise loaded / empty / error
    /// branches without standing up a network stub. The XCUITest layer picks
    /// the behavior via the `-uiTestMode` launch argument.
    enum Behavior {
        case happy
        case empty
        case error
    }

    let behavior: Behavior

    init(behavior: Behavior = .happy) {
        self.behavior = behavior
    }

    func fetchAwards() async throws -> [Award] {
        switch behavior {
        case .happy:
            // All 6 awards sorted by sortOrder ascending — mirrors seed-awards.sql and
            // HomeMockData.previewAwards. UUIDs are deterministic so XCUITest
            // accessibility-identifier lookups are stable across launches.
            return [
                Award(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                    code: "top_talent",
                    nameEN: "TOP TALENT",
                    nameVI: "TOP TALENT",
                    descriptionEN: "All-rounded outstanding individuals",
                    descriptionVI: "Cá nhân xuất sắc toàn diện",
                    thumbnailURL: nil,
                    sortOrder: 1,
                    quantity: 10,
                    quantityUnit: "Cá nhân",
                    prizeValueIndividual: "7.000.000 VNĐ",
                    prizeValueTeam: nil,
                    prizeNote: "cho mỗi giải thưởng"
                ),
                Award(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                    code: "top_project",
                    nameEN: "TOP PROJECT",
                    nameVI: "TOP PROJECT",
                    descriptionEN: "Project teams with business results beyond expectations",
                    descriptionVI: "Tập thể dự án xuất sắc vượt kỳ vọng",
                    thumbnailURL: nil,
                    sortOrder: 2,
                    quantity: 2,
                    quantityUnit: "Tập thể",
                    prizeValueIndividual: "15.000.000 VNĐ",
                    prizeValueTeam: nil,
                    prizeNote: "cho mỗi giải thưởng"
                ),
                Award(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                    code: "top_project_leader",
                    nameEN: "TOP PROJECT LEADER",
                    nameVI: "TOP PROJECT LEADER",
                    descriptionEN: "Outstanding project managers — Aim High, Be Agile",
                    descriptionVI: "Nhà quản lý dự án xuất sắc — Aim High, Be Agile",
                    thumbnailURL: nil,
                    sortOrder: 3,
                    quantity: 3,
                    quantityUnit: "Cá nhân",
                    prizeValueIndividual: "7.000.000 VNĐ",
                    prizeValueTeam: nil,
                    prizeNote: "cho mỗi giải thưởng"
                ),
                Award(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
                    code: "best_manager",
                    nameEN: "BEST MANAGER",
                    nameVI: "BEST MANAGER",
                    descriptionEN: "Exemplary leaders driving sustainable growth",
                    descriptionVI: "Nhà lãnh đạo tiêu biểu dẫn dắt phát triển bền vững",
                    thumbnailURL: nil,
                    sortOrder: 4,
                    quantity: 1,
                    quantityUnit: "Cá nhân",
                    prizeValueIndividual: "10.000.000 VNĐ",
                    prizeValueTeam: nil,
                    prizeNote: "cho mỗi giải thưởng"
                ),
                Award(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
                    code: "signature_2026_creator",
                    nameEN: "SIGNATURE 2026 - CREATOR",
                    nameVI: "SIGNATURE 2026 - CREATOR",
                    descriptionEN: "Generative mindset shaping new standards",
                    descriptionVI: "Tư duy kiến tạo, định hình chuẩn mực mới",
                    thumbnailURL: nil,
                    sortOrder: 5,
                    quantity: 1,
                    quantityUnit: "Cá nhân hoặc tập thể",
                    prizeValueIndividual: "5.000.000 VNĐ",
                    prizeValueTeam: "8.000.000 VNĐ",
                    prizeNote: "cho giải cá nhân"
                ),
                Award(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
                    code: "mvp",
                    nameEN: "MVP",
                    nameVI: "MVP",
                    descriptionEN: "Most outstanding individual of the year",
                    descriptionVI: "Cá nhân xuất sắc nhất năm",
                    thumbnailURL: nil,
                    sortOrder: 6,
                    quantity: 1,
                    quantityUnit: "Cá nhân",
                    prizeValueIndividual: "15.000.000 VNĐ",
                    prizeValueTeam: nil,
                    prizeNote: "cho giải cá nhân"
                ),
            ]
        case .empty:
            return []
        case .error:
            throw AwardsError.network
        }
    }
}
#endif
