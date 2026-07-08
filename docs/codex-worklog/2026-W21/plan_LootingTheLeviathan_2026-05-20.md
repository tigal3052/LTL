# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-05-20

## Active Work

- Harden the project instructions so `app-LTL/prototype/**` is treated as archived reference-only code that cannot be edited without explicit user approval, then rewrite the active M2 work so the next implementation targets `app-LTL/src`.

## Request Summary

- The user chose the strictest process hardening option.
- The user stated that the prototype is reference-only and should no longer be used as an implementation target.
- The user wants the instructions updated accordingly and wants M2 re-planned against the formal `app-LTL/src` path.

## Scope

- Update project guidance files that control path selection and implementation behavior.
- Strengthen the formal-path boundary in `app-LTL/src` documentation.
- Rewrite the active M2 execution plan to target `app-LTL/src`.
- Create a fresh M2 implementation plan document for formal-path execution.

## Out of Scope

- Executing the M2 implementation itself in this pass.
- Editing archived prototype files for feature work.
- Refactoring unrelated repository changes such as the existing `.gitignore` diff.

## Steps

- Update the instruction hierarchy so prototype edits require explicit user approval and formal milestones default to `app-LTL/src`.
- Reinforce the `app-LTL/src` README boundary so scene/HUD work is also treated as formal-path work.
- Rewrite the active M2 milestone file with explicit formal-path targets, file families, and verification expectations.
- Write a fresh M2 implementation plan document with task-level sequencing for `app-LTL/src`.
- Update the worklog with the instruction changes and new plan locations.

## Expected Outputs

- Stronger project rules declaring `app-LTL/prototype/**` archived reference-only code.
- An updated active M2 milestone document that names `app-LTL/src` as the implementation target.
- A new M2 implementation plan document under `docs/superpowers/plans/`.
- Updated worklog entries reflecting the hardened guidance and re-plan.

## Verification Method

- Re-read the modified guidance files to confirm the new prototype prohibition and target-path priority are explicit.
- Re-read the updated M2 milestone and the new M2 implementation plan to confirm they both target `app-LTL/src`.
- Confirm `git diff -- app-LTL/prototype/browser-p0-p4` remains empty after the documentation-only pass.

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
- 2026-05-20: Replaced the stale git-tracking task with the active M2 combat scene reconstruction implementation request.
- 2026-05-20: Replaced the M2 implementation task with a revert-and-review task after the user requested prototype rollback and process correction guidance.
- 2026-05-20: Replaced the revert-and-review task with strict process hardening plus an `app-LTL/src`-based M2 re-plan after the user confirmed prototype code is reference-only and no longer an implementation target.
