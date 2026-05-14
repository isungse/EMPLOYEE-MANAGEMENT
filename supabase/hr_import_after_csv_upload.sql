-- Run this after importing all three CSV files into staging tables.
--
-- Required before running:
-- 1. Set the real month on staging rows:
--    update public.staging_monthly_roster_csv set roster_month = '2026-01-01' where roster_month is null;
--    update public.staging_monthly_payroll_csv set payroll_month = '2026-01-01' where payroll_month is null;
-- 2. Replace 2026-01-01 with the actual year/month if different.

do $$
declare
  missing_tables text[];
begin
  select array_agg(table_name order by table_name)
  into missing_tables
  from (
    values
      ('hr_departments'),
      ('hr_positions'),
      ('hr_job_categories'),
      ('hr_employees'),
      ('hr_monthly_rosters'),
      ('hr_payroll_months'),
      ('hr_payroll_records'),
      ('staging_employee_info_csv'),
      ('staging_monthly_roster_csv'),
      ('staging_monthly_payroll_csv')
  ) as required(table_name)
  where to_regclass('public.' || required.table_name) is null;

  if missing_tables is not null then
    raise exception 'HR schema is not ready. Run hr_actual_csv_schema.sql first. Missing tables: %', array_to_string(missing_tables, ', ');
  end if;
end $$;

begin;

insert into public.hr_departments (department_code, department_name)
select distinct nullif(trim("부서코드"), ''), trim("부서명")
from public.staging_employee_info_csv
where nullif(trim("부서명"), '') is not null
on conflict (department_name) do update set
  department_code = coalesce(excluded.department_code, public.hr_departments.department_code);

insert into public.hr_departments (department_code, department_name)
select distinct nullif(trim("부서코드"), ''), trim("부서")
from public.staging_monthly_payroll_csv
where nullif(trim("부서"), '') is not null
on conflict (department_name) do update set
  department_code = coalesce(excluded.department_code, public.hr_departments.department_code);

insert into public.hr_departments (department_name)
select distinct trim("부서명")
from public.staging_monthly_roster_csv
where nullif(trim("부서명"), '') is not null
on conflict (department_name) do nothing;

insert into public.hr_positions (position_code, position_name)
select distinct nullif(trim("직책코드"), ''), trim("직책명")
from public.staging_employee_info_csv
where nullif(trim("직책명"), '') is not null
on conflict (position_name) do update set
  position_code = coalesce(excluded.position_code, public.hr_positions.position_code);

insert into public.hr_positions (position_name)
select distinct trim("직책명")
from public.staging_monthly_roster_csv
where nullif(trim("직책명"), '') is not null
on conflict (position_name) do nothing;

insert into public.hr_job_categories (job_category_name)
select distinct trim("직종명")
from public.staging_employee_info_csv
where nullif(trim("직종명"), '') is not null
on conflict (job_category_name) do nothing;

insert into public.hr_employees (
  employee_code,
  employee_name,
  gender,
  hire_date,
  mid_resignation_date,
  resignation_date,
  employment_status,
  employment_status_code,
  employment_status_name,
  employment_type_code,
  employment_type_name,
  department_id,
  position_id,
  job_category_id,
  project_name,
  grade_name,
  source_file
)
select
  trim(s."사원코드"),
  trim(s."사원명"),
  nullif(trim(s."성별"), ''),
  public.hr_parse_date(s."입사일"),
  public.hr_parse_date(s."중도퇴사일"),
  public.hr_parse_date(s."퇴직일"),
  public.hr_status(s."재직구분명"),
  nullif(trim(s."재직구분코드"), ''),
  nullif(trim(s."재직구분명"), ''),
  nullif(trim(s."고용형태코드"), ''),
  nullif(trim(s."고용형태명"), ''),
  d.id,
  p.id,
  j.id,
  nullif(trim(s."프로젝트명"), ''),
  nullif(trim(s."직급명"), ''),
  s.source_file
from public.staging_employee_info_csv s
left join public.hr_departments d on d.department_name = trim(s."부서명")
left join public.hr_positions p on p.position_name = trim(s."직책명")
left join public.hr_job_categories j on j.job_category_name = trim(s."직종명")
where nullif(trim(s."사원코드"), '') is not null
  and nullif(trim(s."사원명"), '') is not null
on conflict (employee_code) do update set
  employee_name = excluded.employee_name,
  gender = excluded.gender,
  hire_date = excluded.hire_date,
  mid_resignation_date = excluded.mid_resignation_date,
  resignation_date = excluded.resignation_date,
  employment_status = excluded.employment_status,
  employment_status_code = excluded.employment_status_code,
  employment_status_name = excluded.employment_status_name,
  employment_type_code = excluded.employment_type_code,
  employment_type_name = excluded.employment_type_name,
  department_id = excluded.department_id,
  position_id = excluded.position_id,
  job_category_id = excluded.job_category_id,
  project_name = excluded.project_name,
  grade_name = excluded.grade_name,
  source_file = excluded.source_file;

