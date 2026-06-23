-- Rollback for 20260622145600_kudos_title_required_drop_award_category
-- Re-adds award_category_name as a nullable text column and relaxes
-- title back to nullable. Existing title values are preserved.

begin;

alter table public.kudos
  alter column title drop not null;

alter table public.kudos
  add column if not exists award_category_name text;

commit;
