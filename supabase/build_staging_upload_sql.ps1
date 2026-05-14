param(
  [string]$InputDir = ".\supabase\upload_ready",
  [string]$OutputPath = ".\supabase\upload_ready\hr_upload_staging_data.sql"
)

$ErrorActionPreference = "Stop"

function Convert-CsvToJsonLiteral {
  param(
    [Parameter(Mandatory = $true)][string]$Path
  )

  $rows = Import-Csv -LiteralPath $Path
  $json = $rows | ConvertTo-Json -Depth 5 -Compress
  if ([string]::IsNullOrWhiteSpace($json)) {
    return "[]"
  }
  return $json
}

function Add-JsonInsert {
  param(
    [System.Collections.Generic.List[string]]$Lines,
    [string]$TableName,
    [string[]]$Columns,
    [string]$Json
  )

  $quotedColumns = ($Columns | ForEach-Object { '"' + $_ + '"' }) -join ", "
  $recordColumns = ($Columns | ForEach-Object { '"' + $_ + '" text' }) -join ", "

  $Lines.Add("insert into public.$TableName ($quotedColumns)")
  $Lines.Add("select $quotedColumns")
  $Lines.Add("from jsonb_to_recordset(`$json`$")
  $Lines.Add($Json)
  $Lines.Add("`$json`$::jsonb) as x($recordColumns);")
  $Lines.Add("")
}

$employeePath = Join-Path $InputDir "성모 직원 정보.upload.csv"
$rosterPath = Join-Path $InputDir "월별성모직원명단_1월.upload.csv"
$payrollPath = Join-Path $InputDir "1월성모직원급여.upload.csv"

$employeeColumns = @(
  "사원코드", "사원명", "부서코드", "부서명", "성별", "입사일", "중도퇴사일", "퇴직일",
  "재직구분코드", "재직구분명", "고용형태코드", "고용형태명", "직책코드", "직책명",
  "직종명", "프로젝트명", "직급명"
)

$rosterColumns = @(
  "사원코드", "사원명", "주민등록번호", "부서명", "직책명", "입사일", "퇴사일", "재직기간", "그룹입사일"
)

$payrollColumns = @(
  "부서", "사원코드", "사원명", "부서코드", "기본급", "식대_지급", "자가운전", "시간외수당",
  "야간근로수당", "야간정산수당", "휴일근로수당", "일숙직수당", "특수+교대수당", "처우개선비",
  "연차수당", "부서수당", "직급/직책수당", "직무수당", "보직수당", "근속/경력수당",
  "경력수당", "면허/자격수당", "기타", "당직비", "대기/당직수당", "간호간병평가인센티브",
  "야간간호특별수당", "경영성과금", "국고보조금", "정부지원금", "간호간병특별수당",
  "특별수당", "위탁보육료_1", "순환당직지원금", "위탁보육료_2", "상여", "지급합계",
  "급여합계", "국민연금", "건강보험", "고용보험", "학자금상환액", "사우회비", "기부금",
  "식대_공제", "주차장이용료", "기숙사비", "장기요양보험료", "장기요양보험정산",
  "건강보험료정산", "소득세", "지방소득세", "연말정산소득세", "연말정산지방소득세",
  "연말정산농특세", "공제합계", "차인지급액"
)

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("-- Generated staging upload SQL from local CSV files.")
$lines.Add("-- Run after HR schema tables are created.")
$lines.Add("")
$lines.Add("begin;")
$lines.Add("")
$lines.Add("truncate table public.staging_employee_info_csv, public.staging_monthly_roster_csv, public.staging_monthly_payroll_csv;")
$lines.Add("")

Add-JsonInsert -Lines $lines -TableName "staging_employee_info_csv" -Columns $employeeColumns -Json (Convert-CsvToJsonLiteral $employeePath)
Add-JsonInsert -Lines $lines -TableName "staging_monthly_roster_csv" -Columns $rosterColumns -Json (Convert-CsvToJsonLiteral $rosterPath)
Add-JsonInsert -Lines $lines -TableName "staging_monthly_payroll_csv" -Columns $payrollColumns -Json (Convert-CsvToJsonLiteral $payrollPath)

$lines.Add("commit;")
$lines.Add("")
$lines.Add("select 'staging_employee_info_csv' as table_name, count(*) as row_count from public.staging_employee_info_csv")
$lines.Add("union all")
$lines.Add("select 'staging_monthly_roster_csv', count(*) from public.staging_monthly_roster_csv")
$lines.Add("union all")
$lines.Add("select 'staging_monthly_payroll_csv', count(*) from public.staging_monthly_payroll_csv;")

Set-Content -LiteralPath $OutputPath -Encoding utf8 -Value $lines
Write-Host "Created $OutputPath"
