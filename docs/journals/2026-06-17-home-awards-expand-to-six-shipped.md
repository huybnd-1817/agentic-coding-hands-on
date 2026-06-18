# Home Awards — Expand to six with snap-paging carousel

**Date:** 2026-06-17
**Branch:** `feature/home` (plan at `plans/260616-1749-home-awards-expand-to-six/`)
**Test status:** 135 tests green (108 unit + 27 UI integration), 1 unrelated pre-existing failure
**Commits landed:** 2 (seed data + awards carousel refinement → docs)
**Session shape:** Single-track refinement; reviewer catch on visual correctness

## What landed

**Phase 01 (Seed Data):** Awards table seeded with 6 items (4→6) for `top_manager` and `top_mentor` in `supabase/seeds/dev/seed-awards.sql` and `HomeMockData.swift` preview fixtures. Enables carousel testing with realistic repetition.

**Phase 02 (Carousel UX):** `HomeAwardsSection.loadedCardsView` rewritten as `@ViewBuilder` with iOS 16/17 divergence. iOS 17+ branch uses `.scrollTargetLayout()` + `.scrollTargetBehavior(.viewAligned)` + `.contentMargins(.horizontal, 20, for: .scrollContent)` + `.scrollClipDisabled()` for snap-aligned paging. iOS 16 fallback retains original `padding(.horizontal, 20)` free-scroll. Introduces the project's first `#available` gate with `@ViewBuilder` to avoid AnyView erasure.

**Phase 03 (Build):** 135/136 tests green. One pre-existing failure in `testLanguagePickerOpensInlineDropdown` surfaced on feature/home HEAD, unrelated to this change.

Total: 3 source files modified, 5 plan artifacts, 2 commits.

## Three lessons worth recording

### 1. `.scrollClipDisabled()` is load-bearing when you inset content margins

Initial build passed, 135 tests green, but the iOS 17 branch rendered *identically* to the iOS 16 fallback — no snap-paging, free-scroll behavior everywhere. The reviewer flagged this as M1 medium: visual silent failure.

Root cause: `.contentMargins(.horizontal, 20)` insets the ScrollView's content layout, but the ScrollView itself still clips to its own bounds. Without `.scrollClipDisabled()`, the margin inset is invisible to the eye (content overlaps frame edge anyway). The snap-paging `.scrollTargetBehavior(.viewAligned)` has nothing to visually align against.

Lesson: ScrollView margin/padding semantics are non-intuitive. When you use `.contentMargins()` to inset for visual safety, you *must* disable frame clipping to make the inset visible. Read the behavior, not the name. This gets written as a comment on that line because it's non-obvious the next developer.

### 2. Pre-existing test failures can hide on feature branches

`testLanguagePickerOpensInlineDropdown` fails on `feature/home` HEAD independent of this change. Verified by stashing the awards work, running tests in isolation, and confirming the failure persists. Root is likely the sequence: commit f304905 (LanguageSelectionSheet modal removed) + commit ea63f6b (LanguagePicker integrated into MainTabView). 

XCUITest hit-testing on the LanguagePicker's wrapper view may have become fragile when it lost its modal boundary. Filed as out-of-scope follow-up — warrants its own investigation thread, not bundled with awards expansion.

Lesson: When test results change mid-branch, stash your work and re-run the suspect test in isolation before attributing it to your changes. Prevents false blame and keeps the audit trail clean.

### 3. iOS 16 back-deployment introduces a new pattern: `#available` gates with `@ViewBuilder`

This is the project's first iOS 17+ conditional View implementation. No precedent existed for how to structure it without AnyView erasure. The `@ViewBuilder` pattern allows divergent View types per branch (one branch returns a VStack, another returns a ScrollView) without type erasure.

Consequence: future iOS 17+ adoptions can follow this shape. Worth documenting in codebase standards as the blessed pattern — keeps code clean and avoids the performance tax of AnyView wrapping.

## What I'd do differently next time

- **Visual validation after build.** Build green + tests green is not sufficient when you're refining visual UX. Immediately run the app on iOS 17 simulator after the first green build, inspect the carousel behavior frame-by-frame. Catch the `.scrollClipDisabled()` gap at implementation time, not reviewer time.
- **Isolate test failures early.** When you see a test fail on a feature branch, stash immediately and re-run. Saves time chasing false leads.
- **Document ScrollView margin gotchas.** This is a subtle behavior. Add a comment linking to the Apple docs or a code explanation so the next developer doesn't rediscover it.

