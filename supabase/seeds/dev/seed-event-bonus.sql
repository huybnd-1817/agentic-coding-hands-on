-- seed-event-bonus
-- Seeds one active event_bonus row covering today (Day of Recognition).
-- Safe to re-run: inserts only if no active row already exists.

insert into public.event_bonuses (starts_at, ends_at, multiplier, label)
select
  now(),
  now() + interval '1 day',
  2,
  'Day of Recognition'
where not exists (
  select 1 from public.event_bonuses
  where now() between starts_at and ends_at
);
