# Codex Worklog History

Workspace: LootingTheLeviathan
Date: 2026-06-11

No implementation history has been recorded yet.
## 2026-06-11 18:20:00

- Intent: Close the phase-1 checkpoint honestly by fixing the real runtime containment regressions that the stricter page-contract gate exposed.
- Files or areas touched:
```text
app-LTL/src/Main.tscn
app-LTL/src/ui/MainViewRuntime.gd
LTL-harness/tools/page-contract-gate.ps1
docs/source-map.md
docs/request-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md
docs/artifact-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md
docs/m6-manual-signoff-checklist.ko.md
```
- Summary: Tightened the page-contract gate so the layout audit must emit its success marker, repaired the source-map drift that blocked the harness before runtime checks, then compacted the gameplay shell and reward-board chrome so combat and reward layouts fit the canonical viewport without reintroducing reward-card scrollbars.
- Plan impact: The requested checkpoint commit is now backed by green source-map, page-contract, transition-safety, reward-board, and compile evidence instead of a false-green path.
- Verification:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd` -> `MAIN_LAYOUT_AUDIT_CONTRACT_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_reward_claim_board_contract.gd` -> `REWARD_CLAIM_BOARD_CONTRACT_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` -> `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`
## 2026-06-11 13:05:00

- Intent: Establish the two-phase execution path requested by the user before editing harness/runtime files.
- Files or areas touched:
```text
docs/codex-worklog/plan_LootingTheLeviathan_2026-06-11.md
docs/codex-worklog/history_LootingTheLeviathan_2026-06-11.md
docs/request-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md
```
- Summary: Recorded the minimal-fix checkpoint first, runtime-separation surgery second plan, and created a request ledger covering both phases so harness edits can be verified against explicit scope and invariants.
- Plan impact: The current request is now tracked as a two-phase change set instead of an unspecified work item.
- Verification: Pending.
## 2026-06-11 12:05:30

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

## 2026-06-11 12:35:57

<!-- codex-worklog-signature: 7a09e5ef5c66a4864abd00f240320a1197e01e1cf24e4504b88074664d41e04a -->

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

## 2026-06-11 15:24:01

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
