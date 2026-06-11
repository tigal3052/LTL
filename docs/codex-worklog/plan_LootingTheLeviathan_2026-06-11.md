# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-11

## Active Work

- Continue the `MainViewRuntime.gd` owner split by extracting the shared-backpack dock and deferred reparent coordination into its own execution-responsibility helper.

## Request Summary

- Continue the current runtime-view refactor wave after the reward-board, page-registry, popup-overlay, page-model, app-shell policy, and reward-card-cloud extractions.
- Reduce `MainViewRuntime.gd` further by moving shared backpack docking, node-select host sizing, reward host docking, and deferred reparent follow-up behavior into a dedicated runtime helper.
- Keep the new pre-edit harness requirement active while applying it to the next monitored runtime-owner split.
- Report which files shrank and which implementation-stage checks now prevent owner-growth regressions.

## Scope

- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/*.gd`
- `app-LTL/src/ui/presenters/*.gd`
- `app-LTL/tests/ui_read_models/*.gd`
- `app-LTL/tests/test_ui_read_models.gd`
- `docs/request-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md`
- `docs/codex-worklog/*.md`
- `LTL-harness/tools/request-analysis-gate.ps1`
- `LTL-harness/tools/request-analysis-gate.tests.ps1`
- `LTL-harness/docs/request-analysis-execution-gate.md`
- `LTL-harness/docs/templates/request-constraint-ledger-template.md`
- `LTL-harness/00_AGENTS.md`
- any source-map updates required by the extracted helper or new focused test file

## Out of Scope

- Prototype archive rewrites under `app-LTL/prototype/**`
- `MainControllerRuntime.gd` flow extraction in this pass
- node-map/page-host rewiring outside the shared-backpack host coordination surface
- unrelated gameplay design changes

## Steps

1. Re-read the current runtime-owner separation plan and identify the next live execution unit inside `MainViewRuntime.gd`.
2. Update the request ledger for the shared-backpack host split and rerun the pre-edit request-analysis gate.
3. Add failing focused tests for the new shared-backpack host coordinator helper.
4. Extract node-select dock, reward dock, shared-layout sync, and deferred reparent follow-up behavior into a dedicated helper file and delegate `MainViewRuntime.gd` to it without changing behavior.
5. Re-run focused UI tests plus compile/quality verification, then calculate before/after line counts and note the next remaining owner slices.

## Expected Outputs

- A smaller `MainViewRuntime.gd` with shared backpack docking and deferred reparent orchestration delegated out to a focused helper.
- Focused test surfaces that prove the extracted helper behavior before integration.
- Updated worklog notes that capture what part of the owner split is complete and what still remains.
- A before/after line-count summary for each file that shrank during this refactor wave.

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-11-m6-gate-fix-runtime-surgery.md -Mode pre-edit`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.tests.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -GodotPath D:\Programming\godot_workspace\bin\Godot_v4.3-stable_win64_console.exe`
- `git show <baseline-commit>:<path>` or equivalent line-count comparison commands for reporting shrinkage honestly

## Plan Change Log

- 2026-06-11: Worklog bootstrapped automatically by Codex hook.
- 2026-06-11: Plan updated for a two-phase execution sequence: minimal gate/source-map checkpoint commit first, then runtime-separation surgery and harness hardening.
- 2026-06-11: Plan narrowed again for the next refactor wave: extract reward-board layout policy from `MainViewRuntime.gd` with test-first coverage.
- 2026-06-11: Plan narrowed once more to finish the current `MainViewRuntime.gd` helper-extraction wave and prepare a concrete line-count reduction report.
- 2026-06-11: Plan updated again for the next pass: extract page-scene model projection plus app-shell layout policy and document the remaining route to low-hundreds ownership.
- 2026-06-11: Plan updated for the next pass: extract the reward-card cloud runtime and make pre-edit request analysis enforce responsibility-unit decomposition for monitored runtime owners.
- 2026-06-11: Reward-card cloud extraction, source-map updates, and pre-edit runtime-owner responsibility gating were implemented and verified on the current workspace.
- 2026-06-11: Plan updated again for the next pass: extract shared backpack docking and deferred reparent coordination from `MainViewRuntime.gd`.
