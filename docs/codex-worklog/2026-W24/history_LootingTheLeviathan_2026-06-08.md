# Codex Worklog History

Workspace: LootingTheLeviathan
Date: 2026-06-08

## 2026-06-08 defeat sprite extraction kickoff

- Intent: Split the provided defeat animation atlas into reusable frame PNGs without the white separator gutters.
- Files or areas touched:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
  - Discovery against `C:/Users/YoungSoon/Downloads/defeat1_charator1_bg.png`
  - Target asset area `app-LTL/resources/charactor/`
- Summary:
  - Confirmed the source atlas size is `1536x1024` and the visible layout is `7` columns by `5` rows.
  - Detected the white separator bands directly from pixel data instead of assuming an even mathematical grid, which avoids carrying the white gutters into the exported frames.
  - Identified that the extracted cells vary slightly in raw crop size, so the export path will normalize them onto a common output canvas for easier sprite use.
- Plan impact: Replaced the previous June 8 active plan entry with this asset extraction request before writing any generated files.
- Verification status: Source analysis only so far; generated outputs have not been written yet.

## 2026-06-08 defeat sprite export

- Intent: Materialize the analyzed defeat atlas as reusable project assets with consistent frame dimensions.
- Files or areas touched:
  - `app-LTL/resources/charactor/defeat/`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-08.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-08.md`
- Summary:
  - Created `app-LTL/resources/charactor/defeat/` and exported `35` row-major frame PNGs named `defeat_01.png` through `defeat_35.png`.
  - Normalized every frame onto a common `268x206` canvas so the output set has uniform dimensions even though the source atlas cells vary slightly.
  - Wrote a companion `defeat_sheet.png` laid out in the original `7x5` order for quick visual inspection after removing the white separator gutters.
  - Cleaned bright edge remnants during export so only a few intentional interior highlight pixels remain above the white-threshold scan.
- Plan impact: The implementation matched the current plan; no further scope change was needed.
- Verification status:
  - `generated_frames=35`
  - `defeat_01=268x206`
  - `defeat_35=268x206`
  - `sheet=1876x1030`
  - Near-white pixel scan after export reports only `1` highlight pixel in `defeat_17.png`, `2` highlight pixels in `defeat_20.png`, and the same `3` pixels in `defeat_sheet.png`; these are interior art highlights rather than border gutters.

## 2026-06-08 reward claim runtime implementation kickoff

- Intent: Replace the live reward tray strip with the approved M6 reward-claim wireframe during `reward_loot` tray review.
- Files or areas touched:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
  - Discovery across `docs/mockups/m6-reward-claim-wireframe.html`, `app-LTL/src/Main.tscn`, `app-LTL/src/ui/MainViewRuntime.gd`, `app-LTL/src/MainControllerRuntime.gd`, `app-LTL/src/ui/read_models/RewardReadModel.gd`, and focused layout/read-model contracts.
- Summary:
  - Confirmed that the runtime already uses the new reward ceremony step flow, but `tray_review` still falls back to the old `RichTextLabel + discard panel` reward tray.
  - Verified that the approved mockup expects a click-to-inspect reward card column, a central backpack placement workspace, a fixed inspector panel, and separate discard and claim regions.
  - Identified `RewardReadModel.project_tray()`, `Main.tscn` reward panel structure, and `MainViewRuntime` shared-backpack reparenting as the main implementation surfaces.
- Plan impact: Replaced the stale June 8 localization plan with the active reward-claim implementation scope before editing production files.
- Verification status: Discovery only so far; fresh reward ceremony and layout contract runs have not started yet for this task.

## 2026-06-08 reward claim runtime implementation

- Intent: Ship the approved reward-claim board into the live `reward_loot` tray-review flow instead of the legacy list strip.
- Files or areas touched:
  - `app-LTL/src/Main.tscn`
  - `app-LTL/src/MainControllerRuntime.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
  - `app-LTL/src/ui/read_models/RewardReadModel.gd`
  - `app-LTL/src/data/i18n/text-en.json`
  - `app-LTL/src/data/i18n/text-ko.json`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `app-LTL/tests/test_start_option_contract.gd`
  - `app-LTL/tests/run_main_layout_audit_contract.gd`
  - `app-LTL/tests/run_main_viewport_probe.gd`
- Summary:
  - Replaced the old reward text strip with a three-zone reward-claim board: reward cards on the left, a shared-backpack workspace in the center, and a fixed inspector plus bottom discard/confirm lanes.
  - Moved reward tray projection to a structured read model so the board consumes cards, inspector facts, footprint data, discard copy, and inline claim copy without relying on a `RichTextLabel` list.
  - Changed tray-review layout rules so the combat sidebars and old bottom action bar hide while the reward board owns the shell, but the active reward-ceremony beats still keep the combat snapshot live until `tray_review`.
  - Updated focused read-model and layout contracts, repaired a few pre-existing corrupted localized literals in `test_ui_read_models.gd`, and refreshed the debug viewport probe to the new node paths.
- Plan impact: The implementation matched the approved wireframe direction, with one practical adjustment in the mode pill copy so the live wording stays honest about the current click-to-place interaction.
- Verification status:
  - Passed: `tests/run_reward_ceremony_contract.gd`
  - Passed: `tests/run_start_option_contract.gd`
  - Checked: `tests/run_main_layout_audit_contract.gd` exited successfully but still emitted Godot shutdown resource-leak warnings (`ObjectDB` / dummy texture storage) that were already outside this reward-board scope.

## 2026-06-08 grim baleen runtime implementation kickoff

