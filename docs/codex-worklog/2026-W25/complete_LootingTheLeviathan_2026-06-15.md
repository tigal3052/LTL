# Codex Worklog Complete

Workspace: LootingTheLeviathan
Date: 2026-06-15

## Drill Image And Backpack Drop Cue Completion

### Completion Summary

Implemented the drill-image and drag-footprint feedback plan. Common/rare drill rewards now match the supplied 1x1 and vertical 1x2 drill art, common/rare/basic drills can load raw PNG item art without `.import` files, and backpack drag feedback now colors only the current candidate footprint.

### Actual Outputs

- `reward-table.json`: common drills use `[[1]]`; rare drills use `[[1], [1]]`; epic+ drills and non-drills were left on their existing shapes.
- `ArtifactCodexArtResolver.gd`: common/rare drill descriptors include `res://resources/items/drill/{color}_drill_{rarity}.png` and can detect raw PNG files via `ProjectSettings.globalize_path`.
- `BackpackGridFactory.gd`: added drill texture-path and green/red drop-cue style helpers plus `DropCueOverlay` slots.
- `BackpackUI.gd`: placed drill images render over the existing colored footprint overlay, drill drag ghosts are image-only, and drag feedback clears outside the backpack or paints only the current target footprint.
- `RewardCardCloudHost.gd`: drill reward cards with actual drill item PNG art show the image without the inner square panel; non-drills keep the previous shell.
- Tests were expanded for drill shapes, resolver fallbacks, non-drill fallback guard, texture paths, drop cue colors, same-color drill duplicate placement, and footprint-only feedback.

### Verification Results

- RED before implementation: reward contract failed on common/rare drill shapes and raw PNG resolver fallback; UI read-model suite failed to parse due to missing new helpers.
- Passed: `run_test_reward_contract.gd` -> `REWARD_CONTRACT_TESTS_OK`.
- Passed: `run_test_ui_read_models.gd` -> `UI_READ_MODEL_TESTS_OK`.
- Passed: `godot_contract_runner.gd` -> `GODOT_CONTRACTS_OK`.
- Passed: `run_reward_claim_board_contract.gd` exited 0.
- Passed: `git diff --check` exited 0 with LF-to-CRLF normalization warnings only.

### Remaining Gaps

Manual in-editor drag inspection was not performed in this pass. Headless Godot runs still report the existing anchor/RID/resource leak shutdown warnings.

## Battle Tile-Hit Stutter Performance Completion

### Completion Summary

Fixed the post-language-fix battle tile-hit stutter at the source. The cause was not the combat reducer itself; it was the UI render path refreshing hidden meta pages on every battle render after the locale fix. Battle renders now leave inactive meta pages alone unless the settings language panel is actively applying locale state.

### Actual Outputs

- `app-LTL/src/ui/MainViewRuntime.gd`: ordinary battle renders no longer refresh inactive meta pages.
- `app-LTL/src/ui/PageSceneModelBuilder.gd`: owns the inactive meta-page refresh helper used by settings-visible locale refresh.
- `app-LTL/tests/run_battle_render_performance_contract.gd`: proves repeated battle renders do not call inactive meta page `apply_state()`.
- `LTL-harness/tools/request-analysis-gate.ps1` and tests/docs/templates: add `Runtime Performance Review` enforcement for high-frequency runtime paths.
- `docs/request-ledgers/2026-06-15-battle-render-performance-hotpath.md`: records root cause, performance proof, ERU, and verification evidence.

### Verification Results

- RED before fix: `run_battle_render_performance_contract.gd` failed with each inactive meta page receiving 8 `apply_state()` calls over 8 battle renders.
- Passed after fix: `BATTLE_RENDER_PERFORMANCE_CONTRACT_OK`.
- Passed: `SETTINGS_LANGUAGE_APPLY_CONTRACT_OK`, `I18N_LOCALIZATION_SMOKE_OK`, `GODOT_CONTRACTS_OK`.
- Passed: `REQUEST_ANALYSIS_GATE_TESTS_OK`, `SOURCE_MAP_GATE_OK`, `RUNTIME_SIZE_GATE_OK`.
- Passed: `tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-15-battle-render-performance-hotpath.md`.
- `git diff --check` reported only LF-to-CRLF normalization warnings.

### Remaining Gaps

Manual in-editor feel testing was not performed in this pass. The new headless contract verifies the root cause directly by counting hidden-page `apply_state()` calls on the battle render hot path.

## Settings Bidirectional Locale Apply Completion

### Completion Summary

Fixed the remaining settings-language regression where switching from English back to Korean could leave hidden page scenes with stale English state. Locale changes now keep the selector synced without re-emitting redundant events and refresh inactive meta page models during scene renders, so English and Korean can be applied repeatedly through the settings panel.

### Actual Outputs

