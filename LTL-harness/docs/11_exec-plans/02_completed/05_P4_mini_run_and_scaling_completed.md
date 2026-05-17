# P4 Completion Report

**Related active plan (kept in place)**: `docs/11_exec-plans/01_active/05_P4_mini_run_and_scaling.md`

## Completion Summary

- Delivered the P4 mini-run and scaling slice in `app-LTL`, extending the prototype from single-node combat into a staged loop with node selection, reward generation, and run completion.
- Implemented deterministic node generation, stage scaling, reward rolling, and a headless mini-run progression path that can be exercised without the browser.
- Connected the browser prototype to the mini-run phase flow so the player-facing demo can enter node selection, combat, reward handling, and subsequent stage progression.

## Actual Outputs

- `app-LTL/src/domain/node-generator.js`
- `app-LTL/src/domain/reward-resolver.js`
- `app-LTL/src/domain/stage-scaling.js`
- `app-LTL/src/domain/run-progression.js`
- `app-LTL/src/process/headless-mini-run.js`
- `app-LTL/src/process/mini-run-stage-script.js`
- `app-LTL/src/phases/node-select-phase.js`
- `app-LTL/src/phases/reward-loot-phase.js`
- `app-LTL/src/phases/reduce-mini-run-phase.js`
- `app-LTL/src/data/node-table.json`
- `app-LTL/tests/p4_mini_run.test.js`
- `app-LTL/public/index.html` and `app-LTL/src/ui/mini-run-app.js` (mini-run flow integration)

## Verification Results

- `node --test tests/p4_mini_run.test.js`
- `node --test tests/*.test.js`
- The current Node test suite verifies the intended P4 contract:
  - the normal node is always included and node offers are seed-stable
  - stage shield/health/time pressure scales with stage index
  - reward count rolls stay within the 1~5 contract
  - cleared weakness biases reward colors upward
  - a 5-stage mini-run loops through node select -> combat -> reward -> next stage -> run complete
- This session did not re-run dedicated manual browser QA, so the browser-facing completion claim is based on the integrated code path and automated regression coverage rather than a fresh visual walkthrough.

## Changes From Plan

- The active plan described a 3-stage validation target, but the implemented and tested progression path uses `maxStages = 5` in the current browser/headless prototype.
- The plan expected future Godot `.gd` deliverables, while the actual milestone completion remains in JavaScript/Node to keep the prototype deterministic and testable in the current environment.
- The reward output remains a prototype reward schema (`kind`, `color`, `qty`) rather than the redesigned artifact/progression reward JSON that M0 later decided on.

## Remaining Gaps

- The current P4 reward contract must be redesigned in M1 to match the post-M0 decisions:
  - artifact reward JSON
  - rarity tiers
  - sell value
  - leviathan/progress integration
- The 5-stage prototype loop was later reclassified at M0 as a test-scale mini-run rather than the final Leviathan-driven run structure.
- Browser SoT, replay promotion, and loader/validator contracts still need to be formalized before Godot-side implementation can safely begin.