insert into public.hr_monthly_rosters (
  roster_month,
  employee_id,
  employee_code,
  employee_name,
  department_id,
  position_id,
  department_name_snapshot,
  position_name_snapshot,
  hire_date,
  resignation_date,
  group_hire_date,
  tenure_text,
  resident_registration_no_masked,
  source_file
)
select
  s.roster_month,
  e.id,
  trim(s."사원코드"),
  trim(s."사원명"),
  d.id,
  p.id,
  nullif(trim(s."부서명"), ''),
  nullif(trim(s."직책명"), ''),
  public.hr_parse_date(s."입사일"),
  public.hr_parse_date(s."퇴사일"),
  public.hr_parse_date(s."그룹입사일"),
  nullif(trim(s."재직기간"), ''),
  case
    when nullif(trim(s."주민등록번호"), '') is null then null
    when length(regexp_replace(s."주민등록번호", '[^0-9]', '', 'g')) >= 7
      then left(regexp_replace(s."주민등록번호", '[^0-9]', '', 'g'), 6) || '-*******'
    else null
  end,
  s.source_file
from public.staging_monthly_roster_csv s
left join public.hr_employees e on e.employee_code = trim(s."사원코드")
left join public.hr_departments d on d.department_name = trim(s."부서명")
left join public.hr_positions p on p.position_name = trim(s."직책명")
where s.roster_month is not null
  and nullif(trim(s."사원코드"), '') is not null
  and nullif(trim(s."사원명"), '') is not null
on conflict (roster_month, employee_code) do update set
  employee_id = excluded.employee_id,
  employee_name = excluded.employee_name,
  department_id = excluded.department_id,
  position_id = excluded.position_id,
  department_name_snapshot = excluded.department_name_snapshot,
  position_name_snapshot = excluded.position_name_snapshot,
  hire_date = excluded.hire_date,
  resignation_date = excluded.resignation_date,
  group_hire_date = excluded.group_hire_date,
  tenure_text = excluded.tenure_text,
  resident_registration_no_masked = excluded.resident_registration_no_masked,
  source_file = excluded.source_file;

insert into public.hr_payroll_months (payroll_month)
select distinct payroll_month
from public.staging_monthly_payroll_csv
where payroll_month is not null
on conflict (payroll_month) do nothing;