- `app-LTL/src/ui/SettingsPanelUI.gd`: retained guarded selector synchronization and same-locale suppression for both English and Korean.
- `app-LTL/src/ui/MainViewRuntime.gd`: refreshes inactive meta page models after rendering the active page, preventing hidden character/leviathan/outcome pages from keeping stale localized state across language flips.
- `app-LTL/tests/run_settings_language_apply_contract.gd`: expanded the focused contract to cover English -> Korean -> English -> Korean apply-close cycles, duplicate-event suppression in both directions, active page preservation, and hidden-page Korean refresh.
- Updated today's worklog plan/history/completion notes for the bidirectional bugfix scope.

### Verification Results

- RED observed before the runtime refresh fix: `run_settings_language_apply_contract.gd` failed because the hidden character page still showed `Character Select` after switching back to Korean.
- Passed after fix: `run_settings_language_apply_contract.gd` with `SETTINGS_LANGUAGE_APPLY_CONTRACT_OK`.
- Passed after fix: `run_i18n_localization_smoke.gd` with `I18N_LOCALIZATION_SMOKE_OK`.
- Passed after fix: `godot_contract_runner.gd` with `GODOT_CONTRACTS_OK`.

### Remaining Gaps

Manual in-editor clicking was not performed in this pass. The headless contract exercises the settings panel signal path, apply-close button, repeated locale cycles, and page model refresh behavior.

## Settings English Locale Apply Freeze Completion

### Completion Summary

Fixed the settings-language path so selecting English and applying/closing settings no longer re-enters the locale refresh flow through a redundant active-locale selection event. English now updates the settings panel immediately and refreshes visible/page-transition UI text through the existing main view/controller render path.

### Actual Outputs

- `app-LTL/src/ui/SettingsPanelUI.gd`: added guarded language-selector synchronization and skipped same-locale `language_changed` emissions.
- `app-LTL/tests/run_settings_language_apply_contract.gd`: added a focused Godot regression contract for English selection, apply-close behavior, duplicate-event prevention, and dynamic English text refresh on settings, character select, and leviathan select.
- Updated today's worklog plan/history for the active bugfix scope.

### Verification Results

- RED observed before fix: `run_settings_language_apply_contract.gd` failed because reselecting active English emitted `language_changed` again.
- Passed after fix: `run_settings_language_apply_contract.gd` with `SETTINGS_LANGUAGE_APPLY_CONTRACT_OK`.
- Passed after fix: `run_i18n_localization_smoke.gd` with `I18N_LOCALIZATION_SMOKE_OK`.
- Passed after fix: `godot_contract_runner.gd` with `GODOT_CONTRACTS_OK`.
- `git diff --check` on the touched runtime/test/worklog files reported only existing LF-to-CRLF normalization warnings.

### Remaining Gaps

Manual in-editor clicking was not performed in this pass. The new headless scene contract exercises the same settings panel signal path and apply-close button behavior.

## Runtime Size Pre-Edit Enforcement Completion

### Completion Summary

Strengthened the request-analysis pre-edit gate so the 500-line runtime-size policy is not only a completion-time surprise. Ledgers that touch exact debt/path-capped runtime owners, or strict-glob runtime files already at 80% or more of their cap, now need `Execution Responsibility Units` before implementation.

### Actual Outputs

- `request-analysis-gate.ps1`: parses runtime-size exact caps and strict glob caps, checks mutable-scope paths, and requires ERU coverage for monitored runtime owners.
- `request-analysis-gate.tests.ps1`: added RED/GREEN fixtures for `CharacterSelectPage.gd`, a runtime file monitored through `strict_glob_caps`.
- Request-analysis docs, ledger template, and `00_AGENTS.md`: document pre-edit glob-cap monitoring and file-size budget expectations.
- `2026-06-11-runtime-size-cap-enforcement.md`: updated to the current root-cause/resolution-proof schema.
- `docs/source-map.md`: maps the new implementation plan.

### Verification Results

- Passed: `LTL-harness/tools/request-analysis-gate.tests.ps1`
- Passed: `LTL-harness/tools/runtime-size-gate.tests.ps1`
- Passed: `LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-11-runtime-size-cap-enforcement.md -Mode pre-edit`
- Passed: `LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-11-runtime-size-cap-enforcement.md -Mode pre-complete`
- Passed: `LTL-harness/tools/runtime-size-gate.ps1 -Root .`
- Passed: `LTL-harness/tools/source-map-gate.ps1 -Root .`
- Passed: `git diff --check` with LF-to-CRLF warnings only.

### Remaining Gaps

This pass hardened the harness path only. It did not split additional Godot runtime files or run the full compile/quality gates.

## M6 Closure Completion

### Completion Summary

Closed M6 with the current workspace state ready for commit. The closure includes the combat artifact-codex pause timing fix, battle HUD floor alignment, runtime page-shell migration, node-select/character-select helper extraction, read-model suite splitting, and final gate cleanup required for the M6 checkpoint.

