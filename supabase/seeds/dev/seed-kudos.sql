-- seed-kudos
-- Seeds 12 kudos rows for local development and UI testing.
-- Profiles are created by the handle_new_user trigger — this script uses
-- DO $$ blocks with variables so FK references stay portable across resets.
--
-- Strategy: use a temporary lookup to grab the first few profiles by email
-- pattern.  If fewer than 4 profiles exist the seed is a no-op (safe).
--
-- Mix: named + anonymous, photo + no-photo, all hashtag combos.

do $$
declare
  p1 uuid;  -- sender / recipient slot 1
  p2 uuid;  -- sender / recipient slot 2
  p3 uuid;  -- sender / recipient slot 3
  p4 uuid;  -- sender / recipient slot 4

  k1  uuid;
  k2  uuid;
  k3  uuid;
  k4  uuid;
  k5  uuid;
  k6  uuid;
  k7  uuid;
  k8  uuid;
  k9  uuid;
  k10 uuid;
  k11 uuid;
  k12 uuid;

  h_dedicated  uuid;
  h_inspiring  uuid;
  h_teamwork   uuid;
  h_idol       uuid;
  h_helpful    uuid;
begin
  -- Resolve first 4 profile IDs ordered by created_at.
  select id into p1 from public.profiles order by created_at asc limit 1 offset 0;
  select id into p2 from public.profiles order by created_at asc limit 1 offset 1;
  select id into p3 from public.profiles order by created_at asc limit 1 offset 2;
  select id into p4 from public.profiles order by created_at asc limit 1 offset 3;

  -- Exit gracefully if the dev database has fewer than 2 profiles.
  if p1 is null or p2 is null then
    raise notice 'seed-kudos: fewer than 2 profiles found — skipping kudos seed.';
    return;
  end if;

  -- Use p3/p4 as fallbacks if fewer than 4 profiles.
  if p3 is null then p3 := p1; end if;
  if p4 is null then p4 := p2; end if;

  -- Resolve hashtag IDs.
  select id into h_dedicated from public.hashtags where tag = '#Dedicated';
  select id into h_inspiring  from public.hashtags where tag = '#Inspiring';
  select id into h_teamwork   from public.hashtags where tag = '#Teamwork';
  select id into h_idol       from public.hashtags where tag = '#Idol';
  select id into h_helpful    from public.hashtags where tag = '#Helpful';

  -- ── Insert kudos rows ────────────────────────────────────────────────────
  -- 1. Named, no photo, active
  insert into public.kudos (sender_id, recipient_id, title, message, is_anonymous, status)
  values (p1, p2, 'Top Talent', 'Cảm ơn bạn đã luôn hỗ trợ team trong sprint vừa qua. Tinh thần của bạn thật tuyệt vời!', false, 'active')
  returning id into k1;

  -- 2. Named, with photo, active
  insert into public.kudos (sender_id, recipient_id, title, message, is_anonymous, photo_url, status)
  values (p2, p1, 'MVP', 'Bạn đã hoàn thành feature khó nhất của sprint với chất lượng xuất sắc. Rất tự hào!', false,
          'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800', 'active')
  returning id into k2;

  -- 3. Anonymous, no photo
  insert into public.kudos (sender_id, recipient_id, title, message, is_anonymous, anonymous_nickname, status)
  values (p1, p3, 'Người đồng đội tuyệt vời', 'Một người đồng đội tuyệt vời, luôn sẵn sàng giúp đỡ mọi người!', true, 'Một người bạn ẩn danh', 'active')
  returning id into k3;

  -- 4. Named, with photo, active
  insert into public.kudos (sender_id, recipient_id, title, message, is_anonymous, photo_url, status)
  values (p3, p2, 'Signature 2026 - Creator', 'Cảm ơn bạn vì buổi knowledge sharing rất hữu ích về Swift Concurrency!', false,
          'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800', 'active')
  returning id into k4;

  -- 5. Named, no photo, with title
  insert into public.kudos (sender_id, recipient_id, title, message, is_anonymous, status)
  values (p4, p1, 'Người hùng thầm lặng', 'Bạn đã fix bug production lúc nửa đêm và cứu cả team. Cảm ơn rất nhiều!', false, 'active')
  returning id into k5;

  -- 6. Anonymous, with photo
  insert into public.kudos (sender_id, recipient_id, title, message, is_anonymous, anonymous_nickname, photo_url, status)
  values (p2, p4, 'Reviewer tận tâm', 'Code review của bạn luôn chi tiết và giúp ích rất nhiều cho team!', true, 'Đồng nghiệp bí ẩn',
          'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800', 'active')
  returning id into k6;

  -- 7. Named, no photo
  insert into public.kudos (sender_id, recipient_id, title, message, is_anonymous, status)
  values (p3, p4, 'Top Project Leader', 'Tinh thần Wasshoi của bạn lan toả cả team. Cảm ơn vì luôn giữ năng lượng tích cực!', false, 'active')
  returning id into k7;

  -- 8. Named, with photo
  insert into public.kudos (sender_id, recipient_id, title, message, is_anonymous, photo_url, status)
  values (p4, p3, 'Top Project', 'Bạn đã onboard member mới cực kỳ tốt. Team grow được là nhờ có bạn!', false,
          'https://images.unsplash.com/photo-1552664730-d307ca884978?w=800', 'active')
  returning id into k8;

  -- 9. Named, no photo
  insert into public.kudos (sender_id, recipient_id, title, message, is_anonymous, status)
  values (p1, p4, 'Người giữ deadline', 'Deliverable của bạn luôn đúng deadline và chất lượng cao. Team tin tưởng bạn lắm!', false, 'active')
  returning id into k9;

  -- 10. Anonymous, no photo
  insert into public.kudos (sender_id, recipient_id, title, message, is_anonymous, anonymous_nickname, status)
  values (p4, p2, 'Người bạn đồng hành', 'Cảm ơn vì luôn lắng nghe và đồng hành cùng team trong những lúc áp lực nhất.', true, 'Fan của bạn', 'active')
  returning id into k10;

  -- 11. Named, with photo, title
  insert into public.kudos (sender_id, recipient_id, title, message, is_anonymous, photo_url, status)
  values (p2, p3, 'Star of the Sprint', 'Bạn đã lead technical solution cực kỳ xuất sắc. Cả team học được rất nhiều!', false,
          'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=800', 'active')
  returning id into k11;

  -- 12. Named, no photo (cross p3 → p1)
  insert into public.kudos (sender_id, recipient_id, title, message, is_anonymous, status)
  values (p3, p1, 'Tấm gương kiên nhẫn', 'Cảm ơn vì sự kiên nhẫn và tận tâm trong mọi task. Bạn là tấm gương cho team!', false, 'active')
  returning id into k12;

  -- ── Attach hashtags ──────────────────────────────────────────────────────
  -- k1: Dedicated + Helpful
  if k1 is not null and h_dedicated is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k1, h_dedicated) on conflict do nothing;
  end if;
  if k1 is not null and h_helpful is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k1, h_helpful) on conflict do nothing;
  end if;

  -- k2: Inspiring + Idol
  if k2 is not null and h_inspiring is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k2, h_inspiring) on conflict do nothing;
  end if;
  if k2 is not null and h_idol is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k2, h_idol) on conflict do nothing;
  end if;

  -- k3: Teamwork
  if k3 is not null and h_teamwork is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k3, h_teamwork) on conflict do nothing;
  end if;

  -- k4: Inspiring + Dedicated
  if k4 is not null and h_inspiring is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k4, h_inspiring) on conflict do nothing;
  end if;
  if k4 is not null and h_dedicated is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k4, h_dedicated) on conflict do nothing;
  end if;

  -- k5: Idol
  if k5 is not null and h_idol is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k5, h_idol) on conflict do nothing;
  end if;

  -- k6: Helpful + Teamwork
  if k6 is not null and h_helpful is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k6, h_helpful) on conflict do nothing;
  end if;
  if k6 is not null and h_teamwork is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k6, h_teamwork) on conflict do nothing;
  end if;

  -- k7: Inspiring
  if k7 is not null and h_inspiring is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k7, h_inspiring) on conflict do nothing;
  end if;

  -- k8: Dedicated + Teamwork
  if k8 is not null and h_dedicated is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k8, h_dedicated) on conflict do nothing;
  end if;
  if k8 is not null and h_teamwork is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k8, h_teamwork) on conflict do nothing;
  end if;

  -- k9: Helpful
  if k9 is not null and h_helpful is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k9, h_helpful) on conflict do nothing;
  end if;

  -- k10: Teamwork + Idol
  if k10 is not null and h_teamwork is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k10, h_teamwork) on conflict do nothing;
  end if;
  if k10 is not null and h_idol is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k10, h_idol) on conflict do nothing;
  end if;

  -- k11: Inspiring + Idol + Dedicated
  if k11 is not null and h_inspiring is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k11, h_inspiring) on conflict do nothing;
  end if;
  if k11 is not null and h_idol is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k11, h_idol) on conflict do nothing;
  end if;
  if k11 is not null and h_dedicated is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k11, h_dedicated) on conflict do nothing;
  end if;

  -- k12: Helpful + Inspiring
  if k12 is not null and h_helpful is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k12, h_helpful) on conflict do nothing;
  end if;
  if k12 is not null and h_inspiring is not null then
    insert into public.kudos_hashtags (kudos_id, hashtag_id) values (k12, h_inspiring) on conflict do nothing;
  end if;

  raise notice 'seed-kudos: 12 kudos rows and hashtag joins inserted successfully.';
end;
$$;
