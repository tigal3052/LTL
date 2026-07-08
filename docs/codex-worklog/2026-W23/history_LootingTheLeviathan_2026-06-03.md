# Codex Worklog History

Workspace: LootingTheLeviathan
Date: 2026-06-03

## 2026-06-03

- Intent: Put the newly supplied hazard tile art into a browser-visible comparison before touching Godot runtime rendering.
- Files or areas touched:
  - `docs/mockups/hazard-tile-approaches.html`
  - `docs/mockups/hazard-tile-state-matrix.html`
  - `docs/superpowers/specs/2026-06-03-hazard-tile-visual-design.ko.md`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-03.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-03.md`
- Summary: Re-read the current `CellView.gd` obstacle renderer and checked the new `red/blue/purple/green_tile_hazard.png` assets. The first mockup caused confusion because it over-emphasized the frame look of the hazard PNGs, so the direction was tightened into an explicit state matrix: weakness is read from the base tile alpha, while hazard state is read from the hazard image alpha on the same tile-sized rect. Wrote a dedicated hazard-tile design spec and replaced the loose A/B/C comparison with a new browser mockup that shows the final intended matrix across `hazard none / warning / active / afterglow` and `weakness off / on`.
- Plan impact: The browser-first decision loop is now specific enough to drive implementation once the written spec and refreshed mockup are accepted.
- Verification status:
  - Browser mockups prepared locally at `docs/mockups/hazard-tile-approaches.html` and `docs/mockups/hazard-tile-state-matrix.html`
  - Written design spec saved at `docs/superpowers/specs/2026-06-03-hazard-tile-visual-design.ko.md`
  - Runtime code change intentionally deferred until the user reviews the updated spec/matrix

- Intent: Fix the post-implementation codex regression where selecting an entry freed live button nodes during signal emission and the book frame no longer aligned with its internal layout.
- Files or areas touched:
  - `app-LTL/src/ui/ArtifactCodexPanelUI.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-03.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-03.md`
- Summary: Root-caused the runtime error to immediate `free()` calls on currently emitting card/button nodes inside codex rerenders. Replaced child teardown with `remove_child + queue_free` and moved codex rerenders behind `call_deferred()` so section and entry clicks no longer mutate the grid during the active signal stack. Separately corrected the layout root cause by abandoning the implicit container-sized book rect and computing a centered fitted `ItemBook.png` rect first, then placing the spread and pages inside that real book rect. This keeps the safe-area ratios intact while preventing the interior UI from drifting outside the visible frame.
- Plan impact: The codex implementation remains the active output, but the bugfix turns the new book UI into a stable runtime surface instead of a prototype-only drop-in.
- Verification status:
  - `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL --script tests/run_test_ui_read_models.gd --quit`
    - Passed with `UI_READ_MODEL_TESTS_OK`
  - `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL --script tests/godot_contract_runner.gd --disable-crash-handler --quit`
    - Passed with `GODOT_CONTRACTS_OK`
  - `git diff --check`
    - Reported only repository-wide LF/CRLF warnings and no whitespace errors in the touched files

- Intent: Implement the approved artifact codex book UI directly in Godot with ratio-driven safe-area math instead of hardcoded sample pixels.
- Files or areas touched:
  - `app-LTL/src/ui/ArtifactCodexArtResolver.gd`
  - `app-LTL/src/ui/read_models/ArtifactCodexReadModel.gd`
  - `app-LTL/src/ui/ArtifactCodexPanelUI.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/ui/TextCatalog.gd`
  - `app-LTL/tests/test_reward_contract.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `app-LTL/tests/godot_contract_runner.gd`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-03.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-03.md`
- Summary: Added a dedicated codex art resolver so graphics can later drop final images into stable `hero` / `thumb` slots keyed by reward `presentation.icon` without changing panel code. Expanded the codex read model from a text dump into a richer book payload with sections, selection normalization, left-page detail, right-page large-card grid, and separate hero/thumb art descriptors. Rebuilt the panel itself around `ItemBook.png` with book-relative safe-area ratios, separate left/right scroll containers, premium parchment/brass card styling, locked-state placeholders, and larger low-density right-page cards that only show illustration and rarity. `MainViewRuntime` now owns selected-entry and active-section state so clicking the right-page grid updates the left-page detail without losing context.
- Plan impact: The codex redesign moved from spec/mockup status into production implementation, while keeping the measured `105 / 113 / 102px` values as documentation only and deriving runtime layout from `ItemBook.png` ratios.
- Verification status:
  - `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL --script tests/run_test_ui_read_models.gd --quit`
    - Passed with `UI_READ_MODEL_TESTS_OK`
  - `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL --script tests/tmp_reward_contract_runner.gd --quit`
    - Passed with `REWARD_CONTRACT_TESTS_OK` before the temporary focused runner was removed
  - `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL --script tests/godot_contract_runner.gd --disable-crash-handler --quit`
    - Still fails on the pre-existing `test_combat_vocab.gd` low-pressure obstacle-family rotation assertion (`expected 4, got 2`), not on the codex work
  - `git diff --check`
    - Reported only repository-wide LF/CRLF warnings and no whitespace errors in the touched files

- Intent: Verify whether M5 can actually be closed on the current tree, then turn the recent codex/reward/backpack UI work into a realistic M6 implementation plan.
- Files or areas touched:
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-03.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-03.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-03.md`
  - `docs/superpowers/plans/2026-06-03-m6-ui-ux-finalization-plan.md`
