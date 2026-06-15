import Foundation

// MARK: - RestoreSessionUseCase

/// Restores a previously persisted authentication session at app launch.
///
/// Rule #3 justification: Although this delegates to a single repository call,
/// it is the canonical app-launch operation that prevents the view layer from
/// taking a direct dependency on `AuthRepositoryProtocol`. It also gets its own
/// unit test in Phase 05 (off-network restore with a stub repository), which
/// validates the exact session-nil path the root router relies on.
struct RestoreSessionUseCase: Sendable {

    private let repository: any AuthRepositoryProtocol

    init(repository: some AuthRepositoryProtocol) {
        self.repository = repository
    }

    /// Attempts to restore a session from the local Keychain.
    ///
    /// - Returns: A valid `UserSession` if one exists, otherwise `nil`.
    /// - Throws: `AuthError` if the Keychain read fails unexpectedly.
    func execute() async throws -> UserSession? {
        try await repository.restoreSession()
    }
}
