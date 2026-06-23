-- 20260619104600_create_departments_table
-- Creates public.departments table holding SAA organisational divisions.
-- Must run before 20260619104601_profiles_add_department (FK dependency).
-- Read-only for authenticated app users; writes via service_role only.

create table if not exists public.departments (
  id         uuid        primary key default gen_random_uuid(),
  code       text        not null unique,
  name       text        not null,
  created_at timestamptz not null default now()
);
