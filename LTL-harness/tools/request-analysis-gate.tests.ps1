$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$gatePath = Join-Path $repoRoot "LTL-harness/tools/request-analysis-gate.ps1"
$testRoot = Join-Path $repoRoot ".tmp-request-analysis-gate-tests"

function Assert-True($Condition, $Message) {
  if (-not $Condition) {
    throw $Message
  }
}

function Reset-TestRoot {
  $resolvedRepo = (Resolve-Path -LiteralPath $repoRoot).Path
  $targetFull = [System.IO.Path]::GetFullPath($testRoot)
  Assert-True ($targetFull.StartsWith($resolvedRepo, [System.StringComparison]::OrdinalIgnoreCase)) "refusing to clean outside repo: $targetFull"
  if (Test-Path -LiteralPath $targetFull) {
    Remove-Item -LiteralPath $targetFull -Recurse -Force
  }
  New-Item -ItemType Directory -Force -Path $targetFull | Out-Null
}

function Remove-TestRoot {
  $resolvedRepo = (Resolve-Path -LiteralPath $repoRoot).Path
  $targetFull = [System.IO.Path]::GetFullPath($testRoot)
  Assert-True ($targetFull.StartsWith($resolvedRepo, [System.StringComparison]::OrdinalIgnoreCase)) "refusing to clean outside repo: $targetFull"
  if (Test-Path -LiteralPath $targetFull) {
    Remove-Item -LiteralPath $targetFull -Recurse -Force
  }
}

function Write-TestFile($RelativePath, $Content) {
  $path = Join-Path $testRoot $RelativePath
  $dir = Split-Path -Parent $path
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  Set-Content -LiteralPath $path -Value $Content -Encoding UTF8
  return $path
}

function Invoke-RequestGate($Ledger, $Mode, $ExtraArgs = @()) {
  $args = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $gatePath, "-Ledger", $Ledger, "-Mode", $Mode)
  $args += $ExtraArgs
  $previousErrorActionPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  $output = & powershell @args 2>&1
  $ErrorActionPreference = $previousErrorActionPreference
  [PSCustomObject]@{
    Code = $LASTEXITCODE
    Output = ($output | Out-String)
  }
}

Reset-TestRoot

$validLedger = Write-TestFile "valid-ledger.md" @"
# Request Constraint Ledger

## Request Summary
- Refactor broad UI files and harden harness gates.

## Preserved Invariants
- Reward ceremony order must remain count tease, count lock, reveal queue, tray review.

## Mutable Scope
- UI presenter helpers, harness gates, source-map entries.

## Source Map Findings
- `docs/source-map.md` lists the current harness gate entrypoints and request-ledger files.
- `LTL-harness/tools/request-analysis-gate.ps1` is the request-analysis validator that this ledger change is targeting.

## Transition Safety Review
- no transition impact
- reason: this focused test only validates ledger section structure and does not change a runtime handoff boundary

## Refactor/Delete Disposition
- Keep active runtime scripts; delete only orphan generated import metadata.

## Verification Checklist
- Run consolidated LTL quality gate.

## Verification Notes
- Invariant reward ceremony order: covered by UI read-model contract.
- Harness gate behavior: covered by request-analysis gate tests.

## Artifact Ledger
- Logs: artifacts/godot/.
Checksums are not required for generated logs.
"@

$missingDisposition = Write-TestFile "missing-disposition.md" @"
# Request Constraint Ledger

## Request Summary
- Refactor broad UI files.

## Preserved Invariants
- Existing ceremony order remains unchanged.

## Mutable Scope
- UI presenter helpers.

## Source Map Findings
- `docs/source-map.md` still maps the active UI presenter helpers that remain in scope.

## Transition Safety Review
- no transition impact
- reason: this negative fixture is only checking a missing disposition section

## Verification Checklist
- Run focused contracts.

## Verification Notes
- Focused contracts pass.
"@

$missingVerification = Write-TestFile "missing-verification.md" @"
# Request Constraint Ledger

## Request Summary
- Refactor broad UI files.

## Preserved Invariants
- Existing ceremony order remains unchanged.

## Mutable Scope
- UI presenter helpers.

## Source Map Findings
- `docs/source-map.md` still maps the active UI presenter helpers that remain in scope.

