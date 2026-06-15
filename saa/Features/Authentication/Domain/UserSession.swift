import Foundation

// MARK: - UserSession

/// Domain entity representing an authenticated user's session.
///
/// Replaces direct references to `Supabase.Session` in the Presentation layer,
/// keeping the Domain boundary free of SDK types.
struct UserSession: Equatable {

    /// Opaque user identifier (Supabase UUID string).
    let userID: String

    /// User's email address, if available from the identity provider.
    let email: String?

    /// Display name returned by the identity provider (e.g. Google full name).
    let displayName: String?

    /// Avatar/profile image URL returned by the identity provider.
    let avatarURL: URL?

    /// Identity provider used to create the session. `"google"` today.
    let provider: String

    /// Expiry date of the access token. `nil` if the provider does not supply one.
    let accessTokenExpiresAt: Date?
}
