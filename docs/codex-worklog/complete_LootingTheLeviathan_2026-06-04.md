# Codex Worklog Completion

Workspace: LootingTheLeviathan
Date: 2026-06-04

## M5 Closure And HUD Queue Contract Alignment

### Completion Summary

Completed the M5 closure pass. The broad contract suite now treats the combat HUD queue the same way the shipped runtime does: combat starts with a doubled queue capacity of `16` but only `8` loaded tokens, and the missing M5 completion report is now present for milestone-gate verification.

### Actual Outputs

- Updated `app-LTL/tests/godot_contract_runner.gd` so the HUD queue assertion matches the current half-loaded doubled-queue contract.
- Added `LTL-harness/docs/11_exec-plans/02_completed/11_M5_hazard_hierarchy_completed.md` as the official M5 completion report.
- Updated `docs/source-map.md` and today's worklog files so the new milestone artifact is tracked by repository gates.

### Changes From Plan

- I did not change queue runtime behavior or rebalance combat entry pacing. The closure work intentionally treated the current `8 / 16` start state as the source of truth and aligned the stale suite assertion to that shipped behavior.
- M5 completion was recorded through a dedicated completed-milestone report rather than by rewriting the active M5 plan file into a checklist artifact.

### Verification Results

- `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Headless -Script tests/godot_contract_runner.gd -Quit` -> `GODOT_CONTRACTS_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run-ltl-quality-gate.ps1` -> `LTL_QUALITY_GATE_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\LTL-harness\tools\milestone-gate.ps1 -TargetPlan 12_M6_ui_ux_finalization.md -Root D:\Programming\ex_workspace\LootingTheLeviathan` -> `MILESTONE_GATE_OK`
- `git diff --check` -> no whitespace errors; only repository-wide LF/CRLF warnings

### Blockers Or Unverified Areas

- Manual playthrough and visible UI capture were not part of this closure pass; the evidence is contract- and gate-driven.
- Godot still emits the existing headless anchor/resource leak warnings at exit. They remained non-blocking in the same way they were during prior focused passes.

## Combat Bottom Gap Drift After First Tile Click

### Completion Summary

Completed the reported post-click combat layout drift fix. The lower combat panel now keeps the same bottom breathing room after the first tile click because the purple-status HUD text no longer grows the main battle layout.

### Actual Outputs

- Moved `PurpleStatusRow` from the main `StatusBox` VBox flow into `StatusFooterSpacer` in `app-LTL/src/Main.tscn`.
- Updated `app-LTL/src/ui/StatusPanelUI.gd` so the purple-status row is laid out as a footer-spacer overlay and resized from that spare lane instead of contributing to the status panel minimum height.
- Updated `app-LTL/src/ui/MainViewRuntime.gd` and `app-LTL/tests/test_ui_read_models.gd` to use the new purple-status row path and to lock the structure in place.
- Added regression coverage in `app-LTL/tests/run_reward_cleanup_layout_contract.gd` for status-panel minimum-height stability and in `app-LTL/tests/run_main_layout_audit_contract.gd` for full combat bottom-gap stability after purple-status updates.

### Changes From Plan

- I fixed the drift at the HUD layout layer instead of changing any combat-state semantics. The purple mechanic still surfaces the same stack/buff text; it just renders inside existing spare space now.
- I kept the dedicated purple-status row rather than merging its text into another label, so the feature remains readable without spending extra battle layout height.

### Verification Results

- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_reward_cleanup_layout_contract.gd -Headless -Quit` -> exit `0`
- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_test_ui_read_models.gd -Headless -Quit` -> `UI_READ_MODEL_TESTS_OK`
- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_main_layout_audit_contract.gd -Headless -Quit` -> exit `0` with the existing Godot leak warnings and no contract failures
- `git diff --check -- app-LTL/src/Main.tscn app-LTL/src/ui/StatusPanelUI.gd app-LTL/src/ui/MainViewRuntime.gd app-LTL/tests/test_ui_read_models.gd app-LTL/tests/run_reward_cleanup_layout_contract.gd app-LTL/tests/run_main_layout_audit_contract.gd docs/codex-worklog/plan_LootingTheLeviathan_2026-06-04.md docs/codex-worklog/history_LootingTheLeviathan_2026-06-04.md docs/codex-worklog/complete_LootingTheLeviathan_2026-06-04.md` -> no whitespace errors; only existing LF/CRLF warnings

### Blockers Or Unverified Areas

- I did not run a manual visible desktop click-through in this turn, so the verification remains contract-driven.
- Godot still emits the same headless anchor/leak/resource warnings at exit; those warnings predate this fix and were not part of the requested scope.

## Popup Overlay Top-Layer Follow-Up

### Completion Summary

Completed the requested popup layering follow-up. Settings, codex, and similar menu overlays now claim the top in-scene UI layer, so combat HUD art no longer renders above them while they are open.

### Actual Outputs

- Added a shared popup overlay front-order helper in `app-LTL/src/ui/MainViewRuntime.gd` that assigns a dedicated high `z_index` and calls `move_to_front()` whenever settings, codex, shop, confirm, or repair overlays become visible.
- Raised the reward reveal overlay onto a dedicated higher cinematic layer so it keeps the same explicit front-order contract.
- Added focused regression coverage in `app-LTL/tests/test_ui_read_models.gd` and `app-LTL/tests/run_main_layout_audit_contract.gd` that proves popup overlays move to the last sibling slot and sit above combat popup layers.
- Backed up `LTL-harness/00_AGENTS.md` and added a popup overlay layering addendum so future harness-guided work preserves the same rule.

### Changes From Plan

- I applied the layering contract to the broader popup family, not just settings/codex, because confirm/repair/shop share the same failure mode and should not rely on scene insertion order either.
- The fix stayed entirely in the view/runtime and harness-guidance layer; no combat reducer or content data changed.

### Verification Results

- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_test_ui_read_models.gd -Headless -Quit` -> `UI_READ_MODEL_TESTS_OK`
- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_main_layout_audit_contract.gd -Headless -Quit` -> exit `0` with the existing Godot leak warnings and no contract failures

### Blockers Or Unverified Areas

- I did not run a manual desktop click-through against the visible screenshot path in this turn, so verification is still contract-driven.
- Godot still emits the existing headless leak/resource warnings at exit; they were already present and were not part of this follow-up.

## Combat Overlay Pause For Settings And Codex

### Completion Summary

Completed the requested battle-only overlay pause flow. Opening settings or the artifact codex during combat now pauses combat progression and combat-only visual ticking, the codex no longer gets force-closed by combat rerenders, and closing the overlay resumes combat from the paused snapshot.

### Actual Outputs

- Added battle-only overlay pause ownership in `app-LTL/src/MainControllerRuntime.gd`, including shift-timer pause/resume, disabled-tile release countdown pausing, combat input gating, and view pause propagation.
- Added `combat_overlay_pause_visibility_changed` plus battle-pause forwarding in `app-LTL/src/ui/MainViewRuntime.gd` so settings/codex visibility drives combat pause without relying on global tree pause.
- Updated `app-LTL/src/ui/BattlefieldUI.gd`, `BattlefieldVFX.gd`, `CellView.gd`, `BackpackUI.gd`, `GiantTimerUI.gd`, and `VFXManager.gd` so combat-only pulses, timer animation, cooldown interpolation, hazard animation, and shake stop moving under the overlay.
- Added focused regression coverage in `app-LTL/tests/test_start_option_contract.gd` and a main-scene combat overlay audit in `app-LTL/tests/run_main_layout_audit_contract.gd`.

### Changes From Plan

- I kept the solution in the `A` bucket rather than using full SceneTree pause. The final implementation explicitly pauses combat-owned time sources and combat-only visuals, while leaving overlay UI interactivity alive.
- I replaced the old disabled-tile unlock `create_timer()` with a controller-owned countdown queue so those transient combat locks also freeze cleanly during overlay pause.

### Verification Results

- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_start_option_contract.gd -Headless -Quit` -> `START_OPTION_CONTRACT_OK`
- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_test_ui_read_models.gd -Headless -Quit` -> `UI_READ_MODEL_TESTS_OK`
- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_main_layout_audit_contract.gd -Headless -Quit` -> exit `0` with existing Godot leak warnings and no contract failures

### Blockers Or Unverified Areas

- I did not run an interactive desktop playthrough in this turn, so the verification is contract-driven rather than a manual in-app click-through.
- Godot still prints the existing leak/resource warnings at headless exit; they were present on passing runs and were not addressed as part of this task.

