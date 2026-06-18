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
            return [
                Award(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                    code: "top_talent",
                    nameEN: "TOP TALENT",
                    nameVI: "TOP TALENT",
                    descriptionEN: "All-rounded outstanding individuals",
                    descriptionVI: "Cá nhân xuất sắc toàn diện",
                    thumbnailURL: nil,
                    sortOrder: 1
                )
            ]
        case .empty:
            return []
        case .error:
            throw AwardsError.network
        }
    }
}
#endif
