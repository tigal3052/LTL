# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-02

## Active Work

Design and implement M5 as a color-first obstacle layer plus separate `relic` item support, where relics are not drills or beacons and affect the whole build globally.

## Request Summary

The user asked for M5 to be implemented after parallel sub-agent discussion across balance, fun, design, programming, and feature-lead perspectives. The requested outcome is:

- red/blue/purple/green-aligned obstacles that are easy to solve with the matching trait
- a scalable obstacle difficulty design that continues to work as stages increase
- obstacle art that includes solve/break animations or effects, not just static images
- a high-quality implementation rather than a placeholder
- roughly twenty new relic concepts, split into about ten obstacle-related relics and ten general-purpose relics, where relics are separate from drills/beacons and can globally affect the build or provide independent abilities

## Scope

- Establish the final M5 design direction around a shared obstacle lifecycle and color-specific solve rules.
- Add first-class combat obstacle state to the formal Godot runtime under `app-LTL/src/**`.
- Render obstacle warnings, active states, and solve/fail feedback in the battlefield UI.
- Add deterministic stage-aware obstacle generation that scales through reusable data instead of one-off stage scripts.
- Define the first relic-system content pass around about twenty new relic concepts, including obstacle-solvers and general run-defining passives, with rarity-aware distribution similar to drills/beacons.
- Implement the approved launch subset of relics only after the concept pool, rarity philosophy, and runtime encoding are finalized.
- Add RED-first automated coverage for obstacle generation, obstacle solving, relic effects, and UI/read-model projection.
- Record the design and implementation history in the dated worklog.

## Out of Scope

- Reverting unrelated dirty-worktree files.
- Replacing the broader reward-pool structure beyond the targeted relic substitutions needed for M5.
- Building the full future hazard platform described in the harness plan if it is not required for this M5 slice.
- Broad visual redesign outside the battlefield obstacle layer.

## Steps

- Lock the clarified design assumptions from the user and sub-agent synthesis, especially the separate meaning of `relic`.
- Write the M5 design spec for this slice and have the user review it before implementation.
- Create a focused implementation plan from that approved spec.
- Add RED-first contract tests for obstacle generation, obstacle state projection, obstacle solving, and relic runtime behavior.
- Implement the new obstacle runtime/state flow and battlefield presentation.
- Add and wire the approved launch relic items as global passive items distinct from drills/beacons, using the broader 20-concept design pool as the source set.
- Run focused and broad verification, then update completion reporting.

## Expected Outputs

- New or updated M5 design spec under `docs/superpowers/specs/`
- New or updated M5 implementation plan under `docs/superpowers/plans/`
- Updated combat/runtime/data/UI/test files under `app-LTL/src/**` and `app-LTL/tests/**`
- Updated `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-02.md`
- Updated `docs/codex-worklog/history_LootingTheLeviathan_2026-06-02.md`
- Updated `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-02.md`

## Verification Method

- Focused obstacle/runtime tests to be added in `app-LTL/tests/**`
- Existing combat and UI runners including `app-LTL/tests/test_combat_vocab.gd`
- Existing read-model/UI runner `app-LTL/tests/test_ui_read_models.gd`
- Existing release-content and route-content contracts where relevant
- Broad regression runner: `app-LTL/tests/godot_contract_runner.gd`
- Whitespace check on touched files with `git diff --check`

## Plan Change Log

- 2026-06-02: Re-scoped the active work to M5 obstacle layering after the user requested sub-agent-guided design and implementation, then clarified that relic items are global passive items separate from drills and beacons.