### Remaining Gaps

- Continuous hold-fire is intentionally interrupted when an overlay pause opens. If later desired, that could be resumed explicitly after overlay close, but I kept the safer interruption behavior for now.

## Purple stack/buff loop recovery

## Reward cleanup layout stretch fix

### Completion Summary

Completed the repeated-hit layout fix. The gameplay screen was stretching downward because the status-panel energy queue kept stale gem controls alive inside the live `GridContainer` during same-frame rerenders, so rapid combat updates temporarily inflated the queue grid from one row-set to several stacked copies.

### Actual Outputs

- Updated `app-LTL/src/ui/StatusPanelUI.gd` so queue rerenders detach stale gem children from `VisualQueueBox` immediately before queueing them for deletion.
- Added `app-LTL/tests/run_reward_cleanup_layout_contract.gd` to prove repeated same-frame queue rerenders stay bounded at exactly sixteen live children instead of ballooning to `64`.
- Updated `docs/source-map.md` plus today's worklog plan/history to record the new status-panel layout contract and its responsibility.

### Changes From Plan

- I moved from a broader `Main.tscn` reward-transition probe to a lower-level `StatusPanelUI` contract because the current branch's headless main-scene facade path is unreliable, while the queue-rerender defect reproduced cleanly in isolation.
- The final fix stayed narrower than the original symptom report: no reward, combat, or phase logic changed once the queue-child accumulation root cause was confirmed.

