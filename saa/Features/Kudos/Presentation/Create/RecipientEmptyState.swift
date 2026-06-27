import SwiftUI

/// Empty state shown inside `RecipientDropdown` when `results` is empty and
/// `isLoading` is false.
///
/// Figma does not show an explicit empty-state frame for this screen, so the
/// view uses the project's established dark-panel palette with a neutral
/// "no results" message. The copy key `kudos.create.recipient.noResults` is
/// registered in `Localizable.xcstrings` under `kudos.create.*` per the
/// clarification decision (Q: Localization scope).
@MainActor
struct RecipientEmptyState: View {

    // MARK: - Body

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.slash")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(Color(red: 153.0/255, green: 153.0/255, blue: 153.0/255))

            Text("kudos.create.recipient.noResults", bundle: .main)
                .font(.custom("Montserrat-Medium", size: 14))
                .foregroundColor(Color(red: 153.0/255, green: 153.0/255, blue: 153.0/255))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            NSLocalizedString("kudos.create.recipient.noResults", comment: "No recipient search results")
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color(red: 0, green: 7.0/255, blue: 12.0/255).ignoresSafeArea()
        RecipientEmptyState()
            .padding(6)
            .background(Color(red: 0, green: 7.0/255, blue: 12.0/255))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 153.0/255, green: 140.0/255, blue: 95.0/255), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(width: 311)
    }
    .preferredColorScheme(.dark)
}
#endif
