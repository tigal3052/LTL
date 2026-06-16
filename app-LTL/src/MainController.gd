# 계약:
# - 梨낆엫: UI ?낅젰??以묎퀎?섍퀬 ?곹깭 蹂?붾? ?쒖뼱?섎ŉ, 鍮꾩쫰?덉뒪 ?쒕??덉씠??紐⑤뜽怨??몃깽?좊━ 紐⑤뜽??愿由?議곗쑉?쒕떎. ?꾩떆 蹂댁땐 ?곸젏 諛??깆옣 ?곹깭瑜?諛섏쁺?쒕떎.
# - ?낅젰: MainUI(?⑥떆釉?酉?濡쒕????섏떊???ъ슜???명꽣?숈뀡 ?쒓렇??
# - 異쒕젰: ?쒕??덉씠???곹깭 蹂?붿뿉 ?곕Ⅸ MainUI???뚮뜑留??⑥닔 ?몄텧 諛??곗씠??媛깆떊 紐낅졊.
# - 湲덉?: 吏곸젒?곸씤 UI ?쒕줈???뚰떚???앹꽦/諛깊뙥 ?щ’ ?덉씠?꾩썐 援ъ꽦, 吏곸젒?곸씤 UI 而⑦듃濡??몃뱶 李몄“.

