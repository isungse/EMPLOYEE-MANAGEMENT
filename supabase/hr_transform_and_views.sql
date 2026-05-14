-- Transform raw CSV import tables into normalized HR tables and analytics views.
-- Target project: employee-management (mqvovjcveflkhfzpcdcu)

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

create or replace function public.hr_to_bigint(value text)
returns bigint
language sql
immutable
as $$
  select coalesce(nullif(regexp_replace(coalesce(value, ''), '[^0-9.-]', '', 'g'), '')::numeric, 0)::bigint;
$$;

create table if not exists public.code_master (
  id uuid primary key default gen_random_uuid(),
  code_group text not null,
  code_value text not null,
  display_name text not null,
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (code_group, code_value)
);

create table if not exists public.upload_column_mapping (
  id uuid primary key default gen_random_uuid(),
  file_type public.import_file_type not null,
  source_column_name text not null,
  standard_column_name text not null,
  is_required boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (file_type, source_column_name, standard_column_name)
);

alter table public.code_master enable row level security;
alter table public.upload_column_mapping enable row level security;

create or replace function public.process_hr_raw_imports()
returns table(section text, row_count bigint)
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.code_master (code_group, code_value, display_name, sort_order)
  values
    ('gender', '남', '남성', 1),
    ('gender', '여', '여성', 2),
    ('employment_status', '재직', '재직', 1),
    ('employment_status', '휴직', '휴직', 2),
    ('employment_status', '퇴직', '퇴직', 3),
    ('pay_status', 'paid', '지급', 1),
    ('pay_status', 'unpaid', '미지급', 2)
  on conflict (code_group, code_value) do update set
    display_name = excluded.display_name,
    sort_order = excluded.sort_order,
    updated_at = now();

  insert into public.employment_statuses (status_code, status_name, sort_order)
  select distinct nullif(trim("재직구분코드"), ''), trim("재직구분명"), 0
  from public.employee_info_imports
  where nullif(trim("재직구분코드"), '') is not null
    and nullif(trim("재직구분명"), '') is not null
  on conflict (status_code) do update set
    status_name = excluded.status_name,
    updated_at = now();

  insert into public.employment_types (employment_type_code, employment_type_name, sort_order)
  select distinct nullif(trim("고용형태코드"), ''), trim("고용형태명"), 0
  from public.employee_info_imports
  where nullif(trim("고용형태코드"), '') is not null
    and nullif(trim("고용형태명"), '') is not null
  on conflict (employment_type_code) do update set
    employment_type_name = excluded.employment_type_name,
    updated_at = now();

  insert into public.departments (department_code, department_name)
  select department_code, department_name
  from (
    select distinct on (trim("부서명"))
      nullif(trim("부서코드"), '') as department_code,
      trim("부서명") as department_name
    from public.employee_info_imports
    where nullif(trim("부서명"), '') is not null
    order by trim("부서명"), nullif(trim("부서코드"), '') nulls last
  ) x
  on conflict (department_name) do update set
    department_code = coalesce(excluded.department_code, public.departments.department_code),
    updated_at = now();

  insert into public.departments (department_code, department_name)
  select department_code, department_name
  from (
    select distinct on (trim("부서"))
      nullif(trim("부서코드"), '') as department_code,
      trim("부서") as department_name
    from public.payroll_imports
    where nullif(trim("부서"), '') is not null
    order by trim("부서"), nullif(trim("부서코드"), '') nulls last
  ) x
  on conflict (department_name) do update set
    department_code = coalesce(excluded.department_code, public.departments.department_code),
    updated_at = now();

  insert into public.positions (position_code, position_name)
  select position_code, position_name
  from (
    select distinct on (trim("직책명"))
      nullif(trim("직책코드"), '') as position_code,
      trim("직책명") as position_name
    from public.employee_info_imports
    where nullif(trim("직책명"), '') is not null
    order by trim("직책명"), nullif(trim("직책코드"), '') nulls last
  ) x
  on conflict (position_name) do update set
    position_code = coalesce(excluded.position_code, public.positions.position_code),
    updated_at = now();

  insert into public.positions (position_name)
  select distinct trim("직책명")
  from public.monthly_roster_imports
  where nullif(trim("직책명"), '') is not null
  on conflict (position_name) do nothing;

  insert into public.job_categories (job_category_name)
  select distinct trim("직종명")
  from public.employee_info_imports
  where nullif(trim("직종명"), '') is not null
  on conflict (job_category_name) do nothing;

  insert into public.grades (grade_name)
  select distinct trim("직급명")
  from public.employee_info_imports
  where nullif(trim("직급명"), '') is not null
  on conflict (grade_name) do nothing;

  insert into public.projects (project_name)
  select distinct trim("프로젝트명")
  from public.employee_info_imports
  where nullif(trim("프로젝트명"), '') is not null
  on conflict (project_name) do nothing;

  insert into public.employees (
    employee_code, employee_name, gender, department_id, hire_date,
    interim_resignation_date, retirement_date, employment_status_id,
    employment_type_id, position_id, job_category_id, project_id, grade_id, raw_metadata
  )
  select
    trim(s."사원코드"),
    trim(s."사원명"),
    nullif(trim(s."성별"), ''),
    d.id,
    public.hr_parse_date(s."입사일"),
    public.hr_parse_date(s."중도퇴사일"),
    public.hr_parse_date(s."퇴직일"),
    es.id,
    et.id,
    p.id,
    jc.id,
    pr.id,
    g.id,
    to_jsonb(s) - 'id' - 'imported_at'
  from public.employee_info_imports s
  left join public.departments d on d.department_name = trim(s."부서명")
  left join public.employment_statuses es on es.status_code = trim(s."재직구분코드")
  left join public.employment_types et on et.employment_type_code = trim(s."고용형태코드")
  left join public.positions p on p.position_name = trim(s."직책명")
  left join public.job_categories jc on jc.job_category_name = trim(s."직종명")
  left join public.projects pr on pr.project_name = trim(s."프로젝트명")
  left join public.grades g on g.grade_name = trim(s."직급명")
  where nullif(trim(s."사원코드"), '') is not null
    and nullif(trim(s."사원명"), '') is not null
  on conflict (employee_code) do update set
    employee_name = excluded.employee_name,
    gender = excluded.gender,
    department_id = excluded.department_id,
    hire_date = excluded.hire_date,
    interim_resignation_date = excluded.interim_resignation_date,
    retirement_date = excluded.retirement_date,
    employment_status_id = excluded.employment_status_id,
    employment_type_id = excluded.employment_type_id,
    position_id = excluded.position_id,
    job_category_id = excluded.job_category_id,
    project_id = excluded.project_id,
    grade_id = excluded.grade_id,
    raw_metadata = excluded.raw_metadata,
    updated_at = now();

  insert into public.employee_sensitive_infos (
    employee_id, resident_registration_no_hash, resident_registration_no_masked, raw_metadata
  )
  select
    e.id,
    encode(digest(regexp_replace(coalesce(r."주민등록번호", ''), '[^0-9]', '', 'g'), 'sha256'), 'hex'),
    case
      when length(regexp_replace(coalesce(r."주민등록번호", ''), '[^0-9]', '', 'g')) >= 7
        then left(regexp_replace(r."주민등록번호", '[^0-9]', '', 'g'), 6) || '-*******'
      else null
    end,
    jsonb_build_object('source', 'monthly_roster_imports')
  from (
    select distinct on ("사원코드") *
    from public.monthly_roster_imports
    where nullif(trim("사원코드"), '') is not null
      and nullif(trim("주민등록번호"), '') is not null
    order by "사원코드", roster_month desc
  ) r
  join public.employees e on e.employee_code = trim(r."사원코드")
  on conflict (employee_id) do update set
    resident_registration_no_hash = excluded.resident_registration_no_hash,
    resident_registration_no_masked = excluded.resident_registration_no_masked,
    updated_at = now();

  insert into public.monthly_employee_rosters (
    roster_month, employee_id, employee_code_snapshot, employee_name_snapshot,
    department_id, department_name_snapshot, position_id, position_name_snapshot,
    hire_date, resignation_date, tenure_text, group_hire_date, source_row_no, raw_data
  )
  select
    r.roster_month,
    e.id,
    trim(r."사원코드"),
    nullif(trim(r."사원명"), ''),
    d.id,
    nullif(trim(r."부서명"), ''),
    p.id,
    nullif(trim(r."직책명"), ''),
    public.hr_parse_date(r."입사일"),
    public.hr_parse_date(r."퇴사일"),
    nullif(trim(r."재직기간"), ''),
    public.hr_parse_date(r."그룹입사일"),
    r.id::integer,
    to_jsonb(r) - '주민등록번호'
  from public.monthly_roster_imports r
  left join public.employees e on e.employee_code = trim(r."사원코드")
  left join public.departments d on d.department_name = trim(r."부서명")
  left join public.positions p on p.position_name = trim(r."직책명")
  where r.roster_month is not null
    and nullif(trim(r."사원코드"), '') is not null
  on conflict (roster_month, employee_code_snapshot) do update set
    employee_id = excluded.employee_id,
    employee_name_snapshot = excluded.employee_name_snapshot,
    department_id = excluded.department_id,
    department_name_snapshot = excluded.department_name_snapshot,
    position_id = excluded.position_id,
    position_name_snapshot = excluded.position_name_snapshot,
    hire_date = excluded.hire_date,
    resignation_date = excluded.resignation_date,
    tenure_text = excluded.tenure_text,
    group_hire_date = excluded.group_hire_date,
    source_row_no = excluded.source_row_no,
    raw_data = excluded.raw_data,
    updated_at = now();

  insert into public.payroll_periods (period_month, period_name)
  select distinct payroll_month, to_char(payroll_month, 'YYYY-MM')
  from public.payroll_imports
  where payroll_month is not null
  on conflict (period_month) do update set
    period_name = excluded.period_name,
    updated_at = now();

  insert into public.payroll_records (
    payroll_period_id, employee_id, employee_code_snapshot, employee_name_snapshot,
    department_id, department_code_snapshot, department_name_snapshot,
    base_salary, earning_total, salary_total, deduction_total, net_payment,
    source_row_no, raw_data
  )
  select
    pp.id,
    e.id,
    trim(p."사원코드"),
    nullif(trim(p."사원명"), ''),
    d.id,
    nullif(trim(p."부서코드"), ''),
    nullif(trim(p."부서"), ''),
    greatest(public.hr_to_bigint(p."기본급"), 0),
    greatest(public.hr_to_bigint(p."지급합계"), 0),
    greatest(public.hr_to_bigint(p."급여합계"), 0),
    abs(public.hr_to_bigint(p."공제합계")),
    public.hr_to_bigint(p."차인지급액"),
    p.id::integer,
    to_jsonb(p)
  from public.payroll_imports p
  join public.payroll_periods pp on pp.period_month = p.payroll_month
  left join public.employees e on e.employee_code = trim(p."사원코드")
  left join public.departments d on d.department_name = trim(p."부서")
  where p.payroll_month is not null
    and nullif(trim(p."사원코드"), '') is not null
  on conflict (payroll_period_id, employee_code_snapshot) do update set
    employee_id = excluded.employee_id,
    employee_name_snapshot = excluded.employee_name_snapshot,
    department_id = excluded.department_id,
    department_code_snapshot = excluded.department_code_snapshot,
    department_name_snapshot = excluded.department_name_snapshot,
    base_salary = excluded.base_salary,
    earning_total = excluded.earning_total,
    salary_total = excluded.salary_total,
    deduction_total = excluded.deduction_total,
    net_payment = excluded.net_payment,
    source_row_no = excluded.source_row_no,
    raw_data = excluded.raw_data,
    updated_at = now();

  delete from public.payroll_line_items;

  insert into public.payroll_line_items (payroll_record_id, component_type_id, amount, raw_value)
  select
    pr.id,
    pct.id,
    public.hr_to_bigint(src.row_json ->> cm.import_column),
    src.row_json ->> cm.import_column
  from (
    select pi.*, to_jsonb(pi) as row_json
    from public.payroll_imports pi
  ) src
  join public.payroll_periods pp on pp.period_month = src.payroll_month
  join public.payroll_records pr
    on pr.payroll_period_id = pp.id
   and pr.employee_code_snapshot = trim(src."사원코드")
  cross join public.payroll_component_types pct
  join (
    values
      ('earning_col_05','기본급'),('earning_col_06','식대_지급'),('earning_col_07','자가운전'),('earning_col_08','시간외수당'),
      ('earning_col_09','야간근로수당'),('earning_col_10','야간정산수당'),('earning_col_11','휴일근로수당'),('earning_col_12','일숙직수당'),
      ('earning_col_13','특수+교대수당'),('earning_col_14','처우개선비'),('earning_col_15','연차수당'),('earning_col_16','부서수당'),
      ('earning_col_17','직급/직책수당'),('earning_col_18','직무수당'),('earning_col_19','보직수당'),('earning_col_20','근속/경력수당'),
      ('earning_col_21','경력수당'),('earning_col_22','면허/자격수당'),('earning_col_23','기타'),('earning_col_24','당직비'),
      ('earning_col_25','대기/당직수당'),('earning_col_26','간호간병평가인센티브'),('earning_col_27','야간간호특별수당'),('earning_col_28','경영성과금'),
      ('earning_col_29','국고보조금'),('earning_col_30','정부지원금'),('earning_col_31','간호간병특별수당'),('earning_col_32','특별수당'),
      ('earning_col_33','위탁보육료_1'),('earning_col_34','순환당직지원금'),('earning_col_35','위탁보육료_2'),('earning_col_36','상여'),
      ('deduction_col_39','국민연금'),('deduction_col_40','건강보험'),('deduction_col_41','고용보험'),('deduction_col_42','학자금상환액'),
      ('deduction_col_43','사우회비'),('deduction_col_44','기부금'),('deduction_col_45','식대_공제'),('deduction_col_46','주차장이용료'),
      ('deduction_col_47','기숙사비'),('deduction_col_48','장기요양보험료'),('deduction_col_49','장기요양보험정산'),('deduction_col_50','건강보험료정산'),
      ('deduction_col_51','소득세'),('deduction_col_52','지방소득세'),('deduction_col_53','연말정산소득세'),('deduction_col_54','연말정산지방소득세'),
      ('deduction_col_55','연말정산농특세')
  ) as cm(component_code, import_column) on cm.component_code = pct.component_code
  where pct.is_active = true;

  return query
  select 'employees', count(*) from public.employees
  union all select 'monthly_employee_rosters', count(*) from public.monthly_employee_rosters
  union all select 'payroll_records', count(*) from public.payroll_records
  union all select 'payroll_line_items', count(*) from public.payroll_line_items;
