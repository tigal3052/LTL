# Codex Worklog History

Workspace: LootingTheLeviathan
Date: 2026-06-16

No implementation history has been recorded yet.
## 2026-06-16 00:00:31

<!-- codex-worklog-signature: c207db44212213e91768d5aa38b8f2890f8c8ab69e5c1ee7492226181bdacc78 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M app-LTL/src/MainController.gd
 D app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/reward-table.json
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/ui/ArtifactCodexArtResolver.gd
 M app-LTL/src/ui/ArtifactCodexPanelUI.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/RewardCardCloudHost.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/BackpackGridFactory.gd
 M app-LTL/src/ui/presenters/ShellButtonStyler.gd
 M app-LTL/src/vocabulary/CombatVocab.gd
 M app-LTL/src/vocabulary/NodeVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/run_codex_pause_timing_contract.gd
 M app-LTL/tests/run_i18n_localization_smoke.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_node_select_runtime_contract.gd
 M app-LTL/tests/run_reward_handoff_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-16 Shared Backpack Panel Integration

- Intent: Remove page-local backpack panel instances so battle, reward, and boss surfaces share one live backpack object and therefore one artifact placement path.
- Files or areas touched:
```text
app-LTL/src/scenes/pages/shells/BackpackEnginePanel.tscn
app-LTL/src/scenes/pages/shells/SharedBackpack.tscn
app-LTL/src/scenes/pages/shells/GameplayTopContent.tscn
app-LTL/src/ui/MainViewRuntime.gd
app-LTL/src/ui/main_view/MainViewRuntimeState.gd
app-LTL/src/ui/main_view/MainViewLifecycleRuntime.gd
app-LTL/src/ui/main_view/MainViewBackpackRuntime.gd
app-LTL/src/ui/main_view/MainViewPageShellRuntime.gd
app-LTL/src/ui/main_view/MainViewAppShellRuntime.gd
app-LTL/src/ui/main_view/MainViewRewardLayoutRuntime.gd
app-LTL/src/ui/main_view/MainViewPanelsRuntime.gd
app-LTL/src/scenes/pages/CharacterSelectPage.gd
app-LTL/tests/ui_read_models/ui_backpack_layout_suite.gd
app-LTL/tests/run_character_select_cleanup_contract.gd
app-LTL/tests/run_reward_handoff_contract.gd
app-LTL/tests/run_main_layout_audit_contract.gd
```
- Root cause: `GameplayTopContent.tscn` was instanced separately by battle/reward/boss pages, so each page owned its own `BackpackEnginePanel`. The previous "shared" dock logic only moved whichever page-local backpack was active.
- Actual change summary: Split the backpack panel into `BackpackEnginePanel.tscn`, wrapped it in `SharedBackpack.tscn`, left `GameplayTopContent.tscn` with an empty host, and made `MainViewBackpackRuntime` instantiate/connect/render a single shared backpack. Surface bundles now cache only `backpackHost`, while reward docking reparents the shared instance. Character select Slot1 now creates `ItemImage` from the selected color's basic/common drill texture using the shared drill display helper.
- Plan impact: Followed the implementation plan. The live Node can still have only one parent at a time, so sharing is implemented by reparenting one `SharedBackpackContainer` between active hosts.
- Verification: RED tests failed first for missing `SharedBackpack.tscn`, embedded page-local backpack panels, missing shared runtime helpers, and missing character-select Slot1 image. Green checks passed: `run_test_ui_read_models.gd`, `run_character_select_cleanup_contract.gd`, `run_reward_handoff_contract.gd`, `run_main_layout_audit_contract.gd`, `godot_contract_runner.gd`, and `git diff --check`. `run_reward_claim_board_contract.gd` still fails on an existing live flow issue where that contract remains on `node_select`.

## 2026-06-16 Idle Drill Image Padding Fix

