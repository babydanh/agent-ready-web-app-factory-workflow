[CmdletBinding()]
param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
  [switch]$FailOnAdvisory
)

$ErrorActionPreference = 'Stop'
$excluded = '\\(node_modules|dist|build|\.next|coverage|\.git|workflow-tech-research-v2\.zip)\\'
$extensions = @('*.ts','*.tsx','*.js','*.jsx','*.json','*.yml','*.yaml','*.env*','*.md','*.sql','*.ps1')
$files = @()
$gitRoot = $null
if ((Get-Command git -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath (Join-Path $ProjectRoot '.git'))) {
  $previousErrorAction = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  $gitProbe = @(git -C $ProjectRoot rev-parse --is-inside-work-tree 2>$null)
  $ErrorActionPreference = $previousErrorAction
  if ($gitProbe -contains 'true') {
    $gitRoot = $ProjectRoot
  }
}
if ($gitRoot) {
  # Prefer tracked files for speed, then include the workflow pack even before it is committed.
  $trackedPaths = @(git -C $ProjectRoot ls-files 2>$null)
  $trackedPaths += @(Get-ChildItem -LiteralPath (Join-Path $ProjectRoot 'workflow') -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName.Substring($ProjectRoot.Length + 1).Replace('\\', '/') })
  foreach ($relative in ($trackedPaths | Sort-Object -Unique)) {
    $fullPath = Join-Path $ProjectRoot ($relative -replace '/', '\\')
    if (Test-Path -LiteralPath $fullPath -PathType Leaf) {
      $item = Get-Item -LiteralPath $fullPath
      if ($item.FullName -notmatch $excluded -and $extensions | Where-Object { $item.Name -like $_ }) {
        $files += $item
      }
    }
  }
} else {
  # The sample project may be a folder containing separate apps without a root .git.
  # Limit fallback scanning to source/config/workflow roots so the gate remains fast.
  $scanRoots = @('HethongBackendApi_QuanlyGiaiDau\\src','HethongBackendApi_QuanlyGiaiDau\\package.json','HethongFrontEndWeb_QLgiaidau\\src','HethongFrontEndWeb_QLgiaidau\\package.json','workflow')
  foreach ($relativeRoot in $scanRoots) {
    $scanPath = Join-Path $ProjectRoot $relativeRoot
    if (Test-Path -LiteralPath $scanPath -PathType Leaf) {
      $files += Get-Item -LiteralPath $scanPath
    } elseif (Test-Path -LiteralPath $scanPath -PathType Container) {
      $files += Get-ChildItem -LiteralPath $scanPath -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch $excluded -and $_.Length -lt 5000000 -and $_.Name -match '(?i)\.(ts|tsx|js|jsx|json|ya?ml|env.*|md|sql|ps1)$' }
    }
  }
}
$files = $files | Sort-Object FullName -Unique

$findings = [System.Collections.Generic.List[object]]::new()

function Add-Finding {
  param([string]$Severity, [string]$Rule, [string]$File, [int]$Line, [string]$Message)
  $findings.Add([pscustomobject]@{
    Severity = $Severity
    Rule = $Rule
    File = $File
    Line = $Line
    Message = $Message
  })
}

# This is intentionally a conservative review scanner. It reports locations only and never prints matching values.
$secretPatterns = @(
  @{ Rule = 'SECRET-001'; Severity = 'P0'; Pattern = '(?i)(sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA|OPENSSH|EC|PRIVATE) KEY-----)' },
  @{ Rule = 'SECRET-002'; Severity = 'P0'; Pattern = '(?i)(PAYOS_CHECKSUM_KEY|PAYOS_API_KEY|JWT_(ACCESS|REFRESH)_SECRET|OPENAI_API_KEY|GOOGLE_CLIENT_SECRET)\s*[:=]\s*["''][^"'']{12,}["'']' },
  @{ Rule = 'SECRET-003'; Severity = 'P1'; Pattern = '(?i)(password|passwd|secret|token|api[_-]?key)\s*[:=]\s*["''][^"'']{12,}["'']' }
)

foreach ($file in $files) {
  $relative = $file.FullName.Substring($ProjectRoot.Length + 1).Replace('\', '/')
  $lineNo = 0
  foreach ($line in (Get-Content -LiteralPath $file.FullName -ErrorAction SilentlyContinue)) {
    $lineNo++
    foreach ($rule in $secretPatterns) {
      if ($line -match $rule.Pattern -and $line -notmatch '(?i)(placeholder|example|changeme|your[-_ ]|<.*>)') {
        Add-Finding $rule.Severity $rule.Rule $relative $lineNo 'Possible secret-like literal; review without exposing the value.'
      }
    }

    if ($line -match '(?i)handshake\.query.*token|queryToken.*token' -and $line -notmatch '(?i)(allowQueryToken\s*!==\s*false|allowQueryToken\s*=\s*false)') {
      Add-Finding 'P1' 'AUTH-WS-001' $relative $lineNo 'Query-string token path detected; production should disable it and migrate clients.'
    }

    if ($line -match '(?i)NODE_ENV\s*===\s*["'']development["'']' -and $line -match '(?i)(csrf|security|auth|guard)') {
      Add-Finding 'P1' 'AUTH-CONFIG-001' $relative $lineNo 'Security behavior is bypassed by development environment; use an explicit test profile.'
    }

    if ($line -match '(?i)(Math\.random\(\).*otp|otp.*Math\.random\(\))') {
      Add-Finding 'P1' 'AUTH-OTP-001' $relative $lineNo 'OTP generation appears to use Math.random; use a cryptographic RNG.'
    }
  }
}

# Track accidental environment files without opening their contents.
if ($gitRoot) {
  $trackedEnv = @(git -C $ProjectRoot ls-files 2>$null | Where-Object { $_ -match '(^|/)(\.env($|\.)|.*\.pem$|.*\.key$)' -and $_ -notmatch '(^|/)\.env\.example$' })
  foreach ($tracked in $trackedEnv) {
    Add-Finding 'P0' 'SECRET-FILE-001' $tracked 0 'Potential secret-bearing environment/key file is tracked; remove or rotate through approved process.'
  }
}

$findings = @($findings | Sort-Object Severity, Rule, File, Line)
if ($findings.Count -eq 0) {
  Write-Output 'PASS: no configured security-gate findings.'
  exit 0
}

Write-Output "Security findings: $($findings.Count)"
$findings | Format-Table -AutoSize | Out-String -Width 240 | Write-Output

$blocking = @($findings | Where-Object { $_.Severity -eq 'P0' -or ($FailOnAdvisory -and $_.Severity -eq 'P1') })
if ($blocking.Count -gt 0) {
  Write-Error "Security gate BLOCKED with $($blocking.Count) blocking finding(s)."
  exit 1
}

Write-Warning 'Security gate completed with advisory findings; review the table and update the risk register.'
exit 0
