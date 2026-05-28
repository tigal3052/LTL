# M3. Reward and Progression Completion Report

**Related active plan:** `docs/11_exec-plans/01_active/09_M3_reward_and_progression.md`

## Completion Summary

- M3 reward/progression was promoted into the formal Godot path under `app-LTL/src/**`.
- Reward data is now managed through JSON tables and validator contracts.
- Reward rolling remains seed-based and rarity-first, with deterministic offer metadata and a player-facing next-combat modifier preview.
- Reward selection and backpack organization use formal phase/vocabulary capsules rather than prototype runtime logic.
- Run growth state, gold/xp style payload handling, reward telemetry payload construction, and reward read-model privacy are covered by focused contract tests.
- The later balance pass expanded each rarity tier so both drill-like and beacon candidates can appear without cross-rarity beacon injection.

## Actual Outputs

- `app-LTL/src/data/reward-table.json`
- `app-LTL/src/data/rarity-table.json`
- `app-LTL/src/data/progression-default.json`
- `app-LTL/src/validation/RewardValidator.gd`
- `app-LTL/src/models/RunGrowthState.gd`
- `app-LTL/src/phases/RewardLootPhase.gd`
- `app-LTL/src/phases/BackpackOrganizePhase.gd`
- `app-LTL/src/vocabulary/RewardVocab.gd`
- `app-LTL/src/vocabulary/reward/CreateArtifactFromReward.gd`
- `app-LTL/src/vocabulary/reward/ApplyRewardEffect.gd`
- `app-LTL/src/vocabulary/reward/BuildRewardPreview.gd`
- `app-LTL/src/vocabulary/reward/BuildRewardTelemetry.gd`
- `app-LTL/src/vocabulary/backpack/PickUpFromRewardTray.gd`
- `app-LTL/src/vocabulary/backpack/PlaceHeld.gd`
- `app-LTL/src/vocabulary/backpack/DiscardHeld.gd`
- `app-LTL/src/vocabulary/backpack/RecalculateSynergy.gd`
- `app-LTL/src/ui/read_models/RewardReadModel.gd`
- `app-LTL/tests/test_reward_contract.gd`
- `docs/superpowers/plans/2026-05-28-m3-reward-progression-contract-gap-plan.md`

## Verification Results

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`: passed with `GODOT_CONTRACTS_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/milestone-gate.ps1 -TargetPlan 09_M3_reward_and_progression.md`: passed with `MILESTONE_GATE_OK`.
- `git diff --check`: reported no whitespace errors; Git printed LF-to-CRLF warnings only.
- Reward contract coverage is executed through `app-LTL/tests/godot_contract_runner.gd`, which loads and runs `app-LTL/tests/test_reward_contract.gd`.

## Changes From Plan

- `reward_loot` and `backpack_organize` were implemented as formal phase boundaries.
- Reward scene polish and screenshot evidence were deferred; the milestone focused on formal contracts, deterministic state transitions, and read-model projection.
- The reward-pool balance correction used table expansion instead of changing the rarity-first roll architecture.
- Full meta progression shop and large item-pool expansion remain outside M3 scope.

## Remaining Gaps

- Reward scene screenshot evidence and richer manual reward presentation QA still need a later pass.
- Reward card visual polish remains separate from the formal reward contract work.
- Broader item database management can be improved later with editor-facing data tooling once the vertical slice stabilizes.
