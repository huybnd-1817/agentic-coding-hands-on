-- 20260619104603_create_kudos_table
-- Creates public.kudos table: the core record for peer-to-peer recognition.
-- sender_id / recipient_id RESTRICT on delete so kudos are never silently lost.
-- Indexes: composite (recipient_id, created_at) for the feed query.

create table if not exists public.kudos (
  id                   uuid        primary key default gen_random_uuid(),
  sender_id            uuid        not null references public.profiles(id) on delete restrict,
  recipient_id         uuid        not null references public.profiles(id) on delete restrict,
  title                text,
  message              text        not null,
  award_category_name  text,
  is_anonymous         boolean     not null default false,
  anonymous_nickname   text,
  photo_url            text,
  status               text        not null default 'active',
  created_at           timestamptz not null default now(),
  deleted_at           timestamptz
);

create index if not exists kudos_recipient_created_idx
  on public.kudos (recipient_id, created_at desc);
