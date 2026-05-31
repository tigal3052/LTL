# Release Visual Quality Upgrade Plan

Workspace: LootingTheLeviathan
Date: 2026-05-29

## Goal

Raise the current UI and presentation layer from prototype readability to release-candidate quality without changing the core phase flow.

## Current Quality Gaps

- Node-select composition still depended too heavily on runtime proportions instead of a deterministic presentation grid.
- Backpack readability was being undermined by cooldown darkness and interaction-material conflicts.
- Header, shop, and action buttons had no stable sizing system, so adjacent controls read as unrelated widgets.
- Reward reveal had payoff but not enough anticipation: silhouette timing was short and rarity did not roll before landing.
- The shell still lacks authored background plates, illustrated panel surfaces, bespoke iconography, and audio-backed reward feedback.

## Design Direction

- Readability first: every phase should explain itself at a glance before adding spectacle.
- Tactile feedback second: hover, press, drag-valid, drag-blocked, disabled, and repair-locked states must feel different.
- Anticipation third: reward payoff should escalate in beats instead of revealing the answer immediately.
- Art last, not art-only: external assets should land on top of a stable layout system instead of hiding rough structure.

## Immediate Fixes In This Pass

- Rebalanced combat/reward/top-content ratios so the backpack gets the dominant width.
- Tightened node-map chip spacing and moved route detail below the graph to stop overlap and alignment drift.
- Added a stable shell button width system for header and action controls.
- Prevented shader-material affordances from overriding stylebox-rendered backpack slot panels.
- Blocked combat clicks while repair is active or aim is locked, preventing overload from being retriggered by stale input.
- Added a silhouette pause plus rarity-roll phase to the reward reveal timeline.

## Asset Production Plan

### Phase 1: Shell And Layout Art

- `resources/release/ui/backgrounds/app_shell_bg.webp`
- `resources/release/ui/backgrounds/node_select_bg.webp`
- `resources/release/ui/panels/panel_shell_frame_01.9.png`
- `resources/release/ui/panels/panel_shell_inset_01.9.png`
- `resources/release/ui/panels/log_frame_01.9.png`
- `resources/release/ui/buttons/button_primary_01.9.png`
- `resources/release/ui/buttons/button_secondary_01.9.png`
- `resources/release/ui/buttons/button_danger_01.9.png`

Integration targets:

- `app-LTL/src/ui/MainViewRuntime.gd`
- `app-LTL/src/ui/ShopPanelUI.gd`
- `app-LTL/src/ui/StatusPanelUI.gd`
- `app-LTL/src/Main.tscn`

### Phase 2: Gameplay Surface Art

- `resources/release/ui/backpack/backpack_border_atlas.png`
- `resources/release/ui/backpack/backpack_slot_inner.png`
- `resources/release/ui/backpack/backpack_slot_charge_mask.png`
- `resources/release/ui/node_map/node_safe.png`
- `resources/release/ui/node_map/node_medium.png`
- `resources/release/ui/node_map/node_danger.png`
- `resources/release/ui/node_map/node_unknown.png`
- `resources/release/ui/node_map/route_glow_strip.png`
- `resources/release/ui/combat/weakness_marker_strip.png`

Integration targets:

- `app-LTL/src/ui/presenters/BackpackGridFactory.gd`
- `app-LTL/src/scenes/node_map/NodeMapScene.gd`
- `app-LTL/src/ui/CellView.gd`

### Phase 3: Reward Reveal Package

- `resources/release/vfx/reward/reveal_core_ring.webp`
- `resources/release/vfx/reward/reveal_burst_strip.webp`
- `resources/release/vfx/reward/reveal_smoke_strip.webp`
- `resources/release/ui/reward/reward_card_frame_common.9.png`
- `resources/release/ui/reward/reward_card_frame_rare.9.png`
- `resources/release/ui/reward/reward_card_frame_epic.9.png`
- `resources/release/audio/ui/reward_rumble_01.ogg`
- `resources/release/audio/ui/reward_roll_01.ogg`
- `resources/release/audio/ui/reward_land_01.ogg`

Integration targets:

- `app-LTL/src/ui/BattlefieldVFX.gd`
- `app-LTL/src/ui/BattlefieldUI.gd`
- `app-LTL/src/ui/read_models/RewardReadModel.gd`

## External Asset Strategy

- Keep interaction motion patterns sourced from shader techniques similar to GodotShaders hover, ripple, and pointer-glow examples.
- Prefer licensed drop-in UI kits, 9-slice frames, VFX sprite sheets, and authored background illustrations over more procedural placeholder chrome.
- Only adopt external art/audio that can be redistributed with the project license; otherwise keep the code hooks and path contracts ready for local commercial assets.

## Quality Bar Checklist

- Every phase has a background layer, panel frame language, and icon family.
- All action buttons share stable height, padding, and minimum width rules.
- Backpack slots remain readable at idle with no hidden information only revealed by hover.
- Reward reveals land in three beats: rumble, silhouette suspense, rarity roll, final item reveal.
- Click-blocked states are visibly and mechanically blocked together.
- No panel looks like raw debug text pasted into an empty rectangle.

## Verification For The Next Art Drop

- Re-run `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-compile-check.ps1`
- Re-run `git diff --check`
- Capture fresh node-select, combat, reward-loot, and settings screenshots after each asset drop
- Confirm text fit and button widths at 1440x900 and at one narrower fallback resolution
