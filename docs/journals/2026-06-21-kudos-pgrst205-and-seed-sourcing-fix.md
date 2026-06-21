# Kudos — PGRST205 fix + dev seed auto-sourcing

**Date:** 2026-06-21
**Branch:** `feature/kudos`
**Test status:** N/A — procedural + config fix; no Swift tests touched
**Commits landed:** 0 (uncommitted — awaiting user seal)
**Session shape:** `/fix-bug` quick cycle — survey → diagnose → repair → verify → prevent

## What landed

**Repair:** Ran `supabase db reset` to apply the 9 Kudos migrations that had been merged 2 days earlier but never reached the local DB. All 7 new tables (`departments`, `hashtags`, `kudos`, `kudos_hashtags`, `kudos_reactions`, `user_stats`, `event_bonuses`) now resolve through the PostgREST schema cache; the 5 endpoints that were throwing PGRST205 now return HTTP 200.

**Prevention:** Updated `supabase/config.toml` to glob `./seeds/dev/*.sql` directly in `[db.seed].sql_paths`. Before this change, only `seeds/common/*.sql` and `$SUPABASE_EXTRA_SEEDS` were sourced, leaving dev seeds (awards, departments, hashtags, event-bonus, kudos, profiles) silently skipped on every `db reset`. After: a fresh `db reset` populates 6 dev seed files automatically; the kudos seed correctly detects when profiles<2 and gracefully skips.

## Two lessons worth recording

### 1. The exact same defect class re-occurred 4 days after being journaled

`docs/journals/2026-06-17-home-awards-expand-to-six-shipped.md` has a "Follow-up — PGRST205" section describing this exact pattern: migrations on disk but not applied to the local volume because `supabase start` doesn't replay them, only `db reset` or `migration up` does. The Kudos plan even flagged it explicitly: Phase 04's TODO list ended with "Run `supabase db reset` locally; confirm clean apply + RLS active" — left unchecked at delivery as "pending user verification".

Lesson — a deferred-item that survives across sessions is a defect waiting to happen. The Delivery Manifest should have either (a) blocked delivery until the user confirmed the db reset ran, or (b) automated the reset in a postcommit hook. Documenting "pending user verification" is not the same as preventing the consequence.

### 2. A config "fix that fixed nothing" hid behind a UX claim

When I offered `supabase db reset` as the recommended option, the description claimed seeds would populate "automatically." That was wrong: the project's `config.toml` only sources `seeds/common/*.sql` + `$SUPABASE_EXTRA_SEEDS`, and the dev seeds live in `seeds/dev/`. The first run after `db reset` left every table empty, which would have confused any developer who took my description at face value.

This is the second iteration of a familiar shape: configuration that LOOKS right but does nothing observable when wrong. The defense is the same as before — verify the post-condition (row counts > 0), not just the command exit code.

Lesson — when offering options to the user, verify the behavior against the actual config before describing it. Don't paraphrase intent from filenames.

## Deferred (out of scope, no blockers)

- Real profile data: kudos seed defensively skips when profiles<2. To get sample kudos visible in the app, sign in with Google twice (or seed two profiles into `auth.users` manually) then re-run `psql -f supabase/seeds/dev/seed-kudos.sql`. Worth a follow-up note in `supabase/seeds/README.md` if one ever lands.
- Pre-existing leftovers from the previous session not commit yet: one xcassets format change (`kudos-hero-title.imageset/Contents.json`) and one journal file (`2026-06-19-kudos-feature-shipped.md`).
