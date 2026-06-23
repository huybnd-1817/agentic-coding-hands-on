-- 20260622154500_profiles_authenticated_read_all
-- Loosens public.profiles SELECT to allow any authenticated user to read every
-- row.  Required by the Kudos feed: the query joins
--   sender:profiles!sender_id(...)
--   recipient:profiles!recipient_id(...)
-- and the previous "users read own profile" policy (auth.uid() = id) caused
-- PostgREST to silently drop those join rows for every kudos not directly
-- involving the viewer — leaving sender/recipient name, avatar and
-- department_id null on the wire.  UPDATE policy stays row-owner scoped.

begin;

drop policy if exists "users read own profile" on public.profiles;

create policy "authenticated read all profiles"
  on public.profiles
  for select
  to authenticated
  using (true);

commit;