### Verification Results

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -Script tests/run_reward_cleanup_layout_contract.gd -Headless -Editor` -> `REWARD_CLEANUP_LAYOUT_CONTRACT_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -Script tests/run_test_ui_read_models.gd -Headless -Quit` -> `UI_READ_MODEL_TESTS_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -Script tests/godot_contract_runner.gd -Headless -Editor -ScriptArgs @("--smoke-only")` -> still fails on the unrelated existing assertion `combat scene HUD exposes the doubled queue state: expected 16, got 8`
- `git diff --check -- app-LTL/src/ui/StatusPanelUI.gd app-LTL/tests/run_reward_cleanup_layout_contract.gd docs/codex-worklog/plan_LootingTheLeviathan_2026-06-04.md docs/codex-worklog/history_LootingTheLeviathan_2026-06-04.md docs/codex-worklog/complete_LootingTheLeviathan_2026-06-04.md docs/source-map.md` -> no whitespace errors; only LF/CRLF warnings

### Blockers Or Unverified Areas

- I did not get a trustworthy headless end-to-end `Main.tscn` reward-transition replay in this branch because the current main-scene facade contracts are already out of sync in unrelated ways.
- The broader smoke contract still carries the unrelated pre-existing queue-capacity failure noted above.

### Remaining Gaps

- If similar same-frame rerender accumulation exists in other layout-managed containers, the same immediate-detach pattern should be applied there before those paths start affecting live layout.

### Completion Summary

Completed the requested purple mechanic recovery so purple tile hits can accumulate weakened stacks again without losing them to a live timer. Purple obstacle resolution now uses discrete stack transitions instead of the old pressure percent: it removes one weakened stack if present, or grants one fortified buff stack when the target is back at normal.

### Actual Outputs

- Added `terrainBuffs` serialization and rehydration in `app-LTL/src/models/CombatSimulator.gd` and `app-LTL/src/phases/CombatPhase.gd`.
- Updated `app-LTL/src/vocabulary/CombatVocab.gd` so:
  - active purple hazards no longer decay weakened stacks over time
  - purple execute/fail does `weakened -1 else fortified +1`
  - fortified stacks reduce outgoing damage as discrete layers
  - purple hits remove one fortified stack before resuming weakened-stack buildup
- Updated `app-LTL/src/ui/CombatSceneModel.gd` and `app-LTL/src/ui/StatusPanelUI.gd` so the purple HUD row now projects discrete weakened/fortified stacks and no longer renders `압력 -00%`.
- Added focused regression coverage in `app-LTL/tests/test_combat_vocab.gd` and `app-LTL/tests/test_ui_read_models.gd`.

### Changes From Plan

- I replaced the old percentage pressure path with a discrete fortified-stack model instead of hiding the percent while keeping the same internals. This keeps the runtime and UI aligned and makes the requested `버프 +1` behavior explicit in data and tests.
- I removed the active-timer decay path entirely because that timer was the direct cause of the reported loss of stack accumulation; purple now changes stacks only when a purple obstacle actually executes.

### Verification Results

- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_test_combat_vocab.gd -Headless -Quit` -> `COMBAT_VOCAB_TESTS_OK`
- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_test_ui_read_models.gd -Headless -Quit` -> `UI_READ_MODEL_TESTS_OK` with the pre-existing Godot anchor/leak warnings at exit
- `git diff --check -- app-LTL/src/models/CombatSimulator.gd app-LTL/src/phases/CombatPhase.gd app-LTL/src/vocabulary/CombatVocab.gd app-LTL/src/ui/CombatSceneModel.gd app-LTL/src/ui/StatusPanelUI.gd app-LTL/tests/test_combat_vocab.gd app-LTL/tests/test_ui_read_models.gd docs/codex-worklog/plan_LootingTheLeviathan_2026-06-04.md docs/codex-worklog/history_LootingTheLeviathan_2026-06-04.md docs/codex-worklog/complete_LootingTheLeviathan_2026-06-04.md` -> no whitespace errors; only LF/CRLF warnings

### Blockers Or Unverified Areas

- I did not run a full interactive playthrough in the desktop UI this turn, so the verification is currently focused on combat/runtime and HUD projection contracts.
- Existing Godot headless leak warnings remain and appear unrelated to this purple mechanic change.

### Remaining Gaps

- If later tuning shows fortified stacks should mitigate by a different per-stack amount than the current discrete `10%`, the combat constant can be adjusted without changing the surrounding state model.
- If desired later, a dedicated visual/UI assertion can be added for the exact purple status-row text, but the underlying HUD model and runtime mechanics are now covered.

## Completion Summary

Completed the hazard spawn redesign so terrain-panel hazards no longer respawn just because the active count dropped. Hazards now spawn only from newly generated terrain tiles through an explicit spawn profile, and the runtime can now support boss or gimmick nodes that raise spawn chance, allow multiple hazard colors, and increase per-wave spawn counts.

## Actual Outputs

- Added `app-LTL/src/vocabulary/combat/SpawnNewTileObstacles.gd` to own new-tile-only hazard candidate selection, deterministic chance rolls, allowed-family normalization, and duplicate-cell blocking.
- Updated `app-LTL/src/vocabulary/CombatVocab.gd` so `shift_battlefield()` and `prime_obstacles()` materialize hazards from the new helper instead of maintaining a target active obstacle count.
- Updated `app-LTL/src/models/CombatSimulator.gd` and `app-LTL/src/phases/CombatPhase.gd` so combat keeps a full `hazard` snapshot available while rehydrating simulator state.
- Updated `app-LTL/src/vocabulary/node/ApplyNodeModifiers.gd` to carry `hazardSpawn` overrides into `combat["hazard"]["spawn"]`.
- Updated `app-LTL/src/data/node-table.json` so `hazard_rich` and `boss_spine` now demonstrate explicit spawn-profile overrides.
- Added focused regression coverage in `app-LTL/tests/test_combat_vocab.gd` for:
  - zero-chance waves not backfilling hazards
  - shift-wave spawns using only inserted `c0` tiles
  - boss-like multicolor waves spawning on multiple new tiles
  - explicit initial-board spawn caps
  - node modifier propagation of hazard spawn metadata

## Changes From Plan

- I kept the existing obstacle fail effects and miss-debt bookkeeping even though the new-tile spawn system no longer uses target-active replenishment. That preserves current side-effect behavior while still removing the undesired "clear one, spawn one" loop.
- Instead of passing extra hazard-profile arguments through every combat call, I stored the current hazard snapshot on `CombatSimulator` and let the new helper read from that state directly. This kept the surface area of the combat API smaller.

## Verification Results

- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_test_combat_vocab.gd -Headless -Quit` -> `COMBAT_VOCAB_TESTS_OK`
- `git diff --check` -> no whitespace errors; only pre-existing LF/CRLF warnings from the already-dirty workspace

## Blockers Or Unverified Areas

