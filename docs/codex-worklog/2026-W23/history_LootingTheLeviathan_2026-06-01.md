# Codex Worklog History

Workspace: LootingTheLeviathan
Date: 2026-06-01

## 2026-06-01

- Intent: Apply the user's live-screenshot follow-up by shrinking the backpack pins, snapping them to the named border tiles, and moving the battlefield miner overlay into the upper-right edge.
- Files or areas touched:
  - `app-LTL/src/ui/BackpackUI.gd`
  - `app-LTL/src/ui/BattlefieldUI.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`
- Summary: The first corner-pin fix kept the pins in the backpack canvas, but the user screenshot showed the art was still too large and not attached to the exact requested `backpack_1/3/7/9` border tiles. Updated `BackpackUI` so the four pin specs now target the outer border cells directly, anchor to those tiles' left/right side centers, and render in a shallower rectangular display box that reads closer to a one-by-two-slot prop instead of a giant square overlay. In the same follow-up pass, rewired `BattlefieldUI.layout_metrics_for_board()` so the shared miner pose overlay no longer reserves a left-side column and instead sits flush against the battlefield panel's upper-right edge while keeping the shell and grid stable underneath.
- Plan impact: Expanded the active screenshot-based layout bugfix to cover both backpack pin sizing/placement and battlefield miner placement.
- Verification:
  - Focused UI runner: `tests/run_test_ui_read_models.gd` printed `UI_READ_MODEL_TESTS_OK`.
  - Broad suite: `tests/godot_contract_runner.gd` printed `GODOT_CONTRACTS_OK`.

- Intent: Fix the screenshoted backpack pin placement regression so the four combat pin images stay attached to the backpack corners.
- Files or areas touched:
  - `app-LTL/src/ui/BackpackUI.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`
- Summary: Re-read the backpack shell-gutter work after the user supplied a screenshot showing the four pin images scattered into the wider HUD instead of hugging the backpack corners. The root cause was the pin overlay nodes using top-level/global placement instead of staying in the backpack's local canvas. Updated `BackpackUI` so pin nodes remain local children, corner anchors are derived from the outer backpack-grid rect, and removal VFX tweens use local positions as well. Added focused UI contracts that lock the pin nodes to the backpack-local canvas and verify the rect-based outer-corner anchor helper.
- Plan impact: Replaced the earlier starter-option start-flow investigation with a narrow backpack pin positioning fix and kept verification focused on the UI contract suite plus the broader Godot runner.
- Verification:
  - Focused UI runner: `tests/run_test_ui_read_models.gd` printed `UI_READ_MODEL_TESTS_OK`.
  - Broad suite: `tests/godot_contract_runner.gd` printed `GODOT_CONTRACTS_OK`.

- Intent: Fix the concrete deferred mouse-over cleanup error reported after starter-option interaction.
- Files or areas touched:
  - `app-LTL/src/scenes/node_map/NodeMapScene.gd`
  - `app-LTL/tests/test_node_map_scene_smoke.gd`
  - `app-LTL/tests/run_node_map_scene_smoke.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`
- Summary: Used the concrete `Window::Viewport::_drop_mouse_over` error to re-trace the bug as a UI lifetime issue instead of a combat reducer failure. Added a RED node-map smoke contract that captures the replaced color/node buttons during `NodeMapScene.render()` and asserts they remain valid until deferred cleanup. That test failed immediately because the rerender path removed hovered controls and called `free()` on them in the same tick. Replaced those immediate frees with `queue_free()`, which preserves the old control objects long enough for Godot's deferred mouse-over cleanup to finish safely.
- Plan impact: Refined the earlier starter-option investigation into a narrower node-map rerender lifecycle fix after the engine error made the root cause clear.
- Verification:
  - RED: `tests/run_node_map_scene_smoke.gd` failed first on the old buttons being destroyed immediately during rerender.
  - GREEN: `tests/run_node_map_scene_smoke.gd` printed `NODE_MAP_SCENE_SMOKE_OK`.
  - Follow-up suites: `tests/run_start_option_contract.gd` printed `START_OPTION_CONTRACT_OK`, `tests/run_test_ui_read_models.gd` printed `UI_READ_MODEL_TESTS_OK`, and `tests/godot_contract_runner.gd` printed `GODOT_CONTRACTS_OK`.

