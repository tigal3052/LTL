# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-16

## Active Work

Fix the reward-tray drop rendering regression: after dragging an item into the backpack grid on the reward list page, the reward-page backpack display can disappear even though the item is correctly placed when entering battle.

## Request Summary

The user reports that dropping an item from the reward list into the reward-page backpack grid makes the backpack image/display disappear. Since the following battle shows the item placed correctly, the inventory mutation path is likely correct and the reward-page render/refresh path is stale or cleared. The reward page must keep the shared backpack visible and immediately render the newly placed item after a successful drop.

## Scope

- Reproduce the reward-page drop scenario with a focused contract.
- Inspect reward-card drag/drop completion, backpack slot drop handling, inventory mutation, reward tray rerender, and shared backpack layout/image refresh.
- Fix the root cause without changing inventory placement rules or shared backpack ownership.
- Add/adjust automated checks proving:
  - after a successful reward drop, the shared backpack remains parented to the reward workspace host,
  - the grid remains visible and non-empty,
  - the newly placed artifact appears in the reward-page backpack immediately,
  - previously fixed reward idle drill centering and second-battle backpack return remain intact.
- Capture visual evidence if the local Godot runtime allows it.
- Preserve unrelated dirty/untracked workspace changes.

## Out Of Scope

- Redesigning the reward board, combat page, inventory model, or reward data.
- Changing drag/drop validity rules, cooldown semantics, non-image artifact box rendering, or item data.
- Reverting unrelated worktree changes.
- Replacing shared backpack with page-local backpack instances.

## Steps

- Inspect current reward drag/drop and shared backpack render paths.
- Add RED coverage for reward-page drop completion keeping the backpack visible and newly placed item rendered.
- Implement the smallest reward drop render/layout refresh fix.
- Run focused contracts, full contract runner, and `git diff --check`.
- Generate or collect visual evidence for reward drop state if possible.
- Update history and completion worklog with verification results and any unverified visual limitations.

## Expected Outputs

- Reward page backpack grid remains visible after a reward item is dropped into it.
- The newly placed reward item is rendered immediately on the reward-page shared backpack.
- Existing starter drill image remains centered and visible.
- The same shared backpack instance remains in use across reward and battle.
- Existing cooldown overlays, non-image item rendering, reward flow, and battle layout remain intact.

## Verification Method

- Focused RED/GREEN Godot contract for reward item drop render.
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_reward_claim_board_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_test_ui_read_models.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/run_reward_handoff_contract.gd`
- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/invoke-godot.ps1 -ProjectPath app-LTL -Headless -Script res://tests/godot_contract_runner.gd`
- `git diff --check`

## Plan Change Log

- 2026-06-16: Replaced the prior shared-backpack implementation completion plan with the follow-up regression plan for reward idle image drift and missing second-battle backpack.
- 2026-06-16: Replaced the previous follow-up plan with the reward-tray drag/drop render disappearance regression plan.
