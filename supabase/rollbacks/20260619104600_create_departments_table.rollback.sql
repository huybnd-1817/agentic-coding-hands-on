-- Rollback for 20260619104600_create_departments_table
-- Apply LAST — after rolling back profiles_add_department (20260619104601)
-- which holds the FK reference to this table.

drop table if exists public.departments;
