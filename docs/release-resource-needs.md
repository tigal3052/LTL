# Release Resource Needs

This list is wired to `app-LTL/src/data/release-resource-needs.json`. Drop files at the listed `res://resources/UI/...` paths and the release content manifest will already point to them.

## Key Images

- `res://resources/UI/backgrounds/leviathan_surface_panel.png` - combat surface background.
- `res://resources/UI/backgrounds/node_map_leviathan_spine.png` - leviathan-spine node map background.
- `res://resources/UI/portraits/climber_rig_idle.png` - default miner portrait.
- `res://resources/UI/portraits/engineer_rig_idle.png` - engineer portrait.
- `res://resources/UI/portraits/mechanic_rig_idle.png` - mechanic portrait.
- `res://resources/UI/icons/pulse_red_triangle.png` - red pulse icon.
- `res://resources/UI/icons/pulse_blue_ring.png` - blue pulse icon.
- `res://resources/UI/icons/pulse_purple_diamond.png` - purple pulse icon.
- `res://resources/UI/icons/pulse_green_spore.png` - green pulse icon.
- `res://resources/UI/icons/hazard_freeze.png` - freeze hazard icon.
- `res://resources/UI/icons/hazard_wind.png` - wind hazard icon.
- `res://resources/UI/icons/hazard_debris.png` - debris hazard icon.
- `res://resources/UI/icons/hazard_overheat.png` - overheat hazard icon.
- `res://resources/UI/items/drill_red_basic.png` - red starter drill.
- `res://resources/UI/items/drill_blue_basic.png` - blue starter drill.
- `res://resources/UI/items/beacon_red_basic.png` - red starter beacon.
- `res://resources/UI/cards/reward_card_common.png` - common reward frame.
- `res://resources/UI/cards/reward_card_rare.png` - rare reward frame.
- `res://resources/UI/panels/hud_compact_log_panel.png` - compact combat log panel.
- `res://resources/UI/vfx/crack_burst_01.png` - match hit burst sprite.

## Audio

- `res://resources/UI/audio/sfx_hit_match_red.ogg` - red match hit.
- `res://resources/UI/audio/sfx_shop_buy.ogg` - base shop purchase.

## Fallback Policy

Every manifest row has a procedural fallback tag so current implementation can run before final art lands. Final art only needs to preserve the paths above.
