-- 20260615161001_awards_rls
-- Enables Row Level Security on public.awards.
-- Authenticated users may read all rows; no client-side writes are permitted.
-- Anon role has no access. Service role bypasses RLS for admin seeding.

alter table public.awards enable row level security;

-- Drop policy before recreating for idempotency
drop policy if exists "authenticated read all awards" on public.awards;

create policy "authenticated read all awards"
  on public.awards
  for select
  to authenticated
  using (true);