## 2026-06-01

- Intent: Investigate the reported silent exit after choosing a starter option and pressing `전투 시작`.
- Files or areas touched:
  - `app-LTL/src/ui/RewardRevealOverlay.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `app-LTL/tests/test_start_option_contract.gd`
  - `app-LTL/tests/run_start_option_contract.gd`
  - `app-LTL/tests/run_main_start_flow_contract.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`
- Summary: Reproduced the controller-only start path first and confirmed the starter loadout itself was not immediately completing or failing the run. The real problem surfaced in the UI load chain: `RewardRevealOverlay.gd` contained parser issues after the recent ceremony work, including a broken indentation in `_hero_reward_index()` plus unqualified static-helper calls that left `MainViewRuntime` preload safety under-tested. Fixed the overlay parser issues, promoted the existing `test_main_ui_load_chain_survives_reward_reveal_preloads()` check into the active UI suite, and added a focused `Main.tscn` runner that exercises starter-color and node-selection combinations through the actual scene before pressing the combat-start button.
- Plan impact: Replaced the stale reward-ceremony polish plan with the newly reported starter-option regression investigation.
- Verification:
  - Focused controller path: `tests/run_start_option_contract.gd` printed `START_OPTION_CONTRACT_OK`.
  - Focused preload/UI path: `tests/run_test_ui_read_models.gd` printed `UI_READ_MODEL_TESTS_OK`.
  - Focused `Main.tscn` flow path: `tests/run_main_start_flow_contract.gd` exited successfully with no assertion failures after running multiple starter-color and node-selection combinations.

- Intent: Fix backpack pin layout so shell gutters actually appear and make pin removal VFX readable.
- Files or areas touched:
  - `app-LTL/src/ui/BackpackUI.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/Main.tscn`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`
- Summary: Confirmed the root cause was twofold: pin layout still used full-grid `30%` sizing with `50%` overlap, and the first gutter fix was wrong because it forced `GridMock` into a shrink-centered narrow strip that broke node-select and made pins effectively disappear. Added RED coverage for slot-scaled pin width, expand-fill grid policy, scene-level `GridMock` flags, combat-only side-margin guttering, requested removal order, and localized VFX profile. Updated the runtime so the grid stays expand-fill, combat mode converts pin overhang into left/right shell margins, pins use slot-sized placement outside the corner cells, removals occur `pin_1 -> pin_2 -> pin_3 -> pin_4`, and the removal tween now uses a clearer `0.07s` anticipation plus `0.20s` outward pull/fade.
- Plan impact: Completed the approved backpack pin design and addressed the screenshot-specific gutter failure.
- Verification:
  - RED: focused UI runner failed first on missing pin geometry, grid sizing, removal-order, and VFX helper contracts.
  - GREEN: focused UI runner printed `UI_READ_MODEL_TESTS_OK`.
  - Broad suite: Godot contract runner printed `GODOT_CONTRACTS_OK`.
  - Diff hygiene: `git diff --check` reported no whitespace errors in touched files, only existing LF/CRLF normalization warnings.

- Intent: Fix the remaining reward-screen grid background image change reported after the first backpack ghost unification pass.
- Files or areas touched:
  - `app-LTL/src/ui/InteractionFX.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`
- Summary: Re-investigated the reward-screen inventory click/place path after the user reported the issue still reproduced. Confirmed the remaining background change did not come from the picked-up artifact ghost itself, but from `BackpackUI._update_drag_slot_feedback()` calling `InteractionFX.apply_drag_feedback()` on every `Panel` slot. That path was retinting the slot `self_modulate` during dragging, so the textured backpack cell background visibly changed whenever an item was picked up. Added RED coverage for slot-background stability during dragging, then updated `InteractionFX` so `Panel`-based backpack slots preserve their original tint, alpha, and resting transform while still updating cursor semantics.
- Plan impact: Replaced the stale plan entry with the user-reported follow-up regression scope before changing runtime code.
- Verification:
  - RED: `Godot_v4.3-stable_win64_console.exe --display-driver headless --audio-driver Dummy --path ... --script tests/run_test_ui_read_models.gd --disable-crash-handler --log-file app-LTL/tmp-slot-bg-red.log --quit` failed first on the slot background tint changing during drag.
  - GREEN: the same focused runner with `app-LTL/tmp-slot-bg-green.log` printed `UI_READ_MODEL_TESTS_OK`.
  - `git diff --check -- ...` on the touched source/test/worklog files returned only existing LF/CRLF normalization warnings and no whitespace errors.

