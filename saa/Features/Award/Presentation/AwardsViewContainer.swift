import SwiftUI

// MARK: - AwardsViewContainer

/// Awards tab root. Owns its own `NavigationStack` and the `AwardDetailViewModel`
/// lifecycle — mirrors the `@StateObject` / `@autoclosure` pattern used by
/// `KudosViewContainer` and `HomeViewContainer`.
///
/// The VM is constructed once via `@StateObject` so dropdown selections
/// (`selected`) survive parent re-renders caused by `HomeViewModel` state pushes.
/// When the `awards` list itself changes, `.onChange(of: awards)` calls
/// `viewModel.updateAwards(_:)` to sync without re-creating the VM.
///
/// If `awards` is empty (Home data still loading), renders a neutral loading
/// placeholder. Once awards arrive the real detail screen is shown with Top
/// Talent (sort_order == 1) preselected by default.
struct AwardsViewContainer: View {

    // MARK: - Input

    let awards: [Award]

    /// Stable code used to resolve the initial selection for the VM.
    let initiallySelectedCode: String

    /// Driven by `HomeViewContainer`; mutated here to switch the Kudos tab.
    @Binding var activeTab: NavTab

    // MARK: - ViewModel (stable across parent re-renders)

    @StateObject private var viewModel: AwardDetailViewModel

    // MARK: - Environment

    @EnvironmentObject private var languagePreference: LanguagePreference

    // MARK: - Navigation

    @State private var navPath: [AwardRoute] = []

    // MARK: - Init

    /// `makeViewModel` is `@autoclosure @escaping` so `@StateObject` captures
    /// the closure and constructs the VM exactly once — identical to the pattern
    /// in `HomeViewContainer` and `KudosViewContainer`.
    init(
        awards: [Award],
        initiallySelectedCode: String = "top_talent",
        activeTab: Binding<NavTab>,
        makeViewModel: @autoclosure @escaping () -> AwardDetailViewModel
    ) {
        self.awards = awards
        self.initiallySelectedCode = initiallySelectedCode
        self._activeTab = activeTab
        self._viewModel = StateObject(wrappedValue: makeViewModel())
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navPath) {
            rootContent
                .navigationDestination(for: AwardRoute.self) { route in
                    switch route {
                    case .notifications:
                        NotificationsPanelStubView()
                    case .search:
                        SearchStubView()
                    }
                }
        }
        // Sync the VM whenever the parent's awards list changes without
        // re-creating it — preserves the user's current dropdown selection.
        .onChange(of: awards) { newAwards in
            viewModel.updateAwards(newAwards, preferredCode: initiallySelectedCode)
        }
    }

    // MARK: - Root content

    @ViewBuilder
    private var rootContent: some View {
        if awards.isEmpty {
            loadingPlaceholder
        } else {
            AwardDetailView(
                vm: viewModel,
                unreadCount: 0,
                selectedLanguage: $languagePreference.current,
                onTapKudosCTA: { activeTab = .kudos },
                onBellTap: { navPath.append(.notifications) },
                onSearchTap: { navPath.append(.search) },
                onLanguageChange: { languagePreference.current = $0 }
            )
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Loading placeholder

    private var loadingPlaceholder: some View {
        ZStack {
            Color(red: 0.0, green: 16.0 / 255, blue: 26.0 / 255)
                .ignoresSafeArea()
            ProgressView()
                .tint(.white)
        }
        .accessibilityIdentifier("award.tab.loading")
    }
}

// MARK: - Routes

/// Push destinations available from the Awards tab.
private enum AwardRoute: Hashable {
    case notifications
    case search
}

// MARK: - Preview

#if DEBUG
#Preview {
    let awards = HomeMockData.previewAwards
    let initial = awards.min(by: { $0.sortOrder < $1.sortOrder }) ?? awards[0]
    return AwardsViewContainer(
        awards: awards,
        activeTab: .constant(.awards),
        makeViewModel: AwardDetailViewModel(awards: awards, initiallySelected: initial)
    )
    .environmentObject(LanguagePreference())
}
#endif
