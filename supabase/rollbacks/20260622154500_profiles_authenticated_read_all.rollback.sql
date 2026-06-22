-- Rollback for 20260622154500_profiles_authenticated_read_all
-- Restores the original "users read own profile" SELECT policy on
-- public.profiles.  Re-running the rollback re-tightens cross-user reads.

begin;

drop policy if exists "authenticated read all profiles" on public.profiles;

create policy "users read own profile"
  on public.profiles
  for select
  to authenticated
  using (auth.uid() = id);

commit;
