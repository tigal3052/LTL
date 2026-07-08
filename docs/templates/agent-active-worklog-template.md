# Active Worklog Template

Use one block per concurrent source/session. The shared active file is a live handoff surface, not a full transcript dump.

```md
## work_unit: <source-date-slug-or-session>
- agent: <hermes|codex|cursor|vscode|other>
- source: <tui|cli|cursor|vscode|gateway|other>
- status: <active|handoff-needed|blocked>
- started_at: <ISO-8601>
- updated_at: <ISO-8601>
- objective_ids: <comma-separated ids or none>
- raw_refs:
  - <docs/codex-worklog/... or none>

### Current Goal
- <what this work unit is trying to accomplish now>

### Current Scope
- <what is explicitly in scope>

### Files In Play
- <files currently being edited or inspected>

### Next Intended Step
- <the next concrete action the next agent should take>

### Validation Pending
- <focused checks still needed>

### Notes For Next Agent
- <handoff note, blocker, caveat, or none>
```

Rules:

- Keep only active in-progress state here.
- Move durable outcomes into a shared closeout under `docs/agent-worklog/YYYY-MM-DD-<agent>-<slug>.md`.
- If a raw source-specific log exists, reference it via `raw_refs` instead of copying it here.
- Do not use IDE-local AppData history as the canonical shared active record.
