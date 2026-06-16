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
- Split `CharacterSelectPage.gd` and tighten the refactor harness.

## Preserved Invariants
- Character select loadout choice, selected character state, and start flow behavior must stay unchanged.

## Mutable Scope
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`
- `LTL-harness/tools/request-analysis-gate.ps1`

## Source Map Findings
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd` is an active runtime owner near the strict 500-line source cap.
- `LTL-harness/tools/request-analysis-gate.ps1` is the pre-edit harness gate being tightened for owner-split coverage.

## Root Cause Review
- Observed symptom: monitored runtime owners can keep absorbing new behavior if the request only names file scope and not the execution slice being fixed.
- Evidence: this fixture keeps root-cause coverage valid so the gate can fail specifically on missing execution-responsibility units.
- Root cause target: app-LTL/src/scenes/pages/CharacterSelectPage.gd
- Rejected workaround: editing the owner in place without naming the extraction target would preserve the oversized-owner anti-pattern.
- Chosen fix: require execution-responsibility coverage in addition to the root-cause review.

## Transition Safety Review
- no transition impact
- reason: loadout-text extraction and harness planning only; no runtime page handoff changes

## Feature Unit Lifecycle Plan
- Design stage: keep `CharacterSelectPage.gd` as the page composition owner and move loadout text projection into a helper capsule.
- Implementation stage: write focused character-select tests before moving behavior.
- Maintenance stage: future character-select additions must join an existing page helper only when the responsibility matches.
- Capsule boundary: helper public methods accept selected loadout state and hide copy formatting details inside the unit.
- Size trigger: `CharacterSelectPage.gd` is near the 500-line cap, so any new behavior must name an extraction target before editing.

## Refactor/Delete Disposition
- Keep active runtime owners, but split the touched execution unit into dedicated helpers.

## Verification Checklist
- Run focused UI read-model tests and request-analysis self-tests.
'@

$runtimeOwnerWithUnits = Write-TestFile "runtime-owner-with-units.md" @'
# Request Constraint Ledger

## Request Summary
- Split `CharacterSelectPage.gd` and tighten the refactor harness.

## Preserved Invariants
- Character select loadout choice, selected character state, and start flow behavior must stay unchanged.

## Mutable Scope
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`
- `LTL-harness/tools/request-analysis-gate.ps1`

## Source Map Findings
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd` is an active runtime owner near the strict 500-line source cap.
- `LTL-harness/tools/request-analysis-gate.ps1` is the pre-edit harness gate being tightened for owner-split coverage.

## Root Cause Review
- Observed symptom: monitored runtime owners need a root-cause explanation alongside extraction planning.
- Evidence: this fixture represents the fully valid pre-edit case once the new root-cause requirement is added.
- Root cause target: app-LTL/src/scenes/pages/CharacterSelectPage.gd
- Rejected workaround: leaving the execution slice embedded in the large owner and only adjusting surface styling is not allowed.
- Chosen fix: pair the owner split plan with explicit root-cause review.

## Transition Safety Review
- no transition impact
- reason: loadout-text extraction and harness planning only; no runtime page handoff changes

## Feature Unit Lifecycle Plan
- Design stage: keep `CharacterSelectPage.gd` as the page composition owner and move loadout text projection into a helper capsule.
- Implementation stage: write focused character-select tests before moving behavior.
- Maintenance stage: future character-select additions must join an existing page helper only when the responsibility matches.
- Capsule boundary: helper public methods accept selected loadout state and hide copy formatting details inside the unit.
- Size trigger: `CharacterSelectPage.gd` is near the 500-line cap, so any new behavior must name an extraction target before editing.

