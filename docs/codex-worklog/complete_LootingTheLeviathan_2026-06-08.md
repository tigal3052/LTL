# Codex Worklog Completion

Workspace: LootingTheLeviathan
Date: 2026-06-08

## Completion Summary

Completed the requested defeat-atlas split for the provided source image and placed the generated assets under `app-LTL/resources/charactor/defeat/`.

## Actual Outputs

- New asset directory:
  - `app-LTL/resources/charactor/defeat/`
- Split frame exports:
  - `defeat_01.png` through `defeat_35.png`
- Companion sheet preview:
  - `app-LTL/resources/charactor/defeat/defeat_sheet.png`
- Updated worklog notes:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-08.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-08.md`

## Changes From Plan

The implementation stayed inside the requested scope. One small practical addition was the companion `defeat_sheet.png` so the split order can be visually checked at a glance before wiring the frames into runtime animation.

## Verification Results

- Passed: export command generated `35` frames in the target folder.
- Passed: dimension checks confirmed `defeat_01.png` and `defeat_35.png` are both `268x206`.
- Passed: combined sheet dimensions resolved to `1876x1030`, which matches `7` columns by `5` rows at `268x206` per frame.
- Passed: near-white pixel scan shows only `3` remaining pixels across the whole output set, all inside the artwork (`defeat_17.png` and `defeat_20.png`) rather than along frame borders.
- Passed: visual inspection of `defeat_sheet.png` confirms the white separator gutters are removed and the row-major animation order is preserved.

## Blockers Or Unverified Areas

- The new frames were generated as asset files only; no Godot animation resource or scene wiring was added in this task.
- The exported frames keep the original dark background content from the provided `*_bg.png` source rather than attempting aggressive background-to-transparency reconstruction.

## Reward Claim Runtime Completion Summary

Completed the requested reward-claim runtime implementation so the live `reward_loot` tray-review screen now follows the approved M6 wireframe instead of the old reward list strip.

## Reward Claim Actual Outputs

- Reworked reward tray scene structure in:
  - `app-LTL/src/Main.tscn`
- Rewired reward tray runtime rendering in:
  - `app-LTL/src/MainControllerRuntime.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
  - `app-LTL/src/ui/read_models/RewardReadModel.gd`
- Added board-specific localized copy in:
  - `app-LTL/src/data/i18n/text-en.json`
  - `app-LTL/src/data/i18n/text-ko.json`
- Updated focused regression coverage in:
  - `app-LTL/tests/test_ui_read_models.gd`
  - `app-LTL/tests/test_start_option_contract.gd`
  - `app-LTL/tests/run_main_layout_audit_contract.gd`
  - `app-LTL/tests/run_main_viewport_probe.gd`

## Reward Claim Changes From Plan

The implementation stayed inside the approved mockup scope. One intentional adjustment was the live mode-pill copy: it now emphasizes inspect-and-place wording rather than promising drag-only placement, because the runtime interaction still uses the existing click-to-pick and place flow.

## Reward Claim Verification Results

- Passed: `tests/run_reward_ceremony_contract.gd`
- Passed: `tests/run_start_option_contract.gd`
- Checked: `tests/run_main_layout_audit_contract.gd` exited with success status after the refactor.
- Observed: the layout audit still prints Godot shutdown leak warnings (`ObjectDB` and dummy texture/resource leak messages), but it did not report reward-board assertion failures in this pass.

## Reward Claim Blockers Or Unverified Areas

- The reward-board verification here is contract-focused; no in-app visual capture was taken in this turn.
- The live reward interaction wording is aligned to the current click-to-place runtime, not a new drag interaction system.

## Reward Claim Bugfix Addendum

After the initial reward-board refactor, the live runtime still crashed because the scene tree in `app-LTL/src/Main.tscn` had not actually been replaced from the legacy reward strip to the new `RewardBoard` hierarchy. This follow-up fix aligned the scene with the already-updated runtime paths, which removed the `claim_inline_button` `null instance` crash and allowed the reward tray review board to render again.

