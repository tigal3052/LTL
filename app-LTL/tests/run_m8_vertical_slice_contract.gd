extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	TextCatalogScript.set_locale("ko")
	var MainScene: PackedScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene loads for M8 vertical slice contract")
	if MainScene == null:
		_finish()
		return
	await _assert_defeat_retry_choices(MainScene)
	_finish()

func _assert_defeat_retry_choices(MainScene: PackedScene) -> void:
	var main_instance = MainScene.instantiate()
	root.add_child(main_instance)
	await _settle_frames(3)
	var controller = await _boot_to_node_select(main_instance)
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return
	var initial_seed := int(controller.preview_controller.seed)
	await _force_failure(main_instance, controller)
	_assert_eq(str(main_instance.get("active_page_id")), "defeat", "M8 failure enters the defeat page")
	_assert(controller.growth_state.to_dict().get("unlockedStarterItems", []).has("starter_repair_kit"), "M8 failure unlocks starter repair kit")
	var defeat_page = main_instance.get("page_scenes").get("defeat", null)
	_assert(defeat_page != null, "defeat page exists for retry choice contract")
	if defeat_page == null:
		main_instance.queue_free()
		await process_frame
		return
	var same_seed_button = defeat_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RetryButton") as Button
	var new_seed_button = defeat_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/NewSeedRetryButton") as Button
	_assert(same_seed_button != null, "defeat page exposes same-seed retry button")
	_assert(new_seed_button != null, "defeat page exposes new-seed retry button")
	if same_seed_button != null:
		same_seed_button.pressed.emit()
	await _settle_frames(3)
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "same-seed retry returns to node select")
	_assert_eq(int(controller.preview_controller.seed), initial_seed, "same-seed retry preserves the failed seed")
	_assert(controller.growth_state.to_dict().get("unlockedStarterItems", []).has("starter_repair_kit"), "same-seed retry preserves repair unlock")

	await _force_failure(main_instance, controller)
	var second_seed := int(controller.preview_controller.seed)
	if new_seed_button != null:
		new_seed_button.pressed.emit()
	await _settle_frames(3)
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "new-seed retry returns to node select")
	_assert(int(controller.preview_controller.seed) != second_seed, "new-seed retry changes the failed seed")
	_assert_eq(str(controller.current_scene.get("leviathanId", "")), "ossuary_tortoise", "retry stays on the M8 Leviathan")
	main_instance.queue_free()
	await process_frame

func _boot_to_node_select(main_instance: Node) -> Node:
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists for M8 contract")
	if controller == null:
		return null
	var character_page = main_instance.get("character_select_page")
	if character_page != null:
		character_page.color_selected.emit("red")
		character_page.continue_requested.emit()
	await _settle_frames(2)
	await _advance_story_if_present(main_instance, "leviathan_select")
	var leviathan_page = main_instance.get("leviathan_select_page")
	if leviathan_page != null:
		leviathan_page.leviathan_selected.emit("ossuary_tortoise")
		leviathan_page.start_requested.emit()
	await _settle_frames(3)
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "M8 boot reaches node select")
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
	_assert_eq(str(main_instance.get("active_page_id")), return_page_id, "story scene returns to %s" % return_page_id)

func _force_failure(main_instance: Node, controller: Node) -> void:
	controller.preview_controller.run.select_node(0)
	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "failed"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await _settle_frames(3)

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
	if failures.is_empty():
		print("M8_VERTICAL_SLICE_CONTRACT_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