### Actual Outputs

- Combat codex pause now freezes terrain timing with `Timer.paused`, so combat time, energy queue state, backpack cooldown visuals, and terrain progression resume from the suspended state.
- M6 completion documentation was added under `LTL-harness/docs/11_exec-plans/02_completed/12_M6_ui_ux_finalization_completed.md`, with known manual QA gaps tracked in `docs/m6-known-issues.ko.md` and `docs/m6-manual-signoff-checklist.ko.md`.
- Runtime size pressure was reduced by extracting codex discovery, node-select art controls, shell button styling, and character-select palette logic into focused helper scripts.
- Oversized read-model suites were split into smaller battlefield/status and interaction/accessibility suites.
- Reward board layout was tightened so the confirm card no longer produces an unnecessary vertical scrollbar while keeping the full reward board inside viewport contracts.
- Release-content contract expectations were aligned with the current `storm_wyvern` scan unlock ID.

### Verification Results

- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-13-root-cause-anti-workaround-gate.md`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_codex_pause_timing_contract.gd`
- The full compile check reported existing Godot RID/resource leak warnings during shutdown, but exited successfully with `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`.
- The compile check also reported legacy oversized test-file warnings; `TEST_SIZE_GATE_OK` still passed.

### Remaining Gaps

- Manual screenshot matrix evidence and human readability/accessibility sign-off remain documented M6 evidence gaps and roll forward as release-polish/M7+ work.

## M6 Screenshot Matrix Evidence Completion

### Completion Summary

Added repository-backed screenshot evidence for the full M6 page and viewport matrix. The matrix was captured from live Godot windows, not headless dummy renderer output, and is indexed in the evidence README.

### Actual Outputs

- `app-LTL/tests/run_m6_visual_hold.gd`: drives the live game to character select, leviathan select, node select, battle, reward, or defeat and holds the real window for capture.
- `tools/capture-m6-screenshot-matrix.ps1`: launches the live hold script across four viewports and six pages, then saves Win32 client-area PNG captures.
- `docs/evidence/m6-screenshot-matrix/2026-06-15/`: stores 24 PNG screenshots and `README.ko.md`.
- `docs/m6-manual-signoff-checklist.ko.md`: records screenshot matrix evidence, user-accepted battle readability, user-accepted game-over copy, and the remaining accessibility feel-check.
- `docs/m6-known-issues.ko.md`: reduces remaining M6 sign-off gaps to accessibility-toggle feel strength only.

### Verification Results

- Passed: `tools\capture-m6-screenshot-matrix.ps1 -SettleDelaySeconds 3` with `M6_SCREENSHOT_MATRIX_CAPTURE_OK`.
- Passed: 24 PNG files exist under `docs/evidence/m6-screenshot-matrix/2026-06-15/`.
- Passed: PNG dimensions match `1280x720`, `1440x900`, `1680x1050`, and `1920x1080` for each M6 page.
- Passed: Representative images for character select, leviathan select, node select, battle, reward, and defeat were visually spot-checked as live game screens.

### Remaining Gaps

- Accessibility-toggle code and persistence are covered, but the final "feel difference is strong enough" UX sign-off still needs human judgment.

## Node-Select Start CTA Gate Completion

### Completion Summary

Reworked node-select mining-start readiness around explicit node selection. The page now starts with no selected node, node clicks toggle selection on and off, menu overlays preserve a valid selected node, and the start button only enables for the selected current-stage node when it has not already been cleared.

### Actual Outputs

- `MainControllerRuntime.gd`: selected node defaults/resets to `-1`, selected-node context no longer clamps to the first node, and start transitions are guarded by current-stage/uncleared eligibility.
- `NodeSelectRuntimePage.gd`: fixed-start, branch, and boss nodes now participate in click-to-toggle selection.
- `MainViewRuntime.gd`: the shell CTA uses `selectedNodeStartEnabled` eligibility instead of candidate count.
- `ShellButtonStyler.gd`: disabled start CTA styling is now clearly muted compared with the active mining CTA.
- `run_node_select_start_gate_contract.gd`: covers initial disabled state, select/deselect, shop/codex round trips, branch start, and boss start.

### Verification Results

- Passed: `run_node_select_start_gate_contract.gd` with `NODE_SELECT_START_GATE_CONTRACT_OK`.
- Passed: `run_main_start_flow_contract.gd` with `MAIN_START_FLOW_CONTRACT_OK`.
- Passed: `run_node_select_runtime_contract.gd` with `NODE_SELECT_RUNTIME_CONTRACT_OK`.
- Passed: `run_main_layout_audit_contract.gd` with `MAIN_LAYOUT_AUDIT_CONTRACT_OK`.
- Passed: `godot_contract_runner.gd` with `GODOT_CONTRACTS_OK`.
- Passed: `run_settings_language_apply_contract.gd` with `SETTINGS_LANGUAGE_APPLY_CONTRACT_OK`.
- Passed: `run_battle_render_performance_contract.gd` with `BATTLE_RENDER_PERFORMANCE_CONTRACT_OK`.
- Passed: `source-map-gate.ps1 -Root .` with `SOURCE_MAP_GATE_OK`.
- `git diff --check` on touched files reported only LF-to-CRLF normalization warnings.