## Reward Claim Bugfix Verification

- Passed: `tests/run_main_layout_audit_contract.gd` exits with status `0` after the scene-tree fix, with no reward-board missing-node errors.
- Passed: `tests/run_reward_ceremony_contract.gd`
- Passed: `tests/run_start_option_contract.gd`
- Observed: `tests/run_test_ui_read_models.gd` still fails, but only on unrelated pre-existing Korean expectation/copy drift outside this scene-tree bugfix.

## Node-Select Crossroads Completion Summary

Completed the requested node-select follow-up so the live runtime now reflects the June 8 crossroads mockup direction instead of the older roadmap-board shell.

## Node-Select Crossroads Actual Outputs

- Updated runtime page shell and render logic in:
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd`
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn`
- Added board-head and hover-card copy keys in:
  - `app-LTL/src/data/i18n/text-en.json`
  - `app-LTL/src/data/i18n/text-ko.json`
- Retargeted focused node-select contracts in:
  - `app-LTL/tests/run_main_start_flow_contract.gd`
  - `app-LTL/tests/run_page_scene_mapping_contract.gd`
- Refreshed supporting reference notes in:
  - `docs/source-map.md`
- Captured fresh live-window QA evidence:
  - `app-LTL/test-artifacts/visual/node-select-runtime.png`

## Node-Select Crossroads Changes From Plan

The implementation stayed within the approved crossroads scope. One practical deviation is that the runtime still uses the existing glyph-based hotspot buttons rather than the exact SVG icon set from the HTML mockup, but the board head, hover-card structure, caption tags, and stage gating now follow the same layout direction.

## Node-Select Crossroads Verification Results

- Passed: `tests/run_main_start_flow_contract.gd`
- Passed: `tests/run_main_layout_audit_contract.gd`
- Passed: `tools/capture-node-select-runtime.ps1` produced a fresh live-window screenshot at `app-LTL/test-artifacts/visual/node-select-runtime.png`
- Observed: `tests/run_page_scene_mapping_contract.gd` still fails, but only on the unrelated pre-existing leviathan-select CTA copy assertions; the node-select scene assertions no longer appear in that failure output.

## Node-Select Crossroads Blockers Or Unverified Areas

- The captured live screenshot is the stage-one fixed-entry state. Stage-two five-route behavior is verified by the start-flow and layout contracts rather than by a second live-window capture in this turn.
- The broad page-scene mapping runner still carries unrelated leviathan-select debt in the current dirty worktree, so it cannot yet serve as a clean all-pages pass for this task alone.

## Reward Claim Interaction Follow-up Summary

Completed the reward-claim follow-up so the reward workspace now reuses the live shared backpack panel, reward cards render as floating image cards instead of list blocks, and reward pickup uses click-to-inspect plus drag-to-place/discard rather than the earlier click-to-move behavior.

## Reward Claim Interaction Follow-up Verification

- Passed: `tests/run_reward_ceremony_contract.gd`
- Passed: `tests/run_start_option_contract.gd`
- Passed: `tests/run_main_layout_audit_contract.gd` exits `0`
- Passed: `tests/run_reward_claim_board_contract.gd` exits `0`
- Observed: the focused reward-board runner currently exits cleanly without printing its success banner in captured output; the same shutdown leak warnings still appear as in the other headless Godot checks

## Reward Claim Layout Polish Summary

Completed the requested reward-claim layout polish so the center of the board now reads as the backpack engine panel itself, not a titled wrapper panel around it, and the reward cloud cards float in separated positions instead of stacking on top of each other.

## Reward Claim Layout Polish Actual Outputs

- Updated reward-board layout and float-motion behavior in:
  - `app-LTL/src/ui/MainViewRuntime.gd`
- Replaced today's stale plan with the active reward-board layout-polish scope in:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`

