# Codex Worklog Completion

Workspace: LootingTheLeviathan
Date: 2026-06-11

## Completion Summary

Completed a full `app-LTL` `.tscn`/`.gd` inventory audit after the first cleanup slice. The screenshot mismatch is now diagnosed: Image #1 is the static `Main.tscn` AppShell preview, while Image #2 is the actual runtime `character_select` page mounted by `MainViewRuntime.gd`.

## Actual Outputs

- `docs/superpowers/plans/2026-06-11-debug-runtime-cleanup-separation-plan.md`
  - Updated with the current execution slice, completed deletion set, verification evidence, and deferred internal-ownership work.
- `docs/superpowers/plans/2026-06-11-scene-script-runtime-inventory-audit.md`
  - New exhaustive audit report for all audited `app-LTL` `.gd` and `.tscn` files.
  - Records 171 audited files: 156 scripts and 15 scenes.
  - Separates runtime-reachable, test/probe-only, test-reachable-only `src`, prototype, and migration-required cleanup classes.
  - Identifies the next deletion waves: legacy node map first, then `Main.tscn` AppShell migration.
- Deleted tracked dead residue:
  - `app-LTL/src/ui/legacy/LegacyRewardRevealOverlay.gd`
  - `app-LTL/src/data/rarity-table.json`
  - `app-LTL/tests/inspect_img.gd`
  - `app-LTL/resources/UI/backpack.png`
  - `app-LTL/resources/UI/backpack.png.import`
- `app-LTL/src/ui/MainViewRuntime.gd`
  - Removed declaration-only stale shop fields: `shop_gold_label`, `shop_xp_label`, `shop_buttons`, `shop_labels`, `current_shop_state`.
- `app-LTL/tests/ui_read_models/ui_reward_reveal_ceremony_suite.gd`
  - Added a contract that the legacy reward reveal backup is absent now that the cinematic overlay is the single owner.
- `app-LTL/tests/godot_contract_runner.gd`
  - Removed legacy reward reveal backup from required script/comment script lists.
- `docs/source-map.md`
  - Removed entries for deleted files and added the cleanup plan and inventory audit document entries.
- Generated local residue removed:
  - `app-LTL/.godot/`
  - `.godot-user/`
  - `.tmp-godot-crash-probe/`
  - `.tmp-godot-logs/`
  - `godot-contracts.log`
  - `reward-ceremony-contract.log`
  - `reward-ceremony-red2.log`
  - `reward-ceremony-red3.log`
- `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-11.md`
  - Updated daily plan to reflect the first deletion execution slice.
- `docs/codex-worklog/history_LootingTheLeviathan_2026-06-11.md`
  - Added a compressed record of the red test, deletions, verification, and generated residue cleanup.

## Verification Results

