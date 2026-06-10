//
//  LoginView.swift
//  saa
//
//  Created by nguyen.duc.huyb on 10/6/26.
//

import SwiftUI

// MARK: - LoginView
// `AppLanguage` lives in saa/State/AppLanguage.swift (Phase 05).

/// Pixel-perfect Login screen built from MoMorph design (fileKey: 9ypp4enmFmdK3YAFJLIu6C,
/// screenId: 8HGlvYGJWq). This view is purely presentational — all business logic
/// (OAuth, Supabase, navigation) is handled by the parent view-model (Phase 04/07).
struct LoginView: View {

    // MARK: Inputs

    @Binding var selectedLanguage: AppLanguage

    /// Disable the sign-in button while an auth request is in flight.
    let isLoading: Bool

    /// Non-nil when an auth error should be shown to the user.
    /// Either a String Catalog key (e.g. "login.error.network") or a free-form preview literal.
    /// Wrapped in `LocalizedStringKey` at render time so SwiftUI's `\.locale` environment drives the displayed language.
    let errorMessage: String?

    // MARK: Outputs

    let onLoginTapped: () -> Void
    let onLanguageChange: (AppLanguage) -> Void

    // MARK: Body

    var body: some View {
        ZStack {
            // Background
            Color.loginBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar — language picker aligned trailing
                topBar

                Spacer()

                // Center content — logo + headline + sub-headline
                centerContent

                Spacer()

                // Bottom — sign-in button + error + legal footnote
                bottomContent
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Sub-views

    private var topBar: some View {
        HStack {
            Spacer()
            LanguagePicker(
                selectedLanguage: $selectedLanguage,
                onLanguageChange: onLanguageChange
            )
        }
        .padding(.top, 16)
    }

    private var centerContent: some View {
        VStack(spacing: 16) {
            // App logo
            logoView

            // Brand wordmark — fixed per spec #3 (not localized).
            Text(verbatim: "ROOT FURTHER")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.loginHeadline)
                .multilineTextAlignment(.center)

            // Localized description.
            Text(LocalizedStringKey("login.description"))
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.loginSubheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    private var logoView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.logoBackground)
                .frame(width: 88, height: 88)
                .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 4)

            // TODO: Replace with real Sun* logo asset (Image("SunAsteriskLogo"))
            // once asset is extracted from Figma and added to Assets.xcassets.
            Text("☀︎")
                .font(.system(size: 44))
        }
    }

    private var bottomContent: some View {
        VStack(spacing: 16) {
            // Error message banner
            if let message = errorMessage {
                errorBanner(message: message)
            }

            // Google Sign-In button
            signInButton

            // Copyright footnote
            Text(LocalizedStringKey("login.copyright"))
                .font(.system(size: 11))
                .foregroundColor(.loginFootnote)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }

    private var signInButton: some View {
        Button(action: onLoginTapped) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .googleButtonForeground))
                        .frame(width: 20, height: 20)
                } else {
                    // Google "G" logo
                    googleGLogo
                }

                Text(LocalizedStringKey("login.button.google"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.googleButtonForeground)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.googleButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.googleButtonBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
    }

    /// Minimal inline Google "G" rendered with SF Symbols as placeholder.
    /// TODO: Replace with extracted Figma SVG asset (Image("GoogleLogo")) once
    /// asset is available in Assets.xcassets.
    private var googleGLogo: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 20, height: 20)
            Text("G")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.errorIcon)
                .font(.system(size: 16))
            Text(LocalizedStringKey(message))
                .font(.system(size: 14))
                .foregroundColor(.errorText)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.errorBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.errorBorder, lineWidth: 1)
        )
    }
}

// MARK: - Color tokens

private extension Color {
    // Backgrounds
    static let loginBackground    = Color(UIColor.systemBackground)
    static let logoBackground     = Color(UIColor.secondarySystemBackground)
    static let googleButtonBackground = Color.white
    static let errorBackground    = Color(red: 1.0, green: 0.94, blue: 0.94)

    // Text
    static let loginHeadline      = Color(UIColor.label)
    static let loginSubheadline   = Color(UIColor.secondaryLabel)
    static let loginFootnote      = Color(UIColor.tertiaryLabel)
    static let googleButtonForeground = Color(UIColor.label)
    static let errorText          = Color(red: 0.72, green: 0.11, blue: 0.11)
    static let errorIcon          = Color(red: 0.82, green: 0.18, blue: 0.18)

    // Borders / strokes
    static let googleButtonBorder = Color(UIColor.separator)
    static let errorBorder        = Color(red: 0.94, green: 0.78, blue: 0.78)
}

// MARK: - Preview

#Preview("Default") {
    @Previewable @State var lang: AppLanguage = .vi
    LoginView(
        selectedLanguage: $lang,
        isLoading: false,
        errorMessage: nil,
        onLoginTapped: {},
        onLanguageChange: { _ in }
    )
}

#Preview("Loading") {
    @Previewable @State var lang: AppLanguage = .en
    LoginView(
        selectedLanguage: $lang,
        isLoading: true,
        errorMessage: nil,
        onLoginTapped: {},
        onLanguageChange: { _ in }
    )
}

#Preview("Error — domain rejected") {
    @Previewable @State var lang: AppLanguage = .ja
    LoginView(
        selectedLanguage: $lang,
        isLoading: false,
        errorMessage: "Account not authorized. Only @sun-asterisk.com accounts are allowed.",
        onLoginTapped: {},
        onLanguageChange: { _ in }
    )
}