## Reward Claim Layout Polish Changes From Plan

The implementation stayed within the approved scope. The visible wrapper was removed by runtime layout/theming rather than by deleting the underlying workspace nodes, which keeps the existing scene paths and contract surface intact while still producing the requested visual result.

## Reward Claim Layout Polish Verification Results

- Passed: `tests/run_reward_claim_board_contract.gd`
- Passed: `tests/run_main_layout_audit_contract.gd`
- Passed: `tests/run_reward_ceremony_contract.gd`
- Observed: headless Godot still prints the same shutdown leak warnings that appeared in earlier runs, but these checks exited successfully and did not report new reward-board failures.

## Reward Claim Layout Polish Blockers Or Unverified Areas

- No fresh live-window screenshot was captured in this turn, so the visual result here is contract-verified rather than image-verified.

## Reward Claim Layout Rebalance Summary

Adjusted the follow-up layout once more so the center backpack panel stays proportionally large without pushing the reward board’s bottom row out of view, and the left and right side panels now expand back evenly to preserve the overall board balance.

## Reward Board Interaction Cleanup Summary

Completed the requested reward-board cleanup so the obsolete helper copy is removed, reward-card hover becomes inert, backpack item clicks feed the fixed right-side inspector, and the shared backpack workspace now follows the same drag-and-drop interaction model as the reward cards.

## Reward Board Interaction Cleanup Actual Outputs

- Updated reward-board interaction wiring in:
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/ui/BackpackUI.gd`
  - `app-LTL/src/MainControllerRuntime.gd`
- Removed the requested helper copy in:
  - `app-LTL/src/data/i18n/text-en.json`
  - `app-LTL/src/data/i18n/text-ko.json`
- Added focused regression coverage in:
  - `app-LTL/tests/test_reward_claim_board_contract.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
- Updated today's worklog plan/history in:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-08.md`

## Reward Board Interaction Cleanup Changes From Plan

The implementation stayed inside the requested interaction-cleanup scope. One small practical addition was restoring a dragged backpack artifact to its original slot when the mouse release misses every valid drop surface, which keeps the new drag-and-drop flow from falling back into the old click-and-move holding state.

## Reward Board Interaction Cleanup Verification Results

- Checked: `tests/run_reward_claim_board_contract.gd` exited `0`; the captured output still only showed the familiar Godot shutdown leak warnings and no new reward-board contract failures.
- Checked: `tests/run_test_ui_read_models.gd` still fails on unrelated pre-existing localization expectation drift, but the newly added helper-copy removal and backpack-drag contract failures no longer appear in the runner output after this pass.
- Passed: `git diff --check -- app-LTL/src/ui/MainViewRuntime.gd app-LTL/src/ui/BackpackUI.gd app-LTL/src/MainControllerRuntime.gd app-LTL/src/data/i18n/text-en.json app-LTL/src/data/i18n/text-ko.json app-LTL/tests/test_reward_claim_board_contract.gd app-LTL/tests/test_ui_read_models.gd docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`

## Reward Board Interaction Cleanup Blockers Or Unverified Areas

- No fresh live-window capture was taken in this turn, so the final UX was validated by focused contracts and code-path inspection rather than by a new screenshot.
- The broader `run_test_ui_read_models.gd` suite still carries unrelated legacy expectation failures around localized strings, so it is not yet a clean all-green gate for this reward-board pass by itself.

## Node-Select Shared-Shell Repair Summary

Normalized the node-select runtime so stage one, stage two, and the boss-selection lock all stay on the same `node_select` page and only swap route markers, history, and boss/current-node state as the run advances.

## Node-Select Shared-Shell Repair Actual Outputs

- Hardened roadmap placement and route-offset generation in:
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd`
- Added stage progression layout assertions in:
  - `app-LTL/tests/run_main_layout_audit_contract.gd`
  - `app-LTL/tests/run_main_start_flow_contract.gd`
- Updated today's worklog notes in:
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-08.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-08.md`

