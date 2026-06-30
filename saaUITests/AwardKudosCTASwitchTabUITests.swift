import XCTest

// MARK: - AwardKudosCTASwitchTabUITests
//
// Integration test for the Sun* Kudos promo block CTA on Award Detail:
//   - TC_FUN_015 — Tap "Chi tiết" on Kudos promo → switch to Kudos tab

@MainActor
final class AwardKudosCTASwitchTabUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Helpers

    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    // MARK: - TC_FUN_015 — Kudos CTA switches to Kudos tab

    /// On Award Detail → scroll to Kudos promo block → tap CTA → assert Kudos tab becomes active.
    func testKudosCTA_onAwardDetail_switchesToKudosTab() throws {
        let app = XCUIApplication.launching(.signedIn)

        XCTAssertTrue(
            app.navigateToAwardsTab(timeout: 5),
            "Awards tab must mount AwardDetailView"
        )

        // The Kudos promo block is at the bottom of the scrollable content.
        // Scroll down to ensure it's visible.
        let scrollView = element("award.detail.root", in: app)
        if scrollView.exists {
            scrollView.swipeUp()
        }

        let kudosCtaButton = element("award.kudos.cta", in: app)
        XCTAssertTrue(
            kudosCtaButton.waitForExistence(timeout: 3),
            "Kudos CTA button must be visible after scrolling"
        )

        kudosCtaButton.tap()

        // After tap, the Kudos tab should become active. Verify by looking for
        // Kudos-specific identifiers on the screen. For example, the Kudos root view
        // should be visible, or we can check that the Awards tab is no longer active.
        let kudosRoot = element("kudos.root", in: app)
        XCTAssertTrue(
            kudosRoot.waitForExistence(timeout: 3),
            "Kudos screen must be visible after CTA tap"
        )

        // Verify the Award Detail is no longer visible (pop or background).
        // Due to the tab switch, AwardDetailView should not be in the active nav stack.
        XCTAssertFalse(
            element("award.detail.root", in: app).exists,
            "AwardDetailView must not be visible after Kudos tab switch"
        )
    }
}