- Intent: Create the implementation plan for the approved backpack pin layout and local pull-out VFX design.
- Files or areas touched:
  - `docs/superpowers/plans/2026-06-01-backpack-pin-layout-vfx-implementation-plan.md`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`
- Summary: Converted the approved `Option A` design into a TDD implementation plan with concrete RED tests, slot-scaled width helpers, requested visible-index removal order, local pull-out tween helpers, verification commands, and worklog update steps.
- Plan impact: This prepares the implementation handoff; runtime source files remain unchanged in this planning step.
- Verification: Placeholder/type-name scan passed for the new plan and touched worklog files; `git diff --check` reported no whitespace errors.

- Intent: Fix the reward-screen backpack item image inconsistency so clicking an equipped item does not visually shrink or restyle it inside the grid area.
- Files or areas touched:
  - `app-LTL/src/ui/BackpackUI.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`
- Summary: Traced the click path through `MainControllerRuntime -> BackpackUI` and confirmed the visual swap came from two different render paths for the same artifact: in-grid overlays used slot-sized fills at alpha `0.32`, while the picked-up ghost used fixed `24x24` cells at alpha `0.5`. Added RED coverage for shared ghost sizing/fill helpers, then updated `BackpackUI` so the drag ghost reuses the live slot size, the same artifact fill alpha, and matching footprint math for multi-cell items. This keeps the selected reward-screen inventory item in one visual language before and after click.
- Plan impact: Replaced the stale June 1 active plan with the reward-screen backpack image-consistency bugfix scope before editing runtime code.
- Verification:
  - RED: `Godot_v4.3-stable_win64_console.exe --display-driver headless --audio-driver Dummy --path ... --script tests/run_test_ui_read_models.gd --disable-crash-handler --log-file app-LTL/tmp-drag-ghost-red.log --quit` failed first on missing `ghost_cell_size_for_slot` and `artifact_fill_alpha` helpers.
  - GREEN: the same focused runner with `app-LTL/tmp-drag-ghost-green.log` printed `UI_READ_MODEL_TESTS_OK`.
  - `git diff --check -- ...` on the touched source/test/worklog files returned only existing LF/CRLF normalization warnings and no whitespace errors.

- Intent: Create the approved `Option A` design document for backpack pin layout, removal order, and localized pull-out VFX before implementation begins.
- Files or areas touched:
  - `docs/superpowers/specs/2026-06-01-backpack-pin-layout-vfx-design.md`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`
- Summary: Added a written design for the slot-scaled pin layout, panel-only width policy, requested removal sequence `pin_1 -> pin_2 -> pin_3 -> pin_4`, localized pull-out VFX, component ownership, data flow, reset behavior, RED-first test targets, and approval-board criteria. The design incorporates the sub-agent audit and web-researched Godot/game-animation guidance while keeping this pass documentation-only.
- Plan impact: Active work changed from prior reward ceremony implementation to the backpack pin layout/VFX design-document request.
- Verification: Focused placeholder/spec-structure search passed after the completion report update; `git diff --check` returned no whitespace errors for the new spec and touched worklog files.

- Intent: Fix the first visual pass of the reward ceremony so count tease hides the exact count, the mining lid actually glows/cracks, and result cards read cleanly with visible rarity separation.
- Files or areas touched:
  - `app-LTL/src/ui/RewardRevealOverlay.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`
