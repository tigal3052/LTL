# Request Constraint Ledger

## Request Summary

- `app-LTL/src/MainControllerRuntime.gd` is over 1000 lines.
- `app-LTL/src/MainController.gd` currently only extends `MainControllerRuntime.gd`.
- Replace the empty facade/runtime implementation split with a cleaner controller ownership model.
- Split by feature where feasible, or document a justified exception if a long controller remains.

## Preserved Invariants

- `app-LTL/src/Main.tscn` keeps a `MainController` node as the main-scene controller.
- Existing page ids, transition phases, node-select behavior, reward flow, combat input behavior, and accessibility persistence stay behaviorally stable.
- Existing dirty worktree changes are preserved and not reverted.
- Headless Godot contracts remain the verification source for runtime behavior.

## Mutable Scope

- `app-LTL/src/MainController.gd`
- `app-LTL/src/MainControllerRuntime.gd`
- `app-LTL/src/controllers/MainControllerStartFlow.gd`
- `app-LTL/src/controllers/MainControllerNodeSelection.gd`
- `app-LTL/src/controllers/MainControllerCombatInput.gd`
- `app-LTL/src/controllers/MainControllerAccessibilityStore.gd`
- `app-LTL/src/controllers/MainControllerDisplayText.gd`
- `app-LTL/src/controllers/MainControllerSceneProjection.gd`
- `app-LTL/src/controllers/MainControllerRewardBackpackFlow.gd`
- `app-LTL/src/controllers/MainControllerCombatFlow.gd`
- `app-LTL/src/controllers/MainControllerRunFlow.gd`
- `app-LTL/src/controllers/MainControllerRenderFlow.gd`
- `app-LTL/src/controllers/MainControllerSupportFlow.gd`
- `app-LTL/src/controllers/MainControllerBootstrapFlow.gd`
- `app-LTL/tests/godot_contract_runner.gd`
- `app-LTL/tests/support/UiReadModelTestSuite.gd`
- `app-LTL/tests/run_codex_pause_timing_contract.gd`
- `app-LTL/tests/run_i18n_localization_smoke.gd`
- `app-LTL/tests/test_start_option_contract.gd`
- `app-LTL/tests/ui_read_models/ui_interaction_controller_suite.gd`
- `app-LTL/tests/ui_read_models/ui_interaction_feedback_accessibility_suite.gd`
- `app-LTL/tests/ui_read_models/ui_codex_reward_board_suite.gd`
- `app-LTL/tests/ui_read_models/ui_main_controller_structure_suite.gd`
- `docs/architectural-gates/runtime-size-gate.md`
- `docs/source-map.md`
- `docs/request-ledgers/2026-06-15-main-controller-ownership-split.md`
- `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-15.md`
- `docs/codex-worklog/history_LootingTheLeviathan_2026-06-15.md`
- `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-15.md`

## Source Map Findings

- `app-LTL/src/MainController.gd`
  - Currently mapped as the formal main controller entry script by inheriting `MainControllerRuntime`.
- `app-LTL/src/MainControllerRuntime.gd`
  - Currently mapped as the owner for ready-time domain/runtime bootstrap, combat inputs, backpack/reward transitions, scene rendering handoff, shop/codex actions, timers, and queue color updates.
- `docs/architectural-gates/runtime-size-gate.md`
  - Lists `app-LTL/src/MainControllerRuntime.gd=1667` as frozen legacy debt, while the current file has grown past that baseline.
- `docs/superpowers/plans/2026-06-11-runtime-owner-separation-plan.md`
  - Already names the next `MainControllerRuntime.gd` split wave as start-flow, reward-flow, and codex/debug helper extraction.

## Root Cause Review

- Observed symptom: the scene script is only an inheritance wrapper while the real controller implementation keeps accumulating in a thousand-line runtime file.
- Evidence: `Main.tscn` points to `MainController.gd`, but `MainController.gd` only extends `res://src/MainControllerRuntime.gd`; `MainControllerRuntime.gd` is currently 1731 lines.
- Root cause target: `app-LTL/src/MainControllerRuntime.gd`
- Rejected workaround: raising the runtime-size cap, changing only comments, or leaving `MainController.gd` as an empty wrapper while extracting unrelated code.
- Chosen fix: make `MainController.gd` the active controller owner and extract low-coupled feature units into controller helper scripts before touching high-risk reward/backpack orchestration.

## Transition Safety Review

- Entry owner: `app-LTL/src/Main.tscn` `MainController` node using `app-LTL/src/MainController.gd`.
- Exit owner: `app-LTL/src/MainController.gd` delegating to helper scripts without changing phase ids or scene snapshots.
- Shared handoff risks: direct test preloads and contract lists currently reference `MainControllerRuntime.gd`; these must move to `MainController.gd` or focused helpers.
- Proof: `app-LTL/tests/godot_contract_runner.gd`, `app-LTL/tests/run_main_start_flow_contract.gd`, and `app-LTL/tests/run_node_select_start_gate_contract.gd`.

## Runtime Performance Review

