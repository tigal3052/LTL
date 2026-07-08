# 2026-06-29 CORE-001 Onboarding Story-Scene Baseline

## Request Summary

- Fix the CORE-001 onboarding baseline so the intro onboarding is owned by a story scene instead of the first node-select narrative toast.
- Create or reuse a temporary intro story scene that runs before character selection, returns to `character_select`, and only appears once on the first onboarding pass.
- Keep the rest of the alpha core loop unchanged: after the intro story, character select still hands off to leviathan select, node select, combat, reward, and return flow without adding new gameplay systems.

## Preserved Invariants

- The onboarding intro remains side-effect-free content/routing work; it does not change combat, reward, growth, or reducer semantics.
- `character_select`, `leviathan_select`, `node_select`, combat, reward handoff, and vertical-slice completion remain the accepted alpha loop after onboarding completes.
- Intro shown-once state remains tracked in story-scene history instead of leaking into unrelated run-progress flags.
- Existing dirty worktree changes outside the onboarding owner alignment scope are not reverted.

## Mutable Scope

- `app-LTL/src/data/story-scenes.json`
- `app-LTL/src/data/narrative-beats.json`
- `app-LTL/src/vocabulary/story/SelectStoryScene.gd`
- `app-LTL/src/controllers/MainControllerBootstrapFlow.gd`
- `app-LTL/src/controllers/MainControllerRunFlow.gd`
- `app-LTL/tests/test_story_scene_contract.gd`
- `app-LTL/tests/test_narrative_contract.gd`
- `app-LTL/tests/run_main_start_flow_contract.gd`
- `app-LTL/tests/run_node_select_start_gate_contract.gd`
- `app-LTL/tests/run_m8_vertical_slice_contract.gd`
- `app-LTL/tests/run_reward_handoff_contract.gd`
- `docs/source-map.md`
- `docs/request-ledgers/2026-06-29-core-001-onboarding-story-scene-baseline.md`

## Source Map Findings

- `docs/source-map.md` is the live formal map and was refreshed as part of this onboarding-owner alignment so the touched controller, vocabulary, test, and request-ledger paths stay in tracked source-map scope.
- `app-LTL/src/controllers/MainControllerBootstrapFlow.gd` is the startup/bootstrap handoff surface, which is the narrow place to open first-run onboarding before normal page routing continues.
- `app-LTL/src/controllers/MainControllerRunFlow.gd` is the reset/page-transition owner for the main flow, so reset-time onboarding re-entry belongs there rather than in downstream node-select logic.
- `app-LTL/src/vocabulary/story/SelectStoryScene.gd` is the story-scene trigger selector, which is the correct place to move intro ownership from post-character-confirm to pre-character-select.

## Root Cause Review

- Observed symptom: baseline audit showed onboarding expectations were split, with `run_node_select_start_gate_contract.gd` failing around first-entry intro ownership while the other core-loop contracts were already green.
- Evidence: the failing assertions targeted first node-select intro surface/input behavior, while story-scene data and runtime hooks already existed elsewhere in the codebase.
- Root cause target: `app-LTL/src/controllers/MainControllerBootstrapFlow.gd`
- Rejected workaround: add another special-case node-select toast or duplicate intro copy directly into page-specific UI state.
- Chosen fix: make `story_scene` the single onboarding owner, trigger the intro before `character_select`, return to `character_select`, and leave downstream node-select/runtime flow unchanged.

## Transition Safety Review

- Touched transition: `meta.start_flow`
- Entry owner: `app-LTL/src/controllers/MainControllerBootstrapFlow.gd` now opens the intro `story_scene` before the first `character_select` render, and `app-LTL/src/controllers/MainControllerRunFlow.gd` mirrors that behavior on reset.
- Exit owner: `story_scene` continue/skip returns to `character_select`, then `app-LTL/src/controllers/MainControllerRunFlow.gd` continues the existing handoff to `leviathan_select` and later `node_select`.
- Risk: if intro ownership stays split between story-scene routing and node-select narrative selection, the first-run onboarding can disappear, repeat, or block the wrong surface.
- Runner: `app-LTL/tests/run_main_start_flow_contract.gd`
- Marker: `MAIN_START_FLOW_CONTRACT_OK`
- Guard: `app-LTL/tests/run_node_select_start_gate_contract.gd` proves the player still reaches node select after the new `story_scene -> character_select -> leviathan_select` onboarding path.
- No transition impact: reward handoff, vertical-slice completion, and post-node-select combat/reward loops keep their existing owners; this change only moves the intro onboarding entry point.

