extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	test_main_controller_is_not_an_empty_runtime_facade()
	test_main_controller_helper_scripts_load()
	test_main_controller_followup_helper_scripts_load()
	test_main_controller_removed_obsolete_helper_wrappers()
	test_main_controller_reward_backpack_flow_split_contract()
	test_main_controller_combat_flow_split_contract()
	test_main_controller_run_flow_split_contract()
	test_main_controller_render_flow_split_contract()
	test_main_controller_support_flow_split_contract()
	test_main_controller_bootstrap_flow_split_contract()
	test_main_controller_uses_terrain_shift_interval()
	test_main_controller_syncs_combat_ticks_to_shift_interval()
	test_cell_click_does_not_restart_or_accelerate_terrain_shift_timer()
	test_main_controller_prefers_clicked_cell_color_for_targeting()
	test_main_controller_scene_projection_reads_queue_and_target()
	test_main_controller_starter_loadout_positions_are_adjacent()
	return _result()

func test_main_controller_is_not_an_empty_runtime_facade() -> void:
	var text := FileAccess.get_file_as_string("res://src/MainController.gd")
	_assert(not text.contains("extends \"res://src/MainControllerRuntime.gd\""), "main controller owns the scene controller body instead of extending a runtime implementation facade")
	_assert(text.contains("extends Node"), "main controller remains a Node script for the Main.tscn controller node")

func test_main_controller_helper_scripts_load() -> void:
	_assert(MainControllerRunFlowScript != null, "run flow helper script loads")
	_assert(MainControllerCombatFlowScript != null, "combat flow helper script loads")
	_assert(MainControllerSupportFlowScript != null, "support flow helper script loads")
	_assert(MainControllerBootstrapFlowScript != null, "bootstrap flow helper script loads")

func test_main_controller_followup_helper_scripts_load() -> void:
	_assert(MainControllerDisplayTextScript != null, "display-text helper script loads")
	_assert(MainControllerRenderFlowScript != null, "render flow helper script loads")

func test_main_controller_removed_obsolete_helper_wrappers() -> void:
	var text := FileAccess.get_file_as_string("res://src/MainController.gd")
	var obsolete_wrappers := [
		"func _build_character_row",
		"func _character_accent",
		"func _append_character_placeholder_slots",
		"func _build_leviathan_row",
		"func _active_combat_terrain_colors",
		"func _artifact_display_name",
		"func _node_select_summary",
		"func _current_target",
		"static func resolve_target_color_for_interaction",
		"static func should_continue_hold_fire",
		"static func can_accept_combat_click",
		"static func build_damage_popup_events",
		"static func hold_fire_burst_count"
	]
	for wrapper_name in obsolete_wrappers:
		_assert(not text.contains(wrapper_name), "main controller deletes obsolete wrapper: %s" % wrapper_name)

func test_main_controller_reward_backpack_flow_split_contract() -> void:
	var RewardBackpackFlowScript = load("res://src/controllers/MainControllerRewardBackpackFlow.gd")
	_assert(RewardBackpackFlowScript != null, "reward/backpack flow helper script loads")
	var text := FileAccess.get_file_as_string("res://src/MainController.gd")
	_assert(text.contains("MainControllerRewardBackpackFlowScript"), "main controller preloads the reward/backpack flow helper")
	_assert(text.contains("MainControllerRewardBackpackFlowScript.place_held_artifact_at(self, coord)"), "held artifact placement delegates to reward/backpack flow")
	_assert(text.contains("MainControllerRewardBackpackFlowScript.on_reward_meta_clicked(self, meta)"), "reward tray selection delegates to reward/backpack flow")
	_assert(text.contains("MainControllerRewardBackpackFlowScript.on_backpack_slot_clicked(self, coord)"), "backpack slot selection delegates to reward/backpack flow")
	var line_count := text.split("\n").size()
	_assert(line_count <= 1125, "main controller reward/backpack split lowers controller body to the first split budget")

func test_main_controller_combat_flow_split_contract() -> void:
	var CombatFlowScript = load("res://src/controllers/MainControllerCombatFlow.gd")
	_assert(CombatFlowScript != null, "combat flow helper script loads")
	var text := FileAccess.get_file_as_string("res://src/MainController.gd")
	_assert(text.contains("MainControllerCombatFlowScript"), "main controller preloads the combat flow helper")
	_assert(text.contains("MainControllerCombatFlowScript.on_cell_clicked(self, cell_id, color_name)"), "cell click delegates to combat flow")
	_assert(text.contains("MainControllerCombatFlowScript.trigger_hold_fire(self)"), "hold-fire loop delegates to combat flow")
	_assert(text.contains("MainControllerCombatFlowScript.on_shift_timer_timeout(self)"), "terrain shift timer delegates to combat flow")
	_assert(text.contains("MainControllerCombatFlowScript.recalculate_queue_colors(self)"), "queue color recalculation delegates to combat flow")
	var line_count := text.split("\n").size()
	_assert(line_count <= 960, "main controller combat split lowers controller body to the second split budget")

