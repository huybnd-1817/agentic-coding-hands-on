import XCTest
@testable import saa

// MARK: - SignInWithGoogleUseCaseTests  (Gate #3)
//
// Verifies the orchestration contract of `SignInWithGoogleUseCase`:
//   nonce generation → Google ID-token fetch → repository sign-in.
//
// No UIKit hosting beyond the protocol's `UIViewController` param.
// No GoogleSignIn SDK invoked. No network calls.
// All dependencies are injected as fakes defined in saaTests/Doubles/.

@MainActor
final class SignInWithGoogleUseCaseTests: XCTestCase {

    // MARK: - Happy path

    func test_orchestrates_nonce_google_and_repo_in_order() async throws {
        let nonce  = NonceGeneratorFake(raw: "raw-x", hashed: "hashed-x")
        let google = GoogleSignInServiceFake()
        google.obtainBehavior = .success("tok-x")
        let repo   = AuthRepositoryFake()
        let useCase = SignInWithGoogleUseCase(
            repository:     repo,
            googleService:  google,
            nonceGenerator: nonce
        )

        let session = try await useCase.execute(presenting: UIViewController())

        XCTAssertEqual(google.lastHashedNonce,    "hashed-x", "Google must receive hashed nonce")
        XCTAssertEqual(repo.lastSignInIdToken,    "tok-x",    "Repo must receive Google ID token")
        XCTAssertEqual(repo.lastSignInRawNonce,   "raw-x",    "Repo must receive raw (unhashed) nonce")
        XCTAssertEqual(google.obtainCalls, 1)
        XCTAssertEqual(repo.signInCalls,   1)
        XCTAssertEqual(session.userID, UserSession.preview.userID, "Returns the session from repo.signIn")
    }

    // MARK: - Error propagation

    func test_propagates_google_error_without_calling_repo() async {
        let nonce  = NonceGeneratorFake()
        let google = GoogleSignInServiceFake()
        google.obtainBehavior = .error(AuthError.userCancelled)
        let repo   = AuthRepositoryFake()
        let useCase = SignInWithGoogleUseCase(
            repository:     repo,
            googleService:  google,
            nonceGenerator: nonce
        )

        do {
            _ = try await useCase.execute(presenting: UIViewController())
            XCTFail("Expected userCancelled to propagate")
        } catch let error as AuthError {
            XCTAssertTrue(error ~== .userCancelled, "Expected .userCancelled, got \(error)")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        XCTAssertEqual(repo.signInCalls, 0, "Repo must NOT be called if Google failed")
    }

    func test_propagates_repository_error() async {
        struct BoomError: Error {}
        let nonce  = NonceGeneratorFake()
        let google = GoogleSignInServiceFake()
        let repo   = AuthRepositoryFake()
        repo.signInBehavior = .error(BoomError())
        let useCase = SignInWithGoogleUseCase(
            repository:     repo,
            googleService:  google,
            nonceGenerator: nonce
        )

        do {
            _ = try await useCase.execute(presenting: UIViewController())
            XCTFail("Expected BoomError to propagate")
        } catch is BoomError {
            // expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        XCTAssertEqual(repo.signInCalls, 1)
    }
}

// MARK: - AuthError pattern-match helper
//
// `AuthError` is not `Equatable` (`.unknown` carries an associated `Error`
// which itself may not be `Equatable`). This operator provides a minimal shim
// for the cases used in tests above.  `~==` avoids conflict with `==`.

infix operator ~==: ComparisonPrecedence

private func ~== (lhs: AuthError, rhs: AuthError) -> Bool {
    switch (lhs, rhs) {
    case (.userCancelled,    .userCancelled):    return true
    case (.networkUnavailable, .networkUnavailable): return true
    case (.notAuthorized,    .notAuthorized):    return true
    case (.unknown,          .unknown):          return true   // ignores underlying
    default:                                     return false
    }
}
