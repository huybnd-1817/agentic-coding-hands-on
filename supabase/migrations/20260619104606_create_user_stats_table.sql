-- 20260619104606_create_user_stats_table
-- 1:1 companion to profiles holding running kudos counters.
-- Row is created automatically by tr_user_stats_on_profile_insert trigger
-- (defined in 20260619104608_kudos_rls_and_triggers).
-- CASCADE on delete: stats are meaningless without the owning profile.

create table if not exists public.user_stats (
  user_id                uuid        primary key references public.profiles(id) on delete cascade,
  kudos_received_count   int         not null default 0,
  kudos_sent_count       int         not null default 0,
  kudos_hearts_received  int         not null default 0,
  secret_boxes_opened    int         not null default 0,
  secret_boxes_unopened  int         not null default 0,
  updated_at             timestamptz not null default now()
);
