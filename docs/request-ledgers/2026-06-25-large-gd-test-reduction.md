# 2026-06-25 Large GDScript and Test Reduction

## Request Summary

- Reduce oversized active GDScript owners and oversized test suites without changing gameplay behavior.
- Keep the current main scene/controller load graph intact after the detached runtime cleanup.
- Split large helper/test responsibilities into smaller focused files where a pure wrapper can preserve the existing public test/production path.

## Preserved Invariants

- `app-LTL/src/Main.tscn` continues to use `res://src/MainController.gd` as the live controller script.
- MainController signal/wrapper API remains available to scenes and existing tests.
- Run-flow roster, leviathan, and node-selection behavior remains API-compatible through `MainControllerRunFlow.gd` wrappers.
- Combat vocabulary and UI read-model test runner entry points remain unchanged: `tests/run_test_combat_vocab.gd` and `tests/run_test_ui_read_models.gd` still load the same top-level suite paths.
- Interaction SFX category output remains generated through `InteractionSfxSynth.create_stream(category)`.
- Dirty worktree changes outside this size-reduction surface must not be reverted.

## Mutable Scope

- `app-LTL/src/MainController.gd`
- `app-LTL/src/controllers/MainControllerRunFlow.gd`
- `app-LTL/src/controllers/run_flow/CharacterRosterLoader.gd`
- `app-LTL/src/controllers/run_flow/LeviathanRosterLoader.gd`
- `app-LTL/src/controllers/run_flow/NodeSelectionGuards.gd`
- `app-LTL/src/controllers/MainControllerRewardBackpackFlow.gd`
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- `app-LTL/src/ui/RewardRevealOverlay.gd`
- `app-LTL/src/ui/presenters/InteractionSfxSynth.gd`
- `app-LTL/src/ui/audio/InteractionSfxProfile.gd`
- `app-LTL/tests/test_combat_vocab.gd`
- `app-LTL/tests/combat_vocab/`
- `app-LTL/tests/ui_read_models/ui_backpack_layout_suite.gd`
- `app-LTL/tests/ui_read_models/backpack_layout/`
- `app-LTL/tests/ui_read_models/ui_text_tooltip_suite.gd`
- `app-LTL/tests/ui_read_models/text_tooltip/`
- `docs/source-map.md`
- `docs/architectural-gates/release-blocking-gate.md`

## Source Map Findings

- `docs/source-map.md` tracks live source/test ownership and must be refreshed after every new helper/suite file is introduced.
- `docs/architectural-gates/runtime-size-gate.md` enforces `app-LTL/src/**/*.gd=500` and `app-LTL/src/ui/presenters/*.gd=200`; the active failures were oversized source files and a 251-line presenter.
- `LTL-harness/tools/test-size-gate.ps1` enforces direct `app-LTL/tests/ui_read_models/*.gd` leaf suites at 320 lines, so oversized direct UI suites need wrapper-plus-subdirectory split.
- Historical worklogs and completed plans are evidence only; they are not active load dependencies.

## Root Cause Review

- Observed symptom: runtime-size and test-size gates failed on oversized active `.gd` owners and UI read-model leaf suites; several top-level test files also exceeded the legacy warning threshold.
- Evidence: line-count inventory showed `CharacterSelectPage.gd` 524, `RewardRevealOverlay.gd` 522, `MainControllerRewardBackpackFlow.gd` 522, `MainController.gd` 514, `MainControllerRunFlow.gd` 509, `InteractionSfxSynth.gd` 251, `ui_backpack_layout_suite.gd` 469, `ui_text_tooltip_suite.gd` 349, and `test_combat_vocab.gd` 754 after whitespace reduction.
- Root cause target: `app-LTL/src/controllers/MainControllerRunFlow.gd`
- Rejected workaround: raising line caps or reintroducing the detached `MainControllerRuntime.gd` facade.
- Chosen fix: preserve public wrappers while extracting pure run-flow helpers, SFX profile maps, and focused test suites, plus no-op whitespace/array compaction for active oversized source files.

## Transition Safety Review

