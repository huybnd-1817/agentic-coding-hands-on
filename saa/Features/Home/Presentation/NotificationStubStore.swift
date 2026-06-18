import Foundation
import Combine

// MARK: - NotificationStubStore

/// Local, in-process store for the notification badge count (TC_GUI_006).
///
/// Per clarification 2026-06-15 Q5: hardcoded `unreadCount = 3` so the red dot
/// renders and tests pass. The class itself is the future seam — replace with a
/// real notifications-fetching service when the backend exists; consumers
/// (`HomeViewModel`) won't need to change.
///
/// Intentionally NOT `@MainActor`: the type only holds a `@Published Int` and
/// has no UI-touching surface. Adding `@MainActor` triggers a back-deploy crash
/// in `__deallocating_deinit` on iOS 16 (`swift_task_deinitOnExecutorMainActorBackDeploy`).
/// Combine's `@Published` is thread-safe; consumers (`HomeViewModel`) explicitly
/// `.receive(on: RunLoop.main)` before sinking.
final class NotificationStubStore: ObservableObject {

    @Published var unreadCount: Int

    init(unreadCount: Int = 3) {
        self.unreadCount = unreadCount
    }
}
