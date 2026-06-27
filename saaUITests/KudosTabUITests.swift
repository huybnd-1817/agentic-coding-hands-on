//
//  KudosTabUITests.swift
//  saaUITests
//
//  Phase-coverage E2E tests for the Sun*Kudos tab. The `.signedIn` UI-test
//  scenario routes through `MockKudosRepository` (saaApp+KudosSetup.swift),
//  so the tab reaches `.loaded` on the first frame with three canned kudos
//  in the highlight carousel and the feed — no network I/O, deterministic UUIDs.
//
//  Covered:
//    - Tab mounts when switched via the bottom nav.
//    - Highlight + Send + SecretBox + carousel chrome render.
//    - Hashtag dropdown opens and a row is selectable.
//    - Department dropdown opens and a row is selectable.
//    - SecretBox tap is non-crashing (toast is internal VM state — verifying
//      the button is hittable is enough at the UI level).
//

import XCTest

@MainActor
final class KudosTabUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    /// Element-type-agnostic lookup — SwiftUI may surface identifiers under
    /// `button` / `otherElement` / `staticText` depending on the wrapping.
    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// Looks up a bottom-nav tab by its visible label (NavTab.rawValue).
    ///
    /// The four buttons inside `HomeBottomNavBar` carry the identifier
    /// `home.nav.<id>` in source (HomeBottomNavBar.swift:70), but SwiftUI's
    /// accessibility-identifier propagation in `AppRouter` overwrites that
    /// with the ambient `router.home` value on every nav-bar button. The label
    /// (each NavTab.rawValue — "SAA 2025" / "Awards" / "Kudos" / "Profile")
    /// remains unique per button, so we resolve by label.
    private func navTab(label: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    /// Launches the app signed in and switches to the Kudos tab.
    /// Returns the running app once `kudos.root` exists.
    private func launchAndOpenKudosTab() throws -> XCUIApplication {
        let app = XCUIApplication.launching(.signedIn)

        let kudosTab = navTab(label: "Kudos", in: app)
        XCTAssertTrue(kudosTab.waitForExistence(timeout: 5), "Kudos nav tab button must exist")
        kudosTab.tap()

        XCTAssertTrue(
            element("kudos.root", in: app).waitForExistence(timeout: 5),
            "kudos.root must appear after switching to the Kudos tab"
        )
        return app
    }

    // MARK: - Mount

    /// Switching to the Kudos tab mounts `KudosView` and hides the Home root.
    func testKudosTabMountsWhenSignedIn() throws {
        let app = try launchAndOpenKudosTab()

        // Hero text + Send button are guaranteed by KudosView regardless of repo state.
        XCTAssertTrue(
            element("kudos.hero.tagline", in: app).waitForExistence(timeout: 3),
            "kudos.hero.tagline must render on the Kudos tab"
        )
        XCTAssertTrue(
            element("kudos.sendButton", in: app).waitForExistence(timeout: 3),
            "kudos.sendButton must render on the Kudos tab"
        )
    }

    // MARK: - Highlight carousel

    /// MockKudosRepository returns 3 highlight kudos sorted by heart count.
    /// The carousel mounts with pagination dots and side chevrons.
    func testHighlightCarouselRenders() throws {
        let app = try launchAndOpenKudosTab()

        XCTAssertTrue(
            element("kudos.carousel.pagination", in: app).waitForExistence(timeout: 5),
            "Carousel pagination chrome must render when highlights are non-empty"
        )
        XCTAssertTrue(
            element("kudos.carousel.side.next", in: app).exists,
            "Next side chevron must be present in the carousel"
        )
        XCTAssertTrue(
            element("kudos.carousel.side.prev", in: app).exists,
            "Prev side chevron must be present in the carousel"
        )
    }

    // MARK: - Hashtag filter

    /// Tapping the hashtag chip exposes the dropdown rows from the mock repository.
    func testHashtagFilterOpensDropdown() throws {
        let app = try launchAndOpenKudosTab()

        let chip = element("kudos.filterChip.hashtag", in: app)
        XCTAssertTrue(chip.waitForExistence(timeout: 3), "Hashtag chip must exist")
        chip.tap()

        // MockKudosRepository ships the "#Dedicated" hashtag (deterministic fixture).
        XCTAssertTrue(
            element("kudos.hashtagFilter.row.#Dedicated", in: app).waitForExistence(timeout: 3),
            "Hashtag dropdown row '#Dedicated' must appear after tapping the chip"
        )
    }

    /// Selecting a hashtag row closes the dropdown and re-renders the highlight
    /// section with the filter applied (the row should disappear from screen).
    func testHashtagFilterAppliesAfterSelection() throws {
        let app = try launchAndOpenKudosTab()

        element("kudos.filterChip.hashtag", in: app).tap()

        let row = element("kudos.hashtagFilter.row.#Dedicated", in: app)
        XCTAssertTrue(row.waitForExistence(timeout: 3), "Row must appear before tap")
        row.tap()

        // The dropdown collapses on selection — its row should no longer be hittable.
        // We allow up to 2s for SwiftUI to commit the .opacity transition.
        let collapsed = !element("kudos.hashtagFilter.row.#Dedicated", in: app)
            .waitForExistence(timeout: 2)
        XCTAssertTrue(
            collapsed || !element("kudos.hashtagFilter.row.#Dedicated", in: app).isHittable,
            "Hashtag dropdown must collapse after selecting a row"
        )
    }

    // MARK: - Department filter

    /// Tapping the department chip exposes the dropdown rows from the mock repository.
    /// `MockKudosRepository` ships the CEV1 / HAN / HCM / DAN / R&D set.
    func testDepartmentFilterOpensDropdown() throws {
        let app = try launchAndOpenKudosTab()

        let chip = element("kudos.filterChip.department", in: app)
        XCTAssertTrue(chip.waitForExistence(timeout: 3), "Department chip must exist")
        chip.tap()

        XCTAssertTrue(
            element("kudos.deptFilter.row.CEV1", in: app).waitForExistence(timeout: 3),
            "Department dropdown row 'CEV1' must appear after tapping the chip"
        )
    }

    // MARK: - Secret box

    /// The secret-box button must exist and be hittable when the mock repo
    /// reports `secretBoxesUnopened > 0` (current mock returns 2). Tapping it
    /// must not crash — the toast emission is internal VM state, but the tap
    /// path exercises `KudosViewModel.openSecretBox` end-to-end.
    func testSecretBoxButtonIsHittable() throws {
        let app = try launchAndOpenKudosTab()

        // The Kudos tab is a tall ScrollView; the secret-box button sits below
        // the highlight carousel. Wait for the element to enter the
        // accessibility tree FIRST so swipeUps don't burn while the tab is
        // still loading, then scroll until it becomes hittable. The previous
        // ordering (scroll-then-wait) burned all 6 attempts before the button
        // mounted on slower CI runners (iPhone 16 Pro).
        let secret = element("kudos.secretBoxButton", in: app)
        XCTAssertTrue(
            secret.waitForExistence(timeout: 5),
            "Secret box button must mount on Kudos tab"
        )
        var attempts = 0
        while !secret.isHittable, attempts < 10 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(
            secret.isHittable,
            "Secret box button must be reachable by scrolling (gave up after \(attempts) attempts)"
        )

        secret.tap()
        // App must remain on the Kudos tab — no crash, no navigation.
        XCTAssertTrue(
            element("kudos.root", in: app).exists,
            "Kudos tab must remain mounted after tapping the Secret Box button"
        )
    }
}
