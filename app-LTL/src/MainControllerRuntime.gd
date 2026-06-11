# 계약:
# - 梨낆엫: UI ?낅젰??以묎퀎?섍퀬 ?곹깭 蹂?붾? ?쒖뼱?섎ŉ, 鍮꾩쫰?덉뒪 ?쒕??덉씠??紐⑤뜽怨??몃깽?좊━ 紐⑤뜽??愿由?議곗쑉?쒕떎. ?꾩떆 蹂댁땐 ?곸젏 諛??깆옣 ?곹깭瑜?諛섏쁺?쒕떎.
# - ?낅젰: MainUI(?⑥떆釉?酉?濡쒕????섏떊???ъ슜???명꽣?숈뀡 ?쒓렇??
# - 異쒕젰: ?쒕??덉씠???곹깭 蹂?붿뿉 ?곕Ⅸ MainUI???뚮뜑留??⑥닔 ?몄텧 諛??곗씠??媛깆떊 紐낅졊.
# - 湲덉?: 吏곸젒?곸씤 UI ?쒕줈???뚰떚???앹꽦/諛깊뙥 ?щ’ ?덉씠?꾩썐 援ъ꽦, 吏곸젒?곸씤 UI 而⑦듃濡??몃뱶 李몄“.

# 실행: define the main-scene controller as a Node script and declare class variables.
extends Node
const PreviewControllerScript = preload("res://src/ui/CombatScenePreviewController.gd")
const ArtifactScript = preload("res://src/models/Artifact.gd")
const RunGrowthStateScript = preload("res://src/models/RunGrowthState.gd")
const CreateArtifactFromRewardScript = preload("res://src/vocabulary/reward/CreateArtifactFromReward.gd")
const BuildRewardTelemetryScript = preload("res://src/vocabulary/reward/BuildRewardTelemetry.gd")
const ApplyGrowthModifiersScript = preload("res://src/vocabulary/progression/ApplyGrowthModifiers.gd")
const RecalculateQueueColorsScript = preload("res://src/vocabulary/combat/RecalculateQueueColors.gd")
const ShiftWeaknessMarkersScript = preload("res://src/vocabulary/combat/ShiftWeaknessMarkers.gd")
const NodeSelectReadModelScript = preload("res://src/ui/read_models/NodeSelectReadModel.gd")
const RewardReadModelScript = preload("res://src/ui/read_models/RewardReadModel.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const CombatFeedbackPresenterScript = preload("res://src/ui/presenters/CombatFeedbackPresenter.gd")
const RewardCeremonyPolicyScript = preload("res://src/ui/presenters/RewardCeremonyPolicy.gd")
const EnergyTempoBalanceScript = preload("res://src/balance/EnergyTempoBalance.gd")
const CHARACTER_TABLE_PATH := "res://src/data/character-table.json"
const LEVIATHAN_TABLE_PATH := "res://src/data/leviathan-table.json"
const CHARACTER_PORTRAIT_PATH := "res://resources/charactor/charactor1.png"
const TERRAIN_SHIFT_SECONDS := 1.5
const COMBAT_TICKS_PER_SECOND := 20
const TERRAIN_SHIFT_TICKS := int(round(TERRAIN_SHIFT_SECONDS * COMBAT_TICKS_PER_SECOND))
const STARTER_LOADOUT_POSITIONS := [Vector2(2, 2), Vector2(3, 2)]
const CODEX_FORCE_DISCOVERED_KEY := KEY_F8

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
var selected_node_index: int = 0
var selected_start_color: String = "red"
var selected_character_id := "miner"
var selected_leviathan_id := "ossuary_tortoise"
var character_roster: Array = []
var leviathan_roster: Array = []
var campaign_progress: Dictionary = {"clearedLeviathanIds": []}
var page_override_id := "character_select"
var weakness_shift_step: int = 0
var reward_presentation_step: String = ""
var _start_transition_pending := false
var battle_pause_active := false
var _paused_shift_time_left := -1.0
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
	var codex_growth := base_growth_state.duplicate(true)
	if not force_all_discovered:
		return codex_growth
	var discovered_ids: Array = codex_growth.get("artifactDiscovery", []).duplicate(true)
	var discovered_lookup := {}
	for entry_id in discovered_ids:
		discovered_lookup[str(entry_id)] = true
	for reward in reward_table.get("rewards", []):
		if not (reward is Dictionary):
			continue
		var reward_id := str(reward.get("id", reward.get("catalogId", "")))
		if reward_id.is_empty() or discovered_lookup.has(reward_id):
			continue
		discovered_lookup[reward_id] = true
		discovered_ids.append(reward_id)
	codex_growth["artifactDiscovery"] = discovered_ids
	return codex_growth

static func starter_codex_discovery_ids_for_color(reward_table: Dictionary, _start_color: String) -> Array:
	var discovery_ids: Array = []
	var claimed_types := {}
	for color in EnergyTempoBalanceScript.VALID_COLORS:
		claimed_types[color] = {}
	for reward in reward_table.get("rewards", []):
		if not (reward is Dictionary):
			continue
		var tags = reward.get("tags", [])
		if not (tags is Array) or not tags.has("starter_safe"):
			continue
		var payload: Dictionary = reward.get("payload", {})
		var energy_type := str(payload.get("energy_type", "")).to_lower()
		if not (energy_type in EnergyTempoBalanceScript.VALID_COLORS):
			continue
		var item_type := str(payload.get("item_type", "")).to_lower()
		if not claimed_types.has(energy_type):
			claimed_types[energy_type] = {}
		if not (item_type in ["drill", "beacon"]) or claimed_types[energy_type].has(item_type):
			continue
		var reward_id := str(reward.get("id", reward.get("catalogId", "")))
		if reward_id.is_empty():
			continue
		claimed_types[energy_type][item_type] = true
		discovery_ids.append(reward_id)
	return discovery_ids

static func codex_growth_state_with_starter_discoveries(base_growth_state: Dictionary, reward_table: Dictionary, start_color: String) -> Dictionary:
	var codex_growth := base_growth_state.duplicate(true)
	var discovered_ids: Array = codex_growth.get("artifactDiscovery", []).duplicate(true)
	var discovered_lookup := {}
	for entry_id in discovered_ids:
		discovered_lookup[str(entry_id)] = true
	for starter_id in starter_codex_discovery_ids_for_color(reward_table, start_color):
		var normalized_id := str(starter_id)
		if normalized_id.is_empty() or discovered_lookup.has(normalized_id):
			continue
		discovered_lookup[normalized_id] = true
		discovered_ids.append(normalized_id)
	codex_growth["artifactDiscovery"] = discovered_ids
	return codex_growth

static func _normalized_codex_start_color(start_color: String) -> String:
	var color := start_color.to_lower()
	if color in ["red", "blue", "purple", "green"]:
		return color
	return "red"

func node_map_loadout_colors_for_scene(_scene: Dictionary = {}) -> Array:
	return EnergyTempoBalanceScript.terrain_color_palette()

func _load_character_roster() -> Array:
	var fallback_ids := [
		{"id": "miner", "name": "Anchor Miner", "unlocked": true},
		{"id": "engineer", "name": "Pulse Engineer", "unlocked": false},
		{"id": "mechanic", "name": "Hull Mechanic", "unlocked": false}
	]
	var file := FileAccess.open(CHARACTER_TABLE_PATH, FileAccess.READ)
	if file == null:
		var fallback_rows: Array = []
		for entry in fallback_ids:
			fallback_rows.append(_build_character_row(str(entry.get("id", "")), str(entry.get("name", "")), CHARACTER_PORTRAIT_PATH, bool(entry.get("unlocked", false))))
		return _append_character_placeholder_slots(fallback_rows)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		var parse_fallback: Array = []
		for entry in fallback_ids:
			parse_fallback.append(_build_character_row(str(entry.get("id", "")), str(entry.get("name", "")), CHARACTER_PORTRAIT_PATH, bool(entry.get("unlocked", false))))
		return _append_character_placeholder_slots(parse_fallback)
	var data = json.get_data()
	if not (data is Dictionary):
		var type_fallback: Array = []
		for entry in fallback_ids:
			type_fallback.append(_build_character_row(str(entry.get("id", "")), str(entry.get("name", "")), CHARACTER_PORTRAIT_PATH, bool(entry.get("unlocked", false))))
		return _append_character_placeholder_slots(type_fallback)
	var result: Array = []
	for character in data.get("characters", []):
		if not (character is Dictionary):
			continue
		var character_id := str(character.get("id", ""))
		if character_id.is_empty():
			continue
		result.append(
			_build_character_row(
				character_id,
				str(character.get("name", character_id)),
				str(character.get("portrait", CHARACTER_PORTRAIT_PATH)),
				bool(character.get("unlocked", false))
			)
		)
	return _append_character_placeholder_slots(result if not result.is_empty() else [])

func _build_character_row(character_id: String, fallback_name: String, portrait_path: String, selectable: bool) -> Dictionary:
	return {
		"id": character_id,
		"name": TextCatalogScript.character_text(character_id, "name", fallback_name),
		"role": TextCatalogScript.character_text(character_id, "role", ""),
		"portraitPath": portrait_path if not portrait_path.is_empty() else CHARACTER_PORTRAIT_PATH,
		"selectable": selectable,
		"locked": not selectable,
		"rosterMeta": TextCatalogScript.character_text(character_id, "rosterMeta", ""),
		"description": TextCatalogScript.character_text(character_id, "description", ""),
		"summary": TextCatalogScript.character_text(character_id, "summary", ""),
		"tags": TextCatalogScript.character_tags(character_id),
		"accentColor": _character_accent(character_id)
	}

func _character_accent(character_id: String) -> String:
	match character_id:
		"miner":
			return "red"
		"engineer", "bulk_diver":
			return "blue"
		"mechanic", "pressure_cartographer":
			return "green"
		"future_trawler":
			return "purple"
	return "red"

func _append_character_placeholder_slots(base_roster: Array) -> Array:
	var roster := base_roster.duplicate(true)
	var placeholders := [
		_build_character_row("future_trawler", "Future Trawler", CHARACTER_PORTRAIT_PATH, false),
		_build_character_row("bulk_diver", "Bulk Diver", CHARACTER_PORTRAIT_PATH, false),
		_build_character_row("pressure_cartographer", "Pressure Cartographer", CHARACTER_PORTRAIT_PATH, false)
	]
	var index := 0
	while roster.size() < 6 and index < placeholders.size():
		roster.append(placeholders[index].duplicate(true))
		index += 1
	return roster

func _load_leviathan_roster() -> Array:
	var file := FileAccess.open(LEVIATHAN_TABLE_PATH, FileAccess.READ)
	if file == null:
		return [
			_build_leviathan_row("ossuary_tortoise", "Ossuary Tortoise", "calcified shell", 3, 1, "res://resources/Leviathan/Leviathan_turtle.png"),
			_build_leviathan_row("storm_wyvern", "Storm Wyvern", "storm membrane", 4, 2, "res://resources/Leviathan/Leviathan_lizard.png"),
			_build_leviathan_row("sky_mireu", "Sky Mireu", "living aurora", 5, 3, "res://resources/Leviathan/Leviathan_golem.png")
		]
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return []
	var data = json.get_data()
	if not (data is Dictionary):
		return []
	var result: Array = []
	var art_paths := [
		"res://resources/Leviathan/Leviathan_turtle.png",
		"res://resources/Leviathan/Leviathan_lizard.png",
		"res://resources/Leviathan/Leviathan_golem.png"
	]
	var index := 0
	for leviathan in data.get("leviathans", []):
		if not (leviathan is Dictionary):
			continue
		var leviathan_id := str(leviathan.get("id", ""))
		result.append(
			_build_leviathan_row(
				leviathan_id,
				str(leviathan.get("name", leviathan_id)),
				str(leviathan.get("biome", "")),
				int(leviathan.get("stageCount", leviathan.get("stageCnt", 3))),
				int(leviathan.get("runCount", leviathan.get("runCnt", 1))),
				art_paths[min(index, art_paths.size() - 1)]
			)
		)
		index += 1
	return result

func _build_leviathan_row(leviathan_id: String, fallback_name: String, fallback_biome: String, stage_count: int, run_count: int, art_path: String) -> Dictionary:
	return {
		"id": leviathan_id,
		"name": TextCatalogScript.leviathan_text(leviathan_id, "name", fallback_name),
		"stageCount": stage_count,
		"runCount": run_count,
		"biome": TextCatalogScript.leviathan_text(leviathan_id, "biome", fallback_biome),
		"artPath": art_path
	}

func _selected_leviathan_data() -> Dictionary:
	for leviathan in leviathan_roster:
		if str(leviathan.get("id", "")) == selected_leviathan_id:
			return leviathan.duplicate(true)
	return leviathan_roster[0].duplicate(true) if not leviathan_roster.is_empty() else {}

func _selected_character_data() -> Dictionary:
	for character in character_roster:
		if str(character.get("id", "")) == selected_character_id:
			return character.duplicate(true)
	for character in character_roster:
		if bool(character.get("selectable", false)):
			selected_character_id = str(character.get("id", "miner"))
			return character.duplicate(true)
	return {
		"id": selected_character_id,
		"name": TextCatalogScript.character_text(selected_character_id, "name", "Anchor Miner"),
		"role": TextCatalogScript.character_text(selected_character_id, "role", ""),
		"portraitPath": CHARACTER_PORTRAIT_PATH,
		"selectable": true,
		"locked": false,
		"rosterMeta": TextCatalogScript.character_text(selected_character_id, "rosterMeta", ""),
		"description": TextCatalogScript.character_text(selected_character_id, "description", ""),
		"summary": TextCatalogScript.character_text(selected_character_id, "summary", ""),
		"tags": TextCatalogScript.character_tags(selected_character_id),
		"accentColor": "red"
	}

func _preview_options(seed_value: int) -> Dictionary:
	var leviathan := _selected_leviathan_data()
	return {
		"seed": seed_value,
		"maxStages": maxi(1, int(leviathan.get("stageCount", 5))),
		"runCount": maxi(1, int(leviathan.get("runCount", 1))),
		"leviathanId": str(leviathan.get("id", selected_leviathan_id)),
		"viewportWidth": 1440,
		"viewportHeight": 900,
		"startColor": selected_start_color,
		"selectedCharacter": selected_character_id,
		"progress": campaign_progress.duplicate(true)
	}

func _rebuild_preview_controller(seed_value: int = -1) -> void:
	var next_seed: int = seed_value if seed_value >= 0 else (preview_controller.seed if preview_controller != null else (randi() & 0x7fffffff))
	preview_controller = PreviewControllerScript.new(_preview_options(next_seed))

# ?ㅽ뻾: obtain the parent view container, wire event handlers, and bootstrap initial run state after view is ready.
func _ready() -> void:
	view = get_parent()
	if not view.is_node_ready():
		await view.ready
	inventory = InventoryModel.new(8, 8)
	character_roster = _load_character_roster()
	var selected_character := _selected_character_data()
	selected_character_id = str(selected_character.get("id", selected_character_id))
	leviathan_roster = _load_leviathan_roster()
	if not leviathan_roster.is_empty():
		selected_leviathan_id = str(leviathan_roster[0].get("id", selected_leviathan_id))

	randomize()
	_rebuild_preview_controller(randi() & 0x7fffffff)

	# Load default growth state
	var default_growth = preview_controller.run.state.get("growth", {})
	growth_state = RunGrowthStateScript.new(default_growth)
	campaign_progress = preview_controller.run.state.get("progress", {"clearedLeviathanIds": []}).duplicate(true)

	_load_backpack_items_into_inventory()

	view.reset_pressed.connect(_on_reset_pressed)
	view.start_combat_pressed.connect(_on_start_pressed)
	view.hold_fire_pressed.connect(_on_hold_fire_pressed)
	view.repair_pressed.connect(_on_repair_pressed)
	view.claim_rewards_pressed.connect(_on_claim_rewards_pressed)
	view.confirm_proceed_pressed.connect(_on_confirm_proceed_pressed)
	view.confirm_cancel_pressed.connect(_on_confirm_cancel_pressed)
	view.settings_open_pressed.connect(func(): view.toggle_settings())
	if view.has_signal("combat_overlay_pause_visibility_changed"):
		view.combat_overlay_pause_visibility_changed.connect(_on_combat_overlay_pause_visibility_changed)
	view.loadout_color_selected.connect(_on_loadout_color_selected)
	if view.has_signal("character_continue_pressed"):
		view.character_continue_pressed.connect(_on_character_continue_pressed)
	if view.has_signal("character_selected"):
		view.character_selected.connect(_on_character_selected)
	if view.has_signal("leviathan_selected"):
		view.leviathan_selected.connect(_on_leviathan_selected)
	if view.has_signal("looting_start_pressed"):
		view.looting_start_pressed.connect(_on_looting_start_pressed)
	if view.has_signal("return_to_character_select_pressed"):
		view.return_to_character_select_pressed.connect(_on_return_to_character_select_pressed)
	view.settings_panel.reset_requested.connect(_on_reset_pressed)
	view.settings_panel.language_changed.connect(_on_language_changed)
	view.settings_panel.screenshake_toggled.connect(func(enabled):
		accessibility_state["screenshake"] = enabled
		_apply_accessibility_state()
	)
	if view.settings_panel.has_signal("reduced_flash_toggled"):
		view.settings_panel.reduced_flash_toggled.connect(func(enabled):
			accessibility_state["reducedFlash"] = enabled
			_apply_accessibility_state()
		)
	if view.settings_panel.has_signal("reduced_particles_toggled"):
		view.settings_panel.reduced_particles_toggled.connect(func(enabled):
			accessibility_state["reducedParticles"] = enabled
			_apply_accessibility_state()
		)
	if view.settings_panel.has_signal("hold_fire_assist_toggled"):
		view.settings_panel.hold_fire_assist_toggled.connect(func(enabled):
			accessibility_state["holdFireAssist"] = enabled
		)
	view.settings_panel.fullscreen_toggled.connect(func(toggled): DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if toggled else DisplayServer.WINDOW_MODE_WINDOWED))
	view.node_meta_clicked.connect(_on_node_meta_clicked)
	view.reward_meta_clicked.connect(_on_reward_meta_inspect_clicked)
	view.reward_meta_hovered.connect(_on_reward_meta_hovered)
	view.reward_meta_unhovered.connect(_on_reward_meta_unhovered)
	view.reward_meta_drag_started.connect(_on_reward_meta_drag_started_v2)
	view.reward_meta_drop_requested.connect(_on_reward_meta_drop_requested_v2)
	view.reward_meta_discard_requested.connect(_on_reward_meta_discard_requested_v2)
	view.reward_meta_drag_canceled.connect(_on_reward_meta_drag_canceled_v2)
	view.discard_zone_input.connect(_on_discard_zone_input)

	# Calibration shop connections
	view.shop_open_pressed.connect(_on_shop_open_pressed)
	view.codex_open_pressed.connect(_on_codex_open_pressed)
	view.buy_passive.connect(_on_buy_passive)
	view.buy_base_item.connect(_on_buy_base_item)

	view.repair_overlay_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			var phase = str(current_scene.get("phase", ""))
			if phase == "run_complete" and bool(current_scene.get("failed", false)):
				_on_reset_pressed()
	)
	view.backpack_slot_clicked.connect(_on_backpack_slot_clicked)
	view.backpack_slot_hovered.connect(_on_backpack_slot_hovered)
	view.backpack_slot_unhovered.connect(_on_backpack_slot_unhovered)
	if view.has_signal("backpack_slot_drag_started"):
		view.backpack_slot_drag_started.connect(_on_backpack_slot_drag_started)
	if view.has_signal("backpack_slot_drop_requested"):
		view.backpack_slot_drop_requested.connect(_on_backpack_slot_drop_requested)
	if view.has_signal("backpack_slot_discard_requested"):
		view.backpack_slot_discard_requested.connect(_on_backpack_slot_discard_requested)
	if view.has_signal("backpack_slot_drag_canceled"):
		view.backpack_slot_drag_canceled.connect(_on_backpack_slot_drag_canceled)
	view.cell_hovered.connect(_on_cell_hovered)
	view.cell_clicked.connect(_on_cell_clicked)
	view.cell_pressed.connect(func(cid, col): is_holding = true; hold_cell_id = cid; hold_color = col; _trigger_hold_fire())
	view.cell_released.connect(func(): is_holding = false)
	view.key_pressed.connect(_on_key_pressed)
	view.setup_backpack_slots()
	view.render_backpack(inventory)
	accessibility_state["screenshake"] = bool(view.vfx_manager.shake_enabled)
	_apply_accessibility_state()
	view.setup_settings(
		bool(accessibility_state.get("screenshake", true)),
		DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN,
		accessibility_state
	)
	current_scene = preview_controller.reset()
	_recalculate_queue_colors()
	_render_scene(current_scene)
	_setup_shift_timer()
	set_process(true)