- Hot path: `app-LTL/src/MainControllerRuntime.gd` combat click, hold-fire, process tick, and render-scene orchestration.
- Risk: moving helpers could add extra allocation or node traversal in repeated combat input/render paths.
- Performance proof: `app-LTL/tests/run_battle_render_performance_contract.gd`
- Budget: extracted combat helpers stay static/pure dictionary logic; no per-frame node lookup, no hidden-page render work, and no additional full scene rebuild loops.

## Execution Responsibility Units

- Owner: `app-LTL/src/MainControllerRuntime.gd`
  - Unit: scene controller ownership and low-coupled decision/projection helpers.
  - Extract to: `app-LTL/src/controllers/MainControllerStartFlow.gd`
  - Focused proof: `app-LTL/tests/run_i18n_localization_smoke.gd`
- Owner: `app-LTL/src/MainControllerRuntime.gd`
  - Unit: node-select context and start eligibility projection.
  - Extract to: `app-LTL/src/controllers/MainControllerNodeSelection.gd`
  - Focused proof: `app-LTL/tests/run_node_select_start_gate_contract.gd`
- Owner: `app-LTL/src/MainControllerRuntime.gd`
  - Unit: combat click/hold-fire static decisions and damage popup event projection.
  - Extract to: `app-LTL/src/controllers/MainControllerCombatInput.gd`
  - Focused proof: `app-LTL/tests/run_test_ui_read_models.gd`
- Owner: `app-LTL/src/MainControllerRuntime.gd`
  - Unit: accessibility settings normalization and config persistence.
  - Extract to: `app-LTL/src/controllers/MainControllerAccessibilityStore.gd`
  - Focused proof: `app-LTL/tests/run_test_ui_read_models.gd`
- Owner: `app-LTL/src/MainController.gd`
  - Unit: localized display labels for controller logs, shop messages, and codex debug messages.
  - Extract to: `app-LTL/src/controllers/MainControllerDisplayText.gd`
  - Focused proof: `app-LTL/tests/run_test_ui_read_models.gd`
- Owner: `app-LTL/src/MainController.gd`
  - Unit: scene snapshot projections for active queue color, current target, and node-select summary.
  - Extract to: `app-LTL/src/controllers/MainControllerSceneProjection.gd`
  - Focused proof: `app-LTL/tests/run_test_ui_read_models.gd`
- Follow-up owner: `app-LTL/src/MainController.gd`
  - Unit: reward tray, backpack drag/drop, placement, discard, and reward-claim side effects.
  - Extract to: `app-LTL/src/controllers/MainControllerRewardBackpackFlow.gd`
  - Focused proof: `app-LTL/tests/run_reward_handoff_contract.gd`
- Follow-up owner: `app-LTL/src/MainController.gd`
  - Unit: combat click, hover, hold-fire, pause, terrain timer, queue recalculation, and pure targeting/projection helpers.
  - Extract to: `app-LTL/src/controllers/MainControllerCombatFlow.gd`
  - Focused proof: `app-LTL/tests/run_battle_render_performance_contract.gd`
- Follow-up owner: `app-LTL/src/MainController.gd`
  - Unit: start/reset/loadout/character/leviathan/node-selection flow.
  - Extract to: `app-LTL/src/controllers/MainControllerRunFlow.gd`
  - Focused proof: `app-LTL/tests/run_main_start_flow_contract.gd`
- Follow-up owner: `app-LTL/src/MainController.gd`
  - Unit: scene decoration, page id resolution, scene rendering handoff, and reward tray rendering.
  - Extract to: `app-LTL/src/controllers/MainControllerRenderFlow.gd`
  - Focused proof: `app-LTL/tests/run_test_ui_read_models.gd`
- Follow-up owner: `app-LTL/src/MainController.gd`
  - Unit: shop-disabled actions, codex open/close, growth modifiers, shop telemetry, and accessibility persistence.
  - Extract to: `app-LTL/src/controllers/MainControllerSupportFlow.gd`
  - Focused proof: `app-LTL/tests/run_settings_language_apply_contract.gd`
- Follow-up owner: `app-LTL/src/MainController.gd`
  - Unit: `_ready` bootstrap, signal wiring, and initial render/timer setup.
  - Extract to: `app-LTL/src/controllers/MainControllerBootstrapFlow.gd`
  - Focused proof: `app-LTL/tests/godot_contract_runner.gd`

## Refactor/Delete Disposition

- Preferred disposition: delete `MainControllerRuntime.gd` from active runtime ownership and migrate direct preloads to `MainController.gd`.
- If a temporary compatibility script is unavoidable, it must be small, documented as transitional, and cannot own gameplay/runtime logic.
- Follow-up disposition: reward/backpack orchestration was split after focused RED/GREEN checks, and the earlier tiny helpers were merged into feature owners. Deleted obsolete helper files: `MainControllerStartFlow.gd`, `MainControllerNodeSelection.gd`, `MainControllerCombatInput.gd`, `MainControllerAccessibilityStore.gd`, and `MainControllerSceneProjection.gd`.

