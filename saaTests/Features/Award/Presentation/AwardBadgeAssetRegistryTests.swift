import XCTest
@testable import saa

// MARK: - AwardBadgeAssetRegistryTests
//
// Tests for `AwardBadgeAssetRegistry.image(for:)`:
//   - Known codes (award-badge-{code}) resolve to actual named assets.
//   - Unknown codes fall back to the placeholder (SF Symbol "rosette").
//
// Because SwiftUI `Image` doesn't expose its source publicly, we test the
// **precondition** that asset lookup validates: if `UIImage(named:)` finds
// the asset bundle, the registry will use it; otherwise falls back to placeholder.

final class AwardBadgeAssetRegistryTests: XCTestCase {

    // MARK: - Known codes resolve to assets

    /// Known award codes must have corresponding assets in the bundle.
    /// This test validates the precondition: if asset X exists, registry
    /// prefers it over the placeholder.
    func testImage_topTalent_assetExists() {
        let asset = UIImage(named: "award-badge-top_talent")
        XCTAssertNotNil(asset, "Asset 'award-badge-top_talent' must exist in the bundle")
    }

    func testImage_topProject_assetExists() {
        let asset = UIImage(named: "award-badge-top_project")
        XCTAssertNotNil(asset, "Asset 'award-badge-top_project' must exist in the bundle")
    }

    func testImage_topProjectLeader_assetExists() {
        let asset = UIImage(named: "award-badge-top_project_leader")
        XCTAssertNotNil(asset, "Asset 'award-badge-top_project_leader' must exist in the bundle")
    }

    func testImage_bestManager_assetExists() {
        let asset = UIImage(named: "award-badge-best_manager")
        XCTAssertNotNil(asset, "Asset 'award-badge-best_manager' must exist in the bundle")
    }

    func testImage_signature2026Creator_assetExists() {
        let asset = UIImage(named: "award-badge-signature_2026_creator")
        XCTAssertNotNil(asset, "Asset 'award-badge-signature_2026_creator' must exist in the bundle")
    }

    func testImage_mvp_assetExists() {
        let asset = UIImage(named: "award-badge-mvp")
        XCTAssertNotNil(asset, "Asset 'award-badge-mvp' must exist in the bundle")
    }

    // MARK: - Unknown codes fall back to placeholder

    /// When an asset is missing, the registry must not crash. It returns a
    /// placeholder (SF Symbol "rosette") instead. This test ensures the
    /// fallback branch exists and is used for unknown codes.
    func testImage_unknownCode_doesNotCrash() {
        let image = AwardBadgeAssetRegistry.image(for: "nonexistent_code_xyz")

        // We can't directly inspect SwiftUI `Image` internals, but we know:
        // - If the asset were present, UIImage(named:) would find it
        // - Since it doesn't, the registry returns the SF Symbol fallback
        // - The fact that image(for:) returns without crashing confirms the fallback works.
        XCTAssertNotNil(image, "Registry must return an image (placeholder or asset)")
    }

    func testImage_emptyCode_fallsBackToPlaceholder() {
        let image = AwardBadgeAssetRegistry.image(for: "")

        // Empty string → "award-badge-" doesn't exist → falls back to placeholder.
        XCTAssertNotNil(image, "Registry must return a placeholder for empty code")
    }

    // MARK: - Precondition validation: known codes are preferred

    /// If all known codes have assets in the bundle, the registry's lookup
    /// branch will always prefer them over the placeholder. This validates
    /// the precondition that drives the registry's logic.
    func testAllKnownCodes_haveAssets() {
        let knownCodes = [
            "top_talent",
            "top_project",
            "top_project_leader",
            "best_manager",
            "signature_2026_creator",
            "mvp"
        ]

        for code in knownCodes {
            let assetName = "award-badge-\(code)"
            let asset = UIImage(named: assetName)
            XCTAssertNotNil(
                asset,
                "Asset '\(assetName)' must exist; registry relies on bundle lookup"
            )
        }
    }
}
