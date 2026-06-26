-- Rollback for 20260624090704_kudos_sender_delete_policy
-- Drops the DELETE policy added on public.kudos for the sender.

drop policy if exists "sender can delete own kudos" on public.kudos;
