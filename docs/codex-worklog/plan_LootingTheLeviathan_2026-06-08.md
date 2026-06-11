# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-08

## Active Work

Split oversized formal Godot test sources into smaller leaf suites and add a harness gate that keeps test files small over time.

## Request Summary

The user noticed that test-related source files have grown past the harness expectation, including one file already above 900 lines and one above 2200 lines.

Requested outcomes:

- restructure the formal test source so large suites can be split once they pass a reasonable size
- shrink the current oversized suite into smaller files that are easier to maintain
- add a harness gate so test source size is managed continuously instead of drifting again
- prefer the smallest practical test units rather than only splitting to a barely acceptable size

## Scope

- `app-LTL/tests/test_ui_read_models.gd`
- new leaf suites under `app-LTL/tests/ui_read_models/`
- shared test helper support under `app-LTL/tests/support/`
- new harness gate scripts under `LTL-harness/tools/`
- quality-gate wiring in `tools/run-compile-check.ps1` and `tools/run-ltl-quality-gate.ps1`
- harness/docs/source-map/worklog updates required by the new gate and file moves

## Out Of Scope

- rewriting unrelated production runtime logic
- splitting every existing legacy large test file in one pass
- turning pre-existing unrelated broad-suite failures into part of this task's acceptance criteria

## Steps

- create a request ledger and refresh today's worklog around the test-size refactor scope
- extract a shared base test suite/helper so leaf suites can stay small without duplicating setup and assertions
- split `test_ui_read_models.gd` into topic-based leaf suites while preserving the existing public runner surface
- add a dedicated `test-size-gate` plus self-tests
- wire the new gate into the compile and consolidated quality-gate scripts
- update harness docs and source-map responsibilities
- run focused gate and Godot verification, then record exact outcomes

## Expected Outputs

- `app-LTL/tests/test_ui_read_models.gd` becomes a thin aggregator instead of a 2000+ line monolith
- new leaf suites stay in the small-file range and are individually responsibility-focused
- the harness can block future growth on the split suite surface and warn on remaining legacy test-size debt
- existing runners such as `run_test_ui_read_models.gd`, `run_reward_ceremony_contract.gd`, `run_reward_inspector_stability_contract.gd`, and `run_defeat_page_contract.gd` keep their current public contract

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File 'LTL-harness/tools/request-analysis-gate.ps1' -Ledger 'docs/request-ledgers/2026-06-08-test-suite-size-gate.md' -Mode pre-edit`
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'LTL-harness/tools/test-size-gate.tests.ps1'`
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'LTL-harness/tools/test-size-gate.ps1' -Root 'D:\Programming\ex_workspace\LootingTheLeviathan'`
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_inspector_stability_contract.gd'`
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_defeat_page_contract.gd'`
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_reward_ceremony_contract.gd'`
- `powershell -NoProfile -ExecutionPolicy Bypass -File 'tools/invoke-godot.ps1' -ProjectPath 'app-LTL' -Headless -Script 'tests/run_test_ui_read_models.gd'`

## Plan Change Log

- 2026-06-08: Replaced the stale reward-board follow-up plan entry with the active oversized-test split plus test-size harness-gate work after the user requested smaller test-unit management.
- 2026-06-08: Chose the dedicated test-structure plus dedicated gate approach so the current split and future enforcement live under one repeatable workflow.
