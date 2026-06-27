import Foundation

// MARK: - KudosImageUploaderProtocol

/// Uploads a single image draft to remote storage and returns the persisted attachment.
///
/// Implementations live in the Data layer (e.g. `SupabaseStorageImageUploader`).
/// The Domain and Presentation layers depend on this protocol only, keeping them
/// free of Supabase types.
///
/// Caller responsibilities:
/// - Validate image count, size, and MIME type via `CreateKudoValidator` BEFORE calling upload.
/// - Resize images wider than 2 048 px before constructing `KudosImageDraft`.
///
/// Throws `KudosError.imageTooLarge` when the server rejects an oversized payload,
/// `KudosError.unsupportedImageType` for non-JPEG/PNG content,
/// `KudosError.attachmentUploadFailed` for any other storage failure.
protocol KudosImageUploaderProtocol: Sendable {

    /// Uploads the given draft to Supabase Storage and returns the resulting attachment.
    ///
    /// - Parameter draft: The pre-validated image draft containing raw bytes and metadata.
    /// - Returns: A `KudosAttachment` with the storage path and metadata set by the server.
    /// - Throws: `KudosError` describing the upload failure.
    func upload(draft: KudosImageDraft) async throws -> KudosAttachment
}
