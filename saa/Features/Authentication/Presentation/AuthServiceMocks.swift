#if DEBUG
import Foundation
import Supabase

// MARK: - MockAuthService

/// Canned `AuthService` states for SwiftUI Previews and unit test harnesses.
///
/// Usage in a Preview:
/// ```swift
/// #Preview {
///     HomeView()
///         .environmentObject(AuthService.previewSignedIn())
/// }
/// ```
///
/// Because `AuthService` is a concrete `ObservableObject` (not a protocol),
/// mocks are produced via a factory that returns a fully-initialised instance
/// with its state pre-set before the caller observes it.
extension AuthService {

    // MARK: Factories

    /// Returns an `AuthService` that appears to have a valid session.
    /// `isRestoringSession` is already `false` (restore complete).
    static func previewSignedIn() -> AuthService {
        let service = AuthService(client: .preview)
        service.injectState(session: .preview, isRestoringSession: false)
        return service
    }

    /// Returns an `AuthService` sitting on the Login screen with no session.
    static func previewSignedOut() -> AuthService {
        let service = AuthService(client: .preview)
        service.injectState(session: nil, isRestoringSession: false)
        return service
    }

    /// Returns an `AuthService` with a network error already set.
    static func previewNetworkError() -> AuthService {
        let service = AuthService(client: .preview)
        service.injectState(session: nil, isRestoringSession: false, error: .networkUnavailable)
        return service
    }

    /// Returns an `AuthService` with a not-authorized error set.
    static func previewNotAuthorized() -> AuthService {
        let service = AuthService(client: .preview)
        service.injectState(session: nil, isRestoringSession: false, error: .notAuthorized)
        return service
    }

    /// Returns an `AuthService` mid-restore (splash gate still showing).
    static func previewRestoring() -> AuthService {
        let service = AuthService(client: .preview)
        service.injectState(session: nil, isRestoringSession: true)
        return service
    }

    /// Returns an `AuthService` with `isLoading = true` (sign-in in flight).
    static func previewLoading() -> AuthService {
        let service = AuthService(client: .preview)
        service.injectState(session: nil, isLoading: true, isRestoringSession: false)
        return service
    }

    // `injectState` is defined in AuthService.swift (same-file extension is
    // required to write the `private(set)` properties).
}

// MARK: - SupabaseClient preview stub

private extension SupabaseClient {
    /// A no-op `SupabaseClient` pointing at a localhost URL.
    /// Never makes real network calls in Previews — the mock state is injected
    /// directly via `injectState`, so auth methods are never invoked.
    // API CONFIRM: `SupabaseClient(supabaseURL:supabaseKey:)` is the v2.x init.
    // Verify the exact initialiser signature against the resolved package version.
    static let preview = SupabaseClient(
        supabaseURL: URL(string: "http://127.0.0.1:54321")!,
        supabaseKey: "preview-anon-key"
    )
}

// MARK: - Session preview stub

private extension Session {
    /// Minimal `Session` value for use in Previews only.
    ///
    // API CONFIRM: `Session` in supabase-swift v2.x may require memberwise init
    // or a dedicated test-helper constructor. If `Session` has no public init,
    // use `try! JSONDecoder().decode(Session.self, from: previewSessionJSON)` as
    // a fallback (include a minimal JSON fixture below).
    static let preview: Session = {
        // Session.Codable uses synthesised coding keys matching Swift property names
        // (camelCase). The Supabase Auth SDK's live decoder applies convertFromSnakeCase
        // over the network, but when constructing a value directly in code we must use
        // camelCase keys and the same custom date strategy the SDK uses internally.
        // Dates use ISO-8601 without fractional seconds (supabase() DateFormatter).
        let json = """
        {
          "accessToken": "preview.access.token",
          "tokenType": "bearer",
          "expiresIn": 3600,
          "expiresAt": 9999999999,
          "refreshToken": "preview-refresh-token",
          "isAnonymous": false,
          "user": {
            "id": "00000000-0000-0000-0000-000000000001",
            "aud": "authenticated",
            "role": "authenticated",
            "email": "preview@sun-asterisk.com",
            "createdAt": "2026-01-01T00:00:00",
            "updatedAt": "2026-01-01T00:00:00",
            "appMetadata": {},
            "userMetadata": {},
            "isAnonymous": false
          }
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        // Supabase uses a custom date strategy matching "yyyy-MM-dd'T'HH:mm:ss" or
        // "yyyy-MM-dd'T'HH:mm:ss.SSS". Mirror that with the iso8601 format.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(formatter)
        // swiftlint:disable:next force_try
        return try! decoder.decode(Session.self, from: json)
    }()
}
#endif
