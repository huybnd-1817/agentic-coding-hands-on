//
//  LanguagePicker.swift
//  saa
//
//  Created by nguyen.duc.huyb on 10/6/26.
//

import SwiftUI

/// Compact language selector for the Login top bar. Tapping the chip toggles
/// a custom inline dropdown panel matching MoMorph design uUvW6Qm1ve —
/// dark container with a gold border, selected row highlighted in 20%
/// translucent brand-yellow. The native `Menu` popover is not used because
/// its system-themed surface doesn't match the design language.
struct LanguagePicker: View {

    @Binding var selectedLanguage: AppLanguage

    let onLanguageChange: (AppLanguage) -> Void

    @State private var isExpanded = false

    var body: some View {
        // `.overlay` keeps the picker's layout frame fixed at chip size
        // (~75×32) in both states, so the parent header HStack does NOT
        // grow taller when the dropdown opens — the Home ScrollView no
        // longer gets pushed down (and the Login Spacer absorbs nothing).
        //
        // The dropdown is positioned via `.offset(y: 40)` so it renders
        // ~8pt below the chip without affecting layout. For row taps to
        // resolve against the dropdown (not the sibling Home ScrollView
        // it overlaps), the picker's nearest VStack-sibling-bearing
        // ancestor — `HomeHeaderView` — applies `.zIndex(1)`.
        chipButton
            .overlay(alignment: .topTrailing) {
                if isExpanded {
                    dropdownPanel
                        .offset(y: 40)
                        .transition(.opacity)
                }
            }
    }

    // MARK: - Chip (collapsed state)

    private var chipButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                flagIcon(for: selectedLanguage)

                Text(verbatim: selectedLanguage.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .rotationEffect(isExpanded ? .degrees(180) : .zero)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dropdown panel (expanded state)

    private var dropdownPanel: some View {
        VStack(spacing: 0) {
            ForEach(AppLanguage.allCases) { language in
                dropdownRow(for: language)
            }
        }
        .padding(6)
        .background(Color.dropdownBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.dropdownBorder, lineWidth: 1)
        )
        // Soft drop shadow lifts the #00070C panel off the near-identical
        // dark page background so it reads as opaque rather than blending in.
        .shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 6)
        .fixedSize()
        .zIndex(10)
    }

    private func dropdownRow(for language: AppLanguage) -> some View {
        let isSelected = language == selectedLanguage
        return Button {
            selectedLanguage = language
            onLanguageChange(language)
            withAnimation(.easeInOut(duration: 0.18)) {
                isExpanded = false
            }
        } label: {
            HStack(spacing: 4) {
                flagIcon(for: language)

                Text(verbatim: language.label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(width: 96, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .background(isSelected ? Color.dropdownRowSelected : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("languagePicker.row.\(language.rawValue)")
    }

    // MARK: - Private helpers

    private func flagIcon(for language: AppLanguage) -> some View {
        CountryFlag(language: language)
    }
}

// MARK: - Color tokens

private extension Color {
    /// Figma `Details-Container-2` — #00070C.
    static let dropdownBackground  = Color(red: 0.0, green: 7.0/255, blue: 12.0/255)
    /// Figma `Details-Border` — #998C5F.
    static let dropdownBorder      = Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255)
    /// 20% of the brand-yellow button fill #FFEA9E — selected-row highlight.
    static let dropdownRowSelected = Color(red: 1.0, green: 234.0/255, blue: 158.0/255).opacity(0.2)
}

// MARK: - Preview

private struct LanguagePickerPreviewHost: View {
    @State var lang: AppLanguage = .vi

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
            LanguagePicker(selectedLanguage: $lang) { _ in }
                .padding()
        }
    }
}

#Preview {
    LanguagePickerPreviewHost()
}
