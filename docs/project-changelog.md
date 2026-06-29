# Project Changelog

All significant changes to the SAA iOS app. Newest first.

---

## [feature/all-kudos] — 2026-06-29 — Test hardening (tests only)

### All Kudos: unit + UI test expansion

**Plan:** [`plans/260629-0934-all-kudos-tests/`](../plans/260629-0934-all-kudos-tests/plan.md)

**What shipped:**
- 9 new unit tests: `saaTests/Features/Kudos/Presentation/KudosCardAdapterTests.swift` (201 LOC) — covers `cardData(from:departments:)` adapter across nil/missing/matched department, star-tier mapping, hashtag assembly, and reaction state
- 5 new XCUITests: `saaUITests/AllKudosScreenUITests.swift` — covers initial load, pagination trigger, like toggle, empty state, and navigation back; documents pre-existing SwiftUI accessibility-identifier propagation quirk in `AllKudosView` (not introduced here)
- Zero production code changes; full suite green (393 passing)
- CI: added `-retry-tests-on-failure -test-iterations 3` to `xcodebuild test` in `.github/workflows/ios-tests.yml`; resolves flaky UI test failures (run #28360918205 green after #28357941117 failed)

---

## [feature/all-kudos] — 2026-06-28

### All Kudos full-page screen with paginated infinite scroll, like propagation, and DRY card adapter

**Plan:** [`plans/260627-1813-all-kudos-screen/`](../plans/260627-1813-all-kudos-screen/plan.md)

**What shipped:**
- New `AllKudos/` directory under `Kudos/Presentation/`: `AllKudosViewContainer`, `AllKudosView`, `AllKudosFeedList`, `KudosCardAdapter`
- `KudosViewContainer` wrapped in `NavigationStack`; `KudosViewContainer.Route` enum (`case all`); `onViewAllKudos` pushes `.all`; `AllKudosViewContainer` mounted as `navigationDestination`
- `KudosViewModel+AllFeed.swift` extension: `allFeed: [Kudos]`, `allFeedLoadState: AllFeedLoadState`, `loadAllFeedInitial`, `loadAllFeedMore`, `resetAllFeed`; paginated via `repository.fetchKudosFeed` (bypasses `LoadKudosScreenUseCase`)
- `repository: any KudosRepositoryProtocol` added to `KudosViewModel` constructor; `AllFeedLoadState` enum added to `KudosViewModel`
- `KudosViewModel+Likes` extended to propagate like/unlike into `allFeed` alongside `feed` and `highlights`
- `KudosCardAdapter.swift` extracted: `cardData(from:departments:)` shared between `KudosViewContainer` and `AllKudosViewContainer` (removed duplicate static helper from `KudosViewContainer`)
- `copyLink` extended to search `allFeed` as third fallback

**Localization:** 1 key added — `kudos.allKudos.title` (EN + VI)

**Tests:** 16 new unit tests; full suite green (384 passing)

---

## [feature/create-kudos] — 2026-06-24

### Create Kudos compose flow with multi-image upload, hashtag picker, anonymous mode, and full TC coverage

**Plan:** [`plans/260624-0907-create-kudos/`](../plans/260624-0907-create-kudos/plan.md)

**What shipped:**
- Replaces `WriteKudoFormStubView` with a live, fully-wired Create Kudos compose flow
- Domain: `CreateKudoRequest`, `CreateKudoValidator`, `CreateKudoFieldError`, `KudosImageUploaderProtocol`, `KudosAttachment`, `KudosImageDraft` added to Kudos domain
- Data: `SupabaseKudosRepository.createKudo`, `SupabaseStorageImageUploader`, `KudosImageResizer`, `CreateKudoMapper`, DTOs (`CreateKudoDTO`, `CreateKudoHashtagDTO`, `CreateKudoAttachmentDTO`); error mapping extended
- Presentation: `CreateKudoViewModel`, `CreateKudoView`, `CreateKudoComposer`, `CreateKudoViewContainer`; child components for recipient, hashtag, image, message, anonymous toggle, markdown toolbar, action bar
- New Supabase tables/storage: `kudos_attachments` table; `kudos-images` Storage bucket; INSERT + DELETE RLS policies on `kudos`, `kudos_hashtags`, `kudos_attachments`; C1 fix migration `20260624090704` adds missing sender delete policy

**Database (5 migrations — `20260624090700`–`20260624090704`):**
- `kudos_attachments` table (FK → `kudos.id`); RLS SELECT to `authenticated`, INSERT/DELETE to row owner
- `kudos-images` Storage bucket with matching RLS INSERT/DELETE policies
- INSERT + DELETE RLS policies added to `kudos` and `kudos_hashtags` (previously SELECT-only for `authenticated`)
- Fix migration: sender-scoped DELETE policy on `kudos` (C1 regression guard)

**Localization:** 42+ `kudos.create.*` keys + 5 `kudos.error.*` keys added (EN + VI)

**Tests:** 368 passing (all suites); UI tests for TC_WRITE_FUN_001 + TC_WRITE_FUN_002 written

---

## [feature/kudos] — 2026-06-23 — Kudos Highlight Card refinement (B.3)

### Kudos card UI: star-tier badges, hashtag overflow, self-like guard

**What changed:**
- `KudosCardData`: `senderRole`/`recipientRole` (`String`) replaced by `senderStarTier`/`recipientStarTier` (`StarTier`); `canLike: Bool` added (TC_FUN_008)
- `KudosCardPersonInfo`: new `KudosStarBadge` view (1–3 gold ★ icons per `StarTier`); removes `KudosRoleBadge` text pill
- `KudosCard`: hashtag row capped at 5 + "…" overflow (TC_GUI_004); heart button disabled when `canLike == false`
- `KudosViewContainer`: adapter passes `StarTier.from(received:)` directly; `starLabel(for:)` helper removed

No domain entities, public API, or database changes. No new dependencies.

---

## [feature/kudos] — 2026-06-19

### Sun*Kudos feature

**Plan:** [`plans/260618-1313-kudos-screen-saa-2025/`](../plans/260618-1313-kudos-screen-saa-2025/plan.md)

**What shipped:**
- Full feature-sliced Kudos module (`Domain` / `Data` / `Presentation`) under `saa/Features/Kudos/`
- Domain: `Kudos`, `KudosUser`, `Department`, `Hashtag`, `KudosReaction`, `UserStats` entities; `KudosRepositoryProtocol`; `KudosError` pure enum
- Data: `SupabaseKudosRepository`, mappers, `KudosErrorMapper`
- Presentation: `KudosViewContainer`, `KudosViewModel` (`@MainActor` `ObservableObject`), all Kudos screens
- `MainTabView` mounts real `KudosViewContainer` (replaces `KudosTabStubView`); cross-tab nav from `HomeView.onKudosDetail` → `HomeViewContainer.activeTab = .kudos`
- Composition root split: `saaApp+KudosSetup.swift` + `saaApp+HomeSetup.swift` to keep each ≤ 80 LOC

**Database (9 migrations):**
- 7 new tables: `departments`, `hashtags`, `kudos`, `kudos_hashtags`, `kudos_reactions`, `user_stats`, `event_bonuses`
- `profiles` altered: `department_id` foreign key added
- All 7 tables RLS-protected (SELECT to `authenticated`; writes `service_role` only; `user_stats` SELECT restricted to row owner)
- 3 PL/pgSQL triggers: profile→user_stats bootstrap, kudos insert→sent/received counts, kudos_reactions↔sender hearts

**Localization:** 34 `kudos.*` keys added to `Localizable.xcstrings` (EN + VI)

**Tests:** 227 passing across all suites; new files under `saaTests/Features/Kudos/Domain|Data|Presentation/` + 2 new doubles in `saaTests/Doubles/`

---

## [feature/home] — 2026-06-17 — Awards refinement

### Home Awards: 6 categories + snap-paging carousel

**What changed:**
- `supabase/seeds/dev/seed-awards.sql` — seed expanded from 4 to 6 awards; added `top_manager` and `top_mentor` categories
- `HomeMockData.swift` — `previewAwards` fixture updated to match (6 entries)
- `HomeAwardsSection.swift` — `loadedCardsView` now uses `ScrollView` with `.scrollTargetBehavior(.viewAligned)` snap-paging and a peek offset on iOS 17; falls back to free-scroll on iOS 16

No changes to Domain, Data, ViewModel, or integration layers. No new migrations.

---

## [feature/home] — 2026-06-16

### SAA 2025 Home screen

**What shipped:**
- Full feature-sliced Home module (`Domain` / `Data` / `Presentation`) under `saa/Features/Home/`
- `Award` entity, `AwardsRepositoryProtocol`, `AwardsError` domain enum
- `SupabaseAwardsRepository` backed by `public.awards` table; `AwardMapper` + `AwardsErrorMapper`
- `HomeViewModel` fetches awards on appear, drives `AwardsState` (loading / loaded / empty / error)
- `HomeView` / `HomeViewContainer` / `HomeAwardsSection` / `HomeKudosSection` (feature-flagged)
- `MainTabView` is now the signed-in root (HomeView on tab 0; stub screens for Kudos, Awards, Profile, Notifications tabs)
- `AccessDeniedView` — shown when `AuthSessionStore.isAccessDenied` is true while session exists
- `AppRouter` gains `.accessDenied` route; gate order: spinner → accessDenied → home → login
- `Countdown` component — displays days/hours/mins to SAA event date; clamps to zero
- `FeatureFlags` — compile-time `isKudosAvailable` flag controlling Kudos section visibility
- `LanguageSelectionSheet` on Home header for EN / VI switching
- Localizable.xcstrings: 36 keys added (`home.*`, `accessDenied.*`, `home.stub.*`) in EN + VI

**Database:**
- Migration `20260615161000_create_awards_table.sql` — `public.awards` table
- Migration `20260615161001_awards_rls.sql` — Row-Level Security policies
- Rollback script provided

**Tests:** 136 green (109 unit + 27 UI)
- New: `HomeViewModelTests`, `AwardsErrorMappingTests`, `CountdownTests`, `AwardsRepositoryFake`, `LocalizationKeysExistTests`

**Deferred:** TC_GUI_005 Kudos-hidden UI test — static `FeatureFlags` constant; deferred to future plan

---

## [refactor/clean-architecture] — 2026-06-14

### Clean Architecture refactor

Dissolved the `AuthService` god-object into feature-sliced layers. Full narrative in `docs/journals/2026-06-14-clean-architecture-refactor-shipped.md`.

**What shipped:**
- `AuthSessionStore` (Core/Session) — session SoT as `@EnvironmentObject`
- `LoginViewModel` (Presentation) — sign-in state, delegates to use case
- Use cases: `SignInWithGoogleUseCase`, `RestoreSessionUseCase`, `SignOutUseCase`
- Repositories/services: `SupabaseAuthRepository`, `GoogleSignInService`, `UserSessionMapper`, `AuthErrorMapper`
- `AuthSessionClearable` protocol seam in Domain (avoids Core import from Domain)
- DEBUG-only `NoopAuthRepository` / `NoopGoogleSignInService` for UI-test composition path
- `App/` / `Features/` / `Core/` / `Shared/` top-level structure; 16 file relocations
- Test count: 50 → 63, zero regressions

---

## [feature/google-oauth] — 2026-06-10

### Google OAuth + Supabase sign-in

Initial Login flow. Full narrative in `docs/journals/2026-06-10-login-google-supabase-saa.md`.

**What shipped:**
- Google Sign-In SDK integration with nonce generation
- `SupabaseAuthRepository` backed by `SupabaseClientProvider`
- `LoginView` / `LoginViewModel` with error handling
- `AppRouter` (spinner / login / home switch)
- `LanguagePicker` + `CountryFlag` shared components
- 38-test login regression net (unit + UI)
