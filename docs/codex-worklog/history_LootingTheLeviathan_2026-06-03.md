# Codex Worklog History

Workspace: LootingTheLeviathan
Date: 2026-06-03

## 2026-06-03

- Intent: Ground a graphics-only artifact-codex decoration proposal in the shipped `ItemBook` and existing block/tile/pin UI assets.
- Files or areas touched:
  - `app-LTL/resources/UI/ItemBook.png`
  - `app-LTL/resources/UI/Log_Panel.png`
  - `app-LTL/resources/UI/backpack_1.png`
  - `app-LTL/resources/UI/pin/pin_1.png`
  - `app-LTL/resources/UI/pin/pin_4.png`
  - `app-LTL/resources/UI/tile/blue_tile.png`
  - `app-LTL/resources/UI/tile/green_tile.png`
  - `app-LTL/resources/UI/tile/red_tile.png`
  - `app-LTL/resources/UI/tile/tile_panel.png`
  - `app-LTL/resources/UI/tile/tile_panel_nobg.png`
  - `app-LTL/src/ui/ArtifactCodexPanelUI.gd`
  - `app-LTL/src/ui/read_models/ArtifactCodexReadModel.gd`
  - `docs/mockups/codex-book-approaches.html`
  - `docs/release-visual-quality-upgrade-plan.md`
  - `docs/superpowers/specs/2026-06-01-backpack-pin-layout-vfx-design.md`
  - `docs/superpowers/specs/2026-06-01-reward-ceremony-redesign-design.md`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-03.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-03.md`
- Summary: Reviewed the current book spread, backpack/leather panels, log parchment, stone tile lids, and metal pin assets together with the earlier codex mockup study. The resulting guidance keeps `ItemBook.png` as the soft organic base while using the small block/tile language only as hardware accents: inset hero frames, mechanical thumbnail borders, restrained selected-state glow, grayscale locked-state masking, and rarity cues driven by corner gems and trim rather than replacing the parchment/book material.
- Plan impact: Clarified that the earlier codex redesign remains out of scope for implementation today, but graphics-direction consultation is valid and can inform a later polish pass.
- Verification status:
  - Context review only; no runtime, scene, or test execution was needed for this consultation

- Intent: Fix the newly reported M5 regressions after the first obstacle/relic rollout, with explicit sub-agent discussion for obstacle visuals.
- Files or areas touched:
  - `app-LTL/src/MainControllerRuntime.gd`
  - `app-LTL/src/phases/CombatPhase.gd`
  - `app-LTL/src/ui/CellView.gd`
  - `app-LTL/src/ui/StatusPanelUI.gd`
  - `app-LTL/src/vocabulary/CombatVocab.gd`
  - `app-LTL/src/vocabulary/RewardVocab.gd`
  - `app-LTL/tests/test_combat_vocab.gd`
  - `app-LTL/tests/test_start_option_contract.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-03.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-03.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-03.md`
- Summary: Fixed the queue-panel regression by teaching `StatusPanelUI` to read dictionary queue tokens, restored the intended `1.5` second / `30` tick battlefield cadence, and removed the shift gate that was incorrectly tied to transient `match` / `mismatch` result values. Reworked obstacle family ordering so low-pressure waves rotate through all four families instead of letting a deterministic tie-break keep red first forever. Reward rolling now pre-rolls rarities and forces one same-rarity relic slot when the generated tray has an eligible common/rare relic window, which makes launch relics surface in actual stage rewards without cross-rarity injection. The cell renderer was also upgraded with stronger family-specific motifs: red furnace cracks and pressure chevrons, blue frost brackets and plate cracks, purple echo prisms, and green root/spore silhouettes with clearer warning, active, and afterglow states. Added regression coverage for dictionary queue tokens, post-shot timer shifting, four-family obstacle rotation, and the updated shift cadence constants.
- Plan impact: The active plan shifted away from the stale codex UI note and back to the requested M5 regression-fix track.
- Verification status:
  - `git diff --check` reported only repository-wide LF/CRLF warnings and no whitespace errors in the touched files
  - Godot native verification is currently blocked because the engine crashes during project load with exit code `-1073741819` before the targeted or full contract scripts can emit results

- Intent: Turn the approved M5 obstacle and backpack-relic design into a playable runtime slice with passing Godot contracts.
- Files or areas touched:
  - `app-LTL/src/models/Artifact.gd`
  - `app-LTL/src/models/CombatSimulator.gd`
  - `app-LTL/src/models/HazardModel.gd`
  - `app-LTL/src/models/InventoryModel.gd`
  - `app-LTL/src/phases/NodeSelectPhase.gd`
  - `app-LTL/src/phases/CombatPhase.gd`
  - `app-LTL/src/vocabulary/CombatVocab.gd`
  - `app-LTL/src/vocabulary/combat/RecalculateQueueColors.gd`
  - `app-LTL/src/MainControllerRuntime.gd`
  - `app-LTL/src/ui/CombatSceneModel.gd`
  - `app-LTL/src/ui/CellView.gd`
  - `app-LTL/src/data/reward-table.json`
  - `app-LTL/src/vocabulary/RewardVocab.gd`
  - `app-LTL/src/vocabulary/reward/CreateArtifactFromReward.gd`
  - `app-LTL/src/ui/TextCatalog.gd`
  - `app-LTL/src/ui/read_models/TooltipReadModel.gd`
  - `app-LTL/tests/test_backpack_vocab.gd`
  - `app-LTL/tests/test_combat_vocab.gd`
  - `app-LTL/tests/test_reward_contract.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-03.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-03.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-03.md`
- Summary: Added structured queue tokens carrying drill provenance, made `relic` a non-energy backpack item with `diagonal_1` and `skip_2` link rules, and updated queue recalculation plus combat consumers to read token dictionaries. Implemented M5 obstacle runtime in the formal combat path: `red` cuts time on exit failure, `blue` slows inventory cooldown progression while present, `purple` pulses debuff cleansing and grants damage reduction pressure, and `green` heals the Leviathan on exit failure. Battlefield shift now runs through a reducer event every 1 second, moving weaknesses and obstacle host cells together while spawning new pressure through target active counts, backlog, and `miss_debt`. Added obstacle projection to the combat scene model and cell overlays for warning, active, and afterglow states. In parallel, expanded the reward/content/UI layer with the approved eight launch relics, colorless relic creation, `item.relic` text, and relic-specific tooltip formatting.
- Plan impact: The work moved from design-only planning into a verified implementation state; no remaining plan changes are required for this slice.
- Verification status:
  - `tests/godot_contract_runner.gd` printed `GODOT_CONTRACTS_OK`
  - `git diff --check` reported only repository-wide LF/CRLF warnings and no whitespace errors in the touched files

## 2026-06-03 10:26:39

<!-- codex-worklog-signature: 3ed5d98d3c2a64755d336e206e152b38acb0e2b68ae1f1deec4f1578387eb9d5 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: apply_patch
- Files or areas touched:
``text
 M .gitignore
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 D app-LTL/resources/UI/tile/tile_panel_nobg2.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/reward-table.json
 M app-LTL/src/models/Artifact.gd
 M app-LTL/src/models/CombatSimulator.gd
 M app-LTL/src/models/HazardModel.gd
 M app-LTL/src/models/InventoryModel.gd
 M app-LTL/src/models/RunGrowthState.gd
 M app-LTL/src/phases/CombatPhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatSceneModel.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/ui/read_models/RewardReadModel.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-03 11:00:00

- Intent: Re-scope today's workspace plan around the artifact codex UI redesign request before any implementation work.
- Files or areas touched:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-03.md`
- Summary: Replaced the stale M5 execution plan with a codex-specific plan focused on a polished split layout, right-side collectible grid, left-side detail panel, explicit image-slot support, and role-based collaboration across planning, UI design, graphics, and programming.
- Plan impact: The active work is now the codex menu redesign rather than M5 obstacle implementation.
- Verification status: Context review only; no runtime checks yet.

