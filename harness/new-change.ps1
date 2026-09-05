[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectRoot,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9][a-z0-9-]{2,63}$')]
    [string]$ChangeId,
    [string]$Title = '',
    [ValidateSet('SmallFix', 'Normal', 'HighRisk')]
    [string]$Tier = 'Normal',
    [ValidateSet('Commerce', 'Recommendation', 'Dashboard', 'VietnamCompliance', 'AppleIOS', 'Theme', 'I18N')]
    [string[]]$Profile = @(),
    [switch]$IncludeAI,
    [switch]$AllowRiskWaiver,
    [switch]$Force,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ExistingPath([string]$Path) {
    return [System.IO.Path]::GetFullPath((Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path)
}

function Resolve-WorkflowRoot([string]$Root) {
    $candidate = Join-Path $Root 'workflow'
    if (Test-Path -LiteralPath $candidate -PathType Container) {
        return Resolve-ExistingPath $candidate
    }
    if ((Split-Path -Leaf $Root) -eq 'workflow' -and (Test-Path -LiteralPath $Root -PathType Container)) {
        return Resolve-ExistingPath $Root
    }
    throw "ProjectRoot must contain a workflow directory: $Root"
}

function Add-TextPlan([System.Collections.Generic.List[object]]$Plan, [string]$RelativePath, [string[]]$Lines) {
    $Plan.Add([pscustomobject]@{
        RelativePath = $RelativePath
        Source = $null
        Content = ($Lines -join [Environment]::NewLine)
    })
}

function Add-CopyPlan([System.Collections.Generic.List[object]]$Plan, [string]$TemplatePath, [string]$RelativePath) {
    if (-not (Test-Path -LiteralPath $TemplatePath -PathType Leaf)) {
        throw "Template not found: $TemplatePath"
    }
    $Plan.Add([pscustomobject]@{
        RelativePath = $RelativePath
        Source = $TemplatePath
        Content = $null
    })
}

$ProjectRoot = Resolve-ExistingPath $ProjectRoot
$workflowRoot = Resolve-WorkflowRoot $ProjectRoot
$changeRoot = Join-Path (Join-Path $ProjectRoot 'changes') $ChangeId
if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = $ChangeId.Replace('-', ' ')
}

$plan = [System.Collections.Generic.List[object]]::new()
$createdDate = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd')
$updatedAt = (Get-Date).ToUniversalTime().ToString('o')
$fullTier = ($Tier -ne 'SmallFix')
$highTier = ($Tier -eq 'HighRisk')
$hasProfile = ($Profile.Count -gt 0)
$hasCommerce = ($Profile -contains 'Commerce')
$hasRecommendation = ($Profile -contains 'Recommendation')
$hasDashboard = ($Profile -contains 'Dashboard')
$hasVietnamCompliance = ($Profile -contains 'VietnamCompliance')
$hasAppleIOS = ($Profile -contains 'AppleIOS')
$hasTheme = ($Profile -contains 'Theme')
$hasI18N = ($Profile -contains 'I18N')
$hasThemeOrI18N = ($hasTheme -or $hasI18N)
$profileHighRisk = ($hasCommerce -or $hasRecommendation)
if ($hasProfile -and -not $fullTier) {
    throw 'Profile-specific changes require Normal or HighRisk tier; SmallFix cannot silently omit domain artifacts.'
}
if ($profileHighRisk -and -not $highTier -and -not $AllowRiskWaiver) {
    throw 'Commerce and Recommendation profiles default to HighRisk. Use -Tier HighRisk, or explicitly pass -AllowRiskWaiver after recording the waiver.'
}
$profileRiskStatus = if ($profileHighRisk -and -not $highTier) { 'NEEDS_HUMAN_REVIEW: explicit risk waiver requested' } elseif ($profileHighRisk) { 'HighRisk' } elseif ($hasProfile) { 'Profile review required' } else { 'Not applicable' }
$profileNeedsWaiver = ($profileHighRisk -and -not $highTier)
$profileText = if ($hasProfile) { ($Profile -join ', ') } else { 'None' }

