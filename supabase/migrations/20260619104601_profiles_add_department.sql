-- 20260619104601_profiles_add_department
-- Adds department_id FK column to public.profiles linking to public.departments.
-- Nullable so existing profiles without a department are unaffected.

alter table public.profiles
  add column if not exists department_id uuid references public.departments(id) on delete set null;
