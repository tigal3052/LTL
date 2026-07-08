# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-03

## Active Work

Implement and verify the newly requested gameplay/UI balance pass: remove residual hazard color borders, mark the four basic drill/beacon pairs as discovered in the codex, unify backpack layout policy so reward/backpack views stop resizing inconsistently, restrict hazard families to the selected node colors, and rebalance queue/cooldown/terrain-energy tempo around a doubled queue.

## Request Summary

- Remove the remaining colored outer border from hazard tiles.
- In the codex, mark the basic red/blue/green/purple drills and beacons as already discovered.
- Refactor backpack sizing so the reward-view backpack and reward-drop backpack use one shared layout source instead of diverging.
- Restrict hazard spawns to only the colors present on the selected terrain/node weakness set.
- Double the energy queue and rebalance drill/beacon cooldowns, cooldown reduction, and initial terrain-energy density so the action tempo is faster without increasing total combat time.

## Scope

- Remove the hazard-border draw path from battlefield cell rendering.
- Expand codex starter discovery handling to include the four basic drill/beacon color pairs.
- Move backpack sizing logic behind a single shared layout policy and remove the current feedback-loop sizing source for top-content reward/backpack states.
- Carry selected terrain colors into combat hazard spawning so only matching hazard families appear.
- Rebalance queue capacity, cooldown pacing, cooldown-reduction strength, and initial terrain-energy density for a faster click tempo within the same time limit.
- Run focused combat/UI/reward verification and keep today's worklog aligned with the resulting implementation.

## Out of Scope

- Reworking unrelated M5/M6 milestone items or reverting unrelated user changes already present in the dirty tree.
- Changing the overall combat time limit or extending the total play-session duration for this pass.
- Replacing the reward ceremony visual language beyond the backpack layout-policy refactor needed for consistency.

## Steps

- Lock the requested behavior with focused UI/combat/reward tests before editing runtime code.
- Refactor shared backpack layout policy so node-select and top-content reward/backpack sizing delegate to one source of truth.
- Implement hazard border removal, codex starter discoveries, terrain-colored hazard spawning, and doubled queue tempo pacing.
- Run focused verification and update worklog history/completion notes.

## Expected Outputs

- Updated battlefield rendering with hazard overlays but no extra colored border frame
- Codex discovery state that always reveals the four basic drill/beacon pairs
- Shared backpack sizing policy eliminating reward/backpack layout drift
- Combat runtime restricted to terrain-matching hazard families
- Faster queue/cooldown/terrain-energy tempo with unchanged combat time limit
- Focused verification notes for combat logic and UI helper behavior

## Verification Method

- Focused Godot verification for `test_combat_vocab.gd`, `test_ui_read_models.gd`, and `test_reward_contract.gd`
- `git diff --check` on the resulting tree

## Plan Change Log

- 2026-06-03: Re-scoped the active plan from the earlier hazard-only pass to a broader gameplay/UI consistency pass after the new five-point user request.
- 2026-06-03: Clarified that doubled queue tempo should increase click density while preserving the existing combat time limit.