## Transition Safety Review
- no transition impact
- reason: this negative fixture is only checking a missing verification-notes section

## Refactor/Delete Disposition
- Keep active runtime scripts.

## Verification Checklist
- Run focused contracts.
"@

$missingSourceMap = Write-TestFile "missing-source-map.md" @"
# Request Constraint Ledger

## Request Summary
- Refactor broad UI files.

## Preserved Invariants
- Existing ceremony order remains unchanged.

## Mutable Scope
- UI presenter helpers.

## Transition Safety Review
- no transition impact
- reason: this negative fixture is only checking a missing source-map-findings section

## Refactor/Delete Disposition
- Keep active runtime scripts.

## Verification Checklist
- Run focused contracts.
"@

$missingTransition = Write-TestFile "missing-transition.md" @"
# Request Constraint Ledger

## Request Summary
- Refactor broad UI files.

## Preserved Invariants
- Existing ceremony order remains unchanged.

## Mutable Scope
- UI presenter helpers.

## Source Map Findings
- `docs/source-map.md` still maps the active UI presenter helpers that remain in scope.

## Transition Safety Review
PLACEHOLDER

## Refactor/Delete Disposition
- Keep active runtime scripts.

## Verification Checklist
- Run focused contracts.
"@

$runtimeOwnerWithoutUnits = Write-TestFile "runtime-owner-without-units.md" @'
# Request Constraint Ledger

## Request Summary
- Split `MainViewRuntime.gd` and tighten the refactor harness.

## Preserved Invariants
- Reward-board drag and drop semantics must stay unchanged.

## Mutable Scope
- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/RewardCardCloudHost.gd`
- `LTL-harness/tools/request-analysis-gate.ps1`

## Source Map Findings
- `app-LTL/src/ui/MainViewRuntime.gd` is the active runtime owner that still bundles reward-cloud behavior.
- `LTL-harness/tools/request-analysis-gate.ps1` is the pre-edit harness gate being tightened for owner-split coverage.

## Transition Safety Review
- no transition impact
- reason: reward-cloud extraction and harness planning only; no runtime page handoff changes

## Refactor/Delete Disposition
- Keep active runtime owners, but split the touched execution unit into dedicated helpers.

## Verification Checklist
- Run focused UI read-model tests and request-analysis self-tests.
'@

$runtimeOwnerWithUnits = Write-TestFile "runtime-owner-with-units.md" @'
# Request Constraint Ledger

## Request Summary
- Split `MainViewRuntime.gd` and tighten the refactor harness.

## Preserved Invariants
- Reward-board drag and drop semantics must stay unchanged.

## Mutable Scope
- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/RewardCardCloudHost.gd`
- `LTL-harness/tools/request-analysis-gate.ps1`

## Source Map Findings
- `app-LTL/src/ui/MainViewRuntime.gd` is the active runtime owner that still bundles reward-cloud behavior.
- `LTL-harness/tools/request-analysis-gate.ps1` is the pre-edit harness gate being tightened for owner-split coverage.

## Transition Safety Review
- no transition impact
- reason: reward-cloud extraction and harness planning only; no runtime page handoff changes

## Execution Responsibility Units
- Owner: `app-LTL/src/ui/MainViewRuntime.gd`
  - Unit: reward-card cloud runtime
  - Extract to: `app-LTL/src/ui/RewardCardCloudHost.gd`
  - Focused proof: `app-LTL/tests/ui_read_models/ui_reward_card_cloud_host_suite.gd`

## Refactor/Delete Disposition
- Keep active runtime owners, but split the touched execution unit into dedicated helpers.

## Verification Checklist
- Run focused UI read-model tests and request-analysis self-tests.
'@

$runtimeOwnerWithIncompleteUnits = Write-TestFile "runtime-owner-with-incomplete-units.md" @'
# Request Constraint Ledger

## Request Summary
- Split `MainViewRuntime.gd` and tighten the refactor harness.

## Preserved Invariants
- Reward-board drag and drop semantics must stay unchanged.

