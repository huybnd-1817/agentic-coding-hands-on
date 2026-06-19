import Foundation
@testable import saa

// MARK: - KudosClipboardServiceFake
//
// Records every copy() call for assertion in tests.
// Simple implementation — no behavior switching needed.

final class KudosClipboardServiceFake: KudosClipboardServicing {

    private(set) var copiedTexts: [String] = []

    func copy(_ text: String) {
        copiedTexts.append(text)
    }
}
