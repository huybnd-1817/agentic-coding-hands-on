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
///         .environment(MockAuthService.signedIn())
/// }
/// ```
///
/// Because `AuthService` is a concrete `@Observable` class (not a protocol),
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

    /// Returns an `AuthService` with a domain-rejection error set.
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

    // MARK: Internal state injection

    /// Directly sets observable properties for preview/test purposes.
    /// Internal visibility keeps this out of the production API surface.
    func injectState(
        session: Session? = nil,
        isLoading: Bool = false,
        isRestoringSession: Bool = false,
        error: AuthError? = nil
    ) {
        self.session = session
        self.isLoading = isLoading
        self.isRestoringSession = isRestoringSession
        self.error = error
    }
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
        let json = """
        {
          "access_token": "preview.access.token",
          "token_type": "bearer",
          "expires_in": 3600,
          "expires_at": 9999999999,
          "refresh_token": "preview-refresh-token",
          "user": {
            "id": "00000000-0000-0000-0000-000000000001",
            "aud": "authenticated",
            "role": "authenticated",
            "email": "preview@sun-asterisk.com",
            "created_at": "2026-01-01T00:00:00Z",
            "updated_at": "2026-01-01T00:00:00Z",
            "app_metadata": {},
            "user_metadata": {}
          }
        }
        """.data(using: .utf8)!
        // swiftlint:disable:next force_try
        return try! JSONDecoder().decode(Session.self, from: json)
    }()
}
#endif