## Feature Unit Lifecycle Plan

- Design stage: keep onboarding ownership explicit in content/routing contracts so story-scene entry, return page, and shown-once policy are defined before editing runtime flow.
- Implementation stage: confine the behavior change to story-scene content, story selection, bootstrap/reset handoff, and focused contract expectations instead of spreading intro logic through reducers or gameplay phases.
- Maintenance stage: any future onboarding change must refresh `docs/source-map.md` and rerun the acceptance bundle so story ownership drift is caught before closeout.
- Capsule boundary: story-scene ownership lives in story data/history/selection plus bootstrap/reset routing, while node-select narrative beats remain non-owner presentation only.
- Size trigger: if onboarding routing grows beyond bootstrap/reset handoff plus focused selectors, extract a dedicated onboarding-flow helper before adding more page-branch logic.

## Refactor/Delete Disposition

- Keep existing core-loop controllers and tests; adjust only the onboarding owner, return page, and focused contract expectations.
- Do not delete the intro narrative data; repurpose it so node-select no longer owns first-run onboarding.
- Do not revert unrelated worktree changes already present outside the onboarding alignment scope.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_start_flow_contract.gd -Quit`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_node_select_start_gate_contract.gd -Quit`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_m8_vertical_slice_contract.gd -Quit`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_reward_handoff_contract.gd -Quit`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_vertical_slice_flow_contract.gd -Quit`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-29-core-001-onboarding-story-scene-baseline.md`.

## Verification Notes

- `LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh` passed with `SOURCE_MAP_REFRESH_OK: docs/source-map.md` and `SOURCE_MAP_GATE_OK`.
- `LTL-harness/tools/source-map-gate.ps1 -Root .` passed with `SOURCE_MAP_GATE_OK` after the onboarding-owner alignment and follow-up layout-audit sync.
- `LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-29-core-001-onboarding-story-scene-baseline.md -Mode pre-complete` passed with `REQUEST_ANALYSIS_GATE_OK`.
- `LTL-harness/tools/transition-safety-gate.ps1 -Ledger docs/request-ledgers/2026-06-29-core-001-onboarding-story-scene-baseline.md` passed with `TRANSITION_SAFETY_GATE_OK` and re-ran the `meta.start_flow` proof.
- `tests/godot_contract_runner.gd` passed with `GODOT_CONTRACTS_OK` after the onboarding-owner alignment.
- `tests/run_main_start_flow_contract.gd` exited 0 and emitted `story_scene_started` telemetry with `return_page_id` set to `character_select`.
- `tests/run_node_select_start_gate_contract.gd` exited 0 after traversing the new intro path and no longer depended on node-select owning the onboarding intro.
- `tests/run_m8_vertical_slice_contract.gd`, `tests/run_reward_handoff_contract.gd`, and `tests/run_vertical_slice_flow_contract.gd` all exited 0 under the same onboarding baseline.
- `LTL-harness/tools/page-contract-gate.ps1 -Root .` passed with `PAGE_CONTRACT_GATE_OK` after `run_main_layout_audit_contract.gd` was aligned to advance the intro story before character-select layout assertions.
- `tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-29-core-001-onboarding-story-scene-baseline.md` passed with `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`.
- Godot still prints known shutdown leak/resource warnings on exit, and the compile-check path still reports legacy oversized-test warnings, but the gate markers and exit codes stayed green.

## Resolution Proof

- RED proof: baseline audit isolated the remaining CORE-001 failure to onboarding ownership around first node-select entry while the rest of the acceptance bundle was already green.
- Root-cause proof: after moving intro ownership into the story-scene bootstrap path, the start-flow and node-select gate runners both emitted story-scene telemetry with `return_page_id` set to `character_select` and completed successfully.
- Workaround guard: intro ownership now lives in story-scene selection/bootstrap-reset routing instead of a duplicated node-select toast owner, so future regressions show up in the story-scene and start-flow contracts.

## Artifact Ledger

- No separate artifact ledger was created for this CORE-001 step; the proof is carried by the request ledger, refreshed source map, and Godot contract outputs recorded above.