## 2026-06-03 11:20:00

- Intent: Translate the approved book-style direction into browser-reviewable codex mockups and synthesize role-based design feedback before implementation.
- Files or areas touched:
  - `docs/mockups/codex-book-approaches.html`
  - `docs/mockups/codex-book-hybrid.html`
- Summary: Built an initial browser mockup comparing three codex directions around `ItemBook.png`, then produced a refined hybrid mockup that keeps A-style left-page detail presentation while switching the right page to lower-density, larger trophy-grid cards. Parallel role reviews from planning, UI, graphics, and programming were synthesized around safe-area margins, page-local scroll behavior, existing tile/pin asset consistency, and the future image-slot pipeline.
- Plan impact: The design direction is now narrow enough to present for approval and convert into a written spec.
- Verification status: Browser mockup files created and opened for visual review; no Godot runtime verification yet.

## 2026-06-03 10:31:04

<!-- codex-worklog-signature: 2ac1db211ffbdf410aeaa76a06b1d4276e74c98e483fb8e618471d4fd8b45b40 -->

- Intent: Workspace files changed through Codex tooling.
- Tool: Bash
- Files or areas touched:
``text
 M .gitignore
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 D app-LTL/resources/UI/tile/tile_panel_nobg2.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/reward-table.json
 M app-LTL/src/models/Artifact.gd
 M app-LTL/src/models/CombatSimulator.gd
 M app-LTL/src/models/HazardModel.gd
 M app-LTL/src/models/InventoryModel.gd
 M app-LTL/src/models/RunGrowthState.gd
 M app-LTL/src/phases/CombatPhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatSceneModel.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/ui/read_models/RewardReadModel.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-03 10:31:04

