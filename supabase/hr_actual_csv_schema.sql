-- HR schema tailored to the provided CSV files.
-- Target files:
-- - 성모 직원 정보.csv
-- - 월별성모직원명단_1월.csv
-- - 1월성모직원급여.csv
--
-- Run this in Supabase SQL Editor before CSV upload.
--
-- Important payroll CSV note:
-- The payroll CSV has duplicate headers: 식대 and 위탁보육료.
-- Rename the payroll CSV headers before upload:
-- - first  식대      -> 식대_지급
-- - second 식대      -> 식대_공제
-- - first  위탁보육료 -> 위탁보육료_1
-- - second 위탁보육료 -> 위탁보육료_2
--
-- The CSV files do not include the target month. After upload, set it manually:
-- update public.staging_monthly_roster_csv set roster_month = '2026-01-01' where roster_month is null;
-- update public.staging_monthly_payroll_csv set payroll_month = '2026-01-01' where payroll_month is null;
-- Change the year/month above to the real payroll/roster month.

begin;

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

-- Raw staging table matching 성모 직원 정보.csv headers.
create table if not exists public.staging_employee_info_csv (
  "사원코드" text,
  "사원명" text,
  "부서코드" text,
  "부서명" text,
  "성별" text,
  "입사일" text,
  "중도퇴사일" text,
  "퇴직일" text,
  "재직구분코드" text,
  "재직구분명" text,
  "고용형태코드" text,
  "고용형태명" text,
  "직책코드" text,
  "직책명" text,
  "직종명" text,
  "프로젝트명" text,
  "직급명" text,
  source_file text default '성모 직원 정보.csv',
  imported_at timestamptz not null default now()
);

-- Raw staging table matching 월별성모직원명단_1월.csv headers.
-- 주민등록번호 is retained only in staging and is masked when moved to final rosters.
create table if not exists public.staging_monthly_roster_csv (
  "사원코드" text,
  "사원명" text,
  "주민등록번호" text,
  "부서명" text,
  "직책명" text,
  "입사일" text,
  "퇴사일" text,
  "재직기간" text,
  "그룹입사일" text,
  roster_month date,
  source_file text default '월별성모직원명단_1월.csv',
  imported_at timestamptz not null default now()
);

-- Raw staging table for 1월성모직원급여.csv after duplicate headers are renamed.
create table if not exists public.staging_monthly_payroll_csv (
  "부서" text,
  "사원코드" text,
  "사원명" text,
  "부서코드" text,
  "기본급" text,
  "식대_지급" text,
  "자가운전" text,
  "시간외수당" text,
  "야간근로수당" text,
  "야간정산수당" text,
  "휴일근로수당" text,
  "일숙직수당" text,
  "특수+교대수당" text,
  "처우개선비" text,
  "연차수당" text,
  "부서수당" text,
  "직급/직책수당" text,
  "직무수당" text,
  "보직수당" text,
  "근속/경력수당" text,
  "경력수당" text,
  "면허/자격수당" text,
  "기타" text,
  "당직비" text,
  "대기/당직수당" text,
  "간호간병평가인센티브" text,
  "야간간호특별수당" text,
  "경영성과금" text,
  "국고보조금" text,
  "정부지원금" text,
  "간호간병특별수당" text,
  "특별수당" text,
  "위탁보육료_1" text,
  "순환당직지원금" text,
  "위탁보육료_2" text,
  "상여" text,
  "지급합계" text,
  "급여합계" text,
  "국민연금" text,
  "건강보험" text,
  "고용보험" text,
  "학자금상환액" text,
  "사우회비" text,
  "기부금" text,
  "식대_공제" text,
  "주차장이용료" text,
  "기숙사비" text,
  "장기요양보험료" text,
  "장기요양보험정산" text,
  "건강보험료정산" text,
  "소득세" text,
  "지방소득세" text,
  "연말정산소득세" text,
  "연말정산지방소득세" text,
  "연말정산농특세" text,
  "공제합계" text,
  "차인지급액" text,
  payroll_month date,
  source_file text default '1월성모직원급여.csv',
  imported_at timestamptz not null default now()
);

create index if not exists idx_hr_employees_employee_code on public.hr_employees(employee_code);
create index if not exists idx_hr_employees_department_id on public.hr_employees(department_id);
create index if not exists idx_hr_monthly_rosters_month on public.hr_monthly_rosters(roster_month);
create index if not exists idx_hr_payroll_records_employee_code on public.hr_payroll_records(employee_code);

drop trigger if exists hr_set_updated_at_departments on public.hr_departments;
create trigger hr_set_updated_at_departments before update on public.hr_departments
for each row execute function public.hr_set_updated_at();

drop trigger if exists hr_set_updated_at_positions on public.hr_positions;
create trigger hr_set_updated_at_positions before update on public.hr_positions
for each row execute function public.hr_set_updated_at();

drop trigger if exists hr_set_updated_at_job_categories on public.hr_job_categories;
create trigger hr_set_updated_at_job_categories before update on public.hr_job_categories
for each row execute function public.hr_set_updated_at();

drop trigger if exists hr_set_updated_at_employees on public.hr_employees;
create trigger hr_set_updated_at_employees before update on public.hr_employees
for each row execute function public.hr_set_updated_at();

drop trigger if exists hr_set_updated_at_monthly_rosters on public.hr_monthly_rosters;
create trigger hr_set_updated_at_monthly_rosters before update on public.hr_monthly_rosters
for each row execute function public.hr_set_updated_at();

drop trigger if exists hr_set_updated_at_payroll_months on public.hr_payroll_months;
create trigger hr_set_updated_at_payroll_months before update on public.hr_payroll_months
for each row execute function public.hr_set_updated_at();

drop trigger if exists hr_set_updated_at_payroll_records on public.hr_payroll_records;
create trigger hr_set_updated_at_payroll_records before update on public.hr_payroll_records
for each row execute function public.hr_set_updated_at();

alter table public.hr_departments enable row level security;
alter table public.hr_positions enable row level security;
alter table public.hr_job_categories enable row level security;
alter table public.hr_employees enable row level security;
alter table public.hr_monthly_rosters enable row level security;
alter table public.hr_payroll_months enable row level security;
alter table public.hr_payroll_records enable row level security;
alter table public.staging_employee_info_csv enable row level security;
alter table public.staging_monthly_roster_csv enable row level security;
alter table public.staging_monthly_payroll_csv enable row level security;

commit;
