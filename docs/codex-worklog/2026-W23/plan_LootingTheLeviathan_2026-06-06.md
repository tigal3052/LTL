# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-06

## Active Work

Refine the image-first M6 mockups after user review by improving map readability, panel alignment, and start-page proportions.

## Request Summary

Adjust three existing HTML mockups after review feedback: flip the node-map reading direction, redraw its route language closer to Slay the Spire's branching dotted paths, restore the red discard zone and alignment consistency in reward-claim, and narrow the run-start character selector while expanding the main hero panel and moving the start CTA under the relic/backpack zone.

## Scope

- Update today's worklog to reflect the focused refinement request.
- Rework `docs/mockups/m6-node-select-run-flow-wireframe.html` so the map reads bottom-to-top and uses wavy dotted paths with arrow cues inspired by Slay the Spire route readability.
- Adjust `docs/mockups/m6-reward-claim-wireframe.html` so the discard zone is visibly red again and the backpack panel bottom alignment matches neighboring panels.
- Adjust `docs/mockups/m6-run-start-wireframe.html` so the character selector becomes a narrow scrollable list, the central hero panel becomes wider, and the start CTA moves under the relic/backpack zone.
- Keep the work strictly in documentation/mockup artifacts.

## Out of Scope

- Godot runtime code changes
- Additional redesigns for `event_node`, `boss_reward_pick`, or `defeat`
- Gameplay balance or data tuning
- Git actions

## Steps

1. Refresh today's worklog so the plan matches the review-driven refinement request.
2. Update `node_select` route direction and path visuals using the approved “current LTL tone plus STS-like route grammar” approach.
3. Update `reward_claim` discard styling and panel alignment without changing its click-to-inspect and drag-to-place behavior note.
4. Update `run_start` proportions, selector scrolling, and CTA placement.
5. Verify the requested structure and wording in the edited files.
6. Update the completion report honestly.

## Expected Outputs

- `docs/mockups/m6-node-select-run-flow-wireframe.html`
- `docs/mockups/m6-reward-claim-wireframe.html`
- `docs/mockups/m6-run-start-wireframe.html`
- Updated `docs/codex-worklog/*_LootingTheLeviathan_2026-06-06.md`

## Verification Method

- Targeted `rg` or `Select-String` checks for the new route-direction labels, discard styling text, and start-page CTA placement notes
- `git diff --check` on the edited mockup files

## Plan Change Log

- 2026-06-06: Narrowed the work from the broader phase-first pass to the single event-node wireframe task requested in that turn.
- 2026-06-06: Retargeted the plan to an image-first redesign of five existing mockup pages after the user rejected text-heavy component boards.
- 2026-06-06: Retargeted again to a smaller refinement pass focused on node-map readability, reward-claim alignment, and run-start proportions after the user approved the “current tone + STS-like route grammar” approach.
