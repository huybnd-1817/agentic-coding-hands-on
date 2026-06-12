-- 20260610145902_sync_profile_on_signup
-- AFTER INSERT trigger on auth.users that inserts a row into public.profiles.
-- Reads Google OAuth metadata from raw_user_meta_data / raw_app_meta_data.
-- Idempotent: on conflict (id) do nothing prevents duplicate errors on replay.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, name, avatar_url, provider)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name'),
    new.raw_user_meta_data->>'avatar_url',
    coalesce(new.raw_app_meta_data->>'provider', 'google')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists trg_handle_new_user on auth.users;

create trigger trg_handle_new_user
  after insert on auth.users
  for each row execute function public.handle_new_user();
