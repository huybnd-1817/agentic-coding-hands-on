# Sun*Kudos — Phases 04-09 shipped

**Date:** 2026-06-19
**Branch:** `feature/kudos` (plan at `plans/260618-1313-kudos-screen-saa-2025/`)
**Test status:** 227 unit tests green (55 new Kudos + 34 i18n keys-exist + 138 existing un-regressed)
**Commits landed:** 8 (db / kudos×2 / i18n / app / test / docs / chore)
**Session shape:** Single-track execution of an existing plan with reviewer-driven fix pass before commit

## What landed

**Phase 04 — DB schema (Supabase):** 9 migrations, 9 rollbacks, 4 seeds. 7 new tables (`departments`, `hashtags`, `kudos`, `kudos_hashtags`, `kudos_reactions`, `user_stats`, `event_bonuses`) plus `profiles.department_id`. RLS everywhere; `kudos_reactions` enforces own-kudos guard at the policy level (TC_FUN_008). Three triggers wire the stats automatic: profile→user_stats row creation, kudos insert→sent/received counts, kudos_reactions ↔ sender hearts adjustment with `greatest(0, ...)` floor on DELETE.

**Phase 05 — Domain layer:** 11 Foundation-only files. `StarTier.from(received:)` floor-based per the resolved clarification (<10=0, <20=1, <50=2, else 3). `ToggleKudosReactionUseCase` reads `EventBonus.isActive(now:)` for multiplier; `LoadKudosScreenUseCase` runs 7 parallel `async let` fetches into `KudosScreenSnapshot`.

**Phase 06 — Data layer:** 13 files. `KudosMapper` strips sender identity when `is_anonymous=true` AND `sender_id != currentUserId`, but reveals self for "I sent this" rendering. `KudosErrorMapper` covers `PostgrestError` 42501 → `.cannotLikeOwnKudos`, 23505 → `.alreadyLiked`. `MockKudosRepository` `#if DEBUG`-gated at file level.

**Phase 07 — Presentation:** `KudosViewModel` (@MainActor, 214 LOC after access-comment block) with optimistic like + rollback, re-tap-to-clear filters, carousel reset on filter, fire badge gated on active bonus AND `multiplier > 1`, secret-box `inFlight` guard for double-tap. `KudosViewContainer` bridges Domain → existing presentational structs without modifying `KudosView` (memberwise init absorbed the new params with defaults).

**Phase 08 — i18n:** 33 `kudos.*` keys + the late-added `kudos.error.alreadyLiked` (from reviewer fix). Vi + en, no `needs_review`. Keys-exist test uses locale-direct `lproj` lookup for determinism — the project's existing `Bundle.main + String(localized:)` pattern silently no-ops on iOS 26 simulator.

**Phase 09 — Integration + tests:** Composition root extracted helpers (`saaApp+KudosSetup.swift`, `saaApp+HomeSetup.swift`) to keep `saaApp.swift` at exactly 80 LOC. `MainTabView` mounts real `KudosViewContainer`; `HomeViewContainer.activeTab` binding wires the Home banner's `onKudosDetail` to switch to the Kudos tab. 20 LocalizedStringKey swaps. Doubles: `KudosRepositoryFake` (behavior enums + counters + last-arg recording), `KudosClipboardServiceFake`. Manual TC run sheet authored for 38 in-scope cases.

## Four lessons worth recording

### 1. PostgREST nested aggregates don't accept `.order()` by their alias

`fetchHighlightKudos` originally tried `.order("reactions.count", referencedTable: ...)` against an aggregated nested relation. PostgREST does not validate this at compile time — the query silently returns unsorted rows (or 400s on some versions). The reviewer's "unverified runtime concern" flagged it before it hit a staging environment.

Fix: fetch a larger bounded set (50 rows), then sort client-side by `heartCount` descending and take the top 5. The carousel is N=5 — client sort is essentially free. Documented in a code comment so the next developer doesn't restore the broken `.order()` thinking it was an oversight.

### 2. PostgREST returns nested resources as objects, not their inner scalar

The original select clause `kudos_received_count:user_stats(kudos_received_count)` looks like a scalar projection. PostgREST actually returns `{ kudos_received_count: N }` — a nested object. The DTO declared `let kudos_received_count: Int?` and decode failed silently in a `try?` path → StarTier always 0 on every card.

Fix: introduce `KudosProfileUserStatsDTO` as a nested type and read through `profile.userStats?.kudosReceivedCount`. The added unit test exercises the nested decode path, catching any future regression at the mapper boundary, not at runtime on real Supabase.

### 3. `@MainActor` ObservableObject tests must be `async` even when nothing awaits

`testDismissPhoto_clearsPhoto` crashed in 0.000s — no assertion failure, no message. `code-standards.md` already documents this: "@MainActor ObservableObjects need `async` test methods to avoid SIGABRT from MainActor dealloc races." The tester subagent missed the rule for one test (the photo-viewer pair) while every other VM test in the suite was correctly `async`.

Fix: convert both photo tests to `async`. Lesson — when writing tests for a `@MainActor` class, default every method to `async`, not "async only if awaiting something." The dealloc race fires after the body executes, not from awaiting.

### 4. The reviewer-fix loop is cheap insurance

Reviewer flagged four HIGH issues before commit: two were latent runtime bugs (HIGH-1, HIGH-2 above), one was a hard-cap violation (`saaApp.swift` at 113 LOC vs 80 LOC cap), one was a messageKey collapse (`alreadyLiked` resolved to `unknown`). All four were fixable in a single 30-min implementer pass with 7 new tests added. None of them would have been caught by the build, by the existing test suite, or by reading the diff.

Lesson — for any feature that touches a new database/SDK path, a reviewer adversarial pass before commit pays for itself. The cost (one extra subagent invocation) is small compared to a runtime bug surfacing in staging or worse, production.

## Deferred (out of scope, no blockers)

- Spotlight Board interactive network chart + Sunner search (B.6/B.7) — placeholder card.
- Secret Box open animation + reward reveal — "Coming soon" toast.
- Send Kudos compose flow — routes to existing `WriteKudoFormStubView`.
- Kudos detail screen + profile navigation — route to existing stubs.
- XCUITests for Kudos — manual TC run sheet only.
- `supabase db reset` local manual verification — pending user execution.
- Five reviewer nits (NIT-1/3/5/7/8) — observational tradeoffs documented in the reviewer report.

## What I'd do differently next time

- **Run the reviewer earlier.** Adversarial review caught two latent runtime bugs (PostgREST quirks). Running the reviewer right after phase 06 (the data layer) instead of after the full feature would have caught them before integration tests built atop the broken assumptions.
- **Re-read `code-standards.md` between phases.** The dealloc-race rule and the layer-import rule are both in there. A subagent missed the dealloc rule despite a direct link to the doc in the prompt — explicit single-rule reminders in the prompt would help.
- **Keep the `+Likes` extension file or don't.** The split traded one `private` setter for an `internal` setter to allow the extension to mutate state. Decision: kept the split with a documented rationale comment, on the bet that future like-related logic (history, multi-like reactions) lands in the extension. If that doesn't happen by year-end, consolidate.
