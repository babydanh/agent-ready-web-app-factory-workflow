[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,

    [string]$ChangeId = '',

    [switch]$Strict
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ExistingPath([string]$Path) {
    return [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path)
}

function Resolve-WorkflowRoot([string]$Root) {
    if ((Split-Path -Leaf $Root) -eq 'workflow' -and (Test-Path -LiteralPath $Root -PathType Container)) {
        return Resolve-ExistingPath $Root
    }
    $candidate = Join-Path $Root 'workflow'
    if (Test-Path -LiteralPath $candidate -PathType Container) {
        return Resolve-ExistingPath $candidate
    }
    throw "Could not find workflow directory under ProjectRoot: $Root"
}

function Add-Failure([System.Collections.Generic.List[string]]$Failures, [string]$Message) {
    $Failures.Add($Message)
    Write-Output ("FAIL: " + $Message)
}

function Get-ManifestProperty([object]$Object, [string]$Name) {
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }
    return $property.Value
}

$workflow = Resolve-WorkflowRoot $ProjectRoot
$failures = [System.Collections.Generic.List[string]]::new()
$manifestPath = Join-Path $workflow 'MANIFEST.json'

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "MANIFEST.json not found: $manifestPath"
}

try {
    $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
} catch {
    throw "MANIFEST.json is not valid JSON: $($_.Exception.Message)"
}

$registered = @()
$entrypoints = Get-ManifestProperty $manifest 'entrypoints'
$coreFiles = Get-ManifestProperty $manifest 'core_files'
$flatFiles = Get-ManifestProperty $manifest 'files'
if ($null -ne $entrypoints) {
    $registered += @($entrypoints | Where-Object { $_ -is [string] })
}
if ($null -ne $coreFiles) {
    $registered += @($coreFiles.PSObject.Properties.Name | Where-Object { $_ -is [string] })
}
if ($null -ne $flatFiles) {
    $registered += @($flatFiles | Where-Object { $_ -is [string] })
}
foreach ($property in @('templates', 'standards', 'standards_templates', 'standards_contracts', 'research', 'knowledge', 'phases', 'decisions', 'security_files', 'harness', 'examples', 'audits')) {
    $value = Get-ManifestProperty $manifest $property
    if ($null -ne $value) {
        $registered += @($value | Where-Object { $_ -is [string] })
    }
}

$uniqueRegistered = @($registered | Sort-Object -Unique)
foreach ($relative in $uniqueRegistered) {
    $path = Join-Path $workflow $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure $failures "Manifest path does not exist: $relative"
    }
}

$emptyFiles = @(Get-ChildItem -LiteralPath $workflow -Recurse -File | Where-Object { $_.Length -eq 0 })
foreach ($file in $emptyFiles) {
    Add-Failure $failures ("Empty file: " + $file.FullName)
}

foreach ($file in @(Get-ChildItem -LiteralPath $workflow -Recurse -File -Filter '*.json')) {
    try {
        Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json | Out-Null
    } catch {
        Add-Failure $failures ("Invalid JSON: " + $file.FullName)
    }
}

foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $workflow 'harness') -File -Filter '*.ps1')) {
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors) | Out-Null
    if ($parseErrors.Count -gt 0) {
        Add-Failure $failures ("PowerShell parse failure: " + $file.FullName)
    }
}