$readmeLines = @(
    "# Change - $ChangeId",
    '',
    "- Title: $Title",
    "- Tier: $Tier",
    '- Status: INTAKE',
    '- Owner: <person/team>',
    "- Created: $createdDate",
    '- Workflow source: workflow/MANIFEST.json',
    '- Canonical standards: workflow/standards/README.md',
    '',
    '## How to use this folder',
    '',
    'This folder is the source-of-truth workspace for one change. Complete artifacts in order, link decisions to evidence, and do not mark the change complete when a required check is blocked, not-run or unresolved.',
    '',
    "The selected tier is $Tier. Every change starts with a problem map; Normal adds discovery, architecture, backend and contract artifacts; HighRisk adds security and stronger operational controls. Add the AI artifact when IncludeAI is selected.",
    "Selected profile(s): $profileText",
    "Profile risk gate: $profileRiskStatus",
    'Profile-specific artifacts are required when their signal applies; the validator checks existence only, not legal/platform approval or semantic correctness.',
    'Feature Impact Review: required before implementation; complete the decision, source-of-truth, surface, state, button, negative-case and evidence sections.',
    'If a risk waiver is requested, complete profile-risk-waiver.md before implementation; a waiver cannot bypass legal or platform review.',
    '',
    '## Current gate',
    '',
    '- Next action: <first action>',
    '- Blocking questions:',
    '- Decision owner:',
    "- Last updated: $updatedAt",
    '',
    '## Artifact map',
    '',
    '| Artifact | Required | Status | Owner |',
    '|---|---:|---|---|',
    '| 00-problem-map.md | true | not-started |  |',
    '| 05-feature-impact-review.md | true | not-started |  |',
    "| 05-button-state-matrix.md | $fullTier | not-started |  |",
    "| 05-screen-state-matrix.md | $fullTier | not-started |  |",
    "| 05-cross-platform-matrix.md | $fullTier | not-started |  |",
    "| 00-discovery-brief.md | $fullTier | not-started |  |",
    "| 01-architecture-review.md | $highTier | not-started |  |",
    "| 02-data-entity.md | $fullTier | not-started |  |",
    "| 02-backend-feature-design.md | $fullTier | not-started |  |",
    "| 03-endpoint-contract.md | $fullTier | not-started |  |",
    "| 04-screen-spec.md | $fullTier | not-started |  |",
    "| 05-security-delta.md | $highTier | not-started |  |",
    '| 06-ai-eval-task.yaml | $IncludeAI | not-started |  |',
    "| commerce-flow-spec.md | $hasCommerce | not-started |  |",
    "| recommendation-feature-spec.md | $hasRecommendation | not-started |  |",
    "| dashboard-analytics-spec.md | $hasDashboard | not-started |  |",
    "| transaction-concurrency-test.md | $hasCommerce | not-started |  |",
    "| compliance-scope-record.md | $hasVietnamCompliance | not-started |  |",
    "| apple-ios-release-review.md | $hasAppleIOS | not-started |  |",
    "| theme-config.json | $hasTheme | not-started |  |",
    "| translation-catalog.json | $hasI18N | not-started |  |",
    "| locale-qa-matrix.md | $hasThemeOrI18N | not-started |  |",
    "| profile-risk-waiver.md | $profileNeedsWaiver | not-started |  |",
    '| 07-plan.md | true | not-started |  |',
    '| 08-tasks.md | true | not-started |  |',
    '| 09-test-plan.md | true | not-started |  |',
    '| 10-implementation-log.md | true | not-started |  |',
    '| 11-convergence-review.md | true | not-started |  |',
    '| 12-release-evidence.md | true | not-started |  |',
    '',
    '## Required states',
    '',
    'Use INTAKE, SPECIFIED, DESIGNED, IMPLEMENTING, VERIFYING, STAGING, RELEASED, BLOCKED, NEEDS_CLARIFICATION or NEEDS_HUMAN_REVIEW. Do not invent alternate states.'
)
Add-TextPlan $plan 'README.md' $readmeLines

