extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene resource loads for start-flow contract")
	if MainScene == null:
		_finish()
		return

	for color_index in range(4):
		await _assert_main_start_flow(MainScene, color_index, -1)
		await _assert_main_start_flow(MainScene, color_index, 0)
		await _assert_main_start_flow(MainScene, color_index, 1)
	await _assert_reward_tooltip_cleanup(MainScene)
	await _assert_stage_two_node_select_reentry(MainScene)
	_finish()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _finish() -> void:
	if failures.is_empty():
		print("MAIN_START_FLOW_CONTRACT_OK")
		call_deferred("quit", 0)
		return
	for failure in failures:
		push_error(failure)
	call_deferred("quit", 1)

func _assert_main_start_flow(MainScene: PackedScene, color_index: int, node_index: int) -> void:
	root.size = VIEWPORT_SIZE
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for color %d node %d" % [color_index, node_index])
	if main_instance == null:
		return

	root.add_child(main_instance)
	await process_frame
	await process_frame
	await process_frame

	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists for color %d node %d" % [color_index, node_index])
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return

	var node_map_scene = main_instance.get("node_map_scene")
	_assert(node_map_scene != null, "node map scene exists for color %d node %d" % [color_index, node_index])
	if node_map_scene == null:
		main_instance.queue_free()
		await process_frame
		return

	var current_scene: Dictionary = controller.get("current_scene")
	_assert_eq(str(current_scene.get("phase", "")), "node_select", "main scene starts in node_select phase for color %d node %d" % [color_index, node_index])
	_assert_node_select_start_layout(main_instance, "color %d node %d" % [color_index, node_index])

	node_map_scene.press_color_button(color_index)
	if node_index >= 0 and node_index < node_map_scene.map_node_count():
		node_map_scene.press_node_button(node_index)
	await process_frame
	await process_frame

	var start_button = main_instance.get("start_button")
	_assert(start_button != null, "start button exists for color %d node %d" % [color_index, node_index])
	if start_button != null:
		start_button.pressed.emit()
	await process_frame
	await process_frame

	_assert(main_instance.is_inside_tree(), "main scene remains in the tree for color %d node %d" % [color_index, node_index])
	current_scene = controller.get("current_scene")
	_assert_eq(str(current_scene.get("phase", "")), "combat", "start enters combat for color %d node %d" % [color_index, node_index])
	_assert_eq(bool(current_scene.get("runComplete", false)), false, "start does not complete the run for color %d node %d" % [color_index, node_index])
	_assert_eq(bool(current_scene.get("failed", false)), false, "start does not fail the run for color %d node %d" % [color_index, node_index])
	var queue: Dictionary = current_scene.get("hud", {}).get("queue", {})
	_assert_eq(int(queue.get("capacity", 0)), 16, "combat HUD keeps the doubled queue capacity for color %d node %d" % [color_index, node_index])
	_assert_eq(int(queue.get("loaded", -1)), 8, "combat HUD starts with only half the doubled queue loaded for color %d node %d" % [color_index, node_index])
	_assert_eq(int(queue.get("items", []).size()), 8, "combat HUD item list matches the half-loaded doubled queue for color %d node %d" % [color_index, node_index])

	main_instance.queue_free()
	await process_frame

func _assert_node_select_start_layout(main_instance: Node, label: String) -> void:
	var row = main_instance.get("node_select_content_row") as HBoxContainer
	var panel = main_instance.get("node_select_panel") as Control
	var backpack = main_instance.get("backpack_container") as Control
	var node_map_scene = main_instance.get("node_map_scene")
	_assert(row != null, "node-select content row exists for %s" % label)
	_assert(panel != null, "node-select panel exists for %s" % label)
	_assert(backpack != null, "node-select backpack container exists for %s" % label)
	_assert(node_map_scene != null, "node-select node-map scene exists for %s" % label)
	if row == null or panel == null or backpack == null or node_map_scene == null:
		return
	_assert(backpack.get_parent() == row, "node-select backpack is docked into the map row on startup for %s" % label)
	var row_gap := float(row.get_theme_constant("separation"))
	_assert(row.size.x > 0.0, "node-select row has resolved width on startup for %s" % label)
	_assert(backpack.size.x > 0.0, "node-select backpack resolves a visible width on startup for %s" % label)
	_assert(node_map_scene.size.x > 0.0, "node-select node-map scene resolves a visible width on startup for %s" % label)
	_assert(node_map_scene.size.x >= 460.0, "node-select node-map scene keeps the explicit map minimum width on startup for %s" % label)
	_assert(node_map_scene.size.x + backpack.size.x + row_gap <= row.size.x + 1.5, "node-select startup row keeps map and backpack inside the available width for %s" % label)
	var graph_center_delta := absf(float(node_map_scene.node_visual_center_x()) - float(node_map_scene.map_canvas_center_x()))
	_assert(graph_center_delta <= 24.0, "node-select startup graph stays centered inside the live panel for %s (delta=%.3f)" % [label, graph_center_delta])
	var node_right_in_row := float(node_map_scene.position.x) + float(node_map_scene.node_rightmost_edge())
	var map_visible_right := float(backpack.position.x) - row_gap
	_assert(node_right_in_row <= map_visible_right + 1.0, "node-select startup graph stays left of the backpack dock for %s (graph=%.3f visible=%.3f)" % [label, node_right_in_row, map_visible_right])
	_assert(float(node_map_scene.node_leftmost_edge()) >= -0.5, "node-select startup graph stays inside the live left edge for %s" % label)

