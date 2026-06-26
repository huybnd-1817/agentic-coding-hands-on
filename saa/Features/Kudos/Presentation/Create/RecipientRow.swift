import SwiftUI

/// Single row inside the recipient search dropdown.
///
/// Matches Figma component `490:5562` used in B.1 (`mms_B.1_kết quả search 1`)
/// and B.3 (`mms_B.3_kết quả search 3`).
///
/// Layout (left → right):
///   - Avatar container 60×60pt (10pt padding) → avatar circle 40×40pt,
///     white 1.869pt border, circular clip.
///   - Name + department stack (width 209pt):
///       • displayName  — Montserrat Medium 14pt / 20pt / #FFFFFF
///       • departmentCode — Montserrat Medium 14pt / 20pt / #999999
///
/// Row height: 60pt. Background on the first (highlighted) row:
///   rgba(255,234,158,0.20) — the gold tint that marks the active/first result.
///   Subsequent rows have no background (transparent), matching B.3.
@MainActor
struct RecipientRow: View {

    // MARK: - Inputs

    let profile: ProfileSummary

    /// When true the row renders the highlighted gold-tint background used for
    /// the first search result (B.1). False = transparent (B.3+).
    var isHighlighted: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            avatarContainer
            nameStack
            Spacer(minLength: 0)
        }
        .frame(width: 299, height: 60)
        .background(
            isHighlighted
                ? Color(red: 1.0, green: 234.0/255, blue: 158.0/255).opacity(0.20)
                : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: isHighlighted ? 2 : 0))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(profile.displayName), \(profile.department ?? "")")
    }

    // MARK: - Avatar container (60×60pt, 10pt padding)

    /// Figma `mms_B.1.1_avatar` / `Avatar` frame — 60×60pt, 10pt inset,
    /// holds a 40×40pt circle avatar with 1.869pt white border.
    private var avatarContainer: some View {
        ZStack {
            Group {
                if let url = profile.avatarURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            initialsPlaceholder
                        }
                    }
                } else {
                    initialsPlaceholder
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 1.869)
            )
        }
        .frame(width: 60, height: 60)
    }

    /// Fallback when no `avatarURL` is provided — shows the user's initials
    /// on a neutral grey background. Matches the `#EEE` fallback in Figma.
    private var initialsPlaceholder: some View {
        ZStack {
            Color(red: 238.0/255, green: 238.0/255, blue: 238.0/255)
            Text(initials)
                .font(.custom("Montserrat-Medium", size: 13))
                .foregroundColor(Color(red: 153.0/255, green: 153.0/255, blue: 153.0/255))
        }
    }

    private var initials: String {
        let words = profile.displayName.split(separator: " ")
        let first = words.first?.prefix(1) ?? ""
        let last  = words.count > 1 ? words.last?.prefix(1) ?? "" : ""
        return "\(first)\(last)".uppercased()
    }

    // MARK: - Name + department stack

    /// Figma `mms_B.1.2_tên và đơn vị` → `Frame 540`: two TEXT nodes stacked
    /// vertically (each 20pt line-height), total 40pt height, width 209pt.
    private var nameStack: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(profile.displayName)
                .font(.custom("Montserrat-Medium", size: 14))
                .lineSpacing(20 - 14)          // lineHeight 20pt
                .foregroundColor(.white)
                .lineLimit(1)

            Text(profile.department ?? "")
                .font(.custom("Montserrat-Medium", size: 14))
                .lineSpacing(20 - 14)
                .foregroundColor(Color(red: 153.0/255, green: 153.0/255, blue: 153.0/255))
                .lineLimit(1)
        }
        .frame(width: 209, alignment: .leading)
        .frame(height: 40)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 7.0/255, blue: 12.0/255).ignoresSafeArea()
        VStack(spacing: 0) {
            RecipientRow(profile: ProfileSummary.mockResults[0], isHighlighted: true)
            RecipientRow(profile: ProfileSummary.mockResults[1], isHighlighted: false)
        }
        .padding(6)
        .background(Color(red: 0, green: 7.0/255, blue: 12.0/255))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .preferredColorScheme(.dark)
}
#endif