$briefTemplate = Join-Path $workflowRoot 'standards/templates/PRODUCT_DISCOVERY_BRIEF.template.md'
$architectureTemplate = Join-Path $workflowRoot 'standards/templates/ARCHITECTURE_REVIEW.template.md'
$dataTemplate = Join-Path $workflowRoot 'standards/templates/DATA_ENTITY_SPEC.template.md'
$endpointTemplate = Join-Path $workflowRoot 'standards/templates/ENDPOINT_CONTRACT.template.md'
$screenTemplate = Join-Path $workflowRoot 'standards/templates/SCREEN_SPEC.template.md'
$aiTemplate = Join-Path $workflowRoot 'standards/templates/AI_EVAL_TASK.template.yaml'
$problemMapTemplate = Join-Path $workflowRoot 'standards/templates/WEB_APP_PROBLEM_MAP.template.md'
$backendDesignTemplate = Join-Path $workflowRoot 'standards/templates/BACKEND_FEATURE_DESIGN.template.md'
$commerceTemplate = Join-Path $workflowRoot 'standards/templates/COMMERCE_FLOW_SPEC.template.md'
$recommendationTemplate = Join-Path $workflowRoot 'standards/templates/RECOMMENDATION_FEATURE_SPEC.template.md'
$dashboardTemplate = Join-Path $workflowRoot 'standards/templates/DASHBOARD_ANALYTICS_SPEC.template.md'
$transactionTemplate = Join-Path $workflowRoot 'standards/templates/TRANSACTION_CONCURRENCY_TEST.template.md'
$complianceTemplate = Join-Path $workflowRoot 'standards/templates/COMPLIANCE_SCOPE_RECORD.template.md'
$appleTemplate = Join-Path $workflowRoot 'standards/templates/APPLE_IOS_RELEASE_REVIEW.template.md'
$themeTemplate = Join-Path $workflowRoot 'standards/templates/THEME_CONFIG.template.json'
$translationTemplate = Join-Path $workflowRoot 'standards/templates/TRANSLATION_CATALOG.template.json'
$localeQATemplate = Join-Path $workflowRoot 'standards/templates/LOCALE_QA_MATRIX.template.md'
$featureImpactTemplate = Join-Path $workflowRoot 'templates/FEATURE_IMPACT_REVIEW.template.md'
$buttonStateTemplate = Join-Path $workflowRoot 'templates/BUTTON_STATE_MATRIX.template.md'
$screenStateTemplate = Join-Path $workflowRoot 'templates/SCREEN_STATE_MATRIX.template.md'
$crossPlatformTemplate = Join-Path $workflowRoot 'templates/CROSS_PLATFORM_MATRIX.template.md'

Add-CopyPlan $plan $problemMapTemplate '00-problem-map.md'

if ($fullTier) {
    Add-CopyPlan $plan $featureImpactTemplate '05-feature-impact-review.md'
    Add-CopyPlan $plan $buttonStateTemplate '05-button-state-matrix.md'
    Add-CopyPlan $plan $screenStateTemplate '05-screen-state-matrix.md'
    Add-CopyPlan $plan $crossPlatformTemplate '05-cross-platform-matrix.md'
} else {
    $miniImpactLines = @(
        "# Mini Feature Impact Review - $ChangeId",
        '',
        '- Decision: GO | GO_WITH_CONDITIONS | HOLD | STOP',
        '- Source of truth:',
        '- Affected routes/files:',
        '- Roles/permissions:',
        '- State/button action changed:',
        '- Negative case:',
        '- Test/evidence:',
        '- Rollback/stop condition:',
        '- Reviewer:',
        '',
        'If the change touches API, state, permission, realtime, terminal behavior, Web/App parity or a user action, promote this change to Normal and complete the full impact matrices.'
    )
    Add-TextPlan $plan '05-feature-impact-review.md' $miniImpactLines
}

if ($fullTier) {
    Add-CopyPlan $plan $briefTemplate '00-discovery-brief.md'
    Add-CopyPlan $plan $backendDesignTemplate '02-backend-feature-design.md'
    Add-CopyPlan $plan $dataTemplate '02-data-entity.md'
    Add-CopyPlan $plan $endpointTemplate '03-endpoint-contract.md'
    Add-CopyPlan $plan $screenTemplate '04-screen-spec.md'
}

if ($highTier) {
    Add-CopyPlan $plan $architectureTemplate '01-architecture-review.md'
    $securityLines = @(
        "# Security Delta - $ChangeId",
        '',
        '- Risk tier: HighRisk',
        '- Security owner: <person/team>',
        '- Threat model reference: workflow/security/THREAT_MODEL.md',
        '- Status: not-started',
        '',
        '## Changed trust boundaries',
        '',
        '- <auth/session/ownership/PII/payment/upload/realtime/AI/infra boundary>',
        '',
        '## Controls and tests',
        '',
        '| Risk/control | Required? | Test/evidence | Status |',
        '|---|---:|---|---|',
        '| Authentication/authorization/ownership |  |  |  |',
        '| CSRF/CORS/Origin/session |  |  |  |',
        '| Input validation/IDOR/injection |  |  |  |',
        '| Rate limit/idempotency/replay |  |  |  |',
        '| PII/secret/log redaction |  |  |  |',
        '| Upload/external URL/SSRF |  |  |  |',
        '| Payment/webhook integrity |  |  |  |',
        '| Realtime/tool authorization |  |  |  |',
        '',
        '## Approval and residual risk',
        '',
        '- Decision: PASS | BLOCKED | NEEDS_HUMAN_REVIEW',
        '- Residual risk:',
        '- Approver:',
        '- Follow-up:'
    )
    Add-TextPlan $plan '05-security-delta.md' $securityLines
}