### Remaining Gaps

Manual in-editor menu clicking was not repeated after the headless regression pass. The new contract exercises the same shell menu round-trip path for shop and artifact codex before pressing start.

## Node-Select Drop Mouse-Over Cleanup Completion

### Completion Summary

Fixed the reported Godot `_drop_mouse_over` error in the node-select canvas rebuild path. Replaced node hotspot Controls are now detached immediately but freed at the end of the frame, leaving them valid long enough for Godot's deferred mouse-over cleanup.

### Actual Outputs

- `NodeSelectRuntimePage.gd`: `_clear_container()` now uses `remove_child()` plus `queue_free()` instead of immediate `free()`.
- `run_node_select_runtime_contract.gd`: added a regression contract for replaced hotspot lifetime during a forced canvas rebuild.
- Updated today's worklog plan/history/completion notes for the follow-up error.

### Verification Results

- RED observed before fix: `run_node_select_runtime_contract.gd` failed on the replaced hotspot already being invalid.
- Passed: `run_node_select_runtime_contract.gd` with `NODE_SELECT_RUNTIME_CONTRACT_OK`.
- Passed: `run_node_select_start_gate_contract.gd` with `NODE_SELECT_START_GATE_CONTRACT_OK`.
- Passed: `run_main_start_flow_contract.gd` with `MAIN_START_FLOW_CONTRACT_OK`.
- Passed: `run_main_layout_audit_contract.gd` with `MAIN_LAYOUT_AUDIT_CONTRACT_OK`.
- Passed: `godot_contract_runner.gd` with `GODOT_CONTRACTS_OK`; existing shutdown RID/resource leak warnings still appear.
- Passed: `source-map-gate.ps1 -Root .` with `SOURCE_MAP_GATE_OK`.
- New focused/flow/layout logs contain no `_drop_mouse_over` or `Cannot convert argument 1` occurrence.
- `git diff --check` on touched files reported only LF-to-CRLF normalization warnings.

### Remaining Gaps

The exact live mouse path was not manually replayed in the editor. The regression covers the root lifetime condition that produced the internal deferred cleanup error.

## Shop Disable and Node-Select Preservation Completion

### Completion Summary

Blocked the unfinished shop flow and restored node-select stability independent of shop state. Shop buttons now present as disabled, direct overlay visibility requests cannot force the shop open, and forced buy signals return without mutating the run or replacing the decorated node-select scene model.

### Cause Analysis

- The node-select page is not implemented as two competing pages. `MainViewRuntime` registers one `NodeSelectRuntimePage`; the shop is a separate `ShopPanelUI` overlay.
- The shop was still functionally wired even though it was unfinished. A passive purchase could call the headless run and assign its raw snapshot to `current_scene`.
- That raw snapshot lacks the decorated nested `nodeSelect` structure expected by the runtime page, which caused current route candidates to disappear on the node-select screen.
- A separate routing defect allowed boss candidates into non-final stages, so a stage-two node could incorrectly start `boss_battle`.

### Actual Outputs

- `MainControllerRuntime.gd`: added disabled-shop guards for open/passive/base-item handlers, keeps forced signals from mutating state, and preserves the decorated scene path for future enabled purchases.
- `MainViewRuntime.gd`: blocks shop overlay visibility/toggle while disabled and keeps the disabled shop button state visible.
- `ShopPanelUI.gd`: disables purchase buttons and blocks buy signal emission while the feature is off.
- `NodeSelectRuntimePage.gd`: disables the node-select shop button and blocks its request signal.
- `NodeVocab.gd`: excludes boss nodes from non-final route candidate pools.
- Tests now cover disabled shop entry, forced buy-signal preservation, forced overlay visibility rejection, non-final boss exclusion, and the existing node-select/start/layout flows.

### Verification Results

- Passed: `run_node_select_start_gate_contract.gd` with `NODE_SELECT_START_GATE_CONTRACT_OK`.
- Passed: `run_test_node_routing_contract.gd` with `NODE_ROUTING_TESTS_OK`.
- Passed: `run_node_select_runtime_contract.gd` with `NODE_SELECT_RUNTIME_CONTRACT_OK`.
- Passed: `run_main_start_flow_contract.gd` with `MAIN_START_FLOW_CONTRACT_OK`.
- Passed: `run_main_layout_audit_contract.gd` with `MAIN_LAYOUT_AUDIT_CONTRACT_OK`.
- Passed: `godot_contract_runner.gd` with `GODOT_CONTRACTS_OK`; existing shutdown RID/resource leak warnings still appear.
- Passed: `git diff --check`; output had only LF-to-CRLF normalization warnings.

