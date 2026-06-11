extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	var keepalive := Node.new()
	root.add_child(keepalive)
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene resource loads for page-flow contract")
	if MainScene == null:
		_finish()
		return

	await _assert_meta_to_combat_to_reward_to_node_flow(MainScene)
	await _assert_boss_clear_flow(MainScene)
	await _assert_defeat_flow(MainScene)
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

func _boot_to_node_select(main_instance: Node, color := "blue", leviathan_id := "storm_wyvern") -> Node:
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists during page-flow boot")
	if controller == null:
		return null
	var header = main_instance.get_node_or_null("RootMargin/AppShell/Header") as Control
	var top_content = main_instance.get("top_content") as Control
	var page_scenes: Dictionary = main_instance.get("page_scenes")
	var node_select_page = page_scenes.get("node_select", null) as Control
	_assert(header != null, "header exists during page-flow boot")
	_assert(node_select_page != null, "node-select runtime page exists during page-flow boot")
	_assert(top_content != null, "top-content row exists during page-flow boot")
	if header != null:
		_assert_eq(header.visible, false, "character select hides the legacy shell header")
	if node_select_page != null:
		_assert_eq(node_select_page.visible, false, "character select hides the node-select runtime page")
	if top_content != null:
		_assert_eq(top_content.visible, false, "character select hides the combat top-content row")
	var character_page = main_instance.get("character_select_page")
	_assert(character_page != null, "character select page exists")
	if character_page != null:
		character_page.color_selected.emit(color)
		character_page.continue_requested.emit()
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "leviathan_select", "character select advances to leviathan select")
	if header != null:
		_assert_eq(header.visible, false, "leviathan select keeps the legacy shell header hidden")
	if node_select_page != null:
		_assert_eq(node_select_page.visible, false, "leviathan select keeps the node-select runtime page hidden")
	if top_content != null:
		_assert_eq(top_content.visible, false, "leviathan select keeps the combat top-content row hidden")

	var leviathan_page = main_instance.get("leviathan_select_page")
	_assert(leviathan_page != null, "leviathan select page exists")
	if leviathan_page != null:
		leviathan_page.leviathan_selected.emit(leviathan_id)
		leviathan_page.start_requested.emit()
	await process_frame
	await process_frame
	await process_frame

	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "leviathan select advances to node select")
	var current_scene: Dictionary = controller.get("current_scene")
	var expected_future_markers := maxi(0, int(current_scene.get("maxStages", 1)) - 2)
	if header != null:
		_assert_eq(header.visible, true, "node select restores the legacy shell header")
	if node_select_page != null:
		var hero_section = node_select_page.get_node_or_null("Margin/VStack/HeroSection") as Control
		var hero_title = node_select_page.get_node_or_null("Margin/VStack/HeroSection/HeroTitle") as Label
		var board_label = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/BoardLabel") as Label
		var board_title = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/LeviathanTitle") as Label
		var roadmap_frame = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame") as Control
		var roadmap_canvas = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas") as Control
		var info_card = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/InfoCard") as Control
		var info_name_label = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/InfoCard/InfoMargin/InfoVBox/InfoNameLabel") as Label
		var info_body_label = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/InfoCard/InfoMargin/InfoVBox/InfoBodyLabel") as Label
		var future_preview = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/NodeLayer/FuturePreviewHotspot") as Control
		var retired_split_shell = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/RouteSplit") as Control
		_assert_eq(node_select_page.visible, true, "node select shows the dedicated runtime page")
		_assert(hero_section != null, "node select runtime page exposes the mockup hero section")
		_assert(hero_title != null, "node select runtime page exposes the hero title")
		_assert(board_label != null, "node select runtime page exposes the selected-leviathan label")
		_assert(board_title != null, "node select runtime page exposes the board title")
		_assert(roadmap_frame != null, "node select runtime page exposes the roadmap frame")
		_assert(roadmap_canvas != null, "node select runtime page exposes the roadmap canvas")
		_assert(info_card != null, "node select runtime page exposes the left-side hover info card")
		_assert(info_name_label != null, "node select runtime page exposes the hover-card node-name label")
		_assert(info_body_label != null, "node select runtime page exposes the hover-card node-description label")
		_assert(future_preview != null, "stage-one node select exposes a separate future preview marker instead of treating it as a current route")
		_assert(retired_split_shell == null, "node select runtime page removes the retired split map/backpack shell")
		if hero_title != null:
			_assert_eq(hero_title.text, "", "stage-one node select retires the duplicate hero Leviathan title copy")
		if board_label != null:
			_assert_eq(board_label.text, "", "stage-one node select retires the selected-leviathan label copy")
		if board_title != null:
			_assert(board_title.text in leviathan_expected_names(leviathan_id), "stage-one node select board title uses the selected Leviathan name")
		if info_name_label != null:
			_assert(info_name_label.text.length() > 0, "stage-one node select shows the hover-card node-name label text")
		if info_body_label != null:
			_assert(info_body_label.text.length() > 0, "stage-one node select shows the hover-card node-description label text")
		if node_select_page.has_method("route_button_count"):
			_assert_eq(int(node_select_page.call("route_button_count")), 0, "stage-one node select keeps the opening stage fixed instead of offering five route buttons")
		_assert(node_select_page.has_method("start_marker_count"), "stage-one node select exposes start-marker counts")
		_assert(node_select_page.has_method("boss_marker_count"), "stage-one node select exposes boss-marker counts")
		_assert(node_select_page.has_method("fixed_entry_marker_count"), "stage-one node select exposes retired fixed-entry counts")
		if node_select_page.has_method("start_marker_count"):
			_assert_eq(int(node_select_page.call("start_marker_count")), 1, "stage-one node select renders exactly one start marker")
		if node_select_page.has_method("future_marker_count"):
			_assert_eq(int(node_select_page.call("future_marker_count")), expected_future_markers, "stage-one node select renders the expected future ? marker count for the selected Leviathan stage count")
		if node_select_page.has_method("boss_marker_count"):
			_assert_eq(int(node_select_page.call("boss_marker_count")), 1, "stage-one node select renders exactly one boss marker")
		if node_select_page.has_method("fixed_entry_marker_count"):
			_assert_eq(int(node_select_page.call("fixed_entry_marker_count")), 0, "stage-one node select removes the retired fixed-entry marker from the board")
	_assert_eq(str(current_scene.get("phase", "")), "node_select", "expedition enters node_select after meta flow")
	return controller

