-- Rollback for 20260619104607_create_event_bonuses_table
-- Apply AFTER rolling back 20260619104608_kudos_rls_and_triggers.

drop table if exists public.event_bonuses;
