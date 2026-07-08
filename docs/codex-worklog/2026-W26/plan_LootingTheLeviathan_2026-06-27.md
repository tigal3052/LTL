# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-27

## Active Work

EnergyToken/reward roll follow-up: centralize reward stat rolling and correct rarity roll variance direction.

## Request Summary

Implement approach 1 for same-name/same-rarity drill/beacon stat variance. Low rarity items should have wider random stat spread, high rarity items should be more stable with narrower spread, and high-performance rolls should be rarer. Detail panels, acquired artifacts, combat values, and fusion previews must use the same rolled item instance values. Fusion must not add new randomness, low-roll rescue bonuses, or fusion progress.

## Scope

- Extract reward stat roll behavior into a focused `ItemStatRoller` helper.
- Route `RewardVocab` reward generation through the shared helper.
- Add or adjust focused contract tests for rarity span direction, skewed quality distribution, drill/beacon roll coverage, UI detail parity, and fusion no-extra-randomness.
- Keep existing EnergyToken, queue, beacon, and fusion behavior intact except where tests expose a direct contract mismatch.

## Out of Scope

- New item families or component item bloat.
- Low-roll material rescue bonuses or fusion progress.
- Rebalancing reward-table item identities, names, art, or broad distribution.
- Git commit/push.

## Steps

- Write failing reward/read-model/fusion contract coverage for the requested roll policy.
- Implement the smallest central `ItemStatRoller` extraction and `RewardVocab` routing change.
- Run focused Godot contract tests and the fastest broader quality check available.
- Refresh source-map metadata if touched source/test files require it.
- Record concise history and completion notes.

## Expected Outputs

- A central stat roll helper used by stage reward generation.
- Same catalog item can roll different stats, with low rarity spread wider than high rarity.
- Higher-performance quality results are rarer than low/mid results.
- Drill and beacon stat fields both roll.
- Detail inspector values match materialized Artifact values.
- Fusion uses existing material values without extra randomness.

## Verification Method

- Focused reward contract runner.
- UI read-model contract runner for detail/inspector parity.
- Balance/fusion contract runner.
- Source-map gate after source/test/doc updates.

## Plan Change Log

- 2026-06-27: Worklog bootstrapped automatically by Codex hook.
- 2026-06-27: Updated for reward stat roll centralization and corrected rarity spread policy.
