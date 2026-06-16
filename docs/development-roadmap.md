# Development Roadmap

## Project: SAA iOS App

### Phases

| # | Phase | Status | Shipped |
|---|-------|--------|---------|
| 1 | Google OAuth + Supabase sign-in (Login flow) | Complete | 2026-06-10 |
| 2 | Clean Architecture refactor (Feature-sliced, 3-layer) | Complete | 2026-06-14 |
| 3 | SAA 2025 Home screen (Awards, Kudos, Access Denied) | Complete | 2026-06-16 |

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
- 136 tests green (109 unit + 27 UI)

#### Deferred
- TC_GUI_005 (Kudos-hidden UI test) — `FeatureFlags.isKudosAvailable` is a static constant; runtime toggling deferred to a future plan

---

### Upcoming

- `@Observable` macro migration (replaces `ObservableObject` / `@Published`)
- SwiftPM local-package split per feature (revisit when 4th feature lands)
- Kudos feature (full implementation, replaces stub screens)
- Remote feature flags via Supabase `app_config` table
