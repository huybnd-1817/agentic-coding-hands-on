#if DEBUG
import Foundation

// MARK: - UserSession preview fixture

extension UserSession {
    /// Minimal `UserSession` for SwiftUI Previews and UI-test injection.
    static let preview = UserSession(
        userID: "00000000-0000-0000-0000-000000000001",
        email: "preview@sun-asterisk.com",
        displayName: nil,
        avatarURL: nil,
        provider: "google",
        accessTokenExpiresAt: Date(timeIntervalSinceNow: 3600)
    )
}
#endif
