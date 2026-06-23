-- 20260619104605_create_kudos_reactions_table
-- Stores per-user heart reactions on kudos.
-- UNIQUE (kudos_id, user_id) prevents double-liking (TC_FUN_008).
-- multiplier snapped at insert time from the active event_bonus window.

create table if not exists public.kudos_reactions (
  id         uuid        primary key default gen_random_uuid(),
  kudos_id   uuid        not null references public.kudos(id)     on delete cascade,
  user_id    uuid        not null references public.profiles(id)  on delete cascade,
  multiplier int         not null default 1,
  created_at timestamptz not null default now(),
  unique (kudos_id, user_id)
);

-- Explicit index on kudos_id for heart-count aggregation queries.
create index if not exists kudos_reactions_kudos_id_idx
  on public.kudos_reactions (kudos_id);
