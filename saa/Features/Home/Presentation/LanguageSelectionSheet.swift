//
//  LanguageSelectionSheet.swift
//  saa
//
//  Created by nguyen.duc.huyb on 15/6/26.
//

import SwiftUI

/// Sheet content for the language-selection modal triggered from the Home
/// header. Wraps the existing `LanguagePicker` component inside a
/// `NavigationStack` so the title bar and dismiss button render correctly.
///
/// `@SwiftUI.Environment(\.dismiss)` is qualified to avoid the name collision
/// with the project-local `enum Environment` in `Core/Configuration`.
///
/// Callers present this via `.sheet(isPresented:)`:
/// ```swift
/// .sheet(isPresented: $showLanguageSheet) {
///     LanguageSelectionSheet(
///         selectedLanguage: $preference.current,
///         onLanguageChange: { preference.current = $0 }
///     )
/// }
/// ```
struct LanguageSelectionSheet: View {

    // MARK: - Inputs

    @Binding var selectedLanguage: AppLanguage

    let onLanguageChange: (AppLanguage) -> Void

    // MARK: - Environment

    // Qualified to disambiguate from the project-local `enum Environment`.
    @SwiftUI.Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color.sheetBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    LanguagePicker(
                        selectedLanguage: $selectedLanguage,
                        onLanguageChange: { language in
                            onLanguageChange(language)
                            dismiss()
                        }
                    )

                    Spacer()
                }
                .padding(.top, 24)
                .padding(.horizontal, 20)
            }
            .navigationTitle(String(localized: "home.language.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .accessibilityIdentifier("home.language.dismiss")
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}

// MARK: - Color tokens

private extension Color {
    /// Matches home screen backdrop — #00100A.
    static let sheetBackground = Color(red: 0.0, green: 16.0/255, blue: 26.0/255)
}

// MARK: - Preview

#if DEBUG
private struct LanguageSelectionSheetPreviewHost: View {
    @State private var language: AppLanguage = .vi
    @State private var isPresented = true

    var body: some View {
        ZStack {
            Color(red: 0, green: 16.0/255, blue: 26.0/255).ignoresSafeArea()
            Button("Open Sheet") { isPresented = true }
                .foregroundColor(.white)
        }
        .sheet(isPresented: $isPresented) {
            LanguageSelectionSheet(
                selectedLanguage: $language,
                onLanguageChange: { language = $0 }
            )
        }
    }
}

#Preview {
    LanguageSelectionSheetPreviewHost()
}
#endif
