# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-26

## Active Work

Implement the drill/beacon EnergyToken redesign requested on 2026-06-26.

## Request Summary

Replace color-deduped drill queue behavior with instance-based EnergyToken rotation. Every equipped drill should produce its own token, queue charging should use the arithmetic average of equipped drill effective cooldowns, and token rotation should follow effective cooldown ascending order. Beacons should no longer permanently mutate drill stats; they should annotate generated tokens from adjacent same-color drills. Reward generation should assign deterministic roll variance to catalog items, and fusion should preserve the user's intended low-roll risk: low rolls are usually discardable, not rescued by bonus progress.

## Scope

- Combat queue token contract and queue generation.
- Inventory drill/beacon synergy behavior for token modifiers.
- Combat damage/source handling for structured EnergyTokens.
- Reward item roll metadata and deterministic stat variance.
- Duplicate fusion behavior centered on the chosen base roll.
- Focused Godot contract tests and source-map/worklog updates.

## Out of Scope

- Adding new small component/part item families.
- Turning beacons into direct queue editors.
- Adding low-roll rescue bonuses or fusion progress.
- Commit or push operations.
- Broad UI redesign beyond keeping previews/read-models contract-safe.

## Steps

- Add failing contract coverage for instance-token queue rotation, average cooldown, same-color drill source/damage separation, beacon token modifiers, deterministic reward rolls, and base-roll fusion.
- Implement EnergyToken helpers in the combat queue vocabulary while preserving legacy token compatibility where needed.
- Move beacon contribution from permanent drill damage mutation to token modifier construction.
- Update combat shot resolution to use token source, damage, and modifiers.
- Add deterministic reward roll metadata/stat variance and fusion rules without low-roll rescue.
- Run focused Godot contract tests, source-map refresh/gate, and the smallest applicable compile/check path.
- Record semantic history and completion notes.

## Expected Outputs

- Updated runtime vocabulary/model code for EnergyToken behavior.
- Updated reward/fusion code for roll range and base-roll policy.
- Focused regression tests proving the requested mechanics.
- Refreshed `docs/source-map.md` if scoped files change.
- Worklog history and completion reports.

## Verification Method

- RED/GREEN focused Godot contract tests via `tools/invoke-godot.ps1`.
- Existing reward/combat contract suites touched by the change.
- `LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh` after source/test/doc changes in scope, then gate validation.
- `tools/run-compile-check.ps1` if the focused checks pass far enough to justify broader verification.

## Plan Change Log

- 2026-06-26: Worklog bootstrapped automatically by Codex hook.
- 2026-06-26: Replaced placeholder with EnergyToken implementation scope, frozen exclusions, and verification path.
