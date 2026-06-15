import Foundation
import UIKit
@testable import saa

// MARK: - GoogleSignInServiceFake
//
// Configurable fake implementing `GoogleSignInServiceProtocol`. Returns a
// deterministic ID token or a canned error without opening a Google sheet.
//
// @unchecked Sendable: test doubles mutate properties from the test thread
// without synchronisation — intentional for ergonomics; never used in production.

final class GoogleSignInServiceFake: GoogleSignInServiceProtocol, @unchecked Sendable {

    enum Behavior {
        case success(String)   // ID token to return
        case error(Error)
    }

    // MARK: - Behavior configuration

    var obtainBehavior: Behavior = .success("fake.id.token")

    // MARK: - Call tracking

    private(set) var obtainCalls       = 0
    private(set) var lastPresentedVC:  UIViewController?
    private(set) var lastHashedNonce:  String?
    private(set) var clearCalls        = 0

    // MARK: - GoogleSignInServiceProtocol

    @MainActor
    func obtainIDToken(presenting vc: UIViewController, hashedNonce: String) async throws -> String {
        obtainCalls    += 1
        lastPresentedVC = vc
        lastHashedNonce = hashedNonce
        switch obtainBehavior {
        case .success(let t): return t
        case .error(let e):   throw e
        }
    }

    @MainActor
    func clearLocalGoogleSession() {
        clearCalls += 1
    }
}
