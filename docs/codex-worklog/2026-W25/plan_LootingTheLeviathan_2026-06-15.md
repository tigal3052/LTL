# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-15

## Active Work

Fix idle-state drill image alignment in the reward-list backpack while preserving the drag-state alignment that already works.

## Request Summary

The user reports that image-backed drills align correctly while another item is being dragged, but in the normal idle state after releasing the mouse the image is displayed left of the backpack grid center again. Combat-page placement and drag-state placement must remain correct; idle reward-list placement must keep the image centered in its assigned grid slot/footprint.

## Scope

- Inspect idle versus drag image positioning paths in `BackpackUI` and `BackpackArtifactRenderer`.
- Add focused RED coverage for idle image rect anchoring/centering after release or no held artifact.
- Adjust only image overlay placement, refresh, or anchoring logic needed for idle state.
- Preserve the existing background removal, cooldown overlay behavior, non-image square rendering, drag-state alignment, and combat-page placement.
- Preserve unrelated dirty/untracked workspace changes.

## Out Of Scope

- Changing reward vocabulary, combat logic, inventory placement rules, or controller flow.
- Changing non-image item rendering.
- Removing or changing cooldown timing semantics.
- Reverting unrelated dirty/untracked workspace changes.
- Broad UI redesign of the reward board or combat page.

## Steps

- Read the current idle image overlay path, drag ghost path, and reward/backpack image tests.
- Reproduce or isolate the idle-only offset with a focused test or diagnostic.
- Add/adjust RED coverage that proves idle item image center equals the assigned slot center.
- Implement the smallest image overlay fix that makes idle and drag positioning use compatible geometry.
- Run focused Godot contracts, full contract runner, and `git diff --check`.
- Update history and completion worklog entries with results.

## Expected Outputs

- Reward-list basic drill images remain centered inside their backpack grid slot/footprint in idle state and while dragging other items.
- Combat-page drill placement remains unchanged.
- Image-backed drills still show item art without colored artifact background overlay.
- Cooldown masking still appears above image-backed artifacts when enabled.
- Non-image artifacts keep the current colored box presentation.

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_test_ui_read_models.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_reward_claim_board_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/godot_contract_runner.gd`
- `git diff --check`

## Plan Change Log

- 2026-06-15: Replaced stale 500-line split plan with the active idle-state reward backpack drill image alignment bugfix.
