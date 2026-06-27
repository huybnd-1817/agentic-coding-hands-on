-- 20260624090702_create_kudos_images_storage_bucket
-- Provisions the `kudos-images` Storage bucket.
-- public=false: objects are NOT publicly accessible via the CDN URL.
-- Signed URLs (created server-side) are used for read access.
-- file_size_limit=5242880: 5 MB per object (matches clarification: 5 MB each).
-- allowed_mime_types: JPEG and PNG only; Supabase rejects other types at upload.
-- RLS policies on storage.objects are added in 20260624090703.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'kudos-images',
  'kudos-images',
  false,
  5242880,
  array['image/jpeg', 'image/png']
)
on conflict (id) do update
  set
    public              = excluded.public,
    file_size_limit     = excluded.file_size_limit,
    allowed_mime_types  = excluded.allowed_mime_types;
