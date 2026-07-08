# Codex Worklog History

Workspace: LootingTheLeviathan
Date: 2026-06-12

## 2026-06-12

- Intent: Rework the node-select page layout and action-button language, but hold all runtime edits until an approval mockup exists in HTML and is reviewed in-browser.
- Files or areas touched: `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-12.md`, `docs/codex-worklog/history_LootingTheLeviathan_2026-06-12.md`, `docs/mockups/2026-06-12-node-select-redesign-approval.html`.
- Summary: Switched today's active work from prior sign-off and character-select tasks to an approval-first node-select redesign pass. The immediate deliverable is a browser-viewable HTML mockup that consolidates the header chrome into the main frame, previews the muted-node state system, and demonstrates the new reset/start button tone before any Godot page or shared button code changes land.
- Plan impact: The workspace focus is now design approval for the node-select redesign; implementation and verification are explicitly deferred until the user signs off on the mockup.
- Verification status: Pending in-browser mockup review and user approval.

- Intent: Replace the rough first-pass mockup with an approval prototype that demonstrates real interaction and a mechanically valid node-state presentation.
- Files or areas touched: `docs/mockups/2026-06-12-node-select-redesign-approval.html`.
- Summary: Rebuilt the approval mockup so it now simulates an actual stage-two node-select state: one cleared start node, five current candidates with only one active selection, downstream unexplored `?` markers, a selection-driven info card, and real CSS/JS hover-press reactions for both the header chips and the bottom action buttons. The goal is to let the user judge interaction language and route readability instead of a static composition.
- Plan impact: The approval artifact is now closer to the intended runtime behavior, which should reduce ambiguity before Godot implementation starts.
- Verification status: Pending user review in the in-app browser.

- Intent: Apply the approved node-select redesign directly in the runtime, including utility-action relocation, CTA copy change, left/right action-bar alignment, and muted non-selected nodes.
- Files or areas touched: `app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn`, `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd`, `app-LTL/src/scenes/pages/shells/ActionBar.tscn`, `app-LTL/src/ui/MainViewRuntime.gd`, `app-LTL/src/ui/PageSceneModelBuilder.gd`, `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`, `app-LTL/src/data/i18n/text-ko.json`, `app-LTL/src/data/i18n/text-en.json`, `app-LTL/tests/run_node_select_runtime_contract.gd`, `app-LTL/tests/ui_read_models/ui_phase_layout_suite.gd`, `app-LTL/tests/ui_read_models/ui_page_scene_model_builder_suite.gd`, `app-LTL/tests/ui_read_models/ui_text_tooltip_suite.gd`, `app-LTL/tests/run_i18n_localization_smoke.gd`.
- Summary: Removed the retired node-select hero strip, added page-owned `상점 / 유물 도감 / 설정` buttons beside the run/stage chips, hid the legacy shell header for node-select, inserted an `ActionBar` spacer so reset stays left while start stays right, renamed the start CTA to `채굴 시작`, and introduced shared shell-button color/motion treatment with bronze reset and red start accents. The node runtime now mutes cleared history, non-selected current routes, and future boss markers until they become the active selection.
- Plan impact: The runtime implementation now matches the approved mockup direction closely enough that the browser mockup is only a reference artifact.
- Verification status:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_node_select_runtime_contract.gd` -> `NODE_SELECT_RUNTIME_CONTRACT_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd` -> `UI_READ_MODEL_TESTS_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_i18n_localization_smoke.gd` -> `I18N_LOCALIZATION_SMOKE_OK`

- Intent: Fix the character-select page's oversized top spacing and stabilize the mini-backpack detail behavior without breaking responsive layout containment.
- Files or areas touched: `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-12.md`, `app-LTL/tests/run_character_select_cleanup_contract.gd`, `app-LTL/src/scenes/pages/CharacterSelectPage.gd`, `app-LTL/src/scenes/pages/CharacterSelectPage.tscn`.
- Summary: Switched today's active plan from the earlier M6 sign-off audit to the requested character-select cleanup pass. Added RED coverage for hidden header-row spacing, a fixed-height scrollable detail body, and click-pinned mini-backpack detail selection. Then hid the empty `ZoneHead` rows and eyebrow label, taught the responsive overhead math to ignore hidden rows, replaced the detail body with a two-line scroll viewport, and separated hover-preview state from pinned slot selection so hover exit restores the clicked slot detail.
- Plan impact: The workspace focus is now a contained character-select UI behavior fix rather than sign-off documentation work.
- Verification status:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_character_select_cleanup_contract.gd` -> `CHARACTER_SELECT_CLEANUP_CONTRACT_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd` -> `MAIN_LAYOUT_AUDIT_CONTRACT_OK`

