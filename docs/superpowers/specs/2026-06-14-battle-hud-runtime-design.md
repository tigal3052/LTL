# Battle HUD Runtime Design

Date: 2026-06-14
Workspace: `D:\Programming\ex_workspace\LootingTheLeviathan`

## Goal

Apply the approved June 12-13 battle HUD mockups to the real Godot battle runtime so the live combat page matches the chosen side-panel layout, queue treatment, and terrain info hierarchy.

## Approved Direction

This document treats the previously approved mockups as the design source of truth:

- `docs/mockups/2026-06-12-battle-hud-queue-status-mockup-v2.html`
- `docs/mockups/2026-06-13-battle-hud-energy-queue-variants.html`
- `docs/mockups/2026-06-13-battle-hud-info-panel-variants.html`

No additional concept exploration is required before implementation unless the runtime exposes a hard technical constraint that prevents faithful mapping.

## Layout

The combat HUD keeps a left / center / right structure:

- Left: always-on `드릴 및 노드 상태`
- Center: backpack combat board
- Right: tabbed reference sidebar

The old standalone left explorer panel is removed. Its vertical space is given to the left drill/node panel so that node facts, bars, queue, drill state, and footer timer fit in one stronger status surface.

## Right Sidebar Tabs

The right sidebar becomes a two-tab panel:

- Default tab: `탐사자 상태`
- Secondary tab: `시스템 로그와 정보`

The default open state must always be `탐사자 상태`, because the user considers character presence primary and logs/reference data secondary. The log/info tab is only opened when the player wants supplemental information.

## Explorer Status Tab

The default tab includes:

- portrait / character art
- short character summary
- current loadout summary

This content moves from the old left explorer panel into the right sidebar. The content should remain lightweight and readable, not a dense stat sheet.

## Drill / Node Status Panel

The left panel remains the always-on combat decision surface. It should contain:

- current node name / node summary first
- target health and shield bars
- approved FIFO energy queue
- drill state
- footer timer

The stage-limit presentation is removed from the body of the panel. The large footer timer stays, because it is part of the approved HUD rhythm. The mislabeled progress row should no longer read as stage time limit.

## Energy Queue

The queue follows the approved final direction:

- FIFO only
- no `지금 / 다음 / 예비` role split
- no middle gaps
- two-row layout
- 8-slot and 16-slot states use the same structure
- expanded capacity is communicated by activating the lower row rather than changing component shape

Visual intent:

- slot faces use a thicker waveform/pulse treatment inspired by the center line of the terrain tiles
- filled slots show energy color clearly
- inactive capacity slots remain visibly locked / dormant

Runtime contract:

- row 1 = slots 1-8
- row 2 = slots 9-16
- capacity below 16 keeps later slots visually disabled

## Info Tab

The `시스템 로그와 정보` tab combines:

- system log output
- node information
- terrain weakness / multiplier reference

The layout priority inside this tab is:

1. current node / terrain combat info
2. compact multiplier cards
3. short tag row for extra statuses such as reward bias, risk, or recommended hint
4. scrollable log text

## Terrain Info Rules

The information panel must respect three terrain states:

### Neutral / common terrain

- no specific weakness tile
- show shared shield/health multipliers only
- do not show a colored weakness tile

### Single-weakness terrain

- show one weakness tile color
- show one weakness card
- that card contains two mini cards:
  - `주 공략 기준 실드 배율`
  - `주 공략 기준 체력 배율`

### Composite terrain

- show two weakness colors
- each color gets its own weakness card
- each color card contains its own shield and health multiplier mini cards
- do not show a single shared “main” multiplier summary for the whole composite terrain

This prevents the composite case from implying one global multiplier when each weakness color has different effectiveness.

## Data Flow

The runtime already has most of the source data:

- node tables expose `weakness`, `shieldMul`, `healthMul`, `rewardBias`, `recommendedBuildHint`
- combat snapshots already carry selected node metadata through `combat.node`

Implementation should surface that data through the combat scene / HUD read-model path rather than inventing a second source of truth.

Preferred path:

- combat snapshot / selected node context
- `CombatSceneModel`
- `HudReadModel` or a nearby sidebar-specific projection
- sidebar UI renderer

## Testing

Implementation must be test-first on the existing Godot UI contract suite:

- update scene/layout assertions for the new shell structure
- update queue assertions so the old 3-column role hub is no longer the expected contract
- add projection assertions for terrain info states

## Constraints

- respect the existing shared page-shell/runtime architecture
- do not revert unrelated dirty worktree changes
- preserve reward/runtime flows that share the top-content shell unless a targeted compatibility update is included