- Intent: Fix the idle-state reward backpack drill image appearing left of its cell center while drag-state placement looked correct.
- Files or areas touched:
```text
app-LTL/src/ui/backpack/BackpackArtifactRenderer.gd
app-LTL/src/ui/BackpackUI.gd
app-LTL/tests/ui_read_models/ui_defeat_visual_suite.gd
docs/codex-worklog/plan_LootingTheLeviathan_2026-06-16.md
```
- Root cause: The initial alpha-bounded trim used the asymmetric visible-drill bounds as the display-region center. That made the idle image larger, but changed the apparent anchor from the original source center and moved the reward-list drill left/up compared with the battle page.
- Actual change summary: Changed `drill_display_texture()` to build a source-centered display region that preserves the artifact shape aspect, so 1x1 common/basic drills use a centered square atlas and 1x2 rare drills keep a vertical target aspect. Added `apply_item_image_placement()` as the shared TextureRect placement helper and routed both idle item images and drill drag ghosts through it. Updated UI read-model coverage for centered square common-drill regions and shared placement.
- Plan impact: Stayed within image-backed drill rendering; non-image item rendering, cooldown overlays, drag rules, inventory placement, and controller flow were left unchanged.
- Verification: RED: `run_test_ui_read_models.gd` failed on the old `638x859` non-square atlas and missing shared placement helper. Green: `run_test_ui_read_models.gd` passed with `UI_READ_MODEL_TESTS_OK`; `godot_contract_runner.gd` passed with `GODOT_CONTRACTS_OK`; `git diff --check` reported only LF-to-CRLF normalization warnings. `run_reward_claim_board_contract.gd` still exits 1 only for unrelated live reward boot failures and did not report image/drill failures.

## 2026-06-16 00:00:31

<!-- codex-worklog-signature: 7c73002397e152b716cb7b655cdd1916dcad5146877d6d8a897533c77d220a81 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M app-LTL/src/MainController.gd
 D app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/reward-table.json
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/ui/ArtifactCodexArtResolver.gd
 M app-LTL/src/ui/ArtifactCodexPanelUI.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/RewardCardCloudHost.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/BackpackGridFactory.gd
 M app-LTL/src/ui/presenters/ShellButtonStyler.gd
 M app-LTL/src/vocabulary/CombatVocab.gd
 M app-LTL/src/vocabulary/NodeVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/run_codex_pause_timing_contract.gd
 M app-LTL/tests/run_i18n_localization_smoke.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_node_select_runtime_contract.gd
 M app-LTL/tests/run_reward_handoff_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-16 00:02:57

<!-- codex-worklog-signature: b044b77f6595f525f0150163ffd1c056b5fd55292a1e56b39fa53b09fb9ca8f8 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M app-LTL/src/MainController.gd
 D app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/reward-table.json
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/ui/ArtifactCodexArtResolver.gd
 M app-LTL/src/ui/ArtifactCodexPanelUI.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/RewardCardCloudHost.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/BackpackGridFactory.gd
 M app-LTL/src/ui/presenters/ShellButtonStyler.gd
 M app-LTL/src/vocabulary/CombatVocab.gd
 M app-LTL/src/vocabulary/NodeVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/run_codex_pause_timing_contract.gd
 M app-LTL/tests/run_i18n_localization_smoke.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_node_select_runtime_contract.gd
 M app-LTL/tests/run_reward_handoff_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-16 09:28:30

<!-- codex-worklog-signature: bc1d7f25699b9ded54081951cd61a376275d80fdcbfcd70cef24fefc6d6d9a87 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M app-LTL/src/MainController.gd
 D app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/reward-table.json
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/ui/ArtifactCodexArtResolver.gd
 M app-LTL/src/ui/ArtifactCodexPanelUI.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/RewardCardCloudHost.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/BackpackGridFactory.gd
 M app-LTL/src/ui/presenters/ShellButtonStyler.gd
 M app-LTL/src/vocabulary/CombatVocab.gd
 M app-LTL/src/vocabulary/NodeVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_codex_pause_timing_contract.gd
 M app-LTL/tests/run_i18n_localization_smoke.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_node_select_runtime_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-16 09:29:06

<!-- codex-worklog-signature: 3af04206491c0e50833287c7fcfba13c859071fb7b6052d212739e0d9bf200e0 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M app-LTL/src/MainController.gd
 D app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/reward-table.json
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/ui/ArtifactCodexArtResolver.gd
 M app-LTL/src/ui/ArtifactCodexPanelUI.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/RewardCardCloudHost.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/BackpackGridFactory.gd
 M app-LTL/src/ui/presenters/ShellButtonStyler.gd
 M app-LTL/src/vocabulary/CombatVocab.gd
 M app-LTL/src/vocabulary/NodeVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_codex_pause_timing_contract.gd
 M app-LTL/tests/run_i18n_localization_smoke.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_node_select_runtime_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-16 09:29:06

<!-- codex-worklog-signature: 3af04206491c0e50833287c7fcfba13c859071fb7b6052d212739e0d9bf200e0 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M app-LTL/src/MainController.gd
 D app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/reward-table.json
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/ui/ArtifactCodexArtResolver.gd
 M app-LTL/src/ui/ArtifactCodexPanelUI.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/RewardCardCloudHost.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/BackpackGridFactory.gd
 M app-LTL/src/ui/presenters/ShellButtonStyler.gd
 M app-LTL/src/vocabulary/CombatVocab.gd
 M app-LTL/src/vocabulary/NodeVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_codex_pause_timing_contract.gd
 M app-LTL/tests/run_i18n_localization_smoke.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_node_select_runtime_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-16 09:29:59

