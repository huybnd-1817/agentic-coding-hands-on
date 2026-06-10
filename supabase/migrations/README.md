# Supabase Migrations

## Apply order

Migrations are applied in ascending numeric-timestamp order (Supabase default behaviour):

| # | File | Purpose |
|---|------|---------|
| 1 | `20260610145900_create_profiles_table.sql` | Creates `public.profiles` table and email index |
| 2 | `20260610145901_enforce_sun_domain.sql` | BEFORE INSERT trigger — rejects non `@sun-asterisk.com` emails |
| 3 | `20260610145902_sync_profile_on_signup.sql` | AFTER INSERT trigger — syncs Google OAuth metadata into `profiles` |
| 4 | `20260610145903_profiles_rls.sql` | Enables RLS; read/update policies scoped to the owning user |

Trigger ordering is guaranteed by PostgreSQL trigger semantics: `BEFORE INSERT` (`trg_enforce_sun_domain`) always fires before `AFTER INSERT` (`trg_handle_new_user`), regardless of migration file order.

## How to apply locally

```bash
supabase db reset
```

This drops and recreates the local database, re-applies all migrations in timestamp order, then runs seeds from `supabase/seeds/`.

## Verify Sun* domain trigger manually

Open **Supabase Studio → SQL Editor** and run the following tests:

**Should succeed (profile row created):**
```sql
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data, created_at, updated_at)
values (
  gen_random_uuid(),
  'test.user@sun-asterisk.com',
  '{"full_name": "Test User", "avatar_url": "https://example.com/avatar.png"}'::jsonb,
  '{"provider": "google"}'::jsonb,
  now(),
  now()
);

select * from public.profiles where email = 'test.user@sun-asterisk.com';
```

**Should fail with "Account not authorized" (errcode 42501):**
```sql
insert into auth.users (id, email, raw_user_meta_data, raw_app_meta_data, created_at, updated_at)
values (
  gen_random_uuid(),
  'attacker@gmail.com',
  '{}'::jsonb,
  '{"provider": "google"}'::jsonb,
  now(),
  now()
);
```

Expected error: `ERROR: Account not authorized (SQLSTATE 42501)`