### Remaining Gaps

The shop remains intentionally disabled until its economy/UI behavior is implemented. No manual in-editor click replay was performed after the headless contract pass.

## Main Controller Ownership Split Planning Pause

### Completion Summary

Analyzed the requested `MainController.gd` / `MainControllerRuntime.gd` ownership problem and prepared the implementation path, but did not edit runtime code yet because the selected design needs approval before crossing the brainstorming gate.

### Actual Outputs

- Updated today's worklog plan for the controller ownership split.
- Added `docs/request-ledgers/2026-06-15-main-controller-ownership-split.md` with source-map findings, root-cause review, transition/performance risks, execution responsibility units, and verification checklist.

### Verification Results

- Passed: `LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-15-main-controller-ownership-split.md -Mode pre-edit` with `REQUEST_ANALYSIS_GATE_OK`.
- Read-only inspection confirmed:
  - `Main.tscn` attaches `res://src/MainController.gd` to the `MainController` node.
  - `MainController.gd` only extends `res://src/MainControllerRuntime.gd`.
  - `MainControllerRuntime.gd` is 1731 lines.
  - `docs/architectural-gates/runtime-size-gate.md` still freezes `MainControllerRuntime.gd` at 1667 lines, so current growth needs a split rather than a cap increase.

### Blockers Or Unverified Areas

- Runtime code was not modified and no Godot runtime tests were run in this planning slice.
- User approval is needed before moving controller ownership and extracting helpers.

### Remaining Gaps

- Implement the approved structure.
- Run request-analysis pre-edit gate, focused controller contracts, runtime-size gate, source-map gate, and compile check after implementation.

## Main Controller Ownership Split Completion

### Completion Summary

Implemented the approved ownership split. `MainController.gd` is no longer an empty facade; it now owns the scene controller body directly. `MainControllerRuntime.gd` was deleted from active runtime ownership, and the lowest-coupled controller responsibilities were extracted into focused helper scripts.

### Actual Outputs

- `app-LTL/src/MainController.gd`: real scene controller implementation, with wrapper methods preserving existing signal/test call surfaces.
- Deleted `app-LTL/src/MainControllerRuntime.gd`.
- Added:
  - `app-LTL/src/controllers/MainControllerStartFlow.gd`
  - `app-LTL/src/controllers/MainControllerNodeSelection.gd`
  - `app-LTL/src/controllers/MainControllerCombatInput.gd`
  - `app-LTL/src/controllers/MainControllerAccessibilityStore.gd`
- Updated direct controller preloads in focused tests from the runtime script to `MainController.gd`.
- Updated `godot_contract_runner.gd`, `docs/source-map.md`, `docs/architectural-gates/runtime-size-gate.md`, the request ledger, and the implementation plan.

### Changes From Plan

The remaining stateful controller orchestration was kept in `MainController.gd` instead of being forced into a risky reward/backpack split in the same pass. That file is still large at 1473 lines, so it is frozen as explicit orchestration debt in `runtime-size-gate.md`; the deleted runtime file is no longer the hidden implementation owner.

### Verification Results

- RED: `run_test_ui_read_models.gd` failed before implementation because the required controller helper scripts were missing.
- Passed: `run_test_ui_read_models.gd` with `UI_READ_MODEL_TESTS_OK`.
- Passed: `run_i18n_localization_smoke.gd` with `I18N_LOCALIZATION_SMOKE_OK`.
- Passed: `run_codex_pause_timing_contract.gd` with `CODEX_PAUSE_TIMING_CONTRACT_OK`.
- Passed: `run_main_start_flow_contract.gd` with `MAIN_START_FLOW_CONTRACT_OK`.
- Passed: `run_node_select_start_gate_contract.gd` with `NODE_SELECT_START_GATE_CONTRACT_OK`.
- Passed: `run_battle_render_performance_contract.gd` with `BATTLE_RENDER_PERFORMANCE_CONTRACT_OK`.
- Passed: `godot_contract_runner.gd` with `GODOT_CONTRACTS_OK`.
- Passed: `source-map-gate.ps1 -Root .` with `SOURCE_MAP_GATE_OK`.
- `git diff --check` on current request files reported only LF-to-CRLF normalization warnings.

### Blockers Or Unverified Areas

- `runtime-size-gate.ps1 -Root .` fails because pre-existing dirty `app-LTL/src/ui/MainViewRuntime.gd` is 2479 lines while its frozen cap is 2429.
- `run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-15-main-controller-ownership-split.md` passes source-map, request-analysis, and test-size gates, then stops at that same unrelated runtime-size blocker.
- Existing Godot RID/resource leak warnings still appear in some successful headless runs.

