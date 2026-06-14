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

## Root Cause Review
- Observed symptom: broad UI and harness requests can be declared complete even when the visible symptom is only masked at the presentation layer.
- Evidence: the ledger currently captures scope and verification, but this fixture assumes the root-cause section is present so other negative cases can fail on their intended missing section.
- Root cause target: LTL-harness/tools/request-analysis-gate.ps1
- Rejected workaround: documentation-only warnings that do not block verification are not sufficient.
- Chosen fix: enforce root-cause review and completion proof inside the blocking ledger schema.

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

## Resolution Proof
- RED proof: request-analysis gate self-tests fail before implementation when the new sections are missing.
- Root-cause proof: the strengthened gate blocks ledgers that do not name a root-cause target and chosen source fix.
- Workaround guard: completion cannot rely on a symptom-only workaround because the ledger must declare the rejected workaround explicitly.

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

## Root Cause Review
- Observed symptom: this fixture exists to prove missing disposition failures still point at the missing disposition section, not at root-cause coverage.
- Evidence: a valid root-cause review is included here so the gate keeps checking later required sections.
- Root cause target: app-LTL/src/ui/Presenter.gd
- Rejected workaround: changing button copy alone would not resolve the underlying ownership problem.
- Chosen fix: keep this fixture root-cause-complete and let the missing disposition section trigger the failure.

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

## Root Cause Review
- Observed symptom: this fixture exists to prove missing verification-notes failures still point at the completion evidence section.
- Evidence: a valid root-cause review is included here so the gate keeps checking later completion requirements.
- Root cause target: app-LTL/src/ui/Presenter.gd
- Rejected workaround: visual polish without source ownership repair would not satisfy the request.
- Chosen fix: keep the root-cause review valid and let verification-notes be the first missing completion section.

## Transition Safety Review
- no transition impact
- reason: this negative fixture is only checking a missing verification-notes section

## Refactor/Delete Disposition
- Keep active runtime scripts.

## Verification Checklist
- Run focused contracts.

## Resolution Proof
- RED proof: this fixture includes completion-side resolution proof so missing verification notes remain the intended failure.
- Root-cause proof: the source owner path is already identified above.
- Workaround guard: the fixture explicitly rejects symptom masking as a substitute for a source fix.
"@

$missingSourceMap = Write-TestFile "missing-source-map.md" @"
# Request Constraint Ledger

## Request Summary
- Refactor broad UI files.

## Preserved Invariants
- Existing ceremony order remains unchanged.

## Mutable Scope
- UI presenter helpers.

## Root Cause Review
- Observed symptom: this fixture exists to prove missing source-map-findings failures still point at source-map coverage.
- Evidence: a valid root-cause review is included here so the gate does not stop earlier.
- Root cause target: app-LTL/src/ui/Presenter.gd
- Rejected workaround: restyling the page without locating the owner path would be a symptom-only patch.
- Chosen fix: keep root-cause coverage valid and let the missing source-map section fail.

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

## Root Cause Review
- Observed symptom: this fixture exists to prove invalid transition-review text still points at transition coverage.
- Evidence: a valid root-cause review is included here so the malformed transition section is the blocking problem.
- Root cause target: app-LTL/src/ui/Presenter.gd
- Rejected workaround: cosmetics alone would not repair an invalid handoff contract.
- Chosen fix: keep the root-cause section valid and let transition coverage fail.

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

## Root Cause Review
- Observed symptom: monitored runtime owners can keep absorbing new behavior if the request only names file scope and not the execution slice being fixed.
- Evidence: this fixture keeps root-cause coverage valid so the gate can fail specifically on missing execution-responsibility units.
- Root cause target: app-LTL/src/ui/MainViewRuntime.gd
- Rejected workaround: editing the owner in place without naming the extraction target would preserve the oversized-owner anti-pattern.
- Chosen fix: require execution-responsibility coverage in addition to the root-cause review.

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

## Root Cause Review
- Observed symptom: monitored runtime owners need a root-cause explanation alongside extraction planning.
- Evidence: this fixture represents the fully valid pre-edit case once the new root-cause requirement is added.
- Root cause target: app-LTL/src/ui/MainViewRuntime.gd
- Rejected workaround: leaving the execution slice embedded in the large owner and only adjusting surface styling is not allowed.
- Chosen fix: pair the owner split plan with explicit root-cause review.

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

## Root Cause Review
- Observed symptom: monitored runtime-owner requests must still carry a valid root-cause review even when the execution-responsibility mapping is intentionally incomplete for a negative test.
- Evidence: this keeps the new root-cause requirement satisfied so the missing extraction target remains the intended failure.
- Root cause target: app-LTL/src/ui/MainViewRuntime.gd
- Rejected workaround: a broad owner edit without an extraction plan is still an anti-pattern.
- Chosen fix: let execution-responsibility coverage fail after the root-cause review passes.

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