- Intent: Move the approved Grim Baleen node-select mockup into the live Godot runtime flow.
- Files or areas touched: `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`, `app-LTL/src/scenes/pages/NodeSelectRuntimePage.*`, `app-LTL/tests/run_main_start_flow_contract.gd`, and `app-LTL/tests/run_main_layout_audit_contract.gd`.
- Summary: Re-checked the live node-select scene/script, scene-model wiring, and focused start-flow/layout contracts so the runtime implementation can proceed with Stage 1 fixed-entry behavior, Stage 2 five-route behavior, a left-side hover panel, and a distinct future `?` preview node.
- Plan impact: Replaced the stale June 8 defeat/localization planning context with the active Grim Baleen runtime implementation scope.
- Verification status: Discovery only so far; fresh contract runs have not started yet for this implementation pass.

## 2026-06-08 10:14:15

<!-- codex-worklog-signature: a40dd21c947fe58109f623852c326e65a526f0b8e92abdb5b98f8b1f323800d7 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
 M app-LTL/src/ui/VFXManager.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/m2_main_scene_contract.ps1
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 Reward Board Scroll Containment Follow-up

- Intent: Finish the remaining reward-board layout break by preventing reward inspector/content minimum heights from resizing the entire root shell after reward or backpack selection.
- Actions:
  - Moved the reward-board body under a dedicated `RewardBoardScroll` host in `app-LTL/src/Main.tscn` so the panel shell stays viewport-bounded while the inner board can overflow safely.
  - Repointed reward-board runtime node bindings and localized path updates in `app-LTL/src/ui/MainViewRuntime.gd`.
  - Updated reward-board contract paths in `app-LTL/tests/test_reward_claim_board_contract.gd`, `app-LTL/tests/test_ui_read_models.gd`, `app-LTL/tests/run_main_layout_audit_contract.gd`, and `app-LTL/tests/run_main_viewport_probe.gd`.
  - Removed the temporary reward-box probe script after the containment fix was verified.
- Verification:
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_claim_board_contract.gd'`
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_inspector_stability_contract.gd'`

## 2026-06-08 reward-board interaction cleanup

- Intent: Remove the remaining reward-board helper copy, stop reward-card hover side effects, and align the shared backpack workspace with drag-and-drop interaction.
- Files or areas touched:
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/ui/BackpackUI.gd`
  - `app-LTL/src/MainControllerRuntime.gd`
  - `app-LTL/src/data/i18n/text-en.json`
  - `app-LTL/src/data/i18n/text-ko.json`
  - `app-LTL/tests/test_reward_claim_board_contract.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
- Summary:
  - Removed the reward-board mode-pill copy and the reward-cloud zone hint copy from both locales, then taught the view to hide those labels when the localized string is blank.
  - Marked reward cards as hover-inert by opting them out of the shared interaction-FX lift behavior, freezing their hover styles, and stopping reward hover signal emission so the cards no longer fight between floating anchors and a stale original position.
  - Added backpack drag-start signaling at the slot layer, mirrored those drag signals through the main view, and changed the reward-board controller flow so backpack clicks inspect the artifact while drag-release now handles move, discard, and cancel/restore.
  - Preserved right-panel detail rendering by feeding the controller's selected backpack artifact into the reward tray read model and refreshing the inspector after placement restores or successful drops.
- Plan impact: Stayed within the updated reward-board interaction cleanup scope; no additional layout or balance work was added.
- Verification:
  - Checked: `tests/run_reward_claim_board_contract.gd` exited `0`; the captured output still only shows the usual Godot shutdown leak warnings.
  - Checked: `tests/run_test_ui_read_models.gd` still fails for unrelated pre-existing localization expectation drift, but the newly added reward-board helper-copy and backpack-drag failure messages no longer appear in the runner output after this pass.
  - Passed: `git diff --check -- app-LTL/src/ui/MainViewRuntime.gd app-LTL/src/ui/BackpackUI.gd app-LTL/src/MainControllerRuntime.gd app-LTL/src/data/i18n/text-en.json app-LTL/src/data/i18n/text-ko.json app-LTL/tests/test_reward_claim_board_contract.gd app-LTL/tests/test_ui_read_models.gd docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`

## 2026-06-08 reward-board inspector persistence follow-up

- Intent: Remove the remaining reward-board "layout break" after reward or backpack clicks by normalizing the artifact data that drives the fixed inspector.
- Files or areas touched:
  - `app-LTL/src/models/Artifact.gd`
  - `app-LTL/src/ui/read_models/RewardReadModel.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `app-LTL/tests/run_reward_inspector_stability_contract.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
- Summary:
  - Traced the persistent broken-looking state to starter backpack artifacts that still projected raw English fallback names like `Purple Starter Drill` and an empty inspector summary after selection.
  - Added localized starter drill/beacon text blocks at artifact creation time so those carried backpack instances keep meaningful name and description data across later phases instead of only at reward-card projection time.
  - Added an inspector-summary fallback to `RewardReadModel` so any artifact that still lacks lore text falls back to effect or primary stat copy rather than leaving the right panel blank.
  - Added focused regression coverage plus a dedicated runner for the two new inspector-stability cases, which keeps this bug verifiable even while the broad UI read-model suite still has unrelated localization drift.
- Plan impact: Stayed within the narrowed reward-board inspector stability scope; no additional backpack placement or board-size tuning was added in this pass.
- Verification:
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_inspector_stability_contract.gd'`
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_claim_board_contract.gd'`
  - Checked: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_test_ui_read_models.gd'` still fails, but the newly added starter-inspector and summary-fallback failure messages no longer appear after this change.
  - Checked: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd'` currently fails on pre-existing combat-shell backpack sizing and root viewport containment assertions, including the reward tray's overall page frame, rather than on the focused reward-board contract.
  - Passed: `git diff --check -- app-LTL/src/models/Artifact.gd app-LTL/src/ui/read_models/RewardReadModel.gd app-LTL/tests/test_ui_read_models.gd app-LTL/tests/run_reward_inspector_stability_contract.gd docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`