### Remaining Gaps

- A follow-up pass should split the still-large `MainController.gd` reward/backpack orchestration and reduce or remove its 1473-line frozen debt cap.
- The unrelated `MainViewRuntime.gd` cap breach must be resolved before the full compile-check pipeline can pass again.

## Main Controller Follow-Up Split Completion

### Completion Summary

Performed the requested additional split and deleted unnecessary controller wrapper code where references proved it was safe. `MainController.gd` now delegates display-label formatting and scene snapshot projections to focused helpers, and tests call the already-extracted combat helper directly instead of preserving static compatibility wrappers on the main controller.

### Actual Outputs

- Added `app-LTL/src/controllers/MainControllerDisplayText.gd` for localized artifact, rarity, color, passive, shop item, and toggle labels.
- Added `app-LTL/src/controllers/MainControllerSceneProjection.gd` for active queue color, current target, and node-select summary projection.
- Removed obsolete private/static wrappers from `MainController.gd`, including unused start-flow row builders, unused node-selection wrappers, display label wrappers, scene projection wrappers, and combat static compatibility wrappers.
- Updated tests, `godot_contract_runner.gd`, `docs/source-map.md`, `docs/architectural-gates/runtime-size-gate.md`, and the request ledger.
- Reduced the `MainController.gd` frozen cap from 1473 to 1279 lines; all `MainController*.gd` helper scripts are below 500 lines.

### Verification Results

- RED: `run_test_ui_read_models.gd` failed before implementation on missing follow-up helper scripts and remaining obsolete wrappers.
- Passed: `run_test_ui_read_models.gd` with `UI_READ_MODEL_TESTS_OK`.
- Passed: `run_i18n_localization_smoke.gd` with `I18N_LOCALIZATION_SMOKE_OK`.
- Passed: `run_codex_pause_timing_contract.gd` with `CODEX_PAUSE_TIMING_CONTRACT_OK`.
- Passed: `run_main_start_flow_contract.gd` with `MAIN_START_FLOW_CONTRACT_OK`.
- Passed: `run_node_select_start_gate_contract.gd` with `NODE_SELECT_START_GATE_CONTRACT_OK`.
- Passed: `run_battle_render_performance_contract.gd` with `BATTLE_RENDER_PERFORMANCE_CONTRACT_OK`.
- Passed: `godot_contract_runner.gd` with `GODOT_CONTRACTS_OK`.
- Passed: `source-map-gate.ps1 -Root .` with `SOURCE_MAP_GATE_OK`.
- Passed: `request-analysis-gate.ps1 -Mode pre-complete` with `REQUEST_ANALYSIS_GATE_OK`.
- Passed: `git diff --check` on touched request files; output only had LF-to-CRLF normalization warnings.

### Blockers Or Unverified Areas

- `runtime-size-gate.ps1 -Root .` still fails on the pre-existing unrelated `app-LTL/src/ui/MainViewRuntime.gd` cap breach: 2479 lines over its frozen 2429-line cap.
- `run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-15-main-controller-ownership-split.md` passes source-map, request-analysis, and test-size gates, then stops at the same unrelated runtime-size blocker.
- Some successful Godot headless runs still report existing shutdown RID/resource leak warnings.

### Remaining Gaps

`MainController.gd` still owns stateful reward/backpack orchestration. That area was intentionally left for a separate RED/GREEN split because it mutates shared controller, inventory, reward, and growth state.

## Main Controller 500-Line Split Completion

### Completion Summary

Finished the requested deeper split. `MainController.gd` is now a 393-line scene-facing controller, not an empty facade and not a hidden 1000+ line runtime owner. The remaining controller logic is delegated to feature-sized helpers, and obsolete micro helpers were merged or deleted.

### Actual Outputs

- `app-LTL/src/MainController.gd`: reduced to 393 lines; keeps Godot signal wrappers, exported constants, and scene-facing orchestration only.
- Final helpers:
  - `MainControllerRewardBackpackFlow.gd` for reward tray, backpack drag/drop, placement, discard, and claim side effects.
  - `MainControllerCombatFlow.gd` for combat click/hover/hold-fire/timers/terrain/queue plus merged combat input/projection helpers.
  - `MainControllerRunFlow.gd` for start/reset/loadout/character/leviathan/node-selection flow.
  - `MainControllerRenderFlow.gd` for scene decoration, page id resolution, render handoff, and reward rendering.
  - `MainControllerSupportFlow.gd` for shop-disabled behavior, codex, growth, shop telemetry, and merged accessibility persistence.
  - `MainControllerBootstrapFlow.gd` for ready-time bootstrap and signal wiring.
  - `MainControllerDisplayText.gd` for shared display-label formatting.
