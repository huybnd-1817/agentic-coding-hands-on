import Foundation
import Supabase
import UIKit

// MARK: - SupabaseStorageImageUploader

/// Uploads a `KudosImageDraft` to Supabase Storage and returns a `KudosAttachment`.
///
/// Upload path: `kudos-images/{currentUserId}/{uuid}.{ext}`
///
/// Pre-upload steps (on the calling task's executor, not main actor):
///   1. Decode `draft.data` into a `UIImage` (required for resize check).
///   2. Downsize via `KudosImageResizer` if the longest edge exceeds 2 048 px.
///   3. Re-encode as JPEG (quality 0.85) or PNG when the source is PNG.
///   4. Upload final bytes to Supabase Storage.
///
/// Error mapping:
/// - HTTP 413 → `KudosError.imageTooLarge`
/// - Unsupported MIME type detected before upload → `KudosError.unsupportedImageType`
/// - Any other storage failure → `KudosError.attachmentUploadFailed`
final class SupabaseStorageImageUploader: KudosImageUploaderProtocol {

    // MARK: - Constants

    static let bucketName = "kudos-images"

    // MARK: - Dependencies

    private let client: SupabaseClient

    // MARK: - Init

    init(client: SupabaseClient? = nil) {
        self.client = client ?? SupabaseClientProvider.shared
    }

    // MARK: - KudosImageUploaderProtocol

    func upload(draft: KudosImageDraft) async throws -> KudosAttachment {
        // Guard: only JPEG and PNG are accepted.
        guard draft.contentType == "image/jpeg" || draft.contentType == "image/png" else {
            throw KudosError.unsupportedImageType
        }

        // Resolve the authenticated user's ID for the storage path.
        guard let userId = client.auth.currentUser?.id else {
            throw KudosError.notAuthenticated
        }

        // Downsize + re-encode on a background task (UIKit is safe on any thread for rendering).
        let (finalData, finalContentType) = try await Task.detached(priority: .userInitiated) {
            guard let image = UIImage(data: draft.data) else {
                throw KudosError.attachmentUploadFailed
            }
            guard let result = KudosImageResizer.resizeIfNeeded(
                image,
                sourceContentType: draft.contentType
            ) else {
                throw KudosError.attachmentUploadFailed
            }
            return (result.data, result.contentType)
        }.value

        // Build the storage path: "{userId}/{uuid}.{ext}".
        // Lowercase the userId segment: Postgres `auth.uid()::text` emits a
        // lowercase canonical UUID, and the storage RLS policy on this bucket
        // does a literal text compare against `(storage.foldername(name))[1]`.
        // Swift's `UUID.uuidString` returns uppercase, so without `.lowercased()`
        // every INSERT is denied with an RLS violation.
        let ext = finalContentType == "image/png" ? "png" : "jpg"
        let fileName = "\(UUID().uuidString).\(ext)"
        let storagePath = "\(userId.uuidString.lowercased())/\(fileName)"

        // Upload to Supabase Storage.
        do {
            try await client.storage
                .from(Self.bucketName)
                .upload(
                    storagePath,
                    data: finalData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: finalContentType,
                        upsert: false
                    )
                )
        } catch {
            throw KudosErrorMapper.from(error)
        }

        // sortOrder is set to 0 here; the repository re-assigns it by array position
        // when building the kudos_attachments batch (createKudo flow step 3).
        return KudosAttachment(
            storagePath: storagePath,
            contentType: finalContentType,
            byteSize: finalData.count,
            sortOrder: 0
        )
    }
}
