extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const OUTPUT_PATH := "../docs/evidence/reward-toggle-toast-2026-06-23/reward_toggle_toast_1440x900.png"
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(VIEWPORT_SIZE)
	root.size = VIEWPORT_SIZE
	var MainScene: PackedScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene loads for reward toggle/toast visual capture")
	if MainScene == null:
		_finish(1)
		return
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for reward toggle/toast visual capture")
	if main_instance == null:
		_finish(1)
		return
	root.add_child(main_instance)
	await _settle_frames(8)
	if not await _go_to_reward(main_instance):
		_finish(1)
		return
	await _settle_frames(12)
	if main_instance.has_method("show_info_toast"):
		main_instance.call("show_info_toast", TextCatalogScript.t("log.inventory.invalid_placement"), 5.0)
	await _settle_frames(6)
	_assert_reward_toggle_and_toast_rects(main_instance)
	var absolute_path := ProjectSettings.globalize_path("res://%s" % OUTPUT_PATH)
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var image := root.get_texture().get_image()
	_assert(image != null and not image.is_empty(), "reward toggle/toast screenshot image is non-empty")
	if image != null and not image.is_empty():
		var save_error := image.save_png(absolute_path)
		_assert(save_error == OK, "reward toggle/toast screenshot saves to %s with status %s" % [absolute_path, str(save_error)])
	if failures.is_empty():
		print("REWARD_TOGGLE_TOAST_VISUAL_CAPTURE_OK %s" % absolute_path)
	_finish(0 if failures.is_empty() else 1)

func _go_to_reward(main_instance: Node) -> bool:
	if not await _go_to_battle(main_instance):
		return false
	var controller = main_instance.get_node_or_null("MainController")
	if controller == null:
		_assert(false, "controller exists before reward toggle/toast visual capture")
		return false
	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await _settle_frames(5)
	var reward_reveal_overlay = main_instance.get_node_or_null("RewardRevealOverlay")
	if reward_reveal_overlay != null:
		await _finish_reward_ceremony(controller, reward_reveal_overlay)
	await _settle_frames(32)
	return _expect_active(main_instance, "reward", "reward toggle/toast visual capture")

func _go_to_battle(main_instance: Node) -> bool:
	if not await _go_to_node_select(main_instance):
		return false
	_press_current_node(main_instance)
	await _settle_frames(2)
	var start_button = main_instance.get("start_button")
	if start_button == null:
		_assert(false, "start button exists before reward toggle/toast visual capture")
		return false
	start_button.pressed.emit()
	await _settle_frames(10)
	return _expect_active(main_instance, "battle", "reward toggle/toast battle setup")

func _go_to_node_select(main_instance: Node) -> bool:
	var character_page = main_instance.get("character_select_page")
	if character_page == null:
		_assert(false, "character page exists before reward toggle/toast visual capture")
		return false
	character_page.color_selected.emit("purple")
	character_page.continue_requested.emit()
	await _settle_frames(4)
	await _advance_story_if_present(main_instance, "leviathan_select")
	if not _expect_active(main_instance, "leviathan_select", "reward toggle/toast leviathan select"):
		return false
	var leviathan_page = main_instance.get("leviathan_select_page")
	if leviathan_page == null:
		_assert(false, "leviathan page exists before reward toggle/toast visual capture")
		return false
	leviathan_page.leviathan_selected.emit("storm_wyvern")
	leviathan_page.start_requested.emit()
	await _settle_frames(5)
	await _advance_story_if_present(main_instance, "node_select")
	return _expect_active(main_instance, "node_select", "reward toggle/toast node select")

func _advance_story_if_present(main_instance: Node, return_page_id: String) -> void:
	if str(main_instance.get("active_page_id")) != "story_scene":
		return
	var controller = main_instance.get_node_or_null("MainController")
	var story_page = main_instance.get("story_scene_page")
	if controller == null or story_page == null:
		return
	var story: Dictionary = controller.get("active_story_scene")
	var scene_id := str(story.get("id", ""))
	story_page.continue_requested.emit(scene_id)
	await process_frame
	story_page.continue_requested.emit(scene_id)
	await _settle_frames(3)

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

func _press_current_node(main_instance: Node) -> void:
	var controller = main_instance.get_node_or_null("MainController")
	var page_scenes: Dictionary = main_instance.get("page_scenes")
	var node_select_page = page_scenes.get("node_select", null)
	if node_select_page == null:
		_assert(false, "node select page exists for reward toggle/toast visual capture")
		return
	var route_count := int(node_select_page.call("route_button_count")) if node_select_page.has_method("route_button_count") else 0
	if route_count > 0 and node_select_page.has_method("press_route_button"):
		node_select_page.call("press_route_button", 0)
		return
	var current_scene: Dictionary = controller.get("current_scene") if controller != null else {}
	if bool(current_scene.get("nodeSelect", {}).get("isBossStage", false)):
		if node_select_page.has_method("press_boss_marker"):
			node_select_page.call("press_boss_marker")
		else:
			_assert(false, "node select page exposes boss marker helper")
		return
	if node_select_page.has_method("press_start_marker"):
		node_select_page.call("press_start_marker")
	else:
		_assert(false, "node select page exposes start marker helper")

