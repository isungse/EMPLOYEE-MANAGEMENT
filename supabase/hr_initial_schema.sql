-- HR management initial schema for Supabase/Postgres.
-- Paste this whole file into the Supabase SQL Editor and run it once.
--
-- Flow:
-- 1. Import CSV files into the staging_* tables.
-- 2. Inspect and clean staging data.
-- 3. Run the optional INSERT statements near the bottom to move data into final tables.

begin;

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table if not exists public.hr_departments (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid references public.hr_departments(id) on delete set null,
  name text not null,
  code text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (name),
  unique (code)
);

create table if not exists public.hr_positions (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  code text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (name),
  unique (code)
);

create table if not exists public.hr_employees (
  id uuid primary key default gen_random_uuid(),
  employee_no text not null,
  full_name text not null,
  full_name_en text,
  email text,
  phone text,
  birth_date date,
  gender text check (gender is null or gender in ('male', 'female', 'other', 'unknown')),
  hire_date date,
  resignation_date date,
  employment_status text not null default 'active'
    check (employment_status in ('active', 'leave', 'resigned', 'retired', 'pending')),
  employment_type text,
  department_id uuid references public.hr_departments(id) on delete set null,
  position_id uuid references public.hr_positions(id) on delete set null,
  job_title text,
  work_location text,
  bank_name text,
  bank_account_no text,
  address text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (employee_no)
);

create table if not exists public.hr_monthly_rosters (
  id uuid primary key default gen_random_uuid(),
  roster_month date not null,
  employee_id uuid references public.hr_employees(id) on delete cascade,
  employee_no text not null,
  full_name text not null,
  department_id uuid references public.hr_departments(id) on delete set null,
  position_id uuid references public.hr_positions(id) on delete set null,
  department_name_snapshot text,
  position_name_snapshot text,
  employment_status text not null default 'active'
    check (employment_status in ('active', 'leave', 'resigned', 'retired', 'pending')),
  employment_type text,
  hire_date date,
  resignation_date date,
  work_location text,
  source_file text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (roster_month, employee_no)
);

create table if not exists public.hr_payroll_months (
  id uuid primary key default gen_random_uuid(),
  payroll_month date not null unique,
  payment_date date,
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
  employee_no text not null,
  full_name text not null,
  department_name_snapshot text,
  position_name_snapshot text,
  base_salary numeric(14, 2) not null default 0,
  overtime_pay numeric(14, 2) not null default 0,
  bonus numeric(14, 2) not null default 0,
  meal_allowance numeric(14, 2) not null default 0,
  transport_allowance numeric(14, 2) not null default 0,
  other_allowance numeric(14, 2) not null default 0,
  gross_pay numeric(14, 2) not null default 0,
  income_tax numeric(14, 2) not null default 0,
  local_income_tax numeric(14, 2) not null default 0,
  national_pension numeric(14, 2) not null default 0,
  health_insurance numeric(14, 2) not null default 0,
  long_term_care_insurance numeric(14, 2) not null default 0,
  employment_insurance numeric(14, 2) not null default 0,
  other_deduction numeric(14, 2) not null default 0,
  total_deduction numeric(14, 2) not null default 0,
  net_pay numeric(14, 2) not null default 0,
  source_file text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (payroll_month_id, employee_no)
);

-- CSV import staging tables.
-- If your actual CSV headers differ, rename the CSV headers to these names before import,
-- or adjust these staging columns before running the import.

create table if not exists public.staging_employee_info (
  id bigserial primary key,
  employee_no text,
  full_name text,
  full_name_en text,
  email text,
  phone text,
  birth_date text,
  gender text,
  hire_date text,
  resignation_date text,
  employment_status text,
  employment_type text,
  department_name text,
  parent_department_name text,
  position_name text,
  job_title text,
  work_location text,
  bank_name text,
  bank_account_no text,
  address text,
  notes text,
  source_file text,
  imported_at timestamptz not null default now()
);

create table if not exists public.staging_monthly_employee_rosters (
  id bigserial primary key,
  roster_month text,
  employee_no text,
  full_name text,
  department_name text,
  parent_department_name text,
  position_name text,
  employment_status text,
  employment_type text,
  hire_date text,
  resignation_date text,
  work_location text,
  source_file text,
  imported_at timestamptz not null default now()
);

create table if not exists public.staging_monthly_payrolls (
  id bigserial primary key,
  payroll_month text,
  payment_date text,
  employee_no text,
  full_name text,
  department_name text,
  position_name text,
  base_salary text,
  overtime_pay text,
  bonus text,
  meal_allowance text,
  transport_allowance text,
  other_allowance text,
  gross_pay text,
  income_tax text,
  local_income_tax text,
  national_pension text,
  health_insurance text,
  long_term_care_insurance text,
  employment_insurance text,
  other_deduction text,
  total_deduction text,
  net_pay text,
  notes text,
  source_file text,
  imported_at timestamptz not null default now()
);

