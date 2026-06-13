//
//  LoginFlowUITests.swift
//  saaUITests
//
//  E2E tests that launch the app under each -uiTestMode scenario and assert
//  the live UI tree. No Google or Supabase network calls are made — the DEBUG
//  seam in saaApp returns a pre-populated AuthService stub, and the
//  signInWithGoogle short-circuit in AuthService prevents any real SDK call.
//
//  NOTE on element queries:
//  SwiftUI container views may surface accessibilityIdentifier under different
//  element types in XCUITest. We use app.descendants(matching:.any) for all
//  identifier lookups to be element-type-agnostic. Child elements (buttons,
//  banners) that carry custom identifiers also use the same approach because
//  SwiftUI's Button with custom label content may surface as otherElements.
//

import XCTest

@MainActor
final class LoginFlowUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Helpers

    /// Returns the first element anywhere in the tree with the given a11y identifier.
    /// Element-type-agnostic: works for buttons, otherElements, groups, etc.
    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    // MARK: - Signed-out state

    /// TC: launch with signedOut → LoginView is visible, error banner absent.
    func testSignedOutShowsLogin() throws {
        let app = XCUIApplication.launching(.signedOut)

        XCTAssertTrue(
            element("router.login", in: app).waitForExistence(timeout: 5),
            "router.login must be visible in signedOut state"
        )
        XCTAssertTrue(
            element("login.googleButton", in: app).waitForExistence(timeout: 5),
            "Google sign-in button must exist on Login screen"
        )
        XCTAssertFalse(
            element("login.errorBanner", in: app).exists,
            "Error banner must be absent when there is no auth error"
        )
    }

    // MARK: - Signed-in state

    /// TC: launch with signedIn → HomeView is visible, Login is not.
    func testSignedInShowsHome() throws {
        let app = XCUIApplication.launching(.signedIn)

        // home.root is set on HomeView's VStack; router.home is set on HomeView() in AppRouter.
        // Both identifiers are queried via descendants to handle SwiftUI wrapping.
        let homeVisible = element("home.root", in: app).waitForExistence(timeout: 5)
            || element("router.home", in: app).waitForExistence(timeout: 5)
        XCTAssertTrue(homeVisible, "Home screen (home.root or router.home) must be visible in signedIn state")

        XCTAssertTrue(
            element("home.logoutButton", in: app).waitForExistence(timeout: 5),
            "Logout button must exist on Home screen"
        )
        XCTAssertFalse(
            element("router.login", in: app).exists,
            "Login screen must not be visible when signed in"
        )
    }

    // MARK: - Restoring state

    /// TC: launch with restoring → spinner visible; Home and Login absent.
    func testRestoringShowsSpinner() throws {
        let app = XCUIApplication.launching(.restoring)

        XCTAssertTrue(
            element("router.spinner", in: app).waitForExistence(timeout: 5),
            "Spinner must be visible while session is restoring"
        )
        XCTAssertFalse(
            element("home.root", in: app).exists,
            "Home must not be visible while restoring"
        )
        XCTAssertFalse(
            element("router.login", in: app).exists,
            "Login must not be visible while restoring"
        )
    }

    // MARK: - Error states

    /// TC: launch with networkError → LoginView + error banner visible and non-empty.
    func testNetworkErrorShowsBanner() throws {
        let app = XCUIApplication.launching(.networkError)

        XCTAssertTrue(
            element("router.login", in: app).waitForExistence(timeout: 5),
            "router.login must be visible for networkError state"
        )

        let banner = element("login.errorBanner", in: app)
        XCTAssertTrue(
            banner.waitForExistence(timeout: 5),
            "Error banner must be visible for networkError state"
        )
        // Assert presence + non-empty label (locale-agnostic: avoids hard-coding a string).
        XCTAssertFalse(
            banner.label.isEmpty,
            "Error banner must display a non-empty localized message"
        )
    }

    /// TC: launch with notAuthorized → LoginView + error banner visible and non-empty.
    func testNotAuthorizedShowsBanner() throws {
        let app = XCUIApplication.launching(.notAuthorized)

        XCTAssertTrue(
            element("router.login", in: app).waitForExistence(timeout: 5),
            "router.login must be visible for notAuthorized state"
        )

        let banner = element("login.errorBanner", in: app)
        XCTAssertTrue(
            banner.waitForExistence(timeout: 5),
            "Error banner must be visible for notAuthorized state"
        )
        XCTAssertFalse(
            banner.label.isEmpty,
            "Error banner must display a non-empty localized message"
        )
    }

    // MARK: - Loading state

    /// TC: launch with loading → Google button is disabled (sign-in in flight).
    func testLoadingDisablesGoogleButton() throws {
        let app = XCUIApplication.launching(.loading)

        XCTAssertTrue(
            element("router.login", in: app).waitForExistence(timeout: 5),
            "router.login must be visible in loading state"
        )

        let button = element("login.googleButton", in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Google button must exist")
        XCTAssertFalse(
            button.isEnabled,
            "Google button must be disabled while a sign-in is in flight"
        )
    }

    // MARK: - Tap sanity

    /// TC: tap Google button in signedOut → app does not crash, stays on Login.
    ///
    /// The DEBUG short-circuit in `AuthService.signInWithGoogle` ensures no real
    /// GIDSignIn call is made when `-uiTestMode` is present. This test validates
    /// that the short-circuit is effective: after a tap the app still shows the
    /// Login screen with no crash.
    func testGoogleButtonTapDoesNotCrash() throws {
        let app = XCUIApplication.launching(.signedOut)

        XCTAssertTrue(
            element("router.login", in: app).waitForExistence(timeout: 5),
            "Must start on Login screen"
        )

        let button = element("login.googleButton", in: app)
        XCTAssertTrue(button.waitForExistence(timeout: 5), "Google button must exist before tap")
        button.tap()

        // Allow up to 1s for any (unexpected) transition to complete.
        _ = element("router.home", in: app).waitForExistence(timeout: 1)

        XCTAssertTrue(
            element("router.login", in: app).exists,
            "App must remain on Login screen after tapping Google button in UI-test mode"
        )
        XCTAssertFalse(
            element("router.home", in: app).exists,
            "Home screen must not appear after tapping Google button in UI-test mode"
        )
    }

}