func _assert_reward_toggle_and_toast_rects(main_instance: Node) -> void:
	var backpack_ui = main_instance.get("backpack_ui") as Control
	_assert(backpack_ui != null, "reward page exposes the shared backpack UI")
	if backpack_ui == null:
		return
	var toggle = backpack_ui.get_node_or_null("InfluencePreviewToggle") as Control
	_assert(toggle != null, "reward backpack exposes the influence range toggle")
	if toggle != null:
		var panel_rect := backpack_ui.get_global_rect()
		var toggle_rect := toggle.get_global_rect()
		_assert(toggle.visible, "reward influence toggle is visible on tray review")
		_assert(toggle_rect.position.x >= panel_rect.end.x - toggle_rect.size.x - 24.0, "reward influence toggle sits in the rendered upper-right rail, got %s inside %s" % [str(toggle_rect), str(panel_rect)])
		_assert(toggle_rect.position.y <= panel_rect.position.y + 24.0, "reward influence toggle is near the rendered top edge, got %s inside %s" % [str(toggle_rect), str(panel_rect)])
		_assert(_toggle_stays_off_interactive_slots(backpack_ui, toggle_rect), "reward influence toggle does not cover interactive backpack item slots, got %s" % str(toggle_rect))
	var toast = main_instance.get("info_toast_panel") as Control
	var toast_label = main_instance.get("info_toast_label") as Label
	var hint_label = main_instance.get("info_toast_hint_label") as Label
	_assert(toast != null, "invalid-placement toast exists during reward screenshot")
	_assert(toast_label != null, "invalid-placement toast exposes warning label")
	_assert(hint_label != null, "invalid-placement toast exposes lower dismissal hint")
	if toast != null:
		var toast_rect := toast.get_global_rect()
		var toast_center := toast_rect.position + toast_rect.size * 0.5
		_assert(toast.visible, "invalid-placement toast is visible during reward screenshot")
		_assert(toast_rect.size.x <= 620.0 and toast_rect.size.y <= 120.0, "invalid-placement toast is compact, got %s" % str(toast_rect))
		_assert(absf(toast_center.x - float(VIEWPORT_SIZE.x) * 0.5) <= 12.0, "invalid-placement toast is centered horizontally, got %s" % str(toast_rect))
		_assert(absf(toast_center.y - float(VIEWPORT_SIZE.y) * 0.5) <= 20.0, "invalid-placement toast is centered vertically, got %s" % str(toast_rect))
		if toast_label != null:
			_assert(toast_rect.encloses(toast_label.get_global_rect()), "invalid-placement warning label stays inside the compact toast, got %s inside %s" % [str(toast_label.get_global_rect()), str(toast_rect)])
		if hint_label != null:
			_assert(toast_rect.encloses(hint_label.get_global_rect()), "invalid-placement hint label stays inside the compact toast, got %s inside %s" % [str(hint_label.get_global_rect()), str(toast_rect)])
	if toast_label != null:
		_assert(str(toast_label.text).length() > 0, "invalid-placement toast warning label has message text")
	if hint_label != null:
		_assert(str(hint_label.text) == "0초 뒤 사라집니다.", "invalid-placement toast lower hint matches the requested copy")

func _toggle_stays_off_interactive_slots(backpack_ui: Control, toggle_rect: Rect2) -> bool:
	if not backpack_ui.has_method("slot_coord_at_global_pos"):
		return false
	var sample_points := [
		toggle_rect.position + Vector2(2, 2),
		toggle_rect.position + Vector2(toggle_rect.size.x - 2.0, 2.0),
		toggle_rect.position + toggle_rect.size * 0.5,
		toggle_rect.position + Vector2(2.0, toggle_rect.size.y - 2.0),
		toggle_rect.end - Vector2(2, 2),
	]
	for point in sample_points:
		var coord: Vector2 = backpack_ui.call("slot_coord_at_global_pos", point)
		if coord.x >= 0.0 or coord.y >= 0.0:
			return false
	return true

func _expect_active(main_instance: Node, expected: String, label: String) -> bool:
	var active := str(main_instance.get("active_page_id"))
	if active != expected:
		_assert(false, "%s expected active page %s, got %s" % [label, expected, active])
		return false
	return true

func _settle_frames(count: int) -> void:
	for _index in range(count):
		await process_frame

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _finish(code: int) -> void:
	for failure in failures:
		push_error(failure)
	call_deferred("quit", code)
