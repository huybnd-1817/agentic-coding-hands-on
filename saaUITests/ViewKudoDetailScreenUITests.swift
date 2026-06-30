//
//  ViewKudoDetailScreenUITests.swift
//  saaUITests
//
//  Navigation smoke test for `ViewKudoDetailView`:
//    - Launch signed in → switch to Kudos tab.
//    - Tap a feed card's "Xem chi tiết" → detail screen pushes.
//    - Tap back chevron → returns to the Kudos tab root.
//
//  Mirrors KudosTabUITests / AllKudosScreenUITests style: portrait, MainActor,
//  element-type-agnostic identifier lookup, generous waits before assertions
//  (CI cold clones can take ~30s for the NavigationStack push to settle).
//

import XCTest

@MainActor
final class ViewKudoDetailScreenUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Helpers

    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func navTab(label: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    /// Launches signed in, switches to Kudos tab, taps the FIRST visible
    /// "Xem chi tiết" affordance (`kudos.card.viewDetail`), and returns the
    /// running app once `kudos.detail.root` appears.
    ///
    /// The Kudos tab is a tall ScrollView; the feed lives below the highlight
    /// carousel. Scroll the tab until a viewDetail button is hittable, then
    /// tap. Anchors with a generous timeout to match the cold-clone behaviour
    /// already documented in AllKudosScreenUITests.
    private func launchAndOpenDetail() throws -> XCUIApplication {
        let app = XCUIApplication.launching(.signedIn)

        let kudosTab = navTab(label: "Kudos", in: app)
        XCTAssertTrue(kudosTab.waitForExistence(timeout: 5), "Kudos nav tab must exist")
        kudosTab.tap()

        XCTAssertTrue(
            element("kudos.root", in: app).waitForExistence(timeout: 5),
            "kudos.root must mount before searching for a viewDetail button"
        )

        // Anchor by the localized "viewDetail" label rather than the
        // `kudos.card.viewDetail` identifier — the outer card's
        // `kudos.card.<UUID>` identifier propagates to all descendants and
        // shadows the inner button's identifier (same gotcha documented in
        // AllKudosScreenUITests).
        let viewDetail = app.descendants(matching: .button).matching(
            NSPredicate(format: "label IN {'Xem chi tiết', 'View details'}")
        ).firstMatch
        XCTAssertTrue(
            viewDetail.waitForExistence(timeout: 10),
            "At least one 'Xem chi tiết / View details' button must exist on the Kudos tab"
        )

        var attempts = 0
        while !viewDetail.isHittable, attempts < 20 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(
            viewDetail.isHittable,
            "viewDetail button must become hittable after at most 20 swipeUps (last attempt: \(attempts))"
        )
        viewDetail.tap()

        XCTAssertTrue(
            element("kudos.detail.root", in: app).waitForExistence(timeout: 30),
            "Detail screen (kudos.detail.root) must mount after tapping viewDetail"
        )
        return app
    }

    // MARK: - Mount + back

    /// Tap → detail pushes; tapping the detail header back chevron pops back
    /// to the Kudos tab (verified by re-finding `kudos.root`).
    ///
    /// `kudos.detail.root` is on the inner ScrollView (not the outer ZStack),
    /// so it does NOT shadow `kudos.detail.back` on the chevron — identifier
    /// lookup is reliable.
    func testTapViewDetail_pushesDetail_andBackReturnsToKudosTab() throws {
        let app = try launchAndOpenDetail()

        let back = element("kudos.detail.back", in: app)
        XCTAssertTrue(back.waitForExistence(timeout: 5), "Detail back chevron must exist")
        back.tap()

        XCTAssertTrue(
            element("kudos.root", in: app).waitForExistence(timeout: 10),
            "Kudos tab must remount after popping the detail screen"
        )
    }
}