func _process(delta: float) -> void:
	if battle_pause_active:
		return
	_tick_disabled_tile_release_queue(delta)

func _on_language_changed(next_locale: String) -> void:
	TextCatalogScript.set_locale(next_locale)
	character_roster = _load_character_roster()
	leviathan_roster = _load_leviathan_roster()
	if not current_scene.is_empty():
		_render_scene(current_scene)

# ?ㅽ뻾: handle interactive hover cell aiming.
func _on_cell_hovered(cell_id: String, color_name: String) -> void:
	if battle_pause_active:
		return
	if str(current_scene.get("phase", "")) == "combat":
		_clear_floating_tooltip()
		current_scene = preview_controller.aim_cell(cell_id, resolve_target_color_for_interaction(color_name, _get_active_queue_color()))
		_render_scene(current_scene)

# ?ㅽ뻾: handle interactive click/fire target events, triggering decoupled view VFX.
func _on_cell_clicked(cell_id: String, color_name: String) -> void:
	if battle_pause_active:
		return
	_clear_floating_tooltip()
	if not can_accept_combat_click(current_scene, cell_id, disabled_tiles):
		return
	var active_color = _get_active_queue_color()
	var target_color = resolve_target_color_for_interaction(color_name, active_color)
	var prev_target: Dictionary = current_scene.get("targetPanel", {}).duplicate(true)
	var prev_shield = float(prev_target.get("shield", 0.0))
	var prev_health = float(prev_target.get("health", 0.0))
	current_scene = preview_controller.fire(cell_id, target_color)
	var next_target: Dictionary = current_scene.get("targetPanel", {}).duplicate(true)
	var shield_damage := maxf(0.0, prev_shield - float(next_target.get("shield", 0.0)))
	var health_damage := maxf(0.0, prev_health - float(next_target.get("health", 0.0)))
	var damage := shield_damage + health_damage
	var status = str(current_scene.get("feedback", {}).get("status", "active"))
	var popup_events := build_damage_popup_events(prev_target, next_target, color_name, active_color, status)
	var matched_item = null
	for art_id in inventory.artifacts:
		var art = inventory.artifacts[art_id]
		if str(art.energy_type) == active_color and art.item_type == "drill":
			matched_item = art; break
	_append_localized_log(
		"#ffd766",
		"log.combat.item_activated",
		[
			_artifact_display_name(matched_item) if matched_item else TextCatalogScript.t("log.inventory.unknown_drill"),
			_display_color_name(active_color)
		]
	)
	_append_localized_log(
		"#66c2cd",
		"log.combat.hit_result",
		[
			cell_id.to_upper(),
			_display_color_name(active_color),
			_display_color_name(color_name),
			"%.1f" % damage
		]
	)
	if status == "empty_queue":
		_append_localized_log("#ff6666", "log.combat.empty_queue")
	if not should_continue_hold_fire(current_scene, is_holding):
		is_holding = false
	var hit_pos = view.get_cell_global_pos(cell_id)
	var start_pos = view.get_extractor_global_pos()
	view.trigger_resonance_beam(start_pos, hit_pos, active_color)
	view.trigger_hit_particles(hit_pos, status, active_color)
	view.trigger_damage_popups(popup_events)
	var shake_feedback: Dictionary = CombatFeedbackPresenterScript.project_screenshake(status)
	view.trigger_screenshake(float(shake_feedback.get("duration", 0.08)), float(shake_feedback.get("magnitude", 1.0)))
	disabled_tiles.append(cell_id)
	_schedule_disabled_tile_release(cell_id, 0.5)
	_render_scene(current_scene)
	if status != "empty_queue" and view.battlefield_ui != null and view.battlefield_ui.has_method("play_miner_pose_for_cell"):
		view.battlefield_ui.play_miner_pose_for_cell(cell_id)