insert into public.hr_payroll_records (
  payroll_month_id,
  employee_id,
  employee_code,
  employee_name,
  department_id,
  department_name_snapshot,
  base_salary,
  taxable_earnings_total,
  earnings_total,
  statutory_deductions_total,
  deductions_total,
  net_pay,
  earnings_detail,
  deductions_detail,
  source_file
)
select
  pm.id,
  e.id,
  trim(s."사원코드"),
  trim(s."사원명"),
  d.id,
  nullif(trim(s."부서"), ''),
  public.hr_to_numeric(s."기본급"),
  public.hr_to_numeric(s."급여합계"),
  public.hr_to_numeric(s."지급합계"),
  public.hr_to_numeric(s."국민연금")
    + public.hr_to_numeric(s."건강보험")
    + public.hr_to_numeric(s."고용보험")
    + public.hr_to_numeric(s."장기요양보험료")
    + public.hr_to_numeric(s."소득세")
    + public.hr_to_numeric(s."지방소득세"),
  public.hr_to_numeric(s."공제합계"),
  public.hr_to_numeric(s."차인지급액"),
  jsonb_build_object(
    '기본급', public.hr_to_numeric(s."기본급"),
    '식대_지급', public.hr_to_numeric(s."식대_지급"),
    '자가운전', public.hr_to_numeric(s."자가운전"),
    '시간외수당', public.hr_to_numeric(s."시간외수당"),
    '야간근로수당', public.hr_to_numeric(s."야간근로수당"),
    '야간정산수당', public.hr_to_numeric(s."야간정산수당"),
    '휴일근로수당', public.hr_to_numeric(s."휴일근로수당"),
    '일숙직수당', public.hr_to_numeric(s."일숙직수당"),
    '특수+교대수당', public.hr_to_numeric(s."특수+교대수당"),
    '처우개선비', public.hr_to_numeric(s."처우개선비"),
    '연차수당', public.hr_to_numeric(s."연차수당"),
    '부서수당', public.hr_to_numeric(s."부서수당"),
    '직급/직책수당', public.hr_to_numeric(s."직급/직책수당"),
    '직무수당', public.hr_to_numeric(s."직무수당"),
    '보직수당', public.hr_to_numeric(s."보직수당"),
    '근속/경력수당', public.hr_to_numeric(s."근속/경력수당"),
    '경력수당', public.hr_to_numeric(s."경력수당"),
    '면허/자격수당', public.hr_to_numeric(s."면허/자격수당"),
    '기타', public.hr_to_numeric(s."기타"),
    '당직비', public.hr_to_numeric(s."당직비"),
    '대기/당직수당', public.hr_to_numeric(s."대기/당직수당"),
    '간호간병평가인센티브', public.hr_to_numeric(s."간호간병평가인센티브"),
    '야간간호특별수당', public.hr_to_numeric(s."야간간호특별수당"),
    '경영성과금', public.hr_to_numeric(s."경영성과금"),
    '국고보조금', public.hr_to_numeric(s."국고보조금"),
    '정부지원금', public.hr_to_numeric(s."정부지원금"),
    '간호간병특별수당', public.hr_to_numeric(s."간호간병특별수당"),
    '특별수당', public.hr_to_numeric(s."특별수당"),
    '위탁보육료_1', public.hr_to_numeric(s."위탁보육료_1"),
    '순환당직지원금', public.hr_to_numeric(s."순환당직지원금"),
    '위탁보육료_2', public.hr_to_numeric(s."위탁보육료_2"),
    '상여', public.hr_to_numeric(s."상여")
  ),
  jsonb_build_object(
    '국민연금', public.hr_to_numeric(s."국민연금"),
    '건강보험', public.hr_to_numeric(s."건강보험"),
    '고용보험', public.hr_to_numeric(s."고용보험"),
    '학자금상환액', public.hr_to_numeric(s."학자금상환액"),
    '사우회비', public.hr_to_numeric(s."사우회비"),
    '기부금', public.hr_to_numeric(s."기부금"),
    '식대_공제', public.hr_to_numeric(s."식대_공제"),
    '주차장이용료', public.hr_to_numeric(s."주차장이용료"),
    '기숙사비', public.hr_to_numeric(s."기숙사비"),
    '장기요양보험료', public.hr_to_numeric(s."장기요양보험료"),
    '장기요양보험정산', public.hr_to_numeric(s."장기요양보험정산"),
    '건강보험료정산', public.hr_to_numeric(s."건강보험료정산"),
    '소득세', public.hr_to_numeric(s."소득세"),
    '지방소득세', public.hr_to_numeric(s."지방소득세"),
    '연말정산소득세', public.hr_to_numeric(s."연말정산소득세"),
    '연말정산지방소득세', public.hr_to_numeric(s."연말정산지방소득세"),
    '연말정산농특세', public.hr_to_numeric(s."연말정산농특세")
  ),
  s.source_file
from public.staging_monthly_payroll_csv s
join public.hr_payroll_months pm on pm.payroll_month = s.payroll_month
left join public.hr_employees e on e.employee_code = trim(s."사원코드")
left join public.hr_departments d on d.department_name = trim(s."부서")
where s.payroll_month is not null
  and nullif(trim(s."사원코드"), '') is not null
  and nullif(trim(s."사원명"), '') is not null
on conflict (payroll_month_id, employee_code) do update set
  employee_id = excluded.employee_id,
  employee_name = excluded.employee_name,
  department_id = excluded.department_id,
  department_name_snapshot = excluded.department_name_snapshot,
  base_salary = excluded.base_salary,
  taxable_earnings_total = excluded.taxable_earnings_total,
  earnings_total = excluded.earnings_total,
  statutory_deductions_total = excluded.statutory_deductions_total,
  deductions_total = excluded.deductions_total,
  net_pay = excluded.net_pay,
  earnings_detail = excluded.earnings_detail,
  deductions_detail = excluded.deductions_detail,
  source_file = excluded.source_file;

commit;

-- Basic validation queries.
select 'staging_employee_info_csv' as table_name, count(*) as row_count from public.staging_employee_info_csv
union all
select 'staging_monthly_roster_csv', count(*) from public.staging_monthly_roster_csv
union all
select 'staging_monthly_payroll_csv', count(*) from public.staging_monthly_payroll_csv
union all
select 'hr_employees', count(*) from public.hr_employees
union all
select 'hr_monthly_rosters', count(*) from public.hr_monthly_rosters
union all
select 'hr_payroll_records', count(*) from public.hr_payroll_records;

select
  pm.payroll_month,
  count(*) as payroll_rows,
  sum(pr.earnings_total) as earnings_total,
  sum(pr.deductions_total) as deductions_total,
  sum(pr.net_pay) as net_pay_total
from public.hr_payroll_records pr
join public.hr_payroll_months pm on pm.id = pr.payroll_month_id
group by pm.payroll_month
order by pm.payroll_month;