- Summary: Added RED coverage for an ambiguity-preserving tease preview helper, clean result-stage layout metrics, and distinct rarity visual profiles. Reworked the overlay so `count_tease` now uses one sealed excavation chamber with band-based hotspot pulses instead of drawing the exact number of lids up front, strengthened `tile_panel_nobg` glow/crack behavior, removed the giant lid backdrop from the reveal card stage, increased common-to-epic visual separation through aura/frame/spark profiles, and centered/fitted text using measured font widths instead of brittle fixed offsets.
- Plan impact: This was a quality correction on top of the implemented ceremony flow, not a scope change.
- Verification:
  - RED: `Godot_v4.3-stable_win64_console.exe --display-driver headless --audio-driver Dummy --path ... --script tests/run_reward_ceremony_contract.gd --disable-crash-handler --log-file ... --quit` failed first on missing `count_tease_preview_model`, `reveal_visual_profile`, and `reward_card_layout_metrics`.
  - GREEN: the same focused reward-ceremony runner printed `REWARD_CEREMONY_CONTRACT_OK` after the overlay redesign.
  - Broad suite: `Godot_v4.3-stable_win64_console.exe --display-driver headless --audio-driver Dummy --path ... --script tests/godot_contract_runner.gd --disable-crash-handler --log-file ... --quit` printed `GODOT_CONTRACTS_OK`.
  - `git diff --check -- app-LTL/src/ui/RewardRevealOverlay.gd app-LTL/tests/test_ui_read_models.gd ...` returned only the existing LF/CRLF normalization warning for `app-LTL/tests/test_ui_read_models.gd`.

- Intent: Rework the reward ceremony VFX around the corrected mined-terrain-lid sequence and card reveal beats.
- Files or areas touched:
  - `app-LTL/src/ui/RewardRevealOverlay.gd`
  - `app-LTL/src/ui/BattlefieldUI.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`
- Summary: Updated the active plan to the corrected ceremony scope, added RED-first contracts for terrain-lid pop-up, count concealment, count burst, sealed card charge, and fixed rarity bursts, then implemented the runtime flow. `BattlefieldUI` now exposes a central terrain-cell source rectangle, `MainViewRuntime` passes that rectangle to the full-screen overlay, and `RewardRevealOverlay` uses a cloned `tile_panel_nobg.png` lid that lifts from the board, charges with accelerating light, reveals the exact count only on burst, and then presents each reward as a white sealed card before rarity-based reveal VFX.
- Plan impact: Supersedes the earlier hotspot-based preview correction. The new count tease no longer uses visible hotspot counts that could imply the reward count.
- Verification:
  - RED: the focused reward ceremony runner failed first after the new contracts because the overlay lacked mined-lid motion, count-burst, and card-reveal phase helpers.
  - GREEN: `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --display-driver headless --audio-driver Dummy --path app-LTL --log-file reward-vfx-run.log --script tests/run_reward_ceremony_contract.gd --disable-crash-handler --quit` printed `REWARD_CEREMONY_CONTRACT_OK`.
  - Broader UI: `... --log-file reward-vfx-ui-read-models.log --script tests/run_test_ui_read_models.gd ...` printed `UI_READ_MODEL_TESTS_OK`.
  - Full contracts: `... --log-file reward-vfx-godot-contracts.log --script tests/godot_contract_runner.gd ...` printed `GODOT_CONTRACTS_OK`.
  - Diff hygiene: `git diff --check` returned no whitespace errors, only existing LF/CRLF normalization warnings.

- Intent: Address code-review findings that hidden cards and queue markers leaked rarity colors before reveal.
- Files or areas touched:
  - `app-LTL/src/ui/RewardRevealOverlay.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`
- Summary: Added a second RED contract for rarity concealment, then changed hidden reward cards, pre-reveal stage aura, and unrevealed queue markers to use a neutral white accent instead of actual rarity colors. Actual rarity accents and burst strength now appear only after the card identity is visible. Also split real `rewardTokenCount` from clamped `visualTokenCount` in `count_burst_model()`.
- Plan impact: Tightens the approved reveal semantics; no scope expansion.
- Verification:
  - RED: `reward-vfx-rarity-leak-red.log` failed on missing neutral concealment fields, missing queue marker phase model, and clamped real count.
  - GREEN: `reward-vfx-rarity-leak-green.log` printed `REWARD_CEREMONY_CONTRACT_OK`.
  - Broader UI: `reward-vfx-ui-read-models-green2.log` printed `UI_READ_MODEL_TESTS_OK`.
  - Full contracts: `reward-vfx-godot-contracts-green2.log` printed `GODOT_CONTRACTS_OK`.
  - Diff hygiene: `git diff --check` returned no whitespace errors, only existing LF/CRLF normalization warnings.

