# Interaction Sound Application Plan

Date: 2026-06-23
Workspace: LootingTheLeviathan

## Goal

Add a restrained, coherent SFX layer across player interactions while preserving existing gameplay, UI layout, and visual feedback. Combat hits are the only thunder-like family, and they gain a lower-register body layer for weight.

## Web Reference Notes

- Godot `AudioStreamPlayer` is the correct non-positional player for UI/menu/gameplay SFX. This implementation uses reusable players, assigns streams per event, controls `volume_db`, and adjusts `pitch_scale` for lower hit layers.
- Godot audio bus/dB guidance supports negative category gains and a shared volume scalar rather than full-scale one-off playback.
- Game Accessibility Guidelines recommend player control over effects volume and caution against sound-only communication. All SFX here supplement existing visual state, button states, overlays, VFX, logs, and page changes.
- Research on game feel and impact feedback points to audio-visual coherence as a major contributor to satisfying hits. Combat SFX therefore fires at the same boundary as beam, particles, damage popup, and screenshake.
- Thunder-oriented sound design commonly layers a low-frequency rumble/body under the transient. The combat hit implementation layers a low-pitch hit stream under the existing hit transient instead of making general UI sounds heavier.

Reference URLs:

- https://docs.godotengine.org/en/stable/classes/class_audiostreamplayer.html
- https://docs.godotengine.org/en/stable/tutorials/audio/audio_buses.html
- https://gameaccessibilityguidelines.com/provide-separate-volume-controls-or-mutes-for-effects-speech-and-background-music/
- https://gameaccessibilityguidelines.com/ensure-that-all-important-information-conveyed-by-sounds-is-also-conveyed-by-visuals-or-text/
- https://arxiv.org/abs/2208.06155

## Event Inventory

| Event | Category | Sound Direction | Runtime Boundary |
| --- | --- | --- | --- |
| Neutral button/control press | `ui_click` | short soft tick | `InteractionFX.gui_input` |
| Positive action | `ui_confirm` | slightly brighter short tick | `InteractionFX` name/text mapping |
| Negative/back/discard action | `ui_cancel` | lower, softer down tick | `InteractionFX` name/text mapping |
| Settings/codex/shop/confirm overlay opens | `menu_open` | quiet rising panel cue | overlay visibility callbacks |
| Settings/codex/shop/confirm overlay closes | `menu_close` | quiet falling panel cue | overlay visibility callbacks |
| Page id changes | `page_transition` | soft movement wash | page activation after page id resolution |
| Reward/backpack drag starts | `drag_start` | quiet pickup cue | drag tracking start |
| Reward/backpack valid drop/placement | `drag_drop` | soft settle/confirm cue | pointer release after valid drop decision |
| Reward/backpack canceled/invalid release | `drag_cancel` | dry reject/return cue | pointer release cancel decision |
| Combat mismatch/empty queue/non-match | `combat_miss` | dry miss | combat result boundary |
| Combat match, shield/body not lethal | `combat_hit` | hit transient plus low body | combat result boundary |
| Combat health-damaging hit | `combat_strong_hit` | stronger hit transient plus low body | combat result boundary |
| Reward ceremony reveal beats | `reward_reveal` reserved | existing reward thump/open assets only | reward reveal overlay, not ordinary UI |

## Implementation Rules

- Use stable category names. UI and controllers never choose concrete files directly.
- Keep non-combat category `gainDb` quiet and `toneFamily` non-thunder.
- Fire sounds at semantic decisions: page changed, menu visible changed, drop accepted/canceled, combat result resolved.
- Do not play hover or mouse-motion sounds.
- Reuse the shared interaction SFX player pool for base and layered playback.
- Preserve the existing settings volume slider by routing interaction SFX through the same volume scalar.
- Keep reward ceremony assets reserved for ceremony beats so normal button clicks do not sound like loot explosions.

## Completion Criteria

- The event inventory above is represented by descriptors or intentionally reserved categories.
- Non-combat descriptors are subtle and never thunder-family.
- `combat_hit` and `combat_strong_hit` include lower-pitch combat-only layers.
- Page/menu sounds are gated against duplicate rerender spam.
- Focused tests pass for catalog coverage, volume routing, page gating, and low-hit layering.
- Broader gates are run or their unrelated blockers are recorded.
