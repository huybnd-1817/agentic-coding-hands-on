-- Rollback for 20260615161000_create_awards_table and 20260615161001_awards_rls.
-- Apply manually (Supabase dashboard SQL editor or `psql`) — Supabase CLI's
-- migration system does not auto-pair rollbacks; this file is documentation
-- + a paste-ready revert script.

drop policy if exists "authenticated read all awards" on public.awards;
drop table if exists public.awards;