## 2026-06-08 reward-claim board layout polish

- Intent: Apply the user's live-screen feedback so the reward board centers the backpack grid more aggressively and stops card overlap in the reward cloud.
- Files or areas touched:
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
- Summary:
  - Added a reward-board-specific layout sync that visually removes the `백팩 작업 공간` wrapper treatment, hides its title/note surfaces, and reallocates width toward the shared backpack panel while shrinking the side zones as needed.
  - Replaced the fixed reward-card anchor list with clustered non-overlapping placement plus per-card idle float offsets and slight rotation drift so the reward cloud reads closer to the M6 mockup.
  - Reworked reward backpack sizing to derive the visible panel dimensions from the host bounds and the real backpack chrome measurements instead of the earlier fixed square clamp.
- Plan impact: Stayed within the approved reward-board layout polish scope; no controller or reward-claim rule changes were required.
- Verification:
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_claim_board_contract.gd' -Quit`
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd' -Quit`
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_ceremony_contract.gd' -Quit`
  - Observed: the focused headless runners still print the usual Godot dummy-texture/resource leak warnings on shutdown, but they exited successfully and did not report reward-board assertion failures in this pass.

## 2026-06-08 reward-claim board height rebalance

- Intent: Reduce the enlarged center backpack panel just enough to keep the reward board’s bottom row visible, then give the recovered width back to both side panels evenly.
- Files or areas touched:
  - `app-LTL/src/ui/MainViewRuntime.gd`
- Summary:
  - Added a visible-height cap for the reward backpack panel based on the real reward panel height, board head height, and bottom-row minimum height so the central panel no longer consumes the discard/confirm row.
  - Made the reward left and right side panels grow back with the same stretch ratio after the center column is reduced.
- Plan impact: This is a direct follow-up tuning pass inside the same reward-board layout scope.
- Verification:
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_claim_board_contract.gd' -Quit`
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd' -Quit`
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_ceremony_contract.gd' -Quit`

## 2026-06-08 17:18:32

- Intent: Bring the node-select runtime visuals materially closer to the crossroads mockup without changing the corrected stage semantics.
- Files or areas touched:
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
- Summary:
  - Reworked the node board presentation toward the mockup by widening the route fan, moving anchors closer to the reference composition, shifting the hover card deeper into the frame, and adding layered canvas ambience.
  - Replaced the flat placeholder node buttons with palette-driven rendered cores, preview-ring styling for future `?` markers, and more mockup-like red / gold / muted route overlays.
  - Updated the anatomy backdrop to use a broader spine stroke and rib arcs that read more like the mockup board instead of the earlier sparse scaffold.
- Verification:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_node_select_runtime_contract.gd' -Quit` (exit `0`)
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd' -Quit` (exit `0`)
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_start_flow_contract.gd' -Quit` (exit `0`)
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_test_node_routing_contract.gd' -Quit` (`NODE_ROUTING_TESTS_OK`)
  - `git diff --check -- 'app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd' 'docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md'` (clean)
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/capture-node-select-runtime.ps1'` still failed because the live-window handle never became ready, so fresh screenshot evidence remains blocked by the capture harness rather than the node-select contract.

## 2026-06-08 16:05:41

- Intent: Repair node-select runtime semantics so the board always shows `start -> future ? -> boss` on stage one, preserves chosen branch slots in history, and keeps current five choices visually distinct from future `?` markers.
- Files or areas touched:
  - `app-LTL/src/phases/NodeSelectPhase.gd`
  - `app-LTL/src/ui/SceneReadModel.gd`
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/MainControllerRuntime.gd`
  - `app-LTL/tests/test_node_routing_contract.gd`
  - `app-LTL/tests/run_main_start_flow_contract.gd`
  - `app-LTL/tests/run_node_select_runtime_contract.gd`
  - `tools/capture-node-select-runtime.ps1`
- Summary:
  - Stored `routeSlotIndex` in route history and projected it through the scene read model so explored branches can stay in their original slots.
  - Reworked `NodeSelectRuntimePage` so stage one no longer renders a duplicate fixed-entry node; it now renders one start marker, one future `?` marker, and one boss marker for a three-stage run.
  - Replaced text glyph route chips with drawn icon marks for start, repair/support, unknown event, danger, mixed route, harpoon/red route, and boss states so current selectable nodes no longer look like future `?` markers.
  - Added a focused node-select runtime contract script and hardened the capture helper against blank `MainWindowHandle` values.
  - Patched the existing `MainViewRuntime` / `MainControllerRuntime` compile blockers that surfaced while re-running the runtime contracts.
- Verification:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_test_node_routing_contract.gd' -Quit` -> exit `0`, `NODE_ROUTING_TESTS_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_node_select_runtime_contract.gd' -Quit` -> exit `0`; node-select runtime assertions passed, with only Godot shutdown resource-leak warnings
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd' -Quit` -> exit `0`; only the existing Godot shutdown resource-leak warnings remained
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_start_flow_contract.gd' -Quit` -> exit `0`; only the existing Godot shutdown resource-leak warnings remained
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/capture-node-select-runtime.ps1'` -> one earlier live-window capture succeeded at `app-LTL/test-artifacts/visual/node-select-runtime.png`; later reruns hit a `visual-hold window became ready` automation flake after the final placement nudge, so the latest verification relied on the headless contracts plus the most recent successful capture artifact

