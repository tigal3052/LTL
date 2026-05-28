# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-05-29

## Active Work

Fix follow-up combat readability QA issues: purple terrain debuffs should be presented as a global drill/node status instead of per-tile markings, and battlefield cells matching the current queue color should be highlighted for easier targeting.

## Request Summary

- `weakened_terrain` is still represented visually on individual cells, but the user expects it in the drill/node status as a global combat debuff.
- Current queue gems are far from the 3x10 battlefield, making same-color tile selection visually tiring.

## Scope

- Add regression tests for global terrain debuff projection and active queue color cell matching.
- Move terrain debuff projection from per-cell data to HUD/global status data.
- Render global terrain debuff count in the drill/node status panel.
- Highlight cells whose weakness color matches the active queue energy.

## Out of Scope

- No full balance pass beyond the requested color identity rules.
- No new art assets for the parchment panel.
- No broader combat node generation redesign.

## Steps

- Write failing scene-model tests for active queue highlight and global debuff placement.
- Update combat debuff data to aggregate as a global `weakened_terrain` stack.
- Update `CombatSceneModel`, `StatusPanelUI`, and `CellView` to use the new presentation contract.
- Run Godot contract checks, i18n gate if text keys change, and `git diff --check`.

## Expected Outputs

- Drill/node status shows global weakened-terrain stack count.
- Battlefield cells matching the current queue color are visibly highlighted.
- No per-cell purple debuff marker remains.
- Updated worklog and verification notes.

## Verification Method

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- `git diff --check`

## Plan Change Log

- 2026-05-29: Worklog bootstrapped automatically by Codex hook.
- 2026-05-29: Re-scoped to follow-up M4 UI QA: cooldown mask smoothing, purple debuff readability, and item label cleanup.
- 2026-05-29: Re-scoped to global terrain debuff status and active queue color tile highlighting.
