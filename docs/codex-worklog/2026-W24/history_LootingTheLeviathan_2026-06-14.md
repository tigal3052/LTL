# Codex Worklog History

Workspace: LootingTheLeviathan
Date: 2026-06-14

## Battle HUD runtime implementation

- Intent: Translate the approved battle HUD mockups into the live Godot runtime, covering the tabbed right panel, left status layout reshuffle, two-row FIFO energy queue, and terrain multiplier information cards.
- Files or areas touched:
  - `app-LTL/src/scenes/pages/shells/GameplayTopContent.tscn`
  - `app-LTL/src/ui/StatusPanelUI.gd`
  - `app-LTL/src/ui/BattleSidebarUI.gd`
  - `app-LTL/src/ui/EnergyQueuePulseSlot.gd`
  - `app-LTL/src/ui/read_models/HudReadModel.gd`
  - `app-LTL/src/MainControllerRuntime.gd`
  - `app-LTL/src/vocabulary/node/ApplyNodeModifiers.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/data/i18n/text-en.json`
  - `app-LTL/src/data/i18n/text-ko.json`
  - `app-LTL/tests/ui_read_models/ui_battlefield_hud_suite.gd`
  - `app-LTL/tests/run_main_layout_audit_contract.gd`
- Summary:
  - Replaced the old always-visible log/info panel with a right-side tabbed shell whose default tab is explorer status and whose secondary tab contains the live info/log stack.
  - Removed the retired left explorer sidebar so the drill/node status panel owns the full left column, while keeping the combat timer and drill state in the footer region.
  - Rebuilt the energy queue as a 2-row, 8-columns-per-row FIFO surface with compact pulse-monitor slots, locked 9-16 slots, and contiguous loaded colors.
  - Projected selected-node combat metadata into the HUD read path so node weakness, shield multiplier, health multiplier, and future per-color multiplier maps can drive the info panel directly.
  - Reworked the terrain info cards so neutral terrain, single weakness, and composite weakness cases all render inside the live sidebar shell using tile icons, per-card shield/health multiplier subcards, and condensed note chips.
  - Fixed combat-shell width regressions by restoring backpack-first width sizing and shrinking the queue slot footprint so the full combat page remains inside the 1440x900 audit viewport.
- Verification status:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_combat_layout_containment_contract.gd`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_i18n_localization_smoke.gd`
  - All four commands passed for the HUD/runtime scope.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_start_flow_contract.gd` still fails on existing node-select header/hero-title expectations outside this HUD pass.

## Battle HUD correction pass

- Intent: Correct the first runtime HUD pass so the right sidebar behaves like an in-panel tab toggle and the combat info cards move back into the left status rail.
- Files or areas touched:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-14.md`
  - `app-LTL/src/scenes/pages/shells/GameplayTopContent.tscn`
  - `app-LTL/src/ui/StatusPanelUI.gd`
  - `app-LTL/src/ui/BattleSidebarUI.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/tests/ui_read_models/ui_battlefield_hud_suite.gd`
  - `app-LTL/tests/run_main_layout_audit_contract.gd`
- Summary:
  - Reframed the implementation around five aligned role reviews: planner, programmer, UI designer, graphic designer, and frontend layout engineer all pointed to the same fix.
  - Identified the concrete root cause: `ExplorerContent` and `InfoContent` were layout-managed siblings inside the right sidebar `VBoxContainer`, so the larger info body changed the row's minimum height and reflowed the page.
  - Locked the corrected ownership model before editing: right sidebar owns explorer/log only, while the left status shell owns both the upper combat info panel and the lower compressed drill/node operations panel.
- Plan impact: Replaced the earlier “right info/log tab” target with a fixed-shell correction pass focused on hierarchy ownership and tab-stability regression coverage.
- Verification status:
  - Subagent inspection only at this stage; runtime verification is pending until the corrected scene/script edits land.

## Selected HUD mockup refinement

