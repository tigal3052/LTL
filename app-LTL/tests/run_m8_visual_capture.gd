extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const OUTPUT_DIR := "../docs/evidence/m8-vertical-slice-2026-06-17/screenshots"

var failures: Array[String] = []
var captured: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(VIEWPORT_SIZE)
	root.size = VIEWPORT_SIZE
	var main_scene: PackedScene = load("res://src/Main.tscn")
	_assert(main_scene != null, "main scene loads for M8 visual capture")
	if main_scene == null:
		_finish()
		return
	var main_instance = main_scene.instantiate()
	root.add_child(main_instance)
	await _settle_frames(8)
	var controller := await _boot_to_node_select(main_instance)
	if controller != null:
		await _capture("node_select")
		await _enter_battle(main_instance)
		await _capture("battle")
		await _enter_reward(main_instance, controller)
		await _capture("reward")
	main_instance.queue_free()
	await _settle_frames(4)

	var defeat_instance = main_scene.instantiate()
	root.add_child(defeat_instance)
	await _settle_frames(8)
	var defeat_controller := await _boot_to_node_select(defeat_instance)
	if defeat_controller != null:
		await _enter_defeat(defeat_controller)
		await _settle_frames(6)
		await _capture("defeat")
	defeat_instance.queue_free()
	await _settle_frames(2)
	_finish()

func _boot_to_node_select(main_instance: Node) -> Node:
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists for M8 visual capture")
	var character_page = main_instance.get("character_select_page")
	if character_page != null:
		character_page.color_selected.emit("blue")
		character_page.continue_requested.emit()
	await _settle_frames(2)
	await _advance_story_if_present(main_instance, "leviathan_select")
	var leviathan_page = main_instance.get("leviathan_select_page")
	if leviathan_page != null:
		leviathan_page.leviathan_selected.emit("ossuary_tortoise")
		leviathan_page.start_requested.emit()
	await _settle_frames(4)
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "M8 capture reaches node select")
	return controller

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
	await _settle_frames(2)
	_assert_eq(str(main_instance.get("active_page_id")), return_page_id, "story returns to %s before M8 capture" % return_page_id)

func _enter_battle(main_instance: Node) -> void:
	var page_scenes: Dictionary = main_instance.get("page_scenes")
	var node_select_page = page_scenes.get("node_select", null)
	if node_select_page != null and node_select_page.has_method("press_start_marker"):
		node_select_page.call("press_start_marker")
	var start_button = main_instance.get("start_button")
	if start_button != null:
		start_button.pressed.emit()
	await _settle_frames(5)
	_assert_eq(str(main_instance.get("active_page_id")), "battle", "M8 capture reaches battle")

func _enter_reward(main_instance: Node, controller: Node) -> void:
	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await _settle_frames(8)
	_assert_eq(str(main_instance.get("active_page_id")), "reward", "M8 capture reaches reward")

func _enter_defeat(controller: Node) -> void:
	controller.preview_controller.run.select_node(0)
	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "failed"})
	controller.call("_render_scene", controller.preview_controller.get_scene())

func _capture(page_id: String) -> void:
	await _settle_frames(8)
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		_assert(false, "viewport image is empty for %s M8 capture" % page_id)
		return
	if _is_flat_image(image):
		_assert(false, "viewport image is visually flat for %s M8 capture" % page_id)
		return
	var absolute_path := ProjectSettings.globalize_path("res://%s/%s_1440x900.png" % [OUTPUT_DIR, page_id])
	DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	var save_error := image.save_png(absolute_path)
	_assert(save_error == OK, "saved %s M8 capture to %s" % [page_id, absolute_path])
	if save_error == OK:
		captured.append(absolute_path)

func _is_flat_image(image: Image) -> bool:
	var first := image.get_pixel(0, 0).to_html()
	var y_step: int = max(1, int(image.get_height() / 6))
	var x_step: int = max(1, int(image.get_width() / 6))
	for y in range(0, image.get_height(), y_step):
		for x in range(0, image.get_width(), x_step):
			if image.get_pixel(x, y).to_html() != first:
				return false
	return true

func _settle_frames(count: int) -> void:
	for _index in range(count):
		await process_frame

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _finish() -> void:
	if failures.is_empty() and captured.size() == 4:
		print("M8_VISUAL_CAPTURE_OK")
		for path in captured:
			print("M8_VISUAL_CAPTURE_FILE %s" % path)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
