extends SceneTree

const DEFAULT_VIEWPORT_SIZE := Vector2i(1280, 720)
const DEFAULT_PAGE_ID := "reward"
const DEFAULT_OUTPUT := "../docs/evidence/shared-backpack-2026-06-16/reward_1280x720.png"

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var page_id := _arg_value("--page", DEFAULT_PAGE_ID)
	var viewport_size := _parse_viewport(_arg_value("--viewport", "1280x720"))
	var output_path := _arg_value("--output", DEFAULT_OUTPUT)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(viewport_size)
	root.size = viewport_size
	var MainScene: PackedScene = load("res://src/Main.tscn")
	if MainScene == null:
		_fail("main scene failed to load for shared-backpack capture")
		_finish(1)
		return
	var main_instance = MainScene.instantiate()
	if main_instance == null:
		_fail("main scene failed to instantiate for shared-backpack capture")
		_finish(1)
		return
	root.add_child(main_instance)
	await _settle_frames(8)
	var ok := await _drive_to_page(main_instance, page_id)
	await _settle_frames(32)
	if not ok:
		_finish(1)
		return
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("viewport image is empty for %s capture" % page_id)
		_finish(1)
		return
	var absolute_path := ProjectSettings.globalize_path("res://%s" % output_path)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var save_error := image.save_png(absolute_path)
	if save_error != OK:
		_fail("failed to save %s capture to %s: %s" % [page_id, absolute_path, str(save_error)])
		_finish(1)
		return
	print("SHARED_BACKPACK_VISUAL_CAPTURE_OK %s %s" % [page_id, absolute_path])
	_finish(0)

func _drive_to_page(main_instance: Node, page_id: String) -> bool:
	match page_id:
		"reward":
			return await _go_to_reward(main_instance)
		"reward_drop":
			return await _go_to_reward_drop(main_instance)
		"second_battle":
			return await _go_to_second_battle(main_instance)
		_:
			_fail("unknown shared-backpack capture page id: %s" % page_id)
			return false

func _go_to_node_select(main_instance: Node) -> bool:
	var character_page = main_instance.get("character_select_page")
	if character_page == null:
		_fail("character page missing before shared-backpack capture")
		return false
	character_page.color_selected.emit("purple")
	character_page.continue_requested.emit()
	await _settle_frames(4)
	if not _expect_active(main_instance, "leviathan_select", "leviathan_select"):
		return false
	var leviathan_page = main_instance.get("leviathan_select_page")
	if leviathan_page == null:
		_fail("leviathan page missing before shared-backpack capture")
		return false
	leviathan_page.leviathan_selected.emit("storm_wyvern")
	leviathan_page.start_requested.emit()
	await _settle_frames(5)
	return _expect_active(main_instance, "node_select", "node_select")

func _go_to_battle(main_instance: Node, preferred_route_index: int = 0) -> bool:
	if not await _go_to_node_select(main_instance):
		return false
	_press_current_node(main_instance, preferred_route_index, "battle visual capture")
	await _settle_frames(2)
	var start_button = main_instance.get("start_button")
	if start_button == null:
		_fail("start button missing before battle visual capture")
		return false
	start_button.pressed.emit()
	await _settle_frames(10)
	return _expect_active(main_instance, "battle", "battle")

func _go_to_reward(main_instance: Node) -> bool:
	if not await _go_to_battle(main_instance):
		return false
	var controller = main_instance.get_node_or_null("MainController")
	if controller == null:
		_fail("controller missing before reward visual capture")
		return false
	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await _settle_frames(5)
	var reward_reveal_overlay = main_instance.get_node_or_null("RewardRevealOverlay")
	if reward_reveal_overlay != null:
		await _finish_reward_ceremony(controller, reward_reveal_overlay)
	await _settle_frames(32)
	return _expect_active(main_instance, "reward", "reward")

func _go_to_second_battle(main_instance: Node) -> bool:
	if not await _go_to_reward(main_instance):
		return false
	var controller = main_instance.get_node_or_null("MainController")
	if controller == null:
		_fail("controller missing before second-battle visual capture")
		return false
	controller.call("_proceed_to_node_select")
	await _settle_frames(8)
	if not _expect_active(main_instance, "node_select", "second-battle node_select"):
		return false
	_press_current_node(main_instance, 1, "second-battle visual capture")
	await _settle_frames(2)
	var start_button = main_instance.get("start_button")
	if start_button == null:
		_fail("start button missing before second-battle visual capture")
		return false
	start_button.pressed.emit()
	await _settle_frames(18)
	return _expect_active(main_instance, "battle", "second_battle")