<!-- codex-worklog-signature: 88681b93b3ccb57ab0a7a6c38f1e067c3633776d1970179ce757c2aece44a354 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M app-LTL/src/MainController.gd
 D app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/reward-table.json
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/scenes/pages/shells/GameplayTopContent.tscn
 M app-LTL/src/ui/ArtifactCodexArtResolver.gd
 M app-LTL/src/ui/ArtifactCodexPanelUI.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/RewardCardCloudHost.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/BackpackGridFactory.gd
 M app-LTL/src/ui/presenters/ShellButtonStyler.gd
 M app-LTL/src/vocabulary/CombatVocab.gd
 M app-LTL/src/vocabulary/NodeVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_codex_pause_timing_contract.gd
 M app-LTL/tests/run_i18n_localization_smoke.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-16 09:31:23

<!-- codex-worklog-signature: 380faa4634d156b4fc485477122c9ca855c6be47c2c378ab01f759fa22e3fb9f -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M app-LTL/src/MainController.gd
 D app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/reward-table.json
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/scenes/pages/shells/GameplayTopContent.tscn
 M app-LTL/src/ui/ArtifactCodexArtResolver.gd
 M app-LTL/src/ui/ArtifactCodexPanelUI.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/RewardCardCloudHost.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/BackpackGridFactory.gd
 M app-LTL/src/ui/presenters/ShellButtonStyler.gd
 M app-LTL/src/vocabulary/CombatVocab.gd
 M app-LTL/src/vocabulary/NodeVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_codex_pause_timing_contract.gd
 M app-LTL/tests/run_i18n_localization_smoke.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-16 09:33:34

<!-- codex-worklog-signature: 342180036f1a6d557683bb7e25660a9de6226e5bf48eb029e13ce91ad76a1676 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M app-LTL/src/MainController.gd
 D app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/reward-table.json
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/scenes/pages/shells/GameplayTopContent.tscn
 M app-LTL/src/ui/ArtifactCodexArtResolver.gd
 M app-LTL/src/ui/ArtifactCodexPanelUI.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/RewardCardCloudHost.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/BackpackGridFactory.gd
 M app-LTL/src/ui/presenters/ShellButtonStyler.gd
 M app-LTL/src/vocabulary/CombatVocab.gd
 M app-LTL/src/vocabulary/NodeVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_codex_pause_timing_contract.gd
 M app-LTL/tests/run_i18n_localization_smoke.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-16 09:33:50

<!-- codex-worklog-signature: 351dad3367874ef54c4b10205bfe88e5fd3810aca32889b086cc7e5d3bd1528e -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M app-LTL/src/MainController.gd
 D app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/reward-table.json
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/scenes/pages/shells/GameplayTopContent.tscn
 M app-LTL/src/ui/ArtifactCodexArtResolver.gd
 M app-LTL/src/ui/ArtifactCodexPanelUI.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/RewardCardCloudHost.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/BackpackGridFactory.gd
 M app-LTL/src/ui/presenters/ShellButtonStyler.gd
 M app-LTL/src/vocabulary/CombatVocab.gd
 M app-LTL/src/vocabulary/NodeVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_codex_pause_timing_contract.gd
 M app-LTL/tests/run_i18n_localization_smoke.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-16 10:46:00

<!-- codex-worklog-signature: c3b1598b548e8b7992bc50459eeff06bae4871f8f89c8cc2e7f9b913ec6a1736 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M app-LTL/src/MainController.gd
 D app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/reward-table.json
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/scenes/pages/shells/GameplayTopContent.tscn
 M app-LTL/src/ui/ArtifactCodexArtResolver.gd
 M app-LTL/src/ui/ArtifactCodexPanelUI.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/RewardCardCloudHost.gd
 M app-LTL/src/ui/RewardRevealOverlay.gd
 M app-LTL/src/ui/SettingsPanelUI.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/BackpackGridFactory.gd
 M app-LTL/src/ui/presenters/ShellButtonStyler.gd
 M app-LTL/src/vocabulary/CombatVocab.gd
 M app-LTL/src/vocabulary/NodeVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_codex_pause_timing_contract.gd
 M app-LTL/tests/run_i18n_localization_smoke.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-16 Shared Backpack Reward/Second-Battle Regression Fix

