-- Rollback for 20260616120800_drop_redundant_profiles_email_idx.
-- Apply manually (Supabase dashboard SQL editor or `psql`) — Supabase CLI's
-- migration system does not auto-pair rollbacks; this file is documentation
-- + a paste-ready revert script.
--
-- Note: this recreates the redundant index. Only run if you have evidence
-- that the original UNIQUE constraint's auto-index is insufficient (highly
-- unlikely for plain equality lookups).

create index if not exists profiles_email_idx on public.profiles (email);
