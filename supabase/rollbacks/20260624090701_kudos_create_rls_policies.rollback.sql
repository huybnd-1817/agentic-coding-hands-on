-- Rollback for 20260624090701_kudos_create_rls_policies
-- Drops the INSERT policies added on kudos, kudos_hashtags, and kudos_attachments.
-- Apply this before rolling back 20260624090700.

drop policy if exists "sender can insert attachments for own kudos" on public.kudos_attachments;
drop policy if exists "sender can insert hashtags for own kudos"    on public.kudos_hashtags;
drop policy if exists "sender can insert own kudos"                 on public.kudos;
