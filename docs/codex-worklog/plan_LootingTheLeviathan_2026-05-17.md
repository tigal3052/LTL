# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-05-17

## Active Work

Rebuilding the app structure from the top: separating existing source into `prototype` and creating a comment-only M1 scaffold that follows the clarified logic-based programming methodology.

## Request Summary

- Move the current browser implementation out of active source and into `app-LTL/prototype/browser-p0-p4`.
- Move the existing Godot prototype files into `app-LTL/prototype/godot-p0`.
- Recreate active `app-LTL/src` and `app-LTL/tests` as comment-only M1 scaffolding.
- Ensure new scaffold starts from player-facing Korean behavior sentences and code-leading Korean one-sentence comments.

## Scope

- Preserve existing implementation by moving it under `prototype`, not deleting it.
- Do not implement executable M1 domain behavior yet.
- Create only comments and markdown sentences in the new active source tree.
- Keep package/project metadata unless it must be adjusted for the new skeleton.

## Out of Scope

- Full Godot scene reconstruction or production UI redesign.
- Full meta progression loop, XP, unlocks, or narrative systems.
- Reverting or rewriting unrelated dirty workspace changes already present before this M1 implementation pass.

## Steps

- Create prototype subdirectories.
- Move current `src`, `tests`, and `public` into `prototype/browser-p0-p4`.
- Move existing Godot prototype files into `prototype/godot-p0`.
- Create new comment-only source/test files for M1 through process, phases, domain, data, UI, and tests.
- Verify no executable statements exist in the new active scaffold.

## Expected Outputs

- Existing browser/Godot prototype source preserved under `prototype`.
- New active source tree with comment-only M1 logical scaffold.
- Worklog notes explaining that M1 remains comment-only until player sentences and comments are approved.

## Verification Method

- Inspect active `app-LTL/src` and `app-LTL/tests` for comment-only files.
- Run `node --test tests/*.test.js` from `app-LTL` if the comment-only test scaffold is syntactically valid.
- Note: `npm test` is unavailable in this PowerShell session because execution policy blocks `npm.ps1`; use direct `node --test` commands.

## Plan Change Log

- 2026-05-17: Worklog bootstrapped automatically by Codex hook.
- 2026-05-17: Replaced placeholder plan with concrete scope for handoff-document rewrite and glossary grounding.
- 2026-05-17: Re-scoped active work to combat damage spec alignment requested during handoff interview.
- 2026-05-17: Re-scoped active work to backfill milestone completion docs, bootstrap the redesign-gate tracker, and rewrite the M1 stabilization plan.
- 2026-05-17: Re-scoped active work to M1 code implementation, starting with data contract validators and JSON-backed domain boundaries.
- 2026-05-17: Re-scoped active work to M1 review fixes plus `00_AGENTS.md` logic-based methodology compliance check.
- 2026-05-17: Re-scoped active work to remove the non-compliant M1 implementation after the methodology definition was clarified.
- 2026-05-17: Re-scoped active work to full structure rebuild: prototype separation plus comment-only M1 logical scaffold.