<!-- codex-worklog-signature: 5e04e15ee48d1a59ab697b21e173e0b4afd2079cadad2b3f2c37baa72308b1fb -->

- Intent: Workspace files changed through Codex tooling.
- Tool: unknown
- Files or areas touched:
``text
 M .gitignore
 M LTL-harness/00_AGENTS.md
 M LTL-harness/tools/i18n-text-gate.ps1
 D app-LTL/resources/UI/miner.png
 D app-LTL/resources/UI/miner.png.import
 D app-LTL/resources/UI/tile/tile_panel_nobg2.png.import
 M app-LTL/src/Main.tscn
 M app-LTL/src/MainControllerRuntime.gd
 M app-LTL/src/data/reward-table.json
 M app-LTL/src/models/Artifact.gd
 M app-LTL/src/models/CombatSimulator.gd
 M app-LTL/src/models/HazardModel.gd
 M app-LTL/src/models/InventoryModel.gd
 M app-LTL/src/models/RunGrowthState.gd
 M app-LTL/src/phases/CombatPhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/scenes/node_map/NodeMapScene.gd
 M app-LTL/src/ui/BackpackUI.gd
 M app-LTL/src/ui/BattlefieldUI.gd
 M app-LTL/src/ui/BattlefieldVFX.gd
 M app-LTL/src/ui/CellView.gd
 M app-LTL/src/ui/CombatSceneModel.gd
 M app-LTL/src/ui/GiantTimerUI.gd
 M app-LTL/src/ui/InteractionFX.gd
 M app-LTL/src/ui/MainViewRuntime.gd
 M app-LTL/src/ui/StatusPanelUI.gd
 M app-LTL/src/ui/TextCatalog.gd
 M app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd
 M app-LTL/src/ui/read_models/NodeMapReadModel.gd
 M app-LTL/src/ui/read_models/RewardReadModel.gd
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.
