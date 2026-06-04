# Codex Worklog Completion

Workspace: LootingTheLeviathan
Date: 2026-06-01

## Additional Completion: Backpack Pin Size And Border-Tile Follow-Up

Applied the user's live-screenshot follow-up to the combat backpack pins and battlefield miner overlay. The pins now use a smaller rectangular display box, anchor directly to the requested `backpack_1`, `backpack_3`, `backpack_9`, and `backpack_7` border tiles, and sit on those tiles' left/right sides instead of floating across the backpack interior. The battlefield miner overlay now sits at the upper-right edge of the battlefield panel instead of occupying a left-side reserved column.

## Additional Outputs: Backpack Pin Size And Border-Tile Follow-Up

- Updated `app-LTL/src/ui/BackpackUI.gd`
- Updated `app-LTL/src/ui/BattlefieldUI.gd`
- Updated `app-LTL/tests/test_ui_read_models.gd`
- Updated `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`

## Additional Verification Results: Backpack Pin Size And Border-Tile Follow-Up

- Focused UI runner: `tests/run_test_ui_read_models.gd` printed `UI_READ_MODEL_TESTS_OK`.
- Broad suite: `tests/godot_contract_runner.gd` printed `GODOT_CONTRACTS_OK`.
- Remaining gap: this pass still used headless verification, so a fresh live screenshot was not captured here.

## Additional Completion: Backpack Pin Corner Placement Fix

Fixed the screenshoted backpack pin placement regression. The four combat pin images were drifting into unrelated HUD regions because the overlay nodes were using top-level/global positioning instead of the backpack's own local canvas. `BackpackUI` now keeps the pin nodes local, computes their anchors from the outer backpack-grid rect, and runs the pull-out VFX in local coordinates as well, which keeps the pins attached to the backpack's top-left, top-right, bottom-right, and bottom-left corners.

## Additional Outputs: Backpack Pin Corner Placement Fix

- Updated `app-LTL/src/ui/BackpackUI.gd`
- Updated `app-LTL/tests/test_ui_read_models.gd`
- Updated `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`

## Additional Verification Results: Backpack Pin Corner Placement Fix

- Focused UI runner: `tests/run_test_ui_read_models.gd` printed `UI_READ_MODEL_TESTS_OK`.
- Broad suite: `tests/godot_contract_runner.gd` printed `GODOT_CONTRACTS_OK`.
- Remaining gap: a fresh live screenshot was not captured in this headless verification pass.

## Additional Completion: Deferred Mouse-Over Cleanup Fix

Fixed the concrete `Window::Viewport::_drop_mouse_over` error that appeared after starter-option interaction. The root cause was not the combat transition logic itself, but the node-map rerender path immediately destroying replaced buttons with `free()` while Godot still had deferred mouse-over cleanup queued for the hovered control. `NodeMapScene.render()` now defers destruction with `queue_free()`, which preserves the old control objects until the frame cleanup completes safely.

## Additional Outputs: Deferred Mouse-Over Cleanup Fix

- Updated `app-LTL/src/scenes/node_map/NodeMapScene.gd`
- Updated `app-LTL/tests/test_node_map_scene_smoke.gd`
- Added `app-LTL/tests/run_node_map_scene_smoke.gd`
- Updated `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`

## Additional Verification Results: Deferred Mouse-Over Cleanup Fix

- RED: `tests/run_node_map_scene_smoke.gd` failed first because replaced node-map buttons were freed immediately during rerender.
- GREEN: `tests/run_node_map_scene_smoke.gd` printed `NODE_MAP_SCENE_SMOKE_OK`.
- Follow-up suites: `tests/run_start_option_contract.gd` printed `START_OPTION_CONTRACT_OK`, `tests/run_test_ui_read_models.gd` printed `UI_READ_MODEL_TESTS_OK`, and `tests/godot_contract_runner.gd` printed `GODOT_CONTRACTS_OK`.

## Additional Completion: Backpack Pin Design

Created the approved `Option A` design document for the combat backpack pins. The spec covers the panel-only width policy, slot-scaled pin sizing, requested removal order, localized pull-out VFX, component ownership, data flow, reset behavior, testing targets, and approval-board criteria.

## Additional Completion: Backpack Pin Layout And VFX

