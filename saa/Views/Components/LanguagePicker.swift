//
//  LanguagePicker.swift
//  saa
//
//  Created by nguyen.duc.huyb on 10/6/26.
//

import SwiftUI

/// Compact language selector displayed in the Login screen top bar.
/// Renders a flag image + language label as a tappable menu.
struct LanguagePicker: View {

    @Binding var selectedLanguage: AppLanguage

    let onLanguageChange: (AppLanguage) -> Void

    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                Button {
                    selectedLanguage = language
                    onLanguageChange(language)
                } label: {
                    Label {
                        Text(verbatim: language.label)
                    } icon: {
                        flagImage(for: language)
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                flagImage(for: selectedLanguage)
                    .frame(width: 20, height: 14)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                Text(verbatim: selectedLanguage.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.languagePickerLabel)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.languagePickerChevron)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.languagePickerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Private helpers

    @ViewBuilder
    private func flagImage(for language: AppLanguage) -> some View {
        let assetName = language.flagAsset
        if UIImage(named: assetName) != nil {
            Image(assetName)
                .resizable()
                .scaledToFill()
        } else {
            // TODO: Replace with real flag image assets once flag images are
            // extracted from Figma / added to Assets.xcassets by Phase 05 agent.
            Image(systemName: "flag.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Color extensions (semantic tokens)

private extension Color {
    static let languagePickerLabel = Color(UIColor.label)
    static let languagePickerChevron = Color(UIColor.secondaryLabel)
    static let languagePickerBackground = Color(UIColor.secondarySystemBackground)
}

// MARK: - Preview

#Preview {
    @Previewable @State var lang: AppLanguage = .vi
    LanguagePicker(selectedLanguage: $lang) { _ in }
        .padding()
}
