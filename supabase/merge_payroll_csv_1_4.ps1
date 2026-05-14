param(
  [string]$SourceDir = "D:\인사관리프로그램자료",
  [string]$OutputPath = ".\supabase\upload_ready\성모직원급여_1월_4월_통합.upload.csv",
  [int]$Year = 2026
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputPath) | Out-Null

$files = @(
  @{ Month = 1; Name = "1월성모직원급여.csv" },
  @{ Month = 2; Name = "2월성모직원급여.csv" },
  @{ Month = 3; Name = "3월성모직원급여.csv" },
  @{ Month = 4; Name = "4월성모직원급여.csv" }
)

function Get-UniquePayrollHeaders {
  param([string[]]$Headers)

  $mealCount = 0
  $childcareCount = 0
  $result = @()

  foreach ($header in $Headers) {
    if ($header -eq "식대") {
      $mealCount++
      if ($mealCount -eq 1) {
        $result += "식대_지급"
      } elseif ($mealCount -eq 2) {
        $result += "식대_공제"
      } else {
        $result += "식대_$mealCount"
      }
    } elseif ($header -eq "위탁보육료") {
      $childcareCount++
      $result += "위탁보육료_$childcareCount"
    } else {
      $result += $header
    }
  }

  return $result
}

$merged = [System.Collections.Generic.List[string]]::new()
$canonicalHeaders = $null

foreach ($file in $files) {
  $inputPath = Join-Path $SourceDir $file.Name
  if (-not (Test-Path -LiteralPath $inputPath)) {
    throw "Missing file: $inputPath"
  }

  $lines = @(Get-Content -LiteralPath $inputPath -Encoding Default)
  if ($lines.Count -lt 2) {
    throw "CSV has no data rows: $inputPath"
  }

  $headers = Get-UniquePayrollHeaders -Headers ($lines[0].Split(","))
  if ($null -eq $canonicalHeaders) {
    $canonicalHeaders = $headers
    $merged.Add(("payroll_month," + ($canonicalHeaders -join ",")))
  } elseif (($headers -join "|") -ne ($canonicalHeaders -join "|")) {
    throw "Header mismatch: $inputPath"
  }

  $period = "{0:D4}-{1:D2}-01" -f $Year, $file.Month
  foreach ($line in $lines[1..($lines.Count - 1)]) {
    if ([string]::IsNullOrWhiteSpace($line)) {
      continue
    }
    $merged.Add("$period,$line")
  }
}

Set-Content -LiteralPath $OutputPath -Encoding utf8 -Value $merged
Write-Host "Created: $OutputPath"
Write-Host "Rows including header: $($merged.Count)"
Write-Host "Data rows: $($merged.Count - 1)"
