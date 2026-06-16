# Request Constraint Ledger

## Request Summary

- Review the current large Godot source and scene files after cleanup.
- Split immediately tractable oversized files by responsibility.
- Harden the harness so new runtime `.gd` and `.tscn` files cannot exceed 500 lines.
- Explain why the previous harness rules allowed oversized implementation files to keep growing.

## Preserved Invariants

- Existing user cleanup changes in the dirty worktree are preserved and not reverted.
- Active runtime behavior, page ids, reward contracts, node-select contracts, and source-map ownership stay stable.
- Prototype archives under `app-LTL/prototype/**` remain preserved reference material.
- Existing large runtime owners are treated as frozen debt unless this request directly splits them.

## Mutable Scope

- `LTL-harness/tools/runtime-size-gate.ps1`
- `LTL-harness/tools/runtime-size-gate.tests.ps1`
- `docs/architectural-gates/runtime-size-gate.md`
- `docs/source-map.md`
- `docs/request-ledgers/2026-06-11-runtime-size-cap-enforcement.md`
- `docs/superpowers/plans/2026-06-11-runtime-size-cap-enforcement-plan.md`
- `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-11.md`
- `docs/codex-worklog/history_LootingTheLeviathan_2026-06-11.md`
- `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-11.md`
- `app-LTL/src/vocabulary/RewardVocab.gd`
- `app-LTL/src/vocabulary/reward/DefaultMockRewards.gd`
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
- `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`

## Source Map Findings

- `docs/architectural-gates/runtime-size-gate.md`
  - The previous manifest used high exact caps for large runtime owners, so files above 500 lines still passed.
- `LTL-harness/tools/runtime-size-gate.ps1`
  - The gate can already enforce glob caps for any extension, but it has no explicit legacy-debt field that separates frozen debt from strict 500-line policy.
- `app-LTL/src/**/*.tscn`
  - No active runtime scene currently exceeds 500 lines, so `.tscn` hard caps can be added immediately.
- `app-LTL/src/vocabulary/RewardVocab.gd`
  - The source file is over 500 lines mainly because fallback/mock reward data is stored beside reward rolling logic.
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
  - The page is just over 500 lines because starter loadout text/detail projection is mixed into page rendering.

## Root Cause Review

- Observed symptom: runtime `.gd` files could grow beyond the intended 500-line implementation rule and only fail during completion-time verification.
- Evidence: the previous manifest allowed high exact caps for large runtime owners, and the pre-edit request-analysis gate only mapped exact monitored paths instead of strict glob caps.
- Root cause target: LTL-harness/tools/request-analysis-gate.ps1
- Rejected workaround: relying on the final runtime-size gate alone forces agents to refactor after implementation rather than splitting by responsibility before editing.
- Chosen fix: separate frozen legacy debt from strict runtime caps, then require execution-responsibility coverage for touched monitored runtime owners before implementation.

## Transition Safety Review

- no transition impact
- This request does not change phase routing, page ids, transition handoff owners, or reward/combat state transitions.

## Execution Responsibility Units

- Owner: `LTL-harness/tools/runtime-size-gate.ps1`
  - Unit: strict source/scene size policy with frozen legacy debt exceptions.
  - Keep in owner: manifest parsing, line counting, glob matching, and failure reporting.
  - Focused proof: `LTL-harness/tools/runtime-size-gate.tests.ps1`.
- Owner: `app-LTL/src/vocabulary/RewardVocab.gd`
  - Unit: fallback reward catalog data.
  - Extract to: `app-LTL/src/vocabulary/reward/DefaultMockRewards.gd`
  - Focused proof: `app-LTL/tests/run_test_reward_contract.gd`
- Owner: `app-LTL/src/scenes/pages/CharacterSelectPage.gd`
  - Unit: starter loadout detail and color copy projection.
  - Extract to: `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`
  - Focused proof: `app-LTL/tests/run_character_select_cleanup_contract.gd`

## File Size Budget

- `app-LTL/src/vocabulary/RewardVocab.gd`: current over 500 before split, cap 500, planned final below cap, split target `app-LTL/src/vocabulary/reward/DefaultMockRewards.gd`.
- `app-LTL/src/scenes/pages/CharacterSelectPage.gd`: current over 500 before split, cap 500, planned final below cap, split target `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd`.
- Frozen debt owners listed in `legacy_debt_path_caps`: planned final non-growth unless directly split in a future request.