## Deferred (out of scope, no blockers)

- `testLanguagePickerOpensInlineDropdown` failure — separate investigation task filed.
- Expand `.available` gate coverage to other iOS 17+ APIs as discovered (e.g., `NavigationStack` behaviors differ; `.matchedGeometryEffect` performance characteristics vary).

## Follow-up — PGRST205 at runtime, two-layer root cause

Running the app after the takumi commits surfaced `PostgrestError code: PGRST205 — Could not find the table 'public.awards' in the schema cache`. Diagnosed and repaired in a `/fix-bug` pass. Commit: `940400e fix(supabase): relocate rollback scripts out of migrations dir`.

**Layer 1 (immediate):** Local Supabase volume had been running since before the awards migrations existed. `supabase start` does not replay new migrations on existing volumes — only `migration up` / `db reset` does. The awards table simply was never created locally.

**Layer 2 (latent — the real bug):** `supabase migration up` failed with `relation "public.awards" does not exist`. The CLI sorts every `<timestamp>_name.sql` in `migrations/` lexicographically; `.rollback.sql` lexicographically sorts BEFORE `.sql` (because `.r` < `.s`). The two `*.rollback.sql` files in `supabase/migrations/` were being applied as forward migrations BEFORE their counterparts, dropping tables that didn't exist yet. This had been latent on the branch since the awards migration commit — only surfaced now because no one had `migration up`-d locally since.

**Fix:** Moved the two rollback files to a new `supabase/rollbacks/` directory. Documented the convention in both READMEs.

### Lesson — file conventions become bugs in declarative tooling

A naming convention that's "obvious to humans" (`.rollback.sql` is clearly documentation, not a migration) is invisible to tooling that operates on glob patterns. The Supabase CLI sees a file matching `<timestamp>_name.sql` and treats it as a migration; the human notion of "this one's a rollback, skip it" doesn't exist. When you invent a convention, ask: does the tool processing this directory know about it? If not, the convention is a trap.

This also taught me: when `supabase migration up` failed with a confusing error (`relation does not exist` when trying to apply *new* migrations), the right move was to check `ls supabase/migrations/` and notice the rollback files there — not to immediately reach for `db reset` (which would have masked the underlying issue and reset all dev data). Read the migration apply order before doing anything destructive.

### Lesson — the iOS app's PGRST205 error mapper fell through to `.unknown`

`AwardsErrorMapper.swift` handles 4 cases: AwardsError pass-through, URLError → network, PostgrestError 42501 → forbidden, AuthError 401/403. PGRST205 (table missing) falls to `.unknown(underlying:)` and prints the DEBUG log line that surfaced the bug. Could add a specific case for PGRST205 → `.serverMisconfig` or similar, but that's gold-plating — the bug should never reach production. Filed as low-priority enhancement.

## Follow-up — canonical awards catalogue replacement

Late same-session, user supplied the official SAA 2026 award list (6 categories with rich Vietnamese descriptions) and asked to replace the dev-placeholder catalogue. Commit: `cfa987c feat(home): update awards catalogue to canonical SAA 2026 six`.

**Changes:**
- `seed-awards.sql` — rewrote to delete-then-upsert pattern. Removed 4 placeholder codes (`top_culture_fit`, `top_new_sunner`, `top_manager`, `top_mentor`). Added 4 canonical codes (`top_project_leader`, `best_manager`, `signature_2026_creator`, `mvp`). Long bilingual descriptions verbatim from the supplied copy; English translations preserve tone and structure of the Vietnamese originals.
- `HomeMockData.swift` — preview fixture mirrors the 6 new codes with short EN/VI subtitle copy suitable for the 140pt-wide card.

### Lesson — delete-then-upsert beats raw upsert for canonical lists

Earlier seed file used pure `INSERT … ON CONFLICT DO UPDATE`. That pattern adds and updates but never removes — so when the canonical list shrinks (or codes get renamed), the DB drifts to a superset of the seed. Switched to `DELETE WHERE code NOT IN (canonical_set) + UPSERT`. Now `\dt` after seed always returns exactly the canonical list, regardless of prior state. Two extra DDL lines, zero drift.

