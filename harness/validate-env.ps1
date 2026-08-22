[CmdletBinding()]
param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'
$failures = New-Object System.Collections.Generic.List[string]

function Test-CommandExists([string]$Name) {
  return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Require-Command([string]$Name) {
  if (Test-CommandExists $Name) {
    Write-Host "PASS command: $Name"
  } else {
    $failures.Add("Missing command: $Name")
    Write-Host "FAIL command: $Name"
  }
}

function Require-Path([string]$RelativePath) {
  $full = Join-Path $ProjectRoot $RelativePath
  if (Test-Path -LiteralPath $full) {
    Write-Host "PASS path: $RelativePath"
  } else {
    $failures.Add("Missing path: $RelativePath")
    Write-Host "FAIL path: $RelativePath"
  }
}

Write-Host "Workflow environment validation"
Write-Host "Project root: $ProjectRoot"

Require-Command 'node'
Require-Command 'pnpm'
Require-Command 'docker'
Require-Command 'git'

Require-Path 'README.md'
Require-Path 'docker-compose.yml'
Require-Path 'HethongBackendApi_QuanlyGiaiDau\package.json'
Require-Path 'HethongFrontEndWeb_QLgiaidau\package.json'
Require-Path 'workflow\WORKFLOW.md'
Require-Path 'workflow\SKILL.md'

if (Test-CommandExists 'node') {
  $nodeVersion = (& node --version).Trim()
  Write-Host "Node: $nodeVersion"
  if ($nodeVersion -notmatch '^v(20|21|22|23|24)\.') {
    $failures.Add("Node version is not the project canonical target (expected Node 20+ LTS compatible): $nodeVersion")
  }
}

if (Test-CommandExists 'pnpm') {
  Write-Host "pnpm: $((& pnpm --version).Trim())"
}

$compose = Join-Path $ProjectRoot 'docker-compose.yml'
if (Test-Path -LiteralPath $compose) {
  $content = Get-Content -LiteralPath $compose -Raw
  if ($content -match 'postgis/postgis:15') {
    Write-Host 'WARN database image is PostgreSQL 15/PostGIS; confirm against project status before release.'
  }
  if ($content -match 'backend-api_qlgiaidau') {
    Write-Host 'WARN Compose references backend-api_qlgiaidau; confirm it matches the actual backend folder.'
  }
}

if ($failures.Count -gt 0) {
  Write-Host "`nValidation failed with $($failures.Count) issue(s):"
  $failures | ForEach-Object { Write-Host "- $_" }
  exit 1
}

Write-Host "`nEnvironment validation passed. Warnings still require human review."
exit 0