## Refactor/Delete Disposition

- Split data/text projection that has no scene-tree ownership out of the two smallest oversized files first.
- Do not attempt a risky one-turn rewrite of `MainViewRuntime.gd`, `MainControllerRuntime.gd`, `NodeSelectRuntimePage.gd`, or `RewardRevealOverlay.gd`; freeze their current debt caps and require future extraction units before edits.
- Keep `.tscn` policy simple: active runtime scene files have a hard 500-line cap, and any future exception must be an exact frozen debt entry.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/runtime-size-gate.tests.ps1` after adding RED tests and before implementing gate support.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/runtime-size-gate.tests.ps1` after implementation.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/runtime-size-gate.ps1 -Root .`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_reward_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_character_select_cleanup_contract.gd`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-11-runtime-size-cap-enforcement.md`.

## Verification Notes

- RED gate proof:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/runtime-size-gate.tests.ps1` failed before implementation because a strict `app-LTL/src/**/*.gd=500` rule still blocked a legacy oversized owner; the old gate had no `legacy_debt_path_caps` separation.
- Green gate proof:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/runtime-size-gate.tests.ps1` -> `RUNTIME_SIZE_GATE_TESTS_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/runtime-size-gate.ps1 -Root .` -> `RUNTIME_SIZE_GATE_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .` -> `SOURCE_MAP_GATE_OK`
- Focused Godot proof:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_reward_contract.gd` -> `REWARD_CONTRACT_TESTS_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_character_select_cleanup_contract.gd` -> `CHARACTER_SELECT_CLEANUP_CONTRACT_OK`
- Full compile proof:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-11-runtime-size-cap-enforcement.md` -> `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`
  - The compile output still includes existing Godot anchor/resource-leak warnings and legacy test-size WARN entries, but the command exits 0 with required success markers.
- Current line policy:
  - Active non-debt `app-LTL/src/**/*.gd` files are capped at 500 lines.
  - Active non-debt `app-LTL/src/**/*.tscn` files are capped at 500 lines.
  - Existing oversized owners are exact frozen debt entries; any growth fails the runtime-size gate.
- Split outcomes:
  - `app-LTL/src/vocabulary/RewardVocab.gd` is now 294 lines.
  - `app-LTL/src/vocabulary/reward/DefaultMockRewards.gd` is 301 lines.
  - `app-LTL/src/scenes/pages/CharacterSelectPage.gd` is now 464 lines.
  - `app-LTL/src/scenes/pages/character_select/CharacterSelectLoadoutText.gd` is 106 lines.
- Remaining frozen active runtime debt:
  - `app-LTL/src/ui/MainViewRuntime.gd` = 2429 lines
  - `app-LTL/src/MainControllerRuntime.gd` = 1667 lines
  - `app-LTL/src/scenes/pages/NodeSelectRuntimePage.gd` = 1352 lines
  - `app-LTL/src/ui/RewardRevealOverlay.gd` = 1303 lines
  - `app-LTL/src/ui/ArtifactCodexPanelUI.gd` = 948 lines
  - `app-LTL/src/vocabulary/CombatVocab.gd` = 938 lines
  - `app-LTL/src/ui/BackpackUI.gd` = 723 lines
- Scene file exception policy:
  - No active `.tscn` currently exceeds 500 lines.
  - If a future scene needs more than 500 lines, it must be recorded as an exact frozen debt path with a documented split owner and must not be allowed through broad glob caps.

## Resolution Proof

- RED proof: `runtime-size-gate.tests.ps1` failed before implementation because strict `app-LTL/src/**/*.gd=500` caps also blocked known oversized legacy owners.
- Root-cause proof: `runtime-size-gate.tests.ps1` and `runtime-size-gate.ps1 -Root .` passed after `legacy_debt_path_caps` separated frozen debt from strict non-debt caps.
- Workaround guard: the ledger records concrete split units for `RewardVocab.gd` and `CharacterSelectPage.gd`, not only a completion-time line-count exception.
