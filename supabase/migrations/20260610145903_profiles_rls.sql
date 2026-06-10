-- 20260610145903_profiles_rls
-- Enables Row Level Security on public.profiles and creates read/update policies
-- scoped to the authenticated user's own row. Anon role has no access.

alter table public.profiles enable row level security;

-- Drop policies before recreating for idempotency
drop policy if exists "users read own profile"   on public.profiles;
drop policy if exists "users update own profile" on public.profiles;

create policy "users read own profile"
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);

create policy "users update own profile"
  on public.profiles
  for update
  to authenticated
  using (auth.uid() = id);
