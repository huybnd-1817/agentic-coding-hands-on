//
//  LoginView.swift
//  saa
//
//  Created by nguyen.duc.huyb on 10/6/26.
//

import SwiftUI

/// Pixel-perfect Login screen built from MoMorph design
/// (fileKey: 9ypp4enmFmdK3YAFJLIu6C, screenId: 8HGlvYGJWq).
/// Purely presentational — auth/navigation belongs to `LoginViewContainer`.
struct LoginView: View {

    // MARK: Inputs

    @Binding var selectedLanguage: AppLanguage
    let isLoading: Bool
    let errorMessage: String?

    // MARK: Outputs

    let onLoginTapped: () -> Void
    let onLanguageChange: (AppLanguage) -> Void

    // MARK: Body

    var body: some View {
        // Content lives at the OUTER level so SwiftUI's safe-area inset
        // propagation works correctly. Background layers attach via .background()
        // and extend to all edges — they don't break safe area for siblings.
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 8)

            // Fixed gap from top bar to hero block — matches Figma
            // (logo bottom y=96, ROOT FURTHER top y=252 → 156pt).
            Spacer().frame(height: 156)

            heroBlock
                .padding(.horizontal, 20)

            // Flexible middle space — absorbs extra height on taller phones.
            Spacer(minLength: 24)

            bottomBlock
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(backgroundLayer)
        .preferredColorScheme(.dark)
    }

    // MARK: - Backdrop

    /// Dark color + keyvisual artwork + top gradient overlay, all extending edge-to-edge.
    private var backgroundLayer: some View {
        ZStack {
            Color.loginBackdrop

            Image("login-bg")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Top-edge gradient — softens the artwork behind the status bar
            // and keeps the brand logo legible on bright keyvisual regions.
            LinearGradient(
                colors: [
                    Color.loginBackdrop.opacity(0.9),
                    Color.loginBackdrop.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 140)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .ignoresSafeArea()
    }

    // MARK: - Layout sections

    private var topBar: some View {
        HStack(alignment: .top) {
            Image("sun-annual-awards")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 44)

            Spacer(minLength: 12)

            LanguagePicker(
                selectedLanguage: $selectedLanguage,
                onLanguageChange: onLanguageChange
            )
            .padding(.top, 4)
        }
    }

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 32) {
            Image("root-further")
                .resizable()
                .scaledToFit()
                .frame(width: 247, height: 109)

            // Localized tagline — Montserrat 14/20 in Figma; SF Pro fallback.
            Text(LocalizedStringKey("login.description"))
                .font(.system(size: 14, weight: .light))
                .foregroundColor(.white)
                .lineSpacing(6)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Bottom-anchored stack: button → fixed gap → copyright → bottom safe area.
    /// Distances mirror Figma (button bottom y=666, copyright top y=780 → 114pt gap;
    /// copyright bottom y=796, frame bottom y=812 → 16pt residual).
    private var bottomBlock: some View {
        VStack(spacing: 0) {
            if let message = errorMessage {
                errorBanner(message: message)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }

            googleButton
                .padding(.horizontal, 65)

            Spacer().frame(height: 114)

            Text(LocalizedStringKey("login.copyright"))
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 16)
    }

    private var googleButton: some View {
        Button(action: onLoginTapped) {
            HStack(spacing: 8) {
                Text(LocalizedStringKey("login.button.google"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.loginBackdrop)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .loginBackdrop))
                        .frame(width: 24, height: 24)
                } else {
                    Image("google-icon")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Color.googleButtonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isLoading)
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
            Spacer(minLength: 0)
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
    /// Figma frame fill — #00101A.
    static let loginBackdrop          = Color(red: 0.0,  green: 16.0/255, blue: 26.0/255)
    /// Figma button fill — #FFEA9E.
    static let googleButtonBackground = Color(red: 1.0,  green: 234.0/255, blue: 158.0/255)

    // Error banner palette
    static let errorBackground = Color(red: 1.0,  green: 0.94, blue: 0.94)
    static let errorText       = Color(red: 0.72, green: 0.11, blue: 0.11)
    static let errorIcon       = Color(red: 0.82, green: 0.18, blue: 0.18)
    static let errorBorder     = Color(red: 0.94, green: 0.78, blue: 0.78)
}

// MARK: - Preview

private struct LoginPreviewHost: View {
    @State var lang: AppLanguage
    let isLoading: Bool
    let errorMessage: String?

    var body: some View {
        LoginView(
            selectedLanguage: $lang,
            isLoading: isLoading,
            errorMessage: errorMessage,
            onLoginTapped: {},
            onLanguageChange: { _ in }
        )
    }
}

#Preview("Default") {
    LoginPreviewHost(lang: .vi, isLoading: false, errorMessage: nil)
}

#Preview("Loading") {
    LoginPreviewHost(lang: .en, isLoading: true, errorMessage: nil)
}

#Preview("Error — not authorized") {
    LoginPreviewHost(
        lang: .ja,
        isLoading: false,
        errorMessage: "login.error.notAuthorized"
    )
}