# ?ㅽ뻾: handle hold-to-fire loop ticks.
func _trigger_hold_fire() -> void:
	if battle_pause_active:
		is_holding = false
		return
	if not should_continue_hold_fire(current_scene, is_holding):
		is_holding = false
		return
	_on_cell_clicked(hold_cell_id, hold_color)
	if not should_continue_hold_fire(current_scene, is_holding):
		is_holding = false
		return
	await get_tree().create_timer(0.1).timeout
	_trigger_hold_fire()

func _schedule_disabled_tile_release(cell_id: String, duration: float) -> void:
	var remaining := maxf(0.0, duration)
	for entry in _disabled_tile_release_queue:
		if str(entry.get("cellId", "")) == cell_id:
			entry["remaining"] = remaining
			return
	_disabled_tile_release_queue.append({
		"cellId": cell_id,
		"remaining": remaining
	})

func _tick_disabled_tile_release_queue(delta: float) -> void:
	var did_release := false
	for index in range(_disabled_tile_release_queue.size() - 1, -1, -1):
		var entry: Dictionary = _disabled_tile_release_queue[index]
		var next_remaining := float(entry.get("remaining", 0.0)) - maxf(0.0, delta)
		if next_remaining > 0.0:
			entry["remaining"] = next_remaining
			_disabled_tile_release_queue[index] = entry
			continue
		_disabled_tile_release_queue.remove_at(index)
		disabled_tiles.erase(str(entry.get("cellId", "")))
		did_release = true
	if did_release and str(current_scene.get("phase", "")) == "combat":
		_render_scene(current_scene)

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
	if held_artifact == null:
		return false
	if held_artifact.item_type == "drill":
		var has_same_color := false
		for art_id in inventory.artifacts:
			var art = inventory.artifacts[art_id]
			if art.item_type == "drill" and art.energy_type == held_artifact.energy_type and art.id != held_artifact.id:
				has_same_color = true
				break
		if has_same_color:
			_append_localized_log("#ff6666", "log.inventory.duplicate_drill", [_display_color_name(str(held_artifact.energy_type))])
			return false
	if not inventory.can_place_artifact(held_artifact, int(coord.x), int(coord.y)):
		_append_localized_log("#ff6666", "log.inventory.invalid_placement")
		return false

	var placed_artifact = held_artifact
	var before_growth: Dictionary = growth_state.to_dict()
	var placed_artifact_id := str(placed_artifact.id)
	var claimed_reward_index := held_reward_index
	inventory.place_artifact(placed_artifact, int(coord.x), int(coord.y))
	_append_localized_log("#a3be8c", "log.inventory.artifact_placed", [_artifact_display_name(placed_artifact)])
	inspected_reward_index = -1
	inspected_backpack_artifact = placed_artifact

	if held_from_rewards and claimed_reward_index >= 0 and claimed_reward_index < local_rewards_list.size():
		var reward_data = local_rewards_list[claimed_reward_index]
		var next_s = preview_controller.run.apply_combat_input({
			"type": "claim_reward_effect",
			"reward": reward_data
		})
		var after_growth: Dictionary = next_s.get("growth", {}).duplicate(true)
		growth_state.from_dict(after_growth)
		current_scene = next_s
		_append_localized_log("#a3be8c", "log.progress.reward_claimed")
		_emit_ui_telemetry(
			BuildRewardTelemetryScript.build_reward_selected(
				_selected_node_context(),
				reward_data,
				{
					"inventory_diff": {"added": [placed_artifact_id]},
					"gold_delta": int(after_growth.get("gold", 0)) - int(before_growth.get("gold", 0)),
					"xp_delta": int(after_growth.get("xp", 0)) - int(before_growth.get("xp", 0))
				}
			)
		)
		local_rewards_list.remove_at(claimed_reward_index)
		_sync_reward_inspection_after_removal(claimed_reward_index)
		if preview_controller.run != null:
			preview_controller.run.state["pendingRewards"] = local_rewards_list.duplicate(true)

	held_reward_index = -1
	held_from_rewards = false
	held_artifact = null
	held_inventory_origin = Vector2(-1, -1)
	view.update_backpack_ghost(null)

	_apply_growth_modifiers()
	view.render_backpack(inventory)
	if preview_controller.run != null:
		preview_controller.run.state["inventory"] = inventory.to_dict()
	_recalculate_queue_colors()
	current_scene = preview_controller.get_scene()
	_render_scene(current_scene)
	return true