if ($IncludeAI) {
    Add-CopyPlan $plan $aiTemplate '06-ai-eval-task.yaml'
}
if ($hasCommerce) {
    Add-CopyPlan $plan $commerceTemplate 'commerce-flow-spec.md'
    Add-CopyPlan $plan $transactionTemplate 'transaction-concurrency-test.md'
}
if ($hasRecommendation) {
    Add-CopyPlan $plan $recommendationTemplate 'recommendation-feature-spec.md'
}
if ($hasDashboard) {
    Add-CopyPlan $plan $dashboardTemplate 'dashboard-analytics-spec.md'
}
if ($hasVietnamCompliance) {
    Add-CopyPlan $plan $complianceTemplate 'compliance-scope-record.md'
}
if ($hasAppleIOS) {
    Add-CopyPlan $plan $appleTemplate 'apple-ios-release-review.md'
}
if ($hasTheme) {
    Add-CopyPlan $plan $themeTemplate 'theme-config.json'
}
if ($hasI18N) {
    Add-CopyPlan $plan $translationTemplate 'translation-catalog.json'
}
if ($hasThemeOrI18N) {
    Add-CopyPlan $plan $localeQATemplate 'locale-qa-matrix.md'
}
if ($profileNeedsWaiver) {
    $waiverLines = @(
        "# Profile Risk Waiver - $ChangeId",
        '',
        "- Profiles: $profileText",
        "- Tier: $Tier",
        '- Status: NEEDS_HUMAN_REVIEW',
        '- Owner: <person/team>',
        '- Approver: <domain/security/release owner>',
        '- Expiry: <YYYY-MM-DD>',
        '',
        '## Condition and rationale',
        '',
        '- Required HighRisk control not currently met:',
        '- Why the change must proceed at this tier:',
        '- Affected users/data/money/platforms:',
        '',
        '## Compensating control and stop trigger',
        '',
        '- Compensating control:',
        '- Monitoring/evidence:',
        '- Rollback or stop trigger:',
        '- Follow-up issue/date:',
        '',
        'This waiver does not approve legal compliance, App Review, payment certification or security risk beyond the named scope.'
    )
    Add-TextPlan $plan 'profile-risk-waiver.md' $waiverLines
}

$planLines = @(
    "# Implementation Plan - $ChangeId",
    '',
    "- Change tier: $Tier",
    '- Plan owner: <person/team>',
    '- Approved by: <reviewer or not-yet>',
    '- Status: draft',
    '',
    '## Scope and dependency order',
    '',
    '1. <contract/spec prerequisite>',
    '2. <data/backend prerequisite>',
    '3. <frontend/integration task>',
    '4. <verification/release task>',
    '',
    '## File/module impact',
    '',
    '| Area | Files/modules | Read/write | Risk |',
    '|---|---|---|---|',
    '| Backend |  |  |  |',
    '| Frontend |  |  |  |',
    '| Database |  |  |  |',
    '| Realtime/jobs |  |  |  |',
    '| Infrastructure |  |  |  |',
    '',
    '## Rollback and stop conditions',
    '',
    '- Rollback:',
    '- Stop if: contract missing, approval missing, P0/P1 risk, data integrity threat, non-reproducible test or scope expansion.',
    '- Approval gate:'
)
Add-TextPlan $plan '07-plan.md' $planLines

$taskLines = @(
    "# Tasks - $ChangeId",
    '',
    '| ID | Task | Depends on | Owner/agent | Done check | Status |',
    '|---|---|---|---|---|---|',
    '| T-001 | <small independently verifiable task> |  |  | <command/test/evidence> | todo |',
    '',
    '## Task rules',
    '',
    'Each task must have one owner/writer, a bounded file scope, acceptance criteria and a deterministic done check. Do not combine unrelated changes or report the task as done when the check was not run.'
)
Add-TextPlan $plan '08-tasks.md' $taskLines