func _assert_reward_tooltip_cleanup(MainScene: PackedScene) -> void:
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for reward tooltip cleanup contract")
	if main_instance == null:
		return

	root.add_child(main_instance)
	await process_frame
	await process_frame

	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists for reward tooltip cleanup contract")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return

	var reward := {
		"kind": "Tooltip Cleanup Beacon",
		"rarity": "rare",
		"payload": {"item_type": "beacon", "energy_type": "green", "beacon_cooldown_mod": -3, "beacon_damage_mod": 0.3},
		"presentation": {"description": "Tooltip cleanup contract reward"}
	}
	controller.call("_render_scene", {
		"phase": "reward_loot",
		"rewardPresentationStep": "tray_review",
		"reward": {"pendingRewards": [reward]},
		"terrain": {"rows": 0, "columns": 0, "cells": []},
		"hud": {},
		"targetPanel": {},
		"stageIndex": 1,
		"maxStages": 5
	})
	main_instance.call("show_reward_tooltip", reward, [])
	var tooltip_panel = main_instance.get("tooltip_panel")
	_assert(tooltip_panel != null, "main scene builds the floating tooltip panel for reward tooltip cleanup contract")
	if tooltip_panel != null:
		_assert_eq(bool(tooltip_panel.visible), true, "reward tooltip becomes visible before reward-to-combat cleanup")

	controller.call("_render_scene", {
		"phase": "combat",
		"terrain": {"rows": 0, "columns": 0, "cells": []},
		"hud": {
			"aim": {"canFire": true},
			"repair": {"active": false, "available": false},
			"queue": {"items": []},
			"pin": {"active": false},
			"hazard": {"severity": "stable"}
		},
		"targetPanel": {"timeLimitTicks": 1200.0, "elapsedTicks": 0.0},
		"stageIndex": 1,
		"maxStages": 5
	})
	await process_frame
	tooltip_panel = main_instance.get("tooltip_panel")
	if tooltip_panel != null:
		_assert_eq(bool(tooltip_panel.visible), false, "reward tooltip clears when the scene leaves reward_loot")

	main_instance.queue_free()
	await process_frame

func _assert_stage_two_node_select_reentry(MainScene: PackedScene) -> void:
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for stage-two node-select reentry contract")
	if main_instance == null:
		return
	root.add_child(main_instance)
	await process_frame
	await process_frame
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists for stage-two node-select reentry contract")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return
	controller.call("_render_scene", {
		"phase": "combat",
		"terrain": {"rows": 0, "columns": 0, "cells": []},
		"hud": {
			"aim": {"canFire": true},
			"repair": {"active": false, "available": false},
			"queue": {"items": [], "capacity": 16, "loaded": 8},
			"pin": {"active": false},
			"hazard": {"severity": "stable"}
		},
		"targetPanel": {"timeLimitTicks": 1200.0, "elapsedTicks": 0.0},
		"stageIndex": 0,
		"maxStages": 5
	})
	await process_frame
	await process_frame
	var current_scene: Dictionary = controller.get("current_scene").duplicate(true)
	current_scene["phase"] = "node_select"
	current_scene["stageIndex"] = 1
	current_scene["maxStages"] = maxi(2, int(current_scene.get("maxStages", 5)))
	current_scene["allowStartColorSelection"] = false
	current_scene["selectedNodeIndex"] = 0
	controller.call("_render_scene", current_scene)
	await process_frame
	await process_frame
	await process_frame
	_assert_node_select_start_layout(main_instance, "stage-two reentry")
	var node_map_scene = main_instance.get("node_map_scene")
	_assert(node_map_scene != null, "node map scene exists for stage-two reentry")
	if node_map_scene != null:
		_assert_eq(node_map_scene.loadout_color_count(), 0, "stage-two reentry keeps the starter color picker hidden")
	main_instance.queue_free()
	await process_frame
