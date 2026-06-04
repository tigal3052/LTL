# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-04

## Active Work

Align the stale HUD queue contract with the shipped half-loaded queue design, write the official M5 completion report, and publish the current branch state.

## Request Summary

- The broad Godot contract suite still contains one stale HUD queue assertion that expects `16` loaded tokens even though the current design intentionally starts combat with a half-loaded doubled queue.
- The user asked to update that contract to match the current design, then treat M5 as complete, commit the current branch state, and push it.

## Scope

- Keep runtime behavior unchanged and only update the stale contract expectation that no longer matches the half-loaded queue policy.
- Write the missing M5 completed milestone report under `LTL-harness/docs/11_exec-plans/02_completed/`.
- Update today's worklog and source-map coverage so the closure evidence passes repository gates.
- Verify, then commit and push the current branch state.

## Out of Scope

- Redesigning queue behavior to start fully loaded instead of half loaded.
- Rewriting historical worklog entries that were accurate at the time they were recorded.
- Cleaning or splitting unrelated in-progress workspace changes beyond the requested current-version publish.

## Steps

- Reproduce the current RED failure in `tests/godot_contract_runner.gd` and confirm it is the stale `loaded == 16` HUD assertion.
- Update the contract to the shipped half-loaded doubled-queue expectation and add the M5 completion artifacts.
- Re-run the full contract runner, milestone gate, and quality gate evidence required for honest milestone closure.
- Stage the current branch state, commit it, and push it to `origin`.

## Expected Outputs

- `tests/godot_contract_runner.gd` matches the current queue design and reaches `GODOT_CONTRACTS_OK`.
- `11_M5_hazard_hierarchy_completed.md` exists with concrete outputs, verification evidence, and remaining gaps.
- The current branch has a fresh commit and is pushed to the remote branch.

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\invoke-godot.ps1 -Headless -Script tests/godot_contract_runner.gd -Quit`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\run-ltl-quality-gate.ps1`
- `powershell -NoProfile -ExecutionPolicy Bypass -File .\LTL-harness\tools\milestone-gate.ps1 -TargetPlan 12_M6_ui_ux_finalization.md -Root D:\Programming\ex_workspace\LootingTheLeviathan`
- `git diff --check`

## Plan Change Log

- 2026-06-04: Worklog bootstrapped automatically by Codex hook.
- 2026-06-04: Re-scoped earlier work multiple times for purple runtime, layout containment, backpack priority, hazard spawning, and relic/runtime alignment.
- 2026-06-04: Re-scoped to the reported Anchor Oathplate runtime issue so clicked tile color, one-shot consume, and alpha restoration are verified together.
- 2026-06-04: Re-scoped again to the combat overlay pause bug so settings/codex stop battle progression and resume cleanly on close.
- 2026-06-04: Re-scoped to the popup top-layer follow-up after a combat screenshot showed codex/settings menus rendering underneath active gameplay HUD art.
- 2026-06-04: Re-scoped to the post-click combat bottom-gap drift after comparing before/after screenshots and tracing the change to the purple status HUD lane.
- 2026-06-04: Re-scoped to close M5 honestly by aligning the stale HUD queue assertion with the shipped half-loaded queue design, writing the missing M5 completion report, and publishing the current branch state.
