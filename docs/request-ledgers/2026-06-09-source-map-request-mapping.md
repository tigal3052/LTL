# Request Constraint Ledger

## Request Summary

- Review whether `docs/source-map.md` is only being generated/validated by harness gates or is also used while analyzing a user request and locating related source files.
- If that usage is missing, wire the harness so request handling can use the source map as a practical source-discovery aid instead of a passive documentation artifact.

## Preserved Invariants

- `docs/source-map.md` remains the live repository-wide file map unless a harness-level decision explicitly replaces that single source of truth.
- Existing source-map verification behavior for missing files, stale files, and placeholder responsibilities remains blocking.
- Request ledgers continue to describe preserved invariants, mutable scope, and verification evidence before harness work is considered complete.

## Mutable Scope

- `LTL-harness/tools/request-analysis-gate.ps1`
- `LTL-harness/tools/request-analysis-gate.tests.ps1`
- new source-map request helper scripts under `LTL-harness/tools/`
- `LTL-harness/docs/request-analysis-execution-gate.md`
- `LTL-harness/docs/templates/request-constraint-ledger-template.md`
- `LTL-harness/00_AGENTS.md`
- `LTL-harness/README.md`
- `docs/source-map.md`
- this request ledger
- today's worklog files

## Source Map Findings

- `docs/source-map.md`
  - The current source map describes itself as the live implementation map for AI agents, but the surrounding harness only enforces completeness and responsibility text quality.
- `LTL-harness/tools/source-map-gate.ps1`
  - The gate validates and bootstraps the file map, but it does not help request-analysis flows find candidate files for a new task.
- `LTL-harness/tools/request-analysis-gate.ps1`
  - The request-analysis gate currently checks only for ledger section presence and does not require any explicit source-map review evidence.
- `LTL-harness/docs/request-analysis-execution-gate.md`
  - The request-analysis source-of-truth document does not currently define a required source-map lookup stage before mutable scope is declared.
- `LTL-harness/docs/templates/request-constraint-ledger-template.md`
  - The template has no dedicated section for recording source-map-driven candidate files or responsibilities.
- `LTL-harness/00_AGENTS.md`
  - Agent instructions mention the source map as a gate addendum, but not as a request-triage input for mapping relevant source quickly.
- `LTL-harness/README.md`
  - README guidance frames the source map as maintenance and verification material rather than a practical request-analysis tool.

## Refactor/Delete Disposition

- Keep `docs/source-map.md` as the live file-map source of truth unless the implementation review proves that its current repository-level location blocks harness usage.
- Refactor request-analysis guidance and validation so source-map review becomes an explicit part of request handling.
- Add a focused helper tool rather than replacing the existing source-map gate.
- Do not delete existing gate scripts or quality-gate steps; any new source-map request flow must be additive.

## Verification Checklist

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-09-source-map-request-mapping.md -Mode pre-edit`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-source-map.tests.ps1`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.tests.ps1`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-source-map.ps1 -MapPath docs/source-map.md -Keyword source-map -MaxResults 10`
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-09-source-map-request-mapping.md -Mode pre-complete -RequireArtifactLedger`

## Verification Notes

- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-09-source-map-request-mapping.md -Mode pre-edit` -> `REQUEST_ANALYSIS_GATE_OK`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.tests.ps1` -> `REQUEST_ANALYSIS_GATE_TESTS_OK`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-source-map.tests.ps1` -> `REQUEST_SOURCE_MAP_TESTS_OK`
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-source-map.ps1 -MapPath docs/source-map.md -Keyword source-map -MaxResults 10` -> returned mapped request-analysis and source-map helper candidates from the live file map.
- Passed: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/request-analysis-gate.ps1 -Ledger docs/request-ledgers/2026-06-09-source-map-request-mapping.md -Mode pre-complete -RequireArtifactLedger` -> `REQUEST_ANALYSIS_GATE_OK`
- Checked: `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .` is currently blocked by pre-existing source-map drift in unrelated user work, including newly added defeat art, i18n data, page files, and test runners that are not yet mapped in `docs/source-map.md`.

## Artifact Ledger

- Verification command output and any generated notes for this harness update will be referenced from `docs/artifact-ledgers/2026-06-09-source-map-request-mapping.md`.