## 2026-06-08 reward-claim interaction follow-up

- Intent: Close the remaining reward-board gaps reported after the first mockup implementation.
- Files or areas touched:
  - `app-LTL/src/Main.tscn`
  - `app-LTL/src/MainControllerRuntime.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/ui/BackpackUI.gd`
  - `app-LTL/src/ui/read_models/RewardReadModel.gd`
  - `app-LTL/tests/test_reward_claim_board_contract.gd`
  - `app-LTL/tests/run_reward_claim_board_contract.gd`
- Summary:
  - Converted the reward workspace host into a layout container so the live shared backpack panel docks into the center workspace instead of leaving an empty replacement surface.
  - Replaced reward-card list/grid rendering with floating image cards in a free-positioned cloud layer.
  - Split reward interaction into `click -> inspect only` and `drag -> held artifact + drop/discard/cancel`, while reusing the existing backpack ghost and placement rules.
  - Added a focused reward-board contract runner to cover drag-signal exposure, floating reward cloud structure, and shared backpack reuse.
- Verification status:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_claim_board_contract.gd' -Quit` -> exit `0`; runner exits cleanly, though the captured output currently shows only the usual shutdown warnings and no success banner
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_ceremony_contract.gd' -Quit` -> exit `0`, `REWARD_CEREMONY_CONTRACT_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_start_option_contract.gd' -Quit` -> exit `0`, `START_OPTION_CONTRACT_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd' -Quit` -> exit `0`; only shutdown leak warnings remain in the captured output

## 2026-06-08 localization, font fallback, and i18n gate hardening

- Intent: Fix broken Korean rendering, restore live locale switching, move player-facing text into Korean/English JSON catalogs, and block new hardcoded UI copy through the harness.
- Files or areas touched:
  - `app-LTL/src/data/i18n/text-ko.json`
  - `app-LTL/src/data/i18n/text-en.json`
  - `app-LTL/src/ui/TextCatalog.gd`
  - `app-LTL/src/ui/theme/LTLTheme.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/ui/SettingsPanelUI.gd`
  - `app-LTL/src/MainControllerRuntime.gd`
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd`
  - `app-LTL/src/scenes/pages/LeviathanSelectPage.gd`
  - `app-LTL/src/scenes/node_map/NodeMapScene.gd`
  - `app-LTL/src/ui/read_models/NodeMapReadModel.gd`
  - `app-LTL/src/ui/read_models/TooltipReadModel.gd`
  - `app-LTL/src/Main.tscn`
  - `app-LTL/src/scenes/pages/CharacterSelectPage.tscn`
  - `app-LTL/src/scenes/pages/DefeatPage.gd`
  - `app-LTL/src/scenes/pages/OutcomePage.gd`
  - `LTL-harness/tools/i18n-text-gate.ps1`
  - `LTL-harness/tools/i18n-text-gate.tests.ps1`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
- Summary:
  - Kept the shared runtime theme on Korean-capable system font fallbacks so mixed Korean/English UI copy renders without missing glyphs.
  - Reconnected live locale switching so settings changes update the current runtime view, page chrome, and runtime rosters immediately.
  - Localized controller logs, node-select copy, defeat/outcome copy, node-map fallback text, character status summary text, leviathan fallback text, and tooltip fallback text through `TextCatalog`.
  - Cleared static `.tscn` text defaults so runtime models own visible copy, and repaired scene structure after bulk text cleanup touched a few node headers.
  - Hardened the i18n harness gate so it now rejects hardcoded `view.add_log(...)` copy, file-local locale ternaries, inline page-model text literals, static scene text defaults, unreadable Korean placeholders, and missing localized reward contracts.
  - Added a new gate self-test for inline locale-branch copy and kept the existing positive/negative JSON contract coverage.
- Verification status:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'LTL-harness/tools/i18n-text-gate.tests.ps1'` -> exit `0`, `I18N_TEXT_GATE_TESTS_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'LTL-harness/tools/i18n-text-gate.ps1' -Root 'D:\Programming\ex_workspace\LootingTheLeviathan'` -> exit `0`, `I18N_TEXT_GATE_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_i18n_localization_smoke.gd' -Quit` -> exit `0`, `I18N_LOCALIZATION_SMOKE_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_start_flow_contract.gd' -Quit` -> exit `0`; Godot still prints the existing resource-leak warnings at exit
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd' -Quit` -> exit `0`; Godot still prints the existing resource-leak warnings at exit

## 2026-06-08 defeat cause sentence format update

- Intent: Replace the defeat cause sentence with the new dynamic Korean format built from Leviathan name, current run number, and stage node name.
- Files or areas touched:
  - `app-LTL/src/ui/read_models/FailureReadModel.gd`
  - `app-LTL/src/data/i18n/text-ko.json`
  - `app-LTL/src/data/i18n/text-en.json`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
- Summary:
  - Changed `FailureReadModel` so failed expedition causes now use `selectedLeviathan.name`, `runIndex + 1`, and `lastNodeLabel` instead of the old `stageIndex / maxStages` sentence.
  - Updated the locale-catalog cause template for Korean to `{레비아탄 이름}의 {n}번째 런 {스테이지 노드명}에서 마력이 폭주했습니다.` and added a matching English template plus a node fallback key.
  - Tightened the focused defeat-page regression to assert the exact rendered cause sentence through the live page-model path.