- Summary: Re-read the official M5/M6 milestone docs, the June 1-3 UI design specs, the current codex-book plan, and the release-quality reference notes. Ran the M6 milestone gate, a fresh full Godot contract run, and the local compile/source-map check. The milestone gate failed because `11_M5_hazard_hierarchy_completed.md` does not exist yet. The fresh `godot_contract_runner.gd` run failed on three distinct layers: `test_reward_contract.gd` still calls `ArtifactCodexReadModel.project(...)` with too many arguments, `test_ui_read_models.gd` uses invalid class-level `has_method()` calls that cause parse failure, and `test_combat_vocab.gd` still reports the low-pressure obstacle-family rotation regression (`expected 4, got 2`). The compile check failed even earlier on `SOURCE_MAP_GATE_FAIL` because `ItemBook.png` is still missing from the source map. Two direct single-test Godot invocations for `test_backpack_vocab.gd` and `test_combat_vocab.gd` also timed out after only printing the engine banner, so they were not counted as passing evidence. Parallel subagents converged on the same planning outcome: treat current M5 as code-implemented but not closure-verified, and frame M6 as `UI/UX finalization` with a `core M6` scope for the playable loop and a `stretch M6` scope for the codex-book redesign.
- Plan impact: Replaced the codex-only daily focus with a milestone-oriented verification and planning pass. The new M6 plan starts with a preflight task that restores clean gates and re-verifies M5 before broader UI finalization work begins.
- Verification status:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/milestone-gate.ps1 -TargetPlan 12_M6_ui_ux_finalization.md -Root D:\Programming\ex_workspace\LootingTheLeviathan`
    - Failed because `11_M5_hazard_hierarchy_completed.md` is missing.
  - `git diff --check`
    - Reported only LF/CRLF warnings and no whitespace errors.
  - `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --path app-LTL --script tests/godot_contract_runner.gd --disable-crash-handler --quit`
    - Failed on reward-contract parse errors, UI-read-model parse errors, and the combat obstacle-family rotation assertion.
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
    - Failed on `SOURCE_MAP_GATE_FAIL` for missing `ItemBook.png` mappings.
  - Direct `tests/test_backpack_vocab.gd` and `tests/test_combat_vocab.gd` script launches
    - Timed out after the Godot banner and produced no pass marker, so they remain unverified.

- Intent: Fix the remaining M5 live regression where reward-ceremony entry freezes the last combat HP/timer snapshot and makes clears look early.
- Files or areas touched:
  - `app-LTL/src/ui/StatusPanelUI.gd`
  - `app-LTL/src/ui/presenters/PhaseLayoutPresenter.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-03.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-03.md`
- Summary: Traced the symptom away from the combat reducer and into the reward-ceremony UI gate. `PhaseLayoutPresenter` already keeps the battlefield/status shell visible during active ceremony beats, but `StatusPanelUI` still refused to render target bars/queue state unless combat was active or the legacy victory overlay flag was on. That mismatch froze the final visible HP/timer values right before reward-loot entry, which made live clears look like they happened before the Leviathan reached zero HP. Added a pure helper on `StatusPanelUI`, kept the combat footer timer active through reward-ceremony beats, and added regression coverage for the active-ceremony versus tray-review transition.
- Plan impact: Narrowed the active work from the broader M5 follow-up pass to this remaining reward-ceremony presentation regression.
- Verification status:
  - Direct Godot contract run still crashes during project load with native exit code `-1073741819`, so the new UI regression could not be executed yet.
  - `tools/run-compile-check.ps1` stops earlier on `SOURCE_MAP_GATE_FAIL` for duplicated/missing `ItemBook.png` mappings, which is separate from the ceremony fix.

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

## 2026-06-03 21:35:00

- Intent: Implement the requested five-point gameplay/UI balance pass across hazards, codex discovery, backpack layout, hazard-family spawning, and queue tempo.
- Files or areas touched:
  - `app-LTL/src/ui/CellView.gd`
  - `app-LTL/src/ui/presenters/BackpackPinLayoutPolicy.gd`
  - `app-LTL/src/ui/MainViewRuntime.gd`
  - `app-LTL/src/MainControllerRuntime.gd`
  - `app-LTL/src/vocabulary/node/ApplyNodeModifiers.gd`
  - `app-LTL/src/models/CombatSimulator.gd`
  - `app-LTL/src/vocabulary/CombatVocab.gd`
  - `app-LTL/src/phases/CombatPhase.gd`
  - `app-LTL/src/phases/NodeSelectPhase.gd`
  - `app-LTL/src/models/Artifact.gd`
  - `app-LTL/src/models/RunGrowthState.gd`
  - `app-LTL/src/vocabulary/reward/CreateArtifactFromReward.gd`
  - `app-LTL/src/vocabulary/progression/ApplyGrowthModifiers.gd`
  - `app-LTL/src/ui/read_models/TooltipReadModel.gd`
  - `app-LTL/src/vocabulary/reward/BuildRewardPreview.gd`
  - `app-LTL/src/domain/FormalContracts.gd`
  - `app-LTL/src/process/ReplayProcess.gd`
  - `app-LTL/src/vocabulary/combat/RecalculateQueueColors.gd`
  - `app-LTL/src/ui/StatusPanelUI.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `app-LTL/tests/test_combat_vocab.gd`
  - `app-LTL/tests/test_reward_contract.gd`
  - `app-LTL/tests/godot_contract_runner.gd`
