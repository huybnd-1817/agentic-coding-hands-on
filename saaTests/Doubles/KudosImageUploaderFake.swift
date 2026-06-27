import Foundation
@testable import saa

// MARK: - KudosImageUploaderFake
//
// Configurable test double implementing `KudosImageUploaderProtocol`.
// Supports configurable success / failure / delay behaviour + call counter.
//
// @unchecked Sendable: test doubles mutate properties from the test thread
// without synchronisation — intentional for ergonomics, never used in production.

final class KudosImageUploaderFake: KudosImageUploaderProtocol, @unchecked Sendable {

    // MARK: - Behavior

    indirect enum Behavior {
        /// Returns a `KudosAttachment` with the given `storagePath`.
        case success(storagePath: String)
        /// Throws the given `KudosError`.
        case failure(KudosError)
        /// Suspends for `nanoseconds` then applies the wrapped behavior.
        case delayed(nanoseconds: UInt64, then: Behavior)
    }

    // MARK: - Configuration

    var behavior: Behavior = .success(storagePath: "kudos-images/test/fake.jpg")

    // MARK: - Call tracking

    private(set) var uploadCalls = 0
    private(set) var lastDraft: KudosImageDraft?

    // MARK: - KudosImageUploaderProtocol

    func upload(draft: KudosImageDraft) async throws -> KudosAttachment {
        uploadCalls += 1
        lastDraft = draft
        return try await resolve(behavior: behavior, draft: draft, sortOrder: 0)
    }

    // MARK: - Private

    private func resolve(
        behavior: Behavior,
        draft: KudosImageDraft,
        sortOrder: Int
    ) async throws -> KudosAttachment {
        switch behavior {
        case .success(let path):
            return KudosAttachment(
                storagePath: path,
                contentType: draft.contentType,
                byteSize: draft.byteSize,
                sortOrder: sortOrder
            )
        case .failure(let error):
            throw error
        case .delayed(let ns, let next):
            try await Task.sleep(nanoseconds: ns)
            return try await resolve(behavior: next, draft: draft, sortOrder: sortOrder)
        }
    }
}