create index if not exists idx_hr_employees_department_id on public.hr_employees(department_id);
create index if not exists idx_hr_employees_position_id on public.hr_employees(position_id);
create index if not exists idx_hr_monthly_rosters_month on public.hr_monthly_rosters(roster_month);
create index if not exists idx_hr_monthly_rosters_employee_no on public.hr_monthly_rosters(employee_no);
create index if not exists idx_hr_payroll_records_employee_no on public.hr_payroll_records(employee_no);

drop trigger if exists set_updated_at_hr_departments on public.hr_departments;
create trigger set_updated_at_hr_departments
before update on public.hr_departments
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_hr_positions on public.hr_positions;
create trigger set_updated_at_hr_positions
before update on public.hr_positions
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_hr_employees on public.hr_employees;
create trigger set_updated_at_hr_employees
before update on public.hr_employees
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_hr_monthly_rosters on public.hr_monthly_rosters;
create trigger set_updated_at_hr_monthly_rosters
before update on public.hr_monthly_rosters
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_hr_payroll_months on public.hr_payroll_months;
create trigger set_updated_at_hr_payroll_months
before update on public.hr_payroll_months
for each row execute function public.set_updated_at();

drop trigger if exists set_updated_at_hr_payroll_records on public.hr_payroll_records;
create trigger set_updated_at_hr_payroll_records
before update on public.hr_payroll_records
for each row execute function public.set_updated_at();

alter table public.hr_departments enable row level security;
alter table public.hr_positions enable row level security;
alter table public.hr_employees enable row level security;
alter table public.hr_monthly_rosters enable row level security;
alter table public.hr_payroll_months enable row level security;
alter table public.hr_payroll_records enable row level security;
alter table public.staging_employee_info enable row level security;
alter table public.staging_monthly_employee_rosters enable row level security;
alter table public.staging_monthly_payrolls enable row level security;

commit;

-- Optional data migration after CSV import.
-- Run these statements only after importing CSV data into staging tables.
-- Review parsing first if your CSV has dates or money formats different from YYYY-MM-DD and plain numbers.

/*
insert into public.hr_departments (name)
select distinct trim(department_name)
from public.staging_employee_info
where nullif(trim(department_name), '') is not null
on conflict (name) do nothing;

insert into public.hr_positions (name)
select distinct trim(position_name)
from public.staging_employee_info
where nullif(trim(position_name), '') is not null
on conflict (name) do nothing;

insert into public.hr_employees (
  employee_no, full_name, full_name_en, email, phone, birth_date, gender,
  hire_date, resignation_date, employment_status, employment_type,
  department_id, position_id, job_title, work_location, bank_name,
  bank_account_no, address, notes
)
select
  trim(s.employee_no),
  trim(s.full_name),
  nullif(trim(s.full_name_en), ''),
  nullif(trim(s.email), ''),
  nullif(trim(s.phone), ''),
  nullif(trim(s.birth_date), '')::date,
  coalesce(nullif(lower(trim(s.gender)), ''), 'unknown'),
  nullif(trim(s.hire_date), '')::date,
  nullif(trim(s.resignation_date), '')::date,
  coalesce(nullif(lower(trim(s.employment_status)), ''), 'active'),
  nullif(trim(s.employment_type), ''),
  d.id,
  p.id,
  nullif(trim(s.job_title), ''),
  nullif(trim(s.work_location), ''),
  nullif(trim(s.bank_name), ''),
  nullif(trim(s.bank_account_no), ''),
  nullif(trim(s.address), ''),
  nullif(trim(s.notes), '')
from public.staging_employee_info s
left join public.hr_departments d on d.name = trim(s.department_name)
left join public.hr_positions p on p.name = trim(s.position_name)
where nullif(trim(s.employee_no), '') is not null
  and nullif(trim(s.full_name), '') is not null
on conflict (employee_no) do update set
  full_name = excluded.full_name,
  full_name_en = excluded.full_name_en,
  email = excluded.email,
  phone = excluded.phone,
  birth_date = excluded.birth_date,
  gender = excluded.gender,
  hire_date = excluded.hire_date,
  resignation_date = excluded.resignation_date,
  employment_status = excluded.employment_status,
  employment_type = excluded.employment_type,
  department_id = excluded.department_id,
  position_id = excluded.position_id,
  job_title = excluded.job_title,
  work_location = excluded.work_location,
  bank_name = excluded.bank_name,
  bank_account_no = excluded.bank_account_no,
  address = excluded.address,
  notes = excluded.notes;

insert into public.hr_payroll_months (payroll_month, payment_date)
select distinct
  (date_trunc('month', nullif(trim(payroll_month), '')::date))::date,
  nullif(trim(payment_date), '')::date
from public.staging_monthly_payrolls
where nullif(trim(payroll_month), '') is not null
on conflict (payroll_month) do update set
  payment_date = coalesce(excluded.payment_date, public.hr_payroll_months.payment_date);
*/