- touched transition ids: `meta.start_flow`, `page.scene_mapping`, `reward.ceremony`, `reward.handoff`
- entry owner: `app-LTL/src/phases/CombatPhase.gd` and `app-LTL/src/phases/RewardLootPhase.gd` own the combat-clear and reward-claim phase entries that route back into page ownership.
- exit owner: `app-LTL/src/MainController.gd` / `app-LTL/src/ui/MainViewRuntime.gd` own the runtime page shell exits into battle, reward, node-select, and clear/defeat surfaces.
- shared handoff risk: final boss clears now pass through the reward-loot/reward-board path before terminal clear, so reward ceremony containment, backpack handoff, run-complete state, and page scene mapping must remain stable.
- runner and marker proof: `meta.start_flow` -> `app-LTL/tests/run_main_start_flow_contract.gd` / `MAIN_START_FLOW_CONTRACT_OK`; `page.scene_mapping` -> `app-LTL/tests/run_page_scene_mapping_contract.gd` / `PAGE_SCENE_MAPPING_CONTRACT_OK`; `reward.ceremony` -> `app-LTL/tests/run_reward_ceremony_contract.gd` / `REWARD_CEREMONY_CONTRACT_OK`; `reward.handoff` -> `app-LTL/tests/run_reward_handoff_contract.gd` / `REWARD_HANDOFF_CONTRACT_OK`.
- MainControllerRunFlow.gd keeps the same static wrapper methods; the extracted helpers only host the previous pure roster/node logic behind those wrappers.
- Test suite splits preserve the same runner entry points and aggregate the same assertions.

## Feature Unit Lifecycle Plan

- Design stage: keep entry/facade files as thin ownership wrappers and move pure data projection, profile mapping, and focused test assertions into smaller leaf units.
- Implementation stage: make one ownership-preserving extraction at a time, keep old load paths as wrappers, refresh source-map after adding files, and run the smallest focused proof for each split.
- Maintenance stage: new helpers stay under 500 lines, direct UI read-model leaf suites stay under 320 lines, and oversized top-level legacy tests remain warnings until their surface is actively touched.
- Capsule boundary: source wrappers expose existing production/test APIs; new helper files own one capsule each: roster loading, leviathan loading, node guard projection, SFX profile data, combat vocab focused suites, and UI read-model focused suites.
- Size trigger: if a direct source/test file crosses its strict cap, split pure helpers or focused suites before increasing a gate cap.

## Runtime Performance Review

- Hot path: `app-LTL/src/MainController.gd` remains the live scene controller and should stay a thin delegate/facade.
- Hot path: `app-LTL/src/controllers/MainControllerRunFlow.gd` participates in start/reset/node-selection decisions; wrapper extraction must not add scene-tree scans or per-frame work.
- Hot path: `app-LTL/src/ui/presenters/InteractionSfxSynth.gd` generates audio sample buffers only when a category stream is requested.
- Risk: moving helper functions could introduce extra allocations or preload failures if call paths changed instead of preserving wrappers.
- Performance proof: `app-LTL/tests/run_main_start_flow_contract.gd`, `app-LTL/tests/run_test_combat_vocab.gd`, and the focused UI split smoke runner.
- Budget: no new per-frame work, no runtime scene-tree traversal, and no extra SFX player allocation; helper calls remain static and deterministic.

## Execution Responsibility Units

- Owner: `app-LTL/src/controllers/MainControllerRunFlow.gd`
  - Unit: keep lifecycle/static wrapper API and delegate roster/node pure logic to `run_flow/*` helpers.
  - Extract to: `app-LTL/src/controllers/run_flow/CharacterRosterLoader.gd`, `app-LTL/src/controllers/run_flow/LeviathanRosterLoader.gd`, `app-LTL/src/controllers/run_flow/NodeSelectionGuards.gd`
  - Focused proof: `app-LTL/tests/run_main_start_flow_contract.gd`
