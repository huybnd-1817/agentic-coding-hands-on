import XCTest
@testable import saa

// MARK: - AwardDetailViewModelTests
//
// @MainActor tests on `AwardDetailViewModel`:
//   - select(_:) updates `selected` when award is in list
//   - select(_:) no-ops cleanly when award is not in list
//   - updateAwards(_:preferredCode:) preserves selection when it remains valid
//   - updateAwards(_:preferredCode:) falls back to preferredCode when selection is dropped
//   - updateAwards(_:preferredCode:) falls back to first (by sort_order) when selection dropped and no preferred
//   - updateAwards(_:preferredCode:) defensively handles empty list

@MainActor
final class AwardDetailViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeAward(
        id: UUID = UUID(),
        code: String = "top_talent",
        nameEN: String = "Top Talent",
        nameVI: String = "Tài năng",
        sortOrder: Int = 1,
        quantity: Int = 10,
        prizeValueIndividual: String = "7.000.000 VNĐ",
        prizeValueTeam: String? = nil
    ) -> Award {
        Award(
            id: id,
            code: code,
            nameEN: nameEN,
            nameVI: nameVI,
            descriptionEN: "EN",
            descriptionVI: "VI",
            thumbnailURL: nil,
            sortOrder: sortOrder,
            quantity: quantity,
            quantityUnit: "Cá nhân",
            prizeValueIndividual: prizeValueIndividual,
            prizeValueTeam: prizeValueTeam,
            prizeNote: "cho mỗi giải thưởng"
        )
    }

    // MARK: - Init

    func testInit_setsSelectedToProvidedAward() async {
        let topTalent = makeAward(code: "top_talent", sortOrder: 1)
        let topProject = makeAward(code: "top_project", sortOrder: 2)
        let awards = [topTalent, topProject]

        let vm = AwardDetailViewModel(awards: awards, initiallySelected: topProject)

        XCTAssertEqual(vm.selected.code, "top_project")
    }

    func testInit_guardsFallbackWhenInitialNotInList() async {
        let topTalent = makeAward(code: "top_talent", sortOrder: 1)
        let topProject = makeAward(code: "top_project", sortOrder: 2)
        let awards = [topTalent, topProject]
        let outsider = makeAward(code: "mvp", sortOrder: 6)

        let vm = AwardDetailViewModel(awards: awards, initiallySelected: outsider)

        // Should fall back to the first item (or any member of awards).
        XCTAssertTrue(awards.contains(where: { $0.id == vm.selected.id }))
    }

    // MARK: - select(_:)

    func testSelect_validAward_updatesSelected() async {
        let topTalent = makeAward(code: "top_talent", sortOrder: 1)
        let topProject = makeAward(code: "top_project", sortOrder: 2)
        let awards = [topTalent, topProject]
        let vm = AwardDetailViewModel(awards: awards, initiallySelected: topTalent)

        vm.select(topProject)

        XCTAssertEqual(vm.selected.code, "top_project")
    }

    func testSelect_awardNotInList_isNoOp() async {
        let topTalent = makeAward(code: "top_talent", sortOrder: 1)
        let topProject = makeAward(code: "top_project", sortOrder: 2)
        let awards = [topTalent, topProject]
        let vm = AwardDetailViewModel(awards: awards, initiallySelected: topTalent)

        let outsider = makeAward(code: "mvp", sortOrder: 6)
        vm.select(outsider)

        XCTAssertEqual(vm.selected.code, "top_talent", "Selection must not change for award not in list")
    }

    // MARK: - updateAwards(_:preferredCode:)

    func testUpdateAwards_keepsSelectionWhenStillPresent() async {
        let topTalent = makeAward(code: "top_talent", sortOrder: 1)
        let topProject = makeAward(code: "top_project", sortOrder: 2)
        let awards = [topTalent, topProject]
        let vm = AwardDetailViewModel(awards: awards, initiallySelected: topProject)

        // Update with a list that still contains topProject.
        let newTopTalent = makeAward(code: "top_talent", sortOrder: 1)
        let newTopProject = makeAward(code: "top_project", sortOrder: 2)
        let mvp = makeAward(code: "mvp", sortOrder: 6)
        let newList = [newTopTalent, newTopProject, mvp]

        vm.updateAwards(newList)

        XCTAssertEqual(vm.selected.code, "top_project", "Current selection must be retained")
    }

    func testUpdateAwards_resolvesToPreferredCodeWhenSelectedRemoved() async {
        let topTalent = makeAward(code: "top_talent", sortOrder: 1)
        let topProject = makeAward(code: "top_project", sortOrder: 2)
        let awards = [topTalent, topProject]
        let vm = AwardDetailViewModel(awards: awards, initiallySelected: topProject)

        // Update with a list that drops topProject but includes mvp.
        let newTopTalent = makeAward(code: "top_talent", sortOrder: 1)
        let mvp = makeAward(code: "mvp", sortOrder: 6)
        let newList = [newTopTalent, mvp]

        vm.updateAwards(newList, preferredCode: "mvp")

        XCTAssertEqual(vm.selected.code, "mvp", "Must fall back to preferredCode")
    }

    func testUpdateAwards_fallsBackToFirstWhenSelectedRemovedAndNoPreferred() async {
        let topTalent = makeAward(code: "top_talent", sortOrder: 1)
        let topProject = makeAward(code: "top_project", sortOrder: 2)
        let awards = [topTalent, topProject]
        let vm = AwardDetailViewModel(awards: awards, initiallySelected: topProject)

        // Update with a list that drops topProject but no preferred code.
        let newTopTalent = makeAward(code: "top_talent", sortOrder: 1)
        let newMvp = makeAward(code: "mvp", sortOrder: 6)
        let newList = [newTopTalent, newMvp]

        vm.updateAwards(newList)

        // Should fall back to the one with the lowest sortOrder.
        XCTAssertEqual(vm.selected.code, "top_talent", "Must fall back to first by sort_order")
    }

    func testUpdateAwards_emptyListLeavesSelectedUnchanged() async {
        let topTalent = makeAward(code: "top_talent", sortOrder: 1)
        let topProject = makeAward(code: "top_project", sortOrder: 2)
        let awards = [topTalent, topProject]
        let vm = AwardDetailViewModel(awards: awards, initiallySelected: topProject)

        // Update with empty list.
        vm.updateAwards([])

        // Defensive: selected should remain unchanged when list is empty.
        XCTAssertEqual(vm.selected.code, "top_project", "Selected must not change with empty update list")
    }

    func testUpdateAwards_preferredCodeNotInList_skipsAndFallsBackToFirst() async {
        let topTalent = makeAward(code: "top_talent", sortOrder: 1)
        let topProject = makeAward(code: "top_project", sortOrder: 2)
        let awards = [topTalent, topProject]
        let vm = AwardDetailViewModel(awards: awards, initiallySelected: topProject)

        // Update with a list where preferredCode doesn't exist.
        let newTopTalent = makeAward(code: "top_talent", sortOrder: 1)
        let newMvp = makeAward(code: "mvp", sortOrder: 6)
        let newList = [newTopTalent, newMvp]

        vm.updateAwards(newList, preferredCode: "nonexistent_code")

        // Should fall back to first by sort_order (topTalent).
        XCTAssertEqual(vm.selected.code, "top_talent", "Must fall back to first when preferred is not found")
    }

    func testUpdateAwards_sortOrderNotOne_selectsMinimum() async {
        let topTalent = makeAward(code: "top_talent", sortOrder: 1)
        let topProject = makeAward(code: "top_project", sortOrder: 2)
        let bestManager = makeAward(code: "best_manager", sortOrder: 3)
        let awards = [topTalent, topProject, bestManager]
        let vm = AwardDetailViewModel(awards: awards, initiallySelected: topProject)

        // Update with a reordered list where topTalent is not first positionally.
        let newBestManager = makeAward(code: "best_manager", sortOrder: 3)
        let newTopTalent = makeAward(code: "top_talent", sortOrder: 1)
        let newList = [newBestManager, newTopTalent]

        vm.updateAwards(newList)

        // Should select by sort_order, not position. topTalent has sortOrder=1 (minimum).
        XCTAssertEqual(vm.selected.code, "top_talent", "Must select by minimum sort_order, not position")
    }
}
