# Request Analysis And Execution Gates Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent instruction-following failures where intermediate goals overtake top-level constraints by adding reusable request-analysis guidance, execution gates, and completion gates to the LTL harness workflow.

**Architecture:** Add one explicit pre-execution workflow that turns user language into a machine-checkable constraint ledger, then enforce that ledger at three moments: before edits, during execution updates, and before completion claims. Keep the first rollout documentation-led and lightweight, then wire the same rules into harness scripts so the process survives beyond one agent session.

**Tech Stack:** Markdown process docs, harness policy docs, PowerShell gate scripts, Codex worklog documents.

---

## File Structure

- Create: `LTL-harness/docs/request-analysis-execution-gate.md`
  - Canonical workflow for request parsing, constraint extraction, execution planning, and completion reporting.
- Create: `LTL-harness/docs/templates/request-constraint-ledger-template.md`
  - Reusable template for goals, preserved invariants, mutable areas, verification checks, and completion claims.
- Create: `LTL-harness/docs/templates/request-execution-checklist-template.md`
  - Short operational checklist agents can copy into plans or worklogs before editing.
- Modify: `LTL-harness/00_AGENTS.md`
  - Add mandatory request-analysis gate, constraint-ledger requirement, and completion-gate language.
- Create: `LTL-harness/tools/request-analysis-gate.ps1`
  - Validate that a referenced ledger contains required sections before implementation work begins or completion is reported.
- Modify: `LTL-harness/tools/run-compile-check.ps1`
  - Add an optional hook that checks whether the active plan/worklog references a valid request ledger before verification passes are treated as sufficient evidence.
- Create: `docs/superpowers/plans/examples/request-gate-example.md`
  - One concrete layout-fix example showing how preserved constraints stop the exact class of failure that happened here.
- Modify: `docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md`
  - Record this planning task and expected outputs.
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md`
  - Record the planning work concisely.
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md`
  - Summarize the finished planning deliverable after it is ready to report.

## Design Principles

1. **User wording outranks inferred convenience.**
   - Words like `preserve`, `keep as-is`, `do not remove`, `remaining space`, and `centered` become explicit constraints, not soft preferences.
2. **Top-level constraints are first-class artifacts.**
   - Constraints live in a ledger, not only in memory or commentary.
3. **Execution cannot collapse planning.**
   - A good-looking intermediate result is not sufficient if any preserved invariant is broken.
4. **Completion claims require request-level verification.**
   - `tests passed` and `layout intent satisfied` are separate checks.
5. **The gate should be cheap enough to use every day.**
   - The first pass must be concise and copyable, not a ceremony that gets skipped.

## Failure Modes To Cover

- Loss of preserved constraints while optimizing an intermediate goal.
- Reinterpreting `maintain/preserve` as `roughly similar` instead of `do not mutate`.
- Solving only the visible symptom without checking full request scope.
- Claiming success from code/test evidence when the request required visual or behavioral confirmation.
- Letting follow-up fixes drift because the original request was never converted into a stable artifact.

### Task 1: Define The General Request-Analysis Workflow

**Files:**
- Create: `LTL-harness/docs/request-analysis-execution-gate.md`
- Modify: `LTL-harness/00_AGENTS.md`

- [ ] **Step 1: Write the workflow outline**

Document five required stages:

1. Request Parse Gate
2. Constraint Ledger Gate
3. Execution Mapping Gate
4. Verification Gate
5. Completion Gate

- [ ] **Step 2: Define the Request Parse Gate**

Require the agent to extract:

- primary objective
- preserved constraints
- mutable areas
- explicit exclusions
- hidden risk areas
- proof expectations

- [ ] **Step 3: Define the Constraint Ledger Gate**

Require a ledger entry with these sections:

- request summary in plain language
- non-negotiable invariants
- allowed modifications
- unknowns and assumptions
- success checks tied to user wording

- [ ] **Step 4: Update `00_AGENTS.md`**

Add policy text that implementation must stop if:

- a preserved invariant is still ambiguous
- the planned change mutates a preserved area
- verification cannot prove the user-facing claim

- [ ] **Step 5: Review for overlap with comment-first and milestone gates**

Make sure the new request-analysis gate complements existing gates instead of duplicating them.

### Task 2: Add Reusable Templates So The Workflow Is Easy To Follow

**Files:**
- Create: `LTL-harness/docs/templates/request-constraint-ledger-template.md`
- Create: `LTL-harness/docs/templates/request-execution-checklist-template.md`
- Create: `docs/superpowers/plans/examples/request-gate-example.md`

