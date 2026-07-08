# Backpack Pin Layout And Removal VFX

Date: 2026-06-01
Workspace: `LootingTheLeviathan`

## Goal

Fix the combat-phase backpack corner pins so they behave like physical pins attached to the backpack shell:

- keep the backpack grid image size unchanged
- widen only the backpack panel shell left and right by the pin overhang amount
- let the left and right side panels absorb the remaining width change
- place `pin_1`, `pin_2`, `pin_3`, and `pin_4` at the four backpack corners without excessive grid intrusion
- remove pins in the requested order: `pin_1 -> pin_2 -> pin_3 -> pin_4`
- make each removal readable through a restrained local pull-out VFX

## Current Problems

The current implementation splits the feature between panel sizing and pin placement, but the two parts do not agree on the same geometry.

- `MainViewRuntime.gd` widens the top-content backpack container by a broad ratio based on the whole grid baseline.
- `BackpackUI.gd` sizes pin art from the full grid extent and places each pin with a `50%` overlap against the corner anchor.
- The widened container does not create a dedicated inner shell gutter around `GridMock`, so the extra width does not become usable pin space.
- Pin visibility currently keeps the first `N` pins visible, which removes pins from the end of the list instead of removing `pin_1`, then `pin_2`, then `pin_3`, then `pin_4`.
- Pin disappearance currently reads as a state change, not as a physical object being pulled out.

## Approved Direction

Use `Option A: grounded local pin effect`.

The effect should feel like a small piece of hardware being pulled from the backpack shell. It should be clear, tactile, and local. It should not shake the whole screen or disturb item readability inside the grid.

## Research Notes

Implementation mechanics should follow Godot's existing UI animation primitives:

- Godot `Tween` supports short property animation through `create_tween()`, matching the repo's current UI tween patterns.
- Godot `CanvasItem` exposes `z_index` and top-level drawing behavior that suit a highest-layer pin overlay.
- Godot 2D particles can provide small one-shot dust or metal fleck bursts if the first implementation needs stronger readability.

General game animation guidance supports a small anticipation beat before the release and a short follow-through after the object leaves. For this UI-scale event, that translates to a brief inward lean/compress before an outward diagonal pull, rotation, and fade.

References:

- https://docs.godotengine.org/en/4.0/classes/class_tween.html
- https://docs.godotengine.org/en/4.0/classes/class_canvasitem.html
- https://docs.godotengine.org/en/4.4/tutorials/2d/particle_systems_2d.html
- https://www.gamedeveloper.com/production/the-12-principles-of-animation-in-video-games
- https://mocaponline.com/blogs/mocap-news/animation-polish-game-feel-guide

## Layout Design

`MainViewRuntime.gd` remains responsible for the outer top-content sizing policy.

- Keep `BackpackContainer` fixed-width and centered inside the top row.
- Compute backpack top-content width as the grid baseline plus left and right pin overhang.
- Keep side panels as expand-fill controls so they shrink or grow around the fixed backpack panel.
- Replace the broad full-grid `30%` extra width policy with a slot-scaled overhang policy that matches the actual pin presentation size.

`BackpackUI.gd` owns the local pin geometry.

- Derive pin display size from the corner slot size, not from the whole backpack grid extent.
- Treat the widened shell as the space where the pin can sit.
- Keep `GridMock` visually the same size.
- Place each pin at its requested outer corner:
  - `pin_1`: left of slot `1`, top-left corner
  - `pin_2`: right of slot `3`, top-right corner
  - `pin_3`: right of slot `9`, bottom-right corner
  - `pin_4`: left of slot `7`, bottom-left corner
- Use a smaller grid overlap than the current `50%` whole-pin overlap. The pin may cross the grid edge enough to read as attached, but most of the art should live in the shell gutter.
- Keep pin `z_index` above backpack slots, item overlays, cooldown masks, and drag feedback.

The pin art has large transparent source bounds, so all layout math should use the intended display rectangle and slot-scaled sizing rather than raw image dimensions.

## Removal Order Design

Keep the existing texture and corner mapping order:

1. `pin_1`: top-left
2. `pin_2`: top-right
3. `pin_3`: bottom-right
4. `pin_4`: bottom-left

Change the visibility policy from "show the first visible count" to "show the last visible count".

Expected mapping:

- `visible_count = 4`: show `pin_1`, `pin_2`, `pin_3`, `pin_4`
- `visible_count = 3`: show `pin_2`, `pin_3`, `pin_4`
- `visible_count = 2`: show `pin_3`, `pin_4`
- `visible_count = 1`: show `pin_4`
- `visible_count = 0`: show none

This gives the requested removal order while preserving each pin's corner identity.

## Removal VFX Design

The removal effect starts inside `BackpackUI.update_pin_overlays()` when the computed visible count drops.

For each removed pin:

- run a short anticipation beat, about `40-60 ms`
- lean or compress inward by a small amount, about `0.96-0.98` scale and `4-6` degrees of counter-rotation
- pull outward along that corner's diagonal for about `90-140 ms`
- move about `12-20%` of the displayed pin size
- rotate in the pull direction by about `8-14` degrees
- fade alpha to `0`
- hide and reset the pin after the tween finishes

