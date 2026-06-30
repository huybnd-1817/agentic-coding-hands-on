import XCTest
@testable import saa

// MARK: - KudosViewContainerRouteTests
//
// Asserts the navigation Route enum is stable for `NavigationStack` paths
// (must remain `Hashable` for the `.detail(Kudos)` and `.profile(KudosAuthor)`
// cases) and that the static hashtag-tag → Hashtag.ID resolver used by
// `popToRootAndFilterHashtag(_:)` matches with and without the leading `#`.

@MainActor
final class KudosViewContainerRouteTests: XCTestCase {

    // MARK: - Fixtures

    private func makeAuthor(name: String = "S") -> KudosAuthor {
        KudosAuthor(
            userId: UUID(),
            displayName: name,
            employeeCode: nil,
            avatarURL: nil,
            departmentId: nil,
            kudosReceivedCount: 0
        )
    }

    private func makeKudos(id: KudosID = UUID()) -> Kudos {
        Kudos(
            id: id,
            sender: makeAuthor(name: "Sender"),
            recipient: makeAuthor(name: "Recipient"),
            title: "T", message: "M",
            isAnonymous: false, anonymousNickname: nil,
            hashtags: [], attachments: [],
            heartCount: 0, isLikedByMe: false, canLike: true,
            shareURL: nil, createdAt: Date(timeIntervalSince1970: 0)
        )
    }

    // MARK: - Route enum is Hashable and value-comparable

    func test_routeAll_isEqualToItself() {
        XCTAssertEqual(KudosViewContainer.Route.all, KudosViewContainer.Route.all)
    }

    func test_routeDetail_hashableRoundTrip() {
        let k1 = makeKudos()
        let route1 = KudosViewContainer.Route.detail(k1)
        let route2 = KudosViewContainer.Route.detail(k1)
        XCTAssertEqual(route1, route2, "Same Kudos must produce equal routes")
        XCTAssertEqual(route1.hashValue, route2.hashValue)
    }

    func test_routeDetail_differentKudosNotEqual() {
        let route1 = KudosViewContainer.Route.detail(makeKudos())
        let route2 = KudosViewContainer.Route.detail(makeKudos())
        XCTAssertNotEqual(route1, route2, "Routes carrying different kudos must not be equal")
    }

    func test_routeProfile_hashableRoundTrip() {
        let author = makeAuthor(name: "Profile")
        let route1 = KudosViewContainer.Route.profile(author)
        let route2 = KudosViewContainer.Route.profile(author)
        XCTAssertEqual(route1, route2)
        XCTAssertEqual(route1.hashValue, route2.hashValue)
    }

    func test_routePath_supportsPushAndPopSemantics() {
        // Simulates the NavigationStack path mutations the container performs.
        var path: [KudosViewContainer.Route] = []
        path.append(.all)
        path.append(.detail(makeKudos()))
        path.append(.profile(makeAuthor()))
        XCTAssertEqual(path.count, 3)

        path.removeLast()
        XCTAssertEqual(path.count, 2, "removeLast must pop the profile route")
        path.removeAll()
        XCTAssertTrue(path.isEmpty, "removeAll must collapse to root")
    }

    // MARK: - matchingHashtagId resolver

    func test_matchingHashtagId_returnsId_whenLeadingHashIsPresent() {
        let id = UUID()
        let hashtags = [Hashtag(id: id, tag: "#Dedicated")]
        let resolved = KudosViewContainer.matchingHashtagId(tag: "#Dedicated", in: hashtags)
        XCTAssertEqual(resolved, id)
    }

    func test_matchingHashtagId_returnsId_whenLeadingHashIsMissing() {
        let id = UUID()
        let hashtags = [Hashtag(id: id, tag: "#Dedicated")]
        let resolved = KudosViewContainer.matchingHashtagId(tag: "Dedicated", in: hashtags)
        XCTAssertEqual(resolved, id, "Caller may pass tag without leading '#'")
    }

    func test_matchingHashtagId_returnsNil_whenNoMatch() {
        let hashtags = [Hashtag(id: UUID(), tag: "#Dedicated")]
        XCTAssertNil(KudosViewContainer.matchingHashtagId(tag: "#Unknown", in: hashtags))
    }

    func test_matchingHashtagId_returnsNil_forEmptyCatalogue() {
        XCTAssertNil(KudosViewContainer.matchingHashtagId(tag: "#Dedicated", in: []))
    }
}
