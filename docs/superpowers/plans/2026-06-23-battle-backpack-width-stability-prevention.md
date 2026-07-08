# Battle Backpack Visual Width Oscillation Recovery Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reproduce, diagnose, and fix the battle backpack's visible horizontal expand/shrink loop, then add prevention only after the rendered issue is proven fixed.

**Architecture:** Treat the bug as a rendered visual instability first, not only a layout-tree invariant. The investigation must compare multiple screenshots or viewport captures over 2-3 seconds, correlate the pixel width with the responsible UI node widths, and only then change the minimal runtime code.

**Tech Stack:** Godot 4.3 GDScript, existing `tools/invoke-godot.ps1`, temporary visual probe scripts, and final focused Godot contract coverage.

---

## Task 1: Roll Back Failed Harness Changes

**Files:**
- Delete: `app-LTL/tests/run_battle_backpack_width_stability_contract.gd`
- Modify: `tools/run-ltl-quality-gate.ps1`
- Modify: `app-LTL/tests/ui_read_models/ui_backpack_layout_suite.gd`

- [x] Remove the previous width-stability contract file.
- [x] Remove the previous quality-gate async runner and battle backpack width-stability invocation.
- [x] Remove the narrow source-level tests that were added only for the failed width-stability attempt.
- [x] Keep unrelated user/worktree changes intact.

## Task 2: Build A Temporary Visual Probe

**Files:**
- Create temporarily: `app-LTL/tests/tmp_battle_backpack_visual_width_probe.gd`

- [x] Boot the real `Main.tscn` flow into battle.
- [x] Capture viewport images for at least 2-3 seconds after the battle page is visible.
- [x] Measure the rendered backpack image/grid width per captured frame using pixel bounds in the backpack region.
- [x] Also log correlated node widths for `BackpackUI`, `Margin`, `GridMock`, `SharedBackpackHost`, and the battle page phase.
- [x] Save sample screenshots only under a temporary output directory.

## Task 3: RED Reproduction

**Files:**
- Temporary probe only.

- [x] Run the temporary probe before production edits.
- [x] Require a measurable width range or alternating growth/shrink pattern before changing runtime code.
- [x] If the probe does not reproduce the user-visible bug, refine the capture region/timing until it observes the same rendered width movement.

## Task 4: Root Cause Fix

**Files:**
- Modify only the runtime file(s) shown by Task 3 evidence.

- [x] Trace the changing rendered width back to the exact layout or scale value that moves.
- [x] State one hypothesis and test the smallest code change that would remove that feedback loop.
- [x] Avoid unrelated reward, combat, VFX, audio, or action-bar edits.

## Task 5: GREEN Verification And Harness Promotion

**Files:**
- Create or update final focused harness only after Task 4 passes.
- Modify quality-gate wiring only after the final harness is stable.

- [x] Re-run the visual probe for the same duration and viewports.
- [x] Confirm rendered width range is within tolerance and direction changes are gone.
- [x] Promote the probe into a final named regression contract.
- [x] Wire the final contract into the quality gate only after it passes repeatedly.
- [x] Run `git diff --check` on touched files.

## Result Notes

- RED evidence: windowed visual sampling reproduced the user-visible loop with `backpackGridPixelRange=80`, `backpackGridPixelTurns=11`, `backpackGridRange=80`, `backpackGridTurns=11`, and `battleBackdropDrawnRange=26.91`.
- Root cause: battle renders called `set_reward_workspace_title_state(false)` through reward backpack docking even when the backpack was not in the reward host, resetting reward workspace padding/gutter state during combat. The combat pin pass then restored the pin gutter, producing repeated visible wide/narrow frames.
- Secondary visual source: `BattlefieldUI` also animated `battle_backdrop.scale` horizontally with a sine wave.
- GREEN evidence: final windowed contract sampled 180 battle frames and printed `BATTLE_BACKPACK_VISUAL_WIDTH_CONTRACT_OK` with all measured backpack/grid/backdrop width ranges at `0`.
