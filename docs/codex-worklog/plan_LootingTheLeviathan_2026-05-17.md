# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-05-17

## Active Work

Revise the LTL harness workflow into a three-step comment-to-code process and revert `action-result.js` to its pre-test design-comment state.

## Request Summary

The current rules over-corrected toward executable comments only. Update `LTL-harness/00_AGENTS.md` so work proceeds as: 1. design-based comments, 2. executable sentence comments, 3. comment-based implementation. Also revert the prior `action-result.js` test implementation back to the design-comment skeleton.

## Scope

- Update `LTL-harness/00_AGENTS.md`.
- Preserve the distinction between design comments and executable implementation comments.
- Revert `app-LTL/src/action-result.js` to the design-comment-only state.
- Remove the focused `app-LTL/tests/action_result.test.js` that belonged to the reverted test implementation.
- Update worklog files.

## Out of Scope

- Rewriting all existing `app-LTL/src` comments to the new three-step format.
- Implementing or testing any source module.
- Editing preserved prototype files.

## Steps

- Adjust logic-based programming rules to require the three-step workflow.
- Adjust comment rules, Ready, and Done so design comments are allowed only before executable comments and implementation.
- Restore `action-result.js` to design comments only.
- Remove the now-invalid focused action-result test file.
- Run diff checks.

## Expected Outputs

- `LTL-harness/00_AGENTS.md` documents the three-step workflow.
- `app-LTL/src/action-result.js` contains only the prior design-based comments.
- `app-LTL/tests/action_result.test.js` is removed.

## Verification Method

- `git diff --check -- LTL-harness/00_AGENTS.md app-LTL/src/action-result.js app-LTL/tests/action_result.test.js docs/codex-worklog`
- Spot-check the harness for the three-step workflow wording.
- `node --check src/action-result.js` from `app-LTL`.

## Plan Change Log

- 2026-05-17: Updated plan for three-step comment workflow and action-result revert.
- 2026-05-17: Updated plan for executable-comment rule tightening in `LTL-harness/00_AGENTS.md`.
- 2026-05-17: Updated plan for user-requested test implementation of `action-result.js` only.
- 2026-05-17: Updated plan for user-requested M1 logic-unit comment rewrite in `app-LTL/src`; implementation remains out of scope.
- 2026-05-17: Replaced the prototype recovery plan with the requested M1 comment-first `app-LTL/src` skeleton rebuild.
- 2026-05-17: Updated plan for harness rollback recovery of comment-first and logic-based programming rules.
- 2026-05-17: Updated plan for restoring `Document Structure` and modernizing the generic harness instead of trimming mismatched sections.
