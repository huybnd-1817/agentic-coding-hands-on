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
            element("award.detail.root", in: app).waitForExistence(timeout: 3),
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

    // MARK: - TC_NAV_002 — Back chevron returns to Home

    /// After entering detail from Home → tap back chevron → assert Home is visible again
    /// with the carousel still intact.
    func testBackChevron_returnsToHome() throws {
        let app = XCUIApplication.launching(.signedIn)

        XCTAssertTrue(
            element("home.root", in: app).waitForExistence(timeout: 5),
            "Home must be visible"
        )

        // Tap the MVP detail button to enter the detail view.
        // MVP is the last of 6 awards — wait for it to appear in the carousel.
        let mvpDetailsButton = element("home.awards.card.mvp.details", in: app)
        XCTAssertTrue(
            mvpDetailsButton.waitForExistence(timeout: 5),
            "MVP award card detail button must exist before tapping"
        )
        mvpDetailsButton.tap()

        XCTAssertTrue(
            element("award.detail.root", in: app).waitForExistence(timeout: 3),
            "AwardDetailView must be visible"
        )

        // The detail view has a back chevron in the header. Locate it via the
        // HomeHeaderView's back button identifier (typically in the nav bar).
        // For safety, we look for the award detail root, then the back nav element
        // which may be exposed by HomeHeaderView. If not explicitly marked, we can
        // use a simple back navigation via the system back gesture or button.
        //
        // SwiftUI's NavigationStack on iOS 16+ uses the system back gesture, so
        // swiping from left edge should work. Alternatively, look for the back button.

        let back = element("award.detail.back", in: app)
        if back.exists {
            back.tap()
        } else {
            // Fallback: use the system back gesture (swipe from left).
            let detailRoot = element("award.detail.root", in: app)
            if detailRoot.exists {
                let start = detailRoot.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
                let end = detailRoot.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
                start.press(forDuration: 0, thenDragTo: end)
            }
        }

        // After back, Home should be visible again.
        XCTAssertTrue(
            element("home.root", in: app).waitForExistence(timeout: 3),
            "Home must be visible after back navigation"
        )

        // The awards carousel should still be intact (no crash, no empty state).
        let carousel = element("home.awards.carousel", in: app)
        XCTAssertTrue(
            carousel.exists || element("home.awards.card.mvp.details", in: app).exists,
            "Awards carousel must still be present after returning from detail"
        )
    }
}
