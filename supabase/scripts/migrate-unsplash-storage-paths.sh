#!/usr/bin/env bash
#
# migrate-unsplash-storage-paths.sh
#
# One-off data migration for the LOCAL Supabase stack:
#   1. Finds every public.kudos_attachments row whose storage_path is a
#      legacy `https://images.unsplash.com/...` URL (backfilled by
#      migration 20260630000000 when the kudos.photo_url column was dropped).
#   2. Downloads the image to a tempfile.
#   3. Uploads it to the private `kudos-images` Storage bucket under
#      `{sender_id}/{attachment_id}.jpg` — same convention as SupabaseStorageImageUploader.
#   4. Rewrites kudos_attachments.storage_path to the bucket-relative path
#      `{sender_id}/{attachment_id}.jpg`.
#   5. Also deletes orphan attachment rows that point to a path with no real
#      object in storage.objects (e.g., the seed-leftover `test-uuid.jpg` row).
#
# Idempotent: re-running the script after a successful migration is a no-op
# (the query in step 1 returns zero rows once all storage_paths are bucket-relative).
#
# Requirements (already running for `supabase start`):
#   - Local Supabase stack on the default ports
#   - psql + curl in PATH
#
# Usage:
#   bash supabase/scripts/migrate-unsplash-storage-paths.sh
#
set -euo pipefail

SUPABASE_URL="${SUPABASE_URL:-http://127.0.0.1:54321}"
SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY:-$(supabase status -o env 2>/dev/null | sed -nE 's/^SERVICE_ROLE_KEY="(.+)"$/\1/p')}"
DB_HOST="${SUPABASE_DB_HOST:-127.0.0.1}"
DB_PORT="${SUPABASE_DB_PORT:-54322}"
DB_USER="${SUPABASE_DB_USER:-postgres}"
DB_PASS="${SUPABASE_DB_PASS:-postgres}"
DB_NAME="${SUPABASE_DB_NAME:-postgres}"
BUCKET="kudos-images"

if [[ -z "${SERVICE_ROLE_KEY}" ]]; then
  echo "[migrate] ERROR: service_role key not resolved. Set SUPABASE_SERVICE_ROLE_KEY or ensure 'supabase status' works." >&2
  exit 1
fi

PSQL=(env PGPASSWORD="${DB_PASS}" psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -t -A)

echo "[migrate] Step A: deleting orphan attachment rows (no matching storage object)…"
ORPHAN_COUNT=$("${PSQL[@]}" -c "
DELETE FROM public.kudos_attachments ka
WHERE NOT (ka.storage_path LIKE 'http://%' OR ka.storage_path LIKE 'https://%')
  AND NOT EXISTS (
    SELECT 1 FROM storage.objects o
    WHERE o.bucket_id = '${BUCKET}'
      AND (
        o.name = ka.storage_path
        OR o.name = regexp_replace(ka.storage_path, '^${BUCKET}/', '')
      )
  )
RETURNING ka.id;
" | grep -c . || true)
echo "[migrate] deleted ${ORPHAN_COUNT} orphan attachment row(s)."

echo "[migrate] Step B: enumerating legacy unsplash rows…"
ROWS=$("${PSQL[@]}" -c "
SELECT ka.id || '|' || k.sender_id || '|' || ka.storage_path
FROM public.kudos_attachments ka
JOIN public.kudos k ON ka.kudos_id = k.id
WHERE ka.storage_path LIKE 'https://images.unsplash.com/%';
")
if [[ -z "${ROWS}" ]]; then
  echo "[migrate] no legacy unsplash rows remain — done."
  exit 0
fi
ROW_COUNT=$(printf '%s\n' "${ROWS}" | grep -c .)
echo "[migrate] found ${ROW_COUNT} row(s) to migrate."

TMPDIR_LOCAL=$(mktemp -d)
trap 'rm -rf "${TMPDIR_LOCAL}"' EXIT

MIGRATED=0
FAILED=0
while IFS='|' read -r ATT_ID SENDER_ID SRC_URL; do
  [[ -z "${ATT_ID}" ]] && continue
  NEW_PATH="${SENDER_ID}/${ATT_ID}.jpg"
  TMPFILE="${TMPDIR_LOCAL}/${ATT_ID}.jpg"

  echo "[migrate] ${ATT_ID} ← ${SRC_URL}"
  if ! curl -fsSL "${SRC_URL}" -o "${TMPFILE}"; then
    echo "[migrate]   download failed — skipping"
    FAILED=$((FAILED + 1))
    continue
  fi

  HTTP_CODE=$(curl -s -o /tmp/upload-resp.json -w '%{http_code}' \
    -X POST "${SUPABASE_URL}/storage/v1/object/${BUCKET}/${NEW_PATH}" \
    -H "apikey: ${SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
    -H "Content-Type: image/jpeg" \
    -H "x-upsert: true" \
    --data-binary "@${TMPFILE}")

  if [[ "${HTTP_CODE}" != "200" && "${HTTP_CODE}" != "201" ]]; then
    echo "[migrate]   upload failed (HTTP ${HTTP_CODE}): $(cat /tmp/upload-resp.json 2>/dev/null)"
    FAILED=$((FAILED + 1))
    continue
  fi

  BYTE_SIZE=$(wc -c <"${TMPFILE}" | tr -d ' ')
  "${PSQL[@]}" -c "
    UPDATE public.kudos_attachments
       SET storage_path = '${NEW_PATH}',
           byte_size    = ${BYTE_SIZE},
           content_type = 'image/jpeg'
     WHERE id = '${ATT_ID}';
  " >/dev/null
  echo "[migrate]   → ${NEW_PATH} (${BYTE_SIZE} bytes)"
  MIGRATED=$((MIGRATED + 1))
done <<< "${ROWS}"

echo "[migrate] done — migrated=${MIGRATED}, failed=${FAILED}, orphans_deleted=${ORPHAN_COUNT}"
