#if DEBUG
import Foundation

// MARK: - MockKudosImageUploader

/// In-memory stub implementation of `KudosImageUploaderProtocol` for SwiftUI
/// previews and UI-test injection via `-uiTestMode kudos.create`.
///
/// Always returns a synthetic `KudosAttachment` without network I/O.
/// NOT wired in production — gated by `#if DEBUG`.
struct MockKudosImageUploader: KudosImageUploaderProtocol, Sendable {

    func upload(draft: KudosImageDraft) async throws -> KudosAttachment {
        KudosAttachment(
            storagePath: "kudos-images/mock/\(draft.id.uuidString).jpg",
            contentType: draft.contentType,
            byteSize: draft.byteSize,
            sortOrder: 0
        )
    }
}
#endif
