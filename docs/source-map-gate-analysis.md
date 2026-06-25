# Source Map Gate Analysis

## Problem

The LTL source-map gate was already wired into `tools/run-compile-check.ps1` and `tools/run-ltl-quality-gate.ps1`, but it did not fully enforce "source-map refreshed after source changes".

## Root Cause

The previous `LTL-harness/tools/source-map-gate.ps1` checked only three structural conditions:

1. every non-excluded file exists in `docs/source-map.md`,
2. every mapped file still exists,
3. every mapped entry has a non-empty ASCII responsibility comment.

That caught newly added unmapped files, but it did **not** catch the case where an already mapped source file changed and `docs/source-map.md` was not refreshed. In other words, the gate validated source-map membership, not freshness.

The previous failure message also used confusing wording: `missing mapped files` actually meant files present in the repository but missing from the map. The updated gate reports these as `unmapped source files`.

## Fix

The gate now records and verifies a source fingerprint in `docs/source-map.md`:

- The fingerprint is a SHA-256 digest over all non-excluded files except `docs/source-map.md` itself.
- It includes each candidate file path, size, and content hash.
- If any mapped source/resource/test/doc file changes without refreshing the map, validation fails with a freshness/fingerprint error.
- `-Refresh` preserves existing valid responsibility comments, adds new entries, removes excluded/stale entries, and updates the fingerprint.

## Updated Commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .
powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh
powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.tests.ps1
```

## Cleanup Scope

The refreshed gate excludes generated/process evidence from source-map enforcement:

- `docs/agent-worklog/`
- `docs/artifact-ledgers/`
- `docs/codex-worklog/`
- `docs/comment-gates/backups/`
- `docs/evidence/`
- `docs/request-ledgers/`
- `docs/superpowers/plans/`

These remain useful records when intentionally kept, but they are not live implementation files and should not block source-map freshness.

## Verification

The self-test now includes a regression case where an already mapped file changes after bootstrap. The gate must fail until `-Refresh` is run.