$testLines = @(
    "# Test Plan - $ChangeId",
    '',
    '## Acceptance matrix',
    '',
    '| Requirement | Test type | Fixture/data | Expected result | Command | Status |',
    '|---|---|---|---|---|---|',
    '|  | unit/API/contract/E2E/a11y/security/concurrency/AI |  |  |  | not-run |',
    '',
    '## Negative and edge cases',
    '',
    '- Missing/invalid input:',
    '- Unauthorized/forbidden/ownership:',
    '- Not found/conflict/rate limit:',
    '- Retry/duplicate/concurrency:',
    '- Offline/provider/queue failure:',
    '- Accessibility/localization/long text:',
    '',
    '## Evidence',
    '',
    '- Test run:',
    '- Environment/commit:',
    '- Failures and follow-up:'
)
Add-TextPlan $plan '09-test-plan.md' $testLines

$logLines = @(
    "# Implementation Log - $ChangeId",
    '',
    '| Time | Actor/agent | Action | Files | Command/result | Decision/evidence |',
    '|---|---|---|---|---|---|',
    '|  |  |  |  |  |  |',
    '',
    '## Deviations',
    '',
    'Record every scope expansion, contract change, skipped check, failed attempt and recovery. If a decision changes the approved plan, update the relevant spec or ADR before continuing.'
)
Add-TextPlan $plan '10-implementation-log.md' $logLines

$convergenceLines = @(
    "# Convergence Review - $ChangeId",
    '',
    '- Reviewer: <independent reviewer>',
    '- Date: <YYYY-MM-DD>',
    '- Decision: PASS | PASS_WITH_CONDITIONS | BLOCKED | FAIL',
    '',
    '| Acceptance criterion | Spec/contract | Code/runtime | Test/evidence | Result |',
    '|---|---|---|---|---|',
    '|  |  |  |  | not-verified |',
    '',
    '## Drift and unresolved work',
    '',
    '- Contract drift:',
    '- Data/architecture drift:',
    '- UI/accessibility drift:',
    '- Security/privacy drift:',
    '- SRE/AI/cost drift:',
    '- Follow-up issues:',
    '',
    '## Review statement',
    '',
    '<Explain why the implementation converges with the approved intent, or why it remains blocked.>'
)
Add-TextPlan $plan '11-convergence-review.md' $convergenceLines

$releaseLines = @(
    "# Release Evidence - $ChangeId",
    '',
    '- Release decision: PASS | PASS_WITH_CONDITIONS | BLOCKED | NOT_READY',
    '- Commit/artifact:',
    '- Environment:',
    '- Reviewer/approver:',
    '- Release time:',
    '',
    '| Gate | Result | Evidence | Owner |',
    '|---|---|---|---|',
    '| Discovery/decision |  |  |  |',
    '| Architecture/data/API/UI |  |  |  |',
    '| Security/privacy |  |  |  |',
    '| Tests/contract/a11y/concurrency |  |  |  |',
    '| AI eval/cost (if applicable) |  |  |  |',
    '| SRE/SLO/observability/rollback |  |  |  |',
    '| Audit/compliance traceability |  |  |  |',
    '',
    '## Known limitations and follow-up',
    '',
    '- <unresolved item, owner, due date>'
)
Add-TextPlan $plan '12-release-evidence.md' $releaseLines

$destinations = @($plan | ForEach-Object { Join-Path $changeRoot $_.RelativePath })
$conflicts = @($destinations | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf })
if ($conflicts.Count -gt 0 -and -not $Force) {
    throw "Refusing to overwrite existing change files. Use -Force only after reviewing: $($conflicts -join ', ')"
}

if ($DryRun) {
    Write-Output "DRY_RUN: would create $($plan.Count) files under $changeRoot"
    $destinations | ForEach-Object { Write-Output "  $_" }
    return
}

foreach ($item in $plan) {
    $destination = Join-Path $changeRoot $item.RelativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    if ($null -ne $item.Source) {
        if ($Force) {
            Copy-Item -LiteralPath $item.Source -Destination $destination -Force
        } else {
            Copy-Item -LiteralPath $item.Source -Destination $destination
        }
    } else {
        Set-Content -LiteralPath $destination -Value $item.Content -Encoding UTF8 -NoNewline
    }
}

Write-Output 'CHANGE_WORKSPACE_CREATED'
Write-Output "ChangeRoot: $changeRoot"
Write-Output "Tier: $Tier"
Write-Output "Profiles: $profileText"
Write-Output "FilesCreated: $($plan.Count)"
Write-Output 'Next: fill README.md, then complete artifacts in dependency order and update status/evidence.'
