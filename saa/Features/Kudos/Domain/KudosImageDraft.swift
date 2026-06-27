import Foundation

// MARK: - KudosImageDraft

/// A user-selected image pending upload to Supabase Storage.
///
/// Created in the presentation layer when the user picks an image from the
/// photo library or camera. Passed to `KudosImageUploaderProtocol.upload(draft:)`
/// which returns a `KudosAttachment` on success.
///
/// The `id` is stable across retries so the VM can match upload results back
/// to the originating draft without relying on array position.
struct KudosImageDraft: Identifiable, Hashable, Sendable {

    /// Stable client-side identifier for this draft (not persisted).
    let id: UUID

    /// Raw image bytes ready for upload. JPEG or PNG only.
    /// The presentation layer is responsible for resizing images wider than
    /// 2 048 px before constructing this draft (clarifications.md §image-upload).
    let data: Data

    /// MIME type of `data`, e.g. `"image/jpeg"` or `"image/png"`.
    /// Must match the allowed set enforced by `CreateKudoValidator`.
    let contentType: String

    /// Size of `data` in bytes. Derived from `data.count` at construction time
    /// and stored separately so the validator can check limits without re-counting.
    let byteSize: Int

    // MARK: - Convenience

    /// Returns a new draft derived from the given raw data.
    ///
    /// - Parameters:
    ///   - data: Raw image bytes (JPEG or PNG).
    ///   - contentType: MIME type string, e.g. `"image/jpeg"`.
    init(data: Data, contentType: String) {
        self.id = UUID()
        self.data = data
        self.contentType = contentType
        self.byteSize = data.count
    }

    // MARK: - Hashable

    /// Equality and hashing are based on `id` only — two drafts with the same
    /// bytes but different UUIDs are considered distinct (allows re-upload of
    /// identical images as separate attachments).
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: KudosImageDraft, rhs: KudosImageDraft) -> Bool {
        lhs.id == rhs.id
    }
}
