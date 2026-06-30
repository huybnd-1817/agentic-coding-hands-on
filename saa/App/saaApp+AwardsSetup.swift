import SwiftUI

// MARK: - saaApp Awards composition helpers

/// Builds the Awards feature object graph.
///
/// Extracted from `saaApp.swift` to keep that file under the 80-LoC cap,
/// following the same pattern as `saaApp+KudosSetup.swift` for the Kudos graph.
///
/// `AwardsViewContainer` receives the live `[Award]` list from `HomeViewModel`
/// via a binding; it renders a loading placeholder until data arrives.
extension saaApp {

    // MARK: - Factory

    /// Constructs an `AwardsViewContainer` wired to live awards data and the
    /// shared tab-selection binding so the Kudos CTA can switch tabs.
    ///
    /// The `makeViewModel` closure is captured by `AwardsViewContainer`'s
    /// `@StateObject` and executed exactly once — identical to the pattern used
    /// by `saaApp+KudosSetup.swift` for `KudosViewContainer`.
    ///
    /// When `awards` is empty on first render (Home data still loading), the VM
    /// is seeded with an empty list; `AwardsViewContainer.body` shows a loading
    /// placeholder in that case. Once data arrives `.onChange(of: awards)` calls
    /// `viewModel.updateAwards(_:)` to populate the VM without re-creating it.
    ///
    /// - Parameters:
    ///   - awards: Current awards list from `HomeViewModel.state`.
    ///   - activeTab: Shared tab binding owned by `HomeViewContainer`.
    static func makeAwardsViewContainer(
        awards: [Award],
        activeTab: Binding<NavTab>
    ) -> AwardsViewContainer {
        let initialCode = "top_talent"
        // `makeViewModel:` is declared `@autoclosure @escaping` on `AwardsViewContainer.init`.
        // SwiftUI's `@StateObject` captures the resulting closure and calls it exactly ONCE
        // for the view's lifetime — even though `HomeViewContainer.body` re-invokes this
        // factory at 1 Hz (driven by the countdown timer). The struct re-allocates cheaply;
        // the VM does not. No allocation fix needed here.
        return AwardsViewContainer(
            awards: awards,
            initiallySelectedCode: initialCode,
            activeTab: activeTab,
            makeViewModel: Self.buildAwardDetailViewModel(awards: awards, initialCode: initialCode)
        )
    }

    /// Builds the initial `AwardDetailViewModel`. Separated so the closure
    /// passed to `@autoclosure` stays a single expression without a multi-line
    /// trailing-closure.
    private static func buildAwardDetailViewModel(
        awards: [Award],
        initialCode: String
    ) -> AwardDetailViewModel {
        // Resolve initial selection: prefer matching code, then sort_order == 1,
        // then first in list. If the list is empty on cold-start the VM is
        // constructed with a nil-safe fallback; `updateAwards` repopulates it
        // when data arrives via `.onChange`.
        guard let initial = awards.first(where: { $0.code == initialCode })
                ?? awards.min(by: { $0.sortOrder < $1.sortOrder })
                ?? awards.first
        else {
            // Empty list — VM is inert until updateAwards(_:) is called.
            return AwardDetailViewModel(awards: [], initiallySelected: Award(
                id: UUID(),
                code: initialCode,
                nameEN: "", nameVI: "",
                descriptionEN: "", descriptionVI: "",
                thumbnailURL: nil,
                sortOrder: 1,
                quantity: 0,
                quantityUnit: "",
                prizeValueIndividual: "",
                prizeValueTeam: nil,
                prizeNote: ""
            ))
        }
        return AwardDetailViewModel(awards: awards, initiallySelected: initial)
    }
}
