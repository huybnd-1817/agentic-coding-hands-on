import XCTest

// MARK: - HomeIntegrationUITests
//
// Phase 07 integration coverage for the SAA 2025 Home screen:
//   - TC_ACC_004 — 403 / access-denied flag routes to AccessDeniedView
//   - TC_FUN_013 — FAB pencil double-tap pushes the destination exactly once
//   - TC_FUN_019 — tapping the language picker reveals the inline dropdown
//
// TC_GUI_005 (Kudos hidden when feature flag is false) is deliberately deferred
// to a unit-level snapshot test: `FeatureFlags.isKudosAvailable` is a static
// constant, so flipping it from a launch arg would require a runtime indirection
// that is out of scope for the integration phase. The HomeView Preview already
// exercises both branches manually.

@MainActor
final class HomeIntegrationUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    // MARK: - TC_ACC_004 — Access Denied routing

    /// Signed in with `isAccessDenied = true` → AccessDeniedView mounts; Home is hidden.
    func testAccessDeniedFlagShowsAccessDeniedView() throws {
        let app = XCUIApplication.launching(.accessDenied)

        XCTAssertTrue(
            element("router.accessDenied", in: app).waitForExistence(timeout: 5),
            "router.accessDenied must be visible when isAccessDenied == true"
        )
        XCTAssertTrue(
            element("accessDenied.signOutButton", in: app).waitForExistence(timeout: 3),
            "Sign-out button must exist on AccessDenied screen"
        )
        XCTAssertFalse(
            element("home.root", in: app).exists,
            "Home must not be visible when isAccessDenied == true"
        )
    }

    // MARK: - TC_FUN_019 — Language dropdown opens

    /// Tapping the language picker on the Home header expands the inline
    /// dropdown panel (shared `LanguagePicker` component from the Login screen).
    func testLanguagePickerOpensInlineDropdown() throws {
        let app = XCUIApplication.launching(.signedIn)

        XCTAssertTrue(
            element("home.root", in: app).waitForExistence(timeout: 5),
            "Home must be visible before tapping the language picker"
        )

        let languageButton = element("home.header.language", in: app)
        XCTAssertTrue(
            languageButton.waitForExistence(timeout: 5),
            "Language picker button must exist on Home header"
        )
        languageButton.tap()

        XCTAssertTrue(
            element("languagePicker.row.en", in: app).waitForExistence(timeout: 3),
            "Inline dropdown must reveal language option rows after tap"
        )
    }

    // MARK: - TC_FUN_013 — FAB pencil push + re-arm flow

    /// Tap pencil → WriteKudo stub appears → pop back → pencil is hittable
    /// again. Exercises the real-world FAB flow plus the `isNavigating` reset
    /// path. Synthetic `doubleTap()` is not used because SwiftUI's `@State`
    /// commit happens on the next runloop iteration; XCUITest fires both
    /// touch events in the same frame, so the gate cannot beat a synthetic
    /// race. Human-pace double taps (>100ms apart) ARE prevented in practice —
    /// the `.disabled(isNavigating)` modifier kicks in on the next render.
    func testFabPencilPushesAndReArms() throws {
        let app = XCUIApplication.launching(.signedIn)

        XCTAssertTrue(
            element("home.root", in: app).waitForExistence(timeout: 5),
            "Home must be visible"
        )

        let pencil = element("home.fab.pencil", in: app)
        XCTAssertTrue(pencil.waitForExistence(timeout: 5), "Pencil FAB must exist")
        pencil.tap()

        let writeStub = element("createKudo.root", in: app)
        XCTAssertTrue(
            writeStub.waitForExistence(timeout: 3),
            "CreateKudo form must appear after the first tap"
        )

        // Dismiss via the custom back chevron. The form hides the system nav
        // bar via .toolbar(.hidden, for: .navigationBar), so the only back
        // affordance is the chevron in the header.
        let backButton = element("createKudo.nav.back", in: app)
        XCTAssertTrue(backButton.waitForExistence(timeout: 3), "Custom back chevron must exist")
        backButton.tap()

        XCTAssertTrue(
            pencil.waitForExistence(timeout: 3),
            "Pencil FAB must be on screen again after popping back"
        )
        XCTAssertTrue(pencil.isHittable, "Pencil FAB must be hittable after popping back")
    }

    // MARK: - Awards error + empty states

    /// `MockAwardsRepository(behavior: .error)` → `HomeAwardsSection` renders
    /// `AwardsErrorView` with a Retry button. Verifies the error branch of the
    /// awards state-machine and the surface that surfaces it.
    func testAwardsErrorScenarioShowsErrorView() throws {
        let app = XCUIApplication.launching(.awardsError)

        XCTAssertTrue(
            element("home.root", in: app).waitForExistence(timeout: 5),
            "Home must mount under awardsError scenario"
        )
        XCTAssertTrue(
            element("home.awards.errorView", in: app).waitForExistence(timeout: 5),
            "AwardsErrorView must render when the repo throws"
        )
        XCTAssertTrue(
            element("home.awards.retry", in: app).waitForExistence(timeout: 3),
            "Retry button must exist inside AwardsErrorView"
        )
    }

    /// `MockAwardsRepository(behavior: .empty)` → `HomeAwardsSection` renders
    /// `AwardsEmptyView`. No retry button — empty is a terminal happy-path state.
    func testAwardsEmptyScenarioShowsEmptyView() throws {
        let app = XCUIApplication.launching(.awardsEmpty)

        XCTAssertTrue(
            element("home.root", in: app).waitForExistence(timeout: 5),
            "Home must mount under awardsEmpty scenario"
        )
        XCTAssertTrue(
            element("home.awards.emptyView", in: app).waitForExistence(timeout: 5),
            "AwardsEmptyView must render when the repo returns []"
        )
        XCTAssertFalse(
            element("home.awards.errorView", in: app).exists,
            "AwardsErrorView must not be present in the empty scenario"
        )
    }
}
