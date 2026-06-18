# Supabase Rollback Scripts

These `*.rollback.sql` files are **paste-ready revert scripts**, not Supabase
CLI migrations. They live here (not in `supabase/migrations/`) because the
Supabase CLI processes every `<timestamp>_name.sql` in the migrations folder
in lexicographic order — and `.rollback.sql` sorts before `.sql`, so leaving
them in `migrations/` causes the CLI to try the rollback BEFORE the forward
migration (which fails with `relation does not exist`).

## How to apply a rollback

Apply manually against the target DB, e.g.:

```bash
PGPASSWORD=postgres psql -h 127.0.0.1 -p 54322 -U postgres -d postgres \
  -f supabase/rollbacks/20260615161000_create_awards_table.rollback.sql
```

For the remote project, paste the contents into the Supabase Studio SQL editor.

## Convention

- One rollback per forward migration (or per migration pair that must revert together).
- Filename: `<same timestamp as forward>_<same name>.rollback.sql`.
- Use `if exists` / `if not exists` clauses so the script is idempotent against partial states.
