# 2026-06-16 M7 Narrative Integration

## Request Summary

- Commit and push the current working tree first, then finish M6 closure handling and M7 narrative integration based on `docs/superpowers/plans/2026-06-13-m7-narrative-integration-replan.ko.md`.
- Keep M7 narrative behavior side-effect-free for combat, reward, node selection, and reducer rules.

## Preserved Invariants

- Existing user and checkpoint changes are not reverted.
- Combat, reward, node selection, inventory, and phase reducer rules keep their current behavior.
- Narrative shown-once progress is stored separately from clear and run progress fields.
- Reward ceremony presentation remains isolated from narrative toast presentation.

## Mutable Scope

- `app-LTL/src/data/narrative-beats.json`
- `app-LTL/src/models/NarrativeBeat.gd`
- `app-LTL/src/models/NarrativeHistory.gd`
- `app-LTL/src/vocabulary/narrative/SelectNarrativeBeat.gd`
- `app-LTL/src/vocabulary/narrative/MarkNarrativeSeen.gd`
- `app-LTL/src/vocabulary/narrative/BuildNarrativeTelemetry.gd`
- `app-LTL/src/ui/read_models/NarrativeReadModel.gd`
- `app-LTL/src/scenes/narrative/NarrativeToast.gd`
- `app-LTL/src/controllers/MainControllerRenderFlow.gd`
- `app-LTL/src/controllers/MainControllerBootstrapFlow.gd`
- `app-LTL/src/MainController.gd`
- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/main_view/MainViewRuntimeState.gd`
- `app-LTL/src/ui/main_view/MainViewChromeRuntime.gd`
- `app-LTL/src/ui/main_view/MainViewLifecycleRuntime.gd`
- `app-LTL/src/ui/SceneReadModel.gd`
- `app-LTL/src/ui/CombatScenePreviewController.gd`
- `app-LTL/src/ui/PageSceneModelBuilder.gd`
- `app-LTL/tests/test_release_content_contract.gd`
- `app-LTL/tests/test_narrative_contract.gd`
- `app-LTL/tests/godot_contract_runner.gd`
- `app-LTL/tests/run_node_select_start_gate_contract.gd`
- `docs/m7-manual-signoff-checklist.ko.md`
- `docs/source-map.md`

## Source Map Findings

- `docs/source-map.md` maps `app-LTL/src/controllers/MainControllerRenderFlow.gd` as the scene decoration and render handoff owner, which is the narrow place to attach narrative UI projection.
- `docs/source-map.md` maps `app-LTL/src/ui/MainViewRuntime.gd` and `app-LTL/src/ui/main_view/MainViewChromeRuntime.gd` as view facade and chrome helper surfaces for overlays.
- `docs/source-map.md` maps `app-LTL/src/vocabulary/ReleaseContentVocab.gd` as the release content facade, so narrative beat content validation belongs there.

## Root Cause Review

- Observed symptom: M7 narrative content existed only as release table data and did not reach runtime screens as a shown-once non-blocking beat.
- Evidence: the M7 replan requires side-effect-free beat selection, progress history, telemetry, and node-select toast behavior; the RED `run_node_select_start_gate_contract.gd` assertion failed before the toast implementation.
- Root cause target: `app-LTL/src/controllers/MainControllerRenderFlow.gd`
- Rejected workaround: hard-code narrative text directly in page scenes or mutate phase reducers to trigger UI copy.
- Chosen fix: add pure narrative model and vocabulary helpers, then project selected beats in render flow and display them through an input-transparent toast overlay.

## Transition Safety Review

- Touched transition: `node_select` first-entry render now projects an intro narrative toast.
- No reducer transition changed: combat start, reward claim, run complete, and return-to-node-select still use existing controller and phase flows.
- No transition impact: M7 adds narrative projection after scene decoration and does not alter phase entry or exit ownership.
- Guard: `run_node_select_start_gate_contract.gd` verifies node selection, menu round trips, and boss-stage start gating still work after the narrative toast is present.

## Feature Unit Lifecycle Plan

- Design stage: the dated M7 replan fixes beat ids, metadata, side-effect boundaries, and verification expectations before implementation.
- Implementation stage: pure narrative data and vocabulary helpers stay separate from runtime view wiring and toast rendering.
- Maintenance stage: source-map entries and Godot runner required-script lists keep new M7 files visible to future gate checks.
- Capsule boundary: narrative selection, seen history, read model, telemetry payloads, and toast rendering form the M7 narrative capsule.
- Size trigger: if runtime wiring grows beyond thin facade calls or helper handoff, extract additional narrative runtime helpers before adding more screen logic.

## Runtime Performance Review

- Hot path: `app-LTL/src/ui/MainViewRuntime.gd` only forwards narrative toast creation and rendering to `MainViewChromeRuntime.gd`.
- Risk: repeated scene renders could allocate toast controls or hide and show the overlay every frame.
- Performance proof: `app-LTL/tests/run_node_select_start_gate_contract.gd`
- Budget: create one toast control per main view and reuse it; no per-frame child tree rebuild in narrative render.

## Refactor/Delete Disposition

- No existing runtime files were deleted for M7.
- New narrative helpers were added instead of folding selection or telemetry into existing combat/reward reducers.
- Existing M6 completion docs remain the source of truth for accepted M6 closure and follow-up UX sign-off debt.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_node_select_start_gate_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/godot_contract_runner.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-16-m7-narrative-integration.md`.

## Verification Notes

- `source-map-gate.ps1 -Root .` passed with `SOURCE_MAP_GATE_OK`.
- `run_node_select_start_gate_contract.gd` passed with `NODE_SELECT_START_GATE_CONTRACT_OK` and emitted narrative selected, shown, and history-updated telemetry.
- `godot_contract_runner.gd` passed with `GODOT_CONTRACTS_OK`.
- `tools/run-compile-check.ps1` initially failed on the default older ledger, so this request-specific ledger is used for the final compile check.

## Resolution Proof

- RED proof: `run_node_select_start_gate_contract.gd` failed before runtime toast wiring because `narrative_toast` was missing or hidden on first node-select entry.
- Root-cause proof: after render-flow selection and toast wiring, `run_node_select_start_gate_contract.gd` passed and telemetry showed `intro_contract` selection, display, and history update.
- Workaround guard: narrative selection and history updates are implemented in `SelectNarrativeBeat.gd`, `MarkNarrativeSeen.gd`, and `NarrativeReadModel.gd`, not in combat, reward, node, or phase reducers.

## Artifact Ledger

- No separate artifact ledger is required for this M7 code path; generated evidence is documented in `docs/m7-manual-signoff-checklist.ko.md` and source-map entries.
