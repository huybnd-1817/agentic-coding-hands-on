# Project Changelog

All significant changes to the SAA iOS app. Newest first.

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