### Lesson — translate EN descriptions on write, not later

User supplied Vietnamese only. Tempting to leave EN columns empty (NOT NULL → can't) or paste Vietnamese into the EN column. Both betray the i18n design. Wrote the English translations inline matching the Vietnamese tone, marked the work done. "I'll translate later" is the path to permanent placeholder copy in English-locale builds.

## Follow-up — Kudos + Awards visual alignment with Figma

Same-session after the carousel work + canonical 6-awards landed, user invoked `/momorph-implement-design` against the same Figma frame (`9ypp4enmFmdK3YAFJLIu6C / OuH1BUTYT0`) to fix two visual gaps: Kudos description block and the award card. Commit: `bc860f5 fix(home): align Kudos description and Awards card with Figma`.

### Gaps found via MCP `query_section`

**Kudos `mms_5_kudos / note / txt`** — Figma uses a SINGLE 14pt Montserrat 300 text node with "ĐIỂM MỚI CỦA SAA 2025\n[body]". Current code split it into bold title + light body. The bold weight existed nowhere in the design — it was a developer interpretation.

**Award card `Top Talent Award` component (`6885:8051`)** — current AwardCardView was significantly off the design across every dimension that matters: 140×120 vs 160×298, generic trophy SF Symbol vs centered gold name with gold border + gold glow, semibold white title vs medium gold title, missing per-card "Chi tiết" button. Essentially every property except the existence of a card differed.

### What changed
- `HomeKudosSection.swift` — collapsed `description` to one `Text` view, weight 300. Dropped the bodyTitle subview entirely.
- `Localizable.xcstrings` — folded the "ĐIỂM MỚI CỦA SAA 2025" / "NEW FOR SAA 2025" prefix into `home.kudos.body` with embedded `\n`. Removed the orphan `home.kudos.bodyTitle` key.
- `AwardCardView.swift` — full rewrite: 160×298 card, 160×160 picture block with 0.455 gold border (`#FFEA9E`), 11.429 corner radius, gold-glow shadow (`#FAE287` outer, dark drop shadow inner), centered trophy SF + uppercase gold award name. Below: gold medium name + 3-line light description. Per-card "Chi tiết" button (white label + gold arrow) is now the only tap target — picture and text are decorative. Init param renamed `onTap` → `onDetailTap`; existing call sites use trailing-closure syntax so they recompile without source changes.

### Lesson — Figma's box-shadow has two equally important purposes

The picture's Figma spec carried two shadows: `0 1.905px 1.905px rgba(0,0,0,0.25)` (subtle drop shadow giving the card depth on the dark background) AND `0 0 2.857px #FAE287` (gold halo making the card feel "lit"). Implementing only the drop shadow looks correct but feels lifeless. Implementing only the halo looks too floaty. Both together is what gives the card its trophy-like feel. Layered SwiftUI `.shadow()` modifiers stack — apply both.

### Lesson — trailing-closure syntax is forgiving

Rewriting `AwardCardView`'s API from `onTap` to `onDetailTap` was a public-surface change, but call sites in `HomeAwardsSection.swift` used trailing-closure syntax (`AwardCardView(award: award) { ... }`) which binds to the last parameter by position, not by name. Zero call-site edits. Useful when API rename is a public-surface improvement but rippling through callers would explode the diff. Conversely: if you ever want to make a rename forcibly painful (e.g. you removed semantics), name the trailing closure differently — keyword args force the issue.

### Lesson — when picking from limited assets, normalize, don't fork

Figma had per-award gold-text logos prepared for only Top Talent + Top Project. Tempting to pull those two PNGs and fall back to text for the other 4 — two visual styles in one carousel. User picked instead a single normalized treatment (trophy SF + gold name) for all 6 cards. Cleaner end result and zero per-award asset work. The right move when the design provides a limited subset is to find the common ground the whole collection can share, not to fork the visual treatment based on what art happens to exist.

## Follow-up — wire actual Figma award assets + arrow recolor

Same session, user invoked `/momorph-implement-design` a second time asking for: change kudos banner icon, set Figma's actual award icon image in the carousel, recolor the "Chi tiết" arrow from gold to white. The prior session's "normalize, don't fork" decision got revisited — user reversed it and asked for the Figma logo PNGs to be used where Figma provides them, with the styled-text fallback only for the four codes without prepared art.

Commit: `a988749 fix(home): wire Figma award picture + per-award logos and recolor arrow`.

**What landed:**
- 3 new image assets in `Assets.xcassets/`: `award-picture-bg.imageset` (Figma `MM_MEDIA_Award BG` — dark trophy backdrop), `award-logo-top-talent.imageset`, `award-logo-top-project.imageset` (the two Figma name-logo PNGs).
- `AwardCardView` picture block now uses the BG image as the backdrop (replacing the flat dark `RoundedRectangle`). The 160×160 surface preserves the gold border + gold-glow shadow from the prior pass. Above the BG, a `namePlate` view picks the Figma logo PNG when one exists for the award `code`, otherwise falls back to the styled gold-text rendering. Arrow icon next to "Chi tiết" recolored gold → white.

**Surprise — kudos banner icon was already in sync.** Re-pulled the Figma `MM_MEDIA_Logo/Kudos` SVG to overwrite `home-kudos-logo.svg`. `git status` after the curl: clean. The bytes matched exactly. The asset had been pulled from Figma during the original implementation and never drifted. The user's "change the icon" request was already satisfied — likely a visual mis-recall on their end. No-op confirmed. Worth reporting back so the user can do the visual sanity check themselves on the simulator.

### Lesson — reversed decisions cost less than untouched-but-wrong ones

The "normalize all 6 cards with trophy SF + gold text" decision from earlier this session was a good aesthetic call when no Figma assets were available to pull. The user reversed it 30 minutes later, asking for the Figma assets. The cost of the reversal: 4 file downloads + a ~20-line `namePlate` view + cleanup of one unused color token. The cost of leaving it alone after the user said "the same as figma": permanent divergence between the spec'd design and the implementation. When the user reverses a recent design call, the right reflex is to wire the new direction immediately — the technical cost is almost always lower than the design-fidelity cost of arguing.

### Lesson — confirm asset bytes before swapping; the diff is the proof

Re-fetched the Figma kudos SVG, overwrote in place, expected a non-trivial diff. Got `git status: clean`. The repo's SVG had been Figma-sourced originally and the Figma file hadn't changed since. Without the byte-level check, I would have reported "swapped the Figma SVG in" — accurate but misleading; nothing actually changed. Always confirm the diff is real before claiming work in a commit message.

## Follow-up — text labels over logos, tighter description rows

Third refinement pass same day. User: "title in award icon is not logo, it is label — please change to the same figma" + "decrease the spacing between rows in the description of award". Commit: `bf1dad4 refactor(home): render award titles as text labels and tighten description spacing`.

**Changes:**
- `AwardCardView.namePlate` simplified to a single styled gold-uppercase-text rendering for all 6 codes — removed the per-code switch that branched between Figma PNG overlay (Top Talent + Top Project) and styled-text fallback (other 4). Removed the static `logoAsset(for:)` helper.
- Description `lineSpacing(6)` → `lineSpacing(2)`. The 6 came from Figma's literal 20px line-height with 14px font (delta = 6pt), but SwiftUI's default leading already adds part of that gap — applying the full Figma delta on top stacked the spacing too generously. lineSpacing(2) reads tighter without crowding the descenders.
- `award-logo-top-talent.imageset` and `award-logo-top-project.imageset` deleted from `Assets.xcassets/` via `git rm` — they were added an hour earlier in commit `a988749` and removed now that nothing references them.

### Lesson — Figma values are not always SwiftUI values

The Figma description spec was `font-size: 14px; line-height: 20px`. The naïve translation to SwiftUI was `.font(.system(size: 14)).lineSpacing(6)` — where 6 = 20 − 14. That assumes `lineSpacing` means "extra space added on top of the font size". It doesn't. SwiftUI's `lineSpacing` is extra leading **on top of the platform's default font leading**, which for 14pt is already ~17pt. Stacking 6 more on top yielded ~23pt baselines — visibly too airy. The user caught it visually, not the design spec. Lesson: Figma's CSS-style line-height becomes the SwiftUI line-height when you set `lineSpacing(0)`, not `lineSpacing(line-height - font-size)`. The conversion needs a one-time look at the platform's intrinsic leading before applying the Figma delta.

### Lesson — short-cycle reversals are a feature of fast iteration, not a failure

In one session we (a) normalized 6 cards to styled-text-only, (b) reversed to wire Figma PNGs for the 2 prepared logos + text for 4, (c) reversed again to styled-text-only for all 6. Each pass took ~15-30 min and produced a clean commit. The temptation is to feel embarrassed about the back-and-forth — but the alternative is to argue with the user about which call is right, which is slower and worse for the relationship. Each commit is a self-contained refactor; `git log` reads as a clean exploration of the design space, not chaos. When the user reverses a recent design call cheaply, take the reversal cheaply.

## Follow-up — LanguagePicker chip opacity

User: "Change color of background language dropdown common (not transparent)" against Figma screen `uUvW6Qm1ve`. Two candidate backgrounds in `LanguagePicker.swift`: the **chip** (collapsed trigger button) at `Color.white.opacity(0.08)` — literally translucent — and the **expanded dropdown panel** at `Color.dropdownBackground` (#00070C, fully opaque per Figma `Details-Container-2`). The chip's `opacity(0.08)` value was the smoking gun; the panel had been correctly opaque since the original implementation.

Commit: `044aa13 fix(common): make language picker chip background opaque`. One-line swap: chip now uses the same `Color.dropdownBackground` token as the panel, making the whole component read as one solid surface.

### Lesson — when user-given clarification options conflict, read for intent not selection

Asked the user a two-question disambiguator (chip vs panel + a follow-up about panel-specific fix). Their two answers selected contradictory options — Q1 said "panel" while Q2 explicitly said "skip — chip is the real target". The right move was to trust the more specific signal: "chip is the real target" is an unambiguous statement; the Q1 misclick was the noise. Acting on the Q1 literal answer would have meant tweaking an already-opaque panel and not fixing the actually-transparent chip — opposite of intent. Lesson: read the explanatory text in clarification answers; when it conflicts with the option label, the explanatory text usually carries the truth.

### Lesson — "matches Figma color" is necessary but not sufficient for "looks opaque"

The dropdown panel matches Figma's `Details-Container-2 = #00070C` exactly and is fully opaque. But on a dark page (Home BG is #00101A — almost the same shade), the panel reads as "transparent" because there's no visible boundary against the page. The byte-level color match wasn't the perception-level fix. In this case it didn't matter because the real issue was the adjacent chip. But the lesson generalizes: design tokens are right in isolation, but visual contrast happens at the SCREEN level — the same token can read as "solid" against a colorful Login background and as "ghost" against a uniform Home background. When debugging opacity perception bugs, check the surrounding context, not just the token.

## Follow-up — chip revert + panel shadow

The previous "make chip opaque" call was wrong intent. User clarified: chip should stay translucent (revert `044aa13`); the dropdown LIST panel was the actual target — already-opaque `#00070C` matching Figma, but reading as transparent because near-identical in shade to the page BG. User picked "keep Figma color, add a drop shadow" — strict token fidelity, shadow handles the visual lift.

Commit: `b35a2f1 fix(common): revert chip background and add drop shadow to dropdown panel`. Two changes in one file:
- Chip reverted to `Color.white.opacity(0.08)` translucent.
- Dropdown panel: `.shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 6)` after the clipShape + overlay border. Color unchanged at `#00070C`.

### Lesson — explicit instruction in subagent prompts is the only reliable way to remove the `Co-Authored-By` trailer

The git-manager agent template auto-appended `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>` to all 8 prior commits today, despite the project rule "No AI references in commit messages". The constraint section in the spawn prompts ("No AI / Claude / Anthropic references in commit text") wasn't strong enough — the agent treated the trailer as orthogonal to "references in commit text". For commit `b35a2f1`, I rewrote the constraint explicitly: "DO NOT add any `Co-Authored-By:` trailer" — with bold emphasis and the explicit project-rule citation. That worked. The 9th commit landed clean. Lesson: if you want an agent to suppress a default behavior that lives in its template, name the exact mechanism (the trailer string, not "AI references") and reaffirm it twice in the prompt. Polite phrasing is invisible.
