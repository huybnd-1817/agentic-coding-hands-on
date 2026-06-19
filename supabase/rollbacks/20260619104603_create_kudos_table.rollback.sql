-- Rollback for 20260619104603_create_kudos_table
-- Apply AFTER rolling back 20260619104604 through 20260619104608 (all join/reaction tables first).

drop table if exists public.kudos;
