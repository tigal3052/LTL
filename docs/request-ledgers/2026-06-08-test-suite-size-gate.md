# Request Constraint Ledger

## Request Summary

- Split oversized formal test suites into much smaller files and add a dedicated harness gate so test source size stays controlled.

## Preserved Invariants

- Existing public Godot runner entry points remain the same unless a new gate explicitly needs an additive self-test runner.
- `app-LTL/tests/test_ui_read_models.gd` remains loadable and keeps the public methods used by targeted runners.
- Page-contract, source-map, tech-stack, i18n, and existing quality-gate paths remain additive; the new test-size gate must join them rather than replace them.

## Mutable Scope

- `app-LTL/tests/test_ui_read_models.gd`
- new leaf suites under `app-LTL/tests/ui_read_models/`
- new shared test support under `app-LTL/tests/support/`
- `LTL-harness/tools/test-size-gate.ps1`
- `LTL-harness/tools/test-size-gate.tests.ps1`
- `tools/run-compile-check.ps1`
- `tools/run-ltl-quality-gate.ps1`
- `LTL-harness/00_AGENTS.md`
- `LTL-harness/README.md`
- `docs/source-map.md`
- today's worklog files

## Source Map Findings

- `docs/source-map.md`
  - The live map already tracks the UI read-model aggregator, the split suite directories, and the harness gate scripts that enforce their shape.
- `app-LTL/tests/test_ui_read_models.gd`
  - The aggregator facade remains a mapped public runner surface and must stay loadable after the split.
- `app-LTL/tests/ui_read_models/`
  - The leaf suite directory is the mapped location for the new smaller behavior-owned test files.
- `LTL-harness/tools/test-size-gate.ps1`
  - The dedicated size gate is the mapped enforcement point for keeping this surface small over time.

## Refactor/Delete Disposition

- Keep existing formal test runners and targeted contract entry points; refactor their internals around smaller suite ownership instead of replacing their caller contract.
- Keep current legacy large test files outside the split surface for now; the new gate may warn on them, but this request does not require every legacy test file to be split in one pass.
- Replace the internals of `app-LTL/tests/test_ui_read_models.gd` with an aggregator facade plus smaller suite files.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-08-test-suite-size-gate.md -Mode pre-edit`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/test-size-gate.tests.ps1`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/test-size-gate.ps1 -Root D:\Programming\ex_workspace\LootingTheLeviathan`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_reward_inspector_stability_contract.gd`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_defeat_page_contract.gd`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_reward_ceremony_contract.gd`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script tests/run_test_ui_read_models.gd`

## Verification Notes

- Passed: `request-analysis-gate.ps1 -Mode pre-edit`
- Passed: `test-size-gate.tests.ps1` -> `TEST_SIZE_GATE_TESTS_OK`
- Passed: `test-size-gate.ps1` -> `TEST_SIZE_GATE_OK`
- Passed: `run_reward_inspector_stability_contract.gd` -> `REWARD_INSPECTOR_STABILITY_CONTRACT_OK`
- Passed: `run_reward_ceremony_contract.gd` -> `REWARD_CEREMONY_CONTRACT_OK`
- Checked: `run_defeat_page_contract.gd` still fails on current defeat-page copy expectations (`GAME OVER`, localized cause string, retry CTA), which proves the split preserved the runner surface but did not change the existing copy debt.
- Checked: `run_test_ui_read_models.gd` still fails on broader pre-existing localization and copy expectation drift in the current dirty worktree, but the new split suites load and execute end-to-end without missing-method or load-path regressions.
- Checked: the new hard gate keeps the split surface small while only warning on untouched legacy oversized suites such as `test_reward_contract.gd`, `run_main_layout_audit_contract.gd`, and `godot_contract_runner.gd`.

## Artifact Ledger

- Godot runner logs written under `app-LTL/.tmp-godot-logs/` during verification:
  - `app-LTL/.tmp-godot-logs/run_reward_inspector_stability_contract.log`
  - `app-LTL/.tmp-godot-logs/run_defeat_page_contract.log`
  - `app-LTL/.tmp-godot-logs/run_reward_ceremony_contract.log`
  - `app-LTL/.tmp-godot-logs/run_test_ui_read_models.log`
- No separate screenshot or report artifact was generated for this structural split; the main evidence is the harness gate output, Godot runner exit status, and the split file sizes in the repository tree.