func _clear_reward_drag_hold() -> void:
	held_reward_index = -1
	held_from_rewards = false
	held_artifact = null
	held_inventory_origin = Vector2(-1, -1)
	view.update_backpack_ghost(null)

func _sync_reward_inspection_after_removal(removed_index: int) -> void:
	if inspected_reward_index == removed_index:
		inspected_reward_index = -1
	elif inspected_reward_index > removed_index:
		inspected_reward_index -= 1

func _discard_current_held_reward() -> void:
	var discarded_reward_data: Dictionary = {}
	if held_reward_index >= 0 and held_reward_index < local_rewards_list.size():
		discarded_reward_data = local_rewards_list[held_reward_index].duplicate(true)
	if held_reward_index >= 0 and held_reward_index < local_rewards_list.size():
		local_rewards_list.remove_at(held_reward_index)
		_sync_reward_inspection_after_removal(held_reward_index)
		if preview_controller.run != null:
			preview_controller.run.state["pendingRewards"] = local_rewards_list.duplicate(true)
	_emit_ui_telemetry({
		"event": "reward_discarded",
		"source": "reward_tray",
		"reward_id": str(discarded_reward_data.get("rewardId", "")),
		"artifact_id": str(held_artifact.id),
		"artifact_name": str(held_artifact.name)
	})
	_clear_reward_drag_hold()
	current_scene = preview_controller.get_scene()
	_render_scene(current_scene)

func _reward_board_drag_rearrange_active() -> bool:
	return str(current_scene.get("phase", "")) == "reward_loot" and not _reward_ceremony_active()

func _artifact_at_coord(coord: Vector2):
	if inventory == null:
		return null
	if coord.x < 0.0 or coord.y < 0.0:
		return null
	if int(coord.y) >= inventory.grid.size() or int(coord.x) >= inventory.grid[int(coord.y)].size():
		return null
	var slot_id := str(inventory.grid[int(coord.y)][int(coord.x)])
	if slot_id.is_empty() or not inventory.artifacts.has(slot_id):
		return null
	return inventory.artifacts[slot_id]

func _discard_current_held_inventory_artifact() -> void:
	if held_artifact == null or held_from_rewards:
		return
	_append_localized_log("#e05353", "log.inventory.discarded", [_artifact_display_name(held_artifact)])
	_emit_ui_telemetry({
		"event": "reward_discarded",
		"source": "backpack",
		"artifact_id": str(held_artifact.id),
		"artifact_name": str(held_artifact.name)
	})
	inspected_backpack_artifact = null
	held_inventory_origin = Vector2(-1, -1)
	held_artifact = null
	held_from_rewards = false
	held_reward_index = -1
	view.update_backpack_ghost(null)
	if preview_controller.run != null:
		preview_controller.run.state["inventory"] = inventory.to_dict()
	_recalculate_queue_colors()
	current_scene = preview_controller.get_scene()
	_render_scene(current_scene)

func _restore_held_inventory_drag() -> void:
	if held_artifact == null or held_from_rewards:
		return
	if held_inventory_origin.x >= 0.0 and held_inventory_origin.y >= 0.0:
		inventory.place_artifact(held_artifact, int(held_inventory_origin.x), int(held_inventory_origin.y))
	inspected_backpack_artifact = held_artifact
	held_artifact = null
	held_from_rewards = false
	held_reward_index = -1
	held_inventory_origin = Vector2(-1, -1)
	view.update_backpack_ghost(null)
	view.render_backpack(inventory)
	if preview_controller.run != null:
		preview_controller.run.state["inventory"] = inventory.to_dict()
	current_scene = preview_controller.get_scene()
	_render_scene(current_scene)

func _on_backpack_slot_clicked(coord: Vector2) -> void:
	if str(current_scene.get("phase", "")) == "combat":
		_append_localized_log("#ff6666", "log.inventory.combat_locked"); return
	if _reward_ceremony_active():
		return
	if _reward_board_drag_rearrange_active():
		if held_artifact != null:
			return
		var inspected_artifact = _artifact_at_coord(coord)
		if inspected_artifact == null:
			return
		inspected_reward_index = -1
		inspected_backpack_artifact = inspected_artifact
		_clear_floating_tooltip()
		_render_rewards(current_scene)
		return

	if held_artifact != null:
		_place_held_artifact_at(coord)
		return
	var slot_artifact = _artifact_at_coord(coord)
	if slot_artifact != null:
		held_artifact = slot_artifact
		held_from_rewards = false
		held_reward_index = -1
		inspected_reward_index = -1
		inspected_backpack_artifact = null
		inventory.remove_artifact(str(slot_artifact.id))
		_append_localized_log("#ffd766", "log.inventory.artifact_selected", [_artifact_display_name(held_artifact)])
		view.update_backpack_ghost(held_artifact)
		view.render_backpack(inventory)
		if preview_controller.run != null: preview_controller.run.state["inventory"] = inventory.to_dict()

func _on_backpack_slot_drag_started(coord: Vector2) -> void:
	if not _reward_board_drag_rearrange_active() or held_artifact != null:
		return
	var dragged_artifact = _artifact_at_coord(coord)
	if dragged_artifact == null:
		return
	inspected_reward_index = -1
	inspected_backpack_artifact = dragged_artifact
	held_artifact = dragged_artifact
	held_from_rewards = false
	held_reward_index = -1
	held_inventory_origin = coord
	inventory.remove_artifact(str(dragged_artifact.id))
	_append_localized_log("#ffd766", "log.inventory.artifact_selected", [_artifact_display_name(held_artifact)])
	view.update_backpack_ghost(held_artifact)
	view.render_backpack(inventory)
	if preview_controller.run != null:
		preview_controller.run.state["inventory"] = inventory.to_dict()
	_render_rewards(current_scene)

func _on_backpack_slot_drop_requested(_origin_coord: Vector2, coord: Vector2) -> void:
	if held_artifact == null or held_from_rewards:
		return
	if _place_held_artifact_at(coord):
		return
	_restore_held_inventory_drag()

func _on_backpack_slot_discard_requested(_origin_coord: Vector2) -> void:
	if held_artifact == null or held_from_rewards:
		return
	_discard_current_held_inventory_artifact()

func _on_backpack_slot_drag_canceled(_origin_coord: Vector2) -> void:
	if held_artifact == null or held_from_rewards:
		return
	_restore_held_inventory_drag()

# ?ㅽ뻾: handle slot hovered to show tooltip.
func _on_backpack_slot_hovered(coord: Vector2) -> void:
	if inventory == null or held_artifact != null:
		return
	var slot_id = str(inventory.grid[int(coord.y)][int(coord.x)])
	if not slot_id.is_empty() and inventory.artifacts.has(slot_id):
		view.show_artifact_tooltip(inventory.artifacts[slot_id])
	else:
		_clear_floating_tooltip()