## Verification Checklist

- Run request-analysis pre-edit gate before source edits.
- Run focused RED proof for direct runtime-script dependency or helper ownership before moving code.
- Run focused controller/helper suites after migration.
- Run runtime-size gate to prove the frozen oversized owner is no longer growing.
- Run source-map gate after docs update.
- Run compile check with the request ledger.

## Verification Notes

- RED proof captured before implementation:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd` failed because `res://src/controllers/MainControllerStartFlow.gd`, `MainControllerNodeSelection.gd`, `MainControllerCombatInput.gd`, and `MainControllerAccessibilityStore.gd` did not exist yet.
  - The same run also surfaced a Godot crash after repeated missing preload compile errors; the root failure still names the missing helper scripts required by the new ownership contract.
- Green focused proof:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd` -> `UI_READ_MODEL_TESTS_OK`.
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_i18n_localization_smoke.gd` -> `I18N_LOCALIZATION_SMOKE_OK`.
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_codex_pause_timing_contract.gd` -> `CODEX_PAUSE_TIMING_CONTRACT_OK`.
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_start_flow_contract.gd` -> `MAIN_START_FLOW_CONTRACT_OK`.
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_node_select_start_gate_contract.gd` -> `NODE_SELECT_START_GATE_CONTRACT_OK`.
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_battle_render_performance_contract.gd` -> `BATTLE_RENDER_PERFORMANCE_CONTRACT_OK`.
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/godot_contract_runner.gd` -> `GODOT_CONTRACTS_OK`.
- Harness proof:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .` -> `SOURCE_MAP_GATE_OK`.
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/runtime-size-gate.ps1 -Root .` failed before checking this request's new controller cap because pre-existing dirty `app-LTL/src/ui/MainViewRuntime.gd` is 2479 lines, above its frozen 2429-line cap.
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-15-main-controller-ownership-split.md` passed source-map, request-analysis, and test-size gates, then failed at runtime-size gate for the same pre-existing `MainViewRuntime.gd` cap breach.
- Current controller shape:
  - `app-LTL/src/MainControllerRuntime.gd` is deleted from active runtime ownership.
  - `app-LTL/src/MainController.gd` owns the scene-facing signal wrappers and top-level orchestration surface; it is now 393 lines and frozen under the 497-line cap in `docs/architectural-gates/runtime-size-gate.md`.
  - Extracted helpers are all below the strict source cap: `MainControllerRewardBackpackFlow.gd` 364 lines, `MainControllerCombatFlow.gd` 319 lines, `MainControllerRunFlow.gd` 440 lines, `MainControllerRenderFlow.gd` 139 lines, `MainControllerSupportFlow.gd` 157 lines, `MainControllerBootstrapFlow.gd` 131 lines, and `MainControllerDisplayText.gd` 37 lines.
  - `git diff --check` on the current request files reported no whitespace errors, only LF-to-CRLF normalization warnings.
- Follow-up verification:
  - `powershell.exe -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 --headless --path app-LTL --script res://tests/run_test_ui_read_models.gd` -> `UI_READ_MODEL_TESTS_OK`.
  - `powershell.exe -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 --headless --path app-LTL --script res://tests/godot_contract_runner.gd` -> `GODOT_CONTRACTS_OK`.
  - Focused runners passed: `MAIN_START_FLOW_CONTRACT_OK`, `NODE_SELECT_START_GATE_CONTRACT_OK`, `START_OPTION_CONTRACT_OK`, `REWARD_HANDOFF_CONTRACT_OK`, `SETTINGS_LANGUAGE_APPLY_CONTRACT_OK`, `CODEX_PAUSE_TIMING_CONTRACT_OK`, and `BATTLE_RENDER_PERFORMANCE_CONTRACT_OK`.
  - `source-map-gate.ps1 -Root .` -> `SOURCE_MAP_GATE_OK`.
  - `test-size-gate.ps1 -Root .` -> `TEST_SIZE_GATE_OK` with only legacy oversized-test warnings outside the new split suite.
  - `request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-15-main-controller-ownership-split.md -Mode pre-complete` -> `REQUEST_ANALYSIS_GATE_OK`.
  - `runtime-size-gate.ps1 -Root .` and `run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-15-main-controller-ownership-split.md` still stop at the unrelated `app-LTL/src/ui/MainViewRuntime.gd` cap breach: 2479 lines over its frozen 2429-line cap.

## Resolution Proof

- RED proof: focused UI read-model runner failed on missing controller helper scripts before implementation.
- Root-cause proof: `MainController.gd` no longer extends `res://src/MainControllerRuntime.gd`; the runtime implementation file was deleted; focused and full Godot contract runners load `res://src/MainController.gd` successfully.
- Workaround guard: new helper scripts are compiled by `godot_contract_runner.gd`, tests reject the old facade pattern, `docs/source-map.md` maps helper responsibilities, and runtime-size policy freezes the remaining `MainController.gd` orchestration debt instead of raising the old runtime cap.
