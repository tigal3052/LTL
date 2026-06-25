# Agent Harness Integration

## Two-Layer Design

Looting The Leviathan now uses a two-layer agent harness model:

1. Generic harness: `D:/Programming/ex_workspace/agent-harness`
2. Project integration: this repository's `.agent-harness.json` and `tools/agent-worklog.ps1`

The generic harness owns reusable logic. This project owns paths, validation commands, Godot/manual-check policy, and worklog summary outputs.

## Worklog Commands

Run from the project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/agent-worklog.ps1 -Mode inspect
powershell -NoProfile -ExecutionPolicy Bypass -File tools/agent-worklog.ps1 -Mode token-report
powershell -NoProfile -ExecutionPolicy Bypass -File tools/agent-worklog.ps1 -Mode summarize-worklogs
powershell -NoProfile -ExecutionPolicy Bypass -File tools/agent-worklog.ps1 -Mode validate
powershell -NoProfile -ExecutionPolicy Bypass -File tools/agent-worklog.ps1 -Mode new-log -Task "short task" -Agent hermes -DryRun
```

## Context Loading Order

1. `docs/agent-worklog/INDEX.md`
2. `docs/agent-worklog/COMPACT.md`
3. Relevant raw logs under `docs/codex-worklog/` only when needed
4. Task-specific source/docs files

## Validation Policy

- Use `tools/run-compile-check.ps1` for fast LTL harness checks when Godot is available.
- Use `tools/run-ltl-quality-gate.ps1` for broader verification when the task warrants it.
- If Godot/windowed checks cannot run, record the reason and the smallest alternative validation in the worklog.

## Closeout Policy

Every non-trivial agent task should end with a compact summary containing:

- Goal
- Files changed
- Decisions
- Validation
- Failures/root cause
- Follow-ups


## Source Map Freshness

- Validate source-map coverage/freshness with `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .`.
- After source/resource/test/harness/doc changes that are in source-map scope, refresh with `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh`.
- The gate records a source fingerprint, so already-mapped files changing without source-map refresh now fail validation.
