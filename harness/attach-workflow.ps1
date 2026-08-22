param(
    [string]$ProjectRoot = '.',

    [ValidateSet('All', 'AGENTS', 'Copilot', 'Claude', 'Cursor')]
    [string]$Agent = 'All',

    [ValidateSet('Commerce', 'Recommendation', 'Dashboard', 'VietnamCompliance', 'AppleIOS', 'Theme', 'I18N')]
    [string[]]$Profile = @(),

    [string]$WorkflowRoot = '',

    [string]$ProjectName = '',

    [switch]$Bootstrap,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ExistingPath([string]$Path) {
    return [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path)
}

function Add-Plan([System.Collections.Generic.List[object]]$Plan, [string]$Path, [string]$Content, [bool]$NeedsDirectory) {
    $Plan.Add([pscustomobject]@{ Path = $Path; Content = $Content; NeedsDirectory = $NeedsDirectory })
}

function Merge-ManagedBlock([string]$Existing, [string]$Body) {
    $begin = '<!-- WEB-APP-FACTORY-WORKFLOW:BEGIN -->'
    $end = '<!-- WEB-APP-FACTORY-WORKFLOW:END -->'
    $block = @(
        $begin,
        $Body.Trim(),
        $end
    ) -join [Environment]::NewLine

    $beginIndex = $Existing.IndexOf($begin, [System.StringComparison]::Ordinal)
    $endIndex = $Existing.IndexOf($end, [System.StringComparison]::Ordinal)
    if ($beginIndex -ge 0 -and $endIndex -gt $beginIndex) {
        $afterEnd = $endIndex + $end.Length
        return $Existing.Substring(0, $beginIndex).TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $block + $Existing.Substring($afterEnd).TrimStart()
    }
    if ([string]::IsNullOrWhiteSpace($Existing)) {
        return $block + [Environment]::NewLine
    }
    return $Existing.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $block + [Environment]::NewLine
}

if ([string]::IsNullOrWhiteSpace($WorkflowRoot)) {
    $WorkflowRoot = Split-Path -Parent $PSScriptRoot
}

$ProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$WorkflowRoot = Resolve-ExistingPath $WorkflowRoot
if (-not (Test-Path -LiteralPath (Join-Path $WorkflowRoot 'README.md') -PathType Leaf)) {
    throw "WorkflowRoot does not contain README.md: $WorkflowRoot"
}
if (-not (Test-Path -LiteralPath $ProjectRoot -PathType Container)) {
    throw "ProjectRoot does not exist: $ProjectRoot"
}

$targetWorkflow = Join-Path $ProjectRoot 'workflow'
$workflowExists = Test-Path -LiteralPath $targetWorkflow -PathType Container
if (-not $workflowExists -and -not $Bootstrap) {
    throw "Target has no workflow directory. Run with -Bootstrap or run init-workflow.ps1 first: $targetWorkflow"
}

if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    $ProjectName = Split-Path -Leaf $ProjectRoot
}

if (-not $workflowExists -and $Bootstrap) {
    $initScript = Join-Path $WorkflowRoot 'harness/init-workflow.ps1'
    if (-not (Test-Path -LiteralPath $initScript -PathType Leaf)) {
        throw "Bootstrap script not found: $initScript"
    }
    if ($DryRun) {
        & $initScript -TargetRoot $ProjectRoot -ProjectName $ProjectName -DryRun
    } else {
        & $initScript -TargetRoot $ProjectRoot -ProjectName $ProjectName
        if (-not $?) {
            throw 'Bootstrap failed while running init-workflow.ps1'
        }
        $workflowExists = $true
    }
}

$profileText = if ($Profile.Count -gt 0) { $Profile -join ', ' } else { 'None — agent must select from workflow/standards/COMMERCE_RECOMMENDATION_DASHBOARD_GATES.md' }
$instructionBody = @"
# Web App Factory — Agent Bridge

This repository uses the reusable workflow under `workflow/`.

## Required startup

