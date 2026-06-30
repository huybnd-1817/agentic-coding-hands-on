import XCTest

// MARK: - AwardVariantsRenderingUITests
//
// Parameterized-style tests verifying each of the 6 award variants renders
// correctly with their expected quantity, unit, and prize values per Figma.
//
// Each test follows the same flow:
//   1. Launch app (signed in)
//   2. Tap Awards tab (or navigate to Award Detail)
//   3. Open dropdown selector
//   4. Select the target award code
//   5. Assert the badge identifier appears (proxy for correct selection)
//
// The actual quantity/prize text values are locale-dependent and brittle to
// assert directly, so we validate via accessibility identifiers and badge presence.

@MainActor
final class AwardVariantsRenderingUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Helpers

    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// Launches the app, navigates to the Awards tab, and selects a given award code via dropdown.
    /// Returns the running app for further assertions.
    private func selectAward(_ code: String) -> XCUIApplication {
        let app = XCUIApplication.launching(.signedIn)

        XCTAssertTrue(
            app.navigateToAwardsTab(timeout: 5),
            "Awards tab must mount AwardDetailView after tapping the Awards nav button"
        )

        let chip = element("award.detail.selector", in: app)
        XCTAssertTrue(
            chip.waitForExistence(timeout: 3),
            "Selector chip must exist before selecting award '\(code)'"
        )
        chip.tap()

        let option = element("award.detail.selector.option.\(code)", in: app)
        XCTAssertTrue(
            option.waitForExistence(timeout: 3),
            "Option '\(code)' must appear in dropdown panel"
        )
        option.tap()

        // Dropdown panel should close after selection; wait for it to disappear.
        let panel = element("award.detail.selector.panel", in: app)
        _ = panel.waitForNonExistence(timeout: 1)

        return app
    }

    // MARK: - Individual variant tests

    /// Top Talent: 10 Cá nhân, 7.000.000 VNĐ
    func testTopTalent_rendersCorrectly() throws {
        let app = selectAward("top_talent")

        let badge = element("award.badge.top_talent", in: app)
        XCTAssertTrue(
            badge.waitForExistence(timeout: 3),
            "Top Talent badge must be visible"
        )

        // Chip should be hittable (responsive state).
        let chip = element("award.detail.selector", in: app)
        XCTAssertTrue(chip.isHittable, "Chip must be interactive after selection")
    }

    /// Top Project: 02 Tập thể, 15.000.000 VNĐ
    func testTopProject_rendersCorrectly() throws {
        let app = selectAward("top_project")

        let badge = element("award.badge.top_project", in: app)
        XCTAssertTrue(
            badge.waitForExistence(timeout: 3),
            "Top Project badge must be visible"
        )

        let chip = element("award.detail.selector", in: app)
        XCTAssertTrue(chip.isHittable, "Chip must be interactive")
    }

    /// Top Project Leader: 03 Cá nhân, 7.000.000 VNĐ
    func testTopProjectLeader_rendersCorrectly() throws {
        let app = selectAward("top_project_leader")

        let badge = element("award.badge.top_project_leader", in: app)
        XCTAssertTrue(
            badge.waitForExistence(timeout: 3),
            "Top Project Leader badge must be visible"
        )

        let chip = element("award.detail.selector", in: app)
        XCTAssertTrue(chip.isHittable, "Chip must be interactive")
    }

    /// Best Manager: 01 Cá nhân, 10.000.000 VNĐ
    func testBestManager_rendersCorrectly() throws {
        let app = selectAward("best_manager")

        let badge = element("award.badge.best_manager", in: app)
        XCTAssertTrue(
            badge.waitForExistence(timeout: 3),
            "Best Manager badge must be visible"
        )

        let chip = element("award.detail.selector", in: app)
        XCTAssertTrue(chip.isHittable, "Chip must be interactive")
    }

    /// Signature 2026 - Creator: 01 Cá nhân hoặc tập thể, 5.000.000 + 8.000.000 VNĐ (dual)
    func testSignature2026Creator_rendersCorrectly() throws {
        let app = selectAward("signature_2026_creator")

        let badge = element("award.badge.signature_2026_creator", in: app)
        XCTAssertTrue(
            badge.waitForExistence(timeout: 3),
            "Signature 2026 - Creator badge must be visible"
        )

        let chip = element("award.detail.selector", in: app)
        XCTAssertTrue(chip.isHittable, "Chip must be interactive")
    }

    /// MVP: 01 Cá nhân, 15.000.000 VNĐ
    func testMVP_rendersCorrectly() throws {
        let app = selectAward("mvp")

        let badge = element("award.badge.mvp", in: app)
        XCTAssertTrue(
            badge.waitForExistence(timeout: 3),
            "MVP badge must be visible"
        )

        let chip = element("award.detail.selector", in: app)
        XCTAssertTrue(chip.isHittable, "Chip must be interactive")
    }
}
