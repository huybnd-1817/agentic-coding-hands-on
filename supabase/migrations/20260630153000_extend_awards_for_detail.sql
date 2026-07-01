-- 20260630153000_extend_awards_for_detail
-- Extends public.awards with five columns required by the Award Detail screen.
-- Idempotent: uses ADD COLUMN IF NOT EXISTS.
-- RLS policies from 20260615161001_awards_rls.sql remain unchanged (SELECT to authenticated).

ALTER TABLE public.awards
  ADD COLUMN IF NOT EXISTS quantity                INTEGER NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS quantity_unit           TEXT    NOT NULL DEFAULT 'Cá nhân',
  ADD COLUMN IF NOT EXISTS prize_value_individual  TEXT    NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS prize_value_team        TEXT,
  ADD COLUMN IF NOT EXISTS prize_note              TEXT    NOT NULL DEFAULT 'cho mỗi giải thưởng';

-- Backfill per Figma per-variant values.
-- Only signature_2026_creator receives a non-null prize_value_team.
UPDATE public.awards
SET quantity = 10, quantity_unit = 'Cá nhân', prize_value_individual = '7.000.000 VNĐ', prize_note = 'cho mỗi giải thưởng'
WHERE code = 'top_talent';

UPDATE public.awards
SET quantity = 3, quantity_unit = 'Cá nhân', prize_value_individual = '7.000.000 VNĐ', prize_note = 'cho mỗi giải thưởng'
WHERE code = 'top_project_leader';

UPDATE public.awards
SET quantity = 1, quantity_unit = 'Cá nhân', prize_value_individual = '10.000.000 VNĐ', prize_note = 'cho mỗi giải thưởng'
WHERE code = 'best_manager';

UPDATE public.awards
SET quantity = 1, quantity_unit = 'Cá nhân hoặc tập thể', prize_value_individual = '5.000.000 VNĐ', prize_value_team = '8.000.000 VNĐ', prize_note = 'cho giải cá nhân'
WHERE code = 'signature_2026_creator';

UPDATE public.awards
SET quantity = 1, quantity_unit = 'Cá nhân', prize_value_individual = '15.000.000 VNĐ', prize_note = 'cho giải cá nhân'
WHERE code = 'mvp';

UPDATE public.awards
SET quantity = 2, quantity_unit = 'Tập thể', prize_value_individual = '15.000.000 VNĐ', prize_note = 'cho mỗi giải thưởng'
WHERE code = 'top_project';
