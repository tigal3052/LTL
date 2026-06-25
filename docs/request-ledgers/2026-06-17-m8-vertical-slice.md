# 2026-06-17 M8 Vertical Slice

## Request Summary

- Implement the approved M8 plan for one complete `ossuary_tortoise` Leviathan vertical slice.
- Keep M8 locked to character select -> VN/Leviathan select -> 3-stage node/combat/reward/backpack -> boss clear or defeat/retry.
- Extend the existing `app-LTL/src/Main.tscn`, page shell, and controller flow; do not create `VerticalSliceMain.tscn`.
- Add M8 headless runner, replay batch runner, telemetry export, same-seed/new-seed retry, starter equipment unlocks, ledgers, QA report, known issues, and evidence.

## Preserved Invariants

- `app-LTL/src/Main.tscn` remains the only main runtime scene for the vertical slice.
- Existing page-shell/controller separation remains intact; new runtime work is kept in helpers or existing narrow flow owners.
- M7 story scene and blocking combat/reward guide behavior remain side-effect-free and continue to protect only the intended input windows.
- M8 does not add new playable characters or expand content beyond the one-Leviathan proof.
- Existing user/worktree changes outside the M8 scope are not reverted.

## Mutable Scope

- `app-LTL/src/process/VerticalSliceRunner.gd`
- `app-LTL/src/tools/ReplayBatchRunner.gd`
- `app-LTL/src/tools/TelemetryExport.gd`
- `app-LTL/src/models/RunGrowthState.gd`
- `app-LTL/src/phases/CombatPhase.gd`
- `app-LTL/src/phases/RewardLootPhase.gd`
- `app-LTL/src/ui/CombatScenePreviewController.gd`
- `app-LTL/src/controllers/MainControllerRunFlow.gd`
- `app-LTL/src/controllers/MainControllerRenderFlow.gd`
- `app-LTL/src/controllers/MainControllerBootstrapFlow.gd`
- `app-LTL/src/MainController.gd`
- `app-LTL/src/ui/main_view/MainViewRuntimeState.gd`
- `app-LTL/src/ui/main_view/MainViewPageShellRuntime.gd`
- `app-LTL/src/ui/PageSceneModelBuilder.gd`
- `app-LTL/src/ui/read_models/FailureReadModel.gd`
- `app-LTL/src/scenes/pages/DefeatPage.gd`
- `app-LTL/src/scenes/pages/DefeatPage.tscn`
- `app-LTL/src/vocabulary/ReleaseContentVocab.gd`
- `app-LTL/src/data/i18n/text-ko.json`
- `app-LTL/src/data/i18n/text-en.json`
- `app-LTL/tests/test_vertical_slice_flow.gd`
- `app-LTL/tests/test_vertical_slice_replay_batch.gd`
- `app-LTL/tests/run_reward_handoff_contract.gd`
- `app-LTL/tests/run_m8_vertical_slice_contract.gd`
- `app-LTL/tests/run_m8_telemetry_export.gd`
- `app-LTL/tests/run_m8_visual_capture.gd`
- `app-LTL/tests/godot_contract_runner.gd`
- `LTL-harness/docs/11_exec-plans/02_completed/13_M7_narrative_integration_completed.md`
- `LTL-harness/docs/qa/m8_vertical_slice_report.md`
- `LTL-harness/docs/qa/m8_known_issues.md`
- `docs/evidence/m8-vertical-slice-2026-06-17/README.md`
- `docs/evidence/m8-vertical-slice-2026-06-17/screenshots/`
- `docs/request-ledgers/2026-06-17-m8-vertical-slice.md`
- `docs/artifact-ledgers/2026-06-17-m8-vertical-slice.md`
- `docs/source-map.md`
- `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-17.md`
- `docs/codex-worklog/history_LootingTheLeviathan_2026-06-17.md`
- `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-17.md`

## Source Map Findings