- Plan impact: Narrowed the current task to a copy-format follow-up on the defeat page rather than a broader UI or localization pass.
- Verification status:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_defeat_page_contract.gd' -Quit` -> exit `0`, `DEFEAT_PAGE_CONTRACT_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_i18n_localization_smoke.gd' -Quit` -> exit `0`, `I18N_LOCALIZATION_SMOKE_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_start_flow_contract.gd' -Quit` -> exit `0`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_page_scene_mapping_contract.gd' -Quit` -> currently fails on an unrelated node-select title-band assertion in the dirty worktree, not on the defeat sentence change

## 2026-06-08 defeat page copy removal follow-up

- Intent: Remove the three explanatory text blocks the user called out from the live defeat page while keeping the cause line, retry hint, and CTA intact.
- Files or areas touched:
  - `app-LTL/src/scenes/pages/DefeatPage.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
- Summary:
  - Updated the defeat page model so the subtitle under `GAME OVER`, the board header title, and the board header hint now resolve to empty strings.
  - Cleared the defeat page fallback values for the same three fields and hid those labels or the whole header row automatically when the text is empty.
  - Extended the focused defeat-page test coverage so the removed copy stays gone in future changes.
- Plan impact: Narrowed the current task from the broader defeat-page implementation to a small copy-trim follow-up.
- Verification status:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_defeat_page_contract.gd' -Quit` -> exit `0`, `DEFEAT_PAGE_CONTRACT_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_page_scene_mapping_contract.gd' -Quit` -> exit `0`, `PAGE_SCENE_MAPPING_CONTRACT_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_start_flow_contract.gd' -Quit` -> exit `0`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd' -Quit` -> exit `0`

## 2026-06-08 10:14:35

<!-- codex-worklog-signature: e97aaea2b17c622edce1cc3b47794e684c2e8173305f89b927096709046afd93 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
 M app-LTL/src/ui/VFXManager.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/m2_main_scene_contract.ps1
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 10:16:12

<!-- codex-worklog-signature: 09d15bada44726f3ad6fa4e3e591941f1ca1831350fe8b546bb8a69feb6657c7 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
 M app-LTL/src/ui/VFXManager.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/tests/m2_main_scene_contract.ps1
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 grim baleen runtime implementation

- Intent: Replace the live node-select page with the approved Grim Baleen anatomy-board design while keeping the formal node-select flow intact.
- Files or areas touched:
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd`
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn`
  - `app-LTL/tests/run_main_start_flow_contract.gd`
  - `app-LTL/tests/run_main_layout_audit_contract.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
- Summary:
  - Rebuilt the runtime page into a single-board Grim Baleen layout with a left hover info card, anatomy-style background strokes, dotted red route paths, gold selected-route overlays, and a distinct future `?` preview node.
  - Preserved Stage 1 as a fixed entry lane with zero current route buttons and kept Stage 2+ on the existing five-route interaction contract.
  - Kept the public node-select helpers used by automation (`route_button_count`, `press_route_button`, `start_color_chip_count`) while switching the internals to the new hover-driven presentation.
  - Updated focused page-flow and layout contracts so they assert the new `InfoCard` and `FuturePreviewHotspot` structure instead of the retired split-roadmap shell assumptions.
- Plan impact: The active work is now implementation-complete for the node-select runtime redesign, with only unrelated combat-layout debt still failing in the broad layout audit.
- Verification status:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_start_flow_contract.gd` -> `MAIN_START_FLOW_CONTRACT_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd` -> node-select assertions pass; remaining failures are existing combat backpack / viewport assertions unrelated to the node-select page
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/capture-node-select-runtime.ps1` -> `NODE_SELECT_RUNTIME_CAPTURE_OK D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL\test-artifacts\visual\node-select-runtime.png`

## 2026-06-08 11:00:20

<!-- codex-worklog-signature: 401d7c2782fdc1adc566397ed005ca1be32c47d50dda069a221d47511cf7ca82 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
 M app-LTL/src/ui/VFXManager.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/ui/read_models/TooltipReadModel.gd
 M app-LTL/tests/m2_main_scene_contract.ps1
 M app-LTL/tests/run_main_layout_audit_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 11:01:00

<!-- codex-worklog-signature: 9339cb2782a84c26bbbcf040d6cf3d1e6d0fbb6ba0e09aa20f0bb6818b73e897 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
 M app-LTL/src/ui/VFXManager.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/ui/read_models/TooltipReadModel.gd
 M app-LTL/tests/m2_main_scene_contract.ps1
 M app-LTL/tests/run_main_layout_audit_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 11:08:13

<!-- codex-worklog-signature: 991298e948e6c55c5ea23e65e3bf0f2d0c532d71827533960e9e5d319cb71a45 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
 M app-LTL/src/ui/VFXManager.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/ui/read_models/TooltipReadModel.gd
 M app-LTL/tests/m2_main_scene_contract.ps1
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 11:08:31

<!-- codex-worklog-signature: 7d0a115d78a9454efe33b40ddfdc07be3a951968ad3537b9a508316b8ac815c7 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
 M app-LTL/src/ui/VFXManager.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/ui/read_models/TooltipReadModel.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 11:08:49

<!-- codex-worklog-signature: 047e80047ada308131187a4be6f6fa0d1f2479104f7a1c86fd8afabd81500e3d -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/phases/RewardLootPhase.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
 M app-LTL/src/ui/VFXManager.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 11:09:01

<!-- codex-worklog-signature: bdc895c900591c08a0322f4c8698c5b3c86dcbd676c8f245319ccaeffe127ce4 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/phases/BackpackOrganizePhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/phases/RewardLootPhase.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
 M app-LTL/src/ui/VFXManager.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 11:10:09

