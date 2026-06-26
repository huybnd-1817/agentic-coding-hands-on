-- Rollback for 20260624090700_create_kudos_attachments_table
-- Apply AFTER rolling back 20260624090701 (which drops INSERT policies on this table).
-- Drops the SELECT policy, disables RLS, then drops the table entirely.

drop policy if exists "authenticated read all kudos_attachments" on public.kudos_attachments;

alter table if exists public.kudos_attachments disable row level security;

drop table if exists public.kudos_attachments;
