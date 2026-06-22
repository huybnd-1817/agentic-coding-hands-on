-- seed-base-profiles
-- Local-dev bootstrap: ensure ≥4 profiles exist so seed-kudos.sql can populate
-- without manual multi-account OAuth. Inserts stub rows into auth.users; the
-- handle_new_user trigger then creates the matching profiles automatically.
--
-- Idempotent: each insert uses `on conflict do nothing`. Real Google accounts
-- already in auth.users are left untouched.
--
-- File name starts with "seed-base-" so it sorts before seed-departments.sql,
-- seed-hashtags.sql, seed-kudos.sql in the glob (config.toml sql_paths) — the
-- kudos seed reads `profiles order by created_at asc` and needs ≥2 rows.

do $$
declare
  dept_cev1 uuid;
  dept_cev2 uuid;
  dept_opd  uuid;
  stub1_id uuid := 'ce11ab01-0000-0000-0000-000000000001';
  stub2_id uuid := 'ce11ab01-0000-0000-0000-000000000002';
  stub3_id uuid := 'ce11ab01-0000-0000-0000-000000000003';
begin
  -- Resolve department ids (may be null if departments seed hasn't run yet —
  -- profiles row tolerates null department_id).
  select id into dept_cev1 from public.departments where code = 'CEV1';
  select id into dept_cev2 from public.departments where code = 'CEV2';
  select id into dept_opd  from public.departments where code = 'OPD';

  -- Stub auth.users → handle_new_user trigger fills public.profiles.
  -- created_at is set far enough in the past that real users seeded later
  -- sort AFTER these stubs (seed-kudos picks p1..p4 by created_at asc).
  insert into auth.users (
    instance_id, id, aud, role, email,
    email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at, is_anonymous
  )
  values
    ('00000000-0000-0000-0000-000000000000', stub1_id, 'authenticated', 'authenticated',
     'dev.alice@example.local', now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"full_name":"Alice Lê","avatar_url":null}'::jsonb,
     '2020-01-01 00:00:00+00', '2020-01-01 00:00:00+00', false),
    ('00000000-0000-0000-0000-000000000000', stub2_id, 'authenticated', 'authenticated',
     'dev.bao@example.local', now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"full_name":"Bảo Trần","avatar_url":null}'::jsonb,
     '2020-01-01 00:00:01+00', '2020-01-01 00:00:01+00', false),
    ('00000000-0000-0000-0000-000000000000', stub3_id, 'authenticated', 'authenticated',
     'dev.chi@example.local', now(),
     '{"provider":"email","providers":["email"]}'::jsonb,
     '{"full_name":"Chi Phạm","avatar_url":null}'::jsonb,
     '2020-01-01 00:00:02+00', '2020-01-01 00:00:02+00', false)
  on conflict (id) do nothing;

  -- Attach departments to stub profiles so the department filter has signal.
  update public.profiles set department_id = dept_cev1 where id = stub1_id and department_id is null;
  update public.profiles set department_id = dept_cev2 where id = stub2_id and department_id is null;
  update public.profiles set department_id = dept_opd  where id = stub3_id and department_id is null;

  raise notice 'seed-base-profiles: 3 stub profiles ensured (Alice Lê, Bảo Trần, Chi Phạm).';
end;
$$;
