-- 20260619104604_create_kudos_hashtags_join
-- M:N join table linking kudos to hashtags.
-- CASCADE on both FKs: removing a kudos or hashtag prunes the join rows automatically.

create table if not exists public.kudos_hashtags (
  kudos_id   uuid not null references public.kudos(id)    on delete cascade,
  hashtag_id uuid not null references public.hashtags(id) on delete cascade,
  primary key (kudos_id, hashtag_id)
);

create index if not exists kudos_hashtags_kudos_id_idx
  on public.kudos_hashtags (kudos_id);

create index if not exists kudos_hashtags_hashtag_id_idx
  on public.kudos_hashtags (hashtag_id);