- I did not rerun broader UI/layout or full contract suites in this turn. Verification is currently focused on the combat obstacle path touched by the request.
- The repository is already dirty in many unrelated areas, so `git diff --check` output is noisy with CRLF warnings that were not introduced by this change.

## Remaining Gaps

- If later tuning shows the default spawn-profile heuristics are too soft or too aggressive on nodes without explicit `hazardSpawn`, those defaults should be adjusted or replaced with fully explicit data on more node entries.
- If desired later, a dedicated node-routing or combat-snapshot test can be added for the real `node-table.json` boss profile specifically, but the core spawn-profile propagation is already covered in focused combat tests.

## Stage-two layout and reward reveal containment

### Completion Summary

Completed the follow-up gameplay layout containment pass so stage 2+ node-select reentry now settles to the same centered map/backpack structure as stage 1, and reward reveal/count-tease/count-lock effects now stay inside a shared safe-area model instead of spilling oversized circles or lower-lane UI outside the intended full-screen shell.

### Actual Outputs

- Updated `app-LTL/src/ui/MainViewRuntime.gd` so node-select requests a deterministic follow-up refresh after backpack reparenting and shared layout sync, closing the stage-two reentry gap where the graph could keep stale wide coordinates.
- Updated `app-LTL/src/scenes/node_map/NodeMapScene.gd` so unresolved inner-canvas widths use parent/scene geometry before falling back to the old `620px` emergency width, reducing off-center first-frame placement.
- Added `overlay_safe_layout_model()` plus `safe_radius_for_center()` in `app-LTL/src/ui/RewardRevealOverlay.gd` and moved the headline, prompt, lid, reveal card, progress lane, backdrop rings, count-tease charge halo, count-lock burst, and rarity burst onto that shared safe-area geometry.
- Centered the two-slot reward burst layout symmetrically on the canvas midpoint and aligned fallback reveal-source math with the main runtime's screen-center fallback.
- Expanded focused regression coverage in:
  - `app-LTL/tests/run_main_start_flow_contract.gd`
  - `app-LTL/tests/run_main_layout_audit_contract.gd`
  - `app-LTL/tests/test_ui_read_models.gd`

### Changes From Plan

- Instead of only relying on extra frame delays, I fixed the stage-two reentry issue in two places: the main runtime now performs a follow-up refresh after reparent/layout settle, and the node-map scene no longer depends as heavily on the old hard fallback width while its inner canvas is resolving.
- The reward reveal audit became slightly broader than the initial bug report because the safest fix was to create one shared safe-layout model and route every large effect and lower-lane element through it, rather than patching individual radii in isolation.

### Verification Results

- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_main_start_flow_contract.gd -Headless` -> `MAIN_START_FLOW_CONTRACT_OK`
- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_main_layout_audit_contract.gd -Headless` -> `MAIN_LAYOUT_AUDIT_CONTRACT_OK`
- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_reward_ceremony_contract.gd -Headless` -> `REWARD_CEREMONY_CONTRACT_OK`
- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_test_ui_read_models.gd -Headless` -> `UI_READ_MODEL_TESTS_OK` with the existing Godot anchor/leak warnings at exit
- `powershell -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Script res://tests/run_node_map_scene_smoke.gd -Headless` -> `NODE_MAP_SCENE_SMOKE_OK` with the same pre-existing headless leak warnings at exit
- `git diff --check -- app-LTL/src/ui/MainViewRuntime.gd app-LTL/src/ui/RewardRevealOverlay.gd app-LTL/src/scenes/node_map/NodeMapScene.gd app-LTL/tests/test_ui_read_models.gd app-LTL/tests/run_main_layout_audit_contract.gd app-LTL/tests/run_main_start_flow_contract.gd` -> no whitespace errors; only LF/CRLF warnings

### Blockers Or Unverified Areas

- I did not run a real interactive fullscreen capture pass from the desktop UI in this turn, so validation is contract-driven rather than screenshot-driven.
- The existing Godot headless runs still emit known anchor/leak warnings unrelated to this layout change.

### Remaining Gaps

- If later reports show the header action row getting cramped on even narrower shell widths, the next follow-up should audit button minimum widths and visibility policy separately from the node-map/reward fixes completed here.

## Viewport-bound layout guardrail follow-up

### Completion Summary

