# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-11

## Active Work

- Finish the current `MainViewRuntime.gd` helper-extraction wave by moving page-scene registry and popup-overlay host logic into smaller files, then report line-count reductions.

## Request Summary

- Finish the current runtime-view refactor wave after the reward-board layout extraction.
- Reduce `MainViewRuntime.gd` further by moving page-scene registry and popup-overlay host logic into smaller extracted helpers.
- Report which files shrank and by how many lines after the refactor wave is complete.

## Scope

- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/*.gd`
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

1. Re-read the current runtime-owner separation plan and identify the remaining safe extraction surfaces inside `MainViewRuntime.gd`.
2. Add failing focused tests for page-scene registry and popup-overlay helper behavior before moving production code.
3. Extract page-scene registry and popup-overlay host logic into new helper files.
4. Delegate `MainViewRuntime.gd` to the extracted helpers without changing runtime behavior.
5. Re-run focused UI tests plus compile/quality verification, then calculate before/after line counts for the reduced files.

## Expected Outputs

- A smaller `MainViewRuntime.gd` with reward-board layout, page-scene registry, and popup-overlay host logic delegated out to focused helpers.
- Focused test surfaces that prove the extracted helper behavior before integration.
- Updated worklog notes that capture what part of the owner split is complete and what still remains.
- A before/after line-count summary for each file that shrank during this refactor wave.

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md -ArtifactLedger docs/artifact-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md`
- `git show <baseline-commit>:<path>` or equivalent line-count comparison commands for reporting shrinkage honestly

## Plan Change Log

- 2026-06-11: Worklog bootstrapped automatically by Codex hook.
- 2026-06-11: Plan updated for a two-phase execution sequence: minimal gate/source-map checkpoint commit first, then runtime-separation surgery and harness hardening.
- 2026-06-11: Plan narrowed again for the next refactor wave: extract reward-board layout policy from `MainViewRuntime.gd` with test-first coverage.
- 2026-06-11: Plan narrowed once more to finish the current `MainViewRuntime.gd` helper-extraction wave and prepare a concrete line-count reduction report.
