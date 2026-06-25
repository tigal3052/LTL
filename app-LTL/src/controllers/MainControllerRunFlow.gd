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
const MainControllerRewardBackpackFlowScript = preload("res://src/controllers/MainControllerRewardBackpackFlow.gd")
const VerticalSliceRunnerScript = preload("res://src/process/VerticalSliceRunner.gd")
const CharacterRosterLoaderScript = preload("res://src/controllers/run_flow/CharacterRosterLoader.gd")
const LeviathanRosterLoaderScript = preload("res://src/controllers/run_flow/LeviathanRosterLoader.gd")
const NodeSelectionGuardsScript = preload("res://src/controllers/run_flow/NodeSelectionGuards.gd")
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
	controller.pending_discard_request = {}
	controller.view.set_confirm_overlay_visible(false)
	controller.view.update_backpack_ghost(null)
	controller.active_story_scene = {}
	controller.active_story_step_index = 0
	controller.story_return_page_id = ""
	controller.growth_state.gold = controller.growth_state.get_starting_gold()
	controller.growth_state.xp = 0
	controller.preview_controller.run.state["growth"] = controller.growth_state.to_dict()
	load_backpack_items_into_inventory(controller)
	controller.view.render_backpack(controller.inventory)
	controller._recalculate_queue_colors()
	controller._render_scene(controller.current_scene)
# ?ㅽ뻾: ask for confirmation before discarding unclaimed rewards.
static func on_claim_rewards_pressed(controller) -> void:
	if controller.has_method("_narrative_input_block_active") and controller._narrative_input_block_active():
		return
	if not controller.local_rewards_list.is_empty():
		if controller.view.has_method("show_unclaimed_reward_confirmation"):
			controller.view.show_unclaimed_reward_confirmation()
		else:
			controller.view.set_confirm_overlay_visible(true)
	else:
		proceed_to_node_select(controller)
# ?ㅽ뻾: proceed even when unclaimed rewards remain.
static func on_confirm_proceed_pressed(controller) -> void:
	if MainControllerRewardBackpackFlowScript.confirm_pending_discard(controller):
		return
	controller.view.set_confirm_overlay_visible(false)
	proceed_to_node_select(controller)
# ?ㅽ뻾: cancel reward proceed confirmation.
static func on_confirm_cancel_pressed(controller) -> void:
	if MainControllerRewardBackpackFlowScript.cancel_pending_discard(controller):
		return
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
	controller.pending_discard_request = {}
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
	if controller.has_method("_open_story_scene_for_page") and bool(controller._open_story_scene_for_page("leviathan_select")):
		controller._render_scene(controller.current_scene)
		return
	controller._render_scene(controller.current_scene)
# ?ㅽ뻾: select a leviathan id and refresh the page.
static func on_leviathan_selected(controller, leviathan_id: String) -> void:
	if leviathan_id.is_empty():
		return
	controller.selected_leviathan_id = leviathan_id
	controller._render_scene(controller.current_scene)
# ?ㅽ뻾: start a new looting run from the selected character and leviathan.
static func on_looting_start_pressed(controller) -> void:
	start_looting_run(controller, randi() & 0x7fffffff)
static func on_retry_same_seed_pressed(controller) -> void:
	start_looting_run(controller, retry_seed_for_mode(int(controller.preview_controller.seed) if controller.preview_controller != null else 1, "same_seed"))
static func on_retry_new_seed_pressed(controller) -> void:
	start_looting_run(controller, retry_seed_for_mode(int(controller.preview_controller.seed) if controller.preview_controller != null else 1, "new_seed"))
static func retry_seed_for_mode(seed_value: int, mode: String) -> int:
	return VerticalSliceRunnerScript.retry_seed_for_mode(seed_value, mode)
