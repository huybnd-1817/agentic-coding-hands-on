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
}
