-- 20260624090700_create_kudos_attachments_table
-- Creates public.kudos_attachments: stores uploaded image references for a kudos post.
-- Each kudos can have up to 5 attachments (enforced client-side; schema allows any count).
-- CASCADE on kudos FK: deleting a kudos prunes its attachments automatically.
-- RLS enabled here; INSERT/SELECT policies added in 20260624090701.

create table if not exists public.kudos_attachments (
  id           uuid        primary key default gen_random_uuid(),
  kudos_id     uuid        not null references public.kudos(id) on delete cascade,
  storage_path text        not null,                              -- "kudos-images/{user_id}/{uuid}.jpg"
  sort_order   int         not null default 0,
  content_type text        not null,                             -- "image/jpeg" | "image/png"
  byte_size    int         not null check (byte_size > 0),
  created_at   timestamptz not null default now()
);

create index if not exists kudos_attachments_kudos_id_sort_order_idx
  on public.kudos_attachments (kudos_id, sort_order);

alter table public.kudos_attachments enable row level security;

-- SELECT: any authenticated user can read attachments (needed for the feed).
drop policy if exists "authenticated read all kudos_attachments" on public.kudos_attachments;

create policy "authenticated read all kudos_attachments"
  on public.kudos_attachments for select
  to authenticated using (true);