<!-- codex-worklog-signature: ec7346621f657d0add0a374ca1a6eae1a7f805566797fe0396704224604265df -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/phases/BackpackOrganizePhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/phases/RewardLootPhase.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SceneReadModel.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
 M app-LTL/src/ui/VFXManager.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 11:11:02

<!-- codex-worklog-signature: b1492b9a9fa06c3640ad0d1c84d094e40bd9cfae98989ad78ece76657abbb31e -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/phases/BackpackOrganizePhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/phases/RewardLootPhase.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SceneReadModel.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
 M app-LTL/src/ui/VFXManager.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 node-select gameplay contract completion

- Intent: Finish the missing node-select gameplay behaviors behind the Grim Baleen runtime page so the UI reflects real expedition progression.
- Files or areas touched:
  - `app-LTL/src/process/HeadlessMiniRun.gd`
  - `app-LTL/src/phases/NodeSelectPhase.gd`
  - `app-LTL/src/phases/RewardLootPhase.gd`
  - `app-LTL/src/phases/BackpackOrganizePhase.gd`
  - `app-LTL/src/vocabulary/NodeVocab.gd`
  - `app-LTL/src/ui/SceneReadModel.gd`
  - `app-LTL/src/ui/CombatScenePreviewController.gd`
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd`
  - `app-LTL/tests/test_node_routing_contract.gd`
  - `app-LTL/tests/run_test_node_routing_contract.gd`
  - `app-LTL/tests/run_main_start_flow_contract.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
- Summary:
  - Added persisted `routeHistory` to the formal run state and appended cleared node selections as stages resolve.
  - Changed final-stage node generation so boss selection is truly fixed to one boss candidate instead of mixing boss plus normal routes.
  - Projected route history, fixed-start/boss-stage state, and remaining unexplored `?` counts through the scene read model into the live runtime page.
  - Reworked the Grim Baleen runtime page so cleared routes stay rendered as history markers, middle stages open five current choices, future unexplored stages render as separate `?` previews, and boss stages lock to a fixed boss node with zero current route buttons.
  - Tightened focused tests for node routing and the main start flow, and added a dedicated node-routing runner for isolated verification.
- Plan impact: Completed the missing gameplay-contract portion of the node-select redesign; remaining failures observed during verification were unrelated combat/defeat debt outside this task.
- Verification status:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_test_node_routing_contract.gd'` -> exit `0`, `NODE_ROUTING_TESTS_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_start_flow_contract.gd'` -> exit `0`, `MAIN_START_FLOW_CONTRACT_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd'` -> exit `1`; only the pre-existing combat backpack/viewport containment assertions failed in the captured output
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_test_ui_read_models.gd'` -> exit `1`; unrelated existing defeat-page headline expectation mismatch (`GAME OVER` vs `원정 실패`)

## 2026-06-08 reward-claim board scene mismatch fix

- Intent: Resolve the live `null instance` crash reported after the reward-board refactor by tracing the missing node path back to the scene tree.
- Files or areas touched:
  - `app-LTL/src/Main.tscn`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-08.md`
- Summary:
  - Confirmed the crash was not a button-signal bug in isolation; `MainViewRuntime.gd` already expected the new reward-board node paths, but `Main.tscn` still exposed the old `RewardRow/RewardText/DiscardZone` layout.
  - Replaced the legacy reward tray strip in the scene tree with the expected `BoardHead`, three-column `RewardBoard`, workspace `BackpackHost`, inspector card, and inline claim/discard zones so the runtime view can bind successfully.
  - Reused the existing focused layout contracts instead of adding a second duplicate test because `run_main_layout_audit_contract.gd` already failed red on the missing node tree and now exits cleanly.
- Plan impact: Converted the reward-claim work from “partially wired runtime” to “scene and runtime aligned,” which closes the reported crash and makes the mockup implementation actually renderable.
- Verification status:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd' -Quit` -> exit `0`; no reward-board path or `null instance` failures after the scene fix
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_ceremony_contract.gd' -Quit` -> exit `0`, `REWARD_CEREMONY_CONTRACT_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_start_option_contract.gd' -Quit` -> exit `0`, `START_OPTION_CONTRACT_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_test_ui_read_models.gd' -Quit` -> exit `1`; failures are unrelated existing Korean expectation drift and defeat-page copy assertions outside this scene fix

## 2026-06-08 node-select crossroads mockup runtime follow-up

- Intent: Bring the live node-select page in line with the approved June 8 crossroads mockup instead of the older roadmap-board shell.
- Files or areas touched:
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd`
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn`
  - `app-LTL/src/data/i18n/text-en.json`
  - `app-LTL/src/data/i18n/text-ko.json`
  - `app-LTL/tests/run_main_start_flow_contract.gd`
  - `app-LTL/tests/run_page_scene_mapping_contract.gd`
  - `docs/source-map.md`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
- Summary:
  - Replaced the node-select board-head contract so the inner board now leads with a selected-Leviathan label plus Leviathan title, while run and stage stay in the chips instead of the older fixed-entry/roadmap heading copy.
  - Reworked the hover info card into explicit `노드명 / 노드 설명` rows and added caption tags under fixed-entry, future-preview, boss, and current-route hotspots so the map reads more like the approved crossroads mockup.
  - Tightened the node-select scene-mapping and start-flow contracts to target `docs/mockups/2026-06-08-node-select-crossroads-3up.html` and the new scene-node structure instead of the retired roadmap title-band expectation.
  - Captured a fresh live-window screenshot at `app-LTL/test-artifacts/visual/node-select-runtime.png` to verify the updated stage-one presentation in the actual Godot window.
