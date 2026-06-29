# 2026-06-27 Project Goal and Objective Process

## Agent

- agent: hermes
- source: tui

## Goal

- Extract LTL's final goal, create durable goal/objective HTML artifacts, wire every future LTL task to those artifacts, and promote the same process into the generic agent harness.

## Context Read

- `docs/project-goals/final-goal.html`
- `docs/project-goals/work-objectives.html`
- `AGENTS.md`
- `.agent-harness.json`
- `docs/agent-worklog/INDEX.md`
- `docs/agent-worklog/COMPACT.md`
- `기획서v0.2.md`
- `구현기획서_Godot_TDD.md`
- `docs/request-ledgers/2026-06-26-energy-token-redesign.md`
- Generic harness `docs/project-objective-process.md`

## Files Changed

- `docs/project-goals/final-goal.html`: new north-star HTML for all LTL work.
- `docs/project-goals/work-objectives.html`: new live objective backlog grouped by priority and area.
- `.agent-harness.json`: added `project_objectives` config and objective validation command/manual checks.
- `AGENTS.md`: added read-before-work and objective update rules.
- `tools/project-objectives.ps1`: new LTL wrapper around the generic objective gate.
- `docs/source-map.md`: refreshed after new project-goal/config/wrapper/rules files.
- Generic harness files under `D:/Programming/ex_workspace/agent-harness`: added `tools/project-objective-gate.ps1`, tests, docs, templates, README/agent rules, and refreshed source map.

## Decisions

- Keep project-specific final-goal wording and LTL objective cards in LTL, while keeping parsing/validation/list/update mechanics in the generic harness.
- Use HTML `data-*` markers instead of a freeform markdown checklist so future agents can validate and update status mechanically.
- Mark LTL's process setup objectives complete only after objective validation and source-map verification passed.

## Validation

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/project-objective-gate.tests.ps1` in `D:/Programming/ex_workspace/agent-harness` -> `PROJECT_OBJECTIVE_GATE_TESTS_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/project-objectives.ps1 -Mode validate` in LTL -> `PROJECT_OBJECTIVE_GATE_VALIDATE_OK` with 19 objectives.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/project-objectives.ps1 -Mode inspect` in LTL -> 19 objectives, 3 completed, 14 pending, 2 deferred.
- `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/source-map-gate.ps1 -Root . -Refresh` in LTL -> `SOURCE_MAP_REFRESH_OK`, `SOURCE_MAP_GATE_OK`.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/source-map-gate.ps1 -Root . -Refresh` in generic harness -> `SOURCE_MAP_REFRESH_OK`, `SOURCE_MAP_GATE_OK`.
- Follow-up normal source-map checks for both repos -> `SOURCE_MAP_GATE_OK`.

## Failures / Root Cause

- Initial PowerShell generic gate implementation had here-string escaping and generic-list return pitfalls. Fixed by using plain HTML quotes, simpler regexes, returning `$items.ToArray()`, and array-wrapping at call sites.
- Initial LTL wrapper built paired arguments in a way PowerShell flattened into invalid parameter names such as `Priority medium`. Fixed by appending each parameter explicitly.

## Follow-ups

- Future feature work should cite one or more objective ids from `docs/project-goals/work-objectives.html`.
- As implementation reveals more detail, split broad pending objectives into smaller cards and complete them only with validation/manual-proof notes.

## Compact Summary

- Added LTL final-goal and work-objective HTML artifacts under `docs/project-goals/`, with 19 machine-readable objective cards.
- Wired LTL `.agent-harness.json`, `AGENTS.md`, and `tools/project-objectives.ps1` so future work reads and validates objective artifacts.
- Promoted a generic `project-objective-gate.ps1` process into `agent-harness` with docs, templates, tests, README/agent-rule references, and source-map refresh.
- Verified generic objective tests, LTL objective validation/inspect, and both LTL/generic source-map gates.
