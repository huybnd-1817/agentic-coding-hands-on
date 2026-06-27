-- Rollback for 20260624090702_create_kudos_images_storage_bucket
-- Apply AFTER rolling back 20260624090703 (Storage RLS) so no orphaned policies remain.
-- Deletes all objects in the bucket first, then removes the bucket record.

delete from storage.objects where bucket_id = 'kudos-images';
delete from storage.buckets where id = 'kudos-images';