if (-not [string]::IsNullOrWhiteSpace($ChangeId)) {
    $changeRoot = Join-Path (Join-Path (Split-Path -Parent $workflow) 'changes') $ChangeId
    if (-not (Test-Path -LiteralPath $changeRoot -PathType Container)) {
        Add-Failure $failures "Change workspace does not exist: $ChangeId"
    } else {
        $readme = Join-Path $changeRoot 'README.md'
        $readmeText = ''
        $tier = ''
        $includeAI = $false
        $profiles = @()
        if (Test-Path -LiteralPath $readme -PathType Leaf) {
            $readmeText = Get-Content -LiteralPath $readme -Raw
            $tierMatch = [regex]::Match($readmeText, '(?m)^- (\*\*Tier:\*\*|Tier:)\s*(SmallFix|Normal|HighRisk)')
            if ($tierMatch.Success) {
                $tier = $tierMatch.Groups[2].Value
            } else {
                Add-Failure $failures "Change README has no valid Tier: changes/$ChangeId/README.md"
            }
            if ($readmeText -notmatch '(?m)^- (\*\*Status:\*\*|Status:)\s*\S+') {
                Add-Failure $failures "Change README has no Status field: changes/$ChangeId/README.md"
            }
            $includeAI = $readmeText -match '(?m)^\|\s*06-ai-eval-task\.yaml\s*\|\s*true\s*\|'
            $profileMatch = [regex]::Match($readmeText, '(?m)^Selected profile\(s\):\s*(.+)$')
            if ($profileMatch.Success -and $profileMatch.Groups[1].Value.Trim() -ne 'None') {
                $profiles = @($profileMatch.Groups[1].Value.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
            }
        } else {
            Add-Failure $failures "Required change artifact missing: changes/$ChangeId/README.md"
        }

        $requiredChangeFiles = @('README.md', '00-problem-map.md', '07-plan.md', '08-tasks.md', '09-test-plan.md', '10-implementation-log.md', '11-convergence-review.md', '12-release-evidence.md')
        if ($tier -eq 'Normal' -or $tier -eq 'HighRisk') {
            $requiredChangeFiles += @('00-discovery-brief.md', '02-backend-feature-design.md', '02-data-entity.md', '03-endpoint-contract.md', '04-screen-spec.md')
        }
        if ($tier -eq 'HighRisk') {
            $requiredChangeFiles += @('01-architecture-review.md', '05-security-delta.md')
        }
        if ($includeAI) {
            $requiredChangeFiles += '06-ai-eval-task.yaml'
        }
        if ($profiles -contains 'Commerce') {
            $requiredChangeFiles += @('commerce-flow-spec.md', 'transaction-concurrency-test.md')
        }
        if ($profiles -contains 'Recommendation') {
            $requiredChangeFiles += 'recommendation-feature-spec.md'
        }
        if ($profiles -contains 'Dashboard') {
            $requiredChangeFiles += 'dashboard-analytics-spec.md'
        }
        if ($profiles -contains 'VietnamCompliance') {
            $requiredChangeFiles += 'compliance-scope-record.md'
        }
        if ($profiles -contains 'AppleIOS') {
            $requiredChangeFiles += 'apple-ios-release-review.md'
        }
        if ($profiles -contains 'Theme') {
            $requiredChangeFiles += 'theme-config.json'
        }
        if ($profiles -contains 'I18N') {
            $requiredChangeFiles += 'translation-catalog.json'
        }
        if ($profiles -contains 'Theme' -or $profiles -contains 'I18N') {
            $requiredChangeFiles += 'locale-qa-matrix.md'
        }
        if (($profiles -contains 'Commerce' -or $profiles -contains 'Recommendation') -and $tier -ne 'HighRisk') {
            $requiredChangeFiles += 'profile-risk-waiver.md'
        }
        foreach ($relative in @($requiredChangeFiles | Sort-Object -Unique)) {
            if (-not (Test-Path -LiteralPath (Join-Path $changeRoot $relative) -PathType Leaf)) {
                Add-Failure $failures "Required change artifact missing: changes/$ChangeId/$relative"
            }
        }
    }
}

if ($Strict -and $uniqueRegistered.Count -lt 1) {
    Add-Failure $failures 'Manifest has no registered paths'
}

if ($failures.Count -gt 0) {
    Write-Output ("WORKFLOW_VALIDATION_FAIL failures=" + $failures.Count)
    exit 1
}

Write-Output ("WORKFLOW_VALIDATION_PASS manifest_version=" + $manifest.version + " registered_paths=" + $uniqueRegistered.Count + " json_files=" + @((Get-ChildItem -LiteralPath $workflow -Recurse -File -Filter '*.json')).Count + " change=" + ($(if ([string]::IsNullOrWhiteSpace($ChangeId)) { 'none' } else { $ChangeId })))
