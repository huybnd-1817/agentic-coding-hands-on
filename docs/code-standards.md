# Code Standards

Reference for new code on this codebase. Architectural shape lives in [`system-architecture.md`](system-architecture.md); this file collects the conventions that show up in code review.

## File size

- Code files target **≤ 200 LOC**. Split early — composition is cheaper than untangling.
- `saaApp.swift` (composition root) target **≤ 80 LOC**. If wiring grows beyond that, extract helpers into `saaApp+Setup.swift` (already done) or an `AppContainer.swift` struct.

## Naming

- Swift filenames use **PascalCase** matching the primary type they declare (Apple convention).
- One public type per file, except for closely related siblings (`NonceGenerating` protocol + `DefaultNonceGenerator` impl live together in `Nonce.swift`).
- A `UseCase` suffix is reserved for orchestration use cases (see Rule below). A pure pass-through must not bear it.

## Layer rules (also in [`system-architecture.md`](system-architecture.md))

- **Domain imports only `Foundation`**, with two documented `UIKit` exceptions both rooted in the GIDSignIn presenter requirement:
  - `Features/Authentication/Domain/GoogleSignInServiceProtocol.swift` — protocol carries `UIViewController` as a presenter param.
  - `Features/Authentication/Domain/UseCases/SignInWithGoogleUseCase.swift` — forwards the presenter through the protocol seam.
- No new file in `Features/*/Domain/**` may add an SDK import. CI grep (Gate #1 of the refactor plan) enforces this.
- Repository protocols are declared in Domain. Implementations live in Data.
- Stores live in `Core/Session/` (or a feature folder when feature-scoped). Single instance per scope, injected via `@EnvironmentObject` or constructor. No `static shared`.

## UseCase rule (Rule #3 from the refactor plan)

> A UseCase must add orchestration value OR enable a unit-test seam.

A UseCase whose `execute()` is a single forwarding call to `repository.method()` is forbidden — call the repository directly from the ViewModel and skip the indirection. Reviewers reject the UseCase rather than ship the boilerplate. Current UseCases all qualify (see [`system-architecture.md`](system-architecture.md) → Architectural rules).

## Concurrency

- Stores and ViewModels: `@MainActor final class … : ObservableObject`. `@Published private(set)` on observable state; mutate through methods.
- Use cases: plain `struct … : Sendable` with `async [throws] func execute(...)`. Add `@MainActor` only when the call must hop to the main actor (e.g. forwarding to a UIKit-bound protocol).
- Protocols crossing layer boundaries: `Sendable`. Test doubles use `@unchecked Sendable` to escape strict-concurrency checks ergonomically — annotate each file with a one-line reason.
- Errors that need cross-layer mapping (`Error` → `AuthError`) live in Data (`AuthErrorMapper`). The Domain enum stays pure-Swift.

## Testing

- Doubles live in `saaTests/Doubles/`. Each fake conforms to the Domain protocol; configurable `Behavior` enums for per-method success/error; counters + last-arg recording for orchestration assertions.
- Domain unit tests (`saaTests/Domain/`) **must run with no SDK loaded** — no `Supabase`, no `GoogleSignIn`, no network. This is Gate #3 of the refactor plan.
- ViewModel and Store tests in `saaTests/Presentation/`. Use the Doubles, never instantiate a real repository.
- `@MainActor` ObservableObjects need `async` test methods to avoid `SIGABRT` from MainActor dealloc races (the existing test files document this pattern).

## DI / composition

- Manual composition root in `App/saaApp.swift` (≤ 80 LOC) plus `saaApp+Setup.swift` for helpers.
- DEBUG `-uiTestMode <scenario>` launch arg pre-populates both `AuthSessionStore` and `LoginViewModel` state before the first frame. Scenarios are listed in `saaApp+Setup.swift::applyScenario`. Release builds strip the entire DEBUG branch.

## Errors

- Domain error types are pure Swift enums conforming to `LocalizedError`. Expose a `messageKey: String?` so SwiftUI's `\.locale` environment drives the displayed copy (not the system locale).
- A `nil` `messageKey` means "the UI must stay silent" — the `.userCancelled` case uses this so dismissing the Google sheet does not show a toast.
- SDK-aware mapping (`AuthErrorMapper.from(_:)`) lives in Data. New error sources are added there, not in Domain.

## Comments

- Lead with **why**, not what. Public types get a one-paragraph `///` docstring covering purpose + non-obvious invariants. Avoid restating the method signature in prose.
- `MARK:` sections organize files into Init / Properties / Public API / Private helpers blocks. Don't add a MARK unless the file has ≥ 2 sections worth.
- `// API CONFIRM: ...` is the convention for SDK calls that need verification against the resolved package version — visible to grep, easy to clean up after a dependency bump.