- `app-LTL/src/process/HeadlessMiniRun.gd` owns deterministic phase progression and is the correct headless base for the M8 runner.
- `app-LTL/src/process/ReplayProcess.gd` and `app-LTL/src/tools/FormalReplayRunner.gd` define the existing replay/batch shape that M8 should mirror without replacing.
- `app-LTL/src/controllers/MainControllerRunFlow.gd` owns run start/reset/loadout/selection flow, so defeat retry seed handling belongs there.
- `app-LTL/src/controllers/MainControllerRenderFlow.gd` owns run-complete scene decoration and controller-owned progress sync, so growth unlock sync belongs there.
- `app-LTL/src/scenes/pages/DefeatPage.gd` and `app-LTL/src/ui/read_models/FailureReadModel.gd` own the failure surface and retry copy/options.
- `app-LTL/src/vocabulary/ReleaseContentVocab.gd` owns release table validation, including the `stageCnt/runCnt` and `stageCount/runCount` alias cleanup.

## Root Cause Review

- Observed symptom: M8 could not be verified as a complete one-Leviathan slice because there was no M8-specific headless runner/export path, defeat exposed only one return action, and result unlocks were not applied to growth state.
- Evidence: the RED `tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/godot_contract_runner.gd` failed on missing `res://src/process/VerticalSliceRunner.gd`, `res://src/tools/ReplayBatchRunner.gd`, and `res://src/tools/TelemetryExport.gd`.
- Root cause target: `app-LTL/src/process/VerticalSliceRunner.gd`
- Rejected workaround: creating a separate `VerticalSliceMain.tscn`, broadening content tables, or treating the existing one-button defeat return as M8 retry support.
- Chosen fix: add a thin M8 runner/export API around the existing headless runtime, wire defeat retry choices into the existing page shell/controller flow, and apply M8 result unlocks through growth state at run-complete boundaries.

## Transition Safety Review

- Touched transition id `meta.start_flow`: defeat page retry returns through the existing Main scene start flow.
  - entry owner: `app-LTL/src/scenes/pages/DefeatPage.gd`
  - exit owner: `app-LTL/src/controllers/MainControllerRunFlow.gd`
  - shared handoff risks: same-seed retry could accidentally mint a new seed, new-seed retry could accidentally reuse the failed seed, or either path could bypass `node_select`.
  - runner: `app-LTL/tests/run_m8_vertical_slice_contract.gd`; marker: `M8_VERTICAL_SLICE_CONTRACT_OK`.
- Touched transition id `reward.handoff`: final reward claim reaches `run_complete clear` and applies M8 starter equipment unlocks.
  - entry owner: `app-LTL/src/phases/RewardLootPhase.gd`
  - exit owner: `app-LTL/src/controllers/MainControllerRenderFlow.gd`
  - shared handoff risks: unlocks could be skipped, applied repeatedly during non-terminal renders, or overwrite existing growth state.
  - runner: `app-LTL/tests/run_reward_handoff_contract.gd`; marker: `REWARD_HANDOFF_CONTRACT_OK`.
  - supplemental M8 proof: `app-LTL/tests/test_vertical_slice_flow.gd` runs inside `godot_contract_runner.gd` with marker `GODOT_CONTRACTS_OK`.

## Feature Unit Lifecycle Plan

- Design stage: M8 is explicitly scoped to `ossuary_tortoise`, three stages, one run, final `boss_spine`, internal QA 3-run evidence, and no separate vertical-slice scene.
- Implementation stage: headless verification, telemetry export, retry UI, and unlock policy are split across runner/tool/read-model/page/controller/phase owners instead of adding behavior to a monolithic controller.
- Maintenance stage: new M8 scripts and tests are listed in `godot_contract_runner.gd` and `docs/source-map.md` so future gates catch drift.
- Capsule boundary: `VerticalSliceRunner` owns M8 fixture orchestration and telemetry projection; reducers keep phase transitions; page shell owns visible retry signals.
- Size trigger: if M8 runtime wiring grows beyond thin helper calls, further work must extract into additional leaf helpers rather than expanding `MainController.gd`.

## Runtime Performance Review

