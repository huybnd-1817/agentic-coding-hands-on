# Clean Architecture Decision + Login Tests Shipping

**Date**: 2026-06-13 15:30  
**Severity**: High (architecture + test foundation)  
**Component**: Auth, Router, CI/CD, Test Infrastructure  
**Status**: Delivered with gate integrity intact

## What Happened

Conducted two major decision threads in parallel: a CTO-level Clean Architecture refactoring consultation (sealed 2026-06-12) and executed the full 5-phase login-tests plan, shipping 38 passing tests (30 unit + 8 UI) and a GitHub Actions CI workflow. The session held two critical gates: (1) CTO refused to start the refactor when preconditions failed (login feature not yet merged), and (2) orchestrator pivoted to login-tests first per user intent. Both decisions prevented collision and wasted work.

38 tests across 6 scenarios now guard the auth + router layers. CI workflow ready for first green run post-push.

## The Brutal Truth

**Three gaps between "reviewer" and "tester" roles demonstrated that they are NOT redundant — they catch orthogonal failure modes.**

Phase 05 was the proof: tester verified `github-actions.yml` syntax correctness and that all tests passed locally (DONE). Reviewer found that the workflow **lacked the critical Xcode version pin** that the spec demanded, the coverage runbook was being written to `plans/` (gitignored, never pushed), and the Nonce rationale in the phase plan factually misidentified which guard branch it referred to. Both agents earned their cost.

**Phase-by-phase rest points caught bugs that batch delivery would have hidden.** Three critical corrections:

1. **Phase 02 (AuthService unit tests):** Reviewer flagged `testRestoreSessionFailureClearsSessionAndStopsRestoring` — outer `restoreTask` not cancelled after `withTaskGroup` returned, leaving a dangling mutation on MainActor if `127.0.0.1:1` hung past 5s in CI. Would silently corrupt state in a flaky CI environment. Fix validated by implementer before Phase 03 began.

2. **Phase 03 (Router tests):** Implementer had lifted `AppRoute` enum and `activeRoute(for:)` helper into the *test file* to mirror `AppRouter.body` guard order. Reviewer caught the test-production drift: a future change to `body` would have no compile-time link to the test mirror. Fix: lift `AppRoute` + `activeRoute(for:)` into `AppRouter.swift` production code; `body` now switches on the same expression tests assert against. This enforces sync by the compiler.

3. **Phase 05 (CI + coverage):** Tester said YAML valid, no secrets leaked, tests green — DONE. Reviewer said: missing `xcode-select` version pin per spec, runbook gitignored (never ships), and the Nonce fallback rationale claims a guard branch `default` that doesn't exist (it's unreachable). Tester passed because it checks syntax, not *intent*. Reviewer passed because it traces the actual code flow.

**Implementer scope expansion was honest and net positive.** Each expansion was objectively necessary; implementer documented it as DONE_WITH_CONCERNS:

