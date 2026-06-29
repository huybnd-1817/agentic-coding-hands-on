# All Kudos — Test Expansion (Unit + E2E) Shipped

**Date:** 2026-06-29
**Branch:** `feature/all-kudos` (PR #9 updated)
**Session shape:** `--fast` Takumi: read → blueprint → forge → temper → review → deliver
**Commits landed:** 2
- `396a161 test(kudos): add unit + UI test coverage for All Kudos screen`
- `5ac6931 docs(kudos): record All Kudos test expansion in changelog`

## What landed

**Unit tests:** 9 new tests for `KudosCardAdapter` pure-functional helpers (201 LOC, `saaTests/Features/Kudos/AllKudosCardAdapterTests.swift`). Covers image sizing, accessibility label formatting, date truncation, and edge cases. Zero production code changes.

**UI tests:** 5 new XCUITests for All Kudos screen surface (191 LOC, `saaUITests/AllKudosScreenUITests.swift`). Covers push navigation from Kudos tab, back gesture, tab-bar persistence, pull-to-refresh trigger, and feed card rendering.

**Outcome:** Full `saaTests` suite green (390+ tests, zero regressions). All 5 new XCUITests green on final run.

## Two production-code findings (not bugs, but constrain testing)

### 1. SwiftUI accessibility identifier propagation shadows inner IDs

When `.accessibilityIdentifier("allKudos.root")` is set on the outer `ZStack`, SwiftUI propagates it to every descendant. Inner declarations like `allKudos.backButton` get shadowed by the parent identifier. XCUI cannot target ~6 nested elements by their declared ID. 

**Workaround:** Anchor assertions on deterministic mock data instead — e.g., `.exists("Cảm ơn..." card body text)` for the first feed card.

**No fix applied:** This is SwiftUI's design; changing container identifier names would require production edits across Kudos tab + All Kudos screen.

### 2. NavigationStack cold-start latency on parallel simulator clones

Initial XCUI test timeout was 5s. During review, tests hung on NavigationStack push under parallel-clone execution. Empirical worst case: 31s (network I/O on cold clones, view lifecycle overhead). 

**Fix applied:** Timeout raised from 15s → 30s in both `KudosTabUITests.swift` and new `AllKudosScreenUITests.swift`. Future tests should default to 25–30s for any navigation assertion on simulator clones.

## Reviewer findings (6.5/10 APPROVE_WITH_FIXES)

**Major:**
1. NavigationStack timeout too short — fixed (15s → 30s).
2. Feed-render assertion was tautological (test setup already proved card exists) — assertion rewritten to validate **count > 0 AND first card text matches mock data**.

**Minor:**
3. Stale comment referencing deleted helper function — removed.
4. `.exists` check on scrollable feed should use `.isHittable` (more robust) — changed.

**Info (no action):**
5. AccessibilityIdentifier shadowing documented in PR comments.
6. Deferred items have explicit unblocking criteria in plan.md.

All 4 actionable findings were fixed during session.

## Deferred (concrete unblocking criteria in plan.md)

- **Pagination scroll-bottom test:** `MockKudosRepository.kudosFeed` has 3 items. State transitions to `.endOfList` immediately; no loading spinner to assert. Unblock by expanding fixture to ~20 items (risk: breaks 3 existing Kudos tab UI tests).
- **Empty-state test:** Requires new `-uiTestMode .allKudosEmpty` scenario wiring a mock returning `[]`. Cross-cutting; deferred to follow-up.
- **Initial loading spinner test:** Async race — spinner mounts/unmounts in same SwiftUI commit when mock is sync. Unit-tested; visual assertion deferred.
- **Like-state sync E2E:** `KudosCard.swift` has no `accessibilityIdentifier` on like button. Cannot target from XCUI without production edit (cross-screen impact). Unit-tested in `KudosViewModelLikesAllFeedSyncTests`.

## Lessons worth keeping

**1. Identifier shadowing is sneaky.** When parent container has an ID, inner element IDs are rendered dead weight in XCUI. Don't declare them expecting to use them. Anchor on stable text labels or DOM position instead.

**2. Simulator cold-start adds 15–30s latency.** Default 5–10s timeouts are insufficient under parallel-clone execution. New baseline: 25–30s for navigation, 15s for modal dismissals.

**3. Tautological tests add no signal.** Easy to write an assertion that just re-proves what the test setup already confirmed. Every assertion in the test body must check something the setup didn't.

**4. Vietnam timezone historicity matters.** `TimeZone(identifier: "Asia/Saigon")` honors pre-1975 UTC+8. Epoch timestamp assertions need account for this if they cross the 1975-06-13 boundary.

## Files changed (no production code)

```
saaTests/Features/Kudos/
  └─ AllKudosCardAdapterTests.swift (new, 201 LOC)

saaUITests/
  ├─ AllKudosScreenUITests.swift (new, 191 LOC)
  ├─ KudosTabUITests.swift (timeouts: 15s → 30s)
  └─ KudosUI_Helpers.swift (no change)

docs/
  └─ project-changelog.md (updated: test coverage entry)
```

Full plan: `plans/260629-0934-all-kudos-tests/plan.md`
