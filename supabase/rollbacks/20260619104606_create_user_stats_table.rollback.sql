-- Rollback for 20260619104606_create_user_stats_table
-- Apply AFTER rolling back 20260619104607 and 20260619104608.

drop table if exists public.user_stats;
