# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-04

## Active Work

Audit the M6 implementation plan against the live Godot source tree, identify stale or weak plan assumptions, and write a refreshed M6 plan with stronger visual-production detail informed by reference research.

## Request Summary

- Analyze the current M6 implementation plan and the live codebase together.
- Identify where the plan is stale, structurally weak, or too vague to prevent prototype-grade visuals.
- Use sub-agent reference research on similar games to strengthen the M6 direction, especially for HUD readability, reward/node flow, backpack presentation, and reusable art-kit planning.
- Write the improved plan back into workspace docs.

## Scope

- Inspect the official M6 harness milestone doc and the existing local M6 implementation plan.
- Compare both documents against the actual `app-LTL/src/**` and `app-LTL/tests/**` structure.
- Verify the current source state with the relevant gates and focused UI contract runners.
- Write a refreshed M6 plan that uses the live file map, preserves already-green systems, and adds concrete visual/art-direction guidance.
- Update today's worklog and source-map coverage for any newly added planning document.

## Out of Scope

- Implementing the M6 runtime changes themselves in this request.
- Re-scoping M7, M8, or M9 milestone goals.
- Rewriting unrelated historical worklog entries or reverting unrelated workspace edits.
- Producing final art assets in this pass; this task only needs the implementation and art-production plan.

## Steps

- Read the official M6 milestone doc and the current local M6 implementation plan.
- Inspect the actual UI/runtime files and test runners that now carry M6 responsibilities.
- Run the milestone gate, compile check, UI read-model tests, reward ceremony contract, and layout audit to confirm the live baseline.
- Synthesize plan gaps and stale assumptions.
- Write a refreshed M6 plan with explicit current-file ownership, visual direction, asset-kit rules, and updated verification flow.
- Update worklog/history/complete files with the analysis outcome.

## Expected Outputs

- A written audit of how the current M6 plan diverges from the live codebase.
- A refreshed M6 plan document that is safe to execute against the current tree.
- Updated worklog/source-map entries for the new planning artifact.
- Verification evidence showing the current baseline is already green, so the refresh plan can focus on real gaps instead of stale recovery work.

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File .\LTL-harness\tools\milestone-gate.ps1 -TargetPlan 12_M6_ui_ux_finalization.md -Root D:\Programming\ex_workspace\LootingTheLeviathan`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run-compile-check.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Headless -Script tests/run_test_ui_read_models.gd -Quit`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Headless -Script tests/run_reward_ceremony_contract.gd -Quit`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Headless -Script tests/run_main_layout_audit_contract.gd -Quit`
- `git diff --check`

## Plan Change Log

- 2026-06-04: Worklog bootstrapped automatically by Codex hook.
- 2026-06-04: Re-scoped earlier work multiple times for purple runtime, layout containment, backpack priority, hazard spawning, and relic/runtime alignment.
- 2026-06-04: Re-scoped to the reported Anchor Oathplate runtime issue so clicked tile color, one-shot consume, and alpha restoration are verified together.
- 2026-06-04: Re-scoped again to the combat overlay pause bug so settings/codex stop battle progression and resume cleanly on close.
- 2026-06-04: Re-scoped to the popup top-layer follow-up after a combat screenshot showed codex/settings menus rendering underneath active gameplay HUD art.
- 2026-06-04: Re-scoped to the post-click combat bottom-gap drift after comparing before/after screenshots and tracing the change to the purple status HUD lane.
- 2026-06-04: Re-scoped to close M5 honestly by aligning the stale HUD queue assertion with the shipped half-loaded queue design, writing the missing M5 completion report, and publishing the current branch state.
- 2026-06-04: Re-scoped again to an M6 planning audit: compare the official milestone and local implementation plan against the live source tree, verify the green baseline, and write a refreshed M6 plan with reference-backed visual detail.
