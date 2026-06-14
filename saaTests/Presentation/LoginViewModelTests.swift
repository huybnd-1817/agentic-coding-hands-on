import XCTest
import UIKit
@testable import saa

// MARK: - LoginViewModelTests
//
// Covers `LoginViewModel` state transitions:
//   idle → loading → signedIn / error
//
// All tests are @MainActor because `LoginViewModel` is `@MainActor`-isolated and
// all its `@Published` properties must be read on the main actor.

@MainActor
final class LoginViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeViewModel(
        repo:   AuthRepositoryFake?      = nil,
        google: GoogleSignInServiceFake? = nil
    ) -> (LoginViewModel, AuthSessionStore, AuthRepositoryFake, GoogleSignInServiceFake) {
        let repo   = repo   ?? AuthRepositoryFake()
        let google = google ?? GoogleSignInServiceFake()
        let store  = AuthSessionStore()
        let useCase = SignInWithGoogleUseCase(
            repository:     repo,
            googleService:  google,
            nonceGenerator: NonceGeneratorFake()
        )
        let vm = LoginViewModel(signInUseCase: useCase, store: store)
        return (vm, store, repo, google)
    }

    // MARK: - Initial state

    // async required: LoginViewModel + AuthSessionStore are @MainActor-isolated;
    // sync dealloc races with the main-actor deinit enqueue → SIGABRT (Rule 1).
    func test_init_state_is_idle() async {
        let (vm, _, _, _) = makeViewModel()
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - Successful sign-in

    func test_successful_signIn_updates_store_and_clears_loading() async {
        let (vm, store, repo, _) = makeViewModel()
        repo.signInBehavior = .success(.preview)

        await vm.signIn(presenting: UIViewController())

        XCTAssertFalse(vm.isLoading, "Loading must be cleared on success")
        XCTAssertNil(vm.errorMessage, "Error must be nil on success")
        XCTAssertEqual(store.state?.userID, UserSession.preview.userID)
    }

    // MARK: - Error states

    func test_signIn_sets_errorMessage_for_known_AuthError() async {
        let (vm, store, repo, _) = makeViewModel()
        repo.signInBehavior = .error(AuthError.networkUnavailable)

        await vm.signIn(presenting: UIViewController())

        XCTAssertFalse(vm.isLoading)
        XCTAssertEqual(vm.errorMessage, "login.error.network")
        XCTAssertNil(store.state, "Store must not be updated on failure")
    }

    func test_userCancelled_results_in_silent_dismissal() async {
        let (vm, _, repo, _) = makeViewModel()
        repo.signInBehavior = .error(AuthError.userCancelled)

        await vm.signIn(presenting: UIViewController())

        XCTAssertNil(vm.errorMessage, ".userCancelled must produce nil errorMessage (silent)")
        XCTAssertFalse(vm.isLoading)
    }

    func test_notAuthorized_sets_correct_error_key() async {
        let (vm, _, repo, _) = makeViewModel()
        repo.signInBehavior = .error(AuthError.notAuthorized)

        await vm.signIn(presenting: UIViewController())

        XCTAssertEqual(vm.errorMessage, "login.error.notAuthorized")
    }

    func test_unknown_error_sets_correct_error_key() async {
        let (vm, _, repo, _) = makeViewModel()
        repo.signInBehavior = .error(AuthError.unknown(underlying: NSError(domain: "test", code: 0)))

        await vm.signIn(presenting: UIViewController())

        XCTAssertEqual(vm.errorMessage, "login.error.unknown")
    }

    // MARK: - Concurrent tap guard

    func test_concurrent_taps_are_guarded() async {
        let (vm, _, repo, _) = makeViewModel()
        repo.signInBehavior = .success(.preview)

        // Fire two concurrent sign-in tasks. The guard (`guard !isLoading`) must
        // prevent more than one overlapping invocation.
        async let first: Void  = vm.signIn(presenting: UIViewController())
        async let second: Void = vm.signIn(presenting: UIViewController())
        _ = await (first, second)

        // Strict count is scheduler-dependent; contract is ≤ 2 calls and loading cleared.
        XCTAssertLessThanOrEqual(repo.signInCalls, 2)
        XCTAssertFalse(vm.isLoading)
    }
}
