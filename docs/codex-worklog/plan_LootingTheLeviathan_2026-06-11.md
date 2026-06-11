# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-11

## Active Work

- Continue the next active-runtime separation wave by extracting reward-board layout policy out of `MainViewRuntime.gd` into a smaller helper with test-first coverage.

## Request Summary

- Continue the refactor after the runtime-size gate pass.
- Reduce `MainViewRuntime.gd` by moving reward-board layout math into a smaller extracted helper.
- Keep the current runtime-size/page-contract/quality gates green while shrinking the owner file.

## Scope

- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/presenters/*.gd`
- `app-LTL/tests/ui_read_models/*.gd`
- `app-LTL/tests/test_ui_read_models.gd`
- request ledger and worklog updates for this task
- any source-map updates required by the extracted helper or new focused test file

## Out of Scope

- Prototype archive rewrites under `app-LTL/prototype/**`
- `MainControllerRuntime.gd` flow extraction in this pass
- node-map/page-host rewiring outside the reward-board layout surface
- unrelated gameplay design changes

## Steps

1. Re-read the current runtime-owner separation plan and identify the next safe extraction surface inside `MainViewRuntime.gd`.
2. Add a failing focused UI read-model suite for reward-board layout policy behavior before moving production code.
3. Extract the pure reward-board layout math into a new helper under `app-LTL/src/ui/presenters/`.
4. Delegate `MainViewRuntime.gd` to the extracted helper without changing reward-board behavior.
5. Re-run focused UI tests plus compile/quality verification and record the result.

## Expected Outputs

- A smaller `MainViewRuntime.gd` with reward-board layout math delegated out to a focused helper.
- A new focused test surface that proves the extracted helper behavior before integration.
- Updated worklog notes that capture what part of the owner split is complete and what still remains.

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md -ArtifactLedger docs/artifact-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md`

## Plan Change Log

- 2026-06-11: Worklog bootstrapped automatically by Codex hook.
- 2026-06-11: Plan updated for a two-phase execution sequence: minimal gate/source-map checkpoint commit first, then runtime-separation surgery and harness hardening.
- 2026-06-11: Plan narrowed again for the next refactor wave: extract reward-board layout policy from `MainViewRuntime.gd` with test-first coverage.
