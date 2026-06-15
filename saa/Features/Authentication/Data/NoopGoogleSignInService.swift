#if DEBUG
import Foundation
import UIKit

// MARK: - NoopGoogleSignInService

/// No-op `GoogleSignInServiceProtocol` for UI-test scenarios and SwiftUI Previews.
/// Never presents a real Google sheet — throws immediately so callers that exercise
/// the sign-in path get a deterministic failure instead of a live UI.
struct NoopGoogleSignInService: GoogleSignInServiceProtocol {
    @MainActor
    func obtainIDToken(presenting vc: UIViewController, hashedNonce: String) async throws -> String {
        throw AuthError.unknown(underlying: NSError(domain: "NoopGoogleSignInService", code: -1))
    }

    @MainActor
    func clearLocalGoogleSession() {}
}
#endif
