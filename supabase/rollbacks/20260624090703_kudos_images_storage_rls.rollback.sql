-- Rollback for 20260624090703_kudos_images_storage_rls
-- Drops the SELECT and INSERT policies added on storage.objects for kudos-images.
-- Apply this before rolling back 20260624090702 (bucket deletion).

drop policy if exists "users upload to own kudos-images folder" on storage.objects;
drop policy if exists "authenticated users read kudos-images"   on storage.objects;
