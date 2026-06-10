-- 20260610145900_create_profiles_table
-- Creates the public.profiles table linked to auth.users.
-- Populated automatically by the handle_new_user trigger (migration 20260610145902).

create table if not exists public.profiles (
  id         uuid        primary key references auth.users(id) on delete cascade,
  email      text        not null unique,
  name       text,
  avatar_url text,
  provider   text        not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists profiles_email_idx on public.profiles (email);