- Summary:
  - Removed the remaining colored hazard frame draw path so hazard tiles render without an outer color border.
  - Forced codex starter discovery to reveal the basic red/blue/green/purple drill and beacon pairs from the start.
  - Unified reward/node-select backpack sizing through shared layout-policy helpers so the reward tray and drop state stop diverging.
  - Restricted spawned hazard families to the active terrain/node colors and preserved that color set through combat shifts.
  - Rebalanced queue tempo to a 16-slot default, halved canonical drill/beacon cooldown pacing, strengthened cooldown-reduction scaling for the denser queue, and seeded two terrain-energy columns while keeping the combat time limit unchanged.
- Verification:
  - `git diff --check` reported no whitespace errors in the touched files; only repository LF/CRLF warnings appeared.
  - Windows Godot CLI verification was attempted with `tests/run_test_ui_read_models.gd`, `tests/run_test_combat_vocab.gd`, and `--check-only`, but every `--headless -s ...` invocation timed out in this environment before producing script-level results.

## Additional History Note: Codex Header Alignment And Discovery Debug Follow-Up

- User reported the book-top band still looked broken because the shared codex header was sitting on the decorative leather border instead of inside the parchment spread.
- Root-cause inspection showed `ArtifactCodexPanelUI.gd` still positioned `HeaderBar` directly against the book root top band even after the book background itself was scaled from the original `ItemBook.png` coordinates.
- Follow-up implementation moved the shared header row into the spread safe area, pushed both left and right pages down beneath that row, and clamped usable page height from the remaining parchment interior.
- Added a debug-only codex discovery override in `MainControllerRuntime.gd` so `F8` can temporarily mark every reward-table artifact as discovered for codex display without mutating persisted progression state.
- Added read-model coverage for the new header placement contract and the codex debug discovery helper in `app-LTL/tests/test_ui_read_models.gd`.
- Verification was rerun fresh after the follow-up edits instead of relying on the earlier codex stabilization pass.

