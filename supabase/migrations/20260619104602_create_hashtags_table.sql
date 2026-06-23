-- 20260619104602_create_hashtags_table
-- Creates public.hashtags table holding filterable kudos tags.
-- Read-only for authenticated app users; writes via service_role only.

create table if not exists public.hashtags (
  id         uuid        primary key default gen_random_uuid(),
  tag        text        not null unique,
  created_at timestamptz not null default now()
);
