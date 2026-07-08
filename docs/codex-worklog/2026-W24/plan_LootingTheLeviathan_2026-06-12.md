# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-12

## Active Work

Prepare approval-first battle HUD mockups for the requested combat layout restructuring, then wait for sign-off before any Godot implementation begins.

## Request Summary

Redesign the battle HUD so the page reads as left status panel, center backpack battlefield, and right tabbed panel. Move `탐사자 상태` into the right panel as the default tab, keep `시스템 로그와 정보` as an optional reference tab, expand `드릴 및 노드 상태` upward to reclaim the removed left panel space, replace the current `지금/다음/예비` queue summary with FIFO slot queues that support minimum 8 slots and maximum 16 slots in 2-slot growth steps, remove the stage time-limit display while preserving drill state and combat timer, and present node weakness/strength details as high-visibility multiplier-focused cards or tags with node info above the live combat metrics. Before runtime edits, prepare richer separated mockups for the queue and the drill/node status panel plus a written drill-placement idea pass.

## Scope

- Update today's plan/history to reflect the battle-HUD approval-first flow.
- Create dedicated HTML mockups that separate the queue redesign from the drill/node status panel redesign, and include more polished multi-option visual directions.
- Capture written placement ideas for the drill image without implementing them yet.
- Defer all Godot scene/script/test edits until the user approves the mockup direction.

## Out Of Scope

- Editing `BattlePage`, `GameplayTopContent`, `StatusPanelUI`, or shared runtime code before approval.
- Claiming the combat HUD redesign is implemented or verified in Godot.
- Touching unrelated dirty-tree work.

## Steps

- Inspect the current battle scene structure, status/queue read models, and existing mockup conventions.
- Produce focused HTML approval mockups under `docs/mockups/` with separated queue and status-panel sections, including 8-slot and 16-slot FIFO versions and three style directions.
- Summarize the intended implementation path and drill-image placement ideas alongside the mockup.
- Wait for approval or revision notes before invoking implementation planning/execution.

## Expected Outputs

- Updated worklog plan/history for the approval-first battle HUD request.
- New HTML mockup artifacts for the battle HUD queue and drill/node panel redesign, including an advanced v2 with three design directions.
- A concise approval checkpoint summary listing the locked layout, queue, and node-info direction plus drill-image ideas.

## Verification Method

- Visual inspection of the generated HTML mockup files.
- User approval of the mockup before any runtime code changes.

## Plan Change Log

- 2026-06-12: Replaced the earlier character-select cleanup plan with an approval-first node-select redesign mockup plan.
- 2026-06-12: Re-scoped the active work again to an approval-first battle HUD redesign mockup covering queue, tabbed right panel, node multiplier cards, and drill-placement ideas.
- 2026-06-12: Expanded the mockup scope again to cover FIFO 8-slot and 16-slot queues, node-info-first vertical ordering, preserved drill-state/timer display, and three more production-grade style proposals.
