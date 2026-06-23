-- Rollback for 20260619104605_create_kudos_reactions_table
-- Apply AFTER rolling back 20260619104606, 20260619104607, 20260619104608.

drop table if exists public.kudos_reactions;
