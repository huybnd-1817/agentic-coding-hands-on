import Foundation

// MARK: - SignOutUseCase

/// Orchestrates sign-out from both the repository (Supabase) and the Google SDK.
///
/// Best-effort semantics: the Supabase network call is attempted but its failure
/// is intentionally swallowed — local state must be cleared regardless so the
/// user returns to the Login screen (TC_LOGIN_FUN_014).
///
/// Phase 04 will extend this use case to also accept an `AuthSessionStore`
/// dependency and call `store.clear()` after local sign-out.
struct SignOutUseCase: Sendable {

    private let repository: any AuthRepositoryProtocol
    private let googleService: any GoogleSignInServiceProtocol

    init(
        repository: some AuthRepositoryProtocol,
        googleService: some GoogleSignInServiceProtocol
    ) {
        self.repository = repository
        self.googleService = googleService
    }

    /// Signs the user out from Supabase (best-effort) and clears the Google session.
    ///
    /// Never throws — the repository call is wrapped in `try?` so a network failure
    /// does not prevent the Google cache from being cleared.
    @MainActor
    func execute() async {
        // Best-effort: network or server failure does not block local sign-out.
        try? await repository.signOut()
        googleService.clearLocalGoogleSession()
    }
}