## Execution Responsibility Units
- Owner: `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
  - Unit: starter loadout text projection
  - Extract to: `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`
  - Focused proof: `app-LTL/tests/run_character_select_cleanup_contract.gd`

## Refactor/Delete Disposition
- Keep active runtime owners, but split the touched execution unit into dedicated helpers.

## Verification Checklist
- Run focused UI read-model tests and request-analysis self-tests.
'@

$runtimeOwnerWithIncompleteUnits = Write-TestFile "runtime-owner-with-incomplete-units.md" @'
# Request Constraint Ledger

## Request Summary
- Split `CharacterSelectPage.gd` and tighten the refactor harness.

## Preserved Invariants
- Character select loadout choice, selected character state, and start flow behavior must stay unchanged.

## Mutable Scope
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`
- `LTL-harness/tools/request-analysis-gate.ps1`

## Source Map Findings
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd` is an active runtime owner near the strict 500-line source cap.
- `LTL-harness/tools/request-analysis-gate.ps1` is the pre-edit harness gate being tightened for owner-split coverage.

## Root Cause Review
- Observed symptom: monitored runtime-owner requests must still carry a valid root-cause review even when the execution-responsibility mapping is intentionally incomplete for a negative test.
- Evidence: this keeps the new root-cause requirement satisfied so the missing extraction target remains the intended failure.
- Root cause target: app-LTL/src/scenes/pages/CharacterSelectPage.gd
- Rejected workaround: a broad owner edit without an extraction plan is still an anti-pattern.
- Chosen fix: let execution-responsibility coverage fail after the root-cause review passes.

## Transition Safety Review
- no transition impact
- reason: loadout-text extraction and harness planning only; no runtime page handoff changes

## Feature Unit Lifecycle Plan
- Design stage: keep `CharacterSelectPage.gd` as the page composition owner and move loadout text projection into a helper capsule.
- Implementation stage: write focused character-select tests before moving behavior.
- Maintenance stage: future character-select additions must join an existing page helper only when the responsibility matches.
- Capsule boundary: helper public methods accept selected loadout state and hide copy formatting details inside the unit.
- Size trigger: `CharacterSelectPage.gd` is near the 500-line cap, so any new behavior must name an extraction target before editing.

## Execution Responsibility Units
- Owner: `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
  - Unit: starter loadout text projection
  - Focused proof: `app-LTL/tests/run_character_select_cleanup_contract.gd`

## Refactor/Delete Disposition
- Keep active runtime owners, but split the touched execution unit into dedicated helpers.

## Verification Checklist
- Run focused UI read-model tests and request-analysis self-tests.
'@

$globCappedOwnerWithoutUnits = Write-TestFile "glob-capped-owner-without-units.md" @'
# Request Constraint Ledger

## Request Summary
- Rework the character select page while keeping runtime source files below the global size cap.

## Preserved Invariants
- Character select loadout choice, selected character state, and start flow behavior must remain unchanged unless a focused proof says otherwise.

## Mutable Scope
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`

## Source Map Findings
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd` is an active runtime page owner that is covered by the `app-LTL/src/**/*.gd=500` runtime-size glob.
- `docs/architectural-gates/runtime-size-gate.md` declares strict runtime source caps that should affect pre-edit planning.

## Root Cause Review
- Observed symptom: glob-capped runtime files can still absorb new behavior when pre-edit validation only monitors exact debt paths.
- Evidence: this fixture names `CharacterSelectPage.gd`, which is capped by a strict glob but not listed in legacy debt caps.
- Root cause target: LTL-harness/tools/request-analysis-gate.ps1
- Rejected workaround: waiting for the final runtime-size gate would catch the oversized file only after implementation.
- Chosen fix: require execution-responsibility coverage for strict-glob runtime paths before editing.

## Transition Safety Review
- no transition impact
- reason: this fixture only validates pre-edit planning for a runtime UI owner

## Feature Unit Lifecycle Plan
- Design stage: keep `CharacterSelectPage.gd` as the page composition owner and move loadout text projection into a helper capsule.
- Implementation stage: add focused character-select proof before moving loadout projection behavior.
- Maintenance stage: future character-select copy or projection changes must extend the helper only when they remain loadout-text concerns.
- Capsule boundary: the helper exposes text projection only and keeps formatting details private.
- Size trigger: `CharacterSelectPage.gd` is near the 500-line cap, so new behavior must name a split target before editing.

