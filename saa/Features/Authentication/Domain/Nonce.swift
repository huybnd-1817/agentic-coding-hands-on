import Foundation
import CryptoKit

// MARK: - NonceGenerating

/// Abstraction over nonce generation so use cases can inject a deterministic
/// fake in unit tests without touching the live CSPRNG.
protocol NonceGenerating: Sendable {
    /// Returns a cryptographically random URL-safe nonce string.
    func random() -> String
    /// Returns the lowercase hex-encoded SHA-256 digest of `raw`.
    func sha256(_ raw: String) -> String
}

// MARK: - DefaultNonceGenerator

/// Production implementation of `NonceGenerating`. Delegates to the `Nonce`
/// static helpers so the underlying crypto logic lives in exactly one place.
struct DefaultNonceGenerator: NonceGenerating, Sendable {
    func random() -> String { Nonce.random() }
    func sha256(_ raw: String) -> String { Nonce.sha256(raw) }
}

// MARK: - Nonce

/// Cryptographic nonce helpers for the Google Sign-In + Supabase OIDC flow.
///
/// Flow:
///   1. `Nonce.random()` → `rawNonce`  (keep in memory, pass to Supabase)
///   2. `Nonce.sha256(rawNonce)` → `hashedNonce`  (pass to Google as `nonce:`)
///   3. Google embeds `hashedNonce` in the JWT `nonce` claim.
///   4. Supabase re-hashes `rawNonce` and verifies it matches the JWT claim.
///
/// Never log or persist `rawNonce` — it is a one-time secret.
enum Nonce {

    // MARK: - Random nonce

    /// Generates a cryptographically random URL-safe nonce string.
    ///
    /// Uses `SecRandomCopyBytes` for CSPRNG quality. The resulting bytes are
    /// mapped to a URL-safe Base64 alphabet (`A-Z a-z 0-9 - _`) so the string
    /// can be embedded in a JWT claim without percent-encoding.
    ///
    /// - Parameter length: Number of random bytes to generate (default 32,
    ///   yielding ~43 URL-safe characters). Must be > 0.
    /// - Returns: URL-safe Base64-encoded random nonce string.
    static func random(length: Int = 32) -> String {
        precondition(length > 0, "Nonce length must be greater than zero.")

        var bytes = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        assert(status == errSecSuccess, "SecRandomCopyBytes failed — \(status)")

        // URL-safe Base64: replace '+' → '-' and '/' → '_', strip '=' padding.
        return Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    // MARK: - SHA-256 hash

    /// Returns the lowercase hex-encoded SHA-256 digest of `input`.
    ///
    /// Used to produce the `nonce` parameter passed to Google. Google embeds this
    /// hash in the returned ID token's `nonce` claim, which Supabase then verifies
    /// by hashing the raw nonce supplied at `signInWithIdToken` time.
    ///
    /// - Parameter input: The raw nonce string produced by `Nonce.random()`.
    /// - Returns: Lowercase hex string of the SHA-256 digest (64 characters).
    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Nonce convenience accessor

extension Nonce {
    /// Shared production `NonceGenerating` instance for injection into use cases.
    static let `default`: any NonceGenerating = DefaultNonceGenerator()
}