- Intent: Fix the follow-up regression where the reward tray idle starter drill image drifted outside its grid slot, and the second battle could keep the shared backpack docked away from the battle host.
- Files or areas touched:
```text
app-LTL/src/ui/BackpackUI.gd
app-LTL/src/ui/backpack/BackpackArtifactRenderer.gd
app-LTL/src/ui/MainViewRuntime.gd
app-LTL/src/ui/main_view/MainViewBackpackRuntime.gd
app-LTL/src/ui/main_view/MainViewPageShellRuntime.gd
app-LTL/src/ui/main_view/MainViewAppShellRuntime.gd
app-LTL/src/ui/main_view/MainViewRewardLayoutRuntime.gd
app-LTL/tests/test_reward_claim_board_contract.gd
app-LTL/tests/run_m6_visual_hold.gd
app-LTL/tests/run_shared_backpack_visual_capture.gd
docs/evidence/shared-backpack-2026-06-16/
```
- Root cause: Reparenting the single shared backpack into the reward workspace changed the live slot transforms after the drill image had already been rendered. The image refresh path was either too early for deferred Godot layout or skipped during paused reward/battle states. Separately, surface activation did not always force the shared backpack back into the new active surface host after reward.
- Actual change summary: Added RED coverage for reward idle drill centering without manual rerender and second-battle shared backpack return. Surface activation now schedules the shared backpack into the active top host. Reparent/shared/reward layout syncs now queue drill-image refresh. `BackpackUI` refreshes image layout even while battle pause logic is active, and image refresh retries across a short layout-settle window. The layout signature now includes real inner slot rects, not only the outer grid rect. Added a visual capture helper and refreshed visual-hold route selection automation.
- Plan impact: Stayed within shared backpack host movement and image-layer refresh; item placement rules, cooldown overlays, non-image item rendering, reward board structure, and controller flow were not changed.
- Verification: RED: `run_reward_claim_board_contract.gd` first failed on reward idle image centering and second battle reparent. Green checks passed: `run_reward_claim_board_contract.gd`, `run_test_ui_read_models.gd`, `run_character_select_cleanup_contract.gd`, `run_reward_handoff_contract.gd`, `run_main_start_flow_contract.gd`, `godot_contract_runner.gd`, and `git diff --check`. Captured and inspected `docs/evidence/shared-backpack-2026-06-16/reward_1280x720.png` and `docs/evidence/shared-backpack-2026-06-16/second_battle_1280x720.png`; both show the starter drill centered inside the grid and the second battle backpack visible.

## 2026-06-16 Reward Drop Shared Backpack Visibility Fix

- Intent: Fix the reward-page drag/drop regression where placing a reward item into the backpack grid left the reward workspace visually blank, even though the placed item appeared correctly after entering battle.
- Files or areas touched:
```text
app-LTL/src/ui/main_view/MainViewPageShellRuntime.gd
app-LTL/src/ui/main_view/MainViewRewardLayoutRuntime.gd
app-LTL/tests/test_reward_claim_board_contract.gd
app-LTL/tests/run_shared_backpack_visual_capture.gd
docs/codex-worklog/plan_LootingTheLeviathan_2026-06-16.md
docs/evidence/shared-backpack-2026-06-16/reward_drop_1280x720.png
```
- Root cause: During reward-page rerender after a successful drop, surface activation scheduled the already-docked shared backpack to move back to the reward page's top-content host. Because the container's current parent was still the reward workspace host, the later reward-dock step did not override that pending deferred reparent. One frame later, the shared backpack moved out of the reward workspace, leaving the middle reward panel blank while inventory state remained correct.
- Actual change summary: Added a RED reward-drop contract that selects a placeable reward, emits the same drop signal, waits through deferred reparent, and verifies the shared backpack stays in the reward workspace with the newly placed artifact rendered. Updated surface activation to avoid scheduling top-host reparent when the shared backpack is already docked to that bundle's reward host, and updated reward docking to override any stale pending reparent with the reward workspace host. Extended the visual capture helper with a `reward_drop` page.
- Plan impact: Stayed within shared backpack host arbitration after reward drops. Inventory mutation, placement validity, reward data, cooldown rendering, and page-local backpack ownership were not changed.
- Verification: RED: `run_reward_claim_board_contract.gd` failed on "reward drop keeps the shared backpack docked in the reward workspace host." Green checks passed: `run_reward_claim_board_contract.gd`, `run_test_ui_read_models.gd`, `run_reward_handoff_contract.gd`, `godot_contract_runner.gd`, and `git diff --check`. Captured and inspected `docs/evidence/shared-backpack-2026-06-16/reward_drop_1280x720.png`, which shows the reward backpack grid visible with the newly dropped blue item and starter drill rendered.
