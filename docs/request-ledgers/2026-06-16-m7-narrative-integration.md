# 2026-06-16 M7 Narrative Integration

## Request Summary

- Commit and push the current working tree first, then finish M6 closure handling and M7 narrative integration based on `docs/superpowers/plans/2026-06-13-m7-narrative-integration-replan.ko.md`.
- Keep M7 narrative behavior side-effect-free for combat, reward, node selection, and reducer rules.
- Follow-up: the intro narrative must not read as an indefinite full-screen caption; it needs a central/lower dialogue area, an upper visual area, a visible continue prompt/icon, and click/any-key dismissal.
- Follow-up: combat and reward guide narratives must appear before the player can act, block only those gameplay interactions until dismissed, and English Apply & Close must not freeze the UI.

## Preserved Invariants

- Existing user and checkpoint changes are not reverted.
- Combat, reward, node selection, inventory, and phase reducer rules keep their current behavior except for guide-narrative input gating before first combat/reward interaction.
- Narrative shown-once progress is stored separately from clear and run progress fields.
- Reward ceremony presentation remains isolated from narrative toast presentation.
- Character select may hand off once to `story_scene`; after story completion/skip, leviathan/node routing remains unchanged.

## Mutable Scope

- `app-LTL/src/data/narrative-beats.json`
- `app-LTL/src/data/story-scenes.json`
- `app-LTL/src/data/i18n/text-en.json`
- `app-LTL/src/data/i18n/text-ko.json`
- `app-LTL/src/models/NarrativeBeat.gd`
- `app-LTL/src/models/NarrativeHistory.gd`
- `app-LTL/src/models/StoryScene.gd`
- `app-LTL/src/models/StoryHistory.gd`
- `app-LTL/src/vocabulary/narrative/SelectNarrativeBeat.gd`
- `app-LTL/src/vocabulary/narrative/MarkNarrativeSeen.gd`
- `app-LTL/src/vocabulary/narrative/BuildNarrativeTelemetry.gd`
- `app-LTL/src/vocabulary/story/SelectStoryScene.gd`
- `app-LTL/src/vocabulary/story/BuildStoryTelemetry.gd`
- `app-LTL/src/ui/read_models/NarrativeReadModel.gd`
- `app-LTL/src/ui/read_models/StorySceneReadModel.gd`
- `app-LTL/src/scenes/narrative/NarrativeToast.gd`
- `app-LTL/src/scenes/pages/StoryScenePage.gd`
- `app-LTL/src/scenes/pages/StoryScenePage.tscn`
- `app-LTL/src/controllers/MainControllerRenderFlow.gd`
- `app-LTL/src/controllers/MainControllerBootstrapFlow.gd`
- `app-LTL/src/controllers/MainControllerRewardBackpackFlow.gd`
- `app-LTL/src/controllers/MainControllerRunFlow.gd`
- `app-LTL/src/MainController.gd`
- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/main_view/MainViewRuntimeState.gd`
- `app-LTL/src/ui/main_view/MainViewChromeRuntime.gd`
- `app-LTL/src/ui/main_view/MainViewLifecycleRuntime.gd`
- `app-LTL/src/ui/main_view/MainViewSceneRuntime.gd`
- `app-LTL/src/ui/main_view/MainViewPageShellRuntime.gd`
- `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
- `app-LTL/src/ui/SceneReadModel.gd`
- `app-LTL/src/ui/CombatScenePreviewController.gd`
- `app-LTL/src/ui/PageSceneModelBuilder.gd`
- `app-LTL/tests/test_release_content_contract.gd`
- `app-LTL/tests/test_narrative_contract.gd`
- `app-LTL/tests/test_story_scene_contract.gd`
- `app-LTL/tests/godot_contract_runner.gd`
- `app-LTL/tests/run_main_start_flow_contract.gd`
- `app-LTL/tests/run_main_layout_audit_contract.gd`
- `app-LTL/tests/run_node_select_start_gate_contract.gd`
- `app-LTL/tests/run_m7_narrative_gating_contract.gd`
- `app-LTL/tests/run_settings_language_apply_contract.gd`
- `app-LTL/tests/test_reward_claim_board_contract.gd`
- `docs/m7-manual-signoff-checklist.ko.md`
- `docs/source-map.md`

## Source Map Findings

- `docs/source-map.md` maps `app-LTL/src/controllers/MainControllerRenderFlow.gd` as the scene decoration and render handoff owner, which is the narrow place to attach narrative UI projection.
- `docs/source-map.md` maps `app-LTL/src/ui/MainViewRuntime.gd` and `app-LTL/src/ui/main_view/MainViewChromeRuntime.gd` as view facade and chrome helper surfaces for overlays.
- `docs/source-map.md` maps `app-LTL/src/vocabulary/ReleaseContentVocab.gd` as the release content facade, so narrative beat content validation belongs there.
- `docs/source-map.md` maps `app-LTL/src/ui/main_view/MainViewPageShellRuntime.gd` as page-scene registration/routing, so the full VN page belongs in that page shell registry.
- `docs/source-map.md` maps `app-LTL/src/scenes/narrative/NarrativeToast.gd` as the toast overlay renderer, so in-run character/visual toast presentation belongs there rather than in reducers.

