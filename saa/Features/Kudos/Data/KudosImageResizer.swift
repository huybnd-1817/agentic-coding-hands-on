import UIKit

// MARK: - KudosImageResizer

/// Downsizes a `UIImage` so that its longest edge does not exceed `maxEdge` pixels,
/// then encodes the result as JPEG (quality 0.85) or PNG.
///
/// All heavy work runs on a background `Task`-inherited executor — callers should
/// `await` inside an async context so the main actor is not blocked.
///
/// Design notes:
/// - PNG source is preserved as PNG to avoid lossy re-encoding of transparency.
/// - JPEG source (or any other source) is encoded as JPEG at quality 0.85.
/// - Downsize only occurs when the longest edge exceeds `maxEdge`; images already
///   within the threshold are re-encoded from the original `UIImage` without rescaling.
enum KudosImageResizer {

    // MARK: - Constants

    /// Maximum allowed longest edge in pixels (per clarifications.md §image-upload).
    static let maxEdge: CGFloat = 2048

    /// JPEG compression quality (0.0–1.0). 0.85 balances quality and file size.
    static let jpegQuality: CGFloat = 0.85

    // MARK: - ResizeResult

    /// Outcome of a resize-and-encode operation.
    struct ResizeResult: Sendable {
        /// Encoded image bytes ready for upload.
        let data: Data
        /// MIME type of `data`: `"image/jpeg"` or `"image/png"`.
        let contentType: String
    }

    // MARK: - Public API

    /// Resizes `image` if its longest edge exceeds `maxEdge`, then encodes it.
    ///
    /// - Parameters:
    ///   - image: The source `UIImage` (any scale factor accepted).
    ///   - sourceContentType: Original MIME type; `"image/png"` is preserved,
    ///     all others are encoded as JPEG.
    /// - Returns: `ResizeResult` on success, `nil` when encoding fails (e.g. corrupted image).
    static func resizeIfNeeded(
        _ image: UIImage,
        sourceContentType: String
    ) -> ResizeResult? {
        let isPNG = sourceContentType == "image/png"
        let resized = downscaled(image)
        if isPNG {
            guard let data = resized.pngData() else { return nil }
            return ResizeResult(data: data, contentType: "image/png")
        } else {
            guard let data = resized.jpegData(compressionQuality: jpegQuality) else { return nil }
            return ResizeResult(data: data, contentType: "image/jpeg")
        }
    }

    // MARK: - Private

    /// Returns the image scaled down so its longest edge (in pixels) ≤ `maxEdge`.
    /// Uses pixel dimensions — not UIKit point dimensions — to match the
    /// clarifications constraint of "Client downsizes >2048px".
    /// Returns `image` unchanged when it already fits.
    private static func downscaled(_ image: UIImage) -> UIImage {
        // Pixel dimensions = point size × scale factor.
        let pixelWidth  = image.size.width  * image.scale
        let pixelHeight = image.size.height * image.scale
        let longestEdge = max(pixelWidth, pixelHeight)
        guard longestEdge > maxEdge else { return image }

        let scaleFactor = maxEdge / longestEdge
        // Target is in points at scale 1 (UIGraphicsImageRenderer renders at scale 1
        // when no explicit format is provided; we force 1x so output pixel size = target).
        let targetPixelWidth  = (pixelWidth  * scaleFactor).rounded()
        let targetPixelHeight = (pixelHeight * scaleFactor).rounded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(
            size: CGSize(width: targetPixelWidth, height: targetPixelHeight),
            format: format
        )
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: CGSize(width: targetPixelWidth, height: targetPixelHeight)))
        }
    }
}
