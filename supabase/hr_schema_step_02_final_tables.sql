-- Step 02: final HR tables.
-- Run after hr_schema_step_01_core.sql.

create table if not exists public.hr_employees (
  id uuid primary key default gen_random_uuid(),
  employee_code text not null unique,
  employee_name text not null,
  gender text,
  hire_date date,
  mid_resignation_date date,
  resignation_date date,
  employment_status text not null default 'unknown'
    check (employment_status in ('active', 'leave', 'resigned', 'unknown')),
  employment_status_code text,
  employment_status_name text,
  employment_type_code text,
  employment_type_name text,
  department_id uuid references public.hr_departments(id) on delete set null,
  position_id uuid references public.hr_positions(id) on delete set null,
  job_category_id uuid references public.hr_job_categories(id) on delete set null,
  project_name text,
  grade_name text,
  source_file text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.hr_monthly_rosters (
  id uuid primary key default gen_random_uuid(),
  roster_month date not null,
  employee_id uuid references public.hr_employees(id) on delete set null,
  employee_code text not null,
  employee_name text not null,
  department_id uuid references public.hr_departments(id) on delete set null,
  position_id uuid references public.hr_positions(id) on delete set null,
  department_name_snapshot text,
  position_name_snapshot text,
  hire_date date,
  resignation_date date,
  group_hire_date date,
  tenure_text text,
  resident_registration_no_masked text,
  source_file text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (roster_month, employee_code)
);

create table if not exists public.hr_payroll_months (
  id uuid primary key default gen_random_uuid(),
  payroll_month date not null unique,
  status text not null default 'draft'
    check (status in ('draft', 'confirmed', 'paid', 'closed')),
  memo text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.hr_payroll_records (
  id uuid primary key default gen_random_uuid(),
  payroll_month_id uuid not null references public.hr_payroll_months(id) on delete cascade,
  employee_id uuid references public.hr_employees(id) on delete set null,
  employee_code text not null,
  employee_name text not null,
  department_id uuid references public.hr_departments(id) on delete set null,
  department_name_snapshot text,
  base_salary numeric(14, 2) not null default 0,
  taxable_earnings_total numeric(14, 2) not null default 0,
  earnings_total numeric(14, 2) not null default 0,
  statutory_deductions_total numeric(14, 2) not null default 0,
  deductions_total numeric(14, 2) not null default 0,
  net_pay numeric(14, 2) not null default 0,
  earnings_detail jsonb not null default '{}'::jsonb,
  deductions_detail jsonb not null default '{}'::jsonb,
  source_file text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (payroll_month_id, employee_code)
);

select 'step_02_final_tables_ok' as result;
