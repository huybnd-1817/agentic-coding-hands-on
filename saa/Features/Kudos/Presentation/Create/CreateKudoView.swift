import SwiftUI

// MARK: - CreateKudoView
// Root screen for the Create Kudo flow.
// Presented as .fullScreenCover from existing entry points.
//
// Figma refs:
//   Default state:           7fFAb-K35a  (6885:9271)
//   Filled + anonymous state: PV7jBVZU1N (6885:9883)
//
// Layout (bottom → top):
//   1. Full-bleed background key-visual (mm_media_bg) — same #00101A + image pattern as KudosView
//   2. Fixed top navigation bar (back arrow + "New Kudo" title)
//   3. Scrollable form card (cream #FFF8E1, cornerRadius 10.723pt, padding 18/12pt)
//   4. Sticky action bar (Huỷ / Gửi đi) pinned below the card
//
// All inputs arrive as plain values; all mutations fire typed callbacks.
// No ViewModel or Supabase calls — wired by CreateKudoViewModel in phase-06.

@MainActor
struct CreateKudoView: View {

    // MARK: - Inputs (from VM)

    let recipient: ProfileSummary?
    let title: String
    let message: String
    let hashtags: [Hashtag]
    let images: [ImageDraft]
    let isAnonymous: Bool
    let anonymousNickname: String
    let isSubmitting: Bool
    let errors: [FieldError]
    let showRequiredFieldsError: Bool

    // MARK: - Callbacks (to VM)

    let onOpenRecipientPicker: () -> Void
    let onTitleChange: (String) -> Void
    let onMessageChange: (String) -> Void
    let onApplyMarkdown: (MarkdownMarker) -> Void
    let onOpenHashtagPicker: () -> Void
    let onRemoveHashtag: (Hashtag) -> Void
    let onAddImage: () -> Void
    let onRemoveImage: (ImageDraft.ID) -> Void
    let onToggleAnonymous: () -> Void
    let onNicknameChange: (String) -> Void
    let onTapStandards: () -> Void
    let onCancel: () -> Void
    let onSubmit: () -> Void

    // MARK: - Local binding bridge for TextEditor / TextField

    @State private var titleBinding: String
    @State private var messageBinding: String
    @State private var nicknameBinding: String

    // MARK: - Init

