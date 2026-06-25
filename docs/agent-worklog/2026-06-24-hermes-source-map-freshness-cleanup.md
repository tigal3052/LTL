# 2026-06-24 Hermes Source Map Freshness Cleanup

## Agent

- agent: hermes
- source: tui

## Goal

- Clean LTL source-map drift, analyze why source-map refresh was not enforced, and harden LTL/generic harness gates.

## Context Read

- `AGENTS.md`
- `docs/agent-worklog/INDEX.md`
- `docs/agent-worklog/COMPACT.md`
- `LTL-harness/tools/source-map-gate.ps1`
- `LTL-harness/tools/source-map-gate.tests.ps1`

## Files Changed

- `LTL-harness/tools/source-map-gate.ps1`: added `-Refresh`, source fingerprint generation, fingerprint validation, clearer unmapped/stale failure wording, and generated/process artifact exclusions.
- `LTL-harness/tools/source-map-gate.tests.ps1`: added regression coverage for already-mapped source changes that require source-map refresh.
- `docs/source-map.md`: refreshed map, removed generated/process records from enforcement scope, added source fingerprint, and added currently relevant source/resource/test entries.
- `docs/source-map-gate-analysis.md`: recorded root cause and verification notes.
- `AGENTS.md`, `LTL-harness/00_AGENTS.md`, `docs/agent-harness.md`: documented source-map freshness refresh commands.
- `D:/Programming/ex_workspace/agent-harness/tools/source-map-gate.ps1`: applied the same generic `-Refresh`/fingerprint hardening.
- `D:/Programming/ex_workspace/agent-harness/tools/source-map-gate.tests.ps1`: added generic freshness regression coverage.
- `D:/Programming/ex_workspace/agent-harness/docs/source-map.md`: refreshed generic harness source-map with fingerprint.

## Decisions

- Stale mapped entries were actually zero; the gate failure was caused by unmapped current files plus missing freshness enforcement.
- Generated/process evidence paths are excluded from source-map scope rather than mapped as live implementation.
- Obvious non-operational generated artifacts were deleted; operational source/resources/tests/worklogs were preserved.

## Validation

- `LTL-harness/tools/source-map-gate.ps1 -Root .` -> `SOURCE_MAP_GATE_OK`
- `LTL-harness/tools/source-map-gate.tests.ps1` -> `SOURCE_MAP_GATE_TESTS_OK`
- `tools/agent-worklog.ps1 -Mode validate` -> `WORKLOG_TOKEN_GATE_VALIDATE_OK`
- `agent-harness/tools/source-map-gate.ps1 -Root .` -> `SOURCE_MAP_GATE_OK`
- `agent-harness/tools/source-map-gate.tests.ps1` -> `SOURCE_MAP_GATE_TESTS_OK`
- `agent-harness/tools/worklog-token-gate.tests.ps1` -> `WORKLOG_TOKEN_GATE_TESTS_OK`

## Failures / Root Cause

- Previous source-map gate validated set membership and responsibility text but did not fingerprint source contents, so already-mapped source changes could pass without refreshing `docs/source-map.md`.
- Previous failure wording said `missing mapped files`; the actual condition was unmapped existing files.

## Follow-ups

- Review the remaining large uncommitted operational source/test/resource set before committing.
- Decide whether process records under `docs/request-ledgers` and `docs/superpowers/plans` should be kept as historical evidence or pruned separately.

## Compact Summary

- Source-map stale mapped entries were 0; the blocking issue was 41 unmapped current files and no freshness check for already-mapped source edits.
- LTL and generic source-map gates now support `-Refresh`, preserve existing responsibility comments, write a source fingerprint, and fail if source files change without map refresh.
- Deleted obvious non-operational generated artifacts: `.tmp-source-map-*`, `docs/comment-gates/backups/2026-06-24`, and two `docs/evidence/*` directories.
- Smoke tests passed for LTL source-map gate/tests, LTL worklog validate, generic source-map gate/tests, and generic worklog-token tests.
