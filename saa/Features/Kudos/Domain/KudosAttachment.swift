import Foundation

// MARK: - KudosAttachment

/// A successfully uploaded image attachment associated with a kudos post.
///
/// Returned by `KudosImageUploaderProtocol.upload(draft:)` after the image
/// bytes have been written to Supabase Storage. The domain layer treats this
/// as an immutable value — no network I/O required after construction.
///
/// Stored in `kudos_attachments` (FK → kudos.id, sort_order ascending).
struct KudosAttachment: Hashable, Sendable {

    /// Supabase Storage path relative to the bucket root, e.g. `"{userId}/abc.jpg"`.
    /// Do NOT include the bucket name or a leading slash.
    let storagePath: String

    /// MIME type of the stored file, e.g. `"image/jpeg"` or `"image/png"`.
    let contentType: String

    /// Size in bytes of the stored file.
    let byteSize: Int

    /// Zero-based display order within a kudos post's attachment list.
    let sortOrder: Int
}
