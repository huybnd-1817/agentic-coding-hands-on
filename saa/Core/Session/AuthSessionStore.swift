import Foundation
import Combine

// MARK: - AuthSessionStore

/// Observable session store that owns `UserSession` and restore-state as the
/// single source of truth for auth state across the Presentation layer.
///
/// Replaces the monolithic `AuthService` for state ownership. Use-case objects
/// mutate this store after successful or failed auth operations. The router and
/// all screens observe published properties through `@EnvironmentObject`.
@MainActor
final class AuthSessionStore: ObservableObject {

    // MARK: - Published state

    /// Non-nil when a valid session exists (user is signed in).
    @Published private(set) var state: UserSession?

    /// `true` from app launch until the initial Keychain restore completes.
    /// Drives the spinner gate in `AppRouter` (TC_LOGIN_ACC_002 / TC_LOGIN_FUN_012).
    @Published private(set) var isRestoring: Bool = true

    // MARK: - Mutations (called only by use cases and composition root)

    func setRestoring(_ value: Bool) { isRestoring = value }
    func setState(_ value: UserSession?) { state = value }

    /// Clears the session, returning the router to the login branch.
    func clear() { state = nil }

    // MARK: - DEBUG

    #if DEBUG
    /// Pre-populates observable state for SwiftUI Previews and UI-test launch-arg injection.
    /// Not available in release builds — the entire block is stripped by the compiler.
    func injectState(state: UserSession? = nil, isRestoring: Bool = false) {
        self.state = state
        self.isRestoring = isRestoring
    }
    #endif
}

// MARK: - AuthSessionClearable conformance

extension AuthSessionStore: AuthSessionClearable {}
