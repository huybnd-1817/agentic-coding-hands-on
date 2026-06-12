-- 20260611142900_drop_sun_domain_enforcement
-- Removes the BEFORE INSERT domain-allowlist gate on auth.users so any Google
-- account can complete sign-in. The AFTER INSERT profile-sync trigger
-- (trg_handle_new_user) and RLS policies remain unchanged — user data is
-- still scoped per-row, just no longer membership-gated.

drop trigger if exists trg_enforce_sun_domain on auth.users;
drop function if exists public.enforce_sun_domain();
