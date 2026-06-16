-- 20260616120800_drop_redundant_profiles_email_idx
-- Drops the explicit B-tree index on public.profiles(email).
--
-- Rationale: the `email text not null unique` column constraint declared in
-- 20260610145900_create_profiles_table.sql already creates an implicit
-- B-tree unique index (`profiles_email_key`). That index covers every access
-- pattern an additional plain (email) index would serve — equality lookups
-- (WHERE email = $1), IN-lists, ordered scans, prefix LIKE.
--
-- Keeping both costs write-amplification on every INSERT/UPDATE that touches
-- `email`, plus disk + shared_buffers occupancy, for zero read-path benefit.
-- A separate index would only be justified if it differed in shape — e.g.
-- functional `lower(email)` for case-insensitive lookups, trigram for
-- fuzzy search, or a partial WHERE predicate. None apply here.

drop index if exists public.profiles_email_idx;
