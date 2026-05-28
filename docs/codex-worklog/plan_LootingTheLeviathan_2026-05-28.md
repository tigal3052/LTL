# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-05-28

## Active Work

Execute the M3 pre-refactor logical capsule plan in the current workspace.

## Request Summary

Implement the saved M3 pre-refactor plan, starting with stable verification and strict architecture gates, then extracting gameplay logic out of `MainController.gd` and UI composition out of `MainUI.gd`.

## Scope

- Fix the Godot contract wrapper enough to run without the duplicate `Path/PATH` failure.
- Make the architecture gate fail when main-scene boundaries are violated.
- Extract logic into vocabulary, phase, read-model, presenter, and UI-panel boundaries following the saved plan.
- Preserve existing user/source changes and avoid unrelated rewrites.

## Out of Scope

- No M3 feature expansion beyond the refactoring support needed for M3 readiness.
- No commit or branch creation.

## Steps

- Stabilize verification command.
- Harden architecture gate.
- Extract vocabulary and phase boundaries.
- Split UI read models, presenters, and panels.
- Thin `MainController.gd` and `MainUI.gd`.
- Run verification and record remaining gaps.

## Expected Outputs

- Refactored Godot source files and tests.
- Updated architecture gate and worklog.
- Final verification summary in chat.

## Verification Method

- Run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`.
- Run `powershell -NoProfile -ExecutionPolicy Bypass -File LTL-harness/tools/architectural-gate.ps1 -ManifestPath docs/architectural-gates/m2-refactoring-gate.md`.
- Run focused Godot contract tests added during the refactor.

## Plan Change Log

- 2026-05-28: Worklog bootstrapped automatically by Codex hook.
- 2026-05-28: Updated for M2 review and M3-prep logical capsule refactoring plan.
- 2026-05-28: Switched active work from planning/translation to executing the saved refactoring plan.
