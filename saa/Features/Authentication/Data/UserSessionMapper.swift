import Foundation
import Supabase

// MARK: - UserSessionMapper

/// Maps a `Supabase.Session` (SDK type) to the Domain `UserSession` entity.
///
/// All SDK-to-Domain type translation for authentication is centralised here,
/// keeping both `SupabaseAuthRepository` and the Domain layer free of conversion
/// logic. No Supabase types cross the Data boundary.
enum UserSessionMapper {

    // MARK: - Mapping

    /// Converts a `Supabase.Session` into the Domain-layer `UserSession`.
    ///
    /// - `userMetadata["full_name"]` — display name set by the Google OIDC connector.
    /// - `userMetadata["avatar_url"]` — profile picture URL from the identity provider.
    /// - `appMetadata["provider"]` — identity provider key (e.g. `"google"`).
    /// - `expiresAt` — non-optional `TimeInterval` in supabase-swift v2.x; wrapped
    ///   in `Date(timeIntervalSince1970:)` and stored as the optional `Date?` on
    ///   `UserSession` for forward-compatibility.
    static func toDomain(_ session: Supabase.Session) -> UserSession {
        let userMetadata = session.user.userMetadata
        let appMetadata = session.user.appMetadata

        return UserSession(
            userID: session.user.id.uuidString,
            email: session.user.email,
            displayName: userMetadata["full_name"]?.stringValue,
            avatarURL: userMetadata["avatar_url"]?.stringValue.flatMap(URL.init(string:)),
            provider: appMetadata["provider"]?.stringValue ?? "google",
            accessTokenExpiresAt: Date(timeIntervalSince1970: session.expiresAt)
        )
    }
}
