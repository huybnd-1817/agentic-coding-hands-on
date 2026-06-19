-- Rollback for 20260619104608_kudos_rls_and_triggers
-- Drops all triggers, trigger functions, and RLS policies added by that migration.
-- Apply manually via psql or Supabase Studio before rolling back the table migrations.

-- ── Triggers ─────────────────────────────────
drop trigger if exists tr_kudos_reactions_on_insert_delete on public.kudos_reactions;
drop trigger if exists tr_kudos_counts_on_insert           on public.kudos;
drop trigger if exists tr_user_stats_on_profile_insert     on public.profiles;

-- ── Trigger functions ─────────────────────────
drop function if exists public.fn_kudos_reactions_on_insert_delete();
drop function if exists public.fn_kudos_counts_on_insert();
drop function if exists public.fn_user_stats_on_profile_insert();

-- ── RLS policies — kudos_reactions ───────────
drop policy if exists "user can delete own reaction"     on public.kudos_reactions;
drop policy if exists "user can react to others kudos"   on public.kudos_reactions;
drop policy if exists "authenticated read all kudos_reactions" on public.kudos_reactions;

-- ── RLS policies — remaining tables ──────────
drop policy if exists "authenticated read all event_bonuses"  on public.event_bonuses;
drop policy if exists "user reads own user_stats"             on public.user_stats;
drop policy if exists "authenticated read all kudos_hashtags" on public.kudos_hashtags;
drop policy if exists "authenticated read all kudos"          on public.kudos;
drop policy if exists "authenticated read all hashtags"       on public.hashtags;
drop policy if exists "authenticated read all departments"    on public.departments;

-- ── Disable RLS ───────────────────────────────
alter table if exists public.event_bonuses    disable row level security;
alter table if exists public.user_stats       disable row level security;
alter table if exists public.kudos_reactions  disable row level security;
alter table if exists public.kudos_hashtags   disable row level security;
alter table if exists public.kudos            disable row level security;
alter table if exists public.hashtags         disable row level security;
alter table if exists public.departments      disable row level security;
