-- Step 01: core helpers and master tables.

create extension if not exists pgcrypto;

create or replace function public.hr_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.hr_parse_date(value text)
returns date
language sql
immutable
as $$
  select case
    when nullif(trim(value), '') is null then null
    when trim(value) ~ '^\d{4}[/-]\d{1,2}[/-]\d{1,2}$'
      then replace(trim(value), '/', '-')::date
    when trim(value) ~ '^\d{4}\.\d{1,2}\.\d{1,2}$'
      then replace(trim(value), '.', '-')::date
    else null
  end;
$$;

create or replace function public.hr_to_numeric(value text)
returns numeric
language sql
immutable
as $$
  select coalesce(nullif(regexp_replace(value, '[^0-9.-]', '', 'g'), '')::numeric, 0);
$$;

create or replace function public.hr_status(value text)
returns text
language sql
immutable
as $$
  select case trim(coalesce(value, ''))
    when '재직' then 'active'
    when '휴직' then 'leave'
    when '퇴직' then 'resigned'
    else 'unknown'
  end;
$$;

create table if not exists public.hr_departments (
  id uuid primary key default gen_random_uuid(),
  department_code text unique,
  department_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (department_name)
);

create table if not exists public.hr_positions (
  id uuid primary key default gen_random_uuid(),
  position_code text unique,
  position_name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (position_name)
);

create table if not exists public.hr_job_categories (
  id uuid primary key default gen_random_uuid(),
  job_category_name text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

select 'step_01_core_ok' as result;