## Refactor/Delete Disposition
- Keep `CharacterSelectPage.gd` as the composition owner, but split the touched loadout-copy unit into a helper.

## Verification Checklist
- Run focused character-select contracts and request-analysis self-tests.
'@

$globCappedOwnerWithUnits = Write-TestFile "glob-capped-owner-with-units.md" @'
# Request Constraint Ledger

## Request Summary
- Rework the character select page while keeping runtime source files below the global size cap.

## Preserved Invariants
- Character select loadout choice, selected character state, and start flow behavior must remain unchanged unless a focused proof says otherwise.

## Mutable Scope
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`

## Source Map Findings
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd` is an active runtime page owner that is covered by the `app-LTL/src/**/*.gd=500` runtime-size glob.
- `docs/architectural-gates/runtime-size-gate.md` declares strict runtime source caps that should affect pre-edit planning.

## Root Cause Review
- Observed symptom: glob-capped runtime files need the same pre-edit split planning as exact debt owners.
- Evidence: this fixture names `CharacterSelectPage.gd`, which should resolve through strict glob caps even without an exact manifest entry.
- Root cause target: LTL-harness/tools/request-analysis-gate.ps1
- Rejected workaround: trusting completion-time size checks alone leaves agents to refactor after they already implemented too much in one file.
- Chosen fix: map the glob-capped owner to a concrete extraction unit before implementation starts.

## Transition Safety Review
- no transition impact
- reason: this fixture only validates pre-edit planning for a runtime UI owner

## Feature Unit Lifecycle Plan
- Design stage: keep `CharacterSelectPage.gd` as the page composition owner and move loadout text projection into a helper capsule.
- Implementation stage: add focused character-select proof before moving loadout projection behavior.
- Maintenance stage: future character-select copy or projection changes must extend the helper only when they remain loadout-text concerns.
- Capsule boundary: the helper exposes text projection only and keeps formatting details private.
- Size trigger: `CharacterSelectPage.gd` is near the 500-line cap, so new behavior must name a split target before editing.

## Execution Responsibility Units
- Owner: `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
  - Unit: starter loadout text projection
  - Extract to: `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`
  - Focused proof: `app-LTL/tests/run_character_select_cleanup_contract.gd`

## Refactor/Delete Disposition
- Keep `CharacterSelectPage.gd` as the composition owner, but split the touched loadout-copy unit into a helper.

## Verification Checklist
- Run focused character-select contracts and request-analysis self-tests.
'@

$sourceScopeWithoutLifecyclePlan = Write-TestFile "source-scope-without-lifecycle-plan.md" @'
# Request Constraint Ledger

## Request Summary
- Rework the character select page while keeping future maintenance changes split by feature unit.

## Preserved Invariants
- Character select loadout choice, selected character state, and start flow behavior must remain unchanged.

## Mutable Scope
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`

## Source Map Findings
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd` is an active runtime page owner covered by the strict `app-LTL/src/**/*.gd=500` cap.
- The completed 500-line split showed that maintenance edits need a feature-unit lifecycle plan before adding behavior to capped owners.

## Root Cause Review
- Observed symptom: capped source owners can regrow during maintenance when a request names the file and extraction target but not the design, implementation, and maintenance lifecycle guard.
- Evidence: this fixture includes execution-responsibility coverage, so the missing lifecycle plan should be the blocking issue.
- Root cause target: LTL-harness/tools/request-analysis-gate.ps1
- Rejected workaround: relying on the final runtime-size gate after implementation would catch drift too late.
- Chosen fix: require a feature-unit lifecycle plan before editing source or harness implementation surfaces.

## Transition Safety Review
- no transition impact
- reason: this fixture only validates planning requirements for a runtime UI owner

## Execution Responsibility Units
- Owner: `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
  - Unit: starter loadout text projection
  - Extract to: `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`
  - Focused proof: `app-LTL/tests/run_character_select_cleanup_contract.gd`

