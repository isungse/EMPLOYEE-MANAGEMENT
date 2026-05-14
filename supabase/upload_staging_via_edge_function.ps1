param(
  [Parameter(Mandatory = $true)][string]$ImportToken,
  [string]$ProjectRef = "golmgmfibyeangujlkbd",
  [string]$InputDir = ".\supabase\upload_ready",
  [int]$BatchSize = 200
)

$ErrorActionPreference = "Stop"

$functionUrl = "https://$ProjectRef.supabase.co/functions/v1/hr-staging-import"

function Send-CsvBatches {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$TableName
  )

  $rows = @(Import-Csv -LiteralPath $Path)
  $total = $rows.Count
  $sent = 0

  for ($start = 0; $start -lt $total; $start += $BatchSize) {
    $end = [Math]::Min($start + $BatchSize - 1, $total - 1)
    $batch = @($rows[$start..$end])
    $body = @{
      table = $TableName
      rows = $batch
    } | ConvertTo-Json -Depth 20 -Compress

    Invoke-RestMethod `
      -Method Post `
      -Uri $functionUrl `
      -Headers @{ "x-import-token" = $ImportToken } `
      -ContentType "application/json; charset=utf-8" `
      -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) | Out-Null

    $sent += $batch.Count
    Write-Host "${TableName}: uploaded $sent / $total"
  }
}

Send-CsvBatches `
  -Path (Join-Path $InputDir "성모 직원 정보.upload.csv") `
  -TableName "staging_employee_info_csv"

Send-CsvBatches `
  -Path (Join-Path $InputDir "월별성모직원명단_1월.upload.csv") `
  -TableName "staging_monthly_roster_csv"

Send-CsvBatches `
  -Path (Join-Path $InputDir "1월성모직원급여.upload.csv") `
  -TableName "staging_monthly_payroll_csv"

Write-Host "Done"