## Follow-Up: M5 Automation Cleanup

- Normalized codex reward-contract tests to use dynamic read-model loading so Godot no longer rejects the extended codex `project(...)` signature during parse.
- Fixed obstacle family rotation seeding in `app-LTL/src/vocabulary/CombatVocab.gd` so shift-based family coverage no longer skips half the families under the M5 rotation contract.
- Extended `docs/source-map.md` for the new codex UI/art/mockup/spec/plan files until `tools/run-compile-check.ps1` returned `SOURCE_MAP_GATE_OK` again.
- Tightened `app-LTL/tests/run_main_start_flow_contract.gd` so runtime access errors stop masquerading as a green contract.
- Verification:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` -> `SOURCE_MAP_GATE_OK`, `GODOT_CONTRACTS_OK`
  - `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --editor --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL -s tests/run_test_ui_read_models.gd --quit` -> `UI_READ_MODEL_TESTS_OK`
  - `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --editor --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL -s tests/run_node_map_scene_smoke.gd --quit` -> `NODE_MAP_SCENE_SMOKE_OK`

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

## 2026-06-03 11:40:00

- Intent: Persist the approved artifact codex redesign as a written spec and checkpoint commit before implementation planning.
- Files or areas touched:
  - `docs/superpowers/specs/2026-06-03-artifact-codex-book-design.ko.md`
  - `docs/mockups/codex-book-approaches.html`
  - `docs/mockups/codex-book-hybrid.html`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-03.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-03.md`
- Summary: Wrote the approved hybrid codex spec covering safe-area geometry, page-specific scroll ownership, left-detail/right-grid responsibilities, tile-pin-metal graphic rules, and the future art-resolver expansion. Self-reviewed the spec for placeholder or scope issues, then committed the design package as `4f47a55 docs: add artifact codex book redesign spec`.
- Plan impact: The design phase now has a committed baseline and is waiting at the required user spec-review gate before implementation planning.
- Verification status: Spec self-review completed; runtime verification intentionally deferred until implementation.

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

## 2026-06-03 13:20:00

- Intent: Implement the approved active-only hazard lifecycle and swap battlefield obstacle line art over to the new family hazard PNG overlays.
- Files or areas touched:
  - `app-LTL/src/vocabulary/CombatVocab.gd`
  - `app-LTL/src/ui/CellView.gd`
  - `app-LTL/tests/test_combat_vocab.gd`
  - `app-LTL/tests/run_test_combat_vocab.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
  - `docs/superpowers/specs/2026-06-03-hazard-tile-visual-design.ko.md`
  - `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-03.md`
  - `docs/codex-worklog/history_LootingTheLeviathan_2026-06-03.md`
  - `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-03.md`
- Summary: Reworked combat hazards so new obstacles spawn directly as `active`, removed the runtime warning countdown, preserved optional clear afterglow, and kept right-edge unresolved exits as the only fail-effect trigger point. Replaced the per-family procedural obstacle art in `CellView.gd` with same-rect hazard PNG overlays plus explicit alpha helpers so weakness readability comes from the base tile and hazard readability comes from the overlay.
- Plan impact: The hazard-tile task is now implemented and focused verification is green; only broader unrelated repository noise remains outside the scope of this request.
- Verification status:
  - `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --editor --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL -s tests/run_test_combat_vocab.gd --quit` -> `COMBAT_VOCAB_TESTS_OK`
  - `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --editor --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL -s tests/run_test_ui_read_models.gd --quit` -> `UI_READ_MODEL_TESTS_OK`
  - `git diff --check` -> LF/CRLF warnings only; no whitespace errors

## 2026-06-03 13:45:00

- Intent: Address a real runtime readability gap reported from a live screenshot where hazards still looked like old warning-era highlights and the combat log still said `WARNING`.
- Files or areas touched:
  - `app-LTL/src/models/HazardModel.gd`
  - `app-LTL/src/MainControllerRuntime.gd`
  - `app-LTL/src/ui/CellView.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