## Refactor/Delete Disposition
- Keep `CharacterSelectPage.gd` as the composition owner, but split maintenance additions by feature unit.

## Verification Checklist
- Run focused character-select contracts and request-analysis self-tests.
'@

$highFrequencyRuntimeWithoutPerformanceReview = Write-TestFile "high-frequency-runtime-without-performance-review.md" @'
# Request Constraint Ledger

## Request Summary
- Fix battle tile-hit render stutter after a settings-language refresh change.

## Preserved Invariants
- English/Korean settings changes must still refresh active and inactive meta pages when locale actually changes.
- Battle tile targeting, damage feedback, and page identity must stay unchanged.

## Mutable Scope
- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/tests/run_battle_render_performance_contract.gd`

## Source Map Findings
- `app-LTL/src/ui/MainViewRuntime.gd` owns the high-frequency battle render path that is called after tile-hit state changes.
- `app-LTL/tests/run_settings_language_apply_contract.gd` covers the language-refresh regression that must remain fixed.

## Root Cause Review
- Observed symptom: battle tile hits stutter after the settings-language fix.
- Evidence: repeated combat renders call inactive meta-page state refreshes even though no locale changed.
- Root cause target: app-LTL/src/ui/MainViewRuntime.gd
- Rejected workaround: lowering VFX intensity or skipping tile feedback would hide the symptom without reducing the render work.
- Chosen fix: move inactive meta-page refresh out of ordinary battle renders and into locale-driven refresh only.

## Transition Safety Review
- no transition impact
- reason: this fixture only changes render refresh scheduling, not phase transitions

## Feature Unit Lifecycle Plan
- Design stage: keep render-scene orchestration separate from locale-only inactive meta-page refresh scheduling.
- Implementation stage: add battle render performance proof before changing refresh scheduling.
- Maintenance stage: future render-path changes must declare whether they affect battle render, locale refresh, or page transition capsules.
- Capsule boundary: scheduling policy exposes one render-refresh decision and hides inactive page traversal details.
- Size trigger: high-frequency runtime paths require split or non-growth planning even when the current owner is below the hard cap.

## Execution Responsibility Units
- Owner: `app-LTL/src/ui/MainViewRuntime.gd`
  - Unit: inactive meta-page locale refresh scheduling
  - Extract to: `app-LTL/src/ui/MainViewRuntime.gd`
  - Focused proof: `app-LTL/tests/run_battle_render_performance_contract.gd`

## Refactor/Delete Disposition
- Keep the page scene owner; change only the high-frequency refresh policy.

## Verification Checklist
- Run focused battle render performance and settings-language contracts.
'@

$highFrequencyRuntimeWithPerformanceReview = Write-TestFile "high-frequency-runtime-with-performance-review.md" @'
# Request Constraint Ledger

## Request Summary
- Fix battle tile-hit render stutter after a settings-language refresh change.

## Preserved Invariants
- English/Korean settings changes must still refresh active and inactive meta pages when locale actually changes.
- Battle tile targeting, damage feedback, and page identity must stay unchanged.

## Mutable Scope
- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/tests/run_battle_render_performance_contract.gd`

## Source Map Findings
- `app-LTL/src/ui/MainViewRuntime.gd` owns the high-frequency battle render path that is called after tile-hit state changes.
- `app-LTL/tests/run_settings_language_apply_contract.gd` covers the language-refresh regression that must remain fixed.

## Root Cause Review
- Observed symptom: battle tile hits stutter after the settings-language fix.
- Evidence: repeated combat renders call inactive meta-page state refreshes even though no locale changed.
- Root cause target: app-LTL/src/ui/MainViewRuntime.gd
- Rejected workaround: lowering VFX intensity or skipping tile feedback would hide the symptom without reducing the render work.
- Chosen fix: move inactive meta-page refresh out of ordinary battle renders and into locale-driven refresh only.

