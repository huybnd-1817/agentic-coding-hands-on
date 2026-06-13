import XCTest
@testable import saa

// MARK: - NonceTests
//
// Unit tests for Nonce.random() and Nonce.sha256(_:).
// No network I/O — pure crypto helpers only.

final class NonceTests: XCTestCase {

    // MARK: - Nonce.random()

    /// 32 random bytes → URL-safe Base64 without padding → ceil(32 * 4/3) = 43 chars.
    func testRandomDefaultLengthYields43Chars() {
        let nonce = Nonce.random()
        XCTAssertEqual(nonce.count, 43, "Default 32-byte nonce should encode to 43 URL-safe Base64 chars")
    }

    /// Every character must be in the URL-safe Base64 alphabet: A-Z a-z 0-9 - _
    /// ('+' replaced with '-', '/' with '_', padding '=' stripped).
    func testRandomAlphabetIsUrlSafe() {
        let nonce = Nonce.random()
        let urlSafePattern = "^[A-Za-z0-9_-]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", urlSafePattern)
        XCTAssertTrue(
            predicate.evaluate(with: nonce),
            "Nonce '\(nonce)' contains characters outside the URL-safe Base64 alphabet"
        )
    }

    /// Statistical uniqueness: 100 independent calls should yield 100 distinct strings.
    /// The probability of a collision with 32-byte CSPRNG output is negligible (~2^-256).
    func testRandomProducesUniqueValuesAcrossManyCalls() {
        let count = 100
        let nonces = (0..<count).map { _ in Nonce.random() }
        let uniqueCount = Set(nonces).count
        XCTAssertEqual(uniqueCount, count, "Expected \(count) unique nonces, got \(uniqueCount) unique values")
    }

    // MARK: - Nonce.sha256(_:)

    /// NIST FIPS 180-4 known-vector for SHA-256("abc") — see the `expected` constant
    /// below. Verified locally via `echo -n "abc" | shasum -a 256`.
    func testSha256MatchesKnownVector() {
        // NIST FIPS 180-4 test vector: SHA-256("abc")
        // Verified with: echo -n "abc" | shasum -a 256
        let expected = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        let digest = Nonce.sha256("abc")
        XCTAssertEqual(digest, expected, "SHA-256('abc') should match the NIST known vector")
    }

    /// Same input must always produce the same digest.
    func testSha256IsDeterministic() {
        let input = "deterministic-nonce-test-value"
        let first  = Nonce.sha256(input)
        let second = Nonce.sha256(input)
        XCTAssertEqual(first, second, "sha256(_:) must be deterministic for the same input")
    }

    /// SHA-256 produces a 256-bit digest → 32 bytes → 64 hex characters.
    func testSha256LengthIs64HexChars() {
        let digest = Nonce.sha256("any-nonce-string")
        XCTAssertEqual(digest.count, 64, "SHA-256 hex digest must be exactly 64 characters")
    }
}