# 실행: define the main-scene controller as a Node script and declare class variables.
extends Node
const PreviewControllerScript = preload("res://src/ui/CombatScenePreviewController.gd")
const CodexDiscoveryStateScript = preload("res://src/vocabulary/reward/CodexDiscoveryState.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const RewardCeremonyPolicyScript = preload("res://src/ui/presenters/RewardCeremonyPolicy.gd")
const EnergyTempoBalanceScript = preload("res://src/balance/EnergyTempoBalance.gd")
const MainControllerDisplayTextScript = preload("res://src/controllers/MainControllerDisplayText.gd")
const MainControllerRewardBackpackFlowScript = preload("res://src/controllers/MainControllerRewardBackpackFlow.gd")
const MainControllerCombatFlowScript = preload("res://src/controllers/MainControllerCombatFlow.gd")
const MainControllerRunFlowScript = preload("res://src/controllers/MainControllerRunFlow.gd")
const MainControllerRenderFlowScript = preload("res://src/controllers/MainControllerRenderFlow.gd")
const MainControllerSupportFlowScript = preload("res://src/controllers/MainControllerSupportFlow.gd")
const MainControllerBootstrapFlowScript = preload("res://src/controllers/MainControllerBootstrapFlow.gd")
const CHARACTER_TABLE_PATH := "res://src/data/character-table.json"
const LEVIATHAN_TABLE_PATH := "res://src/data/leviathan-table.json"
const CHARACTER_PORTRAIT_PATH := "res://resources/charactor/charactor1.png"
const TERRAIN_SHIFT_SECONDS := 1.5
const COMBAT_TICKS_PER_SECOND := 20
const TERRAIN_SHIFT_TICKS := int(round(TERRAIN_SHIFT_SECONDS * COMBAT_TICKS_PER_SECOND))
const STARTER_LOADOUT_POSITIONS := [Vector2(2, 2), Vector2(3, 2)]
const CODEX_FORCE_DISCOVERED_KEY := KEY_F8
const ACCESSIBILITY_SETTINGS_PATH := "user://accessibility-settings.cfg"
const ACCESSIBILITY_SETTINGS_SECTION := "accessibility"
const SHOP_ENABLED := false

var view
var preview_controller
var current_scene: Dictionary = {}
var disabled_tiles: Array[String] = []
var is_holding: bool = false
var hold_cell_id: String = ""
var hold_color: String = ""
var shift_timer: Timer
var inventory: InventoryModel = null
var held_artifact = null
var held_from_rewards: bool = false
var held_reward_index: int = -1
var inspected_reward_index: int = -1
var inspected_backpack_artifact = null
var held_inventory_origin := Vector2(-1, -1)
var local_rewards_list: Array = []
var prev_phase: String = ""
var prev_pin_active: bool = false
var prev_hazard_severity: String = "stable"
var show_victory_overlay: bool = false
var selected_node_index: int = -1
var selected_start_color: String = "red"
var selected_character_id := "miner"
var selected_leviathan_id := "ossuary_tortoise"
var character_roster: Array = []
var leviathan_roster: Array = []
var campaign_progress: Dictionary = {"clearedLeviathanIds": []}
var narrative_beats: Array = []
var active_narrative_model: Dictionary = {"visible": false}
var active_narrative_phase := ""
var active_narrative_stage_index := -1
var page_override_id := "character_select"
var weakness_shift_step: int = 0
var reward_presentation_step: String = ""
var _start_transition_pending := false
var battle_pause_active := false
var _disabled_tile_release_queue: Array[Dictionary] = []
var accessibility_state := {
	"screenshake": true,
	"reducedFlash": false,
	"reducedParticles": false,
	"holdFireAssist": false
}

# Progression growth state
var growth_state: RefCounted = null
var is_reveal_vfx_running: bool = false
var codex_force_all_discovered := false

static func reward_presentation_step_sequence() -> Array:
	return RewardCeremonyPolicyScript.step_sequence()

static func codex_growth_state_for_debug(base_growth_state: Dictionary, reward_table: Dictionary, force_all_discovered: bool) -> Dictionary:
	return CodexDiscoveryStateScript.for_debug(base_growth_state, reward_table, force_all_discovered)

static func starter_codex_discovery_ids_for_color(reward_table: Dictionary, _start_color: String) -> Array:
	return CodexDiscoveryStateScript.starter_discovery_ids_for_color(reward_table, _start_color)

static func codex_growth_state_with_starter_discoveries(base_growth_state: Dictionary, reward_table: Dictionary, start_color: String) -> Dictionary:
	return CodexDiscoveryStateScript.with_starter_discoveries(base_growth_state, reward_table, start_color)

func node_map_loadout_colors_for_scene(_scene: Dictionary = {}) -> Array:
	return EnergyTempoBalanceScript.terrain_color_palette()

func _load_character_roster() -> Array:
	return MainControllerRunFlowScript.load_character_roster(CHARACTER_TABLE_PATH, CHARACTER_PORTRAIT_PATH)

func _load_leviathan_roster() -> Array:
	return MainControllerRunFlowScript.load_leviathan_roster(LEVIATHAN_TABLE_PATH)

func _selected_leviathan_data() -> Dictionary:
	return MainControllerRunFlowScript.selected_leviathan_data(leviathan_roster, selected_leviathan_id)

func _selected_character_data() -> Dictionary:
	var selected := MainControllerRunFlowScript.selected_character_data(character_roster, selected_character_id, CHARACTER_PORTRAIT_PATH)
	if not selected.is_empty():
		selected_character_id = str(selected.get("id", selected_character_id))
	return selected

func _preview_options(seed_value: int) -> Dictionary:
	var leviathan := _selected_leviathan_data()
	return MainControllerRunFlowScript.preview_options(seed_value, leviathan, selected_leviathan_id, selected_start_color, selected_character_id, campaign_progress)

func _rebuild_preview_controller(seed_value: int = -1) -> void:
	var next_seed: int = seed_value if seed_value >= 0 else (preview_controller.seed if preview_controller != null else (randi() & 0x7fffffff))
	preview_controller = PreviewControllerScript.new(_preview_options(next_seed))

# ?ㅽ뻾: obtain the parent view container, wire event handlers, and bootstrap initial run state after view is ready.
func _ready() -> void:
	await MainControllerBootstrapFlowScript.ready(self)

func _process(delta: float) -> void:
	MainControllerCombatFlowScript.process(self, delta)

func _on_language_changed(next_locale: String) -> void:
	TextCatalogScript.set_locale(next_locale)
	character_roster = _load_character_roster()
	leviathan_roster = _load_leviathan_roster()
	if not current_scene.is_empty():
		_render_scene(current_scene)

# ?ㅽ뻾: handle interactive hover cell aiming.
func _on_cell_hovered(cell_id: String, color_name: String) -> void:
	MainControllerCombatFlowScript.on_cell_hovered(self, cell_id, color_name)

# ?ㅽ뻾: handle interactive click/fire target events, triggering decoupled view VFX.
func _on_cell_clicked(cell_id: String, color_name: String) -> void:
	MainControllerCombatFlowScript.on_cell_clicked(self, cell_id, color_name)

# ?ㅽ뻾: handle hold-to-fire loop ticks.
func _trigger_hold_fire() -> void:
	MainControllerCombatFlowScript.trigger_hold_fire(self)

# ?ㅽ뻾: handle interactive node selection.
func _on_node_meta_clicked(meta: Variant) -> void:
	selected_node_index = int(meta)
	_render_scene(current_scene)

func _reward_ceremony_active() -> bool:
	var phase := str(current_scene.get("phase", ""))
	return phase == "reward_loot" and RewardCeremonyPolicyScript.is_active_step(reward_presentation_step)

func _allow_start_color_selection(scene: Dictionary = {}) -> bool:
	if page_override_id == "character_select":
		return true
	if scene.is_empty():
		scene = current_scene
	return RewardCeremonyPolicyScript.allow_start_color_selection(scene)

func _clear_reward_ceremony_state() -> void:
	reward_presentation_step = ""
	is_reveal_vfx_running = false
	show_victory_overlay = false
	if view != null and view.has_method("cancel_reward_reveal_vfx"):
		view.cancel_reward_reveal_vfx()

func _set_reward_presentation_step(step: String) -> void:
	if reward_presentation_step == step:
		return
	reward_presentation_step = step
	if not current_scene.is_empty():
		_render_scene(current_scene)

func _on_reward_ceremony_step_changed(step: String) -> void:
	_set_reward_presentation_step(step)

func reward_ceremony_step_changed_callback(step: String) -> void:
	_on_reward_ceremony_step_changed(step)

func _on_reward_ceremony_finished() -> void:
	if view != null and view.has_method("cancel_reward_reveal_vfx"):
		view.cancel_reward_reveal_vfx()
	reward_presentation_step = "tray_review"
	is_reveal_vfx_running = false
	_append_localized_log("#a3be8c", "log.reward.ceremony_complete")
	call_deferred("_render_current_scene_after_reward_ceremony")

func reward_ceremony_finished_callback(_next_step := "") -> void:
	call_deferred("_on_reward_ceremony_finished")

func _render_current_scene_after_reward_ceremony() -> void:
	await get_tree().process_frame
	_render_scene(current_scene)

func _start_reward_ceremony() -> void:
	if str(current_scene.get("phase", "")) != "reward_loot":
		return
	if local_rewards_list.is_empty():
		reward_presentation_step = "tray_review"
		is_reveal_vfx_running = false
		_render_scene(current_scene)
		return
	var ceremony_steps := RewardCeremonyPolicyScript.step_sequence()
	reward_presentation_step = str(ceremony_steps[0])
	is_reveal_vfx_running = true
	_append_localized_log("#ffd766", "log.reward.ceremony_starting")
	var ceremony_step_changed: Callable = reward_ceremony_step_changed_callback
	var ceremony_finished: Callable = reward_ceremony_finished_callback
	view.start_reward_reveal_vfx(
		local_rewards_list,
		ceremony_step_changed,
		ceremony_finished
	)

# ?ㅽ뻾: manage placement/rotation/selection inside backpack.
func _place_held_artifact_at(coord: Vector2) -> bool:
	return MainControllerRewardBackpackFlowScript.place_held_artifact_at(self, coord)

func _clear_reward_drag_hold() -> void:
	MainControllerRewardBackpackFlowScript.clear_reward_drag_hold(self)

func _sync_reward_inspection_after_removal(removed_index: int) -> void:
	MainControllerRewardBackpackFlowScript.sync_reward_inspection_after_removal(self, removed_index)

func _discard_current_held_reward() -> void:
	MainControllerRewardBackpackFlowScript.discard_current_held_reward(self)

func _reward_board_drag_rearrange_active() -> bool:
	return MainControllerRewardBackpackFlowScript.reward_board_drag_rearrange_active(self)

func _artifact_at_coord(coord: Vector2):
	return MainControllerRewardBackpackFlowScript.artifact_at_coord(self, coord)

func _discard_current_held_inventory_artifact() -> void:
	MainControllerRewardBackpackFlowScript.discard_current_held_inventory_artifact(self)

func _restore_held_inventory_drag() -> void:
	MainControllerRewardBackpackFlowScript.restore_held_inventory_drag(self)

func _on_backpack_slot_clicked(coord: Vector2) -> void:
	MainControllerRewardBackpackFlowScript.on_backpack_slot_clicked(self, coord)

func _on_backpack_slot_drag_started(coord: Vector2) -> void:
	MainControllerRewardBackpackFlowScript.on_backpack_slot_drag_started(self, coord)

func _on_backpack_slot_drop_requested(_origin_coord: Vector2, coord: Vector2) -> void:
	MainControllerRewardBackpackFlowScript.on_backpack_slot_drop_requested(self, _origin_coord, coord)

func _on_backpack_slot_discard_requested(_origin_coord: Vector2) -> void:
	MainControllerRewardBackpackFlowScript.on_backpack_slot_discard_requested(self, _origin_coord)

func _on_backpack_slot_drag_canceled(_origin_coord: Vector2) -> void:
	MainControllerRewardBackpackFlowScript.on_backpack_slot_drag_canceled(self, _origin_coord)

# ?ㅽ뻾: handle slot hovered to show tooltip.
func _on_backpack_slot_hovered(coord: Vector2) -> void:
	MainControllerRewardBackpackFlowScript.on_backpack_slot_hovered(self, coord)

# ?ㅽ뻾: handle slot unhovered to hide tooltip.
func _on_backpack_slot_unhovered(_coord: Vector2) -> void:
	MainControllerRewardBackpackFlowScript.on_backpack_slot_unhovered(self, _coord)

# ?ㅽ뻾: handle reward item hovered to show tooltip.
func _on_reward_meta_hovered(meta: Variant) -> void:
	MainControllerRewardBackpackFlowScript.on_reward_meta_hovered(self, meta)

# ?ㅽ뻾: handle reward item unhovered to hide tooltip.
func _on_reward_meta_unhovered(_meta: Variant) -> void:
	MainControllerRewardBackpackFlowScript.on_reward_meta_unhovered(self, _meta)

func _on_reward_meta_drag_canceled(meta: Variant) -> void:
	MainControllerRewardBackpackFlowScript.on_reward_meta_drag_canceled(self, meta)

# ?ㅽ뻾: process ESC and R keyboard keys forwarded from view.
func _on_key_pressed(keycode: int) -> void:
	if battle_pause_active and not keycode in [KEY_ESCAPE, CODEX_FORCE_DISCOVERED_KEY]:
		return
	if keycode == KEY_ESCAPE:
		if view.has_method("is_artifact_codex_visible") and view.is_artifact_codex_visible():
			view.set_artifact_codex_visible(false)
		elif view.is_shop_visible():
			view.set_shop_visible(false)
		else:
			view.toggle_settings()
	elif keycode == CODEX_FORCE_DISCOVERED_KEY:
		_toggle_codex_force_all_discovered()
	elif keycode == KEY_R:
		if held_artifact != null:
			if str(current_scene.get("phase", "")) == "combat" or _reward_ceremony_active():
				return
			held_artifact.rotate_shape()
			_append_localized_log("#ffd766", "log.inventory.artifact_rotated", [MainControllerDisplayTextScript.artifact_display_name(held_artifact)])
			view.update_backpack_ghost(held_artifact)

# ?ㅽ뻾: render full state scene updates, delegate to sub UI systems.
func _render_scene(scene: Dictionary) -> void:
	MainControllerRenderFlowScript.render_scene(self, scene)

# ?ㅽ뻾: delegate battlefield rendering to the view.
func _render_battlefield(scene: Dictionary) -> void:
	MainControllerRenderFlowScript.render_battlefield(self, scene)

# ?ㅽ뻾: render the interactive reward looting list.
func _render_rewards(scene: Dictionary) -> void:
	MainControllerRenderFlowScript.render_rewards(self, scene)

# 실행: clear the floating tooltip when its hover source is no longer authoritative.
func _clear_floating_tooltip() -> void:
	MainControllerRenderFlowScript.clear_floating_tooltip(self)

# 실행: select and package artifact reward.
func _on_reward_meta_clicked(meta: Variant) -> void:
	MainControllerRewardBackpackFlowScript.on_reward_meta_clicked(self, meta)

# 실행: drop and delete selected reward or backpack item.
func _on_reward_meta_inspect_clicked(meta: Variant) -> void:
	MainControllerRewardBackpackFlowScript.on_reward_meta_inspect_clicked(self, meta)

func _on_reward_meta_drag_started_v2(meta: Variant) -> void:
	MainControllerRewardBackpackFlowScript.on_reward_meta_drag_started_v2(self, meta)

func _on_reward_meta_drop_requested_v2(meta: Variant, coord: Vector2) -> void:
	MainControllerRewardBackpackFlowScript.on_reward_meta_drop_requested_v2(self, meta, coord)

func _on_reward_meta_discard_requested_v2(meta: Variant) -> void:
	MainControllerRewardBackpackFlowScript.on_reward_meta_discard_requested_v2(self, meta)

func _on_reward_meta_drag_canceled_v2(meta: Variant) -> void:
	MainControllerRewardBackpackFlowScript.on_reward_meta_drag_canceled_v2(self, meta)

func _on_discard_zone_input(event: InputEvent) -> void:
	MainControllerRewardBackpackFlowScript.on_discard_zone_input(self, event)

# ?ㅽ뻾: start a new combat stage.
func _on_start_pressed() -> void:
	MainControllerRunFlowScript.on_start_pressed(self)

func _commit_start_pressed_transition() -> void:
	MainControllerRunFlowScript.commit_start_pressed_transition(self)

func _perform_start_pressed_transition() -> void:
	MainControllerRunFlowScript.perform_start_pressed_transition(self)

# ?ㅽ뻾: reset run state.
func _on_reset_pressed() -> void:
	MainControllerRunFlowScript.on_reset_pressed(self)

# ?ㅽ뻾: trigger hold fire simulation.
func _on_hold_fire_pressed() -> void:
	MainControllerCombatFlowScript.on_hold_fire_pressed(self)

# ?ㅽ뻾: request repair on heated core.
func _on_repair_pressed() -> void:
	MainControllerCombatFlowScript.on_repair_pressed(self)

# ?ㅽ뻾: claim rewards and proceed, showing confirmation warning if rewards are left.
func _on_claim_rewards_pressed() -> void:
	MainControllerRunFlowScript.on_claim_rewards_pressed(self)

# ?ㅽ뻾: confirm and proceed to node select even with remaining rewards.
func _on_confirm_proceed_pressed() -> void:
	MainControllerRunFlowScript.on_confirm_proceed_pressed(self)

# ?ㅽ뻾: cancel proceeding and return to reward looting.
func _on_confirm_cancel_pressed() -> void:
	MainControllerRunFlowScript.on_confirm_cancel_pressed(self)

# ?ㅽ뻾: execute reward claim and transition.
func _proceed_to_node_select() -> void:
	MainControllerRunFlowScript.proceed_to_node_select(self)

# ?ㅽ뻾: load starter backpack items.
func _load_backpack_items_into_inventory() -> void:
	MainControllerRunFlowScript.load_backpack_items_into_inventory(self)

# ?ㅽ뻾: replace the starter inventory when the node-map start color changes.
func _on_loadout_color_selected(color: String) -> void:
	MainControllerRunFlowScript.on_loadout_color_selected(self, color)

func _on_character_selected(character_id: String) -> void:
	MainControllerRunFlowScript.on_character_selected(self, character_id)

func _on_character_continue_pressed() -> void:
	MainControllerRunFlowScript.on_character_continue_pressed(self)

func _on_leviathan_selected(leviathan_id: String) -> void:
	MainControllerRunFlowScript.on_leviathan_selected(self, leviathan_id)

func _on_looting_start_pressed() -> void:
	MainControllerRunFlowScript.on_looting_start_pressed(self)

func _on_return_to_character_select_pressed() -> void:
	MainControllerRunFlowScript.on_return_to_character_select_pressed(self)

# ?ㅽ뻾: cycle active item colors to fill queue.
func _recalculate_queue_colors() -> void:
	MainControllerCombatFlowScript.recalculate_queue_colors(self)

func is_battle_pause_active() -> bool:
	return battle_pause_active

func _on_combat_overlay_pause_visibility_changed(_active: bool) -> void:
	MainControllerCombatFlowScript.on_combat_overlay_pause_visibility_changed(self, _active)

func _sync_battle_pause_from_overlay_visibility() -> void:
	MainControllerCombatFlowScript.sync_battle_pause_from_overlay_visibility(self)

func _set_battle_pause_active(active: bool) -> void:
	MainControllerCombatFlowScript.set_battle_pause_active(self, active)

func _set_shift_timer_paused(paused: bool) -> void:
	MainControllerCombatFlowScript.set_shift_timer_paused(self, paused)

# ?ㅽ뻾: setup conveyor-belt shift timer.
func _setup_shift_timer() -> void:
	MainControllerCombatFlowScript.setup_shift_timer(self)

# ?ㅽ뻾: shift weaknesses left-to-right on timeout.
func _on_shift_timer_timeout() -> void:
	MainControllerCombatFlowScript.on_shift_timer_timeout(self)

# ?ㅽ뻾: initialize weaknesses.
func _ensure_combat_terrain_markers() -> void:
	MainControllerCombatFlowScript.ensure_combat_terrain_markers(self)

# ?ㅽ뻾: helper to get queue front color.
# 실행: return current inventory artifacts as an array for tooltip comparison.
# 실행: return a localized artifact name for player-facing logs.
func _append_localized_log(color_hex: String, key: String, args: Array = []) -> void:
	if view == null:
		return
	view.add_log("[color=%s]%s[/color]" % [color_hex, TextCatalogScript.t(key, args)])

# ?ㅽ뻾: helper to summarize node select candidates.
# 실행: helper to get best target coordinate.
# ?ㅽ뻾: handle calibration shop button toggle.
func _on_shop_open_pressed() -> void:
	MainControllerSupportFlowScript.on_shop_open_pressed(self, SHOP_ENABLED)

# 실행: open the artifact codex with play-history discovery data.
func _on_codex_open_pressed() -> void:
	MainControllerSupportFlowScript.on_codex_open_pressed(self)

# 실행: load the reward table for the codex menu without changing reward RNG state.
func _load_reward_table_for_codex() -> Dictionary:
	return MainControllerSupportFlowScript.load_reward_table_for_codex()

func _codex_growth_state_for_view(reward_table: Dictionary) -> Dictionary:
	return MainControllerSupportFlowScript.codex_growth_state_for_view(self, reward_table)

func _toggle_codex_force_all_discovered() -> void:
	MainControllerSupportFlowScript.toggle_codex_force_all_discovered(self)

# ?ㅽ뻾: handle buy passive.
func _on_buy_passive(passive_id: String, cost: int) -> void:
	MainControllerSupportFlowScript.on_buy_passive(self, passive_id, cost, SHOP_ENABLED)

# ??쎈뻬: handle base shop item or character purchases.
func _on_buy_base_item(item_id: String) -> void:
	MainControllerSupportFlowScript.on_buy_base_item(self, item_id, SHOP_ENABLED)

# ?ㅽ뻾: apply active growth modifiers (cooldown reduction, flat damage bonus).
func _apply_growth_modifiers() -> void:
	MainControllerSupportFlowScript.apply_growth_modifiers(self)

func _apply_accessibility_state() -> void:
	MainControllerSupportFlowScript.apply_accessibility_state(self)

func save_accessibility_state_to_path(path: String = ACCESSIBILITY_SETTINGS_PATH) -> int:
	return MainControllerSupportFlowScript.save_accessibility_state_to_path(path, ACCESSIBILITY_SETTINGS_SECTION, accessibility_state)

func load_accessibility_state_from_path(path: String = ACCESSIBILITY_SETTINGS_PATH) -> Dictionary:
	return MainControllerSupportFlowScript.load_accessibility_state_from_path(path, ACCESSIBILITY_SETTINGS_SECTION)

func _decorate_scene(scene: Dictionary) -> Dictionary:
	return MainControllerRenderFlowScript.decorate_scene(self, scene)

func _resolve_page_id(scene: Dictionary) -> String:
	return MainControllerRenderFlowScript.resolve_page_id(self, scene)

func _selected_node_context(scene: Dictionary = {}) -> Dictionary:
	if scene.is_empty():
		scene = current_scene
	var selected_run_node: Dictionary = {}
	if preview_controller != null and preview_controller.run != null:
		var selected_node = preview_controller.run.state.get("selectedNode", {})
		if selected_node is Dictionary:
			selected_run_node = selected_node
	return MainControllerRunFlowScript.selected_node_context(scene, selected_node_index, selected_run_node)

func _selected_node_start_enabled(scene: Dictionary = {}) -> bool:
	if scene.is_empty():
		scene = current_scene
	return MainControllerRunFlowScript.selected_node_start_enabled(scene, selected_node_index)

func _emit_ui_telemetry(payload: Dictionary) -> void:
	if payload.is_empty():
		return
	print("TELEMETRY_JSON %s" % JSON.stringify(payload))
