import Foundation
import Combine

// MARK: - HomeViewModel

/// State holder for the Home screen.
///
/// Three published properties drive the view:
///   - `state` — Awards section state machine (loading / loaded / empty / error).
///   - `countdown` — recomputed every second while the timer is running.
///   - `unreadCount` — mirror of `NotificationStubStore.unreadCount`.
///
/// `isKudosAvailable` is captured as a constant (not published) because the
/// FeatureFlag is compile-time.
///
/// Routing concerns (401 → sign-out, 403 → AccessDenied) are intentionally
/// **NOT** in this VM — `HomeViewContainer` observes `state` and dispatches
/// at the boundary where `AuthSessionStore` / `SignOutUseCase` live.
@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published

    @Published private(set) var state: AwardsState = .loading
    @Published private(set) var countdown: Countdown
    @Published private(set) var unreadCount: Int

    let isKudosAvailable: Bool

    // MARK: - Dependencies

    private let repository: any AwardsRepositoryProtocol
    private let notificationStore: NotificationStubStore
    private let eventDate: Date
    private let clock: () -> Date

    // MARK: - Subscriptions

    private var timerCancellable: AnyCancellable?
    private var notificationCancellable: AnyCancellable?

    // MARK: - Init

    init(
        repository: any AwardsRepositoryProtocol,
        notificationStore: NotificationStubStore,
        isKudosAvailable: Bool = FeatureFlags.isKudosAvailable,
        eventDate: Date = FeatureFlags.eventDate,
        clock: @escaping () -> Date = { Date() }
    ) {
        self.repository = repository
        self.notificationStore = notificationStore
        self.isKudosAvailable = isKudosAvailable
        self.eventDate = eventDate
        self.clock = clock
        self.countdown = Countdown.until(eventDate, from: clock())
        self.unreadCount = notificationStore.unreadCount

        notificationCancellable = notificationStore.$unreadCount
            .receive(on: RunLoop.main)
            .sink { [weak self] newValue in
                self?.unreadCount = newValue
            }
    }

    // MARK: - Awards loading

    /// Fetches awards via the repository and maps the result to a state.
    /// Sets `.loading` first so callers don't need to.
    func loadAwards() async {
        state = .loading
        do {
            let awards = try await repository.fetchAwards()
            state = awards.isEmpty ? .empty : .loaded(awards)
        } catch let error as AwardsError {
            state = .error(error)
        } catch {
            state = .error(.unknown(underlying: error))
        }
    }

    /// Alias for `loadAwards` — exists to make the call site self-documenting
    /// (Retry button → `viewModel.retryAwards()`).
    func retryAwards() async {
        await loadAwards()
    }

    // MARK: - Countdown timer

    /// Begins ticking the countdown every second on the main run loop.
    /// Safe to call repeatedly — replaces any prior subscription.
    func startCountdownTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.countdown = Countdown.until(self.eventDate, from: self.clock())
            }
    }

    /// Cancels the countdown timer subscription.
    func stopCountdownTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    // MARK: - Test seams (DEBUG-only)

    #if DEBUG
    /// Direct state injection for previews + UI tests. Skips repository call.
    func _injectState(_ state: AwardsState) {
        self.state = state
    }
    #endif
}