## Runtime Performance Review
- Hot path: `app-LTL/src/ui/MainViewRuntime.gd::render_scene` during battle tile-hit refresh.
- Risk: hidden meta-page `apply_state` calls can invalidate inactive UI trees during repeated combat renders.
- Performance proof: `app-LTL/tests/run_battle_render_performance_contract.gd`
- Budget: inactive meta-page `apply_state` calls remain 0 across repeated battle renders.

## Transition Safety Review
- no transition impact
- reason: this fixture only changes render refresh scheduling, not phase transitions

## Feature Unit Lifecycle Plan
- Design stage: keep render-scene orchestration separate from locale-only inactive meta-page refresh scheduling.
- Implementation stage: add battle render performance proof before changing refresh scheduling.
- Maintenance stage: future render-path changes must declare whether they affect battle render, locale refresh, or page transition capsules.
- Capsule boundary: scheduling policy exposes one render-refresh decision and hides inactive page traversal details.
- Size trigger: high-frequency runtime paths require split or non-growth planning even when the current owner is below the hard cap.

## Execution Responsibility Units
- Owner: `app-LTL/src/ui/MainViewRuntime.gd`
  - Unit: inactive meta-page locale refresh scheduling
  - Extract to: `app-LTL/src/ui/MainViewRuntime.gd`
  - Focused proof: `app-LTL/tests/run_battle_render_performance_contract.gd`

## Refactor/Delete Disposition
- Keep the page scene owner; change only the high-frequency refresh policy.

## Verification Checklist
- Run focused battle render performance and settings-language contracts.
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

$globCappedOwnerPreEdit = Invoke-RequestGate $globCappedOwnerWithoutUnits "pre-edit"
Assert-True ($globCappedOwnerPreEdit.Code -ne 0) "ledger that touches a strict-glob runtime owner without execution responsibility units should fail pre-edit"
Assert-True ($globCappedOwnerPreEdit.Output -match "CharacterSelectPage" -and $globCappedOwnerPreEdit.Output -match "Execution Responsibility Units") "failure should name the glob-capped runtime owner and missing execution responsibility coverage: $($globCappedOwnerPreEdit.Output)"

$globCappedOwnerValid = Invoke-RequestGate $globCappedOwnerWithUnits "pre-edit"
Assert-True ($globCappedOwnerValid.Code -eq 0) "ledger that maps a strict-glob runtime owner should pass pre-edit: $($globCappedOwnerValid.Output)"
Assert-True ($globCappedOwnerValid.Output -match "REQUEST_ANALYSIS_GATE_OK") "glob-capped owner success should still print the standard gate marker"

$missingLifecyclePlan = Invoke-RequestGate $sourceScopeWithoutLifecyclePlan "pre-edit"
Assert-True ($missingLifecyclePlan.Code -ne 0) "ledger that touches source implementation scope without a feature-unit lifecycle plan should fail pre-edit"
Assert-True ($missingLifecyclePlan.Output -match "Feature Unit Lifecycle Plan") "failure should name missing feature-unit lifecycle planning: $($missingLifecyclePlan.Output)"

$highFrequencyMissingPerformance = Invoke-RequestGate $highFrequencyRuntimeWithoutPerformanceReview "pre-edit"
Assert-True ($highFrequencyMissingPerformance.Code -ne 0) "ledger that touches a high-frequency runtime path without performance review should fail pre-edit"
Assert-True ($highFrequencyMissingPerformance.Output -match "Runtime Performance Review") "failure should name missing runtime performance-review coverage: $($highFrequencyMissingPerformance.Output)"

$highFrequencyValid = Invoke-RequestGate $highFrequencyRuntimeWithPerformanceReview "pre-edit"
Assert-True ($highFrequencyValid.Code -eq 0) "ledger that maps high-frequency runtime performance proof should pass pre-edit: $($highFrequencyValid.Output)"
Assert-True ($highFrequencyValid.Output -match "REQUEST_ANALYSIS_GATE_OK") "high-frequency runtime success should still print the standard gate marker"

Remove-TestRoot
Write-Output "REQUEST_ANALYSIS_GATE_TESTS_OK"