$missingRootCause = Write-TestFile "missing-root-cause.md" @"
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
- reason: this negative fixture is only checking a missing root-cause review section

## Refactor/Delete Disposition
- Keep active runtime scripts.

## Verification Checklist
- Run focused contracts.
"@

$rootCauseMissingRejectedWorkaround = Write-TestFile "root-cause-missing-rejected-workaround.md" @"
# Request Constraint Ledger

## Request Summary
- Refactor broad UI files.

## Preserved Invariants
- Existing ceremony order remains unchanged.

## Mutable Scope
- UI presenter helpers.

## Source Map Findings
- `docs/source-map.md` still maps the active UI presenter helpers that remain in scope.

## Root Cause Review
- Observed symptom: this fixture checks that incomplete root-cause reviews fail explicitly.
- Evidence: the gate should require more than a symptom and target path.
- Root cause target: app-LTL/src/ui/Presenter.gd
- Chosen fix: update the owner logic instead of only touching UI copy.

## Transition Safety Review
- no transition impact
- reason: this negative fixture is only checking a malformed root-cause review section

## Refactor/Delete Disposition
- Keep active runtime scripts.

## Verification Checklist
- Run focused contracts.
"@

$missingResolutionProof = Write-TestFile "missing-resolution-proof.md" @"
# Request Constraint Ledger

## Request Summary
- Refactor broad UI files.

## Preserved Invariants
- Existing ceremony order remains unchanged.

## Mutable Scope
- UI presenter helpers.

## Source Map Findings
- `docs/source-map.md` still maps the active UI presenter helpers that remain in scope.

## Root Cause Review
- Observed symptom: this fixture checks that pre-complete runs require completion-side resolution proof.
- Evidence: a valid root-cause review is present so the gate should fail on the missing resolution-proof section.
- Root cause target: app-LTL/src/ui/Presenter.gd
- Rejected workaround: changing the label text alone would not solve the presenter ownership bug.
- Chosen fix: keep the source-owner repair requirement explicit.

## Transition Safety Review
- no transition impact
- reason: this negative fixture is only checking a missing resolution-proof section

## Refactor/Delete Disposition
- Keep active runtime scripts.

## Verification Checklist
- Run focused contracts.

## Verification Notes
- Focused contracts pass.
"@

$pendingResolutionProof = Write-TestFile "pending-resolution-proof.md" @"
# Request Constraint Ledger

## Request Summary
- Refactor broad UI files.

## Preserved Invariants
- Existing ceremony order remains unchanged.

## Mutable Scope
- UI presenter helpers.

## Source Map Findings
- `docs/source-map.md` still maps the active UI presenter helpers that remain in scope.

## Root Cause Review
- Observed symptom: this fixture checks that resolution proof cannot remain pending during pre-complete validation.
- Evidence: the root-cause review is valid so the remaining failure should point at pending completion proof.
- Root cause target: app-LTL/src/ui/Presenter.gd
- Rejected workaround: adjusting button copy alone would not fix the presenter ownership bug.
- Chosen fix: complete the owner repair and then record concrete proof.

## Transition Safety Review
- no transition impact
- reason: this negative fixture is only checking pending resolution proof text

## Refactor/Delete Disposition
- Keep active runtime scripts.

## Verification Checklist
- Run focused contracts.

## Verification Notes
- Focused contracts pass.

## Resolution Proof
- RED proof: pending
- Root-cause proof: pending
- Workaround guard: pending
"@

$badRootCause = Invoke-RequestGate $missingRootCause "pre-edit"
Assert-True ($badRootCause.Code -ne 0) "ledger without root-cause review should fail pre-edit"
Assert-True ($badRootCause.Output -match "Root Cause Review") "failure should name missing root-cause coverage: $($badRootCause.Output)"

$incompleteRootCause = Invoke-RequestGate $rootCauseMissingRejectedWorkaround "pre-edit"
Assert-True ($incompleteRootCause.Code -ne 0) "ledger with an incomplete root-cause review should fail pre-edit"
Assert-True ($incompleteRootCause.Output -match "Rejected workaround") "failure should name the missing rejected-workaround line: $($incompleteRootCause.Output)"

$badResolutionProof = Invoke-RequestGate $missingResolutionProof "pre-complete"
Assert-True ($badResolutionProof.Code -ne 0) "ledger without resolution proof should fail pre-complete"
Assert-True ($badResolutionProof.Output -match "Resolution Proof") "failure should name missing resolution proof coverage: $($badResolutionProof.Output)"

$pendingResolution = Invoke-RequestGate $pendingResolutionProof "pre-complete"
Assert-True ($pendingResolution.Code -ne 0) "ledger with pending resolution proof should fail pre-complete"
Assert-True ($pendingResolution.Output -match "cannot stay pending") "failure should name the pending resolution-proof guard: $($pendingResolution.Output)"

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