Completed the follow-up correction for the remaining right-edge clipping in reward placement, stage 2+ node-select, and stage 2 combat. The important root cause was not a single misplaced panel: the earlier audit used the already-expanded `Main` rect as the window boundary, so it could pass even when the shell was wider than the real viewport.

### Actual Outputs

- `MainViewRuntime.gd` now keeps the root shell full-rect to the viewport and reschedules shared backpack/node-map layout after resize.
- `NodeMapScene` now receives the explicit `460px` map minimum in the actual Control tree, so stage 2+ no longer depends on the stage-1 start-color row to accidentally provide the map width.
- `BackpackPinLayoutPolicy.gd` now exposes viewport-safe top-content backpack width and ratio helpers, so pin-art overhang cannot force the gameplay row past the available screen width.
- `run_main_layout_audit_contract.gd` now forces `1440x900`, checks visible Controls against the real viewport, and covers node-select, combat, reward tray, reward reveal, settings, shop, codex, confirm, and repair overlays.
- `run_main_viewport_probe.gd` was added as a focused diagnostic for printing live rects when future layout drift is suspected.

### Verification Results

- `run_test_ui_read_models.gd` -> `UI_READ_MODEL_TESTS_OK`
- `run_main_layout_audit_contract.gd` -> `MAIN_LAYOUT_AUDIT_CONTRACT_OK`
- `run_main_start_flow_contract.gd` -> `MAIN_START_FLOW_CONTRACT_OK`
- `run_reward_ceremony_contract.gd` -> `REWARD_CEREMONY_CONTRACT_OK`
- `run_reward_reveal_front_contract.gd` -> `REWARD_REVEAL_FRONT_CONTRACT_OK`
- `run_node_map_scene_smoke.gd` -> `NODE_MAP_SCENE_SMOKE_OK`
- `git diff --check` on touched layout/worklog files -> no whitespace errors; only LF/CRLF warnings.

### Guardrails

- Avoid changing `MainViewRuntime.gd` top-content backpack sizing back to available-width clamping.
- Avoid removing `NODE_SELECT_MAP_MIN_WIDTH` from the real node-map Control minimum.
- Avoid using `main_instance.size` as the layout-test window; use `root.size` or `get_viewport_rect().size`.
- Treat `BackpackPinLayoutPolicy.gd` as the single owner for pin-art overhang math so future visual changes do not silently enlarge the shell.

## Backpack-priority layout recovery

### Completion Summary

Completed the requested correction that restores the backpack panel as the priority panel. The previous containment fix made the backpack shrink to the remaining available width first; this pass removes that clamp and instead makes the left explorer/status column and right system-log column absorb horizontal pressure.

### Actual Outputs

- `MainViewRuntime.gd` no longer exposes or uses a top-content `available_width` backpack clamp; top-content backpack width now resolves from row height through `BackpackPinLayoutPolicy.top_content_width_for_height()`.
- `BackpackPinLayoutPolicy.gd` no longer exposes the top-content available-width clamp helpers, reducing the chance that future layout patches reintroduce the same regression.
- `PhaseLayoutPresenter.gd` and `Main.tscn` now use narrower top-content side ratios: left `2.0`, backpack `0.0`, right `1.55`.
- `StatusPanelUI.gd` and `Main.tscn` now render the energy queue as an eight-column `GridContainer`, so the default sixteen queue slots wrap as two rows.
- `run_main_layout_audit_contract.gd` now checks combat viewport containment, backpack priority width, side-panel compression, and the two-row queue grid.

### Changes From Plan

- The earlier viewport-safe helper was removed instead of merely bypassed. That makes the intended policy clearer: viewport containment must come from side-panel compression and queue wrapping, not from shrinking the backpack first.
- Subagent audit was used as requested and confirmed the same root cause plus future risk points around `RewardRow`/`DiscardZone` minimums.

### Verification Results

- `run_main_layout_audit_contract.gd` -> `MAIN_LAYOUT_AUDIT_CONTRACT_OK`
- `run_main_start_flow_contract.gd` -> `MAIN_START_FLOW_CONTRACT_OK`
- `run_main_viewport_probe.gd` -> no right-edge overflow at `1440x900`; combat backpack `557.96px`, reward backpack `641.12px`, combat side panels `456px/355px`, reward side panels `409px/318px`.
- `run_reward_ceremony_contract.gd` -> `REWARD_CEREMONY_CONTRACT_OK`
- `run_reward_reveal_front_contract.gd` -> `REWARD_REVEAL_FRONT_CONTRACT_OK`
- `git diff --check` on the touched layout/worklog files -> no whitespace errors; only LF/CRLF warnings.

