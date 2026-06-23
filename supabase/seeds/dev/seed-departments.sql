-- seed-departments
-- Seeds the canonical SAA organisational divisions.
-- Safe to re-run: upserts on code (unique key).

insert into public.departments (code, name)
values
  ('CEV1',  'Center of Excellence 1'),
  ('CEV2',  'Center of Excellence 2'),
  ('CEV3',  'Center of Excellence 3'),
  ('CEV4',  'Center of Excellence 4'),
  ('OPD',   'Operation Department'),
  ('INFRA', 'Infrastructure & DevOps'),
  ('BOD',   'Board of Directors')
on conflict (code) do update set
  name = excluded.name;
