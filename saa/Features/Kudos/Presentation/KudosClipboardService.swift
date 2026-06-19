import UIKit

// MARK: - KudosClipboardServicing

/// Domain-side seam for clipboard writes.
///
/// Declared in Presentation (not Domain) because the only concrete implementation
/// uses `UIPasteboard` — an SDK type that must not leak into the Domain layer.
/// This mirrors the `GoogleSignInServiceProtocol` UIKit-exception pattern documented
/// in `code-standards.md`.
///
/// All conformances must be `Sendable` — the protocol is injected into `KudosViewModel`
/// which is `@MainActor`-isolated.
protocol KudosClipboardServicing: Sendable {
    /// Writes `text` to the system clipboard, replacing any prior contents.
    func copy(_ text: String)
}

// MARK: - UIKitKudosClipboardService

/// Production clipboard writer backed by `UIPasteboard.general`.
///
/// `UIPasteboard` operations are always safe to call on any thread per Apple docs,
/// so `Sendable` conformance holds without `@unchecked`.
struct UIKitKudosClipboardService: KudosClipboardServicing {
    func copy(_ text: String) {
        UIPasteboard.general.string = text
    }
}
