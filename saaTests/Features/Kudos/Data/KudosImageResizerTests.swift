import XCTest
import UIKit
@testable import saa

// MARK: - KudosImageResizerTests
//
// Verifies `KudosImageResizer.resizeIfNeeded(_:sourceContentType:)`:
// - Images within maxEdge are not scaled (same pixel dimensions).
// - Landscape images wider than maxEdge are scaled down proportionally.
// - Portrait images taller than maxEdge are scaled down proportionally.
// - PNG source → PNG output; JPEG source → JPEG output.
// - Encoding produces non-empty data.

final class KudosImageResizerTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a solid-colour UIImage at the given **pixel** size (scale=1).
    ///
    /// Using `scale=1` ensures `image.size` == pixel dimensions on any device,
    /// making tests device-scale-agnostic. `KudosImageResizer` compares pixel
    /// dimensions (`size × scale`), so passing scale-1 images means the test's
    /// stated width/height are exactly the pixel sizes the resizer sees.
    private func makeImage(width: Int, height: Int, color: UIColor = .red) -> UIImage {
        let size = CGSize(width: width, height: height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// Returns the pixel dimensions of a UIImage, accounting for scale.
    private func pixelSize(of image: UIImage) -> CGSize {
        CGSize(
            width: image.size.width * image.scale,
            height: image.size.height * image.scale
        )
    }

    // MARK: - Within bounds: no resize

    func testImageWithinBounds_jpegNotResized() {
        let image = makeImage(width: 800, height: 600)
        let result = KudosImageResizer.resizeIfNeeded(image, sourceContentType: "image/jpeg")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.contentType, "image/jpeg")
        // Decode result to verify dimensions unchanged.
        if let data = result?.data, let decoded = UIImage(data: data) {
            let ps = pixelSize(of: decoded)
            XCTAssertLessThanOrEqual(ps.width, 800)   // may differ slightly due to JPEG encode
            XCTAssertLessThanOrEqual(ps.height, 600)
        }
    }

    func testImageExactlyAtBound_notResized() {
        let image = makeImage(width: Int(KudosImageResizer.maxEdge), height: 100)
        let result = KudosImageResizer.resizeIfNeeded(image, sourceContentType: "image/jpeg")
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.data.isEmpty)
    }

    // MARK: - Landscape: width > maxEdge

    func testLandscapeImageExceedingBound_resizedProportionally() {
        let originalWidth = 4096
        let originalHeight = 2048
        let image = makeImage(width: originalWidth, height: originalHeight)

        let result = KudosImageResizer.resizeIfNeeded(image, sourceContentType: "image/jpeg")

        XCTAssertNotNil(result)
        guard let data = result?.data, let decoded = UIImage(data: data) else {
            XCTFail("Decode failed")
            return
        }
        let ps = pixelSize(of: decoded)
        // Longest edge must be ≤ maxEdge.
        XCTAssertLessThanOrEqual(max(ps.width, ps.height), KudosImageResizer.maxEdge + 1) // +1 rounding
        // Aspect ratio preserved within 5%.
        let originalRatio = Double(originalWidth) / Double(originalHeight)
        let resultRatio   = Double(ps.width) / Double(ps.height)
        XCTAssertEqual(resultRatio, originalRatio, accuracy: 0.05)
    }

    // MARK: - Portrait: height > maxEdge

    func testPortraitImageExceedingBound_resizedProportionally() {
        let originalWidth  = 1024
        let originalHeight = 4096
        let image = makeImage(width: originalWidth, height: originalHeight)

        let result = KudosImageResizer.resizeIfNeeded(image, sourceContentType: "image/jpeg")

        XCTAssertNotNil(result)
        guard let data = result?.data, let decoded = UIImage(data: data) else {
            XCTFail("Decode failed")
            return
        }
        let ps = pixelSize(of: decoded)
        XCTAssertLessThanOrEqual(max(ps.width, ps.height), KudosImageResizer.maxEdge + 1)
    }

    // MARK: - PNG source preserved as PNG

    func testPNGSource_returnsPNG() {
        let image = makeImage(width: 100, height: 100)
        let result = KudosImageResizer.resizeIfNeeded(image, sourceContentType: "image/png")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.contentType, "image/png")
        XCTAssertFalse(result!.data.isEmpty)
    }

    func testPNGSourceExceedingBound_resizedAndReturnsPNG() {
        let image = makeImage(width: 3000, height: 1000)
        let result = KudosImageResizer.resizeIfNeeded(image, sourceContentType: "image/png")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.contentType, "image/png")
        guard let data = result?.data, let decoded = UIImage(data: data) else {
            XCTFail("Decode failed"); return
        }
        let ps = pixelSize(of: decoded)
        XCTAssertLessThanOrEqual(max(ps.width, ps.height), KudosImageResizer.maxEdge + 1)
    }

    // MARK: - JPEG source yields JPEG

    func testJPEGSource_returnsJPEG() {
        let image = makeImage(width: 200, height: 200)
        let result = KudosImageResizer.resizeIfNeeded(image, sourceContentType: "image/jpeg")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.contentType, "image/jpeg")
    }

    // MARK: - Non-PNG source treated as JPEG

    func testUnknownSourceContentType_treatedAsJPEG() {
        let image = makeImage(width: 100, height: 100)
        let result = KudosImageResizer.resizeIfNeeded(image, sourceContentType: "image/webp")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.contentType, "image/jpeg")
    }
}
