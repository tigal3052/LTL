# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-17

## Active Work

Fix the current quality-gate completion status, rebalance starter items and Leviathan stage health, and add generic duplicate reward item fusion.

## Request Summary

The user asked to resolve the stale `run-ltl-quality-gate.ps1` incomplete gate state, rebalance red/blue/purple/green starter items so stage one is easy for all, adjust Leviathan health scaling so later stages become harder, and implement a reusable fusion mechanic where duplicate reward items up to epic rarity combine into the next tier with improved performance.

## Scope

- Re-run the full LTL quality gate and update stale QA/completion notes if the gate now passes.
- Add focused balance/fusion regression tests before production changes.
- Tune starter drill/beacon numbers and stage durability/health totals within existing balance APIs.
- Add an encapsulated reward item fusion helper for duplicate reward artifacts up to epic rarity.
- Wire fusion into the existing reward-to-backpack placement flow without changing unrelated UI or page structure.

## Out Of Scope

- Reverting or cleaning unrelated dirty-tree changes.
- Redesigning reward UI, character selection UI, or page layouts.
- Adding fusion for legendary or mythic duplicate inputs.
- Creating a commit, branch, PR, or unrelated evidence artifact.

## Steps

- Confirm dirty tree and read quality gate, starter item, stage scaling, reward creation, and backpack placement code.
- Reproduce the quality gate result from a fresh run.
- Add focused RED tests for starter first-stage clearability, increasing stage health, and duplicate reward fusion.
- Implement the minimal balance values and fusion helper/wiring needed to pass the tests.
- Run the focused new contract plus relevant existing Godot reward/combat/full contract checks.
- Run the full quality gate again and update QA/worklog completion notes.

## Expected Outputs

- Updated balance code/data for starter loadouts and stage health scaling.
- New generic item fusion helper and reward placement wiring.
- Focused regression tests and runner for balance/fusion behavior.
- QA/worklog note showing the quality gate is no longer blocked when verified.

## Verification Method

- `tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-17-m8-vertical-slice.md -ArtifactLedger docs/artifact-ledgers/2026-06-17-quality-gate-fix.md`.
- New focused Godot runner for balance and fusion.
- Existing reward/combat/full Godot contracts as relevant.
- `git diff --check`.
- Final request recheck against the original user request.

## Plan Change Log

- 2026-06-17: Replaced the previous active implementation plan with the current review/checklist request.
- 2026-06-17: Updated active work for the follow-up request to auto-complete verifiable checklist items and leave only human-only checks.
- 2026-06-17: Replaced active work with the current gate, starter balance, Leviathan scaling, and reward fusion implementation request.
