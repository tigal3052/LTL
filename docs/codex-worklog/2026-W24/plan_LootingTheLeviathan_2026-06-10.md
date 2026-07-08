# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-10

## Active Work

Reward claim board polish for the tray-review page.

## Request Summary

Adjust the reward-board panels so the left reward cloud removes its helper copy, reward cards can be freely repositioned inside the panel without leaving its bounds, the docked backpack grid stays large and stable from first render, and the discard/confirm panels stop reserving blank lines that trigger unnecessary scrollbars.

## Scope

- Reward cloud copy and drag positioning behavior in `app-LTL/src/ui/MainViewRuntime.gd` and localized text catalogs.
- Docked backpack sizing and reward-board layout sync in `app-LTL/src/ui/MainViewRuntime.gd`.
- Reward-board layout contract coverage in `app-LTL/tests/test_reward_claim_board_contract.gd` and read-model copy assertions.

## Out of Scope

- Combat/top-content backpack layout outside the reward tray.
- Reward claim state transitions and inventory mutation rules.
- Unrelated workspace changes already present in the dirty tree.

## Steps

- Add or extend focused reward-board regression tests for helper-copy removal, docked backpack stability, and blank-scrollbar regressions.
- Update reward-board runtime logic to persist in-panel reward-card drop anchors and clamp card movement inside the cloud panel.
- Remove the reward-cloud helper copy and optional blank labels/titles that currently leave spacer rows in the discard/confirm panels.
- Re-run focused contracts and summarize the verified outcome.

## Expected Outputs

- Updated reward tray behavior and layout in the live Godot UI.
- Regression coverage for the reward claim board.
- Completion note with verification evidence.

## Verification Method

- Run the focused reward-board Godot contract runner.
- Re-check the read-model reward-board suite if copy keys change.
- Review the diff to ensure only the targeted reward-board files changed.

## Plan Change Log

- 2026-06-10: Worklog bootstrapped automatically by Codex hook.
- 2026-06-10: Replaced placeholder plan with reward-board drag/layout stabilization scope for the tray-review UI fixes.
