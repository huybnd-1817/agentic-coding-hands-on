-- 20260615161000_create_awards_table
-- Creates the public.awards table holding SAA 2025 award categories.
-- Read-only for authenticated app users; writes performed via service role only.

create table if not exists public.awards (
  id              uuid        primary key default gen_random_uuid(),
  code            text        not null unique,
  name_en         text        not null,
  name_vi         text        not null,
  description_en  text        not null,
  description_vi  text        not null,
  thumbnail_url   text,
  sort_order      int         not null default 0,
  created_at      timestamptz not null default now()
);

create index if not exists awards_sort_order_idx on public.awards (sort_order);
