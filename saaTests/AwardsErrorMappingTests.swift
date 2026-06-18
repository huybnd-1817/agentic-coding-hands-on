import XCTest
import Supabase
@testable import saa

// MARK: - AwardsErrorMappingTests
//
// Table-driven tests for AwardsErrorMapper.from(_:). Mirrors the structure of
// AuthErrorMappingTests so reviewers can compare both mappers side-by-side.

final class AwardsErrorMappingTests: XCTestCase {

    // MARK: - Pass-through

    func testPassThrough_unauthorized() {
        let result = AwardsErrorMapper.from(AwardsError.unauthorized)
        XCTAssertEqual(result, .unauthorized)
    }

    func testPassThrough_forbidden() {
        let result = AwardsErrorMapper.from(AwardsError.forbidden)
        XCTAssertEqual(result, .forbidden)
    }

    func testPassThrough_network() {
        let result = AwardsErrorMapper.from(AwardsError.network)
        XCTAssertEqual(result, .network)
    }

    // MARK: - URLError → network

    func testURLError_mapsToNetwork() {
        let result = AwardsErrorMapper.from(URLError(.notConnectedToInternet))
        XCTAssertEqual(result, .network)
    }

    // MARK: - PostgrestError 42501 → forbidden

    func testPostgrestError_42501_mapsToForbidden() {
        let pgError = PostgrestError(code: "42501", message: "permission denied")
        let result = AwardsErrorMapper.from(pgError)
        XCTAssertEqual(result, .forbidden)
    }

    func testPostgrestError_otherCode_mapsToUnknown() {
        let pgError = PostgrestError(code: "P0001", message: "some other failure")
        let result = AwardsErrorMapper.from(pgError)
        XCTAssertEqual(result, .unknown(underlying: pgError))
    }

    // MARK: - Supabase.AuthError.api → unauthorized / forbidden / unknown

    private func makeSupabaseApiError(statusCode: Int) -> Supabase.AuthError {
        Supabase.AuthError.api(
            message: "HTTP \(statusCode)",
            errorCode: .unknown,
            underlyingData: Data(),
            underlyingResponse: HTTPURLResponse(
                url: URL(string: "http://127.0.0.1:1/rest/v1/awards")!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
        )
    }

    func testSupabaseAuthError_401_mapsToUnauthorized() {
        let result = AwardsErrorMapper.from(makeSupabaseApiError(statusCode: 401))
        XCTAssertEqual(result, .unauthorized)
    }

    func testSupabaseAuthError_403_mapsToForbidden() {
        let result = AwardsErrorMapper.from(makeSupabaseApiError(statusCode: 403))
        XCTAssertEqual(result, .forbidden)
    }

    func testSupabaseAuthError_500_mapsToUnknown() {
        let result = AwardsErrorMapper.from(makeSupabaseApiError(statusCode: 500))
        XCTAssertEqual(result, .unknown(underlying: NSError()))
    }

    // MARK: - Fallback → unknown

    func testPlainNSError_mapsToUnknown() {
        let nsErr = NSError(domain: "com.test", code: 999)
        let result = AwardsErrorMapper.from(nsErr)
        XCTAssertEqual(result, .unknown(underlying: nsErr))
    }
}