- Baseline `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1` -> `SOURCE_MAP_GATE_OK`
- Baseline `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` -> `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`
- Red test before deletion: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd` -> failed on the expected legacy reward backup presence assertion
- Post-delete focused UI test -> `UI_READ_MODEL_TESTS_OK`
- Post-delete `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1` -> `SOURCE_MAP_GATE_OK`
- Post-delete `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` -> `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`
- Post-generated-residue cleanup `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1` -> `SOURCE_MAP_GATE_OK`
- `git diff --check` -> exit 0; only CRLF normalization warnings were reported
- `Test-Path` checks confirmed all generated residue targets are missing
- Static inventory script completed for all `app-LTL/**/*.gd` and `app-LTL/**/*.tscn`
- Final `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1` after adding the audit report -> `SOURCE_MAP_GATE_OK`

## Remaining Gaps

- Godot was not rerun after generated residue cleanup because it would recreate `app-LTL/.godot/`; the full Godot compile/contract gate passed immediately before generated cleanup.
- Prototypes remain preserved by user decision.
- `docs/comment-gates/backups/**` still needs a separate archive decision.
- `NodeMapScene.gd`, `NodeMapScene.tscn`, and `NodeMapReadModel.gd` remain deferred because they are still runtime/test-wired and require node-select ownership migration first.
- Broad `Main.tscn` app-shell node deletion and Codex debug reveal removal remain deferred for separate coordinated passes.
- There are no loose unreferenced `res://src/**` `.gd`/`.tscn` orphan files left; remaining cleanup is structural migration work.

## Update: ordered cleanup execution

Completed the next requested runtime-cleanup wave from the 2026-06-11 audit. The legacy node-map runtime path is now gone, gameplay AppShell ownership has moved out of `Main.tscn` into dedicated page-shell scenes, and `ParticleTemplate` was kept as a supported hit-particle feature with explicit scene wiring plus a `VFXManager` fallback.

### Additional Outputs

- `app-LTL/src/scenes/pages/shells/ActionBar.tscn`
  - New shared gameplay action-bar shell used by node-select, battle, and reward pages.
- `app-LTL/src/scenes/pages/shells/BattlefieldPanel.tscn`
  - New shared battlefield shell owning the battle board and battle VFX surface.
- `app-LTL/src/scenes/pages/shells/GameplayTopContent.tscn`
  - New shared top-row shell owning status, backpack, and log/sidebar layout.
- `app-LTL/src/scenes/pages/shells/RewardPanel.tscn`
  - New shared reward-tray shell owning the reward board, workspace host, inspector, and discard/claim zones.
- `app-LTL/src/ui/MainViewRuntime.gd`
  - Removed legacy node-map ownership, cached per-page shell bundles, switched gameplay/reward lookups to bundle activation, and broadcast shared UI updates across page-owned shells.
- `app-LTL/src/ui/SharedBackpackHostCoordinator.gd`
  - Dropped the legacy node-map-only coupling after the runtime path removal.
- `app-LTL/src/ui/VFXManager.gd`
  - Added a runtime fallback that resolves `../ParticleTemplate` when the export is unset.
- `app-LTL/src/Main.tscn`
  - Deleted the old gameplay `TopContent`, `BattlefieldPanel`, `RewardPanel`, and `ActionBar` nodes and serialized the `VFXManager.particle_template` link to `ParticleTemplate`.
- `app-LTL/tests/**`
  - Updated start-flow, layout, reward, character-cleanup, viewport probe, reward-claim, and UI read-model contracts to follow page-owned shell nodes instead of deleted `Main.tscn` gameplay paths.
- `docs/source-map.md`
  - Added entries for the new page-shell scene files.

### Additional Verification

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_start_flow_contract.gd` -> `MAIN_START_FLOW_CONTRACT_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_main_layout_audit_contract.gd` -> `MAIN_LAYOUT_AUDIT_CONTRACT_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_character_select_cleanup_contract.gd` -> `CHARACTER_SELECT_CLEANUP_CONTRACT_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_reward_handoff_contract.gd` -> `REWARD_HANDOFF_CONTRACT_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_reward_claim_board_contract.gd` -> `REWARD_CLAIM_BOARD_CONTRACT_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd` -> `UI_READ_MODEL_TESTS_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` -> `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`

### Updated Remaining Gaps

- Existing Godot shutdown warnings still report pre-existing anchor/resource-leak noise even when the contract markers and exit codes are green.
- Prototype preservation and `docs/comment-gates/backups/**` archive decisions remain out of scope for this cleanup wave.

## Update: runtime size cap enforcement

Completed the requested large-file review and enforcement pass with three subagent review streams: script-size analysis, scene-size analysis, and harness/gate analysis. The harness gap was that prior policy used high exact caps for oversized runtime owners, treated some legacy test limits as warnings, and did not have a first-class "frozen debt" concept that lets strict 500-line glob caps apply to new or already-compliant files while forbidding debt growth.

### Runtime Outputs

- `LTL-harness/tools/runtime-size-gate.ps1`
  - Added `legacy_debt_path_caps` parsing and enforcement.
  - Legacy debt paths must exist and must not exceed their frozen line count.
  - Strict glob caps now enforce `app-LTL/src/**/*.gd=500` and `app-LTL/src/**/*.tscn=500` for non-debt runtime files.
- `LTL-harness/tools/runtime-size-gate.tests.ps1`
  - Added red/green coverage for frozen legacy debt, debt growth failure, non-debt `.gd` cap failure, and non-debt `.tscn` cap failure.
- `docs/architectural-gates/runtime-size-gate.md`
  - Replaced high exact runtime allowances with strict 500-line runtime source/scene caps plus exact frozen debt entries.
- `app-LTL/src/vocabulary/RewardVocab.gd`
  - Extracted fallback mock reward catalog data into `app-LTL/src/vocabulary/reward/DefaultMockRewards.gd`.
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
  - Extracted starter palette/loadout copy projection into `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`.

### Runtime Size Results

- `RewardVocab.gd` -> 294 lines
- `DefaultMockRewards.gd` -> 301 lines
- `CharacterSelectPage.gd` -> 464 lines
- `CharacterSelectLoadoutText.gd` -> 106 lines
- Active `.tscn` files are all under 500 lines; no scene exception is currently needed.
- Remaining oversized active runtime files are frozen debt: `MainViewRuntime.gd`, `MainControllerRuntime.gd`, `NodeSelectRuntimePage.gd`, `RewardRevealOverlay.gd`, `ArtifactCodexPanelUI.gd`, `CombatVocab.gd`, and `BackpackUI.gd`.

### Verification Results

- Red proof: runtime-size self-test failed before implementation because the old gate had no `legacy_debt_path_caps` support.
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/runtime-size-gate.tests.ps1` -> `RUNTIME_SIZE_GATE_TESTS_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/runtime-size-gate.ps1 -Root .` -> `RUNTIME_SIZE_GATE_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .` -> `SOURCE_MAP_GATE_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_reward_contract.gd` -> `REWARD_CONTRACT_TESTS_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_character_select_cleanup_contract.gd` -> `CHARACTER_SELECT_CLEANUP_CONTRACT_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-11-runtime-size-cap-enforcement.md` -> `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`

### Remaining Gaps

- The seven frozen oversized runtime owners still need future responsibility-split passes.
- Existing Godot anchor/resource-leak warnings and legacy test-size WARN entries remain visible in compile output, but the verified command exits 0 with the required success markers.
