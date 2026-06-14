import Foundation
@testable import saa

// MARK: - NonceGeneratorFake
//
// Deterministic `NonceGenerating` implementation for unit tests.
// Injects fixed raw/hashed nonce values so assertions are stable across runs.

struct NonceGeneratorFake: NonceGenerating, Sendable {
    let raw:    String
    let hashed: String

    init(raw: String = "raw-test-nonce", hashed: String = "hashed-test-nonce") {
        self.raw    = raw
        self.hashed = hashed
    }

    func random() -> String         { raw }
    func sha256(_ raw: String) -> String { hashed }
}
