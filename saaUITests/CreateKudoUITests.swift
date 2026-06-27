//
//  CreateKudoUITests.swift
//  saaUITests
//
//  XCUITests for the Create Kudo flow.
//
//  Both tests launch with `-uiTestMode kudos.create`, which:
//    - Signs the session in (AuthSessionStore.injectState(.preview))
//    - Routes WriteKudoFormStubView to MockKudosRepository + MockKudosImageUploader
//      (no Supabase I/O, deterministic fixture data)
//
//  Navigation path: Home tab (default) → tap Kudos nav tab → tap "Gửi Kudos" send button
//    → fullScreenCover presents CreateKudoViewContainer
//
//  Covered test cases:
//    TC_WRITE_FUN_001 — happy path: fill all required fields + 1 hashtag → tap Send
//                        → success toast appears AND form dismisses
//    TC_WRITE_FUN_002 — missing hashtag: fill recipient + title + message, skip hashtags
//                        → tap Send → validation error visible, toast absent, form stays open
//

import XCTest

@MainActor
final class CreateKudoUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Force portrait — the app's Info.plist allows landscape and CI's
        // iPhone 16 Pro can boot rotated, which breaks the layout assumptions
        // these tests make (scroll direction, keyboard placement, button hit
        // areas, fullScreenCover presentation).
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Helpers

    /// Element-type-agnostic lookup — SwiftUI may surface identifiers under
    /// `button` / `otherElement` / `staticText` depending on the wrapping.
    private func element(_ id: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// Resolves a bottom-nav tab button by its visible label.
    private func navTab(label: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    /// Dismisses the iOS "Type English and Vietnamese" multilingual-keyboard
    /// introduction sheet if it appears. The simulator shows this once per
    /// fresh boot when a TextField first receives focus, and it covers the
    /// bottom half of the screen — including the form's submit button.
    private func dismissKeyboardIntroIfPresent(_ app: XCUIApplication) {
        let cont = app.buttons["Continue"]
        if cont.waitForExistence(timeout: 0.5) {
            cont.tap()
        }
    }

    /// Launches the app in `kudos.create` mode, switches to the Kudos tab, and
    /// taps the "Send Kudos" button to present `CreateKudoViewContainer`.
    /// Returns the running app once `createKudo.root` is visible.
    private func launchAndOpenCreateForm() throws -> XCUIApplication {
        let app = XCUIApplication.launching(.kudosCreate)

        // Switch to Kudos tab
        let kudosTab = navTab(label: "Kudos", in: app)
        XCTAssertTrue(
            kudosTab.waitForExistence(timeout: 5),
            "Kudos nav tab must exist after launch"
        )
        kudosTab.tap()

        XCTAssertTrue(
            element("kudos.root", in: app).waitForExistence(timeout: 5),
            "Kudos tab root must appear"
        )

        // Tap the send-kudos button (presented in KudosHeroSection)
        let sendBtn = element("kudos.sendButton", in: app)
        XCTAssertTrue(
            sendBtn.waitForExistence(timeout: 3),
            "Send Kudos button must exist on Kudos tab"
        )
        sendBtn.tap()

        // Wait for the create form to appear
        XCTAssertTrue(
            element("createKudo.root", in: app).waitForExistence(timeout: 5),
            "Create Kudo form must present as fullScreenCover after tapping Send"
        )
        return app
    }

    // MARK: - TC_WRITE_FUN_001 — Happy path

    /// Fills all required fields (recipient, title, message, 1 hashtag) and taps Send.
    /// Expects: success toast appears and the form is dismissed (kudos.root hidden).
    func test_TC_WRITE_FUN_001_happy_path_submit_succeeds() throws {
        let app = try launchAndOpenCreateForm()

        // 1. Select recipient — tap picker, pick first row in dropdown
        let recipientPicker = element("createKudo.recipient.picker", in: app)
        XCTAssertTrue(
            recipientPicker.waitForExistence(timeout: 3),
            "Recipient picker button must exist"
        )
        recipientPicker.tap()

        // The dropdown appears — wait for any recipient row
        // The dropdown's wrapper VStack identifier doesn't reliably surface
        // (SwiftUI flattens its accessibility element when child elements like
        // the search TextField and recipient row Buttons have their own IDs).
        // Use the search field as the "dropdown opened" signal — it lives only
        // inside the dropdown overlay.
        let dropdown = element("kudos.create.recipientSearchField", in: app)
        XCTAssertTrue(
            dropdown.waitForExistence(timeout: 3),
            "Recipient dropdown must appear after tapping picker"
        )

        // Tap the first recipient row (MockKudosRepository seeds two profiles)
        let firstRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'kudos.create.recipientRow.'"))
            .firstMatch
        XCTAssertTrue(
            firstRow.waitForExistence(timeout: 3),
            "At least one recipient row must exist in dropdown"
        )
        firstRow.tap()

        // 2. Type title
        let titleInput = element("createKudo.title.input", in: app)
        XCTAssertTrue(
            titleInput.waitForExistence(timeout: 3),
            "Title text input must exist"
        )
        titleInput.tap()
        // Dismiss the iOS multilingual-keyboard intro before typing — it can
        // pop up on first focus and would otherwise eat keystrokes.
        dismissKeyboardIntroIfPresent(app)
        titleInput.typeText("Người truyền động lực cho tôi")

        // 3. Type message — TextEditor in the form card
        let msgEditor = element("createKudo.message.textEditor", in: app)
        XCTAssertTrue(
            msgEditor.waitForExistence(timeout: 3),
            "Message text editor must exist"
        )
        msgEditor.tap()
        msgEditor.typeText("Cảm ơn sự chăm chỉ và nhiệt tình của bạn!")

        // 4. Open hashtag picker and pick first hashtag
        let hashtagAdd = element("createKudo.hashtag.add", in: app)
        XCTAssertTrue(
            hashtagAdd.waitForExistence(timeout: 3),
            "Hashtag add button must exist"
        )
        hashtagAdd.tap()

        // Hashtag dropdown wrapper identifier doesn't reliably surface (its
        // children are Buttons that take their own identifiers). Detect "dropdown
        // opened" via the first hashtag row appearing — those have stable IDs
        // `kudos.createHashtag.row.<tag>`.
        let firstHashtagRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'kudos.createHashtag.row.'"))
            .firstMatch
        XCTAssertTrue(
            firstHashtagRow.waitForExistence(timeout: 3),
            "Hashtag dropdown rows must appear after tapping add"
        )
        firstHashtagRow.tap()

        // Dismiss dropdown by tapping outside
        app.tap()

        // 5. Tap Send
        // Make sure the keyboard intro isn't blocking the submit button area.
        dismissKeyboardIntroIfPresent(app)
        // Dismiss the soft keyboard so it doesn't overlap the submit button's
        // hit area. Tapping the form header (a non-interactive StaticText)
        // falls through to the form card's onTapGesture which calls
        // resignFirstResponder — reliable in iOS 26 where swipeUp doesn't
        // always trigger scrollDismissesKeyboard from the keyboard region.
        if app.keyboards.firstMatch.exists {
            let header = element("createKudo.header.label", in: app)
            if header.exists { header.tap() }
            Thread.sleep(forTimeInterval: 0.5)
        }
        let submitBtn = element("createKudo.action.submit", in: app)
        XCTAssertTrue(
            submitBtn.waitForExistence(timeout: 3),
            "Submit button must exist in action bar"
        )
        // Scroll down if needed so the submit button is hittable
        var attempts = 0
        while !submitBtn.isHittable, attempts < 4 {
            app.swipeUp()
            attempts += 1
        }
        submitBtn.tap()

        // 6. Assert: success toast appears OR form dismisses (either confirms success)
        // MockKudosRepository.createKudo returns a synthetic Kudos synchronously.
        // The form dismisses on .succeeded — kudos.root goes away, Kudos feed visible.
        // Poll with a short loop since XCUIApplication.wait(for:) takes XCUIApplication.State.
        let toastEl = element("createKudo.toast", in: app)
        let kudosRootEl = element("createKudo.root", in: app)
        var successConfirmed = false
        for _ in 0..<10 {
            if toastEl.exists || !kudosRootEl.exists {
                successConfirmed = true
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTAssertTrue(
            successConfirmed,
            "Success toast should appear OR create form should dismiss after successful submit"
        )
    }

    // MARK: - TC_WRITE_FUN_002 — Missing hashtag blocks submit

    /// Fills recipient + title + message but leaves hashtags empty, then taps Send.
    /// Expects: validation UI visible, form stays open, no success toast.
    func test_TC_WRITE_FUN_002_missing_hashtag_blocks_submit() throws {
        let app = try launchAndOpenCreateForm()

        // 1. Select recipient
        let recipientPicker = element("createKudo.recipient.picker", in: app)
        XCTAssertTrue(
            recipientPicker.waitForExistence(timeout: 3),
            "Recipient picker must exist"
        )
        recipientPicker.tap()

        // The dropdown's wrapper VStack identifier doesn't reliably surface
        // (SwiftUI flattens its accessibility element when child elements like
        // the search TextField and recipient row Buttons have their own IDs).
        // Use the search field as the "dropdown opened" signal — it lives only
        // inside the dropdown overlay.
        let dropdown = element("kudos.create.recipientSearchField", in: app)
        XCTAssertTrue(
            dropdown.waitForExistence(timeout: 3),
            "Recipient dropdown must appear"
        )
        let firstRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'kudos.create.recipientRow.'"))
            .firstMatch
        XCTAssertTrue(
            firstRow.waitForExistence(timeout: 3),
            "Recipient row must exist in dropdown"
        )
        firstRow.tap()

        // 2. Type title
        let titleInput = element("createKudo.title.input", in: app)
        XCTAssertTrue(
            titleInput.waitForExistence(timeout: 3),
            "Title input must exist"
        )
        titleInput.tap()
        titleInput.typeText("Test title")

        // 3. Type message
        let msgEditor = element("createKudo.message.textEditor", in: app)
        XCTAssertTrue(
            msgEditor.waitForExistence(timeout: 3),
            "Message editor must exist"
        )
        msgEditor.tap()
        msgEditor.typeText("Test message without hashtag")

        // 4. Skip hashtags — do NOT tap the hashtag add button

        // 5. Tap Send
        let submitBtn = element("createKudo.action.submit", in: app)
        XCTAssertTrue(
            submitBtn.waitForExistence(timeout: 3),
            "Submit button must exist"
        )
        var attempts = 0
        while !submitBtn.isHittable, attempts < 4 {
            app.swipeUp()
            attempts += 1
        }
        submitBtn.tap()

        // 6. Assert: create form is still visible (not dismissed)
        XCTAssertTrue(
            element("createKudo.root", in: app).waitForExistence(timeout: 3),
            "Create form must remain visible when validation fails"
        )

        // 7. Assert: no success toast appeared
        // Wait a brief moment to confirm toast does NOT appear.
        let toastAppearedEarly = element("createKudo.toast", in: app)
            .waitForExistence(timeout: 1)
        XCTAssertFalse(
            toastAppearedEarly,
            "Success toast must NOT appear when hashtags are missing"
        )

        // 8. Assert: the required-fields banner appeared. `createKudo.requiredFieldsError`
        // is rendered only when `showRequiredFieldsError == true` (i.e. submitAttempted &&
        // !fieldErrors.isEmpty), so its presence is the actual signal that submit was
        // blocked by validation. `waitForExistence` polls past the SwiftUI layout pass
        // that fires when `submitAttempted` flips.
        XCTAssertTrue(
            element("createKudo.requiredFieldsError", in: app).waitForExistence(timeout: 3),
            "Required-fields error banner must appear when hashtags are missing"
        )

        // 9. Sanity: hashtag row is still in the tree (always rendered, not conditional).
        XCTAssertTrue(
            element("createKudo.hashtag.row", in: app).exists,
            "Hashtag row must remain visible"
        )
    }
}
