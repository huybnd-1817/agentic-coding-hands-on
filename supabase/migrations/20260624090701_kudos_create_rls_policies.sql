-- 20260624090701_kudos_create_rls_policies
-- Adds INSERT RLS policies to kudos, kudos_hashtags, and kudos_attachments
-- so authenticated users can submit the create-kudos form.
--
-- Security model:
--   kudos INSERT:            auth.uid() = sender_id AND recipient_id != sender_id
--   kudos_hashtags INSERT:   EXISTS(kudos row where sender_id = auth.uid())
--   kudos_attachments INSERT: EXISTS(kudos row where sender_id = auth.uid())
--
-- The sender_id check is server-side and cannot be bypassed by the client.
-- The self-kudos guard mirrors TC_FUN_008 (recipient != sender).
-- service_role bypasses RLS and is used for seed/admin operations.

-- ──────────────────────────────────────────────
-- 1. kudos INSERT policy
-- ──────────────────────────────────────────────
drop policy if exists "sender can insert own kudos" on public.kudos;

create policy "sender can insert own kudos"
  on public.kudos for insert
  to authenticated
  with check (
    auth.uid() = sender_id
    and recipient_id != sender_id
  );

-- ──────────────────────────────────────────────
-- 2. kudos_hashtags INSERT policy
-- ──────────────────────────────────────────────
drop policy if exists "sender can insert hashtags for own kudos" on public.kudos_hashtags;

create policy "sender can insert hashtags for own kudos"
  on public.kudos_hashtags for insert
  to authenticated
  with check (
    exists (
      select 1
        from public.kudos k
       where k.id = kudos_id
         and k.sender_id = auth.uid()
    )
  );

-- ──────────────────────────────────────────────
-- 3. kudos_attachments INSERT policy
-- ──────────────────────────────────────────────
drop policy if exists "sender can insert attachments for own kudos" on public.kudos_attachments;

create policy "sender can insert attachments for own kudos"
  on public.kudos_attachments for insert
  to authenticated
  with check (
    exists (
      select 1
        from public.kudos k
       where k.id = kudos_id
         and k.sender_id = auth.uid()
    )
  );