- Hot path: `app-LTL/src/phases/CombatPhase.gd` combat resolution and failure transition.
- Hot path: `app-LTL/src/phases/RewardLootPhase.gd` final reward claim and clear transition.
- Hot path: `app-LTL/src/controllers/MainControllerRunFlow.gd` run start and defeat retry restart.
- Hot path: `app-LTL/src/controllers/MainControllerRenderFlow.gd` render-scene run-complete sync and narrative projection.
- Risk: syncing growth or retry state on every render could overwrite progression during normal gameplay or add repeated work in combat renders.
- Performance proof: `app-LTL/tests/run_m8_vertical_slice_contract.gd`
- Budget: result unlocks run only on terminal transitions, growth sync is limited to `run_complete`, retry restarts rebuild a single preview controller, and no per-frame node traversal or scene rebuild loop is added.

## Execution Responsibility Units

- Owner: `app-LTL/src/process/VerticalSliceRunner.gd`
  - Unit: fixed M8 fixture, clear/defeat/retry headless orchestration, and telemetry category projection.
  - Focused proof: `app-LTL/tests/test_vertical_slice_flow.gd`
- Owner: `app-LTL/src/tools/ReplayBatchRunner.gd`
  - Unit: three-seed M8 batch execution and manifest aggregation.
  - Focused proof: `app-LTL/tests/test_vertical_slice_replay_batch.gd`
- Owner: `app-LTL/src/tools/TelemetryExport.gd`
  - Unit: in-memory and disk session manifest/export schema.
  - Focused proof: `app-LTL/tests/run_m8_telemetry_export.gd`
- Owner: `app-LTL/src/scenes/pages/DefeatPage.gd`
  - Unit: same-seed and new-seed retry button signals.
  - Focused proof: `app-LTL/tests/run_m8_vertical_slice_contract.gd`

## Refactor/Delete Disposition

- No active runtime scene was deleted or replaced.
- No prototype files were edited.
- The existing `DefeatPage` button surface was extended with a second retry button rather than introducing a new page or modal.
- The release content validator was narrowed to alias compatibility instead of changing Leviathan data shape.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/godot_contract_runner.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_m8_vertical_slice_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_m8_telemetry_export.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/milestone-gate.ps1 -TargetPlan 14_M8_vertical_slice.md -Root .`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-17-m8-vertical-slice.md`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-17-m8-vertical-slice.md -ArtifactLedger docs/artifact-ledgers/2026-06-17-m8-vertical-slice.md`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .`.
- Run `git diff --check`.

## Verification Notes

- Baseline before M8 edits: `godot_contract_runner.gd` passed with `GODOT_CONTRACTS_OK`.
- RED proof: after adding M8 tests to the runner, `godot_contract_runner.gd` failed on missing `VerticalSliceRunner.gd`, `ReplayBatchRunner.gd`, and `TelemetryExport.gd`.
- GREEN proof: `godot_contract_runner.gd` passed with `GODOT_CONTRACTS_OK` after M8 runner/export/retry/unlock implementation.
- GREEN proof: `run_m8_vertical_slice_contract.gd` passed with `M8_VERTICAL_SLICE_CONTRACT_OK`.
- Godot headless shutdown still emits known RID/resource leak warnings after successful markers.

## Resolution Proof

- RED proof: `godot_contract_runner.gd` failed before production implementation because the M8 public runner/export scripts were missing.
- Root-cause proof: the same full runner now compiles and executes the M8 flow/replay telemetry tests with `GODOT_CONTRACTS_OK`, and the focused UI retry runner passes with `M8_VERTICAL_SLICE_CONTRACT_OK`.
- Workaround guard: no `VerticalSliceMain.tscn` exists or is referenced; the runner and retry flow use the existing `Main.tscn`, page shell, `HeadlessMiniRun`, and controller helper boundaries.

## Artifact Ledger

- `docs/artifact-ledgers/2026-06-17-m8-vertical-slice.md` will be generated by `tools/run-ltl-quality-gate.ps1`.
- `docs/evidence/m8-vertical-slice-2026-06-17/` stores M8 session telemetry evidence and the evidence README.
- `LTL-harness/docs/qa/m8_vertical_slice_report.md` records QA status and verification commands.
- `LTL-harness/docs/qa/m8_known_issues.md` records known issues and unverified gaps.