## Node-Select Shared-Shell Repair Root Cause

The broken second-stage and boss-lock layouts were not using a different intended page. The actual failure was inside `NodeSelectRuntimePage`: `_route_offsets_for_count()` returned an untyped duplicated array when the middle stage requested all five route offsets, which violated the declared `Array[Vector2]` contract, interrupted the canvas rebuild, and then cascaded into missing or out-of-bounds route positions. That made stage one appear fine while later stages looked like a different or broken screen.

## Node-Select Shared-Shell Repair Changes From Plan

The implementation stayed inside the requested node-select scope. Rather than rewriting page routing, the fix preserved the existing dedicated `node_select` page and enforced the intended behavior by repairing its internal layout math and by adding explicit tests that the same page instance is reused across stage reentry and boss-lock progression.

## Node-Select Shared-Shell Repair Verification Results

- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_node_select_runtime_contract.gd'`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_start_flow_contract.gd'`
- Checked: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd'` still fails, but only on the pre-existing combat backpack sizing and viewport containment assertions; the node-select shell assertions no longer fail in that run.

## Node-Select Shared-Shell Repair Blockers Or Unverified Areas

- `app-LTL/src/ui/MainViewRuntime.gd` still contains stale helper paths for the retired `RouteSplit` host, but that wiring is not the active page path that drives the current node-select runtime. Cleaning up that legacy branch can be handled separately from this user-reported stage-two regression.
- The broad layout audit is not fully green yet because unrelated combat-shell containment debt remains in the current worktree.

## Node-Select Leviathan Copy Cleanup Summary

Removed the duplicated Leviathan naming on the node-select runtime page so the screen now keeps a single Leviathan title in the board head.

## Node-Select Leviathan Copy Cleanup Actual Outputs

- Updated node-select copy binding in:
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd`
- Added focused regression coverage in:
  - `app-LTL/tests/run_node_select_runtime_contract.gd`
  - `app-LTL/tests/run_main_start_flow_contract.gd`
- Updated today's worklog records in:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-08.md`

## Node-Select Leviathan Copy Cleanup Changes From Plan

The implementation stayed within the requested scope. One practical verification adjustment was dropping the runner's `-Quit` flag for these async Godot contracts so their red/green exit status reflects the script assertions instead of the engine's forced shutdown path.

## Node-Select Leviathan Copy Cleanup Verification Results

- Passed after red-first verification: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_node_select_runtime_contract.gd'`
- Passed after red-first verification: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_start_flow_contract.gd'`

## Node-Select Leviathan Copy Cleanup Blockers Or Unverified Areas

- No fresh live-window screenshot was captured in this turn, so the result is contract-verified rather than image-verified.

## Reward Board Inspection Stability And Drag Ghost Anchoring Summary

Kept the reward-board inspector structurally stable between the pre-selection and selected states, and changed the backpack drag ghost so it now tracks from the cursor's top-left corner instead of hovering around the cursor center.

## Reward Board Inspection Stability And Drag Ghost Anchoring Actual Outputs

- Updated reward-board inspector shell behavior in:
  - `app-LTL/src/ui/read_models/RewardReadModel.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
- Updated drag-ghost anchoring in:
  - `app-LTL/src/ui/BackpackUI.gd`
- Added focused regression coverage in:
  - `app-LTL/tests/test_reward_claim_board_contract.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
- Updated today's worklog records in:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-08.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-08.md`

## Reward Board Inspection Stability And Drag Ghost Anchoring Changes From Plan

The implementation stayed within the requested scope. The only structural adjustment beyond the raw bugfix was preserving placeholder fact tiles and an inactive footprint shell in the empty inspector so the board no longer changes its internal skeleton when focus moves between rewards and backpack artifacts.

## Reward Board Inspection Stability And Drag Ghost Anchoring Verification Results

- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_claim_board_contract.gd' -Quit`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd' -Quit`
- Passed targeted check: the added `run_test_ui_read_models.gd` regression messages for the empty inspector shell and drag-ghost cursor anchoring no longer appear (`NO_TARGETED_FAILURES`), while the runner's unrelated legacy localization failures remain outside this change scope.
- Passed: `git diff --check -- app-LTL/src/ui/BackpackUI.gd app-LTL/src/ui/MainViewRuntime.gd app-LTL/src/ui/read_models/RewardReadModel.gd app-LTL/tests/test_reward_claim_board_contract.gd app-LTL/tests/test_ui_read_models.gd docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`

## Reward Board Inspection Stability And Drag Ghost Anchoring Blockers Or Unverified Areas

- No fresh live-window screenshot was captured in this turn, so the result is verified by focused Godot contracts and targeted regression-output checks rather than a new manual image capture.
- The full `run_test_ui_read_models.gd` suite is still not an all-green gate because of unrelated existing localization expectation drift that predates this fix.

## Reward Board Inspector Persistence Follow-up Summary

Normalized the reward-board inspector payload so backpack-selected starter artifacts no longer switch the panel into an English-title plus empty-summary state, which was the main reason the layout looked broken and kept that broken-looking state across later phases.

## Reward Board Inspector Persistence Follow-up Actual Outputs

- Localized starter artifact metadata at creation time in:
  - `app-LTL/src/models/Artifact.gd`
- Added non-empty inspector summary fallback in:
  - `app-LTL/src/ui/read_models/RewardReadModel.gd`
- Added focused regression coverage and a dedicated runner in:
  - `app-LTL/tests/test_ui_read_models.gd`
  - `app-LTL/tests/run_reward_inspector_stability_contract.gd`
- Updated today's worklog records in:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-08.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-08.md`

## Reward Board Inspector Persistence Follow-up Changes From Plan

The implementation stayed inside the requested bugfix scope. One practical addition was the dedicated `run_reward_inspector_stability_contract.gd` runner so the new behavior can be verified independently from the broader UI read-model suite's older localization expectation drift.

## Reward Board Inspector Persistence Follow-up Verification Results

- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_inspector_stability_contract.gd'`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_claim_board_contract.gd'`
- Checked: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_test_ui_read_models.gd'` still reports unrelated legacy localization failures, but the newly added starter-inspector and summary-fallback failures no longer appear.
- Checked: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd'` currently fails on separate combat-shell backpack sizing and page-frame containment assertions that are outside this focused inspector-data fix.
- Passed: `git diff --check -- app-LTL/src/models/Artifact.gd app-LTL/src/ui/read_models/RewardReadModel.gd app-LTL/tests/test_ui_read_models.gd app-LTL/tests/run_reward_inspector_stability_contract.gd docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`

## Reward Board Inspector Persistence Follow-up Blockers Or Unverified Areas

- No fresh live-window screenshot was captured in this pass, so the result here is contract-verified rather than image-verified.
- The broad `run_main_layout_audit_contract.gd` runner is not a clean gate in the current tree because it now fails on unrelated combat-shell containment debt as well as the reward tray page frame root bounds.

## Reward Board Scroll Containment Follow-up Summary

Stopped the reward page from resizing the whole app shell when a reward or backpack artifact updates the inspector by constraining the reward-board body inside a dedicated scroll host.

## Reward Board Scroll Containment Follow-up Actual Outputs

- Added a fixed-shell reward board body host in:
  - `app-LTL/src/Main.tscn`
- Rebound reward-board runtime paths to the new host in:
  - `app-LTL/src/ui/MainViewRuntime.gd`
