-- Step 05: indexes, triggers, and RLS.
-- Run after hr_schema_step_04_staging_payroll.sql.

create index if not exists idx_hr_employees_employee_code
on public.hr_employees(employee_code);

create index if not exists idx_hr_employees_department_id
on public.hr_employees(department_id);

create index if not exists idx_hr_monthly_rosters_month
on public.hr_monthly_rosters(roster_month);

create index if not exists idx_hr_payroll_records_employee_code
on public.hr_payroll_records(employee_code);

drop trigger if exists hr_set_updated_at_departments on public.hr_departments;
create trigger hr_set_updated_at_departments
before update on public.hr_departments
for each row execute function public.hr_set_updated_at();

drop trigger if exists hr_set_updated_at_positions on public.hr_positions;
create trigger hr_set_updated_at_positions
before update on public.hr_positions
for each row execute function public.hr_set_updated_at();

drop trigger if exists hr_set_updated_at_job_categories on public.hr_job_categories;
create trigger hr_set_updated_at_job_categories
before update on public.hr_job_categories
for each row execute function public.hr_set_updated_at();

drop trigger if exists hr_set_updated_at_employees on public.hr_employees;
create trigger hr_set_updated_at_employees
before update on public.hr_employees
for each row execute function public.hr_set_updated_at();

drop trigger if exists hr_set_updated_at_monthly_rosters on public.hr_monthly_rosters;
create trigger hr_set_updated_at_monthly_rosters
before update on public.hr_monthly_rosters
for each row execute function public.hr_set_updated_at();

drop trigger if exists hr_set_updated_at_payroll_months on public.hr_payroll_months;
create trigger hr_set_updated_at_payroll_months
before update on public.hr_payroll_months
for each row execute function public.hr_set_updated_at();

drop trigger if exists hr_set_updated_at_payroll_records on public.hr_payroll_records;
create trigger hr_set_updated_at_payroll_records
before update on public.hr_payroll_records
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

select 'step_05_indexes_rls_ok' as result;
