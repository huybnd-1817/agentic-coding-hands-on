import SwiftUI

struct AwardDetailStubView: View {
    let awardId: UUID

    var body: some View {
        StubScreen(titleKey: "home.stub.awardDetail", identifier: "stub.awardDetail")
    }
}