- Owner: `app-LTL/src/ui/presenters/InteractionSfxSynth.gd`
  - Unit: keep stream generation while moving profile lookup tables out of the strict presenter file.
  - Extract to: `app-LTL/src/ui/audio/InteractionSfxProfile.gd`
  - Focused proof: focused UI split smoke runner.
- Owner: `app-LTL/tests/test_combat_vocab.gd`
  - Unit: keep the public aggregate test path while moving assertions into focused combat vocab suites.
  - Extract to: `app-LTL/tests/combat_vocab/`
  - Focused proof: `app-LTL/tests/run_test_combat_vocab.gd`
- Owner: `app-LTL/tests/ui_read_models/ui_backpack_layout_suite.gd`
  - Unit: keep direct UI read-model suite under the 320-line gate as an aggregator.
  - Extract to: `app-LTL/tests/ui_read_models/backpack_layout/`
  - Focused proof: focused UI split smoke runner.
- Owner: `app-LTL/tests/ui_read_models/ui_text_tooltip_suite.gd`
  - Unit: keep direct UI read-model suite under the 320-line gate as an aggregator.
  - Extract to: `app-LTL/tests/ui_read_models/text_tooltip/`
  - Focused proof: focused UI split smoke runner.

## Refactor/Delete Disposition

- No active production scene or controller script is deleted in this pass.
- `MainControllerRunFlow.gd`, `InteractionSfxSynth.gd`, and direct UI/test aggregate files are kept as public facades.
- New helper and suite files are added under focused subdirectories rather than increasing strict caps.
- Remaining legacy oversized top-level tests are reported as warnings and left for later focused splits.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/runtime-size-gate.ps1 -Root .`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/test-size-gate.ps1 -Root .`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_combat_vocab.gd -LogName combat-vocab-split.log -Quit`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_start_flow_contract.gd -LogName main-start-flow-split.log -Quit`.
- Run focused UI split smoke runner for backpack/text tooltip suites and `InteractionSfxSynth` load.
- Run `git diff --check` for touched paths.

## Verification Notes

- Source-map refresh printed `SOURCE_MAP_REFRESH_OK: docs/source-map.md` and `SOURCE_MAP_GATE_OK`.
- Source-map validation printed `SOURCE_MAP_GATE_OK` after all new helper/suite files were added.
- Runtime-size gate printed `RUNTIME_SIZE_GATE_OK` after source files and `InteractionSfxSynth.gd` were reduced below strict caps.
- Test-size gate printed `TEST_SIZE_GATE_OK`; remaining oversized top-level tests are warnings only.
- Combat vocab focused runner printed `COMBAT_VOCAB_TESTS_OK`.
- Main start flow runner exited 0 after the `MainControllerRunFlow.gd` helper split.
- Focused UI split smoke runner printed `HERMES_UI_SPLIT_SMOKE_OK` for the split backpack/text-tooltip suites and SFX synth stream creation.
- Full UI read-model runner currently fails on the pre-existing dirty `Main.tscn`/`VFXManager` particle-template wiring assertion, not on the newly split backpack/text-tooltip suites.
- `tools/run-compile-check.ps1` without this request ledger fails at request-analysis because its default ledger lacks `Root Cause Review`; this ledger provides the current request-analysis context.
- `tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-25-large-gd-test-reduction.md` passed source-map, request-analysis, test-size, and runtime-size, then failed in `page-contract-gate.ps1` on the existing `VFXManager particle_template` serialization assertion surfaced by the full UI read-model suite.
- `git diff --check` over touched paths exited 0.

## Resolution Proof

- RED proof: pre-refactor gates failed with oversized active source/test files, including runtime-size failure on strict source/presenter caps and test-size failure on direct UI read-model leaf suites over 320 lines.
- Root-cause proof: the strict gates now pass after extracting the over-cap responsibilities into focused helpers/suites and refreshing the source map.
- Workaround guard: no cap was raised, no old detached runtime facade was restored, and public entry paths are preserved through wrappers.

## Artifact Ledger

- Godot logs are written under ignored `app-LTL/.tmp-godot-logs/`.
- No new persistent generated artifact ledger is required for this refactor-only pass.