- Intent: Raise the quality of the chosen energy-queue direction and remove misleading composite-terrain multiplier summaries from the information panel.
- Files or areas touched:
  - `docs/mockups/2026-06-13-battle-hud-energy-queue-variants.html`
  - `docs/mockups/2026-06-13-battle-hud-info-panel-variants.html`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-14.md`
- Summary:
  - Replaced the multi-direction energy-queue comparison with a single refined final direction based on the first concept.
  - Rebuilt the queue slots around one thicker waveform graphic with layered glow, highlight, and gradient treatment derived from the reference tile's center pulse.
  - Reworked the information panel so composite terrain no longer shows confusing top-level "main attack" summary multipliers.
  - Moved composite-terrain multiplier readability into the red and green weakness cards themselves, each with explicit shield and health multiplier lines.
  - Tightened the composite-terrain section to follow the supplied reference image pattern more closely: helper strip first, then labeled terrain section, then card rows carrying the actual values.
  - Finalized the composite weakness cards so each card now presents shield and health multiplier mini-cards as a side-by-side two-column pair, matching the approved reference layout.
- Plan impact: Tightened the task from exploration into selected-direction refinement, reducing ambiguity ahead of runtime implementation.
- Verification status:
  - `Select-String -Path docs/mockups/2026-06-13-battle-hud-energy-queue-variants.html -Pattern 'Final Direction / Concept 1','모니터 레일','wave-shadow','wave-main','wave-highlight','8칸 기본 상태','16칸 확장 상태'`
  - `Select-String -Path docs/mockups/2026-06-13-battle-hud-info-panel-variants.html -Pattern '복합지형은 색마다 적용 배율이 달라서','적색 약점','녹색 약점','주 공략 기준 실드 배율','주 공략 기준 체력 배율' -Context 0,4`
  - `Select-String -Path docs/mockups/2026-06-13-battle-hud-info-panel-variants.html -Pattern 'panel-helper','metric-item','공통 실드 배율','공통 체력 배율'`
  - `Select-String -Path docs/mockups/2026-06-13-battle-hud-info-panel-variants.html -Pattern 'metric-stack','metric-card-mini','metric-card-label','metric-card-value','적색 약점','녹색 약점' -Context 0,3`
  - File-level checks succeeded and confirmed the refined single-direction queue treatment plus composite per-color multiplier cards.

## 2026-06-14 16:55:44

<!-- codex-worklog-signature: c4c15a70c4cb099e0ee5518878bb480036448c2c9a1500ecf8af81c2b9738216 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/i18n/text-en.json
 M app-LTL/src/data/i18n/text-ko.json
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## Battle HUD runtime fit-and-stability pass

- Intent: Finish the corrected battle HUD by locking the right explorer/log tab behavior in place, compressing the left combat rail to fit the viewport, and clearing the purple-footer rerender drift.
- Files or areas touched:
  - `app-LTL/src/scenes/pages/shells/GameplayTopContent.tscn`
  - `app-LTL/src/scenes/pages/shells/BattlefieldPanel.tscn`
  - `app-LTL/src/ui/StatusPanelUI.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/ui/PageSceneRegistry.gd`
  - `app-LTL/tests/ui_read_models/ui_battlefield_hud_suite.gd`
- Summary:
  - Tightened the live left status panel by reducing its outer padding, collapsing the extra note-chip row, compacting the weakness multiplier cards, shrinking the lower queue/timer rhythm, and keeping the queue, drill state, and combat timer intact.
  - Disabled greedy vertical growth on the battlefield strip so the battle page no longer stretches beyond the active host when the combat shell recomputes.
  - Reworked page-scene registration and host-bound syncing so repeated battle rerenders keep the page anchored to the host instead of jumping upward when the purple footer appears for the first time.
  - Updated the read-model test expectations for the intentionally smaller combat timer footer.
- Plan impact: Completed the runtime correction loop without changing the approved ownership model again; remaining work is limited to future polish outside this viewport-fit fix.
- Verification status:
  - Passed `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_viewport_probe.gd`
  - Passed `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd`
  - Passed `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd`
  - Passed `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_i18n_localization_smoke.gd`
  - The UI read-model command still emits pre-existing Godot resource leak warnings on shutdown, but the suite result is `UI_READ_MODEL_TESTS_OK`.

## 2026-06-14 16:57:36

<!-- codex-worklog-signature: 2dd54ef9ef72d96307df48b2bc6f2f047879473b34a816af2643092b21bf81da -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/i18n/text-en.json
 M app-LTL/src/data/i18n/text-ko.json
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-14 16:58:00

<!-- codex-worklog-signature: aef6a80a8fac966207b37fea638ffc3acb89483e20d30de9e20086441d99c1c5 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/i18n/text-en.json
 M app-LTL/src/data/i18n/text-ko.json
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-14 18:09:45

<!-- codex-worklog-signature: 1b2629b53a80cac489077668682d2745e4923967433ec8201c4a71c667509983 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/i18n/text-en.json
 M app-LTL/src/data/i18n/text-ko.json
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-14 18:17:11

<!-- codex-worklog-signature: e98138152fb4eb534097946d2038c03cd8170b3414e1e51ead3d5452e10d1562 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/i18n/text-en.json
 M app-LTL/src/data/i18n/text-ko.json
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-14 18:19:36

<!-- codex-worklog-signature: 762d5c04817ef15fc5499c2a4e7cd25f8a4786af8975481734c291852ef56db5 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/i18n/text-en.json
 M app-LTL/src/data/i18n/text-ko.json
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-14 21:06:07

<!-- codex-worklog-signature: 25a69c5152e26ae9a0538ad9d21cfb0e34824fbf863e50fd2e49a578791a55d2 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/i18n/text-en.json
 M app-LTL/src/data/i18n/text-ko.json
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 D app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-14 21:36:04

<!-- codex-worklog-signature: 4feba81ece3fad778fa4c1700c098e079e22a5c5de602de2e188eb4a70ac0f55 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/i18n/text-en.json
 M app-LTL/src/data/i18n/text-ko.json
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/PageSceneRegistry.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-14 21:41:09

<!-- codex-worklog-signature: db4780cbf0ad8229e5c1111ec431731b9a6fbb6107c08e99eee3728964ea0f18 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/i18n/text-en.json
 M app-LTL/src/data/i18n/text-ko.json
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/PageSceneRegistry.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-14 22:20:37

<!-- codex-worklog-signature: 60e728d652baddc542d35e2a9538680bb4fafc50d9466afd53094357e2c0f347 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
 M LTL-harness/00_AGENTS.md
 M LTL-harness/docs/request-analysis-execution-gate.md
 M LTL-harness/docs/templates/request-constraint-ledger-template.md
 M LTL-harness/tools/request-analysis-gate.ps1
 M LTL-harness/tools/request-analysis-gate.tests.ps1
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/i18n/text-en.json
 M app-LTL/src/data/i18n/text-ko.json
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/PageSceneRegistry.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## Battle HUD floor alignment and info-toggle polish

- Intent: Fix the oversized lower action gap shown in the latest battle HUD screenshot, keep the lower battlefield/action band on the active phase floor, and upgrade the left combat multiplier panel into a compact toggle/dropdown matching the approved mockup direction.
- Files or areas touched:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-14.md`
  - `app-LTL/src/scenes/pages/BattlePage.tscn`
  - `app-LTL/src/scenes/pages/shells/GameplayTopContent.tscn`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/ui/StatusPanelUI.gd`
  - `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
  - `app-LTL/src/data/i18n/text-en.json`
  - `app-LTL/src/data/i18n/text-ko.json`
  - `app-LTL/tests/run_main_layout_audit_contract.gd`
  - `app-LTL/tests/ui_read_models/ui_battlefield_hud_suite.gd`
