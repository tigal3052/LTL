# Request Constraint Ledger

## Request Summary

- Fix the battle tile-hit stutter introduced after the English/Korean settings-language fix and add harness rules requiring runtime performance evidence for high-frequency paths.

## Preserved Invariants

- English/Korean settings selection must still refresh active and inactive meta pages when the locale actually changes.
- Battle tile hover, click, hold-fire, damage popups, and page identity must stay unchanged.
- `MainViewRuntime.gd` must stay within its frozen runtime-size cap.
- Harness request-analysis checks must keep existing root-cause and execution-responsibility behavior.

## Mutable Scope

- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/PageSceneModelBuilder.gd`
- `app-LTL/tests/run_battle_render_performance_contract.gd`
- `LTL-harness/tools/request-analysis-gate.ps1`
- `LTL-harness/tools/request-analysis-gate.tests.ps1`
- `LTL-harness/docs/request-analysis-execution-gate.md`
- `LTL-harness/docs/templates/request-constraint-ledger-template.md`
- `LTL-harness/00_AGENTS.md`
- `docs/source-map.md`

## Source Map Findings

- `app-LTL/src/ui/MainViewRuntime.gd` owns the high-frequency battle render path that runs after tile hover/click state changes.
- `app-LTL/src/ui/PageSceneModelBuilder.gd` centralizes page-scene projection and is a smaller helper owner for inactive meta-page refresh projection.
- `app-LTL/tests/run_settings_language_apply_contract.gd` protects the bidirectional locale-switching fix that caused the regression.
- `LTL-harness/tools/request-analysis-gate.ps1` validates request ledgers before edits and completion.

## Root Cause Review

- Observed symptom: battle tile hits visibly stutter after the English/Korean settings-language fix.
- Evidence: the RED `run_battle_render_performance_contract.gd` showed eight repeated battle renders applied state to each inactive meta page eight times.
- Root cause target: `app-LTL/src/ui/MainViewRuntime.gd`
- Rejected workaround: lowering VFX intensity, skipping hit feedback, or changing tile input cadence would mask the symptom while leaving hidden-page UI work on the hot path.
- Chosen fix: keep inactive meta-page refresh for settings locale application only, move the refresh loop into `PageSceneModelBuilder.gd`, and leave ordinary battle renders free of hidden meta-page `apply_state` work.

## Runtime Performance Review

- Hot path: `app-LTL/src/ui/MainViewRuntime.gd::render_scene` during repeated battle tile-hit and hover refresh.
- Risk: hidden meta-page `apply_state` calls can rebuild inactive page rosters, labels, textures, style overrides, and layout state during each combat render.
- Performance proof: `app-LTL/tests/run_battle_render_performance_contract.gd`
- Budget: inactive meta-page `apply_state` calls remain 0 across repeated battle renders.

## Transition Safety Review

- no transition impact
- reason: this change only narrows page-state refresh scheduling and harness ledger validation; it does not change phase entry, phase exit, or runtime handoff contracts.

## Execution Responsibility Units

- Owner: `app-LTL/src/ui/MainViewRuntime.gd`
  - Unit: inactive meta-page locale refresh scheduling
  - Extract to: `app-LTL/src/ui/PageSceneModelBuilder.gd`
  - Focused proof: `app-LTL/tests/run_battle_render_performance_contract.gd`

## Refactor/Delete Disposition

- Keep `MainViewRuntime.gd` as the page scene orchestration owner, but do not grow it beyond the frozen cap.
- Keep `PageSceneModelBuilder.gd` as the projection helper for page-state models and the inactive meta-page refresh loop.
- Add the focused performance contract instead of broad timing assertions that would be environment-sensitive.
- No deletion is required.

## Verification Checklist

- Run the new battle render performance contract.
- Run the settings-language apply contract.
- Run the i18n smoke contract.
- Run the full Godot contract runner.
- Run request-analysis gate self-tests.
- Run source-map, test-size, and runtime-size gates.

## Verification Notes

- Battle performance proof: `run_battle_render_performance_contract.gd` passed with `BATTLE_RENDER_PERFORMANCE_CONTRACT_OK`.
- Locale regression proof: `run_settings_language_apply_contract.gd` passed with `SETTINGS_LANGUAGE_APPLY_CONTRACT_OK`.
- i18n smoke proof: `run_i18n_localization_smoke.gd` passed with `I18N_LOCALIZATION_SMOKE_OK`.
- Full Godot proof: `godot_contract_runner.gd` passed with `GODOT_CONTRACTS_OK`; it still prints existing headless shutdown RID/resource warnings.
- Harness proof: `request-analysis-gate.tests.ps1` passed with `REQUEST_ANALYSIS_GATE_TESTS_OK`.
- Map/size proof: source-map, test-size, and runtime-size gates passed; test-size kept only existing oversized legacy warnings.

## Resolution Proof

- RED proof: before the fix, `run_battle_render_performance_contract.gd` failed because each inactive meta page received 8 `apply_state` calls across 8 repeated battle renders.
- Root-cause proof: after the fix, the same contract passed and ordinary battle renders produced 0 inactive meta-page `apply_state` calls.
- Workaround guard: `run_settings_language_apply_contract.gd` still passed, proving the language-refresh behavior was preserved instead of simply removing inactive meta-page refresh.

## Artifact Ledger

- Godot logs: `app-LTL/.tmp-godot-logs/run_battle_render_performance_contract.log`
- Godot logs: `app-LTL/.tmp-godot-logs/run_settings_language_apply_contract.log`
- Godot logs: `app-LTL/.tmp-godot-logs/run_i18n_localization_smoke.log`
- Godot logs: `app-LTL/.tmp-godot-logs/godot_contract_runner.log`
