-- Reset only the HR tables/functions created by the initial HR import scripts.
-- Use this if you accidentally ran hr_initial_schema.sql or need to recreate the schema.
--
-- WARNING:
-- This deletes HR import tables and loaded HR data.
-- Do not run this after production data is entered unless you intentionally want to reset.

begin;

drop table if exists public.hr_payroll_records cascade;
drop table if exists public.hr_payroll_months cascade;
drop table if exists public.hr_monthly_rosters cascade;
drop table if exists public.hr_employees cascade;
drop table if exists public.hr_job_categories cascade;
drop table if exists public.hr_positions cascade;
drop table if exists public.hr_departments cascade;

drop table if exists public.staging_monthly_payroll_csv cascade;
drop table if exists public.staging_monthly_roster_csv cascade;
drop table if exists public.staging_employee_info_csv cascade;

drop table if exists public.staging_monthly_payrolls cascade;
drop table if exists public.staging_monthly_employee_rosters cascade;
drop table if exists public.staging_employee_info cascade;

drop function if exists public.hr_status(text);
drop function if exists public.hr_to_numeric(text);
drop function if exists public.hr_parse_date(text);
drop function if exists public.hr_set_updated_at();
drop function if exists public.set_updated_at();

commit;
