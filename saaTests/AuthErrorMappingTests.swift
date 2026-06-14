import XCTest
import GoogleSignIn
import Supabase
@testable import saa

// MARK: - AuthErrorMappingTests
//
// Table-driven tests for AuthErrorMapper.from(_:).
//
// "AuthError" is ambiguous in this module because Supabase re-exports Auth.AuthError.
// All references to the domain-level error use the explicit "saa.AuthError" qualifier.
//
// Skipped branches / known limitations:
// - GIDSignInError.canceled: ObjC NS_ERROR_ENUM bridge; synthesised via NSError with
//   kGIDSignInErrorDomain + GIDSignInError.canceled.rawValue (-5). Casting succeeds
//   because Swift error bridging re-boxes ObjC errors into their typed enum on cast.
// - Supabase.AuthError.api constructors are all public in v2.47.0 — fully covered.
// - PostgrestError has a public memberwise init in v2.47.0 — fully covered.

final class AuthErrorMappingTests: XCTestCase {

    // MARK: - Pass-through

    func testPassThroughAuthError_userCancelled() {
        let input: saa.AuthError = .userCancelled
        let result = AuthErrorMapper.from(input)
        guard case .userCancelled = result else {
            XCTFail("Expected .userCancelled, got \(result)")
            return
        }
    }

    func testPassThroughAuthError_networkUnavailable() {
        let input: saa.AuthError = .networkUnavailable
        let result = AuthErrorMapper.from(input)
        guard case .networkUnavailable = result else {
            XCTFail("Expected .networkUnavailable, got \(result)")
            return
        }
    }

    // MARK: - URLError → networkUnavailable

    func testURLError_mapsToNetworkUnavailable() {
        let result = AuthErrorMapper.from(URLError(.notConnectedToInternet))
        guard case .networkUnavailable = result else {
            XCTFail("Expected .networkUnavailable, got \(result)")
            return
        }
    }

    // MARK: - GIDSignInError.canceled → userCancelled
    //
    // GIDSignInError is bridged from ObjC NS_ERROR_ENUM(kGIDSignInErrorDomain).
    // kGIDSignInErrorCodeCanceled = -5.  Swift error bridging re-boxes the NSError
    // into a typed GIDSignInError when `error as? GIDSignInError` is evaluated.

    func testGIDSignInError_canceled_mapsToUserCancelled() {
        let nsErr = NSError(
            domain: kGIDSignInErrorDomain,
            code: GIDSignInError.canceled.rawValue   // -5
        )
        let result = AuthErrorMapper.from(nsErr)
        guard case .userCancelled = result else {
            XCTFail("Expected .userCancelled for GIDSignInError.canceled, got \(result)")
            return
        }
    }

    // MARK: - Supabase.AuthError.api → notAuthorized / unknown

    private func makeSupabaseApiError(statusCode: Int) -> Supabase.AuthError {
        Supabase.AuthError.api(
            message: "HTTP \(statusCode)",
            errorCode: .unknown,
            underlyingData: Data(),
            underlyingResponse: HTTPURLResponse(
                url: URL(string: "http://127.0.0.1:1/auth/v1/token")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
        )
    }

    func testSupabaseAuthError_401_mapsToNotAuthorized() {
        let result = AuthErrorMapper.from(makeSupabaseApiError(statusCode: 401))
        guard case .notAuthorized = result else {
            XCTFail("Expected .notAuthorized for 401, got \(result)")
            return
        }
    }

    func testSupabaseAuthError_403_mapsToNotAuthorized() {
        let result = AuthErrorMapper.from(makeSupabaseApiError(statusCode: 403))
        guard case .notAuthorized = result else {
            XCTFail("Expected .notAuthorized for 403, got \(result)")
            return
        }
    }

    func testSupabaseAuthError_422_mapsToNotAuthorized() {
        let result = AuthErrorMapper.from(makeSupabaseApiError(statusCode: 422))
        guard case .notAuthorized = result else {
            XCTFail("Expected .notAuthorized for 422, got \(result)")
            return
        }
    }

    func testSupabaseAuthError_500_mapsToUnknown() {
        let result = AuthErrorMapper.from(makeSupabaseApiError(statusCode: 500))
        guard case .unknown = result else {
            XCTFail("Expected .unknown for 500, got \(result)")
            return
        }
    }

    // MARK: - PostgrestError → notAuthorized

    func testPostgrestError_code42501_mapsToNotAuthorized() {
        let pgError = PostgrestError(code: "42501", message: "permission denied")
        let result = AuthErrorMapper.from(pgError)
        guard case .notAuthorized = result else {
            XCTFail("Expected .notAuthorized for PostgrestError code 42501, got \(result)")
            return
        }
    }

    func testPostgrestError_accountNotAuthorizedMessage_mapsToNotAuthorized() {
        let pgError = PostgrestError(
            code: "P0001",
            message: "Account not authorized for this operation"
        )
        let result = AuthErrorMapper.from(pgError)
        guard case .notAuthorized = result else {
            XCTFail("Expected .notAuthorized for PostgrestError 'Account not authorized', got \(result)")
            return
        }
    }

    // MARK: - Fallback → unknown

    func testPlainNSError_mapsToUnknown() {
        let nsErr = NSError(domain: "com.test", code: 999)
        let result = AuthErrorMapper.from(nsErr)
        guard case .unknown = result else {
            XCTFail("Expected .unknown for plain NSError, got \(result)")
            return
        }
    }
}