func test_main_controller_run_flow_split_contract() -> void:
	var RunFlowScript = load("res://src/controllers/MainControllerRunFlow.gd")
	_assert(RunFlowScript != null, "run flow helper script loads")
	var text := FileAccess.get_file_as_string("res://src/MainController.gd")
	_assert(text.contains("MainControllerRunFlowScript"), "main controller preloads the run flow helper")
	_assert(text.contains("MainControllerRunFlowScript.on_start_pressed(self)"), "start press delegates to run flow")
	_assert(text.contains("MainControllerRunFlowScript.on_reset_pressed(self)"), "reset press delegates to run flow")
	_assert(text.contains("MainControllerRunFlowScript.proceed_to_node_select(self)"), "reward proceed delegates to run flow")
	_assert(text.contains("MainControllerRunFlowScript.on_loadout_color_selected(self, color)"), "loadout color selection delegates to run flow")
	_assert(text.contains("MainControllerRunFlowScript.on_looting_start_pressed(self)"), "looting start delegates to run flow")
	var line_count := text.split("\n").size()
	_assert(line_count <= 820, "main controller run-flow split lowers controller body to the third split budget")

func test_main_controller_render_flow_split_contract() -> void:
	var RenderFlowScript = load("res://src/controllers/MainControllerRenderFlow.gd")
	_assert(RenderFlowScript != null, "render flow helper script loads")
	var text := FileAccess.get_file_as_string("res://src/MainController.gd")
	_assert(text.contains("MainControllerRenderFlowScript"), "main controller preloads the render flow helper")
	_assert(text.contains("MainControllerRenderFlowScript.render_scene(self, scene)"), "scene rendering delegates to render flow")
	_assert(text.contains("MainControllerRenderFlowScript.render_rewards(self, scene)"), "reward rendering delegates to render flow")
	_assert(text.contains("MainControllerRenderFlowScript.decorate_scene(self, scene)"), "scene decoration delegates to render flow")
	_assert(text.contains("MainControllerRenderFlowScript.resolve_page_id(self, scene)"), "page id resolution delegates to render flow")
	var line_count := text.split("\n").size()
	_assert(line_count <= 720, "main controller render-flow split lowers controller body to the fourth split budget")

func test_main_controller_support_flow_split_contract() -> void:
	var SupportFlowScript = load("res://src/controllers/MainControllerSupportFlow.gd")
	_assert(SupportFlowScript != null, "support flow helper script loads")
	var text := FileAccess.get_file_as_string("res://src/MainController.gd")
	_assert(text.contains("MainControllerSupportFlowScript"), "main controller preloads the support flow helper")
	_assert(text.contains("MainControllerSupportFlowScript.on_shop_open_pressed(self, SHOP_ENABLED)"), "shop open delegates to support flow")
	_assert(text.contains("MainControllerSupportFlowScript.on_codex_open_pressed(self)"), "codex open delegates to support flow")
	_assert(text.contains("MainControllerSupportFlowScript.on_buy_passive(self, passive_id, cost, SHOP_ENABLED)"), "passive purchase delegates to support flow")
	_assert(text.contains("MainControllerSupportFlowScript.apply_growth_modifiers(self)"), "growth modifier application delegates to support flow")
	_assert(text.contains("MainControllerSupportFlowScript.save_accessibility_state_to_path(path, ACCESSIBILITY_SETTINGS_SECTION, accessibility_state)"), "accessibility save delegates to support flow")
	var line_count := text.split("\n").size()
	_assert(line_count <= 620, "main controller support-flow split lowers controller body to the fifth split budget")

func test_main_controller_bootstrap_flow_split_contract() -> void:
	var BootstrapFlowScript = load("res://src/controllers/MainControllerBootstrapFlow.gd")
	_assert(BootstrapFlowScript != null, "bootstrap flow helper script loads")
	var text := FileAccess.get_file_as_string("res://src/MainController.gd")
	_assert(text.contains("MainControllerBootstrapFlowScript"), "main controller preloads the bootstrap flow helper")
	_assert(text.contains("await MainControllerBootstrapFlowScript.ready(self)"), "ready lifecycle delegates to bootstrap flow")
	var line_count := text.split("\n").size()
	_assert(line_count <= 520, "main controller bootstrap split lowers controller body near the final target")

