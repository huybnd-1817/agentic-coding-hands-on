# Clean Architecture refactor — shipped

**Date:** 2026-06-14
**Branch:** `refactor/clean-architecture` → `main` (PR #3 on the fork)
**Commits landed:** 8 (one CI hotfix + 6 phases + 1 doc scrub)
**Session shape:** `/tkm:takumi` on the sealed plan at `plans/260612-1012-clean-architecture-refactor/`

## What landed

Dissolved the 167-LOC `AuthService` god-object into:
- `AuthSessionStore` (Core/Session) — single source of truth for session + restoring state
- `LoginViewModel` (Presentation) — sign-in loading + error state, delegates to use case
- `SignInWithGoogleUseCase` / `RestoreSessionUseCase` / `SignOutUseCase` (Domain)
- `SupabaseAuthRepository` + `GoogleSignInService` + `UserSessionMapper` + `AuthErrorMapper` (Data)

Plus the supporting move work: new top-level dirs (`App/`, `Features/`, `Core/`, `Shared/`); 16 file relocations via `git mv`; pure presentation rewire; full test migration to protocol-driven doubles.

Test count went from 50 → 63 with zero regressions on the 38-test login regression net.

## Three deviations from the literal plan

These are the moments where the plan met reality and reality won. All documented in `plan.md` Closeout:

1. **`AuthError` split.** The plan put `AuthError.from(_:)` in Domain. The current file imports `GoogleSignIn` and `Supabase` because the mapping inspects SDK error types. That directly violates Gate #1. Resolved by splitting the enum (stays in Domain, Foundation-only) from the mapping (`AuthErrorMapper` in Data). Tests repointed.

2. **`AuthService.swift` deletion timing.** Phase 04 plan said "delete in Phase 04". But `AuthServiceMocks.swift` extends `AuthService`, and three test files reference it. Deleting in Phase 04 would have made `testsMustStayGreen: true` impossible. Deferred deletion to Phase 05 alongside the test migration — one clean swap instead of two churning ones.

3. **`saa/Configuration/` directory.** Phase 01 plan said "delete once empty". It holds `Debug.xcconfig`/`Release.xcconfig` which are explicit `PBXFileReference` entries (not auto-synced) and weren't in the migration table. Left in place; relocation would need pbxproj edits and that's not Phase 01's job.

## What worked

- **Xcode 16's `PBXFileSystemSynchronizedRootGroup`** turned Phase 01's worst-case scenario (manual pbxproj surgery) into a non-event. 16 `git mv` calls and the project picked them all up. No project file edits required across the entire 6-phase refactor.
- **Phase-by-phase rest points with the user's seal.** Each phase pause caught real plan gaps before they cost a rework: the AuthError gap surfaced before Phase 02 forge began; the AuthService deletion timing was negotiated before Phase 04 began; the UI test seam degradation was caught at Phase 04's verification.
- **Trust-but-verify on implementer subagents.** Phase 04 implementer reported "all tests pass" — `xcresulttool` summary said 3 failed. The independent verification caught it. Phase 05 implementer reported "43/0/0" — true. Treat the subagent's summary as a hypothesis, not a verdict.
- **Splitting the manifest into pre-commit subagent passes.** `project-manager` reconciled plan checkboxes; `doc-writer` found two stale runbook references the eye-grep missed (`docs/setup-google-oauth.md` and `docs/ci-coverage.md`). Both ran in parallel — 60s real time for both.

## What was bumpy

- **Phase 04 UI-test seam.** The first pass populated `AuthSessionStore` state but couldn't reach `LoginViewModel` state (the VM was lazily built inside a factory closure). Three XCUITests failed on launch — `loading`/`networkError`/`notAuthorized` scenarios. Fix was to build the VM once in `saaApp.init()`, inject scenario state into it before `_authSession = StateObject(...)`, and drop the factory. After that all 8 UI tests passed.
- **The smoke test "Cannot login success" report.** Triaged based on the user's symptom ("sheet opens, returns, error banner"). Set up two strong hypotheses (Supabase rejecting / wrong client instance) and asked for console output. User came back saying smoke was actually green — false alarm. Worth the triage time? Yes: had it been real, jumping into a guess-and-fix would have been worse than waiting for the console line. The discipline held.
- **Test count drift.** Three different counts came back from xcresult depending on what summarizer ran: 50 (Phase 04), 63 (Phase 05), 39 (sub-summary). The `summary` JSON has both a per-config count and a top-level count; reading the wrong one once led to "wait, did we lose tests?" Confirmed: 63 is the right top-level number.

## Architectural calls worth recording

- **`internal` (no modifier) over `public` everywhere.** The Phase 02 implementer ran into a known Swift error — `public` on extensions of `internal` types in a single-target app fails to compile. `internal` matches the rest of the codebase and avoids ceremony for a single binary. Documented in `code-standards.md`.
- **`AuthSessionClearable` protocol seam in Domain.** `SignOutUseCase` needs to clear the store after sign-out. We didn't want `Core/Session/AuthSessionStore` referenced from Domain. So Domain defines `AuthSessionClearable` (one method, MainActor); `AuthSessionStore` conforms in a one-line extension. The seam costs nothing and keeps Domain truly free of Core types.
- **DEBUG-only `Noop{AuthRepository,GoogleSignInService}` in the main target, not the test target.** These are needed by the DEBUG composition path in `saaApp.init()` (UI test seam), not by tests directly. Putting them in the main target with `#if DEBUG` strips them from release builds cleanly. Test target has its own `Fake` doubles for unit-test orchestration.

## What I'd do differently next time

- **Tag the AuthError gap in the plan, not at runtime.** The conflict between "Domain has zero SDK imports" (Gate #1) and "`AuthError.from(_:)` stays where it is" (Phase 03 doc) was visible in the plan text on first read. A pre-flight pass over the plan looking for cross-rule contradictions before the forge began would have surfaced it without halting Phase 02.
- **Build the test count tracker into the verification command.** I re-ran tests four times across phases just to confirm counts. A wrapper that prints `passed/failed/skipped` from the xcresult bundle in one line would have saved time and avoided the false "we lost tests" moment.
- **Don't trust the implementer's test-count claim.** Twice I got back "all tests pass" when one test class had failures — once it was real (Phase 04), once it was incomplete reporting (Phase 03 implementer said 15/15 when real total was higher). The discipline is: run `xcresulttool get test-results summary` myself, every time, before committing.

## Followups

These are explicitly out of scope of this PR. None blocks merging.

- `@Observable` macro migration (separate plan, future)
- SwiftPM local-package split per feature (revisit when 3rd feature lands)
- Relocate `Debug.xcconfig`/`Release.xcconfig` into `Core/Configuration/` (requires pbxproj edits; cosmetic)
- Re-run `ci-coverage.md` numbers on the refactored codebase (table currently shows pre-refactor snapshot with a staleness note added by `doc-writer`)
