# Battle Backpack Square Grid Width Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Widen the battle-page backpack grid so the internal grid presents as square while preserving the previously fixed width stability.

**Architecture:** Use the existing live visual contract as the source of truth. First make stable-but-narrow battle backpack layouts fail with node and rendered aspect checks, then adjust only the battle layout bounds that constrain width, preferring right sidebar narrowing if horizontal space is required.

**Tech Stack:** Godot 4.3 GDScript, existing `Main.tscn` battle flow, windowed visual contract, focused Godot contract runners.

---

## Task 1: Measure Current Narrow State

**Files:**
- Inspect: `app-LTL/tests/run_battle_backpack_visual_width_contract.gd`
- Inspect: battle layout runtime files identified by the measurements

- [x] Run the current visual contract with frame output.
- [x] Record grid width, grid height, rendered pixel width, rendered pixel height, and right sidebar width.
- [x] Identify the current aspect ratio and the limiting parent/container.

## Task 2: Add RED Square-Grid Assertions

**Files:**
- Modify: `app-LTL/tests/run_battle_backpack_visual_width_contract.gd`

- [x] Add per-frame height measurements for `GridMock` and rendered grid pixels.
- [x] Summarize grid node/render aspect ratios and minimum widths.
- [x] Fail when the grid is stable but not square enough.
- [x] Run the contract before production edits and confirm it fails for the expected narrow-grid reason.

## Task 3: Widen Battle Backpack Layout

**Files:**
- Modify the smallest runtime layout file shown by Task 1 and Task 2 evidence.

- [x] Adjust battle layout bounds so the backpack grid can use a square width.
- [x] If horizontal space is constrained, reduce the right sidebar width/ratio before touching gameplay or inventory behavior.
- [x] Preserve the anti-oscillation fix: no frame-by-frame reward padding reset and no horizontal scale breathing.

## Task 4: GREEN Verification

**Files:**
- Test: `app-LTL/tests/run_battle_backpack_visual_width_contract.gd`

- [x] Re-run the visual contract over 180 frames with screenshots.
- [x] Confirm width ranges remain stable and grid aspect/min-width assertions pass.
- [x] Run focused backpack compile/layout checks.
- [x] Run `git diff --check` on touched files.

## Result Notes

- RED evidence: before the square-grid fix, the live visual contract measured `backpackGridWidth=486`, `backpackGridHeight=493`, `backpackGridWidthShortfallMax=7`, `backpackGridAspectMaxDelta=0.014`, and all width ranges at `0`. This proved the bug was stable narrowness rather than a recurrence of the previous oscillation.
- Root cause: the combat pin shell side gutter could consume enough horizontal space that the internal `GridMock` became narrower than its rendered height. The panel width was stable, but the pin gutter had no cap tied to the internal grid's square requirement.
- Fix: cap combat pin shell side margins so they cannot shrink the grid below its current height. This reduced margins from `56` to `53` at the 1440x932 battle viewport.
- GREEN evidence: the 180-frame visual contract measured `backpackGridWidth=492`, `backpackGridHeight=493`, `backpackGridWidthShortfallMax=1`, `backpackGridAspectMaxDelta=0.002`, and all width ranges at `0`.
