-- 20260619104608_kudos_rls_and_triggers
-- Enables RLS on all 7 new tables and defines the three kudos triggers.
--
-- RLS summary:
--   All new tables: SELECT to authenticated (read-all for app users).
--   kudos_reactions: INSERT/DELETE allowed when auth.uid() = user_id
--                    AND reacting user is not the kudos sender (TC_FUN_008).
--   kudos, event_bonuses: no INSERT/UPDATE/DELETE policy → authenticated is
--                         implicitly denied; service_role bypasses RLS.
--   departments, hashtags, kudos_hashtags, user_stats: same implicit deny
--                         for writes; service_role manages these tables.
--
-- Triggers:
--   tr_user_stats_on_profile_insert  — creates a user_stats row on new profile
--   tr_kudos_counts_on_insert        — bumps sent/received counters
--   tr_kudos_reactions_on_insert_delete — adjusts sender's hearts_received
--     (TC_FUN_009/032: "số tim của tài khoản gửi Kudos" = the SENDER collects
--      hearts when others like a kudos they sent)

-- ──────────────────────────────────────────────
-- 1. Enable RLS
-- ──────────────────────────────────────────────
alter table public.departments      enable row level security;
alter table public.hashtags         enable row level security;
alter table public.kudos            enable row level security;
alter table public.kudos_hashtags   enable row level security;
alter table public.kudos_reactions  enable row level security;
alter table public.user_stats       enable row level security;
alter table public.event_bonuses    enable row level security;

-- ──────────────────────────────────────────────
-- 2. SELECT policies — authenticated reads all rows on every new table
-- ──────────────────────────────────────────────
drop policy if exists "authenticated read all departments"     on public.departments;
drop policy if exists "authenticated read all hashtags"        on public.hashtags;
drop policy if exists "authenticated read all kudos"           on public.kudos;
drop policy if exists "authenticated read all kudos_hashtags"  on public.kudos_hashtags;
drop policy if exists "authenticated read all kudos_reactions" on public.kudos_reactions;
drop policy if exists "authenticated read all user_stats"      on public.user_stats;
drop policy if exists "user reads own user_stats"              on public.user_stats;
drop policy if exists "authenticated read all event_bonuses"   on public.event_bonuses;

create policy "authenticated read all departments"
  on public.departments for select
  to authenticated using (true);

create policy "authenticated read all hashtags"
  on public.hashtags for select
  to authenticated using (true);

create policy "authenticated read all kudos"
  on public.kudos for select
  to authenticated using (true);

create policy "authenticated read all kudos_hashtags"
  on public.kudos_hashtags for select
  to authenticated using (true);

create policy "authenticated read all kudos_reactions"
  on public.kudos_reactions for select
  to authenticated using (true);

-- Tightened: user_stats SELECT restricted to row owner. Secret box counts are private.
-- fetchTopGiftRecipients currently returns [] (stub), so no cross-user stats read is needed.
-- Revisit this policy when the real leaderboard implementation lands.
create policy "user reads own user_stats"
  on public.user_stats for select
  to authenticated using (auth.uid() = user_id);

create policy "authenticated read all event_bonuses"
  on public.event_bonuses for select
  to authenticated using (true);

-- ──────────────────────────────────────────────
-- 3. kudos_reactions INSERT/DELETE policies
--    Reacting user must be authenticated AND must not be the kudos sender
--    (prevents self-liking — TC_FUN_008).
-- ──────────────────────────────────────────────
drop policy if exists "user can react to others kudos"   on public.kudos_reactions;
drop policy if exists "user can delete own reaction"     on public.kudos_reactions;

create policy "user can react to others kudos"
  on public.kudos_reactions for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and user_id != (
      select sender_id from public.kudos where id = kudos_id
    )
  );

create policy "user can delete own reaction"
  on public.kudos_reactions for delete
  to authenticated
  using (auth.uid() = user_id);

-- ──────────────────────────────────────────────
-- 4. Trigger: auto-create user_stats on profile insert
-- ──────────────────────────────────────────────
create or replace function public.fn_user_stats_on_profile_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_stats (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists tr_user_stats_on_profile_insert on public.profiles;

create trigger tr_user_stats_on_profile_insert
  after insert on public.profiles
  for each row
  execute function public.fn_user_stats_on_profile_insert();

-- ──────────────────────────────────────────────
-- 5. Trigger: bump kudos_sent_count / kudos_received_count on kudos insert
-- ──────────────────────────────────────────────
create or replace function public.fn_kudos_counts_on_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Bump sender's sent count
  update public.user_stats
  set
    kudos_sent_count = kudos_sent_count + 1,
    updated_at       = now()
  where user_id = new.sender_id;

  -- Bump recipient's received count
  update public.user_stats
  set
    kudos_received_count = kudos_received_count + 1,
    updated_at           = now()
  where user_id = new.recipient_id;

  return new;
end;
$$;

drop trigger if exists tr_kudos_counts_on_insert on public.kudos;

create trigger tr_kudos_counts_on_insert
  after insert on public.kudos
  for each row
  execute function public.fn_kudos_counts_on_insert();

-- ──────────────────────────────────────────────
-- 6. Trigger: adjust sender's kudos_hearts_received on reaction insert/delete
--
--    TC_FUN_009/032 spec: "số tim của tài khoản gửi Kudos" — the SENDER of
--    the kudos accumulates hearts when other users like it.
--    On INSERT: add multiplier to sender's hearts_received.
--    On DELETE: subtract multiplier from sender's hearts_received (floor at 0).
-- ──────────────────────────────────────────────
create or replace function public.fn_kudos_reactions_on_insert_delete()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sender_id uuid;
begin
  if tg_op = 'INSERT' then
    select sender_id into v_sender_id
      from public.kudos
     where id = new.kudos_id;

    update public.user_stats
    set
      kudos_hearts_received = kudos_hearts_received + new.multiplier,
      updated_at            = now()
    where user_id = v_sender_id;

    return new;

  elsif tg_op = 'DELETE' then
    select sender_id into v_sender_id
      from public.kudos
     where id = old.kudos_id;

    update public.user_stats
    set
      kudos_hearts_received = greatest(0, kudos_hearts_received - old.multiplier),
      updated_at            = now()
    where user_id = v_sender_id;

    return old;
  end if;

  return null;
end;
$$;

drop trigger if exists tr_kudos_reactions_on_insert_delete on public.kudos_reactions;

create trigger tr_kudos_reactions_on_insert_delete
  after insert or delete on public.kudos_reactions
  for each row
  execute function public.fn_kudos_reactions_on_insert_delete();
