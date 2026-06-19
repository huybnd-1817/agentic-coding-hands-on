-- Rollback for 20260619104604_create_kudos_hashtags_join
-- Apply AFTER rolling back 20260619104605, 20260619104606, 20260619104607, 20260619104608.

drop table if exists public.kudos_hashtags;
