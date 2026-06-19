-- Rollback for 20260619104601_profiles_add_department
-- Removes the department_id column from profiles.
-- Apply AFTER rolling back all kudos-related tables that may join via profiles.

alter table if exists public.profiles
  drop column if exists department_id;
