# Agent Workflow Analysis

## Source

- Project: `D:/Programming/ex_workspace/LootingTheLeviathan`
- Raw Codex worklogs: `docs/codex-worklog/`
- Analysis date: `2026-06-24`
- Files analyzed: `97` markdown logs
- Approximate raw text size: `2658389` characters (~664598 tokens by the harness estimate)
- Log kind counts: `{'complete': 32, 'history': 33, 'plan': 32}`

## Executive Summary

The existing Codex worklog practice is valuable because it records plan/history/complete evidence for many development sessions. The main weakness is not absence of history; it is context cost and retrieval friction. Several `history_*` files are very large, so future agents should not read the whole raw directory by default. The improved workflow keeps raw logs as evidence and introduces `docs/agent-worklog/INDEX.md` plus `COMPACT.md` as the default summary-first context layer.

## Observed Strengths

- Work is recorded consistently across dated `plan_*`, `history_*`, and `complete_*` files.
- Completion logs often separate actual outputs, plan changes, verification results, blockers, and remaining gaps.
- The project already has strong harness culture: request ledgers, source maps, quality gates, artifact ledgers, Godot runner wrappers, and LTL-specific gate scripts.
- Verification evidence is frequently named explicitly with expected markers such as `*_OK`.
- The generic `agent-harness` already contains reusable gates for source maps, request analysis, handoff contracts, runtime size, and test size.

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
- Codex-specific directory naming can make Hermes unsure whether to write a parallel log, reuse the Codex log, or create a neutral summary layer.
- Some verification remains environment-dependent because Godot/windowed checks cannot always run headlessly.
- Worklog value depends on closeout quality; missing compact summaries force future agents to reopen raw logs.

## Recommended Workflow Changes

1. Keep `docs/codex-worklog/` as immutable historical raw evidence.
2. Add `docs/agent-worklog/` as the shared compact summary layer for Hermes, Codex, and other agents.
3. Make `docs/agent-worklog/INDEX.md` the first file agents read for past-work context.
4. Open raw logs only when the index or compact summary identifies a relevant date/task.
5. End non-trivial Hermes work with a compact summary rather than a full transcript dump.
6. Use `tools/agent-worklog.ps1 -Mode token-report` before scanning broad worklog history.
7. Use `tools/agent-worklog.ps1 -Mode summarize-worklogs` after raw logs are added or changed.

## Harness Requirements

- Project-local wrapper: `tools/agent-worklog.ps1`.
- Project config: `.agent-harness.json`.
- Generic reusable implementation: `../agent-harness/tools/worklog-token-gate.ps1`.
- Summary outputs: `docs/agent-worklog/INDEX.md`, `docs/agent-worklog/COMPACT.md`.
- Template: `docs/templates/agent-worklog-template.md`.

## Hermes Worklog Decision

Use compact shared agent worklogs instead of a full parallel `docs/hermes-worklog/` raw transcript directory. This avoids duplicating Codex-style raw logs and optimizes token use. If a future Hermes session needs raw evidence, create a concise `docs/agent-worklog/YYYY-MM-DD-hermes-<task>.md` with a mandatory `Compact Summary` section.

## Open Questions

- Whether future Codex automation should also write directly into `docs/agent-worklog/` or continue writing raw files under `docs/codex-worklog/` and rely on summarization.
- Which Godot validation commands should become required vs. optional in `.agent-harness.json` after machine-specific runner stability is confirmed.

## Verification Notes

- `tools/agent-worklog.ps1 -Mode inspect` passed and counted 97 raw Codex worklogs.
- `tools/agent-worklog.ps1 -Mode token-report` passed and estimated 666645 raw-log tokens; largest raw logs exceed 50000 estimated tokens.
- `tools/agent-worklog.ps1 -Mode summarize-worklogs` generated `docs/agent-worklog/INDEX.md` and `docs/agent-worklog/COMPACT.md`.
- `tools/agent-worklog.ps1 -Mode validate` passed after summary generation.
- `tools/agent-worklog.ps1 -Mode new-log -Task "Harness smoke test" -Agent hermes -DryRun` produced the expected compact closeout template.
- Full `LTL-harness/tools/source-map-gate.ps1 -Root .` currently fails on pre-existing stale mapped files unrelated to the new worklog-token integration. New files added by this pass are present and mapped; the stale source-map cleanup should be handled as a separate request.
