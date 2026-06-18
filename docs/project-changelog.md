# Project Changelog

All significant changes to the SAA iOS app. Newest first.

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