- Intent: Replace the character-select starter palette text buttons with structured cards that improve title emphasis, left padding, and stat readability without breaking the viewport layout.
- Files or areas touched: `app-LTL/src/scenes/pages/CharacterSelectPage.gd`, `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`, `app-LTL/src/data/i18n/text-ko.json`, `app-LTL/src/data/i18n/text-en.json`, `app-LTL/tests/run_character_select_cleanup_contract.gd`, worklog/plan docs.
- Summary: Added a structured starter-card read model that exposes title/body/tag data, rebuilt the palette options as VBox-based clickable cards with wrapped tag chips, compressed the mini-backpack detail card to pay back the added height, and updated the focused contract to assert the nested card structure and preserved no-scroll layout.
- Plan impact: Stayed within the approved redesign scope; no additional subsystem work was required.
- Verification status: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_character_select_cleanup_contract.gd` -> `CHARACTER_SELECT_CLEANUP_CONTRACT_OK`

- Intent: Simplify the new starter-card tags so they read as quick category cues instead of dense stat chips.
- Files or areas touched: `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`, `app-LTL/src/scenes/pages/CharacterSelectPage.gd`, `app-LTL/src/data/i18n/text-ko.json`, `app-LTL/src/data/i18n/text-en.json`, `app-LTL/tests/run_character_select_cleanup_contract.gd`.
- Summary: Replaced numeric drill/beacon stat tags with four qualitative tags per card: `드릴`, a color-specific archetype (`강한 데미지`, `쉴드 타격`, `디버프`, `누적 데미지`), `비콘`, and `인접 보정`. Updated chip styling so feature tags read as the main emphasis and support tags stay secondary.
- Verification status: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_character_select_cleanup_contract.gd` -> `CHARACTER_SELECT_CLEANUP_CONTRACT_OK`

## 2026-06-12 00:29:48

<!-- codex-worklog-signature: 230d80a5552844c48e8eb968190b22fab8c322c0a2556889126dcb6144e2bcef -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_main_viewport_probe.gd
 D app-LTL/tests/run_node_map_scene_smoke.gd
 M app-LTL/tests/run_pin_miner_layout_probe.gd
 M app-LTL/tests/run_reward_handoff_contract.gd
 M app-LTL/tests/support/UiReadModelTestSuite.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 11:46:00

- Intent: Tighten the approved node-select redesign with missing chip padding and a non-faded shared start CTA style on first entry.
- Tool: Codex CLI + apply_patch
- Files or areas touched:
```text
M app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd
M app-LTL/src/ui/MainViewRuntime.gd
M app-LTL/tests/run_main_layout_audit_contract.gd
M app-LTL/tests/run_node_select_runtime_contract.gd
```
- Summary: Added horizontal chip content padding for run/stage badges, defined explicit disabled shell-button visuals plus disabled font colors so `채굴 시작` no longer falls back to Godot's washed-out default, and updated node-select/main-layout contracts to lock the approved structure.
- Verification:
```text
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_node_select_runtime_contract.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd
powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_i18n_localization_smoke.gd
```

## Battle HUD mockup kickoff

- Intent: Re-scope the day from the earlier node-select approval mockup to a new battle HUD mockup pass after the user requested a left-status / center-backpack / right-tab layout, a full-slot queue redesign, node multiplier visibility upgrades, and drill-placement ideas.
- Files or areas touched:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-12.md`
  - `docs/mockups/2026-06-12-battle-hud-queue-status-mockup.html`
- Summary:
  - Audited the live battle scene shell, `GameplayTopContent`, `StatusPanelUI`, `HudReadModel`, `PhaseLayoutPresenter`, and combat/node data contracts to confirm that the current queue UI is collapsing a full token array into `지금/다음/예비`.
  - Updated the worklog plan to reflect the approval-first combat HUD request instead of the earlier node-select scope.
  - Prepared to generate a separated mockup artifact for the queue and the drill/node status panel, with drill-image changes held as written ideas only.
- Plan impact: Keeps the current turn in design approval mode and explicitly blocks runtime scene/script edits until the user signs off on the visual direction.
- Verification status: Source inspection only so far; mockup artifact creation and visual review still pending.

## Battle HUD mockup refinement v2

- Intent: Replace the earlier prototype-like single-direction mockup with a more production-grade review artifact after the user clarified FIFO queue rules, node-first ordering, and the need for multiple style options.
- Files or areas touched:
  - `docs/mockups/2026-06-12-battle-hud-queue-status-mockup-v2.html`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-12.md`
