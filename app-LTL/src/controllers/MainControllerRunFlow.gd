# 怨꾩빟:
# - 梨낆엫: MainController??run lifecycle, start/reset, loadout, character/leviathan selection, reward proceed ?먮쫫???뚯쑀?쒕떎.
# - ?낅젰: MainController context, selected color/id values, reward proceed button events.
# - 異쒕젰: controller run state reset/start mutations, preview-controller transitions, inventory reloads, scene render handoff.
# - 湲덉?: scene-facing signal names, combat reducer rule 蹂寃? reward/backpack placement rule 蹂寃?
#
# ?ㅽ뻾: define the run lifecycle helper as a stateful controller delegate.
extends RefCounted

const ArtifactScript = preload("res://src/models/Artifact.gd")
const InventoryModelScript = preload("res://src/models/InventoryModel.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const MainControllerCombatFlowScript = preload("res://src/controllers/MainControllerCombatFlow.gd")

# ?ㅽ뻾: queue or perform the start transition from node select into combat.
static func on_start_pressed(controller) -> void:
	if controller.is_inside_tree():
		if controller._start_transition_pending:
			return
		controller._start_transition_pending = true
		controller.call_deferred("_commit_start_pressed_transition")
		return
	perform_start_pressed_transition(controller)

# ?ㅽ뻾: complete a deferred start transition after the current input frame.
static func commit_start_pressed_transition(controller) -> void:
	controller._start_transition_pending = false
	perform_start_pressed_transition(controller)

# ?ㅽ뻾: apply node-select guards and move the preview controller into combat.
static func perform_start_pressed_transition(controller) -> void:
	if not controller.page_override_id.is_empty():
		return
	if not controller._selected_node_start_enabled(controller.current_scene):
		controller._render_scene(controller.current_scene)
		return
	controller._clear_reward_ceremony_state()
	controller._set_battle_pause_active(false)
	controller._disabled_tile_release_queue.clear()
	controller.disabled_tiles.clear()
	controller.weakness_shift_step = 0
	controller._apply_growth_modifiers()
	controller.current_scene = controller.preview_controller.start_combat(controller.selected_node_index)
	controller._recalculate_queue_colors()
	controller._ensure_combat_terrain_markers()
	controller.current_scene = controller.preview_controller.get_scene()
	var current_target := MainControllerCombatFlowScript.current_target(controller.current_scene)
	controller.current_scene = controller.preview_controller.aim_cell(
		str(current_target.get("cellId", "r0c0")),
		MainControllerCombatFlowScript.resolve_target_color_for_interaction(
			str(current_target.get("color", "")),
			MainControllerCombatFlowScript.active_queue_color(controller.current_scene)
		)
	)
	controller._render_scene(controller.current_scene)

# ?ㅽ뻾: reset run state to the character-select entry point.
static func on_reset_pressed(controller) -> void:
	controller._clear_reward_ceremony_state()
	controller._set_battle_pause_active(false)
	controller.page_override_id = "character_select"
	controller.selected_node_index = -1
	controller.weakness_shift_step = 0
	randomize()
	controller._rebuild_preview_controller(randi() & 0x7fffffff)
	controller.preview_controller.start_color = controller.selected_start_color
	controller.current_scene = controller.preview_controller.reset()
	controller.disabled_tiles.clear()
	controller._disabled_tile_release_queue.clear()
	controller.local_rewards_list.clear()
	controller.held_reward_index = -1
	controller.held_artifact = null
	controller.held_from_rewards = false
	controller.inspected_reward_index = -1
	controller.inspected_backpack_artifact = null
	controller.held_inventory_origin = Vector2(-1, -1)
	controller.view.set_confirm_overlay_visible(false)
	controller.view.update_backpack_ghost(null)

	controller.growth_state.gold = controller.growth_state.get_starting_gold()
	controller.growth_state.xp = 0
	controller.preview_controller.run.state["growth"] = controller.growth_state.to_dict()

	load_backpack_items_into_inventory(controller)
	controller.view.render_backpack(controller.inventory)
	controller._recalculate_queue_colors()
	controller._render_scene(controller.current_scene)

# ?ㅽ뻾: ask for confirmation before discarding unclaimed rewards.
static func on_claim_rewards_pressed(controller) -> void:
	if not controller.local_rewards_list.is_empty():
		controller.view.set_confirm_overlay_visible(true)
	else:
		proceed_to_node_select(controller)

# ?ㅽ뻾: proceed even when unclaimed rewards remain.
static func on_confirm_proceed_pressed(controller) -> void:
	controller.view.set_confirm_overlay_visible(false)
	proceed_to_node_select(controller)

# ?ㅽ뻾: cancel reward proceed confirmation.
static func on_confirm_cancel_pressed(controller) -> void:
	controller.view.set_confirm_overlay_visible(false)

# ?ㅽ뻾: execute reward claim and transition back to node select.
static func proceed_to_node_select(controller) -> void:
	controller.current_scene = controller.preview_controller.claim_rewards()
	controller._clear_reward_ceremony_state()
	controller._set_battle_pause_active(false)
	controller._disabled_tile_release_queue.clear()
	controller.disabled_tiles.clear()
	controller.local_rewards_list.clear()
	controller.held_reward_index = -1
	controller.held_artifact = null
	controller.held_from_rewards = false
	controller.inspected_reward_index = -1
	controller.inspected_backpack_artifact = null
	controller.held_inventory_origin = Vector2(-1, -1)
	controller.selected_node_index = -1
	controller.view.update_backpack_ghost(null)
	controller._render_scene(controller.current_scene)

# ?ㅽ뻾: load starter backpack items for the selected color.
static func load_backpack_items_into_inventory(controller) -> void:
	controller.inventory = InventoryModelScript.new(8, 8)
	var loadout = ArtifactScript.get_starter_loadout(controller.selected_start_color)
	var positions = ArtifactScript.get_starter_loadout_positions()
	for i in range(loadout.size()):
		controller.inventory.place_artifact(loadout[i], int(positions[i].x), int(positions[i].y))
	controller._apply_growth_modifiers()
	if controller.preview_controller != null and controller.preview_controller.run != null:
		controller.preview_controller.run.state["inventory"] = controller.inventory.to_dict()

# ?ㅽ뻾: replace starter inventory when the node-map start color changes.
static func on_loadout_color_selected(controller, color: String) -> void:
	if not controller._allow_start_color_selection():
		return
	if not color in ["red", "blue", "purple", "green"]:
		return
	controller.selected_start_color = color
	if controller.preview_controller != null:
		controller.preview_controller.start_color = controller.selected_start_color
	if str(controller.current_scene.get("phase", "")) == "node_select":
		load_backpack_items_into_inventory(controller)
		controller.view.render_backpack(controller.inventory)
		controller.current_scene = controller.preview_controller.get_scene()
		controller._render_scene(controller.current_scene)
		if controller.view.has_method("is_artifact_codex_visible") and controller.view.is_artifact_codex_visible():
			var reward_table: Dictionary = controller.view.current_codex_reward_table.duplicate(true)
			if reward_table.is_empty():
				reward_table = controller._load_reward_table_for_codex()
			controller.view.render_artifact_codex(reward_table, controller._codex_growth_state_for_view(reward_table), bool(controller.view.current_codex_debug_all))

# ?ㅽ뻾: select a valid character and refresh the page.
static func on_character_selected(controller, character_id: String) -> void:
	if character_id.is_empty():
		return
	for character in controller.character_roster:
		if str(character.get("id", "")) != character_id:
			continue
		if not bool(character.get("selectable", false)):
			return
		controller.selected_character_id = character_id
		controller._render_scene(controller.current_scene)
		return

# ?ㅽ뻾: continue from character selection to leviathan selection.
static func on_character_continue_pressed(controller) -> void:
	controller.page_override_id = "leviathan_select"
	controller._render_scene(controller.current_scene)

# ?ㅽ뻾: select a leviathan id and refresh the page.
static func on_leviathan_selected(controller, leviathan_id: String) -> void:
	if leviathan_id.is_empty():
		return
	controller.selected_leviathan_id = leviathan_id
	controller._render_scene(controller.current_scene)

# ?ㅽ뻾: start a new looting run from the selected character and leviathan.
static func on_looting_start_pressed(controller) -> void:
	controller._clear_reward_ceremony_state()
	controller._set_battle_pause_active(false)
	controller._disabled_tile_release_queue.clear()
	controller.disabled_tiles.clear()
	controller.weakness_shift_step = 0
	controller._rebuild_preview_controller(randi() & 0x7fffffff)
	controller.selected_node_index = -1
	controller.current_scene = controller.preview_controller.reset()
	controller.preview_controller.start_color = controller.selected_start_color
	if controller.preview_controller != null and controller.preview_controller.run != null:
		controller.preview_controller.run.state["selectedCharacter"] = controller.selected_character_id
	controller.page_override_id = ""
	load_backpack_items_into_inventory(controller)
	controller.view.render_backpack(controller.inventory)
	controller._recalculate_queue_colors()
	controller._render_scene(controller.current_scene)

# ?ㅽ뻾: return from leviathan selection to character select through the normal reset path.
static func on_return_to_character_select_pressed(controller) -> void:
	on_reset_pressed(controller)

# ?ㅽ뻾: load and localize the character roster with stable fallback rows.
static func load_character_roster(character_table_path: String, portrait_path: String) -> Array:
	var fallback_ids := [
		{"id": "miner", "name": "Anchor Miner", "unlocked": true},
		{"id": "engineer", "name": "Pulse Engineer", "unlocked": false},
		{"id": "mechanic", "name": "Hull Mechanic", "unlocked": false}
	]
	var file := FileAccess.open(character_table_path, FileAccess.READ)
	if file == null:
		return _fallback_character_rows(fallback_ids, portrait_path)
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return _fallback_character_rows(fallback_ids, portrait_path)
	var data = json.get_data()
	if not (data is Dictionary):
		return _fallback_character_rows(fallback_ids, portrait_path)
	var result: Array = []
	for character in data.get("characters", []):
		if not (character is Dictionary):
			continue
		var character_id := str(character.get("id", ""))
		if character_id.is_empty():
			continue
		result.append(
			build_character_row(
				character_id,
				str(character.get("name", character_id)),
				str(character.get("portrait", portrait_path)),
				bool(character.get("unlocked", false)),
				portrait_path
			)
		)
	return append_character_placeholder_slots(result if not result.is_empty() else [], portrait_path)

# ?ㅽ뻾: build fallback character rows from inline defaults.
static func _fallback_character_rows(fallback_ids: Array, portrait_path: String) -> Array:
	var rows: Array = []
	for entry in fallback_ids:
		rows.append(build_character_row(str(entry.get("id", "")), str(entry.get("name", "")), portrait_path, bool(entry.get("unlocked", false)), portrait_path))
	return append_character_placeholder_slots(rows, portrait_path)

# ?ㅽ뻾: build one localized character roster row.
static func build_character_row(character_id: String, fallback_name: String, portrait_path: String, selectable: bool, default_portrait_path: String) -> Dictionary:
	return {
		"id": character_id,
		"name": TextCatalogScript.character_text(character_id, "name", fallback_name),
		"role": TextCatalogScript.character_text(character_id, "role", ""),
		"portraitPath": portrait_path if not portrait_path.is_empty() else default_portrait_path,
		"selectable": selectable,
		"locked": not selectable,
		"rosterMeta": TextCatalogScript.character_text(character_id, "rosterMeta", ""),
		"description": TextCatalogScript.character_text(character_id, "description", ""),
		"summary": TextCatalogScript.character_text(character_id, "summary", ""),
		"tags": TextCatalogScript.character_tags(character_id),
		"accentColor": character_accent(character_id)
	}

# ?ㅽ뻾: choose the visual accent color for one character id.
static func character_accent(character_id: String) -> String:
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

# ?ㅽ뻾: pad the roster with future character placeholders.
static func append_character_placeholder_slots(base_roster: Array, portrait_path: String) -> Array:
	var roster := base_roster.duplicate(true)
	var placeholders := [
		build_character_row("future_trawler", "Future Trawler", portrait_path, false, portrait_path),
		build_character_row("bulk_diver", "Bulk Diver", portrait_path, false, portrait_path),
		build_character_row("pressure_cartographer", "Pressure Cartographer", portrait_path, false, portrait_path)
	]
	var index := 0
	while roster.size() < 6 and index < placeholders.size():
		roster.append(placeholders[index].duplicate(true))
		index += 1
	return roster

# ?ㅽ뻾: load and localize the leviathan roster with stable fallback rows.
static func load_leviathan_roster(leviathan_table_path: String) -> Array:
	var file := FileAccess.open(leviathan_table_path, FileAccess.READ)
	if file == null:
		return [
			build_leviathan_row("ossuary_tortoise", "Ossuary Tortoise", "calcified shell", 3, 1, "res://resources/Leviathan/Leviathan_turtle.png"),
			build_leviathan_row("storm_wyvern", "Storm Wyvern", "storm membrane", 4, 2, "res://resources/Leviathan/Leviathan_lizard.png"),
			build_leviathan_row("sky_mireu", "Sky Mireu", "living aurora", 5, 3, "res://resources/Leviathan/Leviathan_golem.png")
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
			build_leviathan_row(
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

# ?ㅽ뻾: build one localized leviathan roster row.
static func build_leviathan_row(leviathan_id: String, fallback_name: String, fallback_biome: String, stage_count: int, run_count: int, art_path: String) -> Dictionary:
	return {
		"id": leviathan_id,
		"name": TextCatalogScript.leviathan_text(leviathan_id, "name", fallback_name),
		"stageCount": stage_count,
		"runCount": run_count,
		"biome": TextCatalogScript.leviathan_text(leviathan_id, "biome", fallback_biome),
		"artPath": art_path
	}

# ?ㅽ뻾: find the selected leviathan row or use the first available row.
static func selected_leviathan_data(leviathan_roster: Array, selected_leviathan_id: String) -> Dictionary:
	for leviathan in leviathan_roster:
		if str(leviathan.get("id", "")) == selected_leviathan_id:
			return leviathan.duplicate(true)
	return leviathan_roster[0].duplicate(true) if not leviathan_roster.is_empty() else {}

# ?ㅽ뻾: find the selected character row or fallback to the first selectable row.
static func selected_character_data(character_roster: Array, selected_character_id: String, portrait_path: String) -> Dictionary:
	for character in character_roster:
		if str(character.get("id", "")) == selected_character_id:
			return character.duplicate(true)
	for character in character_roster:
		if bool(character.get("selectable", false)):
			return character.duplicate(true)
	return {
		"id": selected_character_id,
		"name": TextCatalogScript.character_text(selected_character_id, "name", "Anchor Miner"),
		"role": TextCatalogScript.character_text(selected_character_id, "role", ""),
		"portraitPath": portrait_path,
		"selectable": true,
		"locked": false,
		"rosterMeta": TextCatalogScript.character_text(selected_character_id, "rosterMeta", ""),
		"description": TextCatalogScript.character_text(selected_character_id, "description", ""),
		"summary": TextCatalogScript.character_text(selected_character_id, "summary", ""),
		"tags": TextCatalogScript.character_tags(selected_character_id),
		"accentColor": "red"
	}

# ?ㅽ뻾: build preview-controller options from current start-flow selections.
static func preview_options(seed_value: int, leviathan: Dictionary, selected_leviathan_id: String, selected_start_color: String, selected_character_id: String, campaign_progress: Dictionary) -> Dictionary:
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

# ?ㅽ뻾: project the currently selected or active node into page context data.
static func selected_node_context(scene: Dictionary = {}, selected_index: int = -1, selected_run_node: Dictionary = {}) -> Dictionary:
	var phase := str(scene.get("phase", ""))
	if phase == "node_select":
		var candidates: Array = scene.get("nodeSelect", {}).get("candidates", [])
		var index := int(scene.get("selectedNodeIndex", selected_index))
		if not candidates.is_empty() and index >= 0 and index < candidates.size():
			return node_context_from_dict(candidates[index])
		return empty_node_context()
	var combat_payload: Variant = scene.get("combat", {})
	var combat_node: Dictionary = {}
	if combat_payload is Dictionary:
		combat_node = combat_payload.get("node", {})
	if combat_node is Dictionary and not combat_node.is_empty():
		return node_context_from_dict(combat_node, str(scene.get("lastNodeLabel", "")))
	if selected_run_node is Dictionary and not selected_run_node.is_empty():
		return node_context_from_dict(selected_run_node, str(scene.get("lastNodeLabel", "")))
	return empty_node_context()

# ?ㅽ뻾: build the empty selected-node context shape expected by page renderers.
static func empty_node_context() -> Dictionary:
	return {
		"node_id": "",
		"node_type": "",
		"label": "",
		"risk_tier": "",
		"weakness": [],
		"shieldMul": 1.0,
		"healthMul": 1.0,
		"rewardBias": "baseline",
		"recommendedBuildHint": "",
		"is_boss": false,
		"is_event": false
	}

# ?ㅽ뻾: decide whether the selected node can start combat for the current scene.
static func selected_node_start_enabled(scene: Dictionary = {}, selected_index: int = -1) -> bool:
	if str(scene.get("phase", "")) != "node_select":
		return false
	var node_select: Dictionary = scene.get("nodeSelect", {}) if scene.get("nodeSelect", {}) is Dictionary else {}
	var candidates: Array = node_select.get("candidates", [])
	var index := int(scene.get("selectedNodeIndex", selected_index))
	if index < 0 or index >= candidates.size():
		return false
	var candidate: Dictionary = candidates[index]
	if not node_candidate_matches_current_stage(candidate, scene):
		return false
	return not node_candidate_already_cleared(candidate, index, scene)

# ?ㅽ뻾: check whether a candidate belongs to the current stage distance.
static func node_candidate_matches_current_stage(candidate: Dictionary, scene: Dictionary) -> bool:
	var stage_index := int(scene.get("stageIndex", 0))
	var max_stages := maxi(1, int(scene.get("maxStages", 1)))
	var expected_distance := maxi(0, max_stages - stage_index - 1)
	if candidate.has("finalStageDistance"):
		return int(candidate.get("finalStageDistance", expected_distance)) == expected_distance
	return true

# ?ㅽ뻾: detect whether the current-stage route already cleared this candidate.
static func node_candidate_already_cleared(candidate: Dictionary, candidate_index: int, scene: Dictionary) -> bool:
	if bool(candidate.get("cleared", false)) or str(candidate.get("status", "")) == "cleared":
		return true
	var node_select: Dictionary = scene.get("nodeSelect", {}) if scene.get("nodeSelect", {}) is Dictionary else {}
	var route_history: Array = node_select.get("routeHistory", scene.get("routeHistory", []))
	var stage_index := int(scene.get("stageIndex", 0))
	var candidate_id := str(candidate.get("id", ""))
	var candidate_hash := str(candidate.get("routeHash", ""))
	for entry in route_history:
		if not (entry is Dictionary):
			continue
		var history_entry: Dictionary = entry
		if int(history_entry.get("stageIndex", -1)) != stage_index:
			continue
		if not candidate_hash.is_empty() and str(history_entry.get("routeHash", "")) == candidate_hash:
			return true
		if not candidate_id.is_empty() and str(history_entry.get("id", "")) == candidate_id and int(history_entry.get("routeSlotIndex", -1)) == candidate_index:
			return true
	return false

# ?ㅽ뻾: normalize raw node dictionaries into selected-node page context.
static func node_context_from_dict(node: Dictionary, fallback_label: String = "") -> Dictionary:
	return {
		"node_id": str(node.get("id", "")),
		"node_type": str(node.get("nodeType", "")),
		"label": str(node.get("label", fallback_label)),
		"risk_tier": str(node.get("riskTier", "")),
		"weakness": node.get("weakness", []).duplicate(true) if node.get("weakness", []) is Array else [],
		"shieldMul": float(node.get("shieldMul", 1.0)),
		"healthMul": float(node.get("healthMul", 1.0)),
		"shieldMulByColor": node.get("shieldMulByColor", node.get("shield_mul_by_color", {})).duplicate(true) if node.get("shieldMulByColor", node.get("shield_mul_by_color", {})) is Dictionary else {},
		"healthMulByColor": node.get("healthMulByColor", node.get("health_mul_by_color", {})).duplicate(true) if node.get("healthMulByColor", node.get("health_mul_by_color", {})) is Dictionary else {},
		"rewardBias": str(node.get("rewardBias", "baseline")),
		"recommendedBuildHint": str(node.get("recommendedBuildHint", "")),
		"is_boss": bool(node.get("isBoss", false)) or str(node.get("nodeType", "")) == "boss" or str(node.get("riskTier", "")) == "boss",
		"is_event": bool(node.get("isEvent", false)) or str(node.get("riskTier", "")) == "event"
	}