- Intent: Lock the approved reward ceremony redesign into executable RED-first contracts before touching runtime behavior.
- Files or areas touched:
  - `app-LTL/tests/test_ui_read_models.gd`
  - `app-LTL/tests/run_reward_ceremony_contract.gd`
  - `docs/superpowers/specs/2026-06-01-reward-ceremony-redesign-design.md`
  - `docs/superpowers/plans/2026-06-01-reward-ceremony-implementation-plan.md`
- Summary: Added focused reward-ceremony assertions for confirm-gated presentation, three quantity-tease bands, low-to-high rarity sorting, fixed rarity-VFX tiers, the explicit reward presentation step sequence, and stage-2-plus starter color-picker removal. Verified RED first before implementation.
- Plan impact: Established the executable contract surface for the implementation pass.
- Verification:
  - RED: `Godot_v4.3-stable_win64_console.exe --display-driver headless --audio-driver Dummy --path ... --script tests/run_reward_ceremony_contract.gd --disable-crash-handler --quit` failed first on missing ceremony helpers and color-picker gating.

- Intent: Implement the controller-owned reward ceremony flow and return to the existing tray/backpack organization UI after the cinematic.
- Files or areas touched:
  - `app-LTL/src/MainControllerRuntime.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
  - `app-LTL/src/ui/read_models/NodeMapReadModel.gd`
- Summary: Added explicit reward ceremony state in the controller, auto-started the ceremony on `combat -> reward_loot`, blocked reward/backpack/discard/shop/color-picker inputs until `tray_review`, projected `rewardPresentationStep` and `allowStartColorSelection` into the scene contract, and kept the full-screen overlay mounted from `MainViewRuntime` rather than the battlefield-local path.
- Plan impact: Completed the controller/presenter ownership portion of the redesign.
- Verification:
  - Focused headless reward-ceremony runner passed after integration.

- Intent: Replace the old single-card auto-dismiss overlay with a mining-themed, confirm-gated reward ceremony that supports quantity suspense and single-item reveal progression.
- Files or areas touched:
  - `app-LTL/src/ui/RewardRevealOverlay.gd`
- Summary: Rebuilt `RewardRevealOverlay.gd` around the approved mining-lid metaphor using `tile_panel_nobg.png`, with separate `count_tease`, `count_lock`, and `reveal_queue` steps. The overlay now keeps rewards visible until player confirmation, reveals quantity through the `1-2 / 3 / 4-5` suspense bands, reveals items one-by-one from low rarity to high rarity, and ties color, glow, and hold strength to the actual rarity tier instead of queue position.
- Plan impact: Completed the visual/runtime core of the reward ceremony redesign without changing reward claiming semantics.
- Verification:
  - `Godot_v4.3-stable_win64_console.exe --display-driver headless --audio-driver Dummy --path ... --script tests/run_reward_ceremony_contract.gd --disable-crash-handler --log-file ... --quit` printed `REWARD_CEREMONY_CONTRACT_OK`.
  - `Godot_v4.3-stable_win64_console.exe --display-driver headless --audio-driver Dummy --path ... --script tests/godot_contract_runner.gd --disable-crash-handler --log-file ... --quit` printed `GODOT_CONTRACTS_OK`.

- Intent: Remove the stage-2-plus starter color picker from node select so late-stage selections cannot overwrite earned loadouts.
- Files or areas touched:
  - `app-LTL/src/scenes/node_map/NodeMapScene.gd`
  - `app-LTL/src/ui/read_models/NodeMapReadModel.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
- Summary: Gated the starter color-selection row behind an explicit stage-aware contract, stopped emitting color-selection signals when disabled, and passed the same contract through the presenter/read-model/view pipeline so stage 1 keeps the picker while stage 2+ removes it completely.
- Plan impact: Completed the node-select cleanup requested as part of the reward ceremony follow-up.
- Verification:
  - The focused reward-ceremony runner asserted `allowStartColorSelection == true` on stage 1 and `false` on stage 2, and verified `NodeMapScene.loadout_color_count() == 0` when disabled.

