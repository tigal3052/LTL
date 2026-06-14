# Request Constraint Ledger

## Request Summary

- Harden the harness so non-trivial requests cannot pass by planning or validating a symptom-only workaround instead of a root-cause fix.
- Apply the safeguard to the real request-analysis and verification path rather than leaving it as team guidance only.

## Preserved Invariants

- Existing dirty-worktree user changes stay untouched and are not reverted.
- Request-analysis, transition-safety, source-map, compile-check, and quality-gate entrypoints remain the active harness path.
- The new safeguard must stay general-purpose and must not special-case only `disabled` button styling.

## Mutable Scope

- `LTL-harness/00_AGENTS.md`
- `LTL-harness/docs/request-analysis-execution-gate.md`
- `LTL-harness/docs/templates/request-constraint-ledger-template.md`
- `LTL-harness/tools/request-analysis-gate.ps1`
- `LTL-harness/tools/request-analysis-gate.tests.ps1`
- `tools/run-compile-check.ps1`
- `docs/source-map.md`
- `docs/request-ledgers/2026-06-13-root-cause-anti-workaround-gate.md`
- `docs/codex-worklog/plan_LootingTheLeviathan_2026-06-13.md`
- `docs/codex-worklog/history_LootingTheLeviathan_2026-06-13.md`
- `docs/codex-worklog/complete_LootingTheLeviathan_2026-06-13.md`

## Source Map Findings

- `LTL-harness/tools/request-analysis-gate.ps1`
  - The live source map already names this file as the validator for request ledgers before broad edits and before completion, so it is the primary enforcement point.
- `LTL-harness/tools/request-analysis-gate.tests.ps1`
  - The live source map already names the self-test file, so RED/GREEN harness coverage belongs here instead of in a new ad hoc script.
- `tools/run-compile-check.ps1`
  - The live source map names compile-check as the fast local verification entrypoint, so broad anti-workaround enforcement should also reach this path.
- `docs/source-map.md`
  - End-to-end verification is currently blocked until the live map includes the active June 12-13 mockup review artifacts and this new request ledger.
- `LTL-harness/docs/templates/request-constraint-ledger-template.md`
  - The request-source-map helper returned no direct map entry for the ledger template, so the template is being updated as a manually traced companion to the mapped gate/document files.

## Root Cause Review

- Observed symptom: past requests can technically pass by masking a visible symptom inside presentation code even when the real state, ownership, or sequencing bug remains unresolved.
- Evidence: the current harness validates mutable scope, transition notes, and verification lists, but it does not yet require the request ledger to explain why the chosen change is a source-level fix instead of a cosmetic bypass.
- Root cause target: `LTL-harness/tools/request-analysis-gate.ps1`
- Rejected workaround: adding one more style-only or wording-only guideline without blocking verification would still allow symptom masking to pass as long as tests or screenshots look superficially acceptable.
- Chosen fix: require root-cause reasoning and completion-side resolution proof inside the ledger schema that the existing harness already blocks on.

## Transition Safety Review

- no transition impact
- entry owner: none
- exit owner: none
- shared handoff risks: this request changes harness policy and verification flow, not a runtime phase or page transition boundary
- runner path: `none`
- expected marker: `no transition impact`

## Refactor/Delete Disposition

- Keep the existing request-analysis gate and strengthen it instead of creating a parallel anti-workaround validator.
- Keep compile-check and quality-gate as the active verification entrypoints; extend them rather than replacing them.
- Do not delete existing request-ledger structure sections that are still useful for scope and transition analysis.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.tests.ps1` before implementation to confirm the new RED fixtures fail on the old gate.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.tests.ps1` after implementation and confirm `REQUEST_ANALYSIS_GATE_TESTS_OK`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-13-root-cause-anti-workaround-gate.md -Mode pre-edit`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-13-root-cause-anti-workaround-gate.md`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-13-root-cause-anti-workaround-gate.md -ArtifactLedger docs/artifact-ledgers/2026-06-13-root-cause-anti-workaround-gate.md`.

## Verification Notes

- Focused harness proof:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.tests.ps1` -> `REQUEST_ANALYSIS_GATE_TESTS_OK`
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-13-root-cause-anti-workaround-gate.md -Mode pre-edit` -> `REQUEST_ANALYSIS_GATE_OK`
- Source-map proof:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .` -> `SOURCE_MAP_GATE_OK`
- Fast-path guard proof:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1 -RequestLedger docs/request-ledgers/2026-06-13-root-cause-anti-workaround-gate.md` initially failed with `REQUEST_ANALYSIS_GATE_FAIL: Resolution Proof cannot stay unresolved at pre-complete time`, proving the strengthened compile-check path blocks incomplete anti-workaround evidence before deeper checks run.
  - After the ledger was updated with concrete proof, the same compile-check path passed `REQUEST_ANALYSIS_GATE_OK` and advanced to the next unrelated blocker (`TEST_SIZE_GATE_FAIL`).
- Full quality-gate integration proof:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-ltl-quality-gate.ps1 -RequestLedger docs/request-ledgers/2026-06-13-root-cause-anti-workaround-gate.md -ArtifactLedger docs/artifact-ledgers/2026-06-13-root-cause-anti-workaround-gate.md` passed `REQUEST_ANALYSIS_GATE_OK`, `REQUEST_ANALYSIS_GATE_TESTS_OK`, `REQUEST_SOURCE_MAP_TESTS_OK`, `SOURCE_MAP_GATE_OK`, and `SOURCE_MAP_GATE_TESTS_OK` before stopping at the same pre-existing test-size blocker.

## Resolution Proof

- RED proof: before implementation, `LTL-harness/tools/request-analysis-gate.tests.ps1` failed because a ledger without `Root Cause Review` still passed pre-edit, which proved the old gate was not enforcing source-level reasoning.
- Root-cause proof: after implementation, `REQUEST_ANALYSIS_GATE_TESTS_OK`, a real `REQUEST_ANALYSIS_GATE_OK` pre-edit run on this ledger, and request-analysis success inside both compile-check and the full quality gate prove that the harness now requires root-cause review structure instead of only scope and verification lists.
- Workaround guard: the fast compile-check path now halts on incomplete `Resolution Proof`, and only continues once concrete anti-workaround evidence replaces unresolved draft text.

## Artifact Ledger

- Quality-gate artifact output will be written to `docs/artifact-ledgers/2026-06-13-root-cause-anti-workaround-gate.md`.