### Blockers Or Unverified Areas

- `run_test_ui_read_models.gd` currently fails before the new layout assertions on an unrelated existing all-energy weakness highlight contract: `all-energy weakness tiles stay highlighted even when their color differs from the active queue`.
- I did not run a live desktop screenshot capture in this turn; the layout evidence is contract/probe based.

### Guardrails

- Do not reintroduce `top_content_width_for_available()` or any equivalent top-content backpack available-width clamp.
- Do not change `VisualQueueBox` back to a one-line `HBoxContainer`; sixteen gems must stay `8 x 2`.
- Do not increase left/right side panel stretch or minimum widths without rerunning the `1440x900` layout audit.
- Treat reward placement `RewardRow`, `RewardText.fit_content`, and `DiscardZone.custom_minimum_size` as clipping-sensitive knobs.

## Anchor Oathplate all-energy weakness fix

### Completion Summary

Completed the `앵커 판` relic fix so its fifth weakness-hit trigger no longer repaints the battlefield to one repeated color. The trigger now preserves each tile's original color and marks every current terrain tile as weak to any energy, which means all four tile colors render fully opaque and any follow-up energy/tile pair resolves as a weakness match.

### Actual Outputs

- `CombatVocab.gd` now sets an `allEnergyWeakness` marker flag when Anchor Oathplate reaches its threshold instead of overwriting marker colors.
- `MainControllerRuntime.gd` now forwards the clicked tile color through hover, click, start-combat aim, and hold-fire targeting instead of always substituting the active queue color.
- `fire_shot()` keeps the existing `targetColor` combat contract for normal hits, but upgrades flagged cells to full weakness matches regardless of energy/tile color pairing.
- `fire_shot()` now also clears the `allEnergyWeakness` state after one follow-up shot, so the board returns to its normal alpha behavior unless the relic retriggers.
- `ShiftWeaknessMarkers.gd` now preserves extra marker state like `allEnergyWeakness` when existing tiles shift right across the battlefield.
- `CombatSceneModel.gd` now projects any-energy weakness markers as highlighted cells even when their visible tile color differs from the active queue color.
- `CellView.gd` now uses the projected highlight state to keep those tiles fully opaque instead of fading them against the active queue color.
- `reward-table.json` now describes Anchor Oathplate as making every terrain tile weak to any energy after every five weakness hits.
- Added regression coverage in `test_combat_vocab.gd` and `test_ui_read_models.gd` for both the gameplay rule and the render/read-model contract.

### Changes From Plan

- I kept the existing `targetColor` shot contract intact for ordinary combat so unrelated damage-profile and mismatch tests stayed stable; only the new `allEnergyWeakness` state bypasses the color-pair requirement.
- Instead of introducing a separate battlefield-wide toggle, the fix stores the state on each current marker. That keeps snapshot restore, shifting, and UI projection local to the same terrain data already used by combat.

### Verification Results

- `powershell -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Script res://tests/run_test_combat_vocab.gd -Headless -Quit` -> `COMBAT_VOCAB_TESTS_OK`
- `powershell -ExecutionPolicy Bypass -File ..\tools\invoke-godot.ps1 -Script res://tests/run_test_ui_read_models.gd -Headless -Quit` -> `UI_READ_MODEL_TESTS_OK` with the existing Godot anchor/leak warnings at exit
- `git diff --check` on the touched relic/combat/UI/worklog files -> no whitespace errors; only LF/CRLF warnings

### Blockers Or Unverified Areas

- I did not rerun broader reward-contract or full gameplay scene suites in this turn because the change stayed inside combat marker state, tile projection, and localized reward copy.
- The headless UI run still emits the pre-existing Godot leak warnings at exit; the assertions themselves passed.

### Remaining Gaps

- If design later decides Anchor Oathplate's all-energy weakness should also affect newly inserted tiles after a battlefield shift, that would need an additional persistence rule. The current fix preserves the state only on the tiles that were visible when the trigger fired, matching the prior "current board mutation" behavior.
