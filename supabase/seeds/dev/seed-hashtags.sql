-- seed-hashtags
-- Seeds the 5 canonical kudos hashtags shown in the filter sheet.
-- Safe to re-run: upserts on tag (unique key).
-- Note: "#Inspiring" is the correct spelling (#Inspring in the original spec is a typo).

insert into public.hashtags (tag)
values
  ('#Dedicated'),
  ('#Inspiring'),
  ('#Teamwork'),
  ('#Idol'),
  ('#Helpful')
on conflict (tag) do nothing;
