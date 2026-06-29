# Agent Harness Integration

## Two-Layer Design

Looting The Leviathan uses a two-layer agent harness model:

1. Generic harness: `D:/Programming/ex_workspace/agent-harness`
2. Project integration: this repository's `.agent-harness.json` and `tools/agent-worklog.ps1`

The generic harness owns reusable logic. This project owns paths, validation commands, Godot/manual-check policy, and the shared worklog contract.

## Current Automated Commands

Run from the project root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/agent-worklog.ps1 -Mode inspect
powershell -NoProfile -ExecutionPolicy Bypass -File tools/agent-worklog.ps1 -Mode token-report
powershell -NoProfile -ExecutionPolicy Bypass -File tools/agent-worklog.ps1 -Mode summarize-worklogs
powershell -NoProfile -ExecutionPolicy Bypass -File tools/agent-worklog.ps1 -Mode validate
powershell -NoProfile -ExecutionPolicy Bypass -File tools/agent-worklog.ps1 -Mode new-log -Task "short task" -Agent hermes -DryRun
```

At this stage the wrapper already automates summary generation and shared closeout templating. `ACTIVE.md` is now part of the canonical contract even before dedicated start/update/finish commands are added.

## Canonical Shared Read Order

1. `docs/agent-worklog/ACTIVE.md`
2. `docs/agent-worklog/INDEX.md`
3. `docs/agent-worklog/COMPACT.md`
4. Relevant shared closeout docs under `docs/agent-worklog/YYYY-MM-DD-<agent>-<slug>.md`
5. Relevant raw evidence under `docs/codex-worklog/` only when needed
6. Task-specific source/docs files

## Canonical Write Model

- Shared live status: `docs/agent-worklog/ACTIVE.md`
- Shared closeouts / handoffs: `docs/agent-worklog/YYYY-MM-DD-<agent>-<slug>.md`
- Raw Codex evidence: `docs/codex-worklog/plan_*`, `history_*`, `complete_*`
- Generated summaries: `docs/agent-worklog/INDEX.md`, `docs/agent-worklog/COMPACT.md`

The shared layer is the default collaboration surface. Raw Codex logs remain evidence, not the default prompt context.

## ACTIVE.md Contract

`docs/agent-worklog/ACTIVE.md` is the shared live handoff file.

Use one block per concurrent source/session. Each block should contain:

- `work_unit`
- `agent`
- `source`
- `status` (`active`, `handoff-needed`, `blocked`)
- `started_at`
- `updated_at`
- `objective_ids`
- `raw_refs`
- `Current Goal`
- `Current Scope`
- `Files In Play`
- `Next Intended Step`
- `Validation Pending`
- `Notes For Next Agent`

Until dedicated automation lands, update `ACTIVE.md` manually or through project-local wrappers. Do not treat IDE-local AppData history as the shared live source of truth.

## Shared Closeout Contract

Every non-trivial agent task should end with a shared closeout using `docs/templates/agent-worklog-template.md`.

Required metadata fields:

- `agent`
- `source`
- `work_unit_id`
- `objective_ids`
- `status_at_closeout` (`done`, `partial`, `blocked`, `handoff`)
- `raw_refs`

Required sections:

- Goal
- Context Read
- Files Changed
- Decisions
- Validation
- Failures / Root Cause
- Follow-ups
- Compact Summary

If source-specific raw evidence exists, link it in `raw_refs` instead of duplicating the entire transcript in the shared closeout.

## Validation Policy

- Use `tools/run-compile-check.ps1` for fast LTL harness checks when Godot is available.
- Use `tools/run-ltl-quality-gate.ps1` for broader verification when the task warrants it.
- If Godot/windowed checks cannot run, record the reason and the smallest alternative validation in the worklog.

## Closeout Policy

- When work is still in progress, update `ACTIVE.md` instead of writing a premature completion log.
- When work ends or hands off, create/update the shared closeout and ensure the compact summary is usable without opening the raw evidence.
- When raw Codex logs exist, keep them in `docs/codex-worklog/` and reference them from the shared layer.

## Source Map Freshness

- Validate source-map coverage/freshness with `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .`.
- After source/resource/test/harness/doc changes that are in source-map scope, refresh with `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh`.
- The gate records a source fingerprint, so already-mapped files changing without source-map refresh now fail validation.
