import SwiftUI

// MARK: - StubScreen

/// Shared "Coming soon" placeholder used by every Phase 06 stub destination.
/// Per clarification 2026-06-15 Q1: Home is the only fully-built screen — every
/// other navigation target is a stub so routes work and tests pass.
struct StubScreen: View {

    let titleKey: LocalizedStringKey
    let identifier: String

    var body: some View {
        VStack(spacing: 12) {
            Text(titleKey)
                .font(.title2.weight(.semibold))
            Text(LocalizedStringKey("home.stub.comingSoon"))
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .accessibilityIdentifier(identifier)
    }
}
