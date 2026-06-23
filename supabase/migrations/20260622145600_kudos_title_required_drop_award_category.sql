-- 20260622145600_kudos_title_required_drop_award_category
-- Makes public.kudos.title NOT NULL (backfilling NULL rows from
-- award_category_name when present) and removes the now-unused
-- award_category_name column.
--
-- Backfill rule: prefer the existing award_category_name as the title; fall
-- back to a literal 'Untitled' so the NOT NULL constraint can be applied
-- without losing any rows.

begin;

update public.kudos
set title = coalesce(nullif(title, ''), nullif(award_category_name, ''), 'Untitled')
where title is null or title = '';

alter table public.kudos
  alter column title set not null;

alter table public.kudos
  drop column if exists award_category_name;

commit;
