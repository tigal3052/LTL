# Scene And Script Runtime Inventory Audit

> **For agentic workers:** Use this audit before deleting Godot scenes or GDScript files. It separates current debug-runtime ownership from test/probe-only, prototype, and migration-required legacy surfaces.

**Goal:** Exhaustively classify `app-LTL` `.tscn` scenes and `.gd` scripts against the actual debug runtime screen, not the editor-open `Main.tscn` preview.

**Runtime Root:** `app-LTL/project.godot -> run/main_scene="res://src/Main.tscn"`.

**Audit Method:** Static reference graph from `.tscn` `ext_resource` paths, GDScript `preload/load/ResourceLoader.exists`, string `res://*.gd|*.tscn` paths, `extends "res://..."`, and `class_name` token references. This intentionally over-approximates runtime reachability; therefore `runtime_reachable` means "do not delete without a focused migration," while `test_reachable_only` is the stronger deletion/move signal.

---

## Summary

- Total audited files: 171
- `.gd` scripts: 156
- `.tscn` scenes: 15
- Runtime-reachable files from `res://src/Main.tscn`: 97
- Test/probe-only files under `res://tests/**`: 54
- `src` files reachable only from tests/probes: 12
- Preserved prototype files under `res://prototype/**`: 8
- Unreferenced `res://src/**` `.gd`/`.tscn` orphan files after the first cleanup slice: 0

## Screenshot Diagnosis

- Image #1 is the editor preview of `Main.tscn`. It shows the static `RootMargin/AppShell` composition: header, top-content row, status/sidebar/backpack, battlefield/reward panels, and action bar.
- Image #2 is the actual debug runtime start screen. It is the `character_select` meta page mounted by `MainViewRuntime.gd`; the legacy AppShell rows are hidden at runtime through `PhaseLayoutPresenter.gd`/`MainViewRuntime.gd` visibility policy.
- Therefore, the remaining cleanup target is not primarily "unreferenced files." It is legacy ownership still embedded in `Main.tscn` and `MainViewRuntime.gd` even though the current visible flow is page-scene driven.

## Scene Classification

### Runtime Scenes - Keep Until Migrated

- `res://src/Main.tscn`
- `res://src/scenes/pages/BattlePage.tscn`
- `res://src/scenes/pages/BossBattlePage.tscn`
- `res://src/scenes/pages/BossRewardPage.tscn`
- `res://src/scenes/pages/CharacterSelectPage.tscn`
- `res://src/scenes/pages/ClearPage.tscn`
- `res://src/scenes/pages/DefeatPage.tscn`
- `res://src/scenes/pages/EventNodePage.tscn`
- `res://src/scenes/pages/LeviathanSelectPage.tscn`
- `res://src/scenes/pages/NodeSelectRuntimePage.tscn`
- `res://src/scenes/pages/OutcomePage.tscn`
- `res://src/scenes/pages/RewardPage.tscn`
- `res://src/scenes/pages/StageBackdropPage.tscn`

### Test-Reachable Scene - Delete After Node-Map Legacy Migration

- `res://src/scenes/node_map/NodeMapScene.tscn`

`NodeMapScene.tscn` itself is test-reachable only, but `NodeMapScene.gd` and `NodeMapReadModel.gd` are still runtime-reachable because `MainViewRuntime.gd` directly preloads and instantiates the legacy node-map path. Do not delete the scene alone; remove the entire legacy node-map wiring as one test-first slice.

### Prototype Scene - Preserve

- `res://prototype/godot-p0/PrototypeMain.tscn`

## Runtime Script Inventory

These scripts are reachable from `res://src/Main.tscn` by static graph. Keep them unless a focused migration removes their owner first.