- Summary: Removed the remaining `warning` severity wording from the hazard status model and combat log path so live hazards now project as `active`/`critical` instead of `WARNING`. Also strengthened the in-cell active overlay by adding a visible family-tinted fill plus brighter border framing behind the hazard PNG, because obstacle data was reaching `CellView` correctly but the new art was still too easy to miss at battlefield scale.
- Plan impact: The active-only hazard change is now aligned with the live runtime language and should read much more clearly in the actual game screen, not just in focused logic tests.
- Verification status:
  - `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --editor --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL -s tests/run_test_combat_vocab.gd --quit` -> `COMBAT_VOCAB_TESTS_OK`
  - `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --editor --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL -s tests/run_test_ui_read_models.gd --quit` -> `UI_READ_MODEL_TESTS_OK`
  - `git diff --check` -> LF/CRLF warnings only; no whitespace errors

## 2026-06-03 14:05:00

- Intent: Remove the last border-like tile highlight from live combat cells and verify that the green hazard family really uses its dedicated PNG instead of being visually washed out.
- Files or areas touched:
  - `app-LTL/src/ui/CellView.gd`
  - `app-LTL/tests/test_ui_read_models.gd`
- Summary: Traced the lingering bright border in the screenshot to `CellView`'s hover overlay, not to weakness highlighting, then replaced that border with a faint inner fill so queue/weakness readability continues to come only from tile alpha. Also enlarged the hazard overlay footprint beyond the tile rect, added family-specific helper contracts for hazard margins/fill, and reduced green-family active fill so `green_tile_hazard.png` remains visible instead of blending into the green base tile.
- Plan impact: The hazard-tile presentation now better matches the approved spec in live play: no leftover weakness-like border, larger active hazard framing, and explicit green-family texture coverage.
- Verification status:
  - `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --editor --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL -s tests/run_test_combat_vocab.gd --quit` -> `COMBAT_VOCAB_TESTS_OK`
  - `D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe --headless --editor --path D:\Programming\ex_workspace\LootingTheLeviathan\app-LTL -s tests/run_test_ui_read_models.gd --quit` -> `UI_READ_MODEL_TESTS_OK`
  - `git diff --check` -> LF/CRLF warnings only; no whitespace errors

## 2026-06-03 20:39:23

<!-- codex-worklog-signature: 47640d6e539cac198513a2f59d6c8b0ca8669c0ce710f09d9ea7e38e27733172 -->

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
 M app-LTL/src/domain/FormalContracts.gd
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
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-03 20:39:31

<!-- codex-worklog-signature: 9b8b8dbadd5fd8eb2dc43856fc00e15946a7641f60858763cae152350ed756ad -->

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
 M app-LTL/src/domain/FormalContracts.gd
 M app-LTL/src/models/Artifact.gd
 M app-LTL/src/models/CombatSimulator.gd
 M app-LTL/src/models/HazardModel.gd
 M app-LTL/src/models/InventoryModel.gd
 M app-LTL/src/models/RunGrowthState.gd
 M app-LTL/src/phases/CombatPhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/process/ReplayProcess.gd
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
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.

## 2026-06-03 20:40:37

<!-- codex-worklog-signature: 9edf606729d4c34c78a4c13ed9565567b412a6920a19732b286ad83b0005f729 -->

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
 M app-LTL/src/domain/FormalContracts.gd
 M app-LTL/src/models/Artifact.gd
 M app-LTL/src/models/CombatSimulator.gd
 M app-LTL/src/models/HazardModel.gd
 M app-LTL/src/models/InventoryModel.gd
 M app-LTL/src/models/RunGrowthState.gd
 M app-LTL/src/phases/CombatPhase.gd
 M app-LTL/src/phases/NodeSelectPhase.gd
 M app-LTL/src/process/ReplayProcess.gd
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
``
- Summary: Review the plan and current diff for semantic details; keep this entry compressed if later updates touch the same area.
- Verification: Not recorded by hook. Update this after running checks.
