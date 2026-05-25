# Strict Implementation Gate Analysis

date: 2026-05-22
task: strict-implementation-gate-hardening

## Cause

- The implementation rule existed in prose, but the gate did not parse the ledger as machine-readable fields.
- `Assert-LedgerPhase` used substring matching, so `next_phase: implementation-approved` inside an `execution-only` ledger was enough to satisfy implementation approval.
- The gate only checked whether a code line's previous meaningful line contained `실행:`.
- That check did not model the intended block rule: one non-empty execution sentence directly guards one contiguous code block.
- The implementation workflow did not require a post-code `implementation` gate run before declaring completion, so the mismatch was reported only after manual inspection.

## Fix

- `LTL-harness/tools/comment-first-gate.ps1` now parses the top-level `phase:` scalar exactly.
- `next_phase:` is no longer accepted as current approval.
- `implementation` mode now requires `phase: implementation-approved`.
- Implementation guards must be non-empty execution comments, such as `# 실행: normalize the raw fixture dictionary`.
- Header-only markers such as `# 실행:` do not guard code.
- Each guard must be followed directly by code and covers exactly one contiguous code block.
- After the guarded code block ends, a later code block requires a new guard.

## Enforcement Checks

- Current M0/M1 source with the `execution-only` ledger fails `implementation` mode because the ledger phase is still `execution-only`.
- A header-only execution fixture fails `implementation` mode because the code block is not directly guarded by a non-empty execution sentence.
- A positive fixture with one non-empty execution guard and one code block passes `implementation` mode.
- The generic `D:/Programming/ex_workspace/agent-harness` gate script was updated with the same strict parser and block rule.

## Remaining Action

- The current M0/M1 implementation should either be refactored into `# 실행: ... -> code block` pairs or moved behind helper functions that each have their own concrete execution guard.
- A separate `implementation-approved` ledger should be created only when that refactor is ready to be validated.