## Mutable Scope
- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/RewardCardCloudHost.gd`
- `LTL-harness/tools/request-analysis-gate.ps1`

## Source Map Findings
- `app-LTL/src/ui/MainViewRuntime.gd` is the active runtime owner that still bundles reward-cloud behavior.
- `LTL-harness/tools/request-analysis-gate.ps1` is the pre-edit harness gate being tightened for owner-split coverage.

## Transition Safety Review
- no transition impact
- reason: reward-cloud extraction and harness planning only; no runtime page handoff changes

## Execution Responsibility Units
- Owner: `app-LTL/src/ui/MainViewRuntime.gd`
  - Unit: reward-card cloud runtime
  - Focused proof: `app-LTL/tests/ui_read_models/ui_reward_card_cloud_host_suite.gd`

## Refactor/Delete Disposition
- Keep active runtime owners, but split the touched execution unit into dedicated helpers.

## Verification Checklist
- Run focused UI read-model tests and request-analysis self-tests.
'@

Assert-True (Test-Path -LiteralPath $gatePath) "request-analysis gate script is missing"

$preEdit = Invoke-RequestGate $validLedger "pre-edit"
Assert-True ($preEdit.Code -eq 0) "valid ledger should pass pre-edit: $($preEdit.Output)"
Assert-True ($preEdit.Output -match "REQUEST_ANALYSIS_GATE_OK") "pre-edit success should print marker"

$preComplete = Invoke-RequestGate $validLedger "pre-complete" @("-RequireArtifactLedger")
Assert-True ($preComplete.Code -eq 0) "valid ledger should pass pre-complete with artifact ledger: $($preComplete.Output)"

$badDisposition = Invoke-RequestGate $missingDisposition "pre-edit"
Assert-True ($badDisposition.Code -ne 0) "ledger without refactor/delete disposition should fail pre-edit"
Assert-True ($badDisposition.Output -match "Refactor/Delete Disposition") "failure should name missing disposition section: $($badDisposition.Output)"

$badSourceMap = Invoke-RequestGate $missingSourceMap "pre-edit"
Assert-True ($badSourceMap.Code -ne 0) "ledger without source map findings should fail pre-edit"
Assert-True ($badSourceMap.Output -match "Source Map Findings") "failure should name missing source map findings section: $($badSourceMap.Output)"

$badTransition = Invoke-RequestGate $missingTransition "pre-edit"
Assert-True ($badTransition.Code -ne 0) "ledger without a meaningful transition review should fail pre-edit"
Assert-True ($badTransition.Output -match "Transition Safety Review") "failure should name transition review coverage: $($badTransition.Output)"

$badVerification = Invoke-RequestGate $missingVerification "pre-complete"
Assert-True ($badVerification.Code -ne 0) "ledger without verification notes should fail pre-complete"
Assert-True ($badVerification.Output -match "Verification Notes") "failure should name missing verification notes: $($badVerification.Output)"

$runtimeOwnerPreEdit = Invoke-RequestGate $runtimeOwnerWithoutUnits "pre-edit"
Assert-True ($runtimeOwnerPreEdit.Code -ne 0) "ledger that touches a monitored runtime owner without execution responsibility units should fail pre-edit"
Assert-True ($runtimeOwnerPreEdit.Output -match "Execution Responsibility Units") "failure should name missing execution responsibility coverage: $($runtimeOwnerPreEdit.Output)"

$runtimeOwnerValid = Invoke-RequestGate $runtimeOwnerWithUnits "pre-edit"
Assert-True ($runtimeOwnerValid.Code -eq 0) "ledger that maps runtime-owner execution units should pass pre-edit: $($runtimeOwnerValid.Output)"
Assert-True ($runtimeOwnerValid.Output -match "REQUEST_ANALYSIS_GATE_OK") "runtime-owner success should still print the standard gate marker"

$runtimeOwnerMissingExtract = Invoke-RequestGate $runtimeOwnerWithIncompleteUnits "pre-edit"
Assert-True ($runtimeOwnerMissingExtract.Code -ne 0) "ledger that omits the extraction target for a monitored runtime owner should fail pre-edit"
Assert-True ($runtimeOwnerMissingExtract.Output -match "Extract to") "failure should name missing extraction coverage: $($runtimeOwnerMissingExtract.Output)"

Remove-TestRoot
Write-Output "REQUEST_ANALYSIS_GATE_TESTS_OK"