end;
$$;

create or replace view public.v_monthly_gender_stats as
select
  mer.roster_month as period_month,
  coalesce(jc.job_category_name, '미지정') as job_category_name,
  count(*)::bigint as total_count,
  count(*) filter (where e.gender in ('남', 'male'))::bigint as male_count,
  count(*) filter (where e.gender in ('여', 'female'))::bigint as female_count,
  round(count(*) filter (where e.gender in ('남', 'male'))::numeric * 100 / nullif(count(*), 0), 2) as male_ratio,
  round(count(*) filter (where e.gender in ('여', 'female'))::numeric * 100 / nullif(count(*), 0), 2) as female_ratio
from public.monthly_employee_rosters mer
left join public.employees e on e.id = mer.employee_id
left join public.job_categories jc on jc.id = e.job_category_id
group by mer.roster_month, coalesce(jc.job_category_name, '미지정');

create or replace view public.v_monthly_payroll_stats as
select
  pp.period_month,
  coalesce(jc.job_category_name, '미지정') as job_category_name,
  count(*)::bigint as payroll_count,
  sum(pr.net_payment)::bigint as net_payment_total,
  count(*) filter (where pr.net_payment > 0)::bigint as average_target_count,
  count(*) filter (where pr.net_payment = 0)::bigint as zero_payment_count,
  round(sum(pr.net_payment) filter (where pr.net_payment > 0)::numeric / nullif(count(*) filter (where pr.net_payment > 0), 0), 0) as net_payment_average