- Deleted obsolete helper files: `MainControllerRuntime.gd`, `MainControllerStartFlow.gd`, `MainControllerNodeSelection.gd`, `MainControllerCombatInput.gd`, `MainControllerAccessibilityStore.gd`, and `MainControllerSceneProjection.gd`.
- Updated tests, source map, runtime-size cap, request ledger, and the 500-line split plan.

### Verification Results

- Passed: `run_test_ui_read_models.gd` -> `UI_READ_MODEL_TESTS_OK`.
- Passed: `godot_contract_runner.gd` -> `GODOT_CONTRACTS_OK`.
- Passed focused contracts: `MAIN_START_FLOW_CONTRACT_OK`, `NODE_SELECT_START_GATE_CONTRACT_OK`, `START_OPTION_CONTRACT_OK`, `REWARD_HANDOFF_CONTRACT_OK`, `SETTINGS_LANGUAGE_APPLY_CONTRACT_OK`, `CODEX_PAUSE_TIMING_CONTRACT_OK`, and `BATTLE_RENDER_PERFORMANCE_CONTRACT_OK`.
- Passed: `source-map-gate.ps1 -Root .` -> `SOURCE_MAP_GATE_OK`.
- Passed: `test-size-gate.ps1 -Root .` -> `TEST_SIZE_GATE_OK` with legacy oversized-test warnings only.
- Passed: `request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-15-main-controller-ownership-split.md -Mode pre-complete` -> `REQUEST_ANALYSIS_GATE_OK`.
- Passed: `git diff --check`; output had only LF-to-CRLF normalization warnings.

### Blockers Or Unverified Areas

- `runtime-size-gate.ps1 -Root .` still fails on unrelated existing debt: `app-LTL/src/ui/MainViewRuntime.gd` is 2479 lines over its frozen 2429-line cap.
- `run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-15-main-controller-ownership-split.md` passes source-map, request-analysis, and test-size gates, then stops at the same unrelated `MainViewRuntime.gd` runtime-size blocker.
- Some successful Godot headless runs still print existing shutdown RID/resource leak warnings.

### Remaining Gaps

- Full compile-check can pass only after the unrelated `MainViewRuntime.gd` runtime-size debt is resolved.

## Drill Image Reward Backpack Fix Completion

### Completion Summary

Fixed the reward-list backpack rendering path for image-backed drills. Drill images now use the same canvas-aware slot footprint as the docked reward backpack, render without the colored artifact background overlay, and fill their grid square/footprint more aggressively. Cooldown and drop-cue overlays remain available above the image layer.

### Actual Outputs

- Updated `BackpackUI.gd` image overlay placement to use transformed slot corners in image-layer space.
- Switched drill item images and drag ghosts to `STRETCH_KEEP_ASPECT_COVERED` so the art fills the assigned square/footprint.
- Suppressed the colored artifact overlay only for image-backed drills; non-image items keep the existing colored box presentation.
- Made slot overlay z-order explicit in `BackpackGridFactory.gd` so cooldown masks and drop cues draw above item art.
- Added reward-board and UI read-model tests for image placement, image-only rendering, cooldown overlay preservation, drill art paths, and transformed rect calculation.

### Verification Results

- Passed: `run_test_ui_read_models.gd` -> `UI_READ_MODEL_TESTS_OK`.
- Passed: `run_reward_claim_board_contract.gd` with exit code 0.
- Passed: `godot_contract_runner.gd` -> `GODOT_CONTRACTS_OK`.
- Passed: `git diff --check`; output had only LF-to-CRLF normalization warnings.

### Blockers Or Unverified Areas

- No in-editor visual screenshot was captured in this run.
- Successful Godot headless runs still print existing shutdown RID/resource leak warnings.

## Reward Backpack Drill Drift Follow-Up Completion

### Completion Summary

Fixed the remaining reward-list-only drill image drift. The backpack now tracks the grid's position relative to the image layer and rebuilds image-backed artifact overlays when reward layout movement changes that relationship, so the basic drill image follows the actual slot center after docking settles.

### Actual Outputs

- Added image layout signature state to `BackpackUI.gd`.
- Added `artifact_image_layout_signature()` and `refresh_artifact_images_if_layout_changed()` to `BackpackArtifactRenderer.gd`.
- Added a reward-board regression check for position-only grid drift in `test_reward_claim_board_contract.gd`.
- Updated the active worklog plan to use the `res://` Godot script invocation that actually runs the deferred SceneTree runner.

### Verification Results

- RED: `res://tests/run_reward_claim_board_contract.gd` reported `reward workspace drill image follows grid position-only layout drift` with a 24px center offset before the fix.
- Green for the targeted failure: after the fix, that drift failure no longer appears in `res://tests/run_reward_claim_board_contract.gd`.
- Passed: `res://tests/run_test_ui_read_models.gd` -> `UI_READ_MODEL_TESTS_OK`.
- Passed: `res://tests/godot_contract_runner.gd` -> `GODOT_CONTRACTS_OK`.
- Passed: `git diff --check`; output had only LF-to-CRLF normalization warnings.

