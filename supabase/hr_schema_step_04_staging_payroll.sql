-- Step 04: staging table for payroll CSV.
-- Run after hr_schema_step_03_staging_employee_roster.sql.
--
-- Before upload, the payroll CSV duplicate headers must be renamed:
-- first  식대      -> 식대_지급
-- second 식대      -> 식대_공제
-- first  위탁보육료 -> 위탁보육료_1
-- second 위탁보육료 -> 위탁보육료_2

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

select 'step_04_staging_payroll_ok' as result;