from public.payroll_records pr
join public.payroll_periods pp on pp.id = pr.payroll_period_id
left join public.employees e on e.id = pr.employee_id
left join public.job_categories jc on jc.id = e.job_category_id
group by pp.period_month, coalesce(jc.job_category_name, '미지정');

create or replace view public.v_monthly_hire_retire_stats as
select
  mer.roster_month as period_month,
  coalesce(jc.job_category_name, '미지정') as job_category_name,
  count(*)::bigint as base_count,
  count(*) filter (
    where e.hire_date >= mer.roster_month
      and e.hire_date < (mer.roster_month + interval '1 month')::date
  )::bigint as hire_count,
  count(*) filter (
    where coalesce(e.retirement_date, mer.resignation_date) >= mer.roster_month
      and coalesce(e.retirement_date, mer.resignation_date) < (mer.roster_month + interval '1 month')::date
  )::bigint as retirement_count,
  round(count(*) filter (
    where e.hire_date >= mer.roster_month
      and e.hire_date < (mer.roster_month + interval '1 month')::date
  )::numeric * 100 / nullif(count(*), 0), 2) as hire_ratio,
  round(count(*) filter (
    where coalesce(e.retirement_date, mer.resignation_date) >= mer.roster_month
      and coalesce(e.retirement_date, mer.resignation_date) < (mer.roster_month + interval '1 month')::date
  )::numeric * 100 / nullif(count(*), 0), 2) as retirement_ratio
from public.monthly_employee_rosters mer
left join public.employees e on e.id = mer.employee_id
left join public.job_categories jc on jc.id = e.job_category_id
group by mer.roster_month, coalesce(jc.job_category_name, '미지정');

create or replace view public.v_dashboard_monthly_summary as
select
  g.period_month,
  sum(g.total_count)::bigint as total_employees,
  coalesce(sum(h.hire_count), 0)::bigint as hire_count,
  coalesce(sum(h.retirement_count), 0)::bigint as retirement_count,
  coalesce(sum(p.net_payment_total), 0)::bigint as net_payment_total,
  round(avg(p.net_payment_average) filter (where p.net_payment_average is not null), 0) as net_payment_average
from public.v_monthly_gender_stats g
left join public.v_monthly_hire_retire_stats h
  on h.period_month = g.period_month
 and h.job_category_name = g.job_category_name
left join public.v_monthly_payroll_stats p
  on p.period_month = g.period_month
 and p.job_category_name = g.job_category_name
group by g.period_month;