- Summary:
  - Added a new v2 mockup artifact with three distinct visual directions instead of one.
  - Corrected the queue logic in the visual spec so it now shows contiguous FIFO filling only, with both 8-slot and 16-slot examples.
  - Reordered the left status panel so node analysis appears above health, shield, queue, drill state, and combat timer.
  - Preserved drill state and combat timer in the mockup while continuing to exclude the removed stage time-limit display.
  - Expanded the design analysis to explain which HUD patterns best fit the backpack and terrain-tile visual language, and marked a recommended final direction.
- Plan impact: Keeps the work in approval mode but makes the next implementation step much more concrete once the user picks a direction.
- Verification status: Mockup file creation verified locally; live browser rendering still not captured in this pass.

## 2026-06-12 10:25:00

- Intent: Audit the M6 completion checklist, close the small automatable gaps, and rewrite the remaining manual sign-off guidance so the final status is honest.
- Files or areas touched:
  - `app-LTL/src/MainControllerRuntime.gd`
  - `app-LTL/tests/ui_read_models/ui_interaction_controller_suite.gd`
  - `docs/m6-manual-signoff-checklist.ko.md`
  - `docs/m6-known-issues.ko.md`
  - `docs/source-map.md`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-12.md`
- Summary:
  - Re-ran the real M6 automation gates and confirmed `source-map-gate` and `run_main_layout_audit_contract.gd` both pass on the current tree.
  - Traced the source-map failure to an unmapped June 12 plan file, then updated `docs/source-map.md` and added a dedicated M6 known-issues note.
  - Added a new RED->GREEN UI contract for accessibility persistence and implemented minimal config-backed save/load behavior for screenshake, reduced flash, reduced particles, and hold-fire assist.
  - Rewrote the M6 manual checklist into plain Korean with concrete steps and pass criteria for screenshot review, combat readability, failure messaging, and accessibility checks.
- Verification:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .` -> `SOURCE_MAP_GATE_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd` -> `MAIN_LAYOUT_AUDIT_CONTRACT_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd` -> `UI_READ_MODEL_TESTS_OK` with existing Godot leak warnings on shutdown

## 2026-06-12 00:30:58

<!-- codex-worklog-signature: 1e0a6d4c579afe5da20d8a4f9376f9ee8432a6666948406a8a2e3e05d7fe4d39 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_main_viewport_probe.gd
 D app-LTL/tests/run_node_map_scene_smoke.gd
 M app-LTL/tests/run_pin_miner_layout_probe.gd
 M app-LTL/tests/run_reward_handoff_contract.gd
 M app-LTL/tests/support/UiReadModelTestSuite.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 00:33:29

<!-- codex-worklog-signature: 3b88a12bb3e0c34ee473d6837e1f4ea5c6e0bf95d539ec6af71fa0f04d395f7a -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 D app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_main_viewport_probe.gd
 D app-LTL/tests/run_node_map_scene_smoke.gd
 M app-LTL/tests/run_pin_miner_layout_probe.gd
 M app-LTL/tests/run_reward_handoff_contract.gd
 M app-LTL/tests/support/UiReadModelTestSuite.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 00:37:00

<!-- codex-worklog-signature: 004c529f9606cc59ae84aaa49d22a44d4f43f49b9c9af43305df035106fd77a4 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/data/i18n/text-en.json
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_main_viewport_probe.gd
 D app-LTL/tests/run_node_map_scene_smoke.gd
 M app-LTL/tests/run_pin_miner_layout_probe.gd
 M app-LTL/tests/run_reward_handoff_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 00:37:09

<!-- codex-worklog-signature: 2a5b3da8763e1b259811f2e99b13ac61d78c8f47fb8c11ec4180fd751aa5043c -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/data/i18n/text-en.json
 M app-LTL/src/data/i18n/text-ko.json
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_main_viewport_probe.gd
 D app-LTL/tests/run_node_map_scene_smoke.gd
 M app-LTL/tests/run_pin_miner_layout_probe.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 00:37:53