Read `workflow/README.md`, `workflow/WORKFLOW.md`, `workflow/SKILL.md`, `workflow/AGENTS.md`, `workflow/standards/README.md`, `workflow/knowledge/PROJECT_CONTEXT.md`, `workflow/knowledge/WEB_APP_PROBLEM_CATALOG.md` and `workflow/knowledge/DOMAIN_ADAPTATION_GUIDE.md` before changing code. Load only the profile-specific playbooks selected for the task; do not read the whole corpus by default.

Selected profile(s) for this attachment: **$profileText**.

## Change protocol

Use `workflow/harness/new-change.ps1` to create `changes/<change-id>/`. Complete the problem map, discovery/contract/profile artifacts and plan before implementation. Keep source changes inside the approved scope. Use `workflow/harness/validate-workflow.ps1 -ProjectRoot . -ChangeId <change-id> -Strict` before reporting completion.

## Safety and evidence

Never read, print or commit `.env`, credentials, tokens, private keys or production PII. Do not invent fields, statuses, endpoints or events outside the source of truth. Stop with `NEEDS_CLARIFICATION`, `BLOCKED` or `NEEDS_HUMAN_REVIEW` when contract, business rule, security evidence, legal review or platform review is missing. A successful build is not proof of business correctness, security, legal compliance or App Store approval.

## Relevant profile routing

Commerce/payment/marketplace uses the Commerce and Transaction playbooks. Search/ranking/personalization uses the Recommendation playbook. KPI/reporting/dashboard/export uses the Dashboard playbook. Theme/tokens/dark mode uses the Theme and Design Tokens specification. Localization/multi-language/RTL uses the I18N/L10N specification. Vietnam launch/data/e-commerce uses the Vietnam profile and compliance scope record. iOS/App Store/StoreKit uses the Apple profile and iOS release review template.

## Required final report

Report `status`, `summary`, `source_of_truth`, `files_changed`, `commands_or_tests_run`, `test_results`, `evidence`, `risks_or_findings`, `open_questions` and `next_action`. Do not claim `DONE` when a required check was not run.
"@

$plan = [System.Collections.Generic.List[object]]::new()
$targets = [System.Collections.Generic.List[string]]::new()
if ($Agent -eq 'All' -or $Agent -eq 'AGENTS') { $targets.Add('AGENTS.md') }
if ($Agent -eq 'All' -or $Agent -eq 'Copilot') { $targets.Add('.github/copilot-instructions.md') }
if ($Agent -eq 'All' -or $Agent -eq 'Claude') { $targets.Add('CLAUDE.md') }
if ($Agent -eq 'All' -or $Agent -eq 'Cursor') { $targets.Add('.cursor/rules/workflow.mdc') }

foreach ($relative in $targets) {
    $destination = Join-Path $ProjectRoot $relative
    $existing = if (Test-Path -LiteralPath $destination -PathType Leaf) { Get-Content -LiteralPath $destination -Raw } else { '' }
    $content = Merge-ManagedBlock -Existing $existing -Body $instructionBody
    Add-Plan $plan $destination $content ($relative -match '/')
}

if ($DryRun) {
    Write-Output "DRY_RUN: would attach workflow to $ProjectRoot"
    Write-Output "Agent: $Agent"
    Write-Output "Profiles: $profileText"
    if ($Bootstrap -and -not $workflowExists) { Write-Output 'Bootstrap: requested; target workflow remains unchanged in DryRun' }
    foreach ($item in $plan) { Write-Output ("  " + $item.Path) }
    return
}

foreach ($item in $plan) {
    if ($item.NeedsDirectory) {
        New-Item -ItemType Directory -Path (Split-Path -Parent $item.Path) -Force | Out-Null
    }
    Set-Content -LiteralPath $item.Path -Value $item.Content -Encoding UTF8 -NoNewline
}

Write-Output 'WORKFLOW_ATTACHED'
Write-Output "ProjectRoot: $ProjectRoot"
Write-Output "Agent: $Agent"
Write-Output "Profiles: $profileText"
Write-Output "AdaptersUpdated: $($plan.Count)"
Write-Output 'Next: open a new agent session and create a change workspace with new-change.ps1.'
