-- 20260610145901_enforce_sun_domain
-- BEFORE INSERT trigger on auth.users that rejects any email not ending in @sun-asterisk.com.
-- Runs before handle_new_user (AFTER INSERT) so invalid signups never reach profile sync.

create or replace function public.enforce_sun_domain()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.email is null or new.email !~* '@sun-asterisk\.com$' then
    raise exception 'Account not authorized' using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_enforce_sun_domain on auth.users;

create trigger trg_enforce_sun_domain
  before insert on auth.users
  for each row execute function public.enforce_sun_domain();
