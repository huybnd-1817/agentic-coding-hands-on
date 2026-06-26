import SwiftUI

// MARK: - CreateKudoAnonymousToggle
// Figma node 6885:9363 — G row: checkbox 24×24pt + "Gửi lời cám ơn và ghi nhận ẩn danh"
// Figma node 6885:9997 (PV7jBVZU1N) — B.7/B.8 "Nickname ẩn danh *" row (conditional)
// Unchecked: white fill, #998C5F stroke 1pt
// Checked: inner 16×16pt #998C5F fill square (cornerRadius 2pt)

struct CreateKudoAnonymousToggle: View {

    // MARK: - Inputs

    let isAnonymous: Bool
    @Binding var nickname: String
    let nicknameHasError: Bool
    let onToggle: () -> Void
    let onNicknameChange: (String) -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            anonymousRow
            if isAnonymous {
                nicknameRow
            }
        }
        .accessibilityIdentifier("createKudo.anonymous.section")
    }

    // MARK: - G row — checkbox + label

    private var anonymousRow: some View {
        HStack(spacing: 8) {
            checkboxView
            Text("Gửi lời cám ơn và ghi nhận ẩn danh")
                .font(.custom("Montserrat-Regular", size: 12))
                .foregroundColor(Color.createKudoPlaceholder)
                .lineLimit(1)
        }
        .frame(height: 24)
        .contentShape(Rectangle())
        .onTapGesture { onToggle() }
        .accessibilityIdentifier("createKudo.anonymous.toggle")
    }

    // MARK: - Checkbox (Figma 6885:9364 unchecked / 6885:9994+9995 checked)

    private var checkboxView: some View {
        ZStack {
            // Outer square: white fill, #998C5F stroke 1pt
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.createKudoFieldBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.createKudoBorder, lineWidth: 1)
                )
                .frame(width: 24, height: 24)

            // Inner check indicator (Figma 6885:9995 — 16×16pt, #998C5F fill, cornerRadius 2pt)
            if isAnonymous {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.createKudoChecked)
                    .frame(width: 16, height: 16)
            }
        }
        .frame(width: 24, height: 24)
    }

    // MARK: - B.7/B.8 — "Nickname ẩn danh *" label + text input
    // Figma PV7jBVZU1N node 6885:9997: same HStack pattern as recipient/title rows
    // Label "Nickname ẩn danh *" (82pt wide), input field right (210.106pt)
    // Max 30 chars per clarifications

    private var nicknameRow: some View {
        HStack(spacing: 8) {
            nicknameLabel
            nicknameField
        }
        .frame(height: 40)
        .accessibilityIdentifier("createKudo.nickname.row")
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    private var nicknameLabel: some View {
        HStack(spacing: 1) {
            Text("Nickname ẩn danh")
                .font(.custom("Montserrat-Medium", size: 14))
                .foregroundColor(Color.createKudoText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text("*")
                .font(.custom("NotoSansJP-Bold", size: 14))
                .foregroundColor(Color.createKudoRequired)
        }
        .frame(width: 91, alignment: .leading)
    }

    private var nicknameField: some View {
        TextField("Doraemon", text: $nickname)
            .font(.custom("Montserrat-Regular", size: 12))
            .foregroundColor(Color.createKudoText)
            .tint(Color.createKudoText)
            .onChange(of: nickname) { newValue in
                // Enforce max 30 chars (per clarifications). iOS 16 two-argument form.
                if newValue.count > 30 {
                    nickname = String(newValue.prefix(30))
                }
                onNicknameChange(nickname)
            }
            .padding(.horizontal, 10.723)
            .padding(.vertical, 7.149)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(Color.createKudoFieldBg)
            .overlay(
                RoundedRectangle(cornerRadius: 3.574)
                    .stroke(nicknameHasError ? Color.createKudoRequired : Color.createKudoBorder, lineWidth: 0.447)
            )
            .clipShape(RoundedRectangle(cornerRadius: 3.574))
            .accessibilityIdentifier("createKudo.nickname.input")
    }
}

// MARK: - Preview

#if DEBUG
private struct AnonymousTogglePreviewHost: View {
    @State private var isAnonymous = false
    @State private var nickname = ""

    var body: some View {
        VStack(spacing: 24) {
            CreateKudoAnonymousToggle(
                isAnonymous: isAnonymous,
                nickname: $nickname,
                nicknameHasError: false,
                onToggle: { isAnonymous.toggle() },
                onNicknameChange: { _ in }
            )

            Divider()

            CreateKudoAnonymousToggle(
                isAnonymous: true,
                nickname: .constant("Doraemon"),
                nicknameHasError: false,
                onToggle: {},
                onNicknameChange: { _ in }
            )

            CreateKudoAnonymousToggle(
                isAnonymous: true,
                nickname: .constant(""),
                nicknameHasError: true,
                onToggle: {},
                onNicknameChange: { _ in }
            )
        }
        .padding()
        .background(Color.createKudoCardBg)
        .animation(.easeInOut(duration: 0.2), value: isAnonymous)
    }
}

#Preview {
    AnonymousTogglePreviewHost()
}
#endif
