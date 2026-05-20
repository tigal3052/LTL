# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-05-20

## Active Work

- Implement `LTL-harness/docs/11_exec-plans/01_active/07_M1_core_domain_stabilization.md` inside `app-LTL` from an isolated worktree.

## Request Summary

- The user asked us to create a worktree first.
- After that, the user wants the M1 core-domain stabilization milestone implemented from the referenced execution plan.

## Scope

- Stabilize `app-LTL` data contracts, validation, snapshot/read-model APIs, and replay-facing process boundaries.
- Add or update automated tests that lock the M1 contract decisions before implementation code is added.
- Update worklog and M1-facing documentation inside the worktree to reflect what was implemented and what remains deferred.

## Out of Scope

- Restoring tracked status for `LTL-harness/` in the main repository.
- Full Godot scene reconstruction or browser visual rework.
- Narrative systems or full meta progression beyond the explicit M1 contract fields.

## Steps

- Create and verify an isolated worktree branch for M1 implementation.
- Review the M1 plan and current `app-LTL` code to map comment-only scaffolds vs existing logic.
- Write failing tests for validator coverage, root/phase snapshots, and replay scenarios from the M0 matrix.
- Implement the minimal production code needed to satisfy the new tests while keeping browser-prototype rules as the SoT baseline.
- Update documentation and the tech-debt tracker to distinguish resolved M1 items from deferred work.
- Run the focused test suite and record the results in the worklog completion note.

## Expected Outputs

- A worktree branch containing the M1 domain-contract implementation.
- Validator-backed contracts for artifact, node, reward, leviathan, and progress data.
- Stable public snapshot/read-model APIs plus replay coverage for the promoted M0 scenarios.
- Updated docs/worklog entries that explain the implemented contract boundary and remaining deferred items.

## Verification Method

- Run `npm test` in `app-LTL` and confirm the new M1 contract tests fail first, then pass after implementation.
- Re-read the exported public API files to confirm they no longer expose only placeholder comments.
- Cross-check the resulting snapshot and replay outputs against the required fields and scenarios listed in the M1 plan.

## Plan Change Log

- 2026-05-20: Worklog bootstrapped automatically by Codex hook.
- 2026-05-20: Updated the active plan for the request to implement only `app-LTL/src/action-result.js` from its staged comments.
- 2026-05-20: Replaced placeholders with the current single-file implementation plan for `action-result.js`.
- 2026-05-20: Updated the active plan for the request to amend both `00_AGENTS.md` files with comment-preservation rules.
- 2026-05-20: Updated the active plan for the request to revert `action-result.js` to the Korean comment-only stage.
- 2026-05-20: Updated the active plan for the request to add stronger comment-preservation rules to both AGENTS files.
- 2026-05-20: Updated the active plan for the request to create a shared comment-rule SoT document and point both AGENTS files at it.
- 2026-05-20: Updated the active plan for the request to remove low-signal examples and compress the comment policy into pure allow/forbid/remediation rules.
- 2026-05-20: Replaced the stale action-result task with a documentation task to complete P4/M0 execution-plan notes from source and interview evidence only.
- 2026-05-20: Corrected the document target from `01_active` to `02_completed` after the user clarified the intended location for P4/M0 completion reports.
- 2026-05-20: Replaced the documentation task with a git-tracking task to snapshot the current workspace and untrack `agent-harness` and `LTL-harness`.
- 2026-05-20: Replaced the stale git-tracking task in the worktree with M1 core-domain stabilization implementation for `app-LTL`.