## Root Cause Review

- Observed symptom: M7 narrative content existed only as release table data and did not reach runtime screens as a shown-once non-blocking beat.
- Follow-up symptom: once the intro beat reached runtime, it looked like a caption without an obvious next/continue affordance and did not provide a story-panel layout.
- Follow-up symptom: combat guidance appeared only after the first terrain hit, reward guidance appeared after reward handling had already begun, and applying English from settings could leave the UI stuck.
- Follow-up symptom: regular story needs more than a one-line toast; it needs a full VN-style page while in-run guidance remains toast-based.
- Evidence: the M7 replan requires side-effect-free beat selection, progress history, telemetry, and node-select toast behavior; the RED `run_node_select_start_gate_contract.gd` assertion failed before the toast implementation.
- Follow-up evidence: the RED story-surface extension of `run_node_select_start_gate_contract.gd` failed because the runtime narrative node lacked `VisualArea`, `DialogPanel`, `ContinuePrompt`, `ContinueIcon`, and click/continue input handling.
- Follow-up gating evidence: the RED `run_m7_narrative_gating_contract.gd` failed because combat was not paused before the first hit and reward drag started while reward guidance was visible or stale.
- Root cause target: `app-LTL/src/controllers/MainControllerRenderFlow.gd`
- Root cause target: `app-LTL/src/ui/main_view/MainViewPageShellRuntime.gd`
- Rejected workaround: hard-code narrative text directly in page scenes or mutate phase reducers to trigger UI copy.
- Chosen fix: keep narrative toast beats as a pure in-run projection, add separate story scene data/history/read-model/page routing for regular VN story, and use explicit `blocksInput` metadata only for short guide-gating toasts.

## Transition Safety Review

- Touched transition: `node_select` first-entry render now projects an intro narrative toast.
- Touched transition: `character_select` continue can route once into `story_scene`, then returns to `leviathan_select` after continue/skip.
- No reducer transition changed: combat start, reward claim, run complete, and return-to-node-select still use existing controller and phase flows.
- No transition impact: M7 adds narrative projection after scene decoration and does not alter phase entry or exit ownership.
- Guard: `run_node_select_start_gate_contract.gd` verifies the intro story surface can be dismissed, then node selection, menu round trips, and boss-stage start gating still work.
- Guard: `run_m7_narrative_gating_contract.gd` verifies combat/reward blocking guide narratives and English Apply & Close interactivity.

## Feature Unit Lifecycle Plan

- Design stage: the dated M7 replan fixes beat ids, metadata, side-effect boundaries, and verification expectations before implementation.
- Implementation stage: pure narrative/story data and vocabulary helpers stay separate from runtime page routing and toast rendering.
- Maintenance stage: source-map entries and Godot runner required-script lists keep new M7 files visible to future gate checks.
- Capsule boundary: narrative toast selection plus story scene selection keep separate histories, read models, telemetry payloads, and presentation surfaces.
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
- Run `git diff --check`.

## Verification Notes

- `source-map-gate.ps1 -Root .` passed with `SOURCE_MAP_GATE_OK`.
- `run_node_select_start_gate_contract.gd` passed with `NODE_SELECT_START_GATE_CONTRACT_OK` and emitted narrative selected, shown, and history-updated telemetry.
- Follow-up RED: `run_node_select_start_gate_contract.gd` failed before the story-surface update because the intro narrative lacked upper visual area, lower dialogue area, continue prompt/icon, and click handling.
- Follow-up GREEN: `run_node_select_start_gate_contract.gd` passed after the story surface, bounded layout, and dismiss affordance were added. The focused runner still prints a deferred backpack pin cleanup warning after quit.
- Visual proof: `docs/evidence/m7-narrative-story-surface-2026-06-16/node_select_1440x900.png` shows the upper visual area, lower dialogue area, Korean continue prompt, and continue icon on node select.
- `godot_contract_runner.gd` passed with `GODOT_CONTRACTS_OK`.
- `tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-16-m7-narrative-integration.md` passed with `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`. Legacy oversized-test warnings and Godot shutdown resource-leak warnings remain in the output.
- `git diff --check` passed with line-ending conversion warnings only.
- Follow-up GREEN: `run_m7_narrative_gating_contract.gd` passed after combat and reward guide beats were moved to entry-time triggers, `blocksInput` gating was wired through render/controller state, and English language application was deferred out of the OptionButton event stack.

## Resolution Proof

- RED proof: `run_node_select_start_gate_contract.gd` failed before runtime toast wiring because `narrative_toast` was missing or hidden on first node-select entry.
- Root-cause proof: after render-flow selection and toast wiring, `run_node_select_start_gate_contract.gd` passed and telemetry showed `intro_contract` selection, display, and history update.
- Workaround guard: narrative selection and history updates are implemented in `SelectNarrativeBeat.gd`, `MarkNarrativeSeen.gd`, and `NarrativeReadModel.gd`, not in combat, reward, node, or phase reducers.

## Artifact Ledger

- No separate artifact ledger is required for this M7 code path; generated evidence is documented in `docs/m7-manual-signoff-checklist.ko.md` and source-map entries.
