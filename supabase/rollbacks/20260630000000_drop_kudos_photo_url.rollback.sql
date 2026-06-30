-- Rollback for 20260630000000_drop_kudos_photo_url
-- Re-adds `photo_url` to public.kudos and restores values from the
-- synthetic-import attachment row (sort_order = 0) of each kudos.
--
-- Caveat: this only restores rows that this migration originally synthesised.
-- Any attachments created AFTER the forward migration ran will still be in
-- kudos_attachments — the rollback does NOT delete those rows.

begin;

alter table public.kudos add column if not exists photo_url text;

update public.kudos k
set photo_url = a.storage_path
from public.kudos_attachments a
where a.kudos_id = k.id
  and a.sort_order = 0
  and k.photo_url is null;

commit;