- `res://src/MainController.gd`
- `res://src/MainControllerRuntime.gd`
- `res://src/balance/EnergyTempoBalance.gd`
- `res://src/domain/FormalContracts.gd`
- `res://src/models/Artifact.gd`
- `res://src/models/CombatSimulator.gd`
- `res://src/models/HazardModel.gd`
- `res://src/models/InventoryModel.gd`
- `res://src/models/RunGrowthState.gd`
- `res://src/phases/BackpackOrganizePhase.gd`
- `res://src/phases/CombatEndPhase.gd`
- `res://src/phases/CombatPhase.gd`
- `res://src/phases/CombatStartPhase.gd`
- `res://src/phases/NodeSelectPhase.gd`
- `res://src/phases/PhaseReducers.gd`
- `res://src/phases/RewardLootPhase.gd`
- `res://src/phases/RunCompletePhase.gd`
- `res://src/process/CombatInputAdapter.gd`
- `res://src/process/HeadlessMiniRun.gd`
- `res://src/scenes/node_map/NodeMapScene.gd`
- `res://src/scenes/pages/CharacterSelectPage.gd`
- `res://src/scenes/pages/DefeatPage.gd`
- `res://src/scenes/pages/LeviathanSelectPage.gd`
- `res://src/scenes/pages/NodeSelectRuntimePage.gd`
- `res://src/scenes/pages/OutcomePage.gd`
- `res://src/scenes/pages/StageBackdropPage.gd`
- `res://src/ui/ArtifactCodexArtResolver.gd`
- `res://src/ui/ArtifactCodexPanelUI.gd`
- `res://src/ui/ArtifactTooltipUI.gd`
- `res://src/ui/BackpackUI.gd`
- `res://src/ui/BattlefieldUI.gd`
- `res://src/ui/BattlefieldVFX.gd`
- `res://src/ui/CellView.gd`
- `res://src/ui/CombatSceneModel.gd`
- `res://src/ui/CombatScenePreviewController.gd`
- `res://src/ui/GiantTimerUI.gd`
- `res://src/ui/InteractionFX.gd`
- `res://src/ui/LogConsoleUI.gd`
- `res://src/ui/MainUI.gd`
- `res://src/ui/MainViewRuntime.gd`
- `res://src/ui/PageSceneModelBuilder.gd`
- `res://src/ui/PageSceneRegistry.gd`
- `res://src/ui/PopupOverlayHost.gd`
- `res://src/ui/RewardCardCloudHost.gd`
- `res://src/ui/RewardRevealOverlay.gd`
- `res://src/ui/SceneReadModel.gd`
- `res://src/ui/SettingsPanelUI.gd`
- `res://src/ui/SharedBackpackHostCoordinator.gd`
- `res://src/ui/ShopPanelUI.gd`
- `res://src/ui/StatusPanelUI.gd`
- `res://src/ui/TextCatalog.gd`
- `res://src/ui/VFXManager.gd`
- `res://src/ui/presenters/AppShellLayoutPolicy.gd`
- `res://src/ui/presenters/BackpackGridFactory.gd`
- `res://src/ui/presenters/BackpackPinLayoutPolicy.gd`
- `res://src/ui/presenters/CombatFeedbackPresenter.gd`
- `res://src/ui/presenters/HeartbeatSynth.gd`
- `res://src/ui/presenters/InteractionCuePresenter.gd`
- `res://src/ui/presenters/PhaseLayoutPresenter.gd`
- `res://src/ui/presenters/RewardBoardLayoutPolicy.gd`
- `res://src/ui/presenters/RewardCeremonyPolicy.gd`
- `res://src/ui/read_models/ArtifactCodexReadModel.gd`
- `res://src/ui/read_models/FailureReadModel.gd`
- `res://src/ui/read_models/HudReadModel.gd`
- `res://src/ui/read_models/NodeMapReadModel.gd`
- `res://src/ui/read_models/NodeSelectReadModel.gd`
- `res://src/ui/read_models/RewardReadModel.gd`
- `res://src/ui/read_models/TooltipReadModel.gd`
- `res://src/ui/theme/LTLTheme.gd`
- `res://src/validation/RewardValidator.gd`
- `res://src/vocabulary/CombatVocab.gd`
- `res://src/vocabulary/NodeVocab.gd`
- `res://src/vocabulary/ReleaseContentVocab.gd`
- `res://src/vocabulary/RewardVocab.gd`
- `res://src/vocabulary/combat/RecalculateQueueColors.gd`
- `res://src/vocabulary/combat/ShiftWeaknessMarkers.gd`
- `res://src/vocabulary/combat/SpawnNewTileObstacles.gd`
- `res://src/vocabulary/node/ApplyNodeModifiers.gd`
- `res://src/vocabulary/progression/ApplyGrowthModifiers.gd`
- `res://src/vocabulary/reward/ApplyRewardEffect.gd`
- `res://src/vocabulary/reward/BuildRewardPreview.gd`
- `res://src/vocabulary/reward/BuildRewardTelemetry.gd`
- `res://src/vocabulary/reward/CreateArtifactFromReward.gd`
- `res://src/vocabulary/reward/RewardCatalogOrder.gd`

## `src` Test-Reachable-Only Scripts

These are not reached from the debug runtime root in the static graph. They are still used by formal contracts, probes, or unit suites, so deleting them requires either removing/replacing the test surface or moving them into `tests/support`.

- `res://src/process/MiniRunStageScript.gd`
- `res://src/process/NodeInputAdapter.gd`
- `res://src/process/ReplayProcess.gd`
- `res://src/tools/FormalReplayRunner.gd`
- `res://src/vocabulary/BackpackVocab.gd`
- `res://src/vocabulary/backpack/DiscardHeld.gd`
- `res://src/vocabulary/backpack/PickUpFromInventory.gd`
- `res://src/vocabulary/backpack/PickUpFromRewardTray.gd`
- `res://src/vocabulary/backpack/PlaceHeld.gd`
- `res://src/vocabulary/backpack/RecalculateSynergy.gd`
- `res://src/vocabulary/backpack/RotateHeld.gd`