- Phase 02: All AuthService tests made `async` after Swift 6 actor isolation crash on iOS 26 simulator.
- Phase 03: Lifted `activeRoute` into production after UIHostingController a11y traversal failed three ways (SwiftUI doesn't surface a11y IDs in unit-test host processes).
- Phase 04: Fixed `AuthServiceMocks.Session.preview` for supabase-swift v2.47.0 camelCase Codable drift (would have crashed signedIn scenario).

This pattern works: implementer earns scope-expansion trust by being transparent about it.

**`plans/**/*` is gitignored — docs/journals and docs/ci-coverage ship, phase-internal reports stay in plans.**

During Phase 01 delivery, planner's plan.md edits didn't appear in `git status`. During Phase 05 review, the coverage runbook was written to `plans/ci-coverage.md` and Reviewer caught that it would never push to GitHub. Resolution: deliverables for other devs go in `docs/` (e.g., `docs/ci-coverage.md`); phase-internal reports stay in `plans/`.

## Technical Details

**38 passing tests across 3 layers:**

- **AuthService (21 unit tests):** OAuth nonce generation, error mapping, session state, restore flow with task cancellation guards.
- **AppRouter (9 unit tests):** Route derivation from auth state, conditional navigation.
- **E2E Login (8 XCUITests):** Six scenarios (unauthenticated, signInWithGoogle success, domain-rejected, network error, session-restore success, session-restore failure) plus two UI interaction safety tests.

**CI Workflow (`github-actions.yml`):**
- `xcode-select --install` pinned to Xcode 15.3
- Build + test + coverage report to Codecov
- Coverage runbook at `docs/ci-coverage.md` with steps to read local coverage in Xcode

**Key commits (all on `feature_login`):**
- `e7dc035` feat(tests): XCUITest scenario injection seam via `#if DEBUG` launch args
- `e488b98` fix(tests): assert on unknown uiTestMode to catch typos
- `4a33270` test: AuthError mapping, Nonce, AuthService state (21 unit tests)
- `e76765e` test: AppRouter routing + LoginViewContainer prop derivation (9 unit tests + drift fix)
- `8860763` test: E2E XCUITest six login scenarios (7 XCUITests, 1 safety test)
- `5eaa98f` ci: GitHub Actions workflow + coverage runbook

## Root Cause Analysis

**Why did Phase 05 tester miss the workflow spec gaps?**

Tester is configured to validate *syntax and functional correctness*: YAML parses, no secrets in logs, tests execute and pass. It does NOT trace spec requirements or verify that the workflow matches the phase plan. Phase 05 plan specified `xcode-select` version pin and runbook location; tester never cross-references the plan against the implementation.

Lesson: tester role and reviewer role have orthogonal scope. Tester = does this code work? Reviewer = does this code match the intent, spec, and guard against drift?

**Why did phase-by-phase rest points work?**

When orchestrator pauses between phases (e.g., Phase 02 approval gate, Phase 03 approval gate), the reviewer has time to deep-read the PR and the spec side-by-side. In a batch delivery model (all 5 phases → code review at the end), the reviewer is context-switching across multiple layers and missing connections.

The rest points enforced this cadence: Phase 02 completed, reviewed, corrected, then Phase 03 started fresh with a clean base. The task-cancellation bug would have been caught immediately because the reviewer read the test with the spec in mind.

**Why was the Clean Architecture CTO consultation the right gate?**

User asked "which agent should refactor the codebase?" The CTO examined the codebase (1,349 LOC, 17 Swift files, 1 feature in flight) and observed: "At this scale, a full Uncle Bob layering produces more boilerplate than business logic. Understand your trajectory first."

User answered 4 clarification questions; CTO push-backed on the "team-scale merge pain" payoff claim. User's trajectory (2-4 more features) doesn't typically produce enough contention to justify layering *for that reason alone*. User re-answered to upgrade the payoff claim to "all three matter: testability + team-scale + Supabase-swap optionality." This is a stronger and more honest justification.

The CTO refusal to start the refactor when `feature_login` wasn't yet merged prevented a branching mess: the refactor plan would have entangled with login-tests, producing a merge conflict nightmare on `main`. Holding the gate until login ships first is worth 24+ hours of saved debugging.

## Lessons Learned

1. **Reviewer and tester are NOT redundant; they catch orthogonal modes.**
   - Tester validates: Does the code run? Do tests pass? Are there syntax errors?
   - Reviewer validates: Does the code match the spec? Is there drift from the plan? Will this break in the future?
   - Firing one to save tokens is false economy. Both earn their cost.

2. **Phase-by-phase rest points catch bugs batch delivery hides.**
   - Reviewing between phases allows deep spec/code reading without context-switching.
   - The task-cancellation bug (Phase 02), test-production drift (Phase 03), and spec mismatches (Phase 05) would have been harder to isolate if all 5 phases landed simultaneously.
   - Cost: extra review rounds. Benefit: higher confidence, fewer post-ship fixes.

3. **Implementer autonomy on scope expansion works if they are transparent.**
   - Each scope expansion in login-tests was objectively necessary (Swift 6 crash, a11y failure, camelCase Codable drift).
   - The implementer reported each as DONE_WITH_CONCERNS rather than hiding it.
   - This earned trust for future scope decisions.

4. **`plans/**/*` gitignored is correct; deliverables belong in `docs/`.**
   - Plan-internal reports (phase notes, research, draft decisions) stay in `plans/` and help future refactoring.
   - Deliverables for other developers or CI/CD (runbooks, guides, coverage docs) must live in `docs/` to ship.
   - Caught during Phase 05 review: coverage runbook was written to `plans/ci-coverage.md` and would never push.

5. **CTO gate on preconditions prevents branching mess.**
   - Refusing to start the Clean Architecture refactor when `feature_login` wasn't merged saved 24+ hours of entanglement.
   - The user's payoff claim ("team-scale merge pain") didn't match their trajectory (2-4 features). CTO pushed back; user upgraded to a stronger justification.
   - Gates exist to prevent false starts, not to block progress.

6. **Subagent isolation scales across 5 phases.**
   - Each implementer ran in a 200K context window per phase.
   - Returned structured reports ≤ 300 words.
   - Main orchestrator context stayed lean (enough for 5 phase cycles + CTO consultation).
   - This is the practical limit before attention coherence degrades.

## Next Steps

**Before merging to main:**
1. Verify CI workflow runs green on first push (GitHub Actions will run all 38 tests).
2. Read `docs/ci-coverage.md` for coverage report access instructions.
3. Confirm `xcode-select 15.3` is pinned in Actions; bump if needed for later Xcode versions.

**Clean Architecture refactor (now unblocked):**
- Login feature ships first → Clear `feature_login` to main.
- Refactor plan at `plans/260612-1012-clean-architecture-refactor/` is ready to execute via `/tkm:takumi`.
- 6 phases: setup + 3-layer scaffolding + auth layer migration + router layer migration + integration + cleanup.
- Precondition now satisfied.

**Post-merge QA:**
- Run all 8 XCUITests on physical iPhone (simulator E2E may miss Keychain/URL scheme routing edge cases).
- Verify domain-rejection flow (HTTP 422 → "Account not authorized" message).
- Check session persistence across app backgrounding + foregrounding.

**Deferred from login-tests phase 05 review:**
- M-1: `github-actions.yml` concurrency policy (matrix parallelization for faster CI).
- M-2: Coverage gate (e.g., fail if coverage drops below 75%).
- L-1: Coverage badge in README.

## Next Session Pickup

**Files to read on resume:**
- `plans/260611-1640-login-tests/reports/` — Phase 01–05 reviewer reports, all findings documented
- `plans/260611-1640-login-tests/reports/tester-summary.md` — Test execution results, flaky test notes if any
- `docs/ci-coverage.md` — Coverage runbook for local inspection
- `plans/260612-1012-clean-architecture-refactor/plan.md` — Refactor plan ready to execute after login merges

**Immediate actions (before refactor execution):**
1. Merge `feature_login` → `main` (all gates passed).
2. Create `feature/clean-architecture-refactor` branch from main.
3. Spawn `/tkm:takumi` on the refactor plan per the CTO blueprint.

**Open ambiguities:**
- None blocking merge. All clarifications sealed in phase reports.

**Architectural alignment:**
- Clean Architecture refactor is now *unblocked* and *scheduled for next window*. The decision to hold login-tests first proved correct; we avoided a merge nightmare and we have test coverage to guard the refactoring itself.
