import SwiftUI

// MARK: - AwardBadgeAssetRegistry

/// Resolves the badge `Image` for a given award code.
///
/// Looks up `award-badge-{code}` in the asset catalogue. If the named asset
/// is not present (designer not yet delivered), returns a generic placeholder
/// so the layout never crashes.
enum AwardBadgeAssetRegistry {

    /// Returns the badge image for `code`, or a placeholder when the asset is missing.
    static func image(for code: String) -> Image {
        let assetName = "award-badge-\(code)"
        if UIImage(named: assetName) != nil {
            return Image(assetName)
        }
        return placeholder
    }

    // MARK: - Private

    private static var placeholder: Image {
        Image(systemName: "rosette")
    }
}
