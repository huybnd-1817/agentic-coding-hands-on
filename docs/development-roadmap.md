# Development Roadmap

## Project: SAA iOS App

### Phases

| # | Phase | Status | Shipped |
|---|-------|--------|---------|
| 1 | Google OAuth + Supabase sign-in (Login flow) | Complete | 2026-06-10 |
| 2 | Clean Architecture refactor (Feature-sliced, 3-layer) | Complete | 2026-06-14 |
| 3 | SAA 2025 Home screen (Awards, Kudos, Access Denied) | Complete | 2026-06-16 |
| 4 | Sun*Kudos feature (full implementation, replaces stub screens) | Complete | 2026-06-19 |

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

### Upcoming

- `@Observable` macro migration (replaces `ObservableObject` / `@Published`)
- SwiftPM local-package split per feature (revisit when 5th feature lands)
- Remote feature flags via Supabase `app_config` table
