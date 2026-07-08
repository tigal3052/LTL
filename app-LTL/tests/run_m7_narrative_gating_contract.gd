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
	_assert(MainScene != null, "main scene loads for M7 narrative gating")
	if MainScene == null:
		_finish()
		return
	await _assert_combat_and_reward_gating(MainScene)
	await _assert_english_apply_close_remains_interactive(MainScene)
	_finish()

func _assert_combat_and_reward_gating(MainScene: PackedScene) -> void:
	var main_instance = MainScene.instantiate()
	root.add_child(main_instance)
	await _settle_frames(3)
	var controller = await _boot_to_node_select(main_instance)
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return
	await _dismiss_visible_narrative(main_instance)
	var node_select_page = _node_select_page(main_instance)
	var start_button = main_instance.get("start_button") as Button
	_assert(node_select_page != null, "node-select page exists before battle gating")
	_assert(start_button != null, "start button exists before battle gating")
	if node_select_page != null and node_select_page.has_method("press_start_marker"):
		node_select_page.call("press_start_marker")
	await _settle_frames(2)
	if start_button != null:
		start_button.pressed.emit()
	await _settle_frames(4)
	_assert_eq(str(main_instance.get("active_page_id")), "battle", "selected node enters battle page")
	_assert_narrative_visible(main_instance, "first_valid_hit", "combat guide appears before the first attack")
	_assert_eq(bool(controller.get("battle_pause_active")), true, "combat is paused while the guide narrative is visible")
	var shots_before := _shots_hit(controller)
	var target := _current_target(controller)
	controller.call("_on_cell_clicked", str(target.get("cellId", "r0c0")), str(target.get("color", "red")))
	await _settle_frames(2)
	_assert_eq(_shots_hit(controller), shots_before, "combat click is ignored until the guide is dismissed")
	await _dismiss_visible_narrative(main_instance)
	await _settle_frames(2)
	_assert_eq(bool(controller.get("battle_pause_active")), false, "combat resumes after the guide narrative is dismissed")

	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await _settle_frames(4)
	controller.call("_on_reward_ceremony_finished")
	await _settle_frames(5)
	_assert(str(main_instance.get("active_page_id")) in ["reward", "boss_reward"], "combat clear reaches the reward page")
	_assert_narrative_visible(main_instance, "first_artifact", "reward guide appears before reward item handling")
	controller.call("_on_reward_meta_drag_started_v2", 0)
	await _settle_frames(2)
	_assert_eq(controller.get("held_artifact"), null, "reward drag is blocked while reward guide is visible")
	_assert_eq(bool(controller.get("held_from_rewards")), false, "reward selection source stays clear while guide is visible")
	await _dismiss_visible_narrative(main_instance)
	await _settle_frames(2)
	controller.call("_on_reward_meta_drag_started_v2", 0)
	await _settle_frames(2)
	_assert(controller.get("held_artifact") != null, "reward drag starts after reward guide dismissal")
	_assert_eq(bool(controller.get("held_from_rewards")), true, "reward item handling resumes after guide dismissal")
	main_instance.queue_free()
	await process_frame

func _assert_english_apply_close_remains_interactive(MainScene: PackedScene) -> void:
	TextCatalogScript.set_locale("ko")
	var main_instance = MainScene.instantiate()
	root.add_child(main_instance)
	await _settle_frames(3)
	var controller = await _boot_to_node_select(main_instance)
	var settings_panel = main_instance.get("settings_panel")
	_assert(controller != null, "controller exists for English apply-close contract")
	_assert(settings_panel != null, "settings panel exists for English apply-close contract")
	if settings_panel == null:
		main_instance.queue_free()
		await process_frame
		return
	main_instance.call("set_settings_visible", true)
	await _settle_frames(2)
	var language_select = settings_panel.get("language_select") as OptionButton
	_assert(language_select != null, "language selector exists for English apply-close contract")
	if language_select != null:
		language_select.select(1)
		language_select.item_selected.emit(1)
	await _settle_frames(2)
	var close_button = settings_panel.get_node_or_null("Center/SettingsBox/ButtonsRow/CloseSettingsButton") as Button
	_assert(close_button != null, "apply-and-close button exists for English apply-close contract")
	if close_button != null:
		close_button.pressed.emit()
	await _settle_frames(6)
	_assert_eq(TextCatalogScript.locale(), "en", "English selection is applied")
	_assert_eq(bool(settings_panel.visible), false, "Apply & Close hides the settings panel after English selection")
	_assert(not str(main_instance.get("active_page_id")).is_empty(), "main UI remains rendered after English Apply & Close")
	if controller != null:
		_assert_eq(bool(controller.get("battle_pause_active")), false, "closing settings leaves non-combat UI unpaused")
	main_instance.queue_free()
	await process_frame
	TextCatalogScript.set_locale("ko")

func _boot_to_node_select(main_instance: Node) -> Node:
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists for M7 narrative gating")
	if controller == null:
		return null
	var character_page = main_instance.get("character_select_page")
	if character_page != null:
		character_page.color_selected.emit("purple")
		character_page.continue_requested.emit()
	await _settle_frames(2)
	var leviathan_page = main_instance.get("leviathan_select_page")
	if leviathan_page != null:
		leviathan_page.leviathan_selected.emit("ossuary_tortoise")
		leviathan_page.start_requested.emit()
	await _settle_frames(3)
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "boot reaches node-select page")
	return controller

func _dismiss_visible_narrative(main_instance: Node) -> void:
	var toast = main_instance.get("narrative_toast") as Control
	if toast != null and toast.visible and toast.has_method("dismiss"):
		toast.call("dismiss")
	await _settle_frames(2)

func _assert_narrative_visible(main_instance: Node, beat_id: String, label: String) -> void:
	var toast = main_instance.get("narrative_toast") as Control
	_assert(toast != null, "%s: toast exists" % label)
	if toast == null:
		return
	_assert_eq(bool(toast.visible), true, "%s: toast is visible" % label)
	var controller = main_instance.get_node_or_null("MainController")
	if controller != null:
		var model: Dictionary = controller.get("active_narrative_model")
		_assert_eq(str(model.get("beatId", "")), beat_id, "%s: expected beat is active" % label)

func _current_target(controller: Node) -> Dictionary:
	var scene: Dictionary = controller.get("current_scene")
	var hud: Dictionary = scene.get("hud", {}) if scene.get("hud", {}) is Dictionary else {}
	var aim: Dictionary = hud.get("aim", {}) if hud.get("aim", {}) is Dictionary else {}
	if not str(aim.get("cellId", "")).is_empty():
		return {"cellId": str(aim.get("cellId", "r0c0")), "color": str(aim.get("targetColor", "red"))}
	return {"cellId": "r0c0", "color": "red"}

func _shots_hit(controller: Node) -> int:
	var scene: Dictionary = controller.get("current_scene")
	var combat: Dictionary = scene.get("combat", {}) if scene.get("combat", {}) is Dictionary else {}
	var summary: Dictionary = combat.get("summary", {}) if combat.get("summary", {}) is Dictionary else {}
	return int(summary.get("shots_hit_match", 0))

func _node_select_page(main_instance: Node) -> Node:
	var page_scenes: Dictionary = main_instance.get("page_scenes")
	return page_scenes.get("node_select", null)

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
		print("M7_NARRATIVE_GATING_CONTRACT_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
