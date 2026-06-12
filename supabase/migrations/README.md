# Supabase Migrations

## Apply order

Migrations are applied in ascending numeric-timestamp order (Supabase default behaviour):

| # | File | Purpose |
|---|------|---------|
| 1 | `20260610145900_create_profiles_table.sql` | Creates `public.profiles` table and email index |
| 2 | `20260610145901_enforce_sun_domain.sql` | (historical) BEFORE INSERT trigger that rejected non `@sun-asterisk.com` emails — dropped by migration #5 |
| 3 | `20260610145902_sync_profile_on_signup.sql` | AFTER INSERT trigger — syncs Google OAuth metadata into `profiles` |
| 4 | `20260610145903_profiles_rls.sql` | Enables RLS; read/update policies scoped to the owning user |
| 5 | `20260611142900_drop_sun_domain_enforcement.sql` | Drops `trg_enforce_sun_domain` and `public.enforce_sun_domain()`; sign-in now open to any Google account |

## How to apply locally

```bash
supabase db reset
```

This drops and recreates the local database, re-applies all migrations in timestamp order, then runs seeds from `supabase/seeds/`.

## Verify profile sync manually

Open **Supabase Studio → SQL Editor** and run the following test. Any
Google-style email should succeed and create a corresponding profile row.

```sql
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data, created_at, updated_at)
values (
  gen_random_uuid(),
  'test.user@example.com',
  '{"full_name": "Test User", "avatar_url": "https://example.com/avatar.png"}'::jsonb,
  '{"provider": "google"}'::jsonb,
  now(),
  now()
);

select * from public.profiles where email = 'test.user@example.com';
```

To confirm the historical domain trigger no longer exists:

```sql
\df public.enforce_sun_domain   -- expect 0 rows
select tgname from pg_trigger where tgname = 'trg_enforce_sun_domain';  -- expect 0 rows
```