- Updated reward-board regression contracts in:
  - `app-LTL/tests/test_reward_claim_board_contract.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `app-LTL/tests/run_main_layout_audit_contract.gd`
  - `app-LTL/tests/run_main_viewport_probe.gd`
- Removed the temporary probe artifact:
  - `app-LTL/tests/tmp_reward_box_probe.gd`

## Reward Board Scroll Containment Follow-up Changes From Plan

The fix stayed within the same reward-board bug scope. The only structural adjustment was introducing the internal scroll host because tightening label minimum sizes alone could not stop the reward board from inflating the root shell in the real boot flow.

## Reward Board Scroll Containment Follow-up Verification Results

- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_claim_board_contract.gd'`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_inspector_stability_contract.gd'`

## Reward Board Scroll Containment Follow-up Blockers Or Unverified Areas

- No fresh live-window screenshot was captured in this pass, so the result is contract-verified rather than image-verified.

## Test Suite Size Split And Harness Gate Summary

Completed the requested test-source restructuring by splitting the oversized formal UI read-model suite into small leaf files and adding a dedicated harness gate that keeps those test surfaces small over time.

## Test Suite Size Split And Harness Gate Actual Outputs

- Replaced the old monolithic aggregator surface in:
  - `app-LTL/tests/test_ui_read_models.gd`
- Added a shared base helper in:
  - `app-LTL/tests/support/UiReadModelTestSuite.gd`
- Added ten focused leaf suites in:
  - `app-LTL/tests/ui_read_models/`
- Added dedicated harness enforcement in:
  - `LTL-harness/tools/test-size-gate.ps1`
  - `LTL-harness/tools/test-size-gate.tests.ps1`
- Wired the new gate into:
  - `tools/run-compile-check.ps1`
  - `tools/run-ltl-quality-gate.ps1`
- Updated supporting governance/docs in:
  - `LTL-harness/00_AGENTS.md`
  - `LTL-harness/README.md`
  - `docs/source-map.md`
  - `docs/request-ledgers/2026-06-08-test-suite-size-gate.md`

## Test Suite Size Split And Harness Gate Changes From Plan

The implementation stayed within the approved "2번" direction: a dedicated split structure plus a dedicated enforcement gate. One deliberate boundary choice was warning, not hard-failing, for other already-large legacy test files outside the split surface so this pass could land without turning unrelated debt into a blocker.

## Test Suite Size Split And Harness Gate Verification Results

- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'LTL-harness/tools/test-size-gate.tests.ps1'` -> `TEST_SIZE_GATE_TESTS_OK`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'LTL-harness/tools/test-size-gate.ps1' -Root 'D:\Programming\ex_workspace\LootingTheLeviathan'` -> `TEST_SIZE_GATE_OK`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_inspector_stability_contract.gd' -Quit` -> `REWARD_INSPECTOR_STABILITY_CONTRACT_OK`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_ceremony_contract.gd' -Quit` -> `REWARD_CEREMONY_CONTRACT_OK`
- Checked: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_defeat_page_contract.gd' -Quit` still fails on the current defeat-page copy expectations rather than on split-runner structure.
- Checked: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_test_ui_read_models.gd' -Quit` still fails on broad pre-existing localization and copy drift in the current worktree, but the new split suites load and run successfully.
- Passed: `git diff --check -- LTL-harness/00_AGENTS.md LTL-harness/README.md LTL-harness/tools/test-size-gate.ps1 LTL-harness/tools/test-size-gate.tests.ps1 app-LTL/tests/support/UiReadModelTestSuite.gd app-LTL/tests/ui_read_models app-LTL/tests/test_ui_read_models.gd docs/source-map.md docs/request-ledgers/2026-06-08-test-suite-size-gate.md tools/run-compile-check.ps1 tools/run-ltl-quality-gate.ps1`

## Test Suite Size Split And Harness Gate Blockers Or Unverified Areas

- The new gate already warns about remaining legacy oversized files such as `test_reward_contract.gd`, `run_main_layout_audit_contract.gd`, and `godot_contract_runner.gd`; those still need separate follow-up splits when their surfaces are touched.
- The full UI read-model and defeat-page broad assertions are not green in the current dirty worktree because of existing localized-copy expectation drift that predates this structural split.