# ?ㅽ뻾: handle slot unhovered to hide tooltip.
func _on_backpack_slot_unhovered(_coord: Vector2) -> void:
	_clear_floating_tooltip()

# ?ㅽ뻾: handle reward item hovered to show tooltip.
func _on_reward_meta_hovered(meta: Variant) -> void:
	if local_rewards_list.is_empty():
		return
	var idx := int(meta)
	if idx >= 0 and idx < local_rewards_list.size():
		view.show_reward_tooltip(local_rewards_list[idx], _equipped_artifacts())

# ?ㅽ뻾: handle reward item unhovered to hide tooltip.
func _on_reward_meta_unhovered(_meta: Variant) -> void:
	_clear_floating_tooltip()

func _on_reward_meta_drag_canceled(meta: Variant) -> void:
	if not held_from_rewards or held_artifact == null or held_reward_index != int(meta):
		return
	held_artifact = null
	held_from_rewards = false
	held_reward_index = -1
	view.update_backpack_ghost(null)
	_append_localized_log("#ffd766", "log.reward.selection_cleared")
	_render_rewards(current_scene)

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
			_append_localized_log("#ffd766", "log.inventory.artifact_rotated", [_artifact_display_name(held_artifact)])
			view.update_backpack_ghost(held_artifact)

# ?ㅽ뻾: render full state scene updates, delegate to sub UI systems.
func _render_scene(scene: Dictionary) -> void:
	current_scene = _decorate_scene(scene)
	scene = current_scene
	if str(scene.get("phase", "")) == "run_complete" and not bool(scene.get("failed", false)):
		campaign_progress = scene.get("progress", campaign_progress).duplicate(true)
	_sync_battle_pause_from_overlay_visibility()
	var phase := str(scene.get("phase", "unknown"))
	if phase != prev_phase:
		_clear_floating_tooltip()
		if phase != "reward_loot":
			inspected_backpack_artifact = null
			held_inventory_origin = Vector2(-1, -1)
		if phase == "reward_loot" and prev_phase == "combat":
			show_victory_overlay = false
			var server_rewards = scene.get("reward", {}).get("pendingRewards", [])
			local_rewards_list = server_rewards.duplicate(true)
			inspected_reward_index = -1
			inspected_backpack_artifact = null
			var ceremony_steps := RewardCeremonyPolicyScript.step_sequence()
			reward_presentation_step = str(ceremony_steps[0]) if not local_rewards_list.is_empty() else "tray_review"
			is_reveal_vfx_running = not local_rewards_list.is_empty()
			_append_localized_log("#ffd766", "log.phase.reward_chamber_opened")
			if is_reveal_vfx_running:
				call_deferred("_start_reward_ceremony")
			_append_localized_log("#ffd766", "log.phase.leviathan_mined")

		if phase == "node_select":
			_append_localized_log("#8fa1b3", "log.phase.node_select")
		elif phase == "combat":
			_append_localized_log("#8fa1b3", "log.phase.combat")
		elif phase == "reward_loot" and not show_victory_overlay:
			_append_localized_log("#8fa1b3", "log.phase.reward_loot")
		elif phase == "run_complete":
			_append_localized_log("#e05353" if bool(scene.get("failed", false)) else "#a3be8c", "log.phase.run_failed" if bool(scene.get("failed", false)) else "log.phase.run_complete")
		prev_phase = phase
	current_scene["show_victory_overlay"] = show_victory_overlay
	current_scene["is_reveal_vfx_running"] = is_reveal_vfx_running
	current_scene["rewardPresentationStep"] = reward_presentation_step
	current_scene["selectedNodeIndex"] = selected_node_index
	current_scene["selectedStartColor"] = selected_start_color
	current_scene["allowStartColorSelection"] = _allow_start_color_selection(current_scene)
	current_scene["loadoutColors"] = node_map_loadout_colors_for_scene(current_scene)
	if phase == "combat":
		var pin_active = bool(scene.get("hud", {}).get("pin", {}).get("active", false))
		if pin_active != prev_pin_active:
			_append_localized_log("#e05353" if pin_active else "#a3be8c", "log.pin.enabled" if pin_active else "log.pin.disabled")
			prev_pin_active = pin_active
		var hazard_sev = str(scene.get("hud", {}).get("hazard", {}).get("severity", "stable"))
		if hazard_sev != prev_hazard_severity:
			if hazard_sev == "active":
				_append_localized_log("#e05353", "log.hazard.active")
			elif hazard_sev == "critical":
				_append_localized_log("#e05353", "log.hazard.critical")
			elif hazard_sev == "stable":
				_append_localized_log("#a3be8c", "log.hazard.stable")
			prev_hazard_severity = hazard_sev
	view.render_scene(current_scene, show_victory_overlay)
	_render_battlefield(current_scene)
	view.update_action_state(current_scene, show_victory_overlay)
	_render_rewards(current_scene)

# ?ㅽ뻾: delegate battlefield rendering to the view.
func _render_battlefield(scene: Dictionary) -> void:
	if not is_reveal_vfx_running:
		view.update_battlefield_disabled(scene, disabled_tiles)

# ?ㅽ뻾: render the interactive reward looting list.
func _render_rewards(scene: Dictionary) -> void:
	if str(scene.get("phase", "")) != "reward_loot":
		_clear_floating_tooltip()
		return
	var server_rewards = scene.get("reward", {}).get("pendingRewards", [])
	if local_rewards_list.is_empty() and not server_rewards.is_empty():
		local_rewards_list = server_rewards.duplicate(true)
	if local_rewards_list.is_empty():
		inspected_reward_index = -1
	elif inspected_reward_index >= local_rewards_list.size():
		inspected_reward_index = local_rewards_list.size() - 1
	if inspected_backpack_artifact != null and held_artifact != inspected_backpack_artifact and (inventory == null or not inventory.artifacts.has(str(inspected_backpack_artifact.id))):
		inspected_backpack_artifact = null
	var reward_model: Dictionary = RewardReadModelScript.project_tray(local_rewards_list, held_reward_index, held_artifact, held_from_rewards, inspected_reward_index, inspected_backpack_artifact)
	_clear_floating_tooltip()
	view.render_reward_tray(reward_model)

# 실행: clear the floating tooltip when its hover source is no longer authoritative.
func _clear_floating_tooltip() -> void:
	if view != null and view.has_method("hide_artifact_tooltip"):
		view.hide_artifact_tooltip()

# 실행: select and package artifact reward.
func _on_reward_meta_clicked(meta: Variant) -> void:
	if _reward_ceremony_active():
		return
	var clicked_idx := int(meta)
	if held_from_rewards and held_reward_index == clicked_idx and held_artifact != null:
		held_artifact = null
		held_from_rewards = false
		held_reward_index = -1
		view.update_backpack_ghost(null)
		_append_localized_log("#ffd766", "log.reward.selection_cleared")
		_render_rewards(current_scene)
		return
	if clicked_idx < 0 or clicked_idx >= local_rewards_list.size():
		return

	inspected_backpack_artifact = null
	held_reward_index = clicked_idx
	var item_data = local_rewards_list[held_reward_index]
	var create_result: Dictionary = CreateArtifactFromRewardScript.create(item_data, growth_state)
	if bool(create_result.get("ok", false)):
		held_artifact = create_result["artifact"]
		held_from_rewards = true
		_append_localized_log("#ffd766", "log.reward.selection_picked", [_artifact_display_name(held_artifact), _artifact_rarity_label(held_artifact.grade)])
		_render_rewards(current_scene)
		view.update_backpack_ghost(held_artifact)
		return

# 실행: drop and delete selected reward or backpack item.
func _on_reward_meta_inspect_clicked(meta: Variant) -> void:
	if _reward_ceremony_active():
		return
	var clicked_idx := int(meta)
	if clicked_idx < 0 or clicked_idx >= local_rewards_list.size():
		return
	inspected_backpack_artifact = null
	inspected_reward_index = clicked_idx
	_render_rewards(current_scene)

func _on_reward_meta_drag_started_v2(meta: Variant) -> void:
	if _reward_ceremony_active() or held_artifact != null:
		return
	var dragged_idx := int(meta)
	if dragged_idx < 0 or dragged_idx >= local_rewards_list.size():
		return
	inspected_backpack_artifact = null
	inspected_reward_index = dragged_idx
	held_reward_index = dragged_idx
	var item_data = local_rewards_list[held_reward_index]
	var create_result: Dictionary = CreateArtifactFromRewardScript.create(item_data, growth_state)
	if bool(create_result.get("ok", false)):
		held_artifact = create_result["artifact"]
		held_from_rewards = true
		_append_localized_log("#ffd766", "log.reward.selection_picked", [_artifact_display_name(held_artifact), _artifact_rarity_label(held_artifact.grade)])
		view.update_backpack_ghost(held_artifact)

