# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-05-31

## Active Work

Fix the top-content height mismatch so `LeftColumn`, `Backpack`, and `RightSidebar` share the same visible height, using the backpack as the baseline and letting it consume the full vertical space between the header and the terrain panel.

## Request Summary

After the previous top-content spacing change, the user observed that the visible backpack panel became shorter than the left and right side panels. They asked to determine whether the issue is caused by the side panels growing or by the backpack no longer preserving the intended size, then make all three top-content panels share the same height with the backpack using the maximum available vertical space.

## Scope

- Confirm the root cause in the top-content height/width sizing chain.
- Add focused regression tests for the backpack height-baseline policy.
- Make the top-content backpack width derive from the full available row height so the visible backpack panel reaches the same height as the left and right panels.
- Preserve the fixed-gap horizontal policy and keep node-select right-docked behavior unchanged.

## Out of Scope

- Reworking the node-select page layout or map/detail vertical split.
- Reverting pre-existing dirty workspace changes.
- Changing gameplay balance, node routing rules, artifact rules, or non-layout data.

## Steps

- Add failing layout contract tests for the top-content backpack height-baseline policy.
- Patch `MainViewRuntime.gd` so the top-content backpack width is driven by the full available row height rather than a reduced value.
- Keep the existing top-content fixed-gap policy intact while restoring equal visible heights.
- Run the focused Godot smoke test and whitespace diff checks.
- Record results in history/completion worklogs.

## Expected Outputs

- Updated `app-LTL/src/ui/MainViewRuntime.gd`
- Updated `app-LTL/tests/test_ui_read_models.gd`
- Updated worklog files

## Verification Method

- Run direct headless Godot smoke verification with `tests/godot_contract_runner.gd -- --smoke-only`.
- Run `git diff --check` on the touched files.

## Plan Change Log

- 2026-05-31: Worklog bootstrapped automatically by Codex hook.
- 2026-05-31: Replaced placeholders with a generalized planning task for request-analysis and execution gates.
- 2026-05-31: Replaced the earlier planning-only scope with the approved backpack/node-panel layout rebalance task.
- 2026-05-31: Expanded the scope after screenshot review to include the rightmost node-button click regression and node-map/detail-panel vertical rebalance.
- 2026-05-31: Follow-up request shifted from live layout edits to a visual terrain-panel comparison mockup using the newly provided `miner` and `tile` art assets.
- 2026-05-31: Follow-up request shifted to root-cause explanation for node-select sizing and a broad UI layout/test-separation refactor plan.
- 2026-05-31: Follow-up clarified the desired fix: shrink the node graph bottom gap, make detail space absorb the freed height, and size the right backpack from the same row height as the left stack.
- 2026-05-31: Active work changed to the top-content horizontal layout request: keep backpack size, widen both side panels toward it, and leave about 20px between the visible panels.
- 2026-05-31: Follow-up bugfix narrowed the issue to the top-content height mismatch: the visible backpack panel must reclaim the full available row height and become the baseline for the left and right panels.