    init(
        recipient: ProfileSummary? = nil,
        title: String = "",
        message: String = "",
        hashtags: [Hashtag] = [],
        images: [ImageDraft] = [],
        isAnonymous: Bool = false,
        anonymousNickname: String = "",
        isSubmitting: Bool = false,
        errors: [FieldError] = [],
        showRequiredFieldsError: Bool = false,
        onOpenRecipientPicker: @escaping () -> Void = {},
        onTitleChange: @escaping (String) -> Void = { _ in },
        onMessageChange: @escaping (String) -> Void = { _ in },
        onApplyMarkdown: @escaping (MarkdownMarker) -> Void = { _ in },
        onOpenHashtagPicker: @escaping () -> Void = {},
        onRemoveHashtag: @escaping (Hashtag) -> Void = { _ in },
        onAddImage: @escaping () -> Void = {},
        onRemoveImage: @escaping (ImageDraft.ID) -> Void = { _ in },
        onToggleAnonymous: @escaping () -> Void = {},
        onNicknameChange: @escaping (String) -> Void = { _ in },
        onTapStandards: @escaping () -> Void = {},
        onCancel: @escaping () -> Void = {},
        onSubmit: @escaping () -> Void = {}
    ) {
        self.recipient = recipient
        self.title = title
        self.message = message
        self.hashtags = hashtags
        self.images = images
        self.isAnonymous = isAnonymous
        self.anonymousNickname = anonymousNickname
        self.isSubmitting = isSubmitting
        self.errors = errors
        self.showRequiredFieldsError = showRequiredFieldsError
        self.onOpenRecipientPicker = onOpenRecipientPicker
        self.onTitleChange = onTitleChange
        self.onMessageChange = onMessageChange
        self.onApplyMarkdown = onApplyMarkdown
        self.onOpenHashtagPicker = onOpenHashtagPicker
        self.onRemoveHashtag = onRemoveHashtag
        self.onAddImage = onAddImage
        self.onRemoveImage = onRemoveImage
        self.onToggleAnonymous = onToggleAnonymous
        self.onNicknameChange = onNicknameChange
        self.onTapStandards = onTapStandards
        self.onCancel = onCancel
        self.onSubmit = onSubmit
        _titleBinding = State(initialValue: title)
        _messageBinding = State(initialValue: message)
        _nicknameBinding = State(initialValue: anonymousNickname)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            screenBackground

            VStack(spacing: 0) {
                navigationBar
                scrollContent
            }
        }
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        // Sync external props → local bindings (VM updates state on submit reset).
        // Use two-argument onChange for iOS 16 compatibility (deployment target 16.0).
        .onChange(of: title) { newVal in
            if titleBinding != newVal { titleBinding = newVal }
        }
        .onChange(of: message) { newVal in
            if messageBinding != newVal { messageBinding = newVal }
        }
        .onChange(of: messageBinding) { newVal in
            onMessageChange(newVal)
        }
        .onChange(of: anonymousNickname) { newVal in
            if nicknameBinding != newVal { nicknameBinding = newVal }
        }
    }

    // MARK: - Screen background
    // Reuses the same navy + key-visual pattern as KudosView (mm_media_bg).

    private var screenBackground: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = w * 812.0 / 375.0
            ZStack(alignment: .top) {
                Color(red: 0, green: 16/255, blue: 26/255)
                if UIImage(named: "kudos-hero-bg-group") != nil {
                    Image("kudos-hero-bg-group")
                        .resizable()
                        .scaledToFill()
                        .frame(width: w, height: h, alignment: .top)
                        .clipped()
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
        .ignoresSafeArea()
    }

    // MARK: - Navigation bar
    // Figma 6885:9888: transparent header, back arrow left (mm_media_back 24x24), "New Kudo" centred
    // No background — sits on top of the key-visual.

    private var navigationBar: some View {
        ZStack {
            Color.clear
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                // Status bar spacer
                Color.clear.frame(height: 47)

                // Nav content row (height 42pt)
                HStack(spacing: 0) {
                    // Back button (Figma 6885:9892 mm_media_back, 24x24).
                    // Use Button instead of Image+onTapGesture so the accessibility
                    // identifier reliably surfaces for XCUITest queries (an Image
                    // with a tap gesture is not a discoverable accessibility element).
                    Button(action: onCancel) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 24)
                            .frame(width: 42, height: 42)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 7)
                    .accessibilityIdentifier("createKudo.nav.back")

                    Spacer()

                    // Title (centred)
                    Text("New Kudo")
                        .font(.custom("Helvetica Neue", size: 17).weight(.medium))
                        .foregroundColor(.white)
                        .tracking(0.5)

                    Spacer()

                    // Mirror spacer for title centering (matches back-button hit area)
                    Color.clear.frame(width: 42, height: 42)
                        .padding(.trailing, 7)
                }
                .frame(height: 42)
            }
        }
        .frame(height: 89)
    }

    // MARK: - Scrollable form content

    private var scrollContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                formCard
                CreateKudoActionBar(
                    isSubmitting: isSubmitting,
                    onCancel: onCancel,
                    onSubmit: onSubmit
                )
                .padding(.horizontal, 20)
            }
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
        // Drag the scroll content downward to dismiss the keyboard.
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Form card
    // Figma 6885:9291: cream #FFF8E1, cornerRadius 10.723pt, padding 18/12pt, gap 16pt

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            CreateKudoHeaderLabel()

            CreateKudoRecipientField(
                recipient: recipient,
                hasError: hasError(for: .recipient),
                onOpenPicker: onOpenRecipientPicker
            )

            CreateKudoTitleField(
                title: $titleBinding,
                hasError: hasError(for: .title),
                onTitleChange: onTitleChange
            )

            CreateKudoStandardsLink(onTapStandards: onTapStandards)

            CreateKudoMessageEditor(
                message: $messageBinding,
                hasError: hasError(for: .message),
                onApplyMarkdown: onApplyMarkdown,
                onTapStandards: onTapStandards
            )

            CreateKudoHashtagField(
                hashtags: hashtags,
                hasError: hasError(for: .hashtag),
                onOpenPicker: onOpenHashtagPicker,
                onRemove: onRemoveHashtag
            )

            CreateKudoImageField(
                images: images,
                onAddImage: onAddImage,
                onRemoveImage: onRemoveImage
            )

            CreateKudoAnonymousToggle(
                isAnonymous: isAnonymous,
                nickname: $nicknameBinding,
                nicknameHasError: hasError(for: .nickname),
                onToggle: onToggleAnonymous,
                onNicknameChange: onNicknameChange
            )

            // Figma node 6885:10124 — inline red banner shown when the user
            // taps Send while required fields are missing.
            if showRequiredFieldsError {
                Text(LocalizedStringKey("kudos.create.error.requiredFields"))
                    .font(.custom("Montserrat-Regular", size: 12))
                    .foregroundColor(Color(red: 212.0 / 255, green: 39.0 / 255, blue: 29.0 / 255))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("createKudo.requiredFieldsError")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 18)
        .background(Color.createKudoCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10.723))
        .padding(.horizontal, 20)
        // Tap empty area inside the form card to dismiss the keyboard.
        // Scoped to the card (not the root) so the action bar's Send/Cancel
        // buttons are outside this gesture and receive their taps directly.
        .onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil,
                from: nil,
                for: nil
            )
        }
    }

    // MARK: - Helpers

    private func hasError(for field: FieldError.Field) -> Bool {
        errors.contains { $0.field == field }
    }
}

// MARK: - Preview

#if DEBUG
private struct CreateKudoViewPreviewHost: View {
    // Default (empty) state
    var body: some View {
        CreateKudoView()
    }
}

private struct CreateKudoViewFilledPreviewHost: View {
    // Filled + anonymous state (mirrors PV7jBVZU1N)
    var body: some View {
        CreateKudoView(
            recipient: ProfileSummary(
                id: UUID(),
                displayName: "Dương Huỳnh Xuân Nhật",
                employeeCode: "CECV10",
                avatarURL: nil,
                department: nil
            ),
            title: "Người truyền động lực cho tôi",
            message: "Cảm ơn người em bình thường nhưng phi thường :D Cảm ơn sự chăm chỉ, cần mẫn của em đã tạo động lực rất lớn cho mọi người trong team.",
            hashtags: [
                Hashtag(id: UUID(), tag: "#Dedicated"),
                Hashtag(id: UUID(), tag: "#Inspiring"),
                Hashtag(id: UUID(), tag: "#Teamwork")
            ],
            images: [],
            isAnonymous: true,
            anonymousNickname: "Doraemon",
            isSubmitting: false,
            errors: []
        )
    }
}

#Preview("Default (empty)") {
    CreateKudoViewPreviewHost()
        .preferredColorScheme(.dark)
}

#Preview("Filled + anonymous") {
    CreateKudoViewFilledPreviewHost()
        .preferredColorScheme(.dark)
}
#endif
