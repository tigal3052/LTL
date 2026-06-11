# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-11

## Active Work

- Continue the `MainViewRuntime.gd` owner split by extracting the reward-card cloud runtime into its own execution-responsibility helper and harden the pre-edit harness so large runtime-owner edits must declare decomposition units before implementation begins.

## Request Summary

- Continue the current runtime-view refactor wave after the reward-board, page-registry, popup-overlay, page-model, and app-shell policy extractions.
- Reduce `MainViewRuntime.gd` further by moving the reward-card cloud execution path into a dedicated runtime helper.
- Harden the harness so touching a monitored large runtime owner requires an `Execution Responsibility Units` plan at `pre-edit` time instead of waiting for late verification.
- Report which files shrank and which implementation-stage checks now prevent owner-growth regressions.

## Scope

- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/*.gd`
- `app-LTL/src/ui/presenters/*.gd`
- `app-LTL/tests/ui_read_models/*.gd`
- `app-LTL/tests/test_ui_read_models.gd`
- `LTL-harness/tools/request-analysis-gate.ps1`
- `LTL-harness/tools/request-analysis-gate.tests.ps1`
- `LTL-harness/docs/request-analysis-execution-gate.md`
- `LTL-harness/docs/templates/request-constraint-ledger-template.md`
- `LTL-harness/00_AGENTS.md`
- request ledger and worklog updates for this task
- any source-map updates required by the extracted helper or new focused test file

## Out of Scope

- Prototype archive rewrites under `app-LTL/prototype/**`
- `MainControllerRuntime.gd` flow extraction in this pass
- node-map/page-host rewiring outside the reward-board layout surface
- unrelated gameplay design changes

## Steps

1. Re-read the current runtime-owner separation plan and identify the next live execution unit inside `MainViewRuntime.gd`.
2. Add failing focused tests for the reward-card cloud helper and for the request-analysis gate’s new runtime-owner responsibility requirement.
3. Extract the reward-card cloud runtime into a dedicated helper file and delegate `MainViewRuntime.gd` to it without changing behavior.
4. Tighten `request-analysis-gate.ps1`, its self-tests, and the ledger template/docs so monitored runtime-owner edits must declare execution responsibility units before implementation.
5. Re-run request-analysis, focused UI tests, compile/quality verification, then calculate before/after line counts and note the remaining large extraction groups.

## Expected Outputs

- A smaller `MainViewRuntime.gd` with reward-card cloud runtime delegated out to a focused helper.
- A stricter pre-edit request-analysis gate that forces responsibility-unit decomposition planning whenever a monitored large runtime owner is touched.
- Focused test surfaces that prove the extracted helper behavior before integration.
- Updated worklog notes that capture what part of the owner split is complete and what still remains.
- A before/after line-count summary for each file that shrank during this refactor wave.

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md -Mode pre-edit`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.tests.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md -ArtifactLedger docs/artifact-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md`
- `git show <baseline-commit>:<path>` or equivalent line-count comparison commands for reporting shrinkage honestly

## Plan Change Log

- 2026-06-11: Worklog bootstrapped automatically by Codex hook.
- 2026-06-11: Plan updated for a two-phase execution sequence: minimal gate/source-map checkpoint commit first, then runtime-separation surgery and harness hardening.
- 2026-06-11: Plan narrowed again for the next refactor wave: extract reward-board layout policy from `MainViewRuntime.gd` with test-first coverage.
- 2026-06-11: Plan narrowed once more to finish the current `MainViewRuntime.gd` helper-extraction wave and prepare a concrete line-count reduction report.
- 2026-06-11: Plan updated again for the next pass: extract page-scene model projection plus app-shell layout policy and document the remaining route to low-hundreds ownership.
- 2026-06-11: Plan updated for the next pass: extract the reward-card cloud runtime and make pre-edit request analysis enforce responsibility-unit decomposition for monitored runtime owners.
- 2026-06-11: Reward-card cloud extraction, source-map updates, and pre-edit runtime-owner responsibility gating were implemented and verified on the current workspace.