## Test And Probe Scripts

All files under `res://tests/**` are not debug runtime implementation. Keep them as verification surfaces unless replacing their covered behavior.

- `res://tests/godot_contract_runner.gd`
- `res://tests/run_backpack_ui_compile_contract.gd`
- `res://tests/run_character_select_cleanup_contract.gd`
- `res://tests/run_combat_layout_containment_contract.gd`
- `res://tests/run_defeat_page_contract.gd`
- `res://tests/run_i18n_localization_smoke.gd`
- `res://tests/run_leviathan_select_visual_hold.gd`
- `res://tests/run_main_layout_audit_contract.gd`
- `res://tests/run_main_start_flow_contract.gd`
- `res://tests/run_main_viewport_probe.gd`
- `res://tests/run_node_map_scene_smoke.gd`
- `res://tests/run_node_select_runtime_contract.gd`
- `res://tests/run_node_select_visual_capture.gd`
- `res://tests/run_node_select_visual_hold.gd`
- `res://tests/run_page_scene_mapping_contract.gd`
- `res://tests/run_pin_miner_layout_probe.gd`
- `res://tests/run_reward_ceremony_contract.gd`
- `res://tests/run_reward_claim_board_contract.gd`
- `res://tests/run_reward_cleanup_layout_contract.gd`
- `res://tests/run_reward_handoff_contract.gd`
- `res://tests/run_reward_inspector_stability_contract.gd`
- `res://tests/run_reward_reveal_front_contract.gd`
- `res://tests/run_start_option_contract.gd`
- `res://tests/run_test_combat_vocab.gd`
- `res://tests/run_test_node_routing_contract.gd`
- `res://tests/run_test_reward_contract.gd`
- `res://tests/run_test_ui_read_models.gd`
- `res://tests/support/UiReadModelTestSuite.gd`
- `res://tests/test_backpack_vocab.gd`
- `res://tests/test_combat_vocab.gd`
- `res://tests/test_formal_replay_runner.gd`
- `res://tests/test_node_map_scene_smoke.gd`
- `res://tests/test_node_routing_contract.gd`
- `res://tests/test_release_content_contract.gd`
- `res://tests/test_reward_claim_board_contract.gd`
- `res://tests/test_reward_contract.gd`
- `res://tests/test_start_option_contract.gd`
- `res://tests/test_ui_read_models.gd`
- `res://tests/ui_read_models/ui_app_shell_layout_policy_suite.gd`
- `res://tests/ui_read_models/ui_backpack_layout_suite.gd`
- `res://tests/ui_read_models/ui_battlefield_hud_suite.gd`
- `res://tests/ui_read_models/ui_codex_reward_board_suite.gd`
- `res://tests/ui_read_models/ui_defeat_visual_suite.gd`
- `res://tests/ui_read_models/ui_interaction_controller_suite.gd`
- `res://tests/ui_read_models/ui_overlay_contract_suite.gd`
- `res://tests/ui_read_models/ui_page_scene_model_builder_suite.gd`
- `res://tests/ui_read_models/ui_page_scene_registry_suite.gd`
- `res://tests/ui_read_models/ui_phase_layout_suite.gd`
- `res://tests/ui_read_models/ui_reward_board_layout_policy_suite.gd`
- `res://tests/ui_read_models/ui_reward_card_cloud_host_suite.gd`
- `res://tests/ui_read_models/ui_reward_reveal_ceremony_suite.gd`
- `res://tests/ui_read_models/ui_reward_reveal_layout_suite.gd`
- `res://tests/ui_read_models/ui_shared_backpack_host_coordinator_suite.gd`
- `res://tests/ui_read_models/ui_text_tooltip_suite.gd`

## Prototype Inventory - Preserve

- `res://prototype/godot-p0/PrototypeMain.tscn`
- `res://prototype/godot-p0/PrototypeController.gd`
- `res://prototype/godot-p0/domain/EnergyQueue.gd`
- `res://prototype/godot-p0/domain/MiningResolver.gd`
- `res://prototype/godot-p0/domain/RunSimulator.gd`
- `res://prototype/godot-p0/domain/SeededRng.gd`
- `res://prototype/godot-p0/telemetry/Telemetry.gd`
- `res://prototype/godot-p0/tools/replay_runner.gd`

## Main-Process Cleanup Candidates

### 1. Legacy Node Map Path

Status: highest-confidence code deletion candidate, but not a single-file delete.

Evidence:

- `res://src/scenes/node_map/NodeMapScene.tscn` is test-reachable only.
- `res://src/scenes/node_map/NodeMapScene.gd` remains runtime-reachable only because `MainViewRuntime.gd` preloads `NodeMapSceneScript` and calls `_create_node_map_scene()`.
- `res://src/ui/read_models/NodeMapReadModel.gd` remains coupled to that legacy path.
- The current page scene is `res://src/scenes/pages/NodeSelectRuntimePage.tscn`, which owns the visible runtime node-select page.

Required deletion wave:

- Add a failing contract that `node_select` works through `NodeSelectRuntimePage` without `node_map_scene`.
- Remove `NodeMapReadModelScript`, `NodeMapSceneScript`, `node_map_scene`, `node_select_map_host`, `_create_node_map_scene()`, and node-map render/rerender branches from `MainViewRuntime.gd`.
- Remove `node_map_scene` and `node_select_map_host` parameters from `SharedBackpackHostCoordinator.gd` if no longer needed.
- Replace/delete tests that directly exercise the legacy map: `test_node_map_scene_smoke.gd`, `run_node_map_scene_smoke.gd`, legacy probe references in viewport/pin-miner tests, and `godot_contract_runner.gd` required-scene entries.
- Delete `NodeMapScene.gd`, `NodeMapScene.tscn`, and `NodeMapReadModel.gd` only after `run_main_start_flow_contract`, `run_main_layout_audit_contract`, `run_node_select_runtime_contract`, `run_test_ui_read_models`, and `run-compile-check` pass.

### 2. `Main.tscn` Static AppShell Legacy Layout

Status: real target behind Image #1, but migration-required.

Evidence:

- `Main.tscn` contains 183 node declarations.
- Only `RepairOverlay`, `ConfirmOverlay`, `SettingsPanel`, and one internal status row are default-hidden in the scene file.
- Header, top-content, sidebars, backpack, active battlefield/reward panels, and action bar are visible in the editor preview before `MainViewRuntime.gd` applies runtime page visibility.
- Runtime meta pages hide these via layout policy, which is why Image #2 is correct.

Not safe to delete immediately:

- `TopContent`, `LeftColumn`, `StatusPanel`, `BackpackContainer`, `RightSidebar`, `ActionBar`, `BattlefieldPanel`, and `RewardPanel` are still actively referenced by `MainViewRuntime.gd` and layout tests.
- Existing contracts explicitly assert combat/reward layout behavior against those nodes.

Required migration waves:

- Move battle battlefield ownership from `Main.tscn/ActivePhaseContainer/BattlefieldPanel` into `BattlePage.tscn` and `BossBattlePage.tscn`, then delete old battlefield subtree and matching onready paths.
- Move reward board ownership from `Main.tscn/ActivePhaseContainer/RewardPanel` into `RewardPage.tscn` and `BossRewardPage.tscn`, then delete old reward subtree and matching onready paths.
- Move or retire shared status/sidebar/log/backpack shell ownership after each active gameplay page owns the required pieces.
- Move `ActionBar` behavior into page-local controls or controller commands, then delete the old bottom action bar.
- Move `SettingsPanel`, `ConfirmOverlay`, and `RepairOverlay` into dedicated overlay owners before deleting their root scene nodes.

### 3. `ParticleTemplate`

Status: suspicious but needs one focused behavior decision.

Evidence:

- `Main.tscn` has `ParticleTemplate` as a `CPUParticles2D`.
- `VFXManager.gd` exposes `@export var particle_template: CPUParticles2D`.
- Current `Main.tscn` text does not show `particle_template = NodePath(...)` or another assignment linking `ParticleTemplate` into `VFXManager`.
- If `particle_template` is null, `spawn_hit_particles()` returns without spawning particles.

Required decision:

- If hit particles are still required, add a contract proving `VFXManager` has a configured particle template in `Main.tscn`, then wire it correctly.
- If hit particles are no longer required, remove `ParticleTemplate` and simplify/contract `spawn_hit_particles()` as a no-op or remove that branch.

### 4. Test/Formal-Only `src` Scripts

Status: not debug runtime, but not junk.

These can be moved under tests or retained as formal harness support:

- `MiniRunStageScript.gd`
- `NodeInputAdapter.gd`
- `ReplayProcess.gd`
- `FormalReplayRunner.gd`
- `BackpackVocab.gd` and `src/vocabulary/backpack/**`

Do not delete them until their tests are removed or rewritten, because they preserve formal behavior coverage outside the visible game screen.

## Recommended Next Deletion Order

1. Node-map legacy deletion wave.
2. ParticleTemplate decision wave.
3. Battle page migration out of `Main.tscn`.
4. Reward page migration out of `Main.tscn`.
5. AppShell/sidebar/action-bar deletion after battle/reward migrations.
6. Overlay ownership migration.
7. Optional formal/test-only source relocation under `tests/support`.

## Verification Gate For Each Wave

- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_start_flow_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