Implemented the backpack pin gutter and VFX fix. The first gutter attempt overconstrained the grid and leaked into node select, so this pass normalized the grid back to expand-fill and moved the pin space into combat-only left/right shell margins. Pins are now sized from slot geometry rather than full-grid width, placed outside the corner slots with controlled overlap, removed in the requested `pin_1 -> pin_2 -> pin_3 -> pin_4` order, and animated with a stronger local pull-out/fade that is easier to read.

## Additional Completion: Backpack Pin Implementation Plan

Created the implementation plan for the approved backpack pin design. The plan breaks the work into TDD tasks covering RED contracts, slot-scaled width helpers, requested pin-removal order, shell-gutter placement, localized pull-out tween behavior, broad verification, and worklog updates.

## Additional Completion: Reward-Screen Backpack Ghost Visual Unification

Fixed the reward-screen backpack selection visual mismatch. Clicking an inventory item no longer swaps to a smaller, darker-looking ghost style inside the grid area; the selected artifact now reuses the same slot-sized footprint and fill language as the in-grid overlay.

## Additional Completion: Reward-Screen Slot Background Stability

Fixed the remaining reward-screen grid background change during item pickup and placement. The actual cause was not the held-item ghost but the slot drag-feedback path retinting every backpack `Panel` slot while an item was held. Backpack slots now preserve their original background tint, alpha, and resting transform during dragging, so clicking or placing an inventory item no longer changes the grid cell artwork itself.

## Additional Completion: Corrected Reward Ceremony VFX Rework

Implemented the corrected mined-terrain reward ceremony. The ceremony now clones `tile_panel_nobg.png` from the battlefield tile area, lifts it toward the center as a mined lid, hides exact reward count during the charge, accelerates sparkle/light wrapping, reveals the exact count only during the burst, and then reveals each reward through a white sealed card with fixed rarity-based VFX.

Follow-up code review found that hidden cards and queue markers still leaked rarity colors before reveal. That is now fixed: hidden cards, hidden queue markers, and pre-reveal aura use a neutral white accent, while actual rarity colors and burst strength appear only once the card identity is visible.

## Additional Bugfix Outputs

- Updated `app-LTL/src/ui/BackpackUI.gd`
- Updated `app-LTL/src/ui/InteractionFX.gd`
- Updated `app-LTL/src/ui/RewardRevealOverlay.gd`
- Updated `app-LTL/src/ui/BattlefieldUI.gd`
- Updated `app-LTL/src/ui/MainViewRuntime.gd`
- Updated `app-LTL/tests/test_ui_read_models.gd`
- Updated `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`

## Additional Outputs

- Added `docs/superpowers/specs/2026-06-01-backpack-pin-layout-vfx-design.md`
- Added `docs/superpowers/plans/2026-06-01-backpack-pin-layout-vfx-implementation-plan.md`
- Updated `app-LTL/src/ui/BackpackUI.gd`
- Updated `app-LTL/src/ui/MainViewRuntime.gd`
- Updated `app-LTL/src/Main.tscn`
- Updated `app-LTL/tests/test_ui_read_models.gd`
- Updated `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`

## Additional Verification Results

- Placeholder and ambiguity scan passed for the new spec and touched worklog files.
- `git diff --check` returned no whitespace errors for the new spec and touched worklog files.
- Runtime/Godot tests were not run because this pass intentionally created the design document only and did not implement behavior changes.
- Implementation-plan placeholder and consistency scan passed.
- Implementation-plan `git diff --check` returned no whitespace errors.
- Backpack pin fix RED/GREEN verification passed:
  - RED: focused UI runner failed first on missing pin geometry, grid sizing, removal-order, and VFX helper contracts.
  - GREEN: `tests/run_test_ui_read_models.gd` printed `UI_READ_MODEL_TESTS_OK`.
  - Broad suite: `tests/godot_contract_runner.gd` printed `GODOT_CONTRACTS_OK`.
  - Diff hygiene: `git diff --check` reported no whitespace errors in touched files, only existing LF/CRLF normalization warnings.
- Reward-screen ghost RED/GREEN verification passed:
  - RED: the focused UI runner failed first on missing `ghost_cell_size_for_slot` and `artifact_fill_alpha`.
  - GREEN: `tests/run_test_ui_read_models.gd` printed `UI_READ_MODEL_TESTS_OK` after the `BackpackUI` fix.
