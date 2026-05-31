# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-05-30

## Active Work

Fix the remaining backpack reward-placement blackout and the still-clipped node-select layout reported after live manual QA.

## Request Summary

- Fix the backpack grid still turning into a black, undifferentiated block after clicking a reward artifact, placing it into the backpack, or returning it to the reward list.
- Fix the node-select layout so the backpack keeps its current panel size on the right edge while the remaining width belongs to the node-map panel, with the route graph centered inside that panel.
- Keep the gameplay flow intact; this is a visual/layout correction pass.

## Scope

- Inspect `BackpackUI`, `InteractionFX`, and the reward-placement path in `MainControllerRuntime`.
- Add test coverage for both drag-feedback tint cleanup and slot-alpha restoration after reward placement.
- Adjust the node-select docking behavior in `MainViewRuntime` so the backpack stays right-aligned at a stable width and the node-map panel uses the leftover width.
- Recenter the node-route graph within the node-map panel after the docking change.

## Out of Scope

- No redesign of reward reveal flow or reward tray layout.
- No rebalance of artifacts, rewards, or combat pacing in this pass.
- No broad interaction-FX refactor outside the backpack regression and the node-select dock/layout correction.

## Steps

- Add failing regression tests for backpack slot tint restoration and slot alpha restoration after drag feedback ends.
- Fix the drag-feedback cleanup path in `InteractionFX.apply_drag_feedback()`.
- Adjust node-select right-dock layout in `MainViewRuntime` and center the route graph within the available node panel.
- Run Godot contract verification and a whitespace diff check.

## Expected Outputs

- Reward placement or canceling a held reward no longer leaves the backpack grid blackened or visually flattened.
- Backpack slots still show valid/invalid drag feedback while dragging.
- The backpack remains flush to the right with a stable size, and the node-select graph uses the remaining width and sits centrally in its panel.
- Regression tests protect the backpack cleanup path for future UI passes.

## Verification Method

- Red/green Godot contract run for the new backpack regression tests.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- `git diff --check`

## Plan Change Log

- 2026-05-30: Worklog bootstrapped automatically by Codex hook.
- 2026-05-30: Re-scoped to the reward-placement backpack blackout regression reported after the latest UI/layout pass.
- 2026-05-30: Expanded scope after fresh live QA to include the node-select right-dock layout and graph centering issue that still leaves the map clipped.
