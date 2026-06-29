# Looting The Leviathan Agent Rules

## Context Loading

- Before non-trivial work, read `docs/project-goals/final-goal.html` for the project north star.
- Before choosing scope or claiming completion, read `docs/project-goals/work-objectives.html` and tie the work to at least one objective id.
- Start with `docs/agent-worklog/INDEX.md` and `docs/agent-worklog/COMPACT.md` for historical context.
- Do not read every raw file in `docs/codex-worklog/` unless the current task requires raw evidence.
- Use `docs/source-map.md` to locate owners before broad edits.

## Project Goals / Objectives

- Final goal SoT: `docs/project-goals/final-goal.html`.
- Live objective backlog: `docs/project-goals/work-objectives.html`.
- Objective wrapper: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/project-objectives.ps1 -Mode inspect`.
- Objective validation: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/project-objectives.ps1 -Mode validate`.
- Objective listing: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/project-objectives.ps1 -Mode list`.
- If a task reveals missing granularity, add or refine an objective rather than burying it only in a worklog.
- Mark an objective `completed` only after a test, harness gate, or explicit manual proof is recorded in that objective's log.
- Completion reports and compact worklogs should cite relevant objective ids.

## Harness

- Worklog/token wrapper: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/agent-worklog.ps1 -Mode inspect`.
- Goal/objective wrapper: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/project-objectives.ps1 -Mode inspect`.
- Token report: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/agent-worklog.ps1 -Mode token-report`.
- Refresh summaries: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/agent-worklog.ps1 -Mode summarize-worklogs`.
- Fast quality path when available: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`.

## Development

- For bugs, create or identify a tight feedback loop before fixing.
- For behavior changes, prefer meaningful RED evidence: behavior/contract failure, not existence-only stubs.
- Avoid generated/heavy folders such as `.godot`, `.godot-user`, `.tmp-*`, logs, and evidence outputs unless the task is explicitly about them.

## Validation

- Run the smallest applicable automated verification before declaring completion.
- If Godot/windowed checks cannot run, record why and provide the smallest alternative manual check.

## Worklog Closeout

- Non-trivial Hermes/Codex work should end with a compact summary, not a full transcript dump.
- Use `docs/templates/agent-worklog-template.md` for shared agent closeouts.
- Include goal, files changed, decisions, validation, failures/root cause, follow-ups, and compact summary.

## Git

- Do not commit or push unless the user explicitly asks.


## Source Map Freshness

- Validate source-map coverage/freshness with `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root .`.
- After source/resource/test/harness/doc changes that are in source-map scope, refresh with `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh`.
- The gate records a source fingerprint, so already-mapped files changing without source-map refresh now fail validation.