Optional local feedback:

- a `1-2 px` nudge or tint pulse on a small corner shell target near the vacated pin
- `4-8` tiny warm dust or metal flecks, fading within `0.2-0.35 s`

Avoid these effects:

- whole-screen shake
- full backpack shake
- wobbling the remaining pins
- moving inventory slots or item overlays
- bright magical bursts that compete with item readability

## Component Ownership

`MainViewRuntime.gd`

- Owns top-content backpack width and ratio helpers.
- Keeps side panels as the flexible width absorbers.
- Does not know individual pin anchor positions.

`BackpackUI.gd`

- Owns pin texture nodes, corner specs, sizing, placement, visibility order, and removal VFX.
- Tracks the previous visible pin count so drops can trigger VFX exactly once.
- Resets all pin transforms when phase changes or layout refreshes require a clean state.

`Main.tscn`

- Should only change if a small scene-level margin or container adjustment is necessary.
- Prefer script-owned pin geometry first, because the behavior is specific to the backpack pin overlay.

`MainControllerRuntime.gd`

- Does not need to own pin VFX unless the backend later emits explicit per-pin removal events.
- Existing HUD `pin.progress` remains the source for count calculation.

## Data Flow

1. Combat scene snapshot exposes `phase` and `hud.pin.progress`.
2. `MainViewRuntime.render_scene()` forwards the scene to `BackpackUI.update_pin_overlays()`.
3. `BackpackUI.pin_visible_count()` maps combat progress to `4`, `3`, `2`, `1`, or `0`.
4. `BackpackUI` compares the new count with the previous count.
5. Any newly removed pin index is animated through the pull-out VFX.
6. The remaining visible pins are laid out in their stable corner positions.
7. Non-combat phases hide pins cleanly and reset transient VFX state.

## Error Handling And Reset Behavior

- If pin textures or grid slots are missing, fail gracefully by hiding the affected pin.
- If the grid size is zero during an early layout pass, skip layout and retry through existing deferred layout calls.
- If progress increases again because of a new combat setup, restore all required pins without replaying removal VFX.
- If multiple pins are removed between snapshots, animate each removed pin in the correct sequence. Staggering is allowed only if it remains short and clear.
- If a resize happens during an active removal tween, remaining pins should relayout normally; the removed pin can complete its tween from the current displayed position.

## Testing Targets

Add focused regression coverage before implementation:

- top-content backpack width uses a slot-scaled pin overhang instead of the old broad `30%` full-grid policy
- side panels remain expand-fill while the backpack remains fixed-width centered
- `pin_visible_count()` still maps combat progress to quarter-count values
- combat pins stay visible from progress even when the transient `hud.pin.active` flag is false
- non-combat phases hide pins
- corner mapping remains `pin_1` top-left, `pin_2` top-right, `pin_3` bottom-right, `pin_4` bottom-left
- visible-index mapping removes pins as `pin_1 -> pin_2 -> pin_3 -> pin_4`
- pin display extent is derived from slot-scale geometry rather than whole-grid extent
- removal VFX contract exposes corner pull direction, short duration bounds, fade, and localized-only feedback

Expected verification:

- focused UI read-model contract runner prints `UI_READ_MODEL_TESTS_OK`
- broad Godot contract runner prints `GODOT_CONTRACTS_OK`
- any Godot exit-time leak warnings are treated separately from explicit success markers
- `git diff --check` reports no whitespace errors in touched files

## Approval Board Criteria

The implementation is acceptable only if the review board can answer yes to these checks:

- The grid image stays the same apparent size.
- The backpack shell, not the grid, receives the extra pin space.
- The side panels absorb the horizontal budget change around the fixed backpack.
- Pins sit on top of all backpack visuals.
- Pins do not intrude deeply into usable grid/item space.
- Pins are removed in the requested order: `pin_1`, `pin_2`, `pin_3`, `pin_4`.
- A removed pin reads as pulled out, not instantly hidden.
- The effect is localized and does not disturb remaining pins or inventory items.
- The animation finishes quickly enough for combat HUD feedback.

## Out Of Scope

- Replacing pin source art.
- Changing backend pin timing or combat rules.
- Adding audio.
- Reworking the whole top-content layout system.
- Reworking backpack item drag/drop behavior.
- Adding global screen shake for pin removal.

## Implementation Sequence

1. Add RED tests for width policy, visible-index order, and VFX contract helpers.
2. Replace the broad backpack extra-width constant with slot-scaled pin overhang helpers.
3. Adjust `BackpackUI` pin sizing and placement to use corner slot geometry.
4. Change visible-index mapping to remove `pin_1`, then `pin_2`, then `pin_3`, then `pin_4`.
5. Add local pull-out tween behavior for newly removed pins.
6. Reset transforms and visibility cleanly across phase changes and layout refreshes.
7. Run focused and broad verification.

## Final Decision

Proceed with `Option A: grounded local pin effect` after user review of this design document.

No code implementation should begin until this written design is accepted.