static func start_looting_run(controller, seed_value: int) -> void:
	controller._clear_reward_ceremony_state()
	controller._set_battle_pause_active(false)
	controller._disabled_tile_release_queue.clear()
	controller.disabled_tiles.clear()
	controller.weakness_shift_step = 0
	controller._rebuild_preview_controller(seed_value)
	controller.selected_node_index = -1
	controller.current_scene = controller.preview_controller.reset()
	controller.preview_controller.start_color = controller.selected_start_color
	if controller.preview_controller != null and controller.preview_controller.run != null:
		controller.preview_controller.run.state["selectedCharacter"] = controller.selected_character_id
		if controller.growth_state != null: controller.preview_controller.run.state["growth"] = controller.growth_state.to_dict()
	controller.page_override_id = ""
	controller.active_story_scene = {}
	controller.active_story_step_index = 0
	controller.story_return_page_id = ""
	load_backpack_items_into_inventory(controller)
	controller.view.render_backpack(controller.inventory)
	controller._recalculate_queue_colors()
	controller._render_scene(controller.current_scene)
# ?ㅽ뻾: return from leviathan selection to character select through the normal reset path.
static func on_return_to_character_select_pressed(controller) -> void:
	on_reset_pressed(controller)
# 실행: load and localize the character roster with stable fallback rows.
static func load_character_roster(character_table_path: String, portrait_path: String) -> Array:
	return CharacterRosterLoaderScript.load_character_roster(character_table_path, portrait_path)
static func _fallback_character_rows(fallback_ids: Array, portrait_path: String) -> Array:
	return CharacterRosterLoaderScript._fallback_character_rows(fallback_ids, portrait_path)
static func build_character_row(character_id: String, fallback_name: String, portrait_path: String, selectable: bool, default_portrait_path: String) -> Dictionary:
	return CharacterRosterLoaderScript.build_character_row(character_id, fallback_name, portrait_path, selectable, default_portrait_path)
static func character_accent(character_id: String) -> String:
	return CharacterRosterLoaderScript.character_accent(character_id)
static func append_character_placeholder_slots(base_roster: Array, portrait_path: String) -> Array:
	return CharacterRosterLoaderScript.append_character_placeholder_slots(base_roster, portrait_path)
static func load_leviathan_roster(leviathan_table_path: String) -> Array:
	return LeviathanRosterLoaderScript.load_leviathan_roster(leviathan_table_path)
static func build_leviathan_row(leviathan_id: String, fallback_name: String, fallback_biome: String, stage_count: int, run_count: int, art_path: String) -> Dictionary:
	return LeviathanRosterLoaderScript.build_leviathan_row(leviathan_id, fallback_name, fallback_biome, stage_count, run_count, art_path)
static func selected_leviathan_data(leviathan_roster: Array, selected_leviathan_id: String) -> Dictionary:
	return LeviathanRosterLoaderScript.selected_leviathan_data(leviathan_roster, selected_leviathan_id)
static func selected_character_data(character_roster: Array, selected_character_id: String, portrait_path: String) -> Dictionary:
	return CharacterRosterLoaderScript.selected_character_data(character_roster, selected_character_id, portrait_path)
static func preview_options(seed_value: int, leviathan: Dictionary, selected_leviathan_id: String, selected_start_color: String, selected_character_id: String, campaign_progress: Dictionary, growth_state: Dictionary = {}) -> Dictionary:
	var options := {
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
	if not growth_state.is_empty():
		options["growth"] = growth_state.duplicate(true)
	return options
# 실행: project the currently selected or active node into page context data.
static func selected_node_context(scene: Dictionary = {}, selected_index: int = -1, selected_run_node: Dictionary = {}) -> Dictionary:
	return NodeSelectionGuardsScript.selected_node_context(scene, selected_index, selected_run_node)
static func empty_node_context() -> Dictionary:
	return NodeSelectionGuardsScript.empty_node_context()
static func selected_node_start_enabled(scene: Dictionary = {}, selected_index: int = -1) -> bool:
	return NodeSelectionGuardsScript.selected_node_start_enabled(scene, selected_index)
static func node_candidate_matches_current_stage(candidate: Dictionary, scene: Dictionary) -> bool:
	return NodeSelectionGuardsScript.node_candidate_matches_current_stage(candidate, scene)
static func node_candidate_already_cleared(candidate: Dictionary, candidate_index: int, scene: Dictionary) -> bool:
	return NodeSelectionGuardsScript.node_candidate_already_cleared(candidate, candidate_index, scene)
static func node_context_from_dict(node: Dictionary, fallback_label: String = "") -> Dictionary:
	return NodeSelectionGuardsScript.node_context_from_dict(node, fallback_label)