func _on_reward_meta_drop_requested_v2(meta: Variant, coord: Vector2) -> void:
	if _reward_ceremony_active():
		return
	if held_artifact == null or not held_from_rewards or held_reward_index != int(meta):
		return
	if _place_held_artifact_at(coord):
		return
	_clear_reward_drag_hold()
	_render_rewards(current_scene)

func _on_reward_meta_discard_requested_v2(meta: Variant) -> void:
	if _reward_ceremony_active():
		return
	if held_artifact == null or not held_from_rewards or held_reward_index != int(meta):
		return
	_discard_current_held_reward()

func _on_reward_meta_drag_canceled_v2(meta: Variant) -> void:
	if held_artifact == null or not held_from_rewards or held_reward_index != int(meta):
		return
	_clear_reward_drag_hold()
	_render_rewards(current_scene)

func _on_discard_zone_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _reward_ceremony_active():
			return
		if held_artifact != null:
			if held_from_rewards:
				_discard_current_held_reward()
			else:
				_discard_current_held_inventory_artifact()

# ?ㅽ뻾: start a new combat stage.
func _on_start_pressed() -> void:
	if is_inside_tree():
		if _start_transition_pending:
			return
		_start_transition_pending = true
		call_deferred("_commit_start_pressed_transition")
		return
	_perform_start_pressed_transition()

func _commit_start_pressed_transition() -> void:
	_start_transition_pending = false
	_perform_start_pressed_transition()

func _perform_start_pressed_transition() -> void:
	if not page_override_id.is_empty():
		return
	_clear_reward_ceremony_state()
	_set_battle_pause_active(false)
	_disabled_tile_release_queue.clear()
	disabled_tiles.clear()
	weakness_shift_step = 0
	_apply_growth_modifiers()
	current_scene = preview_controller.start_combat(selected_node_index)
	_recalculate_queue_colors()
	_ensure_combat_terrain_markers()
	current_scene = preview_controller.get_scene()
	var current_target := _current_target(current_scene)
	current_scene = preview_controller.aim_cell(str(current_target.get("cellId", "r0c0")), resolve_target_color_for_interaction(str(current_target.get("color", "")), _get_active_queue_color()))
	_render_scene(current_scene)

# ?ㅽ뻾: reset run state.
func _on_reset_pressed() -> void:
	_clear_reward_ceremony_state()
	_set_battle_pause_active(false)
	page_override_id = "character_select"
	selected_node_index = 0
	weakness_shift_step = 0
	randomize()
	_rebuild_preview_controller(randi() & 0x7fffffff)
	preview_controller.start_color = selected_start_color
	current_scene = preview_controller.reset()
	disabled_tiles.clear(); _disabled_tile_release_queue.clear(); local_rewards_list.clear(); held_reward_index = -1; held_artifact = null; held_from_rewards = false; inspected_reward_index = -1; inspected_backpack_artifact = null; held_inventory_origin = Vector2(-1, -1)
	view.set_confirm_overlay_visible(false)
	view.update_backpack_ghost(null)

	# Apply growth passive starting gold values
	growth_state.gold = growth_state.get_starting_gold()
	growth_state.xp = 0
	preview_controller.run.state["growth"] = growth_state.to_dict()

	_load_backpack_items_into_inventory()
	view.render_backpack(inventory)
	_recalculate_queue_colors()
	_render_scene(current_scene)

# ?ㅽ뻾: trigger hold fire simulation.
func _on_hold_fire_pressed() -> void:
	if battle_pause_active:
		return
	var current_target := _current_target(current_scene)
	current_scene = preview_controller.hold_fire(
		str(current_target.get("cellId", "r0c0")),
		resolve_target_color_for_interaction(str(current_target.get("color", "")), _get_active_queue_color()),
		hold_fire_burst_count(accessibility_state)
	)
	_render_scene(current_scene)

# ?ㅽ뻾: request repair on heated core.
func _on_repair_pressed() -> void:
	if battle_pause_active:
		return
	current_scene = preview_controller.repair()
	_render_scene(current_scene)

# ?ㅽ뻾: claim rewards and proceed, showing confirmation warning if rewards are left.
func _on_claim_rewards_pressed() -> void:
	if not local_rewards_list.is_empty():
		view.set_confirm_overlay_visible(true)
	else:
		_proceed_to_node_select()

# ?ㅽ뻾: confirm and proceed to node select even with remaining rewards.
func _on_confirm_proceed_pressed() -> void:
	view.set_confirm_overlay_visible(false)
	_proceed_to_node_select()

# ?ㅽ뻾: cancel proceeding and return to reward looting.
func _on_confirm_cancel_pressed() -> void:
	view.set_confirm_overlay_visible(false)

# ?ㅽ뻾: execute reward claim and transition.
func _proceed_to_node_select() -> void:
	current_scene = preview_controller.claim_rewards()
	_clear_reward_ceremony_state()
	_set_battle_pause_active(false)
	_disabled_tile_release_queue.clear()
	disabled_tiles.clear()
	local_rewards_list.clear(); held_reward_index = -1; held_artifact = null; held_from_rewards = false; inspected_reward_index = -1; inspected_backpack_artifact = null; held_inventory_origin = Vector2(-1, -1)
	selected_node_index = 0
	view.update_backpack_ghost(null)
	_render_scene(current_scene)

# ?ㅽ뻾: load starter backpack items.
func _load_backpack_items_into_inventory() -> void:
	inventory = InventoryModel.new(8, 8)
	var loadout = ArtifactScript.get_starter_loadout(selected_start_color)
	var positions = ArtifactScript.get_starter_loadout_positions()
	for i in range(loadout.size()):
		inventory.place_artifact(loadout[i], int(positions[i].x), int(positions[i].y))
	_apply_growth_modifiers()
	if preview_controller != null and preview_controller.run != null:
		preview_controller.run.state["inventory"] = inventory.to_dict()

# ?ㅽ뻾: replace the starter inventory when the node-map start color changes.
func _on_loadout_color_selected(color: String) -> void:
	if not _allow_start_color_selection():
		return
	if not color in ["red", "blue", "purple", "green"]:
		return
	selected_start_color = color
	if preview_controller != null:
		preview_controller.start_color = selected_start_color
	if str(current_scene.get("phase", "")) == "node_select":
		_load_backpack_items_into_inventory()
		view.render_backpack(inventory)
		current_scene = preview_controller.get_scene()
		_render_scene(current_scene)
		if view.has_method("is_artifact_codex_visible") and view.is_artifact_codex_visible():
			var reward_table: Dictionary = view.current_codex_reward_table.duplicate(true)
			if reward_table.is_empty():
				reward_table = _load_reward_table_for_codex()
			view.render_artifact_codex(reward_table, _codex_growth_state_for_view(reward_table), bool(view.current_codex_debug_all))

func _on_character_selected(character_id: String) -> void:
	if character_id.is_empty():
		return
	for character in character_roster:
		if str(character.get("id", "")) != character_id:
			continue
		if not bool(character.get("selectable", false)):
			return
		selected_character_id = character_id
		_render_scene(current_scene)
		return

func _on_character_continue_pressed() -> void:
	page_override_id = "leviathan_select"
	_render_scene(current_scene)

func _on_leviathan_selected(leviathan_id: String) -> void:
	if leviathan_id.is_empty():
		return
	selected_leviathan_id = leviathan_id
	_render_scene(current_scene)

func _on_looting_start_pressed() -> void:
	_clear_reward_ceremony_state()
	_set_battle_pause_active(false)
	_disabled_tile_release_queue.clear()
	disabled_tiles.clear()
	weakness_shift_step = 0
	_rebuild_preview_controller(randi() & 0x7fffffff)
	current_scene = preview_controller.reset()
	preview_controller.start_color = selected_start_color
	if preview_controller != null and preview_controller.run != null:
		preview_controller.run.state["selectedCharacter"] = selected_character_id
	page_override_id = ""
	_load_backpack_items_into_inventory()
	view.render_backpack(inventory)
	_recalculate_queue_colors()
	_render_scene(current_scene)

func _on_return_to_character_select_pressed() -> void:
	_on_reset_pressed()

# ?ㅽ뻾: cycle active item colors to fill queue.
func _recalculate_queue_colors() -> void:
	var run_state = preview_controller.run.state if preview_controller and preview_controller.run else null
	if run_state and run_state.has("combat") and run_state["combat"] != null:
		var queue_state: Dictionary = run_state["combat"].get("queue", {})
		var capacity := int(queue_state.get("capacity", EnergyTempoBalanceScript.DEFAULT_QUEUE_CAPACITY))
		var loaded_count := int(queue_state.get("items", []).size())
		if not queue_state.has("items"):
			loaded_count = EnergyTempoBalanceScript.initial_queue_loaded_count(capacity)
		var queue_result: Dictionary = RecalculateQueueColorsScript.recalculate(inventory, capacity, loaded_count)
		run_state["combat"]["queue"]["items"] = queue_result.get("items", [])

