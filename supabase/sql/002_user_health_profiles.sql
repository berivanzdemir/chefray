-- ============================================================================
-- 002_user_health_profiles
-- Seni Tanıyalım onboarding flow for ChefRay.
-- Adds profile_setup_completed flag to profiles and creates the dedicated
-- user_health_profiles table with RLS policies.
-- ============================================================================

-- 1. Extend profiles table ---------------------------------------------------
alter table public.profiles
add column if not exists profile_setup_completed boolean default false;

-- 2. Create user_health_profiles table ---------------------------------------
create table if not exists public.user_health_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  age int,
  gender text,
  height_cm numeric,
  weight_kg numeric,
  goal_type text,
  health_conditions text[],
  allergies text[],
  diet_preferences text[],
  activity_level text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  unique(user_id)
);

-- 3. Enable RLS --------------------------------------------------------------
alter table public.user_health_profiles enable row level security;

-- 4. RLS policies ------------------------------------------------------------
drop policy if exists "Users can view own health profile" on public.user_health_profiles;
create policy "Users can view own health profile"
on public.user_health_profiles
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own health profile" on public.user_health_profiles;
create policy "Users can insert own health profile"
on public.user_health_profiles
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can update own health profile" on public.user_health_profiles;
create policy "Users can update own health profile"
on public.user_health_profiles
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- 5. updated_at trigger ------------------------------------------------------
create or replace function public.handle_health_profile_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists user_health_profiles_updated_at on public.user_health_profiles;

create trigger user_health_profiles_updated_at
before update on public.user_health_profiles
for each row
execute function public.handle_health_profile_updated_at();