- Summary:
  - Added failing coverage for the reported state: top row height budget, equal top-panel heights, action-bar floor contact, left/right width targets, and `전투 핵심 배율` dropdown stability.
  - Replaced naive vertical expansion with a calculated top-content minimum height derived from the safe active-phase budget, so the top row grows while the battle page root remains clipped to the host.
  - Rebalanced top-row horizontal ratios from `2.0 / 1.55` to `2.2 / 1.25`, producing a wider left status panel, larger height-derived backpack, and narrower right sidebar at 1440x900.
  - Converted the static combat multiplier title into a styled toggle button and added a compact detail shell with localized state/risk chips; the collapsed state keeps the compact card readout.
  - Changed page scene bounds syncing to full-rect anchors so stale page root sizes do not linger after layout recomputation.
- Cross-check:
  - UI programmer subagent confirmed the root cause was the battle page/active-phase vertical budget rather than button sizing.
  - Graphic designer subagent recommended a compact runtime disclosure, larger tile icons/readable metric values, restrained borders, and no collapsed-height bloat; the implementation follows that direction.
- Verification status:
  - Passed `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd`
  - Passed `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd`
  - Passed `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_combat_layout_containment_contract.gd`
  - Passed `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_i18n_localization_smoke.gd`
  - Passed `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_viewport_probe.gd`
  - `run_test_ui_read_models.gd` still emits pre-existing Godot shutdown resource warnings after the suite result.

## Battle HUD node/drill info panel correction

- Intent: Apply the screenshot/mockup feedback for the left battle HUD info panels: rename sections, make collapsed node info weakness-only, move node status into node info, and make expanded node info replace the drill panel.
- Files or areas touched:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-14.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-14.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-14.md`
  - `app-LTL/src/scenes/pages/shells/GameplayTopContent.tscn`
  - `app-LTL/src/ui/StatusPanelUI.gd`
  - `app-LTL/src/data/i18n/text-ko.json`
  - `app-LTL/src/data/i18n/text-en.json`
  - `app-LTL/tests/ui_read_models/ui_battlefield_hud_suite.gd`
  - `app-LTL/tests/run_main_layout_audit_contract.gd`
- Summary:
  - Renamed "전투 핵심 배율" to "노드 정보" and "드릴 및 노드 상태" to "드릴 정보" in Korean and English locale entries.
  - Moved `NodeCard` from `OpsShell` into `InfoShell`; it stays hidden while collapsed and appears when node info expands.
  - Collapsed node info now keeps only terrain/weakness copy visible; multiplier cards and tags are hidden until expanded.
  - Expanded node info hides `OpsShell`, grows the info shell, shows terrain explanation, moved node status, health-first multiplier cards, and note chips.
  - Multiplier cards now order 체력 before 실드 and use rounded red/blue dot markers; composite terrain uses stacked color rows with two metric columns.
  - Health, shield, queue, pin, and drill rows share a 76px label column and expanding right-side content.
- Verification status:
  - Passed `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd`; Godot still prints shutdown resource warnings after the OK marker.
  - Passed `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_combat_layout_containment_contract.gd`.
  - Passed `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_viewport_probe.gd`.
  - `tests/run_main_layout_audit_contract.gd` still fails three pre-existing broader floor-alignment assertions: top row height is 420px instead of the expected 500px+, left column width is 561px outside the old 480-520px band, and action bar floor ends at 789px while the active phase floor is 884px.
  - `tools/run-compile-check.ps1` still fails at the source-map gate because mapped `app-LTL/resources/charactor/npc1.png` paths are reported missing by that gate; this is outside the node/drill info-panel change.
