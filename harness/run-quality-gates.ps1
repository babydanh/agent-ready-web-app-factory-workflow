[CmdletBinding()]
param(
  [switch]$Backend,
  [switch]$Frontend,
  [switch]$E2E,
  [switch]$ContinueOnError,
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'
$results = New-Object System.Collections.Generic.List[object]

if (-not $Backend -and -not $Frontend) {
  $Backend = $true
  $Frontend = $true
}

function Invoke-Step([string]$Name, [string]$WorkingDirectory, [string]$Command, [string[]]$Arguments) {
  Write-Host "`n=== $Name ==="
  Push-Location $WorkingDirectory
  try {
    & $Command @Arguments
    $code = $LASTEXITCODE
  } catch {
    $code = 1
    Write-Host $_
  } finally {
    Pop-Location
  }
  $status = if ($code -eq 0) { 'PASS' } else { 'FAIL' }
  $results.Add([pscustomobject]@{ Name = $Name; Status = $status; ExitCode = $code })
  if ($code -ne 0 -and -not $ContinueOnError) {
    throw "$Name failed with exit code $code"
  }
}

$backendPath = Join-Path $ProjectRoot 'HethongBackendApi_QuanlyGiaiDau'
$frontendPath = Join-Path $ProjectRoot 'HethongFrontEndWeb_QLgiaidau'

if ($Backend) {
  if (-not (Test-Path -LiteralPath (Join-Path $backendPath 'package.json'))) {
    throw "Backend package.json not found: $backendPath"
  }
  Invoke-Step 'Backend format check' $backendPath 'pnpm' @('exec', 'prettier', '--check', 'src/**/*.ts', 'test/**/*.ts')
  Invoke-Step 'Backend unit tests' $backendPath 'pnpm' @('test', '--', '--runInBand')
  if ($E2E) { Invoke-Step 'Backend E2E tests' $backendPath 'pnpm' @('run', 'test:e2e', '--', '--runInBand') }
  Invoke-Step 'Backend build' $backendPath 'pnpm' @('run', 'build')
}

if ($Frontend) {
  if (-not (Test-Path -LiteralPath (Join-Path $frontendPath 'package.json'))) {
    throw "Frontend package.json not found: $frontendPath"
  }
  Invoke-Step 'Frontend lint' $frontendPath 'pnpm' @('run', 'lint')
  Invoke-Step 'Frontend i18n check' $frontendPath 'pnpm' @('run', 'i18n:check')
  Invoke-Step 'Frontend build' $frontendPath 'pnpm' @('run', 'build')
}

Invoke-Step 'Git diff check' $ProjectRoot 'git' @('diff', '--check')

Write-Host "`n=== Quality gate summary ==="
$results | Format-Table -AutoSize

$failed = @($results | Where-Object { $_.Status -eq 'FAIL' })
if ($failed.Count -gt 0) {
  exit 1
}
exit 0
