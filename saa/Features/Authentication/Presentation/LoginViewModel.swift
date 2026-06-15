import Foundation
import UIKit
import Combine

// MARK: - LoginViewModel

/// View model for the Login screen. Owns `isLoading` and `errorMessage` state
/// and delegates the sign-in flow to `SignInWithGoogleUseCase`.
///
/// Constructor-injected into `LoginViewContainer` from the composition root
/// (`saaApp`) so that fakes can be substituted in tests and Previews.
@MainActor
final class LoginViewModel: ObservableObject {

    // MARK: - Published state

    /// `true` while a sign-in request is in flight. Disables the button to
    /// prevent double-taps (TC_LOGIN_FUN_008).
    @Published private(set) var isLoading: Bool = false

    /// Localization catalog key for the most recent error, or `nil` when there
    /// is no error to display. `.userCancelled` maps to `nil` (silent dismissal).
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let signInUseCase: SignInWithGoogleUseCase
    private let store: AuthSessionStore

    // MARK: - Init

    init(signInUseCase: SignInWithGoogleUseCase, store: AuthSessionStore) {
        self.signInUseCase = signInUseCase
        self.store = store
    }

    // MARK: - Actions

    /// Runs the Google Sign-In flow and updates `store` on success.
    ///
    /// Guard against concurrent taps: returns immediately if already loading
    /// (TC_LOGIN_FUN_008).
    func signIn(presenting vc: UIViewController) async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let session = try await signInUseCase.execute(presenting: vc)
            store.setState(session)
            errorMessage = nil
        } catch {
            let mapped = AuthErrorMapper.from(error)
            // .userCancelled → messageKey is nil → UI stays silent per clarifications.md
            errorMessage = mapped.messageKey
        }
    }

    // MARK: - DEBUG

    #if DEBUG
    /// Pre-populates observable state for SwiftUI Previews and UI-test injection.
    func injectState(isLoading: Bool = false, errorMessage: String? = nil) {
        self.isLoading = isLoading
        self.errorMessage = errorMessage
    }
    #endif
}
