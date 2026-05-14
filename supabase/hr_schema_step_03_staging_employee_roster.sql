-- Step 03: staging tables for employee info and monthly roster CSV files.
-- Run after hr_schema_step_02_final_tables.sql.

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

select 'step_03_staging_employee_roster_ok' as result;
