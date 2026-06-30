-- 20260630000000_drop_kudos_photo_url
-- Migrates legacy `public.kudos.photo_url` data into `public.kudos_attachments`
-- (one synthetic attachment per non-null photo_url where no attachment yet
-- exists for that kudos), then drops the `photo_url` column.
--
-- byte_size check (> 0) is honoured by writing a sentinel `1` — the legacy
-- field never carried byte size, and downstream code does not depend on it
-- for legacy rows.
--
-- content_type best-guess: `image/jpeg` (the historic default for photo_url
-- uploads). If a real value is needed for any legacy row, run a separate
-- backfill script later.
--
-- Idempotent: the WHERE clause skips kudos that already have any attachment,
-- so re-running this migration after manual attachment writes is safe.

begin;

insert into public.kudos_attachments (kudos_id, storage_path, sort_order, content_type, byte_size)
select
  k.id,
  k.photo_url,
  0,
  'image/jpeg',
  1
from public.kudos k
where k.photo_url is not null
  and length(k.photo_url) > 0
  and not exists (
    select 1
    from public.kudos_attachments a
    where a.kudos_id = k.id
  );

alter table public.kudos drop column if exists photo_url;

commit;