func leviathan_expected_names(leviathan_id: String) -> Array[String]:
	var fallback := leviathan_id
	var localized_fallback := ""
	match leviathan_id:
		"ossuary_tortoise":
			fallback = "Ossuary Tortoise"
			localized_fallback = "유해갑 거북"
		"storm_wyvern":
			fallback = "Storm Wyvern"
			localized_fallback = "폭풍 와이번"
		"sky_mireu":
			fallback = "Sky Mireu"
			localized_fallback = "창공 미르"
	var names: Array[String] = [fallback]
	var localized := TextCatalogScript.display_name(fallback)
	if localized != fallback:
		names.append(localized)
	if not localized_fallback.is_empty() and not (localized_fallback in names):
		names.append(localized_fallback)
	return names

func _assert_meta_to_combat_to_reward_to_node_flow(MainScene: PackedScene) -> void:
	var main_instance = MainScene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "character_select", "main scene starts on character select page")

	var controller = await _boot_to_node_select(main_instance)
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return

	var page_scenes: Dictionary = main_instance.get("page_scenes")
	var node_select_page = page_scenes.get("node_select", null)
	_assert(node_select_page != null, "node select page exists after meta flow")
	if node_select_page != null and node_select_page.has_method("route_button_count") and node_select_page.has_method("press_route_button"):
		if int(node_select_page.call("route_button_count")) > 0:
			node_select_page.call("press_route_button", 0)
	else:
		_assert(false, "node select page exposes route-button helpers for runtime flow automation")
	await process_frame
	var start_button = main_instance.get("start_button")
	_assert(start_button != null, "start button exists on node select")
	if start_button != null:
		start_button.pressed.emit()
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "battle", "starting a normal route enters battle page")

	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "reward", "clearing a normal route enters reward page")

	controller.call("_proceed_to_node_select")
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "claiming rewards returns to node select")

	main_instance.queue_free()
	await process_frame

