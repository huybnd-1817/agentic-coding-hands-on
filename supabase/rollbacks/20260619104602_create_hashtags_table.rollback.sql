-- Rollback for 20260619104602_create_hashtags_table
-- Apply AFTER rolling back kudos_hashtags (20260619104604) which references this table.

drop table if exists public.hashtags;
