extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("INITIAL_ROOT_SIZE=", root.size)
	root.size = VIEWPORT_SIZE
	print("FORCED_ROOT_SIZE=", root.size)
	var MainScene = load("res://src/Main.tscn")
	if MainScene == null:
		push_error("main scene failed to load")
		quit(1)
		return
	await _probe_stage_two_node_select(MainScene)
	await _probe_reward_tray(MainScene)
	await _probe_stage_two_combat(MainScene)
	quit(0)

func _instantiate_main(MainScene: PackedScene) -> Node:
	var main_instance = MainScene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	await process_frame
	return main_instance

func _probe_stage_two_node_select(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	var controller = main_instance.get_node_or_null("MainController")
	if controller == null:
		push_error("controller missing for stage-two node-select probe")
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
	var scene: Dictionary = controller.get("current_scene").duplicate(true)
	scene["phase"] = "node_select"
	scene["stageIndex"] = 1
	scene["maxStages"] = 5
	scene["allowStartColorSelection"] = false
	scene["selectedStartColor"] = "red"
	scene["selectedNodeIndex"] = 0
	controller.call("_render_scene", scene)
	await process_frame
	await process_frame
	await process_frame
	_dump_layout(main_instance, "STAGE_TWO_NODE_SELECT")
	main_instance.queue_free()
	await process_frame

func _probe_reward_tray(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	var controller = main_instance.get_node_or_null("MainController")
	if controller == null:
		push_error("controller missing for reward tray probe")
		main_instance.queue_free()
		await process_frame
		return
	controller.call("_render_scene", {
		"phase": "reward_loot",
		"rewardPresentationStep": "tray_review",
		"reward": {"pendingRewards": [
			{"kind": "Vermilion Venting Beacon", "rarity": "rare", "qty": 1, "presentation": {"badge": "rare red beacon"}, "payload": {"item_type": "beacon", "energy_type": "red"}},
			{"kind": "Tremor Heat Post", "rarity": "common", "qty": 1, "presentation": {"badge": "common red beacon"}, "payload": {"item_type": "beacon", "energy_type": "red"}},
			{"kind": "Relic Spur", "rarity": "common", "qty": 1, "presentation": {"badge": "common relic"}, "payload": {"item_type": "relic", "energy_type": ""}},
			{"kind": "Purple Starter Drill", "rarity": "rare", "qty": 1, "presentation": {"badge": "rare purple drill"}, "payload": {"item_type": "drill", "energy_type": "purple"}},
			{"kind": "Blue Starter Beacon", "rarity": "common", "qty": 1, "presentation": {"badge": "common blue beacon"}, "payload": {"item_type": "beacon", "energy_type": "blue"}}
		]},
		"terrain": {"rows": 0, "columns": 0, "cells": []},
		"hud": {},
		"targetPanel": {},
		"stageIndex": 1,
		"maxStages": 5
	})
	await process_frame
	await process_frame
	await process_frame
	_dump_layout(main_instance, "REWARD_TRAY")
	main_instance.queue_free()
	await process_frame

func _probe_stage_two_combat(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	var controller = main_instance.get_node_or_null("MainController")
	var node_map_scene = main_instance.get("node_map_scene")
	var start_button = main_instance.get("start_button") as Button
	if controller == null or node_map_scene == null or start_button == null:
		push_error("combat probe setup failed")
		main_instance.queue_free()
		await process_frame
		return
	node_map_scene.press_color_button(0)
	if node_map_scene.map_node_count() > 0:
		node_map_scene.press_node_button(0)
	await process_frame
	await process_frame
	start_button.pressed.emit()
	await process_frame
	await process_frame
	_dump_layout(main_instance, "STAGE_TWO_COMBAT")
	main_instance.queue_free()
	await process_frame

func _dump_layout(main_instance: Node, label: String) -> void:
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(root.size))
	print("\n== ", label, " viewport=", viewport_rect, " ==")
	var targets := {
		"Main": main_instance,
		"RootMargin": main_instance.get_node_or_null("RootMargin"),
		"AppShell": main_instance.get_node_or_null("RootMargin/AppShell"),
		"Header": main_instance.get_node_or_null("RootMargin/AppShell/Header"),
		"HeaderActions": main_instance.get("header_actions"),
		"TopContent": main_instance.get("top_content"),
		"LeftColumn": main_instance.get("left_column"),
		"BackpackContainer": main_instance.get("backpack_container"),
		"RightSidebar": main_instance.get("right_sidebar"),
		"ActivePhaseContainer": main_instance.get("active_phase_container"),
		"NodeSelectPanel": main_instance.get("node_select_panel"),
		"NodeMapRow": main_instance.get("node_select_content_row"),
		"BattlefieldPanel": main_instance.get("battlefield_ui"),
		"BattlefieldVisualRoot": main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/BattlefieldPanel/Margin/BattlefieldBox/BattlefieldVisualRoot"),
		"RewardPanel": main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel"),
		"RewardRow": main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow"),
		"DiscardZone": main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/DiscardZone"),
		"ActionBar": main_instance.get("action_bar")
	}
	for key in targets.keys():
		_print_control(key, targets[key], viewport_rect)
	_dump_overflows(main_instance, viewport_rect)

func _print_control(label: String, value: Variant, viewport_rect: Rect2) -> void:
	var control = value as Control
	if control == null:
		print(label, " missing")
		return
	var rect := control.get_global_rect()
	var min_size := control.get_combined_minimum_size()
	var over_right := rect.end.x - viewport_rect.end.x
	var over_bottom := rect.end.y - viewport_rect.end.y
	print(label, " visible=", control.visible, " rect=", rect, " min=", min_size, " custom_min=", control.custom_minimum_size, " over_right=", over_right, " over_bottom=", over_bottom)

func _dump_overflows(node: Node, viewport_rect: Rect2) -> void:
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		for child in current.get_children():
			stack.append(child)
		var control = current as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		if rect.end.x > viewport_rect.end.x + 0.5 or rect.end.y > viewport_rect.end.y + 0.5 or rect.position.x < viewport_rect.position.x - 0.5 or rect.position.y < viewport_rect.position.y - 0.5:
			print("OVERFLOW ", control.get_path(), " rect=", rect, " viewport=", viewport_rect)
