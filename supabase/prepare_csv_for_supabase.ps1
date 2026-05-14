param(
  [string]$SourceDir = "D:\인사관리프로그램자료",
  [string]$OutputDir = ".\supabase\upload_ready"
)

$ErrorActionPreference = "Stop"

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

function Copy-CsvAsUtf8 {
  param(
    [Parameter(Mandatory = $true)][string]$InputPath,
    [Parameter(Mandatory = $true)][string]$OutputPath
  )

  $lines = Get-Content -LiteralPath $InputPath -Encoding Default
  Set-Content -LiteralPath $OutputPath -Encoding utf8 -Value $lines
}

function Convert-PayrollCsv {
  param(
    [Parameter(Mandatory = $true)][string]$InputPath,
    [Parameter(Mandatory = $true)][string]$OutputPath
  )

  $lines = Get-Content -LiteralPath $InputPath -Encoding Default
  if ($lines.Count -eq 0) {
    throw "Payroll CSV is empty: $InputPath"
  }

  $headers = $lines[0].Split(",")
  $mealCount = 0
  $childcareCount = 0

  for ($i = 0; $i -lt $headers.Count; $i++) {
    switch ($headers[$i]) {
      "식대" {
        $mealCount++
        if ($mealCount -eq 1) {
          $headers[$i] = "식대_지급"
        } elseif ($mealCount -eq 2) {
          $headers[$i] = "식대_공제"
        }
      }
      "위탁보육료" {
        $childcareCount++
        $headers[$i] = "위탁보육료_$childcareCount"
      }
    }
  }

  $outputLines = @($headers -join ",") + $lines[1..($lines.Count - 1)]
  Set-Content -LiteralPath $OutputPath -Encoding utf8 -Value $outputLines
}

Copy-CsvAsUtf8 `
  -InputPath (Join-Path $SourceDir "성모 직원 정보.csv") `
  -OutputPath (Join-Path $OutputDir "성모 직원 정보.upload.csv")

Copy-CsvAsUtf8 `
  -InputPath (Join-Path $SourceDir "월별성모직원명단_1월.csv") `
  -OutputPath (Join-Path $OutputDir "월별성모직원명단_1월.upload.csv")

Convert-PayrollCsv `
  -InputPath (Join-Path $SourceDir "1월성모직원급여.csv") `
  -OutputPath (Join-Path $OutputDir "1월성모직원급여.upload.csv")

Write-Host "Created upload-ready CSV files in: $OutputDir"