- Intent: Close the implementation loop with verification and documentation updates.
- Files or areas touched:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`
- Summary: Replaced the stale June 1 worklog state with the reward ceremony implementation record and captured the verification evidence for both focused and broad Godot runners.
- Verification:
  - `git diff --check -- ...` on the touched source, tests, and worklog files returned only LF/CRLF normalization warnings and no whitespace errors.

## 2026-06-01 16:11:02

<!-- codex-worklog-signature: f5be31f1f4a19f18d8002661ddb0f3e4351a26ef127c05a72e325c846ac4c15b -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts.log
?? app-LTL/resources/UI/charactor/
?? app-LTL/resources/UI/miner/
?? app-LTL/resources/UI/pin/
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-01 16:11:48

<!-- codex-worklog-signature: 122bf424caef5772fa220e7ef495e72821db75e0e5a466c4554ab12392addd2d -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts.log
?? app-LTL/resources/UI/charactor/
?? app-LTL/resources/UI/miner/
?? app-LTL/resources/UI/pin/
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-01 16:40:14

<!-- codex-worklog-signature: 7bf767ddb3b68cec42ffad28040b835a4a1674f63788ef375b56183b5a117ea8 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts.log
?? app-LTL/resources/UI/charactor/
?? app-LTL/resources/UI/miner/
?? app-LTL/resources/UI/pin/
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-01 17:58:21

<!-- codex-worklog-signature: 13e32d5ad80f6c19ad0c02052ff8b27e970b29d560ca3146617a8db00629d917 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts.log
?? app-LTL/resources/UI/charactor/
?? app-LTL/resources/UI/miner/
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-01 17:59:01

<!-- codex-worklog-signature: d804e5426144689eead2626dcead021af42e28ec35c1fd6fcdf0277356e3b2d8 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts.log
?? app-LTL/resources/UI/charactor/
?? app-LTL/resources/UI/miner/
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-01 18:06:58

<!-- codex-worklog-signature: 28ef76448eecfdcd660255619fe57d6d480b37ddd2293b9341aa70204da483f8 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts.log
?? app-LTL/resources/UI/charactor/
?? app-LTL/resources/UI/miner/
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-01 18:42:16

- Intent: Polish the mining-themed reward ceremony after screenshot review showed the excavation lid still clipped, the count reveal still felt like a scene cut, and rarity reveal intensity was still too weak.
- Root cause:
  - The center lid still used a plaque-like aspect ratio instead of the long horizontal mined-tile ratio, so the lower edge looked visually cropped.
  - The count reveal handed off from a static closed lid to a separate open-count composition, which read like a state swap instead of a continuous opening event.
  - The fixed rarity VFX profiles did not push enough beams, shockwaves, or screen wash to make even common reveals legible as reveals.
- Production changes:
  - Refactored `app-LTL/src/ui/RewardRevealOverlay.gd` so the center lid layout comes from `center_lid_layout_model()` and `_excavation_lid_aspect_ratio()`, keeping the wide tile proportions intact.
  - Replaced the old count-lock composition with `count_burst_animation_model()` and `_draw_count_burst_animation()`, which split the lid into left/right doors and emit orbs from the seam as the count appears.
  - Increased `reveal_visual_profile()` intensity across all rarities and expanded `_draw_rarity_burst()` with larger screen wash, layered shockwaves, denser beams, and more sparks/embers.
  - Extended `app-LTL/tests/test_ui_read_models.gd` so the lid aspect, burst continuity, and stronger rarity thresholds are contract-protected.
- Verification:
  - RED first: the focused reward-ceremony runner failed on the new lid-layout, burst-animation, and rarity-profile expectations before the implementation.
  - GREEN: `tests/run_reward_ceremony_contract.gd` printed `REWARD_CEREMONY_CONTRACT_OK`.
  - Broad verification: `tests/run_test_ui_read_models.gd` printed `UI_READ_MODEL_TESTS_OK` and `tests/godot_contract_runner.gd` printed `GODOT_CONTRACTS_OK`.
  - Diff hygiene: `git diff --check` returned only existing LF/CRLF normalization warnings and no whitespace errors.

## 2026-06-01 19:27:32

<!-- codex-worklog-signature: 99935ac7fed046858762ffc21d2da6ec34d27e69cf569e3854ec562db949b3a7 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_node_map_scene_smoke.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts.log
?? app-LTL/resources/UI/charactor/
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-01 19:29:20

<!-- codex-worklog-signature: 79071a932c4df20eab289fa73616bd51778e7407f57dbe0001e51dd2d0678f8a -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_node_map_scene_smoke.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts.log
?? app-LTL/resources/UI/charactor/
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-01 21:45:28

<!-- codex-worklog-signature: b278e99d9ec6e52957435d3b700046c44c0d2a915547d459aabc8a7ce8d69de8 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_node_map_scene_smoke.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts.log
?? app-LTL/main-start-probe.log
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-01 21:46:19

<!-- codex-worklog-signature: 87f72688e5e07af8eafd6d9c7a20b439d9e542bff5bb9d6536e6c437414d5cd2 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_node_map_scene_smoke.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts.log
?? app-LTL/main-start-probe-noquit.log
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-01 21:46:48

<!-- codex-worklog-signature: dd839eb4bfaaae8fdedc160084c1aa1e85db4d9ddaddb499b4f40cbf2a39f769 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_node_map_scene_smoke.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts.log
?? app-LTL/main-start-probe-noquit.log
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-01 21:47:36

<!-- codex-worklog-signature: 379c4de21465c05aeb4576a725e72fe4f571f2da24ba34214df9df720678855b -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_node_map_scene_smoke.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts.log
?? app-LTL/main-start-direct-probe.log
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-01 21:47:36

<!-- codex-worklog-signature: 379c4de21465c05aeb4576a725e72fe4f571f2da24ba34214df9df720678855b -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_node_map_scene_smoke.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts.log
?? app-LTL/main-start-direct-probe.log
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-01 21:48:35

<!-- codex-worklog-signature: 1a4f1bb9ccee0ee02c501e718ff60c7904abd0b526b1e2cebd6cddac178b7de3 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_node_map_scene_smoke.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts.log
?? app-LTL/main-start-direct-probe.log
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-01 22:16:22

<!-- codex-worklog-signature: 2f8e2c21bfef26c22dac18186cfa1f722baec51943abb1642db98d792699ac39 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_node_map_scene_smoke.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts-green.log
?? app-LTL/godot-contracts.log
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-01 22:35 Silent Combat-Start Freeze Investigation

- Intent: Trace the remaining `전투 시작` freeze/exit after the earlier `_drop_mouse_over` fix removed the visible engine error.
- Files or areas touched:
  - `app-LTL/src/ui/BackpackUI.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-01.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-01.md`
- Summary:
  - Reproduced the freeze headlessly with the real `Main.tscn` flow by running the start button path without `--quit`; the process consistently stopped after combat render and before the next frame.
  - Isolated the stall to the backpack pin overlay subsystem by proving that a control probe with pin overlays disabled advanced into combat normally.
  - Fixed the loop in `BackpackUI._layout_pin_overlays()` by stopping the same-idle `call_deferred("_layout_pin_overlays")` retry when the combat pin gutter margin changes; resize notifications already trigger the follow-up layout pass.
  - Removed temporary one-off probe scripts after the root cause was confirmed so the regression remains covered by the reusable contract runner instead of ad hoc diagnostics.
- Plan impact: Confirmed the silent shutdown was a deferred combat-entry layout loop, not controller state or preview-controller data corruption.
- Verification status:
  - `tests/run_main_start_flow_contract.gd`: `MAIN_START_FLOW_CONTRACT_OK`
  - `tests/run_start_option_contract.gd`: `START_OPTION_CONTRACT_OK`
  - `tests/run_test_ui_read_models.gd`: `UI_READ_MODEL_TESTS_OK`
  - `tests/godot_contract_runner.gd`: `GODOT_CONTRACTS_OK`
  - `git diff --check`: no whitespace errors; existing LF/CRLF warnings remain

## 2026-06-01 22:16:41

<!-- codex-worklog-signature: 7cd60cc4694b283386555aaa027e38e03d8deb40a7144a95571b3a12aa0ded11 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_node_map_scene_smoke.gd
 M app-LTL/tests/test_ui_read_models.gd
 M docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md
MM docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md
 M docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md
M  docs/mockups/render-terrain-panel-before-after.ps1
M  docs/mockups/terrain-panel-before-after-render.png
 M docs/source-map.md
?? .superpowers/
?? app-LTL/backpack-ui-compile-contract-run.log
?? app-LTL/backpack-ui-compile-contract.log
?? app-LTL/godot-contracts-green.log
?? app-LTL/godot-contracts.log
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.
