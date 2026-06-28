# Development Roadmap

## Project: SAA iOS App

### Phases

| # | Phase | Status | Shipped |
|---|-------|--------|---------|
| 1 | Google OAuth + Supabase sign-in (Login flow) | Complete | 2026-06-10 |
| 2 | Clean Architecture refactor (Feature-sliced, 3-layer) | Complete | 2026-06-14 |
| 3 | SAA 2025 Home screen (Awards, Kudos, Access Denied) | Complete | 2026-06-16 |
| 4 | Sun*Kudos feature (full implementation, replaces stub screens) | Complete | 2026-06-19 |
| 5 | Create Kudos compose flow (multi-image upload, hashtag picker, anonymous mode) | Complete | 2026-06-24 |
| 6 | All Kudos full-page screen (paginated feed, like propagation, DRY card adapter) | Complete | 2026-06-28 |

---

### Phase 3 — SAA 2025 Home Screen

**Branch:** `feature/home`
**Shipped:** 2026-06-16

#### Scope
- Feature-sliced Home module: `Domain` (Award entity, AwardsRepositoryProtocol, AwardsError), `Data` (SupabaseAwardsRepository, mappers), `Presentation` (HomeView, HomeViewModel, HomeAwardsSection, HomeKudosSection, MainTabView, AccessDeniedView, etc.)
- Supabase `public.awards` table with RLS (migrations `20260615161000`, `20260615161001`)
- AppRouter gains `.accessDenied` route; `AuthSessionStore` gains `isAccessDenied`
- `MainTabView` is the signed-in root; `HomeViewContainer` is on tab 0
- Localizable.xcstrings: 36 keys added (EN + VI) for `home.*`, `accessDenied.*`, `home.stub.*`
- Countdown component (clamps to zero — event date 2025-12-26 is past)
- Awards expanded to 6 categories (`top_manager`, `top_mentor` added); `HomeAwardsSection` uses snap-paging carousel with peek on iOS 17, free-scroll fallback on iOS 16
- 136 tests green (109 unit + 27 UI)

#### Deferred
- TC_GUI_005 (Kudos-hidden UI test) — `FeatureFlags.isKudosAvailable` is a static constant; runtime toggling deferred to a future plan

---

---

### Phase 4 — Sun*Kudos Feature

**Branch:** `feature/kudos`
**Shipped:** 2026-06-19
**Plan:** [`plans/260618-1313-kudos-screen-saa-2025/plan.md`](../plans/260618-1313-kudos-screen-saa-2025/plan.md)

#### Scope
- Full feature-sliced Kudos module (`Domain` / `Data` / `Presentation`) under `saa/Features/Kudos/`
- 7 new Supabase tables: `departments`, `hashtags`, `kudos`, `kudos_hashtags`, `kudos_reactions`, `user_stats`, `event_bonuses`; `profiles` altered to add `department_id`
- 9 migrations; all 7 tables RLS-protected (SELECT to authenticated, writes service_role only; `user_stats` SELECT restricted to row owner)
- 3 PL/pgSQL triggers: profile→user_stats bootstrap, kudos insert→sent/received counts, kudos_reactions↔sender hearts
- Composition root extracted: `saaApp+KudosSetup.swift` + `saaApp+HomeSetup.swift` (≤ 80 LOC each)
- `MainTabView` mounts real `KudosViewContainer`; cross-tab nav from `HomeView.onKudosDetail` → `HomeViewContainer.activeTab = .kudos`
- Localizable.xcstrings: 34 keys added (`kudos.*`) in EN + VI
- Tests: 227 passing (all suites); new Kudos test files under `saaTests/Features/Kudos/Domain|Data|Presentation/` + 2 new doubles

---

### Phase 5 — Create Kudos Compose Flow

**Branch:** `feature/create-kudos`
**Shipped:** 2026-06-24
**Plan:** [`plans/260624-0907-create-kudos/`](../plans/260624-0907-create-kudos/plan.md)

#### Scope
- Replaces `WriteKudoFormStubView` with a live Create Kudos compose flow
- Domain additions: `CreateKudoRequest`, `CreateKudoValidator`, `CreateKudoFieldError`, `KudosImageUploaderProtocol`, `KudosAttachment`, `KudosImageDraft`
- Data additions: `SupabaseKudosRepository.createKudo`, `SupabaseStorageImageUploader`, `KudosImageResizer`, `CreateKudoMapper`, new DTOs; error mapping extended
- Presentation: `CreateKudoViewModel`, `CreateKudoView`, `CreateKudoComposer`, `CreateKudoViewContainer`; recipient + hashtag dropdowns, image picker, markdown toolbar, anonymous toggle, action bar
- 5 new Supabase migrations: `kudos_attachments` table, `kudos-images` Storage bucket, INSERT/DELETE RLS on `kudos` + `kudos_hashtags` + `kudos_attachments`, C1 fix migration for sender-scoped DELETE
- Localizable.xcstrings: 42+ `kudos.create.*` + 5 `kudos.error.*` keys (EN + VI)
- Tests: 368 passing; UI tests for TC_WRITE_FUN_001 + TC_WRITE_FUN_002

---

---

### Phase 6 — All Kudos Screen

**Branch:** `feature/all-kudos`
**Shipped:** 2026-06-28
**Plan:** [`plans/260627-1813-all-kudos-screen/`](../plans/260627-1813-all-kudos-screen/plan.md)

#### Scope
- New `AllKudos/` directory under `Kudos/Presentation/`: `AllKudosViewContainer`, `AllKudosView`, `AllKudosFeedList`, `KudosCardAdapter`
- `KudosViewContainer` wraps content in `NavigationStack`; `onViewAllKudos` pushes `Route.all`
- `KudosViewModel+AllFeed.swift` extension: `allFeed`, `allFeedLoadState`, `loadAllFeedInitial`, `loadAllFeedMore`, `resetAllFeed`; calls `repository.fetchKudosFeed` directly (bypasses `LoadKudosScreenUseCase`)
- `repository` dependency added to `KudosViewModel` constructor (was already owned by the Data layer; now exposed to Presentation via widened `internal` access)
- Like-toggle propagation extended to `allFeed` (in `KudosViewModel+Likes`)
- `KudosCardAdapter.swift` extracted: card-mapping helpers shared between `KudosViewContainer` and `AllKudosViewContainer` (DRY)
- Localizable.xcstrings: 1 key added (`kudos.allKudos.title`, EN + VI)
- Tests: 16 new unit tests; full suite green (384 passing)

---

### Upcoming

- `@Observable` macro migration (replaces `ObservableObject` / `@Published`)
- SwiftPM local-package split per feature (revisit when 6th feature lands)
- Remote feature flags via Supabase `app_config` table