func _go_to_reward_drop(main_instance: Node) -> bool:
	if not await _go_to_reward(main_instance):
		return false
	var controller = main_instance.get_node_or_null("MainController")
	if controller == null:
		_fail("controller missing before reward-drop visual capture")
		return false
	var selection := await _select_first_placeable_reward_drag(controller)
	if selection.is_empty():
		_fail("no placeable reward found for reward-drop visual capture")
		return false
	main_instance.emit_signal("reward_meta_drop_requested", int(selection.get("index", -1)), selection.get("coord", Vector2(-1, -1)))
	await _settle_frames(24)
	return _expect_active(main_instance, "reward", "reward_drop")

func _finish_reward_ceremony(controller: Node, reward_reveal_overlay: Node) -> void:
	var reward_count: int = max(1, int(Array(controller.get("local_rewards_list")).size()))
	reward_reveal_overlay.set("current_step", "reveal_queue")
	reward_reveal_overlay.set("current_reveal_index", reward_count - 1)
	reward_reveal_overlay.set("readable", true)
	reward_reveal_overlay.call("_handle_confirm_input")
	var settle_frames := 0
	while bool(controller.get("is_reveal_vfx_running")) and settle_frames < 18:
		await process_frame
		settle_frames += 1

func _press_current_node(main_instance: Node, preferred_route_index: int, label: String) -> void:
	var controller = main_instance.get_node_or_null("MainController")
	var page_scenes: Dictionary = main_instance.get("page_scenes")
	var node_select_page = page_scenes.get("node_select", null)
	if node_select_page == null:
		_fail("node select page missing for %s" % label)
		return
	var route_count := int(node_select_page.call("route_button_count")) if node_select_page.has_method("route_button_count") else 0
	if route_count > 0:
		if node_select_page.has_method("press_route_button"):
			node_select_page.call("press_route_button", clampi(preferred_route_index, 0, route_count - 1))
		else:
			_fail("node select page lacks route-button helper for %s" % label)
		return
	var current_scene: Dictionary = controller.get("current_scene") if controller != null else {}
	if bool(current_scene.get("nodeSelect", {}).get("isBossStage", false)):
		if node_select_page.has_method("press_boss_marker"):
			node_select_page.call("press_boss_marker")
		else:
			_fail("node select page lacks boss-marker helper for %s" % label)
		return
	if node_select_page.has_method("press_start_marker"):
		node_select_page.call("press_start_marker")
	else:
		_fail("node select page lacks start-marker helper for %s" % label)

func _select_first_placeable_reward_drag(controller: Node) -> Dictionary:
	var rewards: Array = Array(controller.get("local_rewards_list"))
	for index in range(rewards.size()):
		controller.call("_on_reward_meta_drag_started_v2", index)
		await _settle_frames(2)
		var artifact = controller.get("held_artifact")
		if artifact == null:
			continue
		var coord := _first_valid_reward_drop_coord(controller.get("inventory"), artifact)
		if coord.x >= 0.0 and coord.y >= 0.0:
			return {"index": index, "coord": coord}
		controller.call("_on_reward_meta_drag_canceled_v2", index)
		await _settle_frames(2)
	return {}

func _first_valid_reward_drop_coord(inventory, artifact) -> Vector2:
	if inventory == null or artifact == null:
		return Vector2(-1, -1)
	for row in range(8):
		for column in range(8):
			if inventory.can_place_artifact(artifact, column, row):
				return Vector2(column, row)
	return Vector2(-1, -1)

func _expect_active(main_instance: Node, expected: String, label: String) -> bool:
	var active := str(main_instance.get("active_page_id"))
	if active != expected:
		_fail("%s expected active page %s, got %s" % [label, expected, active])
		return false
	return true

func _arg_value(prefix: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix + "="):
			return arg.substr(prefix.length() + 1)
	return fallback

func _parse_viewport(raw: String) -> Vector2i:
	var parts := raw.split("x")
	if parts.size() != 2:
		return DEFAULT_VIEWPORT_SIZE
	return Vector2i(maxi(1, int(parts[0])), maxi(1, int(parts[1])))

func _settle_frames(count: int) -> void:
	for _index in range(count):
		await process_frame

func _fail(message: String) -> void:
	failures.append(message)

func _finish(code: int) -> void:
	for failure in failures:
		push_error(failure)
	call_deferred("quit", code)
