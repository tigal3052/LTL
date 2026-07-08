# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-25

## Active Work

Update the requested beacon reward rows so `Crimson Spark Relay` and `Violet Veil Relay` are common 1x1 backpack items.

## Request Summary

User asked to change the Korean rewards `"진홍 스파크 릴레이"` and `"보랏빛 베일 릴레이"` from rare multi-cell beacons into common 1x1 grid items.

## Scope

- Inspect the two named reward rows and existing reward contract tests.
- Add a focused contract assertion for the requested common 1x1 beacon rows.
- Update only the requested reward metadata/shape and any directly affected distribution expectations.
- Refresh source-map metadata if the data/test/doc edits make the fingerprint stale.

## Out of Scope

- Changing unrelated reward weights, payload stats, or run progression behavior.
- Renaming stable reward ids unless validation proves it is required.
- Refactoring unrelated backpack, reward, or controller surfaces.
- Committing or pushing changes.

## Steps

- Add RED coverage that locates the two Korean reward names and asserts `rarity == "common"` plus `shape == [[1]]`.
- Update the two reward rows and any grade-facing badge/tag/description text that would otherwise still say rare.
- Adjust exact reward distribution expectations only where the two requested rarity changes affect them.
- Run the focused reward contract and source-map freshness checks where feasible.
- Update worklog history/completion with the final scope and verification result.

## Expected Outputs

- `Crimson Spark Relay` / `"진홍 스파크 릴레이"` is a common beacon with `payload.shape == [[1]]`.
- `Violet Veil Relay` / `"보랏빛 베일 릴레이"` is a common beacon with `payload.shape == [[1]]`.
- Existing reward table contracts reflect the intentional two-row rarity migration.

## Verification Method

- Focused Godot contract: `app-LTL/tests/run_test_reward_contract.gd`.
- Source-map gate refresh/check or documented blocker if the current dirty workspace prevents a clean pass.

## Plan Change Log

- 2026-06-25: Worklog bootstrapped automatically by Codex hook.
- 2026-06-25: Scoped current request to beacon item-image wiring and focused verification.
- 2026-06-25: Rescoped active work to the requested `Crimson Spark Relay` and `Violet Veil Relay` common 1x1 reward data change.
