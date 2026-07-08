# Codex Worklog Plan

Workspace: LootingTheLeviathan
Date: 2026-06-13

## Active Work

Refine the separated battle HUD mockups so the energy queue feels more like a wave/pulse system, and reshape the information panel into an A-line layout that clearly separates neutral base terrain, single-weakness terrain, and dual-weakness composite terrain.

## Request Summary

The user wants another refinement pass. The queue page should lean harder into wave, pulse, and heartbeat imagery instead of reading primarily as structural cartridges or frames. The information panel should keep the earlier A-like structure, but the multiplier dots must be fixed semantically: health uses a red circular marker and shield uses a blue circular marker in every state. The three state examples also need clearer roles: state 1 stays neutral base terrain, state 2 becomes a single-weakness terrain example with only one weakness tile shown, and state 3 remains the composite-terrain example that shows two weakness colors together.

## Scope

- Rebuild the queue-only mockup with three more original concepts that emphasize wave/pulse imagery while still deriving their language from the supplied assets.
- Rebuild the info-panel mockup into an A-like layout that demonstrates neutral base terrain, single-weakness terrain, and dual-weakness composite terrain.
- Keep secondary combat notes to a single inline strip inside the main multiplier panel.
- Keep the work limited to static mockup artifacts, browser verification, and worklog updates.

## Out Of Scope

- Editing live Godot runtime scenes or scripts.
- Changing combat logic, queue behavior, or scene layout in-engine.
- Browser automation or live rendering capture unless separately requested.

## Steps

- Translate the tile frame, drill segmentation, and leviathan vein motifs into original queue component patterns with stronger oscillograph, pulse-lane, and heartbeat cues.
- Rebuild the queue mockup as three two-row queue concepts with explicit 8-slot inactive-row and 16-slot fully active-row states.
- Rebuild the information-panel mockup around one stronger A-line direction with state examples for base terrain, single-weakness terrain, and composite terrain.
- Verify both files in the browser and with file-level section checks, then update worklog history/completion.

## Expected Outputs

- Updated `docs/mockups/2026-06-13-battle-hud-energy-queue-variants.html`
- Updated `docs/mockups/2026-06-13-battle-hud-info-panel-variants.html`
- Updated dated worklog plan/history/completion entries for the revised mockup request

## Verification Method

- Confirm the queue mockup contains three variants, a two-row structure, and explicit 8-slot inactive-row vs 16-slot active-row states without direct per-slot tile-image reuse.
- Confirm the information-panel mockup shows neutral base-terrain handling with no specific weakness tile, single-weakness handling with one tile, and composite-terrain handling with two weakness tiles displayed together.
- Confirm the information-panel mockup compresses secondary facts into a single inline strip inside the multiplier section.
- Verify both files visually in the in-app browser and confirm they were updated successfully in the workspace.

## Plan Change Log

- 2026-06-13: Replaced the unrelated bootstrapped harness plan with the battle HUD separated mockup task.
- 2026-06-13: Re-scoped the task again to enforce two-row queue visuals and card-plus-tag information panels based on the attached asset references.
- 2026-06-13: Re-scoped the mockups again to avoid literal tile reuse in the queue and to add dynamic base/composite terrain weakness handling in the information panel.
- 2026-06-13: Re-scoped the mockups again to push the queue toward stronger pulse imagery and to split the information panel into base, single-weakness, and composite terrain examples.