func _assert_boss_clear_flow(MainScene: PackedScene) -> void:
	var main_instance = MainScene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	var controller = await _boot_to_node_select(main_instance, "purple", "ossuary_tortoise")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return

	var page_scenes: Dictionary = main_instance.get("page_scenes")
	var node_select_page = page_scenes.get("node_select", null)
	await process_frame
	var start_button = main_instance.get("start_button")
	_assert(start_button != null, "start button exists for boss-flow automation")
	if start_button == null:
		main_instance.queue_free()
		await process_frame
		return

	start_button.pressed.emit()
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "battle", "fixed opening stage enters a normal battle before the branch stage")

	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "reward", "clearing the fixed opening stage enters reward page")

	controller.call("_proceed_to_node_select")
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "reward claim after the fixed opening stage returns to node select")

	var stage_two_scene: Dictionary = controller.get("current_scene")
	_assert_eq(int(stage_two_scene.get("stageIndex", -1)), 1, "reward claim after the fixed opening stage advances to stage two")
	_assert_eq(stage_two_scene.get("nodeSelect", {}).get("routeHistory", []).size(), 1, "stage-two node select keeps the cleared opening lane in route history")
	if node_select_page != null:
		_assert(node_select_page.has_method("route_button_count"), "node select page exposes route-button automation for the branch stage")
		_assert(node_select_page.has_method("history_marker_count"), "node select page exposes cleared-route history marker counts for boss-flow automation")
		_assert(node_select_page.has_method("future_marker_count"), "node select page exposes future ? marker counts for boss-flow automation")
		_assert(node_select_page.has_method("current_unknown_route_count"), "node select page exposes current-route unknown-icon counts for boss-flow automation")
		if node_select_page.has_method("route_button_count"):
			_assert_eq(int(node_select_page.call("route_button_count")), 5, "stage two offers five current node choices")
		if node_select_page.has_method("history_marker_count"):
			_assert_eq(int(node_select_page.call("history_marker_count")), 1, "stage two keeps one cleared node visible in route history")
		if node_select_page.has_method("future_marker_count"):
			_assert_eq(int(node_select_page.call("future_marker_count")), 0, "stage two has no unexplored non-boss stages left for a three-stage Leviathan")
		if node_select_page.has_method("current_unknown_route_count"):
			_assert_eq(int(node_select_page.call("current_unknown_route_count")), 0, "stage two keeps the current five route candidates visually distinct from future ? markers")
		if node_select_page.has_method("press_route_button"):
			node_select_page.call("press_route_button", 1)
		else:
			_assert(false, "node select page exposes route-button helpers for branch-stage automation")
	await process_frame
	if start_button != null:
		start_button.pressed.emit()
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "battle", "branch-stage route still enters a normal battle before the boss stage")

	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "reward", "clearing the branch stage enters reward page")

	controller.call("_proceed_to_node_select")
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "reward claim after the branch stage returns to node select for the boss lock")

	var boss_scene: Dictionary = controller.get("current_scene")
	var boss_candidates: Array = boss_scene.get("nodeSelect", {}).get("candidates", [])
	_assert_eq(int(boss_scene.get("stageIndex", -1)), 2, "reward claim after the branch stage advances to the boss stage")
	_assert_eq(boss_scene.get("nodeSelect", {}).get("routeHistory", []).size(), 2, "boss-stage node select keeps both cleared nodes visible in route history")
	_assert_eq(boss_candidates.size(), 1, "boss-stage node select locks to exactly one candidate")
	if boss_candidates.size() == 1:
		_assert_eq(str(boss_candidates[0].get("nodeType", "")), "boss", "boss-stage node select exposes only a boss node")
	if node_select_page != null:
		if node_select_page.has_method("route_button_count"):
			_assert_eq(int(node_select_page.call("route_button_count")), 0, "boss-stage node select does not expose current route buttons")
		if node_select_page.has_method("history_marker_count"):
			_assert_eq(int(node_select_page.call("history_marker_count")), 2, "boss-stage node select keeps both cleared nodes rendered as history markers")
		if node_select_page.has_method("future_marker_count"):
			_assert_eq(int(node_select_page.call("future_marker_count")), 0, "boss-stage node select does not render future ? markers once the boss is current")

	start_button.pressed.emit()
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "boss_battle", "boss-stage fixed start enters boss battle page")

	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "boss_reward", "boss clear enters boss reward page")

	controller.call("_proceed_to_node_select")
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "clear", "final boss reward claim enters clear page")

	controller.call("_on_return_to_character_select_pressed")
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "character_select", "clear page returns to character select")

	main_instance.queue_free()
	await process_frame

func _assert_defeat_flow(MainScene: PackedScene) -> void:
	var main_instance = MainScene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	var controller = await _boot_to_node_select(main_instance, "green", "sky_mireu")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return

	var page_scenes: Dictionary = main_instance.get("page_scenes")
	var node_select_page = page_scenes.get("node_select", null)
	if node_select_page != null and node_select_page.has_method("route_button_count") and node_select_page.has_method("press_route_button"):
		if int(node_select_page.call("route_button_count")) > 0:
			node_select_page.call("press_route_button", 0)
	else:
		_assert(false, "node select page exposes route-button helpers for defeat-flow automation")
	await process_frame
	var start_button = main_instance.get("start_button")
	if start_button != null:
		start_button.pressed.emit()
	await process_frame
	await process_frame

	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "failed"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "defeat", "combat failure enters defeat page")
	var repair_overlay = main_instance.get("repair_overlay") as Control
	_assert(repair_overlay != null, "repair overlay exists for defeat-page flow audit")
	if repair_overlay != null:
		_assert_eq(repair_overlay.visible, false, "defeat page hides the legacy repair overlay so the dedicated outcome page owns the full screen")
	var defeat_page = page_scenes.get("defeat", null) as Control
	_assert(defeat_page != null, "defeat page scene exists for defeat-page flow audit")
	if defeat_page != null:
		_assert_eq(defeat_page.visible, true, "defeat page scene is the visible failure surface")
	var defeat_page_model: Dictionary = main_instance.call("_page_scene_model", "defeat", controller.get("current_scene"))
	var selected_leviathan: Dictionary = controller.get("current_scene").get("selectedLeviathan", {})
	_assert_eq(
		str(defeat_page_model.get("pageHeroPath", "")),
		str(selected_leviathan.get("artPath", "")),
		"defeat page model uses the selected leviathan art instead of a fixed fallback backdrop"
	)

	controller.call("_on_return_to_character_select_pressed")
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "character_select", "defeat page returns to character select")

	main_instance.queue_free()
	await process_frame