- [ ] **Step 1: Create the ledger template**

Include fields for:

- request id or short title
- original user phrasing
- preserved invariants
- allowed edits
- forbidden edits
- verification evidence needed
- completion statement constraints

- [ ] **Step 2: Create the execution checklist template**

Include a short copyable checklist:

- request restated
- invariants frozen
- mutable surface identified
- steps mapped to each invariant
- verification mapped to each user claim

- [ ] **Step 3: Create one concrete example**

Use the recent layout case to show:

- how `keep backpack size/ratio` becomes a frozen invariant
- how `move to right edge` becomes a position-only change
- how `use remaining space for node panel` becomes the only expand target
- how a before/after size comparison would catch drift

### Task 3: Add A Lightweight Pre-Execution Gate Script

**Files:**
- Create: `LTL-harness/tools/request-analysis-gate.ps1`

- [ ] **Step 1: Define script inputs**

Support:

- `-Ledger <path>`
- `-Mode pre-edit|pre-complete`
- `-RequireVisualProof`

- [ ] **Step 2: Validate required ledger sections**

Fail if the ledger is missing:

- request summary
- preserved invariants
- mutable scope
- verification checklist

- [ ] **Step 3: Validate completion-specific fields**

In `pre-complete` mode, fail if:

- any invariant lacks a matching verification note
- visual/interaction claims lack explicit visual verification notes when required

- [ ] **Step 4: Print actionable errors**

Errors should say what is missing and what the agent must add, not only that the gate failed.

### Task 4: Connect The New Gate To The Existing Harness Flow

**Files:**
- Modify: `LTL-harness/tools/run-compile-check.ps1`
- Modify: `LTL-harness/00_AGENTS.md`

- [ ] **Step 1: Decide the minimum integration point**

Keep the request-analysis gate opt-in at first, then promote it to required once the templates settle.

- [ ] **Step 2: Add a non-destructive first rollout**

First rollout behavior:

- warn when no request ledger is referenced
- fail only when a ledger is referenced but incomplete

- [ ] **Step 3: Define the stricter second rollout**

Second rollout behavior:

- fail verification if no valid ledger exists for non-trivial tasks

- [ ] **Step 4: Document rollout policy**

Explain when the project moves from warning mode to hard-fail mode.

### Task 5: Add Completion Reporting Rules That Prevent Premature Success Claims

**Files:**
- Modify: `LTL-harness/docs/request-analysis-execution-gate.md`
- Modify: `LTL-harness/00_AGENTS.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md`

- [ ] **Step 1: Define claim categories**

Separate:

- code change complete
- local verification complete
- visual verification complete
- user request fully satisfied

- [ ] **Step 2: Require claim-to-evidence mapping**

Each final completion claim must map to one of:

- test evidence
- script/gate evidence
- visual/manual QA evidence
- explicit unverified note

- [ ] **Step 3: Ban vague completion language**

Disallow phrases like:

- “fixed”
- “resolved”
- “done”

unless the preserved constraints and proof expectations are explicitly checked.

### Task 6: Roll Out With Small, Verifiable Adoption Steps

**Files:**
- Modify: `docs/codex-worklog/plan_LootingTheLeviathan_2026-05-31.md`
- Modify: `docs/codex-worklog/history_LootingTheLeviathan_2026-05-31.md`
- Modify: `docs/codex-worklog/complete_LootingTheLeviathan_2026-05-31.md`

- [ ] **Step 1: Phase 1 - Planning only**

Deliver:

- this implementation plan
- worklog updates
- no harness behavior change yet

- [ ] **Step 2: Phase 2 - Docs and templates**

Deliver:

- new workflow doc
- ledger template
- checklist template
- example doc

- [ ] **Step 3: Phase 3 - Warning-mode script gate**

Deliver:

- request-analysis gate script
- optional invocation path from verification flow

- [ ] **Step 4: Phase 4 - Required gate**

Deliver:

- hard requirement for non-trivial tasks
- updated completion language rules

## Verification Plan

- Confirm the plan covers:
  - request analysis
  - preserved-constraint capture
  - execution gating
  - verification gating
  - completion gating
- Confirm every failure mode listed above has at least one task addressing it.
- Confirm file targets are all inside the harness/docs/worklog surface intended for process enforcement.
- Confirm the rollout phases allow low-risk adoption before hard enforcement.

## Expected Outputs

- One reusable implementation plan for generalized request-analysis and execution gates.
- Updated worklog entries showing why this plan exists and what it will change.
- A clear next-step path from documentation to warning gate to required gate.
