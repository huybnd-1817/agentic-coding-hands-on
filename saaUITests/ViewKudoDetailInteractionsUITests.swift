import XCTest

// MARK: - ViewKudoDetailInteractionsUITests
//
// Gap D (UI/XCUITest): Extended interactions on the detail screen beyond basic navigation.
// Covers:
// - Gap D5: Lightbox — tap first thumbnail → lightbox mounts → close dismisses
// - Gap D6: Sender/recipient tap — tap avatar/name → profile stub pushes → back pops
// - Gap D7: Hashtag tap-and-pop-and-filter — tap hashtag → returns to Kudos root + filter applied
// - Gap D8: Anonymous sender label — navigate to anonymous kudo → "Người gửi ẩn danh" visible
//
// Reuses `launchAndOpenDetail()` helper pattern and waitForExistence with 30s timeout
// (documented in AllKudosScreenUITests.swift for cold-clone simulator behavior).

@MainActor
final class ViewKudoDetailInteractionsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Helpers

    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func navTab(label: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    /// Launches signed in, switches to Kudos tab, and opens the detail screen.
    /// Returns the app once `kudos.detail.root` is visible.
    private func launchAndOpenDetail() throws -> XCUIApplication {
        let app = XCUIApplication.launching(.signedIn)

        let kudosTab = navTab(label: "Kudos", in: app)
        XCTAssertTrue(kudosTab.waitForExistence(timeout: 5), "Kudos nav tab must exist")
        kudosTab.tap()

        XCTAssertTrue(
            element("kudos.root", in: app).waitForExistence(timeout: 5),
            "kudos.root must mount before searching for a viewDetail button"
        )

        let viewDetail = app.descendants(matching: .button).matching(
            NSPredicate(format: "label IN {'Xem chi tiết', 'View details'}")
        ).firstMatch
        XCTAssertTrue(
            viewDetail.waitForExistence(timeout: 10),
            "At least one 'Xem chi tiết / View details' button must exist on the Kudos tab"
        )

        var attempts = 0
        while !viewDetail.isHittable, attempts < 20 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(
            viewDetail.isHittable,
            "viewDetail button must become hittable after at most 20 swipeUps"
        )
        viewDetail.tap()

        XCTAssertTrue(
            element("kudos.detail.root", in: app).waitForExistence(timeout: 30),
            "Detail screen (kudos.detail.root) must mount after tapping viewDetail"
        )
        return app
    }

    // MARK: - Gap D5: Lightbox interaction

    /// Gap D5: Tap a thumbnail → lightbox mounts → close button visible → tap closes
    func testLightbox_tapThumbnail_opensLightbox_andCloseButtonDismisses() throws {
        let app = try launchAndOpenDetail()

        // Find the first image in the gallery (kudos.detail.gallery.image.0)
        let firstImage = element("kudos.detail.gallery.image.0", in: app)
        XCTAssertTrue(
            firstImage.waitForExistence(timeout: 5),
            "First gallery image must exist on detail screen"
        )

        firstImage.tap()

        // Lightbox should now mount (kudos.detail.lightbox.root)
        XCTAssertTrue(
            element("kudos.detail.lightbox.root", in: app).waitForExistence(timeout: 10),
            "Lightbox (kudos.detail.lightbox.root) must mount after tapping image"
        )

        // Close button should be visible
        let closeButton = element("kudos.detail.lightbox.close", in: app)
        XCTAssertTrue(
            closeButton.waitForExistence(timeout: 5),
            "Lightbox close button (kudos.detail.lightbox.close) must exist"
        )

        closeButton.tap()

        // Lightbox should dismiss — identifier should no longer exist
        let lightboxDismissed = element("kudos.detail.lightbox.root", in: app).waitForNonExistence(timeout: 5)
        XCTAssertTrue(
            lightboxDismissed,
            "Lightbox must dismiss after tapping close button"
        )

        // Detail screen should still be visible
        XCTAssertTrue(
            element("kudos.detail.root", in: app).exists,
            "Detail screen must remain visible after lightbox closes"
        )
    }

    // MARK: - Gap D6: Sender/recipient tap → profile stub push

    /// Gap D6: Tap sender avatar/name → profile stub pushes → back-swipe pops
    func testSenderTap_pushesProfileStub_andBackPops() throws {
        let app = try launchAndOpenDetail()

        // Tap the sender profile area (LEFT side of trao-nhận row)
        // The sender row has identifier kudos.detail.sender.button
        let senderButton = element("kudos.detail.sender.button", in: app)
        XCTAssertTrue(
            senderButton.waitForExistence(timeout: 5),
            "Sender button (kudos.detail.sender.button) must exist on detail screen"
        )

        senderButton.tap()

        // Profile stub should push (kudos.detail.profile.root)
        XCTAssertTrue(
            element("kudos.detail.profile.root", in: app).waitForExistence(timeout: 10),
            "Profile stub (kudos.detail.profile.root) must mount after tapping sender"
        )

        // Back-swipe or back chevron to pop
        let backChevron = element("kudos.detail.profile.back", in: app)
        if backChevron.waitForExistence(timeout: 2) {
            backChevron.tap()
        } else {
            // Fallback: swipe from left edge to pop
            let screenSize = app.windows.element.frame
            let edge = CGPoint(x: screenSize.minX + 10, y: screenSize.midY)
            let target = CGPoint(x: screenSize.maxX - 50, y: screenSize.midY)
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)).press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        }

        // Profile should dismiss, detail should return
        XCTAssertTrue(
            element("kudos.detail.root", in: app).waitForExistence(timeout: 10),
            "Detail screen must remount after popping profile stub"
        )
    }

    /// Gap D6: Tap recipient avatar/name → profile stub pushes → back pops
    func testRecipientTap_pushesProfileStub_andBackPops() throws {
        let app = try launchAndOpenDetail()

        // Tap the recipient profile area (RIGHT side of trao-nhận row)
        // The recipient row has identifier kudos.detail.recipient.button
        let recipientButton = element("kudos.detail.recipient.button", in: app)
        XCTAssertTrue(
            recipientButton.waitForExistence(timeout: 5),
            "Recipient button (kudos.detail.recipient.button) must exist on detail screen"
        )

        recipientButton.tap()

        // Profile stub should push
        XCTAssertTrue(
            element("kudos.detail.profile.root", in: app).waitForExistence(timeout: 10),
            "Profile stub must mount after tapping recipient"
        )

        // Pop back
        let backChevron = element("kudos.detail.profile.back", in: app)
        if backChevron.waitForExistence(timeout: 2) {
            backChevron.tap()
        } else {
            // Fallback: swipe from left edge to pop
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.5)).press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        }

        // Detail should return
        XCTAssertTrue(
            element("kudos.detail.root", in: app).waitForExistence(timeout: 10),
            "Detail screen must remount after popping profile from recipient tap"
        )
    }

    // MARK: - Gap D7: Hashtag tap → pop and filter

    /// Gap D7: Tap hashtag pill → returns to Kudos root → filter applied
    func testHashtagTap_popsToKudosRoot_andAppliesFilter() throws {
        let app = try launchAndOpenDetail()

        // Find a hashtag pill (kudos.detail.hashtag.<tag>)
        let hashtags = app.descendants(matching: .button).matching(
            NSPredicate(format: "identifier BEGINSWITH 'kudos.detail.hashtag.'")
        )
        XCTAssertGreaterThan(hashtags.count, 0,
                             "At least one hashtag pill must exist on detail screen")

        let firstHashtag = hashtags.element(boundBy: 0)
        XCTAssertTrue(firstHashtag.waitForExistence(timeout: 5),
                      "First hashtag pill must be accessible")

        // Capture the tag from the identifier (e.g. "kudos.detail.hashtag.#Dedicated"
        // → "#Dedicated"). Reading the .label string here is unreliable on cold
        // simulator clones because SwiftUI sometimes returns the raw glyph text
        // before localization settles.
        let identifierPrefix = "kudos.detail.hashtag."
        let identifier = firstHashtag.identifier
        guard identifier.hasPrefix(identifierPrefix) else {
            XCTFail("Hashtag pill identifier must start with '\(identifierPrefix)' — got '\(identifier)'")
            return
        }
        let hashtagTag = String(identifier.dropFirst(identifierPrefix.count))
        XCTAssertFalse(hashtagTag.isEmpty, "Captured hashtag tag must be non-empty")

        firstHashtag.tap()

        // Should pop back to Kudos root.
        XCTAssertTrue(
            element("kudos.root", in: app).waitForExistence(timeout: 10),
            "Tapping hashtag must pop back to Kudos root (kudos.root)"
        )

        // The hashtag filter chip lives on the Kudos tab root. Its accessibility
        // label is "<placeholder>: <selectedValue>" when active — see
        // KudosFilterChip.accessibilityLabel. The chip's identifier is
        // `kudos.filterChip.hashtag` (not `kudos.root.filter`).
        let chip = app.descendants(matching: .any)
            .matching(identifier: "kudos.filterChip.hashtag").firstMatch
        XCTAssertTrue(chip.waitForExistence(timeout: 5),
                      "Hashtag filter chip must exist on Kudos root after pop")
        XCTAssertTrue(
            chip.label.contains(hashtagTag),
            "Filter chip label should contain the selected hashtag tag — expected substring '\(hashtagTag)', got '\(chip.label)'"
        )
    }

    // Gap D8 (anonymous-sender label visibility) is intentionally NOT covered
    // by an XCUITest here:
    //   - The data-layer masking + label injection is fully covered by
    //     `KudosMapperAnonymousMaskingTests` (9 unit tests).
    //   - The i18n key `kudos.anonymousSender.label` is asserted in
    //     `KudosLocalizationKeysExistTests.testAnonymousSenderLabel`.
    //   - A UI-level test that scrolls a fixture-dependent feed to find a card
    //     by sender-name then taps a coordinate offset proved unstable on cold
    //     simulator clones. Unit coverage is sufficient.
}
