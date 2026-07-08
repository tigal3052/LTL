# Agent Workflow Analysis

## Source

- Project: `D:/Programming/ex_workspace/LootingTheLeviathan`
- Historical raw Codex analysis date: `2026-06-24`
- Shared-layer decision update: `2026-06-29`
- Raw Codex worklogs: `docs/codex-worklog/`
- Shared worklog layer: `docs/agent-worklog/`
- Historical raw-log sample: `97` markdown logs, `2658389` characters (~`664598` estimated tokens), kind counts `{'complete': 32, 'history': 33, 'plan': 32}`

## Executive Summary

The Codex worklog practice is valuable because it preserves plan/history/complete evidence across many sessions. The main weakness is not lack of history; it is context cost and retrieval friction. Several `history_*` files are too large to load by default, and the old compact layer did not clearly represent current live work or non-Codex shared closeouts.

The updated decision is to keep `docs/codex-worklog/` as raw evidence while formalizing `docs/agent-worklog/` as the neutral shared layer:

- `ACTIVE.md` for live in-progress state
- `INDEX.md` for summary-first discovery
- `COMPACT.md` for concise recent patterns
- `YYYY-MM-DD-<agent>-<slug>.md` for shared closeout/handoff records

## Observed Strengths

- Work is recorded consistently across dated `plan_*`, `history_*`, and `complete_*` files.
- Completion logs often separate actual outputs, plan changes, verification results, blockers, and remaining gaps.
- The project already has strong harness culture: request ledgers, source maps, quality gates, artifact ledgers, Godot runner wrappers, and LTL-specific gate scripts.
- Verification evidence is frequently named explicitly with expected markers such as `*_OK`.
- The generic `agent-harness` already contains reusable gates for source maps, request analysis, handoff contracts, runtime size, and test size.
- Shared Hermes closeouts already exist under `docs/agent-worklog/*.md`, so the neutral layer is not hypothetical; it already has real artifacts.

## Observed Weaknesses / Risk Patterns

- Raw history logs are large. Largest sampled logs include:
  - `history_LootingTheLeviathan_2026-06-15.md`: 215098 chars (~53775 tokens)
  - `history_LootingTheLeviathan_2026-05-28.md`: 194998 chars (~48750 tokens)
  - `history_LootingTheLeviathan_2026-06-16.md`: 174362 chars (~43591 tokens)
  - `history_LootingTheLeviathan_2026-06-11.md`: 171827 chars (~42957 tokens)
  - `history_LootingTheLeviathan_2026-06-23.md`: 160399 chars (~40100 tokens)
  - `history_LootingTheLeviathan_2026-05-29.md`: 158083 chars (~39521 tokens)
  - `history_LootingTheLeviathan_2026-06-07.md`: 155804 chars (~38951 tokens)
  - `history_LootingTheLeviathan_2026-06-02.md`: 102742 chars (~25686 tokens)
- Raw logs are better evidence than default context; reading all of them in each Hermes turn would waste tokens and bury the active signal.
- The prior compact layer did not define a canonical live in-progress file, so “what is active right now?” still required session memory or manual inspection.
- Cursor/VSCode-local histories exist, but they are not versioned, not project-local, and not suitable as the canonical shared collaboration surface.
- Worklog value depends on closeout quality; missing compact summaries or missing raw references force future agents to reopen large evidence files.

## Recommended Workflow Changes

1. Keep `docs/codex-worklog/` as immutable historical raw evidence.
2. Use `docs/agent-worklog/ACTIVE.md` as the shared live handoff file for all agents.
3. Make `docs/agent-worklog/INDEX.md` the first historical discovery file after `ACTIVE.md`.
4. Use `docs/agent-worklog/COMPACT.md` plus shared closeouts as default context before raw logs.
5. End non-trivial Hermes/Cursor/VSCode agent work with a shared closeout rather than a parallel raw transcript silo.
6. Keep source-specific raw evidence linked through `raw_refs` instead of duplicating it.
7. Route future Codex/Cursor automation through a project-local wrapper so LTL-specific policy stays in-repo.

## Harness Requirements

- Project-local wrapper: `tools/agent-worklog.ps1`
- Project config: `.agent-harness.json`
- Generic reusable implementation: `../agent-harness/tools/worklog-token-gate.ps1`
- Shared live status file: `docs/agent-worklog/ACTIVE.md`
- Shared summary outputs: `docs/agent-worklog/INDEX.md`, `docs/agent-worklog/COMPACT.md`
- Shared closeout template: `docs/templates/agent-worklog-template.md`
- Shared active template: `docs/templates/agent-active-worklog-template.md`

## Confirmed Decisions

- `docs/codex-worklog/` remains the raw evidence owner for Codex automation.
- `docs/agent-worklog/` is the neutral shared collaboration layer for Hermes, Codex, Cursor, and plain VSCode workflows.
- The canonical shared read order is `ACTIVE.md -> INDEX.md -> COMPACT.md -> relevant shared closeout -> raw evidence on demand`.
- Future source-specific hooks should bridge into the project-local shared layer; they should not make IDE-local AppData or workspace-root scratch docs the canonical source of truth.
- VSCode/Cursor AppData history is for backfill or forensics only, not for the canonical live worklog.

## Deferred Rollout Items

- Extend the generic summarizer so `INDEX.md` / `COMPACT.md` ingest `ACTIVE.md` and shared closeouts directly, not only raw Codex files.
- Add dedicated start/update/finish shared-worklog commands to the project-local wrapper once the shared contract is stable.
- Decide later whether shared-layer freshness/staleness checks should become hard gates.
- Decide later whether any Godot validation commands should move from optional to required after runner stability improves.

## Verification Notes

- `tools/agent-worklog.ps1` is currently a thin wrapper around `../agent-harness/tools/worklog-token-gate.ps1`.
- The current generic gate generates `INDEX.md`, `COMPACT.md`, and `new-log` templates from `docs/codex-worklog/` only.
- Existing shared Hermes closeouts are already present under `docs/agent-worklog/*.md`.
- The shared-layer contract above is based on direct inspection of `.agent-harness.json`, `tools/agent-worklog.ps1`, `../agent-harness/tools/worklog-token-gate.ps1`, `docs/templates/agent-worklog-template.md`, and current `docs/agent-worklog/` files.
