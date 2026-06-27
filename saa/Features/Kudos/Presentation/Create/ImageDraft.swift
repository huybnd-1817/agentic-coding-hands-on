import Foundation

// MARK: - ImageUploadState

/// Per-image upload lifecycle tracked by `CreateKudoViewModel`.
///
/// Transitions:
///   idle → uploading (on task start)
///   uploading → uploaded(path) (on success)
///   uploading → failed (on error)
///
/// Only `uploaded` images are included in the final `CreateKudoRequest`.
enum ImageUploadState: Equatable, Sendable {
    case idle
    case uploading
    case uploaded(storagePath: String)
    case failed

    var isUploaded: Bool {
        if case .uploaded = self { return true }
        return false
    }

    var storagePath: String? {
        if case .uploaded(let path) = self { return path }
        return nil
    }
}

// MARK: - ImageDraftVM

/// Presentation-layer draft that pairs a domain `KudosImageDraft` with its
/// current upload state. Separate from `ImageDraft` (the plain UI struct in
/// `CreateKudoModels.swift`) — the VM owns this richer version internally and
/// exposes `[ImageDraft]` (localURL only) to the view.
struct ImageDraftVM: Identifiable, Sendable {
    typealias ID = UUID

    /// Stable identifier — matches the underlying `KudosImageDraft.id`.
    let id: ID

    /// Local file URL for thumbnail rendering (passed to the view layer).
    let localURL: URL

    /// The validated domain draft passed to the uploader.
    let domain: KudosImageDraft

    /// Current upload lifecycle state.
    var uploadState: ImageUploadState = .idle
}