- Reward-screen slot-background stability verification passed:
  - RED: the focused UI runner failed first because backpack slot drag feedback changed the slot background tint during dragging.
  - GREEN: `tests/run_test_ui_read_models.gd` again printed `UI_READ_MODEL_TESTS_OK` after the `InteractionFX` fix.
- Diff hygiene on the touched bugfix files returned only existing LF/CRLF normalization warnings and no whitespace errors.
- Corrected reward ceremony VFX verification passed:
  - Focused reward ceremony runner printed `REWARD_CEREMONY_CONTRACT_OK`.
  - Broader UI read-model runner printed `UI_READ_MODEL_TESTS_OK`.
  - Full Godot contract runner printed `GODOT_CONTRACTS_OK`.
  - `git diff --check` returned no whitespace errors, only existing LF/CRLF normalization warnings.
- Rarity-leak review fix verification passed:
  - RED: focused reward ceremony runner failed first on missing neutral pre-reveal concealment and queue marker visibility contracts.
  - GREEN: focused reward ceremony runner printed `REWARD_CEREMONY_CONTRACT_OK`.
  - Broader UI and full Godot contract runners again printed `UI_READ_MODEL_TESTS_OK` and `GODOT_CONTRACTS_OK`.

## Additional Remaining Gaps

- A live screenshot pass was not captured in this headless verification step.

## Additional Completion: Reward Ceremony Polish Pass

Polished the mining-themed reward ceremony after live screenshot review. The excavation lid now respects the wide `tile_panel_nobg.png` aspect instead of collapsing into a short plaque, the count reveal flows out of opening lid doors and orbiting reward orbs rather than reading like a scene cut, and rarity reveal effects are intentionally exaggerated so common through mythic each read as distinct reveal moments.

## Additional Outputs: Reward Ceremony Polish Pass

- Updated `app-LTL/src/ui/RewardRevealOverlay.gd`
- Updated `app-LTL/tests/test_ui_read_models.gd`
- Updated `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`

## Additional Verification Results: Reward Ceremony Polish Pass

- RED: the focused ceremony runner failed first on missing `center_lid_layout_model`, `count_burst_animation_model`, and stronger `reveal_visual_profile` guarantees.
- GREEN: `tests/run_reward_ceremony_contract.gd` printed `REWARD_CEREMONY_CONTRACT_OK`.
- Broad UI runner: `tests/run_test_ui_read_models.gd` printed `UI_READ_MODEL_TESTS_OK`.
- Full contract suite: `tests/godot_contract_runner.gd` printed `GODOT_CONTRACTS_OK`.
- `git diff --check` returned only existing LF/CRLF normalization warnings and no whitespace errors in the touched files.

## Completion Summary

Implemented the approved reward ceremony redesign. Reward drops now open as a mining-themed, confirm-gated ceremony with quantity suspense, count lock, and low-to-high single-item reveals, then return to the existing reward tray and backpack organization flow. Stage-2-plus node-select screens no longer show the starter color picker.

Applied a follow-up visual correction pass after screenshot review. The count tease now hides the exact reward count until count lock, uses a single glowing/cracking excavation chamber instead of exposing all slots immediately, removes the messy lid backdrop from the result card stage, increases common-to-epic visual separation, and centers/fits the overlay text to avoid clipping.

## Actual Outputs