<!-- codex-worklog-signature: 64150d97e99e1b319f48183c70fd25f1661df829726cd3f47c5d971365e2d947 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/data/i18n/text-en.json
 M app-LTL/src/data/i18n/text-ko.json
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_main_viewport_probe.gd
 D app-LTL/tests/run_node_map_scene_smoke.gd
 M app-LTL/tests/run_pin_miner_layout_probe.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 00:38:22

<!-- codex-worklog-signature: 1f2eb4d9f2ab422710912750aef1d44004c3aec187e5959cc5ece6f448d19493 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M LTL-harness/tools/runtime-size-gate.ps1
 M LTL-harness/tools/runtime-size-gate.tests.ps1
 D app-LTL/resources/UI/backpack.png
 D app-LTL/resources/UI/backpack.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/data/i18n/text-en.json
 M app-LTL/src/data/i18n/text-ko.json
 D app-LTL/src/data/rarity-table.json
 D app-LTL/src/scenes/node_map/NodeMapScene.gd
 D app-LTL/src/scenes/node_map/NodeMapScene.tscn
 M app-LTL/src/scenes/pages/BattlePage.tscn
 M app-LTL/src/scenes/pages/BossBattlePage.tscn
 M app-LTL/src/scenes/pages/BossRewardPage.tscn
 M app-LTL/src/scenes/pages/CharacterSelectPage.gd
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_main_viewport_probe.gd
 D app-LTL/tests/run_node_map_scene_smoke.gd
 M app-LTL/tests/run_pin_miner_layout_probe.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 09:06:44

<!-- codex-worklog-signature: 9495c4c3ba56f0f03e8f9998dccfa4596bf3ab65f4bf969c18f83e7c7b18ae69 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
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
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_main_viewport_probe.gd
 D app-LTL/tests/run_node_map_scene_smoke.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 09:09:30

<!-- codex-worklog-signature: 4a919584b6112e620f84a92f6f4aaec3fe2cd9cd28d2a267ed24d65dd1e6241b -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
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
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_main_viewport_probe.gd
 D app-LTL/tests/run_node_map_scene_smoke.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 10:06:19

<!-- codex-worklog-signature: 311b7da0bfdaec3c09a0d3d0fd11211f664fcb7c16139e92ef32a479c74a6fdc -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
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
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
 M app-LTL/tests/run_main_viewport_probe.gd
 D app-LTL/tests/run_node_map_scene_smoke.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 11:07:22

<!-- codex-worklog-signature: 71ddd67746705040f89aea1609e07310e6540d39743f0e878f1532aa45008250 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
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
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 11:07:33

<!-- codex-worklog-signature: 67634f782e18b63e02a03c3f04163e0d34873407996d94d5e1c69228cc53309b -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
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
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 11:07:33

<!-- codex-worklog-signature: 67634f782e18b63e02a03c3f04163e0d34873407996d94d5e1c69228cc53309b -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
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
 M app-LTL/src/scenes/pages/NodeSelectRuntimePage.tscn
 M app-LTL/src/scenes/pages/RewardPage.tscn
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/PageSceneModelBuilder.gd
 M app-LTL/src/ui/SharedBackpackHostCoordinator.gd
 M app-LTL/src/ui/VFXManager.gd
 D app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 D app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
 M app-LTL/tests/run_main_start_flow_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 11:07:57

<!-- codex-worklog-signature: f8c5ae59e72400f3ecbff3f117a0cc898d87f97fae45179548698a06402bdbfb -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
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
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 11:08:07

<!-- codex-worklog-signature: 77df1491d4463cdaf31c10a96dc4aae12a79f0c7a8e5c0ff3ac433064772652c -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
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
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 11:10:58

<!-- codex-worklog-signature: 59b7d7e2ca8fa7bb148620b7d9fed21d4ba5817e01708950ee777a7bb132d30f -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
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
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_main_layout_audit_contract.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 11:12:20

<!-- codex-worklog-signature: fbae81ad2df3c9731553c7f756add365dd0faf5242780374c34980b964519fed -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
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
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_i18n_localization_smoke.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-12 11:13:25

<!-- codex-worklog-signature: 0e499f858ff9201c453ef076b3a3b86ad9479a2350256c27cedaecce32701ab1 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
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
 M app-LTL/src/vocabulary/RewardVocab.gd
 M app-LTL/tests/godot_contract_runner.gd
 D app-LTL/tests/inspect_img.gd
 M app-LTL/tests/run_character_select_cleanup_contract.gd
 M app-LTL/tests/run_i18n_localization_smoke.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.