func test_main_controller_uses_terrain_shift_interval() -> void:
	var MainControllerScript = load("res://src/MainController.gd")
	_assert(MainControllerScript != null, "main controller loads")
	if MainControllerScript == null:
		return
	_assert_eq(float(MainControllerScript.TERRAIN_SHIFT_SECONDS), 2.0, "terrain marker shift interval is 2 seconds")

func test_main_controller_syncs_combat_ticks_to_shift_interval() -> void:
	var MainControllerScript = load("res://src/MainController.gd")
	_assert(MainControllerScript != null, "main controller loads for shift tick sync")
	if MainControllerScript == null:
		return
	_assert_eq(int(MainControllerScript.TERRAIN_SHIFT_TICKS), 40, "2 second shift advances 40 combat ticks")

func test_cell_click_does_not_restart_or_accelerate_terrain_shift_timer() -> void:
	var text := FileAccess.get_file_as_string("res://src/controllers/MainControllerCombatFlow.gd")
	var click_body := _function_body(text, "static func on_cell_clicked")
	_assert(not click_body.is_empty(), "combat flow exposes on_cell_clicked body for timer coupling review")
	_assert(not click_body.contains("shift_timer"), "cell clicks do not touch the terrain shift timer")
	_assert(not click_body.contains("TERRAIN_SHIFT_SECONDS"), "cell clicks do not restart the terrain shift interval")
	_assert(not click_body.contains("on_shift_timer_timeout"), "cell clicks do not force an immediate terrain shift")

func test_main_controller_prefers_clicked_cell_color_for_targeting() -> void:
	_assert_eq(MainControllerCombatFlowScript.resolve_target_color_for_interaction("blue", "red"), "blue", "click targeting uses the clicked tile color instead of the active queue color")
	_assert_eq(MainControllerCombatFlowScript.resolve_target_color_for_interaction("green", "purple"), "green", "hover and hold targeting preserve the actual cell color")
	_assert_eq(MainControllerCombatFlowScript.resolve_target_color_for_interaction("normal", "red"), "red", "normal fallback still uses the active queue color when a cell exposes no color")
	_assert_eq(MainControllerCombatFlowScript.resolve_target_color_for_interaction("", "purple"), "purple", "empty cell-color input falls back to the active queue color")

func test_main_controller_scene_projection_reads_queue_and_target() -> void:
	_assert(MainControllerCombatFlowScript != null, "combat flow helper loads for queue and target checks")
	if MainControllerCombatFlowScript == null:
		return
	var scene := {
		"hud": {
			"queue": {"items": [{"color": "green"}]},
			"aim": {"cellId": "r1c2", "targetColor": "blue"}
		},
		"terrain": {
			"cells": [
				{"id": "r0c0", "weakness": "red"}
			]
		}
	}
	_assert_eq(MainControllerCombatFlowScript.active_queue_color(scene), "green", "combat flow reads the active queue color")
	_assert_eq(MainControllerCombatFlowScript.current_target(scene).get("cellId", ""), "r1c2", "combat flow prefers explicit aim cell")
	_assert_eq(MainControllerCombatFlowScript.current_target(scene).get("color", ""), "blue", "combat flow prefers explicit aim target color")
	var fallback_scene := {
		"hud": {"queue": {"items": []}},
		"terrain": {"cells": [{"id": "r0c4", "weakness": "purple"}]}
	}
	_assert_eq(MainControllerCombatFlowScript.active_queue_color(fallback_scene), "red", "combat flow keeps red as empty-queue fallback")
	_assert_eq(MainControllerCombatFlowScript.current_target(fallback_scene).get("cellId", ""), "r0c4", "combat flow falls back to weakness cell")

func test_main_controller_starter_loadout_positions_are_adjacent() -> void:
	var MainControllerScript = load("res://src/MainController.gd")
	_assert(MainControllerScript != null, "main controller loads for starter positions")
	if MainControllerScript == null:
		return
	var positions: Array = MainControllerScript.STARTER_LOADOUT_POSITIONS
	_assert_eq(positions.size(), 2, "starter loadout exposes two positions")
	var delta: Vector2 = positions[0] - positions[1]
	_assert_eq(int(abs(delta.x) + abs(delta.y)), 1, "starter drill and beacon begin orthogonally adjacent")

func _function_body(text: String, signature: String) -> String:
	var start := text.find(signature)
	if start < 0:
		return ""
	var next := text.find("\nstatic func ", start + signature.length())
	if next < 0:
		next = text.length()
	return text.substr(start, next - start)