- Updated `app-LTL/src/MainControllerRuntime.gd`
- Updated `app-LTL/src/ui/MainViewRuntime.gd`
- Updated `app-LTL/src/ui/RewardRevealOverlay.gd`
- Updated `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
- Updated `app-LTL/src/ui/read_models/NodeMapReadModel.gd`
- Updated `app-LTL/src/scenes/node_map/NodeMapScene.gd`
- Updated `app-LTL/tests/test_ui_read_models.gd`
- Added `app-LTL/tests/run_reward_ceremony_contract.gd`
- Updated the June 1 worklog files

## Changes From Plan

No scope expansion was needed beyond the approved redesign. The implementation kept the existing tray/backpack claim flow intact and used the already-approved `tile_panel_nobg.png` lid metaphor instead of introducing any new art asset dependency.

## Verification Results

- Focused ceremony contract:
  - `Godot_v4.3-stable_win64_console.exe --display-driver headless --audio-driver Dummy --path ... --script tests/run_reward_ceremony_contract.gd --disable-crash-handler --log-file ... --quit`
  - Result: `REWARD_CEREMONY_CONTRACT_OK`
- Broad Godot contract suite:
  - `Godot_v4.3-stable_win64_console.exe --display-driver headless --audio-driver Dummy --path ... --script tests/godot_contract_runner.gd --disable-crash-handler --log-file ... --quit`
  - Result: `GODOT_CONTRACTS_OK`
- Diff hygiene:
  - `git diff --check -- ...`
  - Result: only LF/CRLF normalization warnings, no whitespace errors

- Follow-up visual correction RED/GREEN:
  - RED: the focused reward-ceremony runner failed first on missing `count_tease_preview_model`, `reveal_visual_profile`, and `reward_card_layout_metrics`.
  - GREEN: after the overlay cleanup pass, the same runner again printed `REWARD_CEREMONY_CONTRACT_OK`.

## Blockers Or Unverified Areas

- Godot still prints its usual exit-time RID/ObjectDB leak warnings after successful contract runs. The success markers were present and the process exit codes for the verified runs were successful, so this remains an existing engine/runtime noise issue rather than a new blocker from the ceremony work.

## Remaining Gaps

- No new screenshot artifact was captured in this pass, so final visual confirmation comes from the implemented runtime plus headless contracts rather than a saved rendered frame.

## Additional Completion: Starter-Option Start-Flow Regression

Investigated the reported silent exit after choosing a starter option and pressing `전투 시작`. The controller-level start path itself remained valid, but the main UI preload chain had become fragile after the reward-ceremony work because `RewardRevealOverlay.gd` still contained parser issues. Fixing the overlay parser path restored the preload chain, and the regression is now protected by both the active UI read-model suite and a focused `Main.tscn` start-flow runner that exercises multiple starter-color and node-selection combinations through the real scene.

## Additional Outputs: Starter-Option Start-Flow Regression

- Updated `app-LTL/src/ui/RewardRevealOverlay.gd`
- Updated `app-LTL/tests/test_ui_read_models.gd`
- Added `app-LTL/tests/run_main_start_flow_contract.gd`
- Added `app-LTL/tests/test_start_option_contract.gd`
- Added `app-LTL/tests/run_start_option_contract.gd`
- Updated `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`

## Additional Verification Results: Starter-Option Start-Flow Regression

- Focused controller path: `tests/run_start_option_contract.gd` printed `START_OPTION_CONTRACT_OK`.
- Focused preload/UI path: `tests/run_test_ui_read_models.gd` printed `UI_READ_MODEL_TESTS_OK`.
- Focused `Main.tscn` flow path: `tests/run_main_start_flow_contract.gd` exited successfully with no assertion failures after running multiple starter-color and node-selection combinations.

## Additional Completion: Silent Combat-Start Freeze

The remaining silent close after pressing `전투 시작` was a combat-entry layout loop in the backpack pin overlay path, not a controller or preview-controller state failure. After the scene switched into combat, `BackpackUI._layout_pin_overlays()` changed the combat pin gutter margin and immediately re-deferred itself in the same idle cycle, which could spin forever before the first post-start frame completed. That matched the observed behavior exactly: brief freeze, no new gameplay log, and debugger stop without a higher-level script error.

## Additional Outputs: Silent Combat-Start Freeze

- Updated `app-LTL/src/ui/BackpackUI.gd`
- Updated `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
- Updated `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`

## Additional Verification Results: Silent Combat-Start Freeze

- Headless real-scene start-flow contract: `tests/run_main_start_flow_contract.gd` printed `MAIN_START_FLOW_CONTRACT_OK`.
- Focused starter-option controller contract: `tests/run_start_option_contract.gd` printed `START_OPTION_CONTRACT_OK`.
- Broad UI helper contract: `tests/run_test_ui_read_models.gd` printed `UI_READ_MODEL_TESTS_OK`.
- Broad Godot suite: `tests/godot_contract_runner.gd` printed `GODOT_CONTRACTS_OK`.
- `git diff --check` returned only existing LF/CRLF normalization warnings and no whitespace errors.

## Additional Remaining Gaps: Silent Combat-Start Freeze

- Godot still prints its existing exit-time RID/ObjectDB leak warnings after successful headless runs; those warnings did not block the new start-flow success markers.