- Plan impact: Kept the existing node-select stage contract intact while shifting the page shell and mockup source of truth to the June 8 crossroads direction.
- Verification status:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_start_flow_contract.gd' -Quit` -> exit `0`; node-select stage-one/start-flow assertions passed, with only the existing Godot dummy-renderer leak warnings at shutdown
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd' -Quit` -> exit `0`; node-select stage-one and stage-two layout containment assertions passed, with only the existing Godot dummy-renderer leak warnings at shutdown
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_page_scene_mapping_contract.gd' -Quit` -> exit `1`; node-select scene assertions now pass, but the run still fails on the pre-existing unrelated leviathan-select CTA copy expectations
  - `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/capture-node-select-runtime.ps1'` -> exit `0`, `NODE_SELECT_RUNTIME_CAPTURE_OK D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL\test-artifacts\visual\node-select-runtime.png`

## 2026-06-08 15:41:12

<!-- codex-worklog-signature: d4dd0febb6cd5be48b2aee69c93575373371763c7769172ac35e594962035da0 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/phases/BackpackOrganizePhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/phases/RewardLootPhase.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SceneReadModel.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 15:41:14

<!-- codex-worklog-signature: dfdde5a72a2e55f1682341de22bf50ff23398ef9a45dcb114efdecf09977d72f -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/phases/BackpackOrganizePhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/phases/RewardLootPhase.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SceneReadModel.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 reward-board inspection stability and drag-ghost anchoring

- Intent: Stop the reward board from visually reflowing when inspection focus changes and make drag-release feel aligned with the backpack's top-left placement rule.
- Files or areas touched:
  - `app-LTL/src/ui/BackpackUI.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/ui/read_models/RewardReadModel.gd`
  - `app-LTL/tests/test_reward_claim_board_contract.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
- Summary:
  - Added focused regression coverage for two user-facing expectations: the reward-board inspector should keep a stable empty shell before selection, and the backpack drag ghost should anchor from the cursor's top-left instead of the cursor center.
  - Traced the perceived reward-board jump to the inspector changing structure too aggressively between the empty and selected states. The empty model previously removed all fact tiles and footprint cells, so clicking a reward or backpack artifact made the right column rebuild with a visibly different internal skeleton.
  - Changed the empty reward inspector model to keep four fact slots and a two-row by four-column inactive footprint shell, then taught `MainViewRuntime` to render footprint grids with a stable minimum layout and fact tiles with a fixed minimum height.
  - Re-anchored the live drag ghost in `BackpackUI` so the ghost's top-left corner now follows the cursor, matching the actual top-left backpack placement origin used on release.
- Plan impact: The implementation stayed within the requested reward-board stability and drag-ghost scope; no unrelated controller, balance, or scene-routing work was added.
- Verification status:
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_claim_board_contract.gd' -Quit`
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd' -Quit`
  - Passed targeted check: `run_test_ui_read_models.gd` still reports unrelated legacy localization failures, but the new reward-inspector-shell and drag-ghost regression messages no longer appear (`NO_TARGETED_FAILURES`).
  - Passed: `git diff --check -- app-LTL/src/ui/BackpackUI.gd app-LTL/src/ui/MainViewRuntime.gd app-LTL/src/ui/read_models/RewardReadModel.gd app-LTL/tests/test_reward_claim_board_contract.gd app-LTL/tests/test_ui_read_models.gd docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`

## 2026-06-08 node-select shared-shell repair

- Intent: Fix the reported stage-two and boss-selection layout break so node select keeps one stable screen and only swaps node state as the run advances.
- Files or areas touched:
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd`
  - `app-LTL/tests/run_main_layout_audit_contract.gd`
  - `app-LTL/tests/run_main_start_flow_contract.gd`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-08.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-08.md`
- Summary:
  - Traced the visible stage-two divergence to `NodeSelectRuntimePage._route_offsets_for_count()`: for the five-choice middle stage it returned an untyped duplicated array into a function declared as `Array[Vector2]`, which broke the roadmap rebuild and cascaded into out-of-bounds node placement on stage-two and boss-lock reentry.
  - Kept the existing `node_select` runtime page as the single shell and hardened its canvas math so start, history, current routes, future previews, and the boss hotspot are all clamped inside one shared safe area instead of drifting outside the roadmap frame.
  - Added explicit layout-flow assertions that stage-one, stage-two, and boss-lock states reuse the same `node_select` page instance rather than swapping to a different scene, which matches the requested “same screen, only nodes change” behavior.
  - Confirmed the old `MainViewRuntime` split-shell cache still points at retired `RouteSplit` paths, but that code path is not what currently drives stage progression; the active runtime surface is the dedicated `page_scenes["node_select"]` page.
- Plan impact: Completed the requested shared-shell repair without expanding into the unrelated combat-shell containment debt that still exists in the broad layout audit.
- Verification status:
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_node_select_runtime_contract.gd'`
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_start_flow_contract.gd'`
  - Checked: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_layout_audit_contract.gd'` still exits `1`, but the remaining failures are the pre-existing combat backpack and viewport containment assertions rather than node-select layout failures.

## 2026-06-08 node-select duplicate leviathan copy cleanup

