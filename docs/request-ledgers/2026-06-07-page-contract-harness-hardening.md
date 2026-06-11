# Request Constraint Ledger

## Request Summary

- Harden the harness so mockup-backed runtime pages cannot drift from the approved contract without a blocking gate failure.

## Preserved Invariants

- The M6 page order and existing page ids remain the active runtime sequence.
- The battle and reward gameplay layout contracts remain enforced by the existing layout and Godot contract suites.
- Source-map, tech-stack, i18n, and architectural gates remain part of the quality pipeline.

## Mutable Scope

- `LTL-harness/00_AGENTS.md`
- `LTL-harness/docs/page-contract-execution-gate.md`
- `LTL-harness/tools/page-contract-gate.ps1`
- `LTL-harness/tools/page-contract-gate.tests.ps1`
- `tools/run-compile-check.ps1`
- `tools/run-ltl-quality-gate.ps1`
- page-contract runner success-marker behavior in `app-LTL/tests/run_main_start_flow_contract.gd` and `app-LTL/tests/run_main_layout_audit_contract.gd`
- worklog and source-map updates required by the harness change

## Source Map Findings

- `docs/source-map.md`
  - The live map already tracks the page-contract gate, the runtime runners, and the harness entry docs, which keeps this hardening pass inside named formal files.
- `LTL-harness/tools/page-contract-gate.ps1`
  - The blocking page-contract verification suite is the main enforcement target for this request.
- `tools/run-compile-check.ps1`
  - The fast local verification path is already mapped as the blocking place where source-map and page-contract checks join.
- `app-LTL/tests/run_page_scene_mapping_contract.gd`
  - The scene-mapping contract runner is a mapped verification surface that must stay additive rather than replaced.

## Refactor/Delete Disposition

- Keep the existing page-scene mapping, flow, layout, and UI read-model runners; extend the harness around them instead of replacing them.
- Do not remove the existing compile/source-map gate path; the page-contract gate must be additive and blocking.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/page-contract-gate.tests.ps1`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/page-contract-gate.ps1 -Root D:\Programming\ex_workspace\LootingTheLeviathan`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-07-page-contract-harness-hardening.md -ArtifactLedger docs/artifact-ledgers/2026-06-07-page-contract-harness-hardening.md`

## Verification Notes

- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/page-contract-gate.tests.ps1` -> `PAGE_CONTRACT_GATE_TESTS_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/page-contract-gate.ps1 -Root D:\Programming\ex_workspace\LootingTheLeviathan` -> `PAGE_CONTRACT_GATE_OK`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1` -> `SOURCE_MAP_GATE_OK`, `PAGE_CONTRACT_GATE_OK`, `GODOT_CONTRACTS_OK`, `Compilation Check: PASSED (GODOT_CONTRACTS_OK)`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-07-page-contract-harness-hardening.md -ArtifactLedger docs/artifact-ledgers/2026-06-07-page-contract-harness-hardening.md` -> blocked by the pre-existing `warning-refactor-gate` finding `PanelContainer.new` in `app-LTL/src/ui/StatusPanelUI.gd`, after `REQUEST_ANALYSIS_GATE_OK`, `SOURCE_MAP_GATE_OK`, `LTL_TECH_STACK_GATE_OK`, and `I18N_TEXT_GATE_OK`

## Artifact Ledger

- Generated gate logs should be captured by the quality-gate artifact ledger at `docs/artifact-ledgers/2026-06-07-page-contract-harness-hardening.md`.
