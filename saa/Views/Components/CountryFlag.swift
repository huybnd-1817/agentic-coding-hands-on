//
//  CountryFlag.swift
//  saa
//
//  Created by nguyen.duc.huyb on 11/6/26.
//

import SwiftUI

/// Inline country flag for the language picker. Drawn with SwiftUI shapes
/// because Unicode regional-indicator emojis render as tofu on the iOS 26
/// simulator (Text("🇻🇳") drops the combining behavior and shows two
/// REGIONAL INDICATOR boxes instead of the flag glyph).
struct CountryFlag: View {

    let language: AppLanguage

    var body: some View {
        Group {
            switch language {
            case .vi: vietnamFlag
            case .ja: japanFlag
            case .en: unitedKingdomFlag
            }
        }
        .frame(width: 24, height: 16)
        .clipShape(RoundedRectangle(cornerRadius: 2))
    }

    // MARK: - Per-country art

    private var vietnamFlag: some View {
        ZStack {
            Color.vnRed
            Image(systemName: "star.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.vnYellow)
                .frame(width: 11, height: 11)
        }
    }

    private var japanFlag: some View {
        ZStack {
            Color.white
            Circle()
                .fill(Color.jpRed)
                .frame(width: 9, height: 9)
        }
    }

    /// Simplified Union Jack — blue field with red+white horizontal,
    /// vertical, and diagonal crosses. Close enough at 24×16 to read as UK.
    private var unitedKingdomFlag: some View {
        ZStack {
            Color.ukBlue

            // Diagonal white saltire
            Color.white.frame(width: 30, height: 3).rotationEffect(.degrees(33))
            Color.white.frame(width: 30, height: 3).rotationEffect(.degrees(-33))

            // Diagonal red saltire (thinner)
            Color.ukRed.frame(width: 30, height: 1.5).rotationEffect(.degrees(33))
            Color.ukRed.frame(width: 30, height: 1.5).rotationEffect(.degrees(-33))

            // Vertical + horizontal white cross
            Color.white.frame(width: 24, height: 5)
            Color.white.frame(width: 5, height: 16)

            // Red cross overlay
            Color.ukRed.frame(width: 24, height: 3)
            Color.ukRed.frame(width: 3, height: 16)
        }
    }
}

// MARK: - Flag palette

private extension Color {
    static let vnRed    = Color(red: 0.85, green: 0.10, blue: 0.13)
    static let vnYellow = Color(red: 1.00, green: 0.80, blue: 0.00)
    static let jpRed    = Color(red: 0.74, green: 0.04, blue: 0.20)
    static let ukBlue   = Color(red: 0.00, green: 0.14, blue: 0.49)
    static let ukRed    = Color(red: 0.79, green: 0.06, blue: 0.18)
}

// MARK: - Preview

#Preview {
    HStack(spacing: 16) {
        CountryFlag(language: .vi)
        CountryFlag(language: .en)
        CountryFlag(language: .ja)
    }
    .padding()
    .background(Color.black)
}
