# Request Constraint Ledger

## Request Summary

- Implement the drill/beacon EnergyToken redesign: drills generate individual token objects, beacons stamp buffs onto generated tokens, rewards gain seeded roll variance, and duplicate fusion uses the base roll without low-roll rescue progress.

## Preserved Invariants

- Keep the user-facing terms and identities `drill` and `beacon`.
- Preserve color-based attack styles for red, blue, purple, and green combat behavior.
- Do not add small component item families or fusion progress systems.
- Do not make beacons permanent drill-stat mutators or queue editors.
- Do not commit or push.

## Mutable Scope

- `app-LTL/src/models/InventoryModel.gd`
- `app-LTL/src/models/Artifact.gd`
- `app-LTL/src/phases/NodeSelectPhase.gd`
- `app-LTL/src/phases/CombatPhase.gd`
- `app-LTL/src/vocabulary/CombatVocab.gd`
- `app-LTL/src/vocabulary/RewardVocab.gd`
- `app-LTL/src/vocabulary/combat/RecalculateQueueColors.gd`
- `app-LTL/src/vocabulary/combat/EnergyToken.gd`
- `app-LTL/src/vocabulary/reward/CreateArtifactFromReward.gd`
- `app-LTL/src/vocabulary/reward/ItemFusion.gd`
- Focused Godot contract tests for combat, backpack, reward, and fusion behavior.

## Source Map Findings

- `docs/source-map.md` maps `app-LTL/src/models/InventoryModel.gd` to artifact grid placement, collisions, and bounds.
- `docs/source-map.md` maps `app-LTL/src/phases/NodeSelectPhase.gd` to node-select snapshot generation.
- `docs/source-map.md` maps `app-LTL/src/vocabulary/combat/EnergyToken.gd` to focused Energy Token vocabulary.
- `docs/source-map.md` maps `app-LTL/src/vocabulary/CombatVocab.gd` to combat simulator preparation and combat vocabulary behavior.
- `docs/source-map.md` maps `app-LTL/src/vocabulary/reward/ItemFusion.gd` to duplicate reward-item fusion.
- `docs/source-map.md` maps `app-LTL/src/vocabulary/RewardVocab.gd` to deterministic stage reward generation.

## Root Cause Review

- Observed symptom: same-color drills collapsed into one queue color, beacon damage permanently mutated drill stats, reward offers had no per-instance roll tension, and fusion selected the best incoming material stats.
- Evidence: RED focused tests failed on missing average cooldown metadata, same-color source separation, token damage/modifiers, seeded roll metadata, and base roll preservation.
- Root cause target: `app-LTL/src/models/InventoryModel.gd`
- Rejected workaround: only retune numeric damage/cooldown values or add low-roll rescue bonuses while keeping the old color-dedupe and permanent mutation model.
- Chosen fix: add a shared EnergyToken contract, persist average queue charge state, stamp beacon effects onto generated tokens, add seeded reward roll metadata, and make fusion inherit base roll stats.

## Transition Safety Review

- Touched transition: `meta.start_flow` covers node_select -> combat -> reward flow touched by `app-LTL/src/phases/NodeSelectPhase.gd`.
- Entry owner: NodeSelectPhase reduce.
- Exit owner: CombatPhase reduce.
- Shared state risk: initial combat queues and inventory queue charge state must survive dictionary snapshot/restore boundaries.
- Mitigation: InventoryModel to_dict now includes `energyQueueChargeProgress` and `energyQueueRotationIndex`; CombatPhase and NodeSelectPhase restore those fields.
- Runner proof: `res://tests/godot_contract_runner.gd` -> `GODOT_CONTRACTS_OK`.

## Feature Unit Lifecycle Plan

- Design stage: introduce `app-LTL/src/vocabulary/combat/EnergyToken.gd` as the narrow helper boundary for token construction, normalization, source id, average cooldown, and beacon token modifiers.
- Implementation stage: RED contract tests first for queue tokens, average cooldown rotation, beacon token buffs, seeded reward rolls, and base-roll fusion.
- Maintenance stage: extend `EnergyToken.gd` for future token-only beacon modifiers instead of spreading token shape logic across reducers.
- Capsule boundary: public static helpers return plain Dictionaries; inventory placement, combat damage rules, and reward fusion formulas stay in their existing owners.
- Size trigger: keep `CombatVocab.gd` under the existing 500-line cap by moving token details into `EnergyToken.gd`.

## Execution Responsibility Units

- Owner: `app-LTL/src/vocabulary/CombatVocab.gd`
- Unit: consume queue tokens and apply token damage/source identity during combat shots.
- Extract to: `app-LTL/src/vocabulary/combat/EnergyToken.gd`
- Keep in owner: combat hit, terrain, obstacle, repair, and relic hook sequencing.
- Focused proof: `res://tests/run_test_combat_vocab.gd` -> `COMBAT_VOCAB_TESTS_OK`.

## Runtime Performance Review

- Hot path: `app-LTL/src/models/InventoryModel.gd` `InventoryModel.tick` during combat tick events through `app-LTL/src/phases/CombatPhase.gd` and `app-LTL/src/vocabulary/CombatVocab.gd`.
- Risk: rebuilding token records every tick can add repeated allocation as inventories grow.
- Performance proof: `res://tests/godot_contract_runner.gd`
- Budget: keep token record construction linear in placed artifacts and avoid UI/render work in tick.

## File Size Budget

- `app-LTL/src/vocabulary/CombatVocab.gd`: 414 lines after implementation, cap 500, planned final shape stays under cap via `EnergyToken.gd`.
- `app-LTL/src/vocabulary/combat/EnergyToken.gd`: 118 lines, focused helper.
- Other touched `.gd` files remain below their current source-map gate constraints.

## Refactor/Delete Disposition

- Keep existing drill/beacon/reward/fusion owners.
- Refactor only token construction and normalization into `EnergyToken.gd`.
- Delete no source files.

## Verification Checklist

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_test_combat_vocab.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_test_reward_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_balance_and_fusion_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/godot_contract_runner.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-26-energy-token-redesign.md`

## Verification Notes

- Focused combat, reward, and fusion contracts passed after implementation.
- Full Godot contract runner passed with existing headless RID leak warnings after backpack tests were updated to the new token contract.
- Source-map refresh passed and recorded `app-LTL/src/vocabulary/combat/EnergyToken.gd`.

## Resolution Proof

- RED proof: focused combat/reward/fusion tests failed before implementation on missing average cooldown, same-color drill source separation, token modifiers, seeded roll metadata, and base roll preservation.
- Root-cause proof: focused contracts now pass and full `godot_contract_runner.gd` reports `GODOT_CONTRACTS_OK`.
- Workaround guard: tests assert drill damage remains unchanged under beacon placement and fusion preserves base `rollQuality`, preventing permanent-stat mutation or low-roll rescue workarounds.

## Artifact Ledger

- No generated visual artifacts.