func is_battle_pause_active() -> bool:
	return battle_pause_active

func _on_combat_overlay_pause_visibility_changed(_active: bool) -> void:
	_sync_battle_pause_from_overlay_visibility()

func _sync_battle_pause_from_overlay_visibility() -> void:
	var overlay_visible := false
	if view != null and view.has_method("is_combat_pause_overlay_visible"):
		overlay_visible = bool(view.is_combat_pause_overlay_visible())
	_set_battle_pause_active(overlay_visible and str(current_scene.get("phase", "")) == "combat")

func _set_battle_pause_active(active: bool) -> void:
	if battle_pause_active == active:
		return
	battle_pause_active = active
	if active:
		is_holding = false
		_set_shift_timer_paused(true)
	else:
		_set_shift_timer_paused(false)
	if view != null and view.has_method("set_battle_pause_active"):
		view.set_battle_pause_active(active)

func _set_shift_timer_paused(paused: bool) -> void:
	if shift_timer == null:
		return
	if paused:
		_paused_shift_time_left = shift_timer.time_left if not shift_timer.is_stopped() else shift_timer.wait_time
		shift_timer.stop()
		return
	var resume_time := _paused_shift_time_left
	_paused_shift_time_left = -1.0
	if resume_time > 0.0:
		shift_timer.start(resume_time)
	elif shift_timer.is_stopped():
		shift_timer.start(TERRAIN_SHIFT_SECONDS)

# ?ㅽ뻾: setup conveyor-belt shift timer.
func _setup_shift_timer() -> void:
	shift_timer = Timer.new()
	shift_timer.wait_time = TERRAIN_SHIFT_SECONDS; shift_timer.autostart = true
	shift_timer.timeout.connect(_on_shift_timer_timeout)
	add_child(shift_timer)

# ?ㅽ뻾: shift weaknesses left-to-right on timeout.
func _on_shift_timer_timeout() -> void:
	if battle_pause_active:
		return
	if str(current_scene.get("phase", "")) != "combat": return
	var colors := EnergyTempoBalanceScript.terrain_color_palette()
	weakness_shift_step += 1
	current_scene = preview_controller.run.apply_combat_input({
		"type": "shift_battlefield",
		"ticks": TERRAIN_SHIFT_TICKS,
		"shiftSeed": int(preview_controller.run.state.get("seed", randi())),
		"shiftStep": weakness_shift_step,
		"colors": colors
	})
	if str(current_scene.get("phase", "")) != "combat":
		_render_scene(current_scene); return
	var run_state = preview_controller.run.state
	var inv_data = run_state.get("inventory", {})
	if inv_data is Dictionary:
		inventory = InventoryModel.new(int(inv_data.get("width", 8)), int(inv_data.get("height", 8)))
		if inv_data.has("artifacts"):
			for art_dict in inv_data["artifacts"]:
				var art = ArtifactScript.new(art_dict)
				inventory.place_artifact(art, art.x, art.y)
	_apply_growth_modifiers()
	view.render_backpack(inventory)
	current_scene = preview_controller.get_scene()
	_render_scene(current_scene)

# ?ㅽ뻾: initialize weaknesses.
func _ensure_combat_terrain_markers() -> void:
	if not current_scene.has("combat") or current_scene["combat"] == null: return
	var run_state = preview_controller.run.state
	if not run_state.has("combat") or run_state["combat"] == null: return
	var battlefield: Dictionary = run_state["combat"].get("battlefield", {})
	if not battlefield.get("weaknessMarkers", []).is_empty():
		return
	run_state["combat"]["battlefield"]["weaknessMarkers"] = _terrain_markers_for_colors(
		EnergyTempoBalanceScript.terrain_color_palette(),
		int(battlefield.get("rows", 3)),
		int(battlefield.get("columns", 10))
	)
	current_scene = preview_controller.get_scene()

func _active_combat_terrain_colors(_run_state: Dictionary) -> Array:
	return EnergyTempoBalanceScript.terrain_color_palette()

func _terrain_markers_for_colors(_colors: Array, rows: int, columns: int) -> Array:
	var run_seed := 1
	if preview_controller != null and preview_controller.run != null:
		run_seed = int(preview_controller.run.state.get("seed", 1))
	return EnergyTempoBalanceScript.terrain_markers(rows, columns, run_seed, weakness_shift_step)

# ?ㅽ뻾: helper to get queue front color.
func _get_active_queue_color() -> String:
	var items: Array = current_scene.get("hud", {}).get("queue", {}).get("items", [])
	if items.is_empty():
		return "red"
	return str(items[0].get("color", "")) if items[0] is Dictionary else str(items[0])

# 실행: return current inventory artifacts as an array for tooltip comparison.
func _equipped_artifacts() -> Array:
	var result: Array = []
	if inventory == null:
		return result
	for art_id in inventory.artifacts:
		result.append(inventory.artifacts[art_id])
	return result

# 실행: return a localized artifact name for player-facing logs.
func _artifact_display_name(artifact) -> String:
	if artifact == null:
		return ""
	return TextCatalogScript.localized_text(artifact.text, "name", TextCatalogScript.display_name(str(artifact.name)))

func _artifact_rarity_label(raw_rarity: Variant) -> String:
	var rarity := str(raw_rarity).to_lower()
	var key := "rarity.%s" % rarity
	var label := TextCatalogScript.t(key)
	return str(raw_rarity) if label == key else label

func _display_color_name(raw_color: String) -> String:
	var color_name := raw_color.to_lower()
	if color_name in ["red", "blue", "purple", "green"]:
		return TextCatalogScript.color_label(color_name)
	return raw_color.to_upper()

func _passive_display_label(passive_id: String) -> String:
	var key := "passive.%s.name" % passive_id
	var label := TextCatalogScript.t(key)
	return passive_id if label == key else label

func _base_shop_item_display_label(item_id: String) -> String:
	return TextCatalogScript.base_shop_label(item_id, item_id)

func _toggle_state_label(enabled: bool) -> String:
	return TextCatalogScript.t("common.on" if enabled else "common.off")

func _append_localized_log(color_hex: String, key: String, args: Array = []) -> void:
	if view == null:
		return
	view.add_log("[color=%s]%s[/color]" % [color_hex, TextCatalogScript.t(key, args)])

# ?ㅽ뻾: helper to summarize node select candidates.
func _node_select_summary(scene: Dictionary) -> String:
	return str(NodeSelectReadModelScript.project(scene, selected_node_index).get("text", ""))

# 실행: helper to get best target coordinate.
func _current_target(scene: Dictionary) -> Dictionary:
	var aim = scene.get("hud", {}).get("aim", {})
	if aim.get("cellId", null) != null and aim.get("targetColor", null) != null:
		return {"cellId": aim.get("cellId", "r0c0"), "color": aim.get("targetColor", "red")}
	for cell in scene.get("terrain", {}).get("cells", []):
		if cell.get("weakness", null) != null:
			return {"cellId": cell.get("id", "r0c0"), "color": cell.get("weakness", "red")}
	return {"cellId": "r0c0", "color": "red"}

static func resolve_target_color_for_interaction(cell_color_name: String, active_queue_color: String) -> String:
	var resolved_cell_color := str(cell_color_name)
	if resolved_cell_color.is_empty() or resolved_cell_color == "normal":
		return str(active_queue_color)
	return resolved_cell_color

static func should_continue_hold_fire(scene: Dictionary, holding: bool) -> bool:
	if not holding:
		return false
	if str(scene.get("phase", "")) != "combat":
		return false
	if str(scene.get("feedback", {}).get("status", "")) == "empty_queue":
		return false
	var hud: Dictionary = scene.get("hud", {})
	if bool(hud.get("repair", {}).get("active", false)):
		return false
	if not bool(hud.get("aim", {}).get("canFire", true)):
		return false
	var queue_items: Array = hud.get("queue", {}).get("items", [])
	return not queue_items.is_empty()

static func can_accept_combat_click(scene: Dictionary, cell_id: String, disabled: Array[String]) -> bool:
	if str(scene.get("phase", "")) != "combat":
		return false
	if cell_id in disabled:
		return false
	var hud: Dictionary = scene.get("hud", {})
	if bool(hud.get("repair", {}).get("active", false)):
		return false
	return bool(hud.get("aim", {}).get("canFire", true))

static func build_damage_popup_events(prev_target: Dictionary, next_target: Dictionary, hit_tile_color: String, fallback_color: String = "", status: String = "") -> Array:
	if status == "empty_queue":
		return []
	var shield_damage := maxf(0.0, float(prev_target.get("shield", 0.0)) - float(next_target.get("shield", 0.0)))
	var health_damage := maxf(0.0, float(prev_target.get("health", 0.0)) - float(next_target.get("health", 0.0)))
	var resolved_color := hit_tile_color if not hit_tile_color.is_empty() and hit_tile_color != "normal" else fallback_color
	if resolved_color.is_empty():
		resolved_color = "red"
	var events: Array = []
	if shield_damage > 0.0:
		events.append({"channel": "shield", "amount": shield_damage, "color": resolved_color, "prefix": "SP"})
	if health_damage > 0.0:
		events.append({"channel": "health", "amount": health_damage, "color": resolved_color, "prefix": "HP"})
	return events

