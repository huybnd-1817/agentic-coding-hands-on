//
//  UITestHelpers.swift
//  saaUITests
//

import XCTest

// MARK: - UITestScenario

/// Matches the scenario strings accepted by `saaApp.makeAuthService()` via
/// the `-uiTestMode <scenario>` launch argument.
enum UITestScenario: String {
    case signedIn
    case signedOut
    case restoring
    case loading
    case networkError
    case notAuthorized
    /// Signed-in + `isAccessDenied = true` — AppRouter mounts AccessDeniedView (TC_ACC_004).
    case accessDenied
    /// Signed-in + awards repo throws — `HomeAwardsSection` shows `AwardsErrorView`.
    case awardsError
    /// Signed-in + awards repo returns `[]` — `HomeAwardsSection` shows `AwardsEmptyView`.
    case awardsEmpty
    /// Signed-in + Create Kudo form injected with MockKudosRepository + MockKudosImageUploader.
    /// WriteKudoFormStubView detects this mode and bypasses Supabase.
    case kudosCreate = "kudos.create"
}

// MARK: - XCUIApplication factory

extension XCUIApplication {

    /// Creates, configures, and launches a fresh `XCUIApplication` instance with
    /// the given UI-test scenario injected as a launch argument.
    ///
    /// The `-uiTestMode` flag is read by `saaApp.makeAuthService()` in DEBUG builds
    /// to return a pre-populated stub instead of the live `AuthService`.
    ///
    /// - Parameter scenario: The auth-state scenario to inject at launch.
    /// - Returns: The running application, ready for element queries.
    @discardableResult
    static func launching(_ scenario: UITestScenario) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTestMode", scenario.rawValue]
        app.launch()
        return app
    }

    /// Taps the Awards tab in the bottom navigation bar and waits for
    /// `AwardDetailView` to mount. Returns `true` if the navigation succeeded.
    ///
    /// The app launches on the Home tab by default; call this helper at the start
    /// of any test that needs to exercise the Awards tab root.
    @discardableResult
    func navigateToAwardsTab(timeout: TimeInterval = 5) -> Bool {
        let awardsTabButton = descendants(matching: .any)
            .matching(identifier: "home.nav.awards")
            .firstMatch
        guard awardsTabButton.waitForExistence(timeout: timeout) else { return false }
        awardsTabButton.tap()
        return descendants(matching: .any)
            .matching(identifier: "award.detail.root")
            .firstMatch
            .waitForExistence(timeout: timeout)
    }
}
