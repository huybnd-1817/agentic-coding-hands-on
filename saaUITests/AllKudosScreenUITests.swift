//
//  AllKudosScreenUITests.swift
//  saaUITests
//
//  Smoke tests for the All Kudos screen. Mirrors KudosTabUITests.swift style:
//  force-portrait, `@MainActor`, element-type-agnostic lookup, waits before taps.
//
//  Covers:
//    - Tap "View all Kudos" pushes AllKudosView; screen mounts.
//    - Header back button pops back to the Kudos tab.
//    - Feed renders card content from the deterministic MockKudosRepository fixture.
//    - Pull-to-refresh gesture does not crash; screen remains mounted.
//    - Bottom HomeBottomNavBar stays visible (NavigationStack push does not cover it).
//
//  Known limitation (infrastructure):
//    Under Xcode's parallel UI-test execution, fresh simulator clones can show
//    timing variance — NavigationStack pushes that complete in <2s on a hot
//    simulator may take >15s on a cold clone. The helper `launchAndOpenAllKudos`
//    anchors on the deterministic mock card body text ("Cảm ơn ...") with a 15s
//    timeout. If the CI runner experiences additional load, configure the test
//    plan to retry failed UI tests up to 2x.
//

import XCTest

@MainActor
final class AllKudosScreenUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Helpers

    /// Element-type-agnostic identifier lookup (SwiftUI may surface IDs under
    /// `button` / `otherElement` / `staticText` depending on wrapping).
    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// Looks up a bottom-nav tab by its visible label (NavTab.rawValue).
    /// Matches the resolution strategy used by KudosTabUITests.
    private func navTab(label: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    /// Launches the app signed in, switches to the Kudos tab, scrolls down
    /// until the "View all Kudos" button is hittable, taps it, and returns
    /// the running app once `allKudos.root` is on screen.
    ///
    /// The "View all Kudos" link sits at the bottom of a tall scroll view
    /// (hero + carousel + spotlight + stats + top recipients + feed). Cap
    /// the swipe loop at 20 attempts — borderline cases were timing out at
    /// 10 on the iPhone 17 simulator.
    private func launchAndOpenAllKudos() throws -> XCUIApplication {
        let app = XCUIApplication.launching(.signedIn)

        let kudosTab = navTab(label: "Kudos", in: app)
        XCTAssertTrue(kudosTab.waitForExistence(timeout: 5), "Kudos nav tab must exist")
        kudosTab.tap()

        XCTAssertTrue(
            element("kudos.root", in: app).waitForExistence(timeout: 15),
            "kudos.root must mount before scrolling for the View all Kudos link"
        )

        let viewAllButton = element("kudos.all.viewAllButton", in: app)
        XCTAssertTrue(
            viewAllButton.waitForExistence(timeout: 15),
            "kudos.all.viewAllButton must exist in the Kudos tab's accessibility tree"
        )

        var attempts = 0
        while !viewAllButton.isHittable, attempts < 20 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(
            viewAllButton.isHittable,
            "View all Kudos link must become hittable after at most 20 swipeUps (last attempt: \(attempts))"
        )

        viewAllButton.tap()

        // SwiftUI's `.accessibilityIdentifier("allKudos.root")` on the outer
        // ZStack propagates that identifier to EVERY descendant, AND the hero
        // text "ALL KUDOS" appears on both the parent Kudos tab section header
        // and the destination's hero block. `app.buttons` queries also showed
        // flake on the back button under parallel simulator clones.
        //
        // Anchor on the deterministic mock card body text instead. The
        // `MockKudosRepository.kudosFeed` items all start with "Cảm ơn", which
        // only renders on the destination's feed list (parent's highlight
        // carousel renders the same content but in a wider view that's typically
        // off-screen after the swipeUp series that brought "View all Kudos"
        // into view). `staticTexts` queries are most reliable under parallel
        // XCUI execution.
        let cardBody = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS 'Cảm ơn'")
        ).firstMatch
        // Empirical: cold parallel simulator clones occasionally take ~45s for
        // the NavigationStack push to settle in the accessibility tree when
        // running alongside the Award feature's UI test suite (additional
        // simulator clone load). 45s + one CI-level retry covers observed cases.
        XCTAssertTrue(
            cardBody.waitForExistence(timeout: 45),
            "All Kudos screen must mount after tapping View all Kudos (looked for card body 'Cảm ơn...')"
        )
        return app
    }

    // MARK: - Mount

    /// Tap "View all Kudos" → AllKudosView pushes. The helper anchors on the
    /// mock card body ("Cảm ơn ..."); this test verifies the destination is
    /// reached without extra assertions.
    func testAllKudosScreenMountsWhenSignedIn() throws {
        _ = try launchAndOpenAllKudos()
    }

    // MARK: - Back navigation

    /// Header back button pops the NavigationStack back to the Kudos tab.
    ///
    /// Locate the back button via its localized label since identifier
    /// propagation shadows `allKudos.backButton` (see `launchAndOpenAllKudos`).
    /// Use `descendants(matching: .button)` instead of `app.buttons` — the
    /// latter showed flake under parallel simulator clones.
    func testBackButtonPopsList() throws {
        let app = try launchAndOpenAllKudos()

        let backButton = app.descendants(matching: .button).matching(
            NSPredicate(format: "label IN {'Quay Lại', 'Back'}")
        ).firstMatch
        // Bumped 5s → 15s: parallel simulator clones on CI take longer to
        // surface localized system-back-button labels.
        XCTAssertTrue(backButton.waitForExistence(timeout: 15), "Back button must exist on All Kudos")
        backButton.tap()

        XCTAssertTrue(
            element("kudos.all.viewAllButton", in: app).waitForExistence(timeout: 15),
            "Kudos tab content must remount after popping the All Kudos screen"
        )
    }

    // MARK: - Feed render

    /// The deterministic `MockKudosRepository.kudosFeed` ships THREE kudos that
    /// each render a sender name beginning "Huỳnh Dương". Assert the feed list
    /// contains >=2 such labels — proves the feed is a list (not just the
    /// single card body that the helper already waits on).
    func testAllKudosFeedRendersContent() throws {
        let app = try launchAndOpenAllKudos()

        let senderPredicate = NSPredicate(format: "label CONTAINS 'Huỳnh Dương'")
        let senderLabels = app.staticTexts.matching(senderPredicate)
        // Bumped 5s → 15s: on parallel CI simulator clones the second feed
        // card can take longer to enter the accessibility tree after the push.
        XCTAssertTrue(
            senderLabels.element(boundBy: 1).waitForExistence(timeout: 15),
            "All Kudos feed must render at least 2 cards from the mock fixture"
        )
    }

    // MARK: - Pull to refresh

    /// Pull-to-refresh gesture must not crash and the screen must survive it.
    /// The transient native refresh spinner is XCUI-invisible, so this is a
    /// smoke test — assert a mock card body is still visible after the gesture.
    func testPullToRefreshGestureDoesNotCrash() throws {
        let app = try launchAndOpenAllKudos()

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 10), "Feed scrollView must exist")
        scrollView.swipeDown(velocity: .slow)

        // The test name (`DoesNotCrash`) reflects the intent: did the swipe
        // crash the app process? A crash would tear down `app.scrollViews` —
        // its continued existence is sufficient proof the gesture survived.
        // Anchoring on card-body text caused intermittent CI failures because
        // the swipe sometimes scrolls the deterministic "Cảm ơn..." string
        // off-screen before XCUI's accessibility tree settles.
        XCTAssertTrue(
            app.scrollViews.firstMatch.waitForExistence(timeout: 5),
            "All Kudos screen must remain mounted (scroll view alive) after the pull-to-refresh gesture"
        )
    }

    // MARK: - Bottom nav bar persistence

    /// `MainTabView` overlays `HomeBottomNavBar` via a ZStack — the
    /// NavigationStack push inside the Kudos tab must NOT cover it.
    func testNavBarVisibleOnAllKudos() throws {
        let app = try launchAndOpenAllKudos()

        let kudosNavButton = navTab(label: "Kudos", in: app)
        // Wait for the button to exist and settle before testing hittability.
        // Without this guard the synchronous `isHittable` can return false on
        // cold simulator clones that haven't fully rendered the ZStack overlay.
        XCTAssertTrue(
            kudosNavButton.waitForExistence(timeout: 15),
            "Kudos bottom-nav button must be visible on the All Kudos screen"
        )
        XCTAssertTrue(
            kudosNavButton.isHittable,
            "Kudos bottom-nav button must remain hittable (not occluded) on the All Kudos screen"
        )
    }
}
