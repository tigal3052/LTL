# Codex Worklog History

Workspace: LootingTheLeviathan
Date: 2026-05-30

No implementation history has been recorded yet.
## 2026-05-30 09:45:43

<!-- codex-worklog-signature: c0f13c849463f805240efb4270d5235fe2c35a9028ffbbc367611711bc06ea01 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/node-table.json
 M app-LTL/src/domain/FormalContracts.gd
 M app-LTL/src/models/Artifact.gd
 M app-LTL/src/models/RunGrowthState.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/tools/FormalReplayRunner.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatSceneModel.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/SceneReadModel.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/BackpackGridFactory.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/vocabulary/CombatVocab.gd
 M app-LTL/src/vocabulary/NodeVocab.gd
 M app-LTL/src/vocabulary/combat/ShiftWeaknessMarkers.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_backpack_vocab.gd
 M app-LTL/tests/test_combat_vocab.gd
 M app-LTL/tests/test_node_map_scene_smoke.gd
 M app-LTL/tests/test_node_routing_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-05-30 09:55:00

- Intent: Fix the backpack blackout regression that appears after placing a selected reward artifact into the backpack.
- Files or areas touched:
  - `app-LTL/src/ui/InteractionFX.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
- Summary: Root-caused the issue to `InteractionFX.apply_drag_feedback()` mutating backpack slot `self_modulate` without first storing an original baseline on slots that intentionally skip full interaction-FX installation. Added a regression test that drives drag feedback on a plain slot and verifies the original tint is restored after reward-drop cleanup, then fixed the baseline bookkeeping in the drag-feedback path.
- Verification: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` passed with `SOURCE_MAP_GATE_OK` and `GODOT_CONTRACTS_OK`; `git diff --check` pending final rerun.

## 2026-05-30 10:10:00

- Intent: Address the follow-up report that reward placement still blackens the backpack grid and that the node-select graph still loses width to the backpack dock.
- Files or areas touched:
  - `app-LTL/src/ui/InteractionFX.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
- Summary: Found the remaining backpack regression in the drag-feedback alpha path: idle drag cleanup still tweened slot alpha toward `0.0`, effectively erasing the visible grid. Changed drag feedback to keep control alpha at `1.0` and added a regression check for slot alpha restoration after reward-drop cleanup. Also changed node-select docking so the backpack stays right-aligned at a stable width while the node-map panel expands into the remaining width instead of competing through stretch ratios.
- Verification: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` passed with `SOURCE_MAP_GATE_OK` and `GODOT_CONTRACTS_OK`; `git diff --check` returned only existing LF/CRLF warnings and no whitespace errors.

## 2026-05-30 09:47:06

<!-- codex-worklog-signature: a5f69a242e6a2e910f22f03cf4a48e9a838f4e39910b25edf4bd6251855c4c49 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/node-table.json
 M app-LTL/src/domain/FormalContracts.gd
 M app-LTL/src/models/Artifact.gd
 M app-LTL/src/models/RunGrowthState.gd
 M app-LTL/src/process/HeadlessMiniRun.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/tools/FormalReplayRunner.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatSceneModel.gd
 M app-LTL/src/ui/CombatScenePreviewController.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/SceneReadModel.gd
 M app-LTL/src/ui/ShopPanelUI.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/presenters/BackpackGridFactory.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/vocabulary/CombatVocab.gd
 M app-LTL/src/vocabulary/NodeVocab.gd
 M app-LTL/src/vocabulary/combat/ShiftWeaknessMarkers.gd
 M app-LTL/tests/godot_contract_runner.gd
 M app-LTL/tests/test_backpack_vocab.gd
 M app-LTL/tests/test_combat_vocab.gd
 M app-LTL/tests/test_node_map_scene_smoke.gd
 M app-LTL/tests/test_node_routing_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.
