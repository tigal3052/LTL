# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-05-29

## Active Work

Resolve the latest Game Studio-directed manual QA pass: widen the node-select map, remove the CORE marker, disable backpack hover wobble, and rebalance the five-stage health curve against reward snowballing.

## Request Summary

- Give the node-select map more room than the docked backpack and stop chips from clipping in the left panel.
- Remove the `CORE` marker so the selection screen shows only `START` plus the five candidate nodes.
- Disable backpack hover wobble so idle slot art stays stable and readable.
- Rebalance stage durability/health so stage 3 no longer collapses under reward snowballing and the five-stage health rise is front-loaded, then tapers.

## Scope

- Adjust node-select split ratios and minimum widths in the live `MainViewRuntime` shell.
- Rebuild `NodeMapScene` geometry around a five-choice fan layout with real width-based placement and resize-safe rerendering.
- Opt backpack slots out of generic interaction FX while preserving drag/drop accept-reject feedback.
- Introduce an explicit `stageHealthTotals` tuning table and update contract tests to the new five-stage curve.

## Out of Scope

- No full replacement of the reward tray with a brand-new authored card system in this pass.
- No asset downloads or third-party binary imports directly into the repository during this implementation pass.
- No redesign of combat rules outside the overload/input bug and current reveal pacing.

## Steps

- Add red tests for CORE removal, backpack hover opt-out, widened node-map split, and the revised five-stage durability/health table.
- Fix runtime layout math in `NodeMapScene`, `PhaseLayoutPresenter`, and `MainViewRuntime`.
- Disable generic hover FX on backpack slots while leaving drag/drop placement cues intact.
- Update stage scaling defaults and fallback curves, then rerun Godot contract verification.

## Expected Outputs

- Node-select presents a clean `START + 5 choices` map that fits the available panel width.
- Backpack idle rendering stays stable with no hover wobble or black slot wash.
- The docked backpack remains visible but stops starving the node map of width.
- Stage durability and health follow the new front-loaded, tapering five-stage curve.

## Verification Method

- Red/green Godot contract run for the targeted additions.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- `git diff --check`

## Plan Change Log

- 2026-05-29: Re-scoped from source-map creation work to formal replay fixture promotion, prototype reference removal, and safe residue deletion while preserving the prototype tree.
- 2026-05-29: Re-scoped to the approved M4 follow-up: node map UI, start-color loadout, durability balance formula, and slower terrain marker movement.
- 2026-05-29: Re-scoped to external-shader-inspired UI affordance polish: hover glow, click ripple/compression, drag/drop accept/reject feedback, disabled-state clarity, and source-attributed implementation notes.
- 2026-05-29: Re-scoped to the next manual QA/UI direction corrections: node-map overlap, backpack idle readability, shell button standards, overload input lockout, reward reveal anticipation, and a formal visual-upgrade roadmap.
- 2026-05-29: Re-scoped again to the Game Studio-directed node-select/backpack pass: remove the CORE marker, widen the map split, disable backpack hover wobble, and front-load stage health scaling through stage three.