### Blockers Or Unverified Areas

- Full `res://tests/run_reward_claim_board_contract.gd` still exits 1 due unrelated live reward boot/layout failures such as staying on `node_select`; the new drill drift failure is no longer present.
- No in-editor screenshot was captured for this follow-up.
- Successful Godot headless runs still print existing shutdown RID/resource leak warnings.

## Active Source 500-Line Split Completion

### Completion Summary

Completed the repeated feature-unit split cycle for active Godot source and scene files. No `app-LTL/src/**/*.gd` or `app-LTL/src/**/*.tscn` file now exceeds 500 lines, and the runtime-size gate no longer needs any legacy debt exception for the split targets.

### Actual Outputs

- Split oversized owners by coherent runtime responsibilities:
  - `CombatVocab.gd` into combat relic hook, terrain effect, and obstacle definition helpers.
  - `StatusPanelUI.gd` into status-panel info card helpers.
  - `BackpackUI.gd` into artifact rendering and pin overlay runtime helpers.
  - `ArtifactCodexPanelUI.gd` into codex layout and book visual helpers.
  - `RewardRevealOverlay.gd` into presentation, layout, animation, ceremony, and effect helpers.
  - `NodeSelectRuntimePage.gd` into visual factory, layout policy, roadmap rendering, content model, and composer helpers.
  - `MainViewRuntime.gd` into runtime state, lifecycle, reward, presentation, reward layout, page shell, app shell, scene, panels, locale, chrome, backpack, and feedback helpers.
- Removed verified-unused MainView private compatibility wrappers after split/test/delete checks.
- Updated focused UI tests, `godot_contract_runner.gd`, `docs/source-map.md`, and `docs/architectural-gates/runtime-size-gate.md`.

### Verification Results

- Passed: `run_test_ui_read_models.gd` -> `UI_READ_MODEL_TESTS_OK`.
- Passed: `godot_contract_runner.gd` -> `GODOT_CONTRACTS_OK`.
- Passed: direct line-count inventory over `app-LTL/src/**/*.gd` and `app-LTL/src/**/*.tscn`; no files over 500 lines were printed.
- Passed: `runtime-size-gate.ps1 -Root .` -> `RUNTIME_SIZE_GATE_OK`.
- Passed: `git diff --check`; output had only LF-to-CRLF normalization warnings.

### Blockers Or Unverified Areas

- `source-map-gate.ps1 -Root .` still fails on unrelated missing mapped drill image files and `.import` files under `app-LTL/resources/items/drill/`.
- Successful Godot headless runs still print existing shutdown RID/resource leak warnings.

### Remaining Gaps

- The source-size objective is complete. Source-map cleanup for the missing drill image artifacts remains separate from the feature-unit split work.

## Feature Unit Lifecycle Harness Completion

### Completion Summary

Applied the completed 500-line refactor analysis back into the harness. Future request ledgers that touch source or harness implementation surfaces must now declare how the work stays split by feature unit across design, implementation, and maintenance.

### Actual Outputs

- Added `Feature Unit Lifecycle Plan` enforcement to `LTL-harness/tools/request-analysis-gate.ps1`.
- Added RED/GREEN self-test coverage in `LTL-harness/tools/request-analysis-gate.tests.ps1`.
- Updated `LTL-harness/docs/request-analysis-execution-gate.md`, `LTL-harness/docs/templates/request-constraint-ledger-template.md`, and `LTL-harness/00_AGENTS.md`.
- Added `docs/request-ledgers/2026-06-15-feature-unit-lifecycle-harness.md`.
- Updated `docs/source-map.md` for the changed harness responsibilities and new ledger.

### Verification Results

- RED: `request-analysis-gate.tests.ps1` failed before implementation on the missing feature-unit lifecycle plan fixture.
- Passed: `request-analysis-gate.tests.ps1` -> `REQUEST_ANALYSIS_GATE_TESTS_OK`.
- Passed: lifecycle harness ledger pre-edit gate -> `REQUEST_ANALYSIS_GATE_OK`.
- Passed: lifecycle harness ledger pre-complete gate with artifact ledger -> `REQUEST_ANALYSIS_GATE_OK`.
- Passed: `runtime-size-gate.ps1 -Root .` -> `RUNTIME_SIZE_GATE_OK`.

### Blockers Or Unverified Areas

- `source-map-gate.ps1 -Root .` still fails on pre-existing missing drill image files and `.import` files under `app-LTL/resources/items/drill/`.
- No Godot runtime test was needed for this harness-only methodology change.

### Remaining Gaps

- The lifecycle methodology is now enforced for future ledgers, but existing old ledgers are not automatically rewritten.
