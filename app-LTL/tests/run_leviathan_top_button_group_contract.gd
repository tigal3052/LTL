extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	var main_scene := load("res://src/Main.tscn") as PackedScene
	_assert(main_scene != null, "main scene loads for leviathan top button group contract")
	if main_scene == null:
		_finish()
		return
	await _assert_top_button_group(main_scene)
	_finish()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _finish() -> void:
	if failures.is_empty():
		print("LEVIATHAN_TOP_BUTTON_GROUP_CONTRACT_OK")
		call_deferred("quit", 0)
		return
	for failure in failures:
		push_error(failure)
	call_deferred("quit", 1)

func _advance_story_if_present(main_instance: Node, return_page_id: String) -> void:
	if str(main_instance.get("active_page_id")) != "story_scene":
		return
	var story_page = main_instance.get("story_scene_page")
	var controller = main_instance.get_node_or_null("MainController")
	_assert(story_page != null, "story scene exists during top button group contract")
	_assert(controller != null, "main controller exists during top button group contract story handoff")
	if story_page == null or controller == null:
		return
	var story: Dictionary = controller.get("active_story_scene")
	var scene_id := str(story.get("id", ""))
	_assert(scene_id != "", "story scene exposes a scene id during top button group contract")
	if scene_id.is_empty():
		return
	story_page.continue_requested.emit(scene_id)
	await process_frame
	story_page.continue_requested.emit(scene_id)
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), return_page_id, "story scene returns to %s for top button group contract" % return_page_id)

func _instantiate_main(main_scene: PackedScene) -> Node:
	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	return main_instance

func _go_to_leviathan_select(main_instance: Node) -> Node:
	await _advance_story_if_present(main_instance, "character_select")
	var character_page = main_instance.get("character_select_page")
	_assert(character_page != null, "character select page exists before top button group contract")
	if character_page == null:
		return null
	character_page.color_selected.emit("purple")
	character_page.continue_requested.emit()
	await process_frame
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "leviathan_select", "character select advances to leviathan select for top button group contract")
	return main_instance.get("leviathan_select_page")

func _assert_top_button_group(main_scene: PackedScene) -> void:
	var main_instance := await _instantiate_main(main_scene)
	var leviathan_page = await _go_to_leviathan_select(main_instance)
	_assert(leviathan_page != null, "leviathan select page exists for top button group contract")
	if leviathan_page == null:
		main_instance.queue_free()
		await process_frame
		return
	await process_frame
	await process_frame
	var tabs_row := leviathan_page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow") as HBoxContainer
	var top_actions := leviathan_page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/TopActions") as HBoxContainer
	var character_button := leviathan_page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow/CharacterTabButton") as Button
	var leviathan_button := leviathan_page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow/LeviathanTabButton") as Button
	var codex_button := leviathan_page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow/CodexActionButton") as Button
	var settings_button := leviathan_page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow/SettingsActionButton") as Button
	_assert(tabs_row != null, "top tabs row exists for shared button group contract")
	_assert(character_button != null and leviathan_button != null and codex_button != null and settings_button != null, "shared top button group exposes character/leviathan/codex/settings buttons")
	if tabs_row != null:
		_assert_eq(tabs_row.get_child_count(), 4, "shared top button group keeps exactly four buttons in the header row")
	if top_actions != null:
		_assert(not top_actions.visible or top_actions.get_child_count() == 0, "legacy top-actions host is retired after merging codex/settings into the shared button group")
	if character_button != null and leviathan_button != null and codex_button != null and settings_button != null:
		_assert(character_button.get_parent() == tabs_row and leviathan_button.get_parent() == tabs_row and codex_button.get_parent() == tabs_row and settings_button.get_parent() == tabs_row, "all four top buttons share the same header button group host")
		_assert_eq(str(character_button.get_meta("kind", "")), "top_group", "character button uses the shared top-group style kind")
		_assert_eq(str(leviathan_button.get_meta("kind", "")), "top_group", "leviathan button uses the shared top-group style kind")
		_assert_eq(str(codex_button.get_meta("kind", "")), "top_group", "codex button uses the shared top-group style kind")
		_assert_eq(str(settings_button.get_meta("kind", "")), "top_group", "settings button uses the shared top-group style kind")
		_assert(bool(leviathan_button.get_meta("active", false)), "leviathan button stays marked active inside the shared group")
		_assert(not bool(character_button.get_meta("active", false)) and not bool(codex_button.get_meta("active", false)) and not bool(settings_button.get_meta("active", false)), "other top-group buttons stay non-active in the shared group")
		var ordered_names := [str(tabs_row.get_child(0).name), str(tabs_row.get_child(1).name), str(tabs_row.get_child(2).name), str(tabs_row.get_child(3).name)]
		_assert_eq(ordered_names, ["CharacterTabButton", "LeviathanTabButton", "CodexActionButton", "SettingsActionButton"], "shared top button group orders codex/settings immediately after character/leviathan")
		_assert(character_button.get_global_rect().position.x < leviathan_button.get_global_rect().position.x and leviathan_button.get_global_rect().position.x < codex_button.get_global_rect().position.x and codex_button.get_global_rect().position.x < settings_button.get_global_rect().position.x, "shared top button group lays out the four buttons left-to-right without splitting the group")
	var settings_panel = main_instance.get("settings_panel") as Control
	var codex_panel = main_instance.get("codex_panel") as Control
	if codex_button != null:
		codex_button.pressed.emit()
		await process_frame
		await process_frame
		_assert(codex_panel != null and codex_panel.visible, "shared-group codex button opens the shared codex overlay")
	if settings_button != null:
		settings_button.pressed.emit()
		await process_frame
		await process_frame
		_assert(settings_panel != null and settings_panel.visible, "shared-group settings button opens the shared settings overlay")
		_assert(codex_panel == null or not codex_panel.visible, "shared-group settings button hides the codex overlay when settings opens")
	if character_button != null:
		character_button.pressed.emit()
		await process_frame
		await process_frame
		await _advance_story_if_present(main_instance, "character_select")
		_assert_eq(str(main_instance.get("active_page_id")), "character_select", "shared-group character button returns to character select")
	main_instance.queue_free()
	await process_frame
