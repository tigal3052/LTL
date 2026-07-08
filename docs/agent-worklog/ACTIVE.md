# Active Worklog

This file is the shared live status surface for concurrent agents working in Looting The Leviathan.

Rules:

- Keep one block per concurrent source/session.
- Use this file for in-progress handoff state, not for full transcript history.
- When work ends, create or update a shared closeout and remove or replace the active block.
- While dedicated automation is still rolling out, manual updates here are acceptable.

## work_unit: hermes-2026-06-29-shared-worklog-contract-step-1
- agent: hermes
- source: tui
- status: active
- started_at: 2026-06-29T08:10:05Z
- updated_at: 2026-06-29T08:10:05Z
- objective_ids: none
- raw_refs:
  - none

### Current Goal
- Establish the shared worklog contract so all future agents can read/write the same live and closeout surfaces.

### Current Scope
- Update `.agent-harness.json`, `docs/agent-harness.md`, `docs/agent-workflow-analysis.md`, and shared worklog templates.
- Create `docs/agent-worklog/ACTIVE.md` as the canonical live shared state file.
- Do not change Codex/Cursor global hooks or summary-generation code in this step.

### Files In Play
- `.agent-harness.json`
- `docs/agent-harness.md`
- `docs/agent-workflow-analysis.md`
- `docs/templates/agent-worklog-template.md`
- `docs/templates/agent-active-worklog-template.md`
- `docs/agent-worklog/ACTIVE.md`

### Next Intended Step
- Extend the generic summarizer so `INDEX.md` / `COMPACT.md` include this active file and shared Hermes closeouts directly.

### Validation Pending
- Re-run `tools/agent-worklog.ps1 -Mode summarize-worklogs` and `-Mode validate` after the summarizer step lands.

### Notes For Next Agent
- This block represents the documentation/config phase only. Do not assume shared summary ingestion is implemented yet.
