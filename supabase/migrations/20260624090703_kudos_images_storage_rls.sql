-- 20260624090703_kudos_images_storage_rls
-- RLS policies on storage.objects scoped to the `kudos-images` bucket.
--
-- Policy summary:
--   SELECT: any authenticated user can read any object in the bucket
--           (feed needs to fetch images uploaded by other users).
--   INSERT: authenticated user may only upload to their own folder
--           — path must begin with their own auth.uid().
--           storage.foldername(name) returns an array of path segments;
--           element [1] is the first folder component (1-based in Postgres).
--   UPDATE: denied — no in-app edit path exists yet.
--   DELETE: denied — no in-app delete path exists yet.
--
-- Path convention: kudos-images/{auth.uid()}/{uuid}.{ext}

-- ──────────────────────────────────────────────
-- SELECT — any authenticated user reads any object
-- ──────────────────────────────────────────────
drop policy if exists "authenticated users read kudos-images" on storage.objects;

create policy "authenticated users read kudos-images"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'kudos-images');

-- ──────────────────────────────────────────────
-- INSERT — upload only to own folder prefix
-- ──────────────────────────────────────────────
drop policy if exists "users upload to own kudos-images folder" on storage.objects;

create policy "users upload to own kudos-images folder"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'kudos-images'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- UPDATE and DELETE are intentionally omitted — no policy means the operation
-- is denied for the `authenticated` role. service_role bypasses RLS and can
-- manage objects directly if needed (e.g., admin cleanup).
