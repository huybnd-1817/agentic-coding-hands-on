import XCTest

// MARK: - AwardDetailEntryFromHomeUITests
//
// Integration tests for the Home → Award Detail push navigation:
//   - TC_NAV_001 — Tap "Chi tiết" on Home award card → AwardDetailView mounts
//   - TC_NAV_002 — Back chevron on detail → returns to Home with carousel intact

@MainActor
final class AwardDetailEntryFromHomeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Helpers

    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    // MARK: - TC_NAV_001 — Home card push to Award Detail

    /// Sign in → on Home screen → find the MVP award card's "Chi tiết" button → tap →
    /// assert AwardDetailView mounts with MVP preselected.
    func testHomeCard_tapDetail_pushesAwardDetail() throws {
        let app = XCUIApplication.launching(.signedIn)

        XCTAssertTrue(
            element("home.root", in: app).waitForExistence(timeout: 5),
            "Home must be visible"
        )

        // Find the MVP card's detail button. The card has a "details" button with identifier
        // pattern home.awards.card.{code}.details. For MVP, it's home.awards.card.mvp.details.
        let mvpDetailsButton = element("home.awards.card.mvp.details", in: app)
        XCTAssertTrue(
            mvpDetailsButton.waitForExistence(timeout: 5),
            "MVP award card's detail button must exist on Home"
        )

        mvpDetailsButton.tap()

        // After tap, the AwardDetailView should mount via the HomeRoute.awardDetail push.
        XCTAssertTrue(
            element("award.detail.root", in: app).waitForExistence(timeout: 5),
            "AwardDetailView must push and become visible"
        )

        // Verify the detail view shows an MVP-related affordance. The MVP badge identifier
        // confirms the correct award is selected.
        let mvpBadge = element("award.badge.mvp", in: app)
        XCTAssertTrue(
            mvpBadge.waitForExistence(timeout: 3),
            "MVP badge must be visible on detail screen"
        )
    }

    // MARK: - TC_NAV_002 — Back chevron (DEFERRED)
    //
    // Back navigation from the Home-pushed AwardDetailView is not testable via
    // XCUITest at present. The push destination applies
    // `.toolbar(.hidden, for: .navigationBar)` (see
    // HomeViewContainer.awardDetailDestination:163), which removes the system
    // back chevron. `HomeHeaderView` does not expose a custom back button.
    //
    // A user-facing follow-up is required to add an explicit back affordance
    // to the pushed detail view (e.g. a leading chevron in `HomeHeaderView`
    // with identifier `award.detail.back`). Once that lands, add a test here
    // that exercises the real button — the previous swipe-gesture fallback was
    // flaky on the simulator and produced misleading failures.
}
