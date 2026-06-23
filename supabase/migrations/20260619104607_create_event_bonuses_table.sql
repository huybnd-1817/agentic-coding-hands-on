-- 20260619104607_create_event_bonuses_table
-- Admin-managed table of heart-multiplier windows (e.g. Day of Recognition).
-- CHECK constraint guarantees ends_at > starts_at so queries are always well-formed.
-- Composite index on (starts_at, ends_at) for active-window lookup:
--   WHERE now() BETWEEN starts_at AND ends_at

create table if not exists public.event_bonuses (
  id         uuid        primary key default gen_random_uuid(),
  starts_at  timestamptz not null,
  ends_at    timestamptz not null,
  multiplier int         not null default 2,
  label      text,
  created_at timestamptz not null default now(),
  constraint event_bonuses_ends_after_starts check (ends_at > starts_at)
);

create index if not exists event_bonuses_window_idx
  on public.event_bonuses (starts_at, ends_at);