# ?ㅽ뻾: handle calibration shop button toggle.
func _on_shop_open_pressed() -> void:
	if _reward_ceremony_active():
		return
	view.toggle_shop()
	view.render_shop(growth_state.to_dict())

# 실행: open the artifact codex with play-history discovery data.
func _on_codex_open_pressed() -> void:
	if _reward_ceremony_active():
		return
	var reward_table := _load_reward_table_for_codex()
	view.toggle_artifact_codex(
		reward_table,
		_codex_growth_state_for_view(reward_table),
		false
	)

# 실행: load the reward table for the codex menu without changing reward RNG state.
func _load_reward_table_for_codex() -> Dictionary:
	var path := "res://src/data/reward-table.json"
	if not FileAccess.file_exists(path):
		return {"rewards": []}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"rewards": []}
	var parsed = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {"rewards": []}

func _codex_growth_state_for_view(reward_table: Dictionary) -> Dictionary:
	var starter_growth := codex_growth_state_with_starter_discoveries(growth_state.to_dict(), reward_table, selected_start_color)
	return codex_growth_state_for_debug(starter_growth, reward_table, codex_force_all_discovered)

func _toggle_codex_force_all_discovered() -> void:
	codex_force_all_discovered = not codex_force_all_discovered
	_append_localized_log("#c8a96b", "log.debug.codex_discovery_toggle", [_toggle_state_label(codex_force_all_discovered)])
	if not (view.has_method("is_artifact_codex_visible") and view.is_artifact_codex_visible()):
		return
	var reward_table: Dictionary = view.current_codex_reward_table.duplicate(true)
	if reward_table.is_empty():
		reward_table = _load_reward_table_for_codex()
	var codex_growth := _codex_growth_state_for_view(reward_table)
	view.render_artifact_codex(reward_table, codex_growth, bool(view.current_codex_debug_all))

# ?ㅽ뻾: handle buy passive.
func _on_buy_passive(passive_id: String, cost: int) -> void:
	var before_growth: Dictionary = growth_state.to_dict()
	var next_s = preview_controller.run.apply_combat_input({
		"type": "purchase_passive",
		"passiveId": passive_id,
		"cost": cost
	})
	var after_growth: Dictionary = next_s.get("growth", {}).duplicate(true)
	growth_state.from_dict(after_growth)
	current_scene = next_s
	_apply_growth_modifiers()
	view.render_backpack(inventory)
	_render_scene(current_scene)
	view.render_shop(growth_state.to_dict())
	_append_localized_log("#a3be8c", "log.shop.passive_purchased", [_passive_display_label(passive_id), growth_state.purchased_passives[passive_id]])

	var telemetry := BuildRewardTelemetryScript.build_growth_state_changed("passive_purchase", before_growth, after_growth)
	telemetry["passive_id"] = passive_id
	telemetry["level"] = growth_state.purchased_passives[passive_id]
	telemetry["cost"] = cost
	_emit_ui_telemetry(telemetry)

# ??쎈뻬: handle base shop item or character purchases.
func _on_buy_base_item(item_id: String) -> void:
	var before_growth: Dictionary = growth_state.to_dict()
	if not growth_state.purchase_base_item(item_id):
		_append_localized_log("#bf616a", "log.shop.base_purchase_failed", [_base_shop_item_display_label(item_id)])
		view.render_shop(growth_state.to_dict())
		return
	if preview_controller != null and preview_controller.run != null:
		preview_controller.run.state["growth"] = growth_state.to_dict()
	current_scene["growth"] = growth_state.to_dict()
	view.render_shop(growth_state.to_dict())
	_render_scene(current_scene)
	_append_localized_log("#a3be8c", "log.shop.base_purchase_complete", [_base_shop_item_display_label(item_id)])
	_emit_ui_telemetry({
		"event": "base_shop_purchase",
		"item_id": item_id,
		"gold_delta": int(growth_state.to_dict().get("gold", 0)) - int(before_growth.get("gold", 0)),
		"xp_delta": int(growth_state.to_dict().get("xp", 0)) - int(before_growth.get("xp", 0))
	})

# ?ㅽ뻾: apply active growth modifiers (cooldown reduction, flat damage bonus).
func _apply_growth_modifiers() -> void:
	if inventory == null or growth_state == null:
		return
	if preview_controller != null and preview_controller.run != null:
		var tuning = preview_controller.run.state.get("tuning", {})
		if tuning is Dictionary:
			ApplyGrowthModifiersScript.apply(inventory, growth_state, tuning)

func _apply_accessibility_state() -> void:
	if view == null or view.vfx_manager == null:
		return
	if view.vfx_manager.has_method("set_accessibility_state"):
		view.vfx_manager.set_accessibility_state(accessibility_state)
		return
	view.vfx_manager.shake_enabled = bool(accessibility_state.get("screenshake", true))

func _decorate_scene(scene: Dictionary) -> Dictionary:
	var decorated := scene.duplicate(true)
	decorated["show_victory_overlay"] = show_victory_overlay
	decorated["is_reveal_vfx_running"] = is_reveal_vfx_running
	decorated["rewardPresentationStep"] = reward_presentation_step
	decorated["selectedNodeIndex"] = selected_node_index
	decorated["selectedStartColor"] = selected_start_color
	decorated["allowStartColorSelection"] = _allow_start_color_selection(decorated)
	decorated["loadoutColors"] = node_map_loadout_colors_for_scene(decorated)
	decorated["characterRoster"] = character_roster.duplicate(true)
	decorated["leviathanRoster"] = leviathan_roster.duplicate(true)
	decorated["selectedLeviathanId"] = selected_leviathan_id
	decorated["selectedLeviathan"] = _selected_leviathan_data()
	decorated["selectedCharacter"] = _selected_character_data()
	decorated["selectedNodeContext"] = _selected_node_context(decorated)
	decorated["nodeSelectSummary"] = _node_select_summary(decorated)
	decorated["pageId"] = _resolve_page_id(decorated)
	return decorated

func _resolve_page_id(scene: Dictionary) -> String:
	if not page_override_id.is_empty():
		return page_override_id
	var phase := str(scene.get("phase", "unknown"))
	var context: Dictionary = scene.get("selectedNodeContext", {})
	if phase == "node_select":
		return "node_select"
	if phase == "combat":
		return "boss_battle" if bool(context.get("is_boss", false)) else "battle"
	if phase == "reward_loot":
		return "boss_reward" if bool(context.get("is_boss", false)) else "reward"
	if phase == "run_complete":
		return "defeat" if bool(scene.get("failed", false)) else "clear"
	return phase

func _selected_node_context(scene: Dictionary = {}) -> Dictionary:
	if scene.is_empty():
		scene = current_scene
	var phase := str(scene.get("phase", ""))
	if phase == "node_select":
		var candidates: Array = scene.get("nodeSelect", {}).get("candidates", [])
		var index := clampi(int(scene.get("selectedNodeIndex", selected_node_index)), 0, maxi(0, candidates.size() - 1))
		if not candidates.is_empty() and index < candidates.size():
			var candidate: Dictionary = candidates[index]
			return {
				"node_id": str(candidate.get("id", "")),
				"node_type": str(candidate.get("nodeType", "")),
				"label": str(candidate.get("label", "")),
				"risk_tier": str(candidate.get("riskTier", "")),
				"is_boss": str(candidate.get("nodeType", "")) == "boss" or str(candidate.get("riskTier", "")) == "boss",
				"is_event": bool(candidate.get("isEvent", false)) or str(candidate.get("riskTier", "")) == "event"
			}
	if preview_controller != null and preview_controller.run != null:
		var selected_node = preview_controller.run.state.get("selectedNode", {})
		if selected_node is Dictionary:
			return {
				"node_id": str(selected_node.get("id", "")),
				"node_type": str(selected_node.get("nodeType", "")),
				"label": str(selected_node.get("label", scene.get("lastNodeLabel", ""))),
				"risk_tier": str(selected_node.get("riskTier", "")),
				"is_boss": bool(selected_node.get("isBoss", false)) or str(selected_node.get("nodeType", "")) == "boss" or str(selected_node.get("riskTier", "")) == "boss",
				"is_event": bool(selected_node.get("isEvent", false)) or str(selected_node.get("riskTier", "")) == "event"
			}
	return {"node_id": "", "node_type": "", "label": "", "risk_tier": "", "is_boss": false, "is_event": false}

func _emit_ui_telemetry(payload: Dictionary) -> void:
	if payload.is_empty():
		return
	print("TELEMETRY_JSON %s" % JSON.stringify(payload))

static func hold_fire_burst_count(state: Dictionary = {}) -> int:
	return 4 if bool(state.get("holdFireAssist", false)) else 2
