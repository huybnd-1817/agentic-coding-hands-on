-- 20260624090704_kudos_sender_delete_policy
-- Adds a DELETE RLS policy to kudos so that the sender can delete their own row.
--
-- Security model:
--   kudos DELETE: auth.uid() = sender_id
--
-- This is required for the best-effort rollback path in SupabaseKudosRepository.createKudo.
-- Without this policy a DELETE issued by the sender silently no-ops, leaving orphan kudos
-- rows in the feed when hashtag or attachment insertion fails after the kudos row is committed.

drop policy if exists "sender can delete own kudos" on public.kudos;

create policy "sender can delete own kudos"
  on public.kudos
  for delete
  to authenticated
  using (auth.uid() = sender_id);