- Intent: Remove the repeated Leviathan naming on the node-select runtime page so the selected Leviathan name appears only once.
- Files or areas touched:
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd`
  - `app-LTL/tests/run_node_select_runtime_contract.gd`
  - `app-LTL/tests/run_main_start_flow_contract.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-08.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-08.md`
- Summary:
  - Added focused node-select runtime assertions that lock the new copy contract: the hero section keeps the `진입 통로` eyebrow but no longer renders a second Leviathan title, and the board-head `선택 레비아탄` kicker is also retired.
  - Confirmed the new assertions fail against the pre-change runtime, which showed both the duplicate hero title and the board kicker on stage one and later stages.
  - Updated `NodeSelectRuntimePage._render_copy()` so it explicitly clears and hides the duplicate hero title plus the board label while leaving the single board-head Leviathan title intact.
  - Re-ran the focused runtime and integrated start-flow contracts without `-Quit`, because the async SceneTree contracts only surface reliable failure exit codes when the script controls shutdown itself.
- Plan impact: Completed the requested copy cleanup without expanding into unrelated roadmap-layout or reward-board work already present elsewhere in the worktree.
- Verification status:
  - Red before fix: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_node_select_runtime_contract.gd'`
  - Red before fix: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_start_flow_contract.gd'`
  - Passed after fix: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_node_select_runtime_contract.gd'`
  - Passed after fix: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_main_start_flow_contract.gd'`

## 2026-06-08 15:41:14

<!-- codex-worklog-signature: dfdde5a72a2e55f1682341de22bf50ff23398ef9a45dcb114efdecf09977d72f -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/phases/BackpackOrganizePhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/phases/RewardLootPhase.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SceneReadModel.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 19:31:06

<!-- codex-worklog-signature: 9a94c92b026f3ad9c1843821951e32a75dcdcd8e923c39f42d69e5c595135d5c -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/models/Artifact.gd
 M app-LTL/src/phases/BackpackOrganizePhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/phases/RewardLootPhase.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SceneReadModel.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 19:31:41

<!-- codex-worklog-signature: 8718b9f895f03eaf0637f75e7cbc076f4ffe9041086cb18c1405e82b9e1377bb -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/charactor/background.png
 D app-LTL/resources/UI/charactor/background.png.import
 D app-LTL/resources/UI/charactor/charactor1.png
 D app-LTL/resources/UI/charactor/charactor1.png.import
 D app-LTL/resources/UI/charactor/charactor1_ss.png
 D app-LTL/resources/UI/charactor/charactor1_ss.png.import
 D app-LTL/resources/UI/charactor/charactor_backpack.png
 D app-LTL/resources/UI/charactor/charactor_backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/character-table.json
 M app-LTL/src/data/release-resource-needs.json
 M app-LTL/src/models/Artifact.gd
 M app-LTL/src/phases/BackpackOrganizePhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/phases/RewardLootPhase.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SceneReadModel.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-08 test suite size split and harness gate

- Intent: Break the oversized formal UI read-model suite into much smaller files and add a dedicated harness gate so test-source growth is managed continuously.
- Files or areas touched:
  - `app-LTL/tests/test_ui_read_models.gd`
  - `app-LTL/tests/support/UiReadModelTestSuite.gd`
  - `app-LTL/tests/ui_read_models/*.gd`
  - `LTL-harness/tools/test-size-gate.ps1`
  - `LTL-harness/tools/test-size-gate.tests.ps1`
  - `tools/run-compile-check.ps1`
  - `tools/run-ltl-quality-gate.ps1`
  - `LTL-harness/00_AGENTS.md`
  - `LTL-harness/README.md`
  - `docs/source-map.md`
  - `docs/request-ledgers/2026-06-08-test-suite-size-gate.md`
- Summary:
  - Replaced the former `2214`-line `test_ui_read_models.gd` monolith with a `74`-line aggregator that preserves the existing runner-facing API while dispatching into topic-focused leaf suites.
  - Added a shared `UiReadModelTestSuite` base helper plus ten leaf suites under `app-LTL/tests/ui_read_models/`, keeping the split surfaces between `74` and `284` lines so future edits can stay narrowly scoped.
  - Added a dedicated `test-size-gate` with self-tests and wired it into both the compile wrapper and the consolidated LTL quality gate so these split test surfaces now hard-fail if they grow past the small-file thresholds.
  - Kept the specialized runner entry points stable for reward inspector, reward ceremony, and defeat-page contracts instead of forcing downstream runner rewrites.
- Plan impact: Completed the chosen "dedicated split structure plus dedicated gate" implementation path and left the remaining oversized legacy test files as warned debt rather than folding them into this pass.
- Verification status:
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'LTL-harness/tools/test-size-gate.tests.ps1'` -> `TEST_SIZE_GATE_TESTS_OK`
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'LTL-harness/tools/test-size-gate.ps1' -Root 'D:\Programming\ex_workspace\LootingTheLeviathan'` -> `TEST_SIZE_GATE_OK`
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_inspector_stability_contract.gd' -Quit` -> `REWARD_INSPECTOR_STABILITY_CONTRACT_OK`
  - Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_ceremony_contract.gd' -Quit` -> `REWARD_CEREMONY_CONTRACT_OK`
  - Checked: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_defeat_page_contract.gd' -Quit` still fails on current defeat-page copy expectations (`GAME OVER`, localized cause string, retry CTA) rather than on missing split-suite methods or runner breakage.
  - Checked: `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_test_ui_read_models.gd' -Quit` still fails on the broader pre-existing localization and copy drift already present in the dirty worktree, but the split suite loads and executes end-to-end.
  - Passed: `git diff --check -- LTL-harness/00_AGENTS.md LTL-harness/README.md LTL-harness/tools/test-size-gate.ps1 LTL-harness/tools/test-size-gate.tests.ps1 app-LTL/tests/support/UiReadModelTestSuite.gd app-LTL/tests/ui_read_models app-LTL/tests/test_ui_read_models.gd docs/source-map.md docs/request-ledgers/2026-06-08-test-suite-size-gate.md tools/run-compile-check.ps1 tools/run-ltl-quality-gate.ps1`
