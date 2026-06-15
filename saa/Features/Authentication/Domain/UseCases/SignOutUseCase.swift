import Foundation

// MARK: - AuthSessionClearable

/// Seam that lets `SignOutUseCase` clear session state without importing
/// `AuthSessionStore` (a Presentation/Core type). Keeps Domain → Foundation only.
protocol AuthSessionClearable: Sendable {
    @MainActor func clear()
}

// MARK: - SignOutUseCase

/// Orchestrates sign-out from both the repository (Supabase) and the Google SDK,
/// then clears the local session store.
///
/// Best-effort semantics: the Supabase network call is attempted but its failure
/// is intentionally swallowed — local state must be cleared regardless so the
/// user returns to the Login screen (TC_LOGIN_FUN_014).
struct SignOutUseCase: Sendable {

    let repository: any AuthRepositoryProtocol
    let googleService: any GoogleSignInServiceProtocol
    let store: any AuthSessionClearable

    /// Signs the user out from Supabase (best-effort), clears the Google session,
    /// and wipes the local `AuthSessionStore`.
    ///
    /// Never throws — the repository call is wrapped in `try?` so a network failure
    /// does not prevent local sign-out (TC_LOGIN_FUN_014).
    @MainActor
    func execute() async {
        try? await repository.signOut()
        googleService.clearLocalGoogleSession()
        store.clear()
    }
}
