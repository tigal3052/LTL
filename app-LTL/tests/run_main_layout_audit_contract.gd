extends SceneTree
const VIEWPORT_SIZE := Vector2i(1440, 900)
var failures: Array[String] = []
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = VIEWPORT_SIZE
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene resource loads for gameplay layout audit")
	if MainScene == null:
		_finish()
		return
	await _assert_character_select_layout(MainScene)
	await _assert_leviathan_select_layout(MainScene)
	await _assert_defeat_layout(MainScene)
	await _assert_stage_one_node_select_layout(MainScene)
	await _assert_stage_two_node_select_layout(MainScene)
	await _assert_boss_node_select_layout(MainScene)
	await _assert_combat_layout(MainScene)
	await _assert_combat_purple_status_overlay_keeps_bottom_gap(MainScene)
	await _assert_combat_overlay_pause_behavior(MainScene)
	await _assert_reward_tray_layout(MainScene)
	await _assert_reward_reveal_layout(MainScene)
	await _assert_overlay_layouts(MainScene)
	await _finish()
func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
func _assert_color_close(actual: Color, expected: Color, tolerance: float, label: String) -> void:
	var delta := absf(actual.r - expected.r) + absf(actual.g - expected.g) + absf(actual.b - expected.b) + absf(actual.a - expected.a)
	_assert(delta <= tolerance, "%s stays within color tolerance %.3f (actual=%s expected=%s delta=%.3f)" % [label, tolerance, str(actual), str(expected), delta])
func _viewport_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(root.size))
func _assert_control_inside_viewport(control: Control, label: String) -> void:
	_assert(control != null, "%s exists for viewport containment" % label)
	if control == null:
		return
	var rect := control.get_global_rect()
	var viewport := _viewport_rect()
	_assert(rect.position.x >= viewport.position.x - 0.5, "%s stays inside the viewport left edge (rect=%s viewport=%s)" % [label, str(rect), str(viewport)])
	_assert(rect.position.y >= viewport.position.y - 0.5, "%s stays inside the viewport top edge (rect=%s viewport=%s)" % [label, str(rect), str(viewport)])
	_assert(rect.end.x <= viewport.end.x + 0.5, "%s stays inside the viewport right edge (rect=%s viewport=%s)" % [label, str(rect), str(viewport)])
	_assert(rect.end.y <= viewport.end.y + 0.5, "%s stays inside the viewport bottom edge (rect=%s viewport=%s)" % [label, str(rect), str(viewport)])
func _assert_control_inside_parent(control: Control, parent: Control, label: String) -> void:
	_assert(control != null, "%s exists for parent containment" % label)
	_assert(parent != null, "%s has a parent container for containment" % label)
	if control == null or parent == null:
		return
	var rect := control.get_global_rect()
	var parent_rect := parent.get_global_rect()
	_assert(rect.position.x >= parent_rect.position.x - 0.5, "%s stays inside the parent left edge (rect=%s parent=%s)" % [label, str(rect), str(parent_rect)])
	_assert(rect.position.y >= parent_rect.position.y - 0.5, "%s stays inside the parent top edge (rect=%s parent=%s)" % [label, str(rect), str(parent_rect)])
	_assert(rect.end.x <= parent_rect.end.x + 0.5, "%s stays inside the parent right edge (rect=%s parent=%s)" % [label, str(rect), str(parent_rect)])
	_assert(rect.end.y <= parent_rect.end.y + 0.5, "%s stays inside the parent bottom edge (rect=%s parent=%s)" % [label, str(rect), str(parent_rect)])
func _assert_page_shell_host(main_instance: Node, page: Control, expected_host_property: String, label: String, require_viewport_host := false) -> void:
	_assert(page != null, "%s exists for host ownership audit" % label)
	var expected_host = main_instance.get(expected_host_property) as Control
	_assert(expected_host != null, "%s host exists for host ownership audit" % label)
	if page == null or expected_host == null:
		return
	_assert(page.get_parent() == expected_host, "%s mounts under %s instead of leaking into a different layout shell" % [label, expected_host_property])
	_assert_control_inside_parent(page, expected_host, "%s root" % label)
	if require_viewport_host:
		_assert_control_inside_viewport(expected_host, "%s host" % label)
func _assert_visible_controls_inside_viewport(main_instance: Node, label: String) -> void:
	var viewport := _viewport_rect()
	var stack: Array[Node] = [main_instance]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		for child in current.get_children():
			stack.append(child)
		var control = current as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		_assert(rect.position.x >= viewport.position.x - 0.5 and rect.position.y >= viewport.position.y - 0.5 and rect.end.x <= viewport.end.x + 0.5 and rect.end.y <= viewport.end.y + 0.5, "%s visible control stays inside viewport: %s rect=%s viewport=%s" % [label, str(control.get_path()), str(rect), str(viewport)])
func _finish() -> void:
	if failures.is_empty():
		print("MAIN_LAYOUT_AUDIT_CONTRACT_OK")
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	await process_frame
	quit(1)
func _instantiate_main(MainScene: PackedScene) -> Node:
	root.size = VIEWPORT_SIZE
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for layout audit")
	if main_instance == null:
		return null
	root.add_child(main_instance)
	await process_frame
	await process_frame
	await process_frame
	return main_instance
func _boot_to_node_select(main_instance: Node, color := "red", leviathan_id := "filed_lizard") -> Node:
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists during layout-flow boot")
	if controller == null:
		return null
	var character_page = main_instance.get("character_select_page")
	_assert(character_page != null, "character select page exists during layout-flow boot")
	if character_page != null:
		character_page.color_selected.emit(color)
		character_page.continue_requested.emit()
	await process_frame
	await process_frame
	await _advance_story_if_present(main_instance, "leviathan_select")
	var leviathan_page = main_instance.get("leviathan_select_page")
	_assert(leviathan_page != null, "leviathan select page exists during layout-flow boot")
	if leviathan_page != null:
		leviathan_page.leviathan_selected.emit(leviathan_id)
		leviathan_page.start_requested.emit()
	await process_frame
	await process_frame
	await process_frame
	return controller
func _advance_story_if_present(main_instance: Node, return_page_id: String) -> void:
	if str(main_instance.get("active_page_id")) != "story_scene":
		return
	var story_page = main_instance.get("story_scene_page")
	var controller = main_instance.get_node_or_null("MainController")
	_assert(story_page != null, "story scene page exists during layout-flow handoff")
	_assert(controller != null, "main controller exists during layout-flow story handoff")
	if story_page == null or controller == null:
		return
	var story: Dictionary = controller.get("active_story_scene")
	var scene_id := str(story.get("id", ""))
	_assert(scene_id != "", "story scene exposes an active scene id during layout-flow handoff")
	story_page.continue_requested.emit(scene_id)
	await process_frame
	story_page.continue_requested.emit(scene_id)
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), return_page_id, "story scene returns to %s during layout audit" % return_page_id)
func _node_select_page(main_instance: Node) -> Node:
	var page_scenes: Dictionary = main_instance.get("page_scenes")
	return page_scenes.get("node_select", null)
func _press_route_button(main_instance: Node, index: int, label: String) -> void:
	var controller = main_instance.get_node_or_null("MainController")
	var node_select_page = _node_select_page(main_instance)
	_assert(node_select_page != null, "node select page exists for %s" % label)
	if node_select_page == null:
		return
	var route_count := int(node_select_page.call("route_button_count")) if node_select_page.has_method("route_button_count") else 0
	if route_count > 0:
		_assert(node_select_page.has_method("press_route_button"), "node select page exposes route-button automation for %s" % label)
		if node_select_page.has_method("press_route_button"):
			node_select_page.call("press_route_button", clampi(index, 0, route_count - 1))
		return
	var current_scene: Dictionary = controller.get("current_scene") if controller != null else {}
	if bool(current_scene.get("nodeSelect", {}).get("isBossStage", false)):
		_assert(node_select_page.has_method("press_boss_marker"), "node select page exposes boss marker automation for %s" % label)
		if node_select_page.has_method("press_boss_marker"):
			node_select_page.call("press_boss_marker")
		return
	_assert(node_select_page.has_method("press_start_marker"), "node select page exposes fixed-start marker automation for %s" % label)
	if node_select_page.has_method("press_start_marker"):
		node_select_page.call("press_start_marker")
func _assert_character_select_layout(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	_assert_eq(str(main_instance.get("active_page_id")), "character_select", "main scene starts on character select for layout audit")
	var character_page = main_instance.get("character_select_page") as Control
	_assert(character_page != null, "character select page exists for layout audit")
	if character_page == null:
		main_instance.queue_free()
		await process_frame
		return
	var meta_page_host = main_instance.get("meta_page_shell_host") as Control
	var gameplay_page_host = main_instance.get("page_shell_host") as Control
	_assert_page_shell_host(main_instance, character_page, "meta_page_shell_host", "character select page", true)
	_assert(meta_page_host != null and bool(meta_page_host.visible), "character select uses the dedicated viewport-sized meta page host")
	_assert(gameplay_page_host == null or not bool(gameplay_page_host.visible), "character select keeps the gameplay page host hidden")
	var page_stack = character_page.get_node_or_null("Margin/VStack") as Control
	var board_shell = character_page.get_node_or_null("Margin/VStack/BoardShell") as Control
	var roster_scroll = character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/SelectorZone/ZoneMargin/ZoneVBox/RosterScroll") as Control
	var hero_stage = character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FeatureZone/ZoneMargin/ZoneVBox/HeroColumn/HeroStage") as Control
	var continue_button = character_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/PrepZone/ZoneMargin/ZoneVBox/PrepColumn/CtaCard/CtaMargin/CtaVBox/ContinueButton") as Control
	_assert_control_inside_parent(page_stack, character_page, "character select stack")
	_assert_control_inside_parent(board_shell, character_page, "character select board shell")
	_assert_control_inside_viewport(page_stack, "character select stack")
	_assert_control_inside_viewport(board_shell, "character select board shell")
	_assert_control_inside_viewport(roster_scroll, "character select roster scroll host")
	_assert_control_inside_viewport(hero_stage, "character select hero stage")
	_assert_control_inside_viewport(continue_button, "character select continue button")
	main_instance.queue_free()
	await process_frame
func _assert_leviathan_select_layout(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var character_page = main_instance.get("character_select_page")
	_assert(character_page != null, "character select page exists before leviathan layout audit")
	if character_page != null:
		character_page.color_selected.emit("blue")
		character_page.continue_requested.emit()
	await process_frame
	await process_frame
	await _advance_story_if_present(main_instance, "leviathan_select")
	_assert_eq(str(main_instance.get("active_page_id")), "leviathan_select", "character select advances to leviathan select for layout audit")
	var leviathan_page = main_instance.get("leviathan_select_page") as Control
	_assert(leviathan_page != null, "leviathan select page exists for layout audit")
	if leviathan_page == null:
		main_instance.queue_free()
		await process_frame
		return
	var meta_page_host = main_instance.get("meta_page_shell_host") as Control
	var gameplay_page_host = main_instance.get("page_shell_host") as Control
	_assert_page_shell_host(main_instance, leviathan_page, "meta_page_shell_host", "leviathan select page", true)
	_assert(meta_page_host != null and bool(meta_page_host.visible), "leviathan select keeps the dedicated meta page host visible")
	_assert(gameplay_page_host == null or not bool(gameplay_page_host.visible), "leviathan select keeps the gameplay page host hidden")
	var layout = leviathan_page.get_node_or_null("Margin/Layout") as Control
	var board_panel = leviathan_page.get_node_or_null("Margin/Layout/BoardPanel") as Control
	var target_ribbon = leviathan_page.get_node_or_null("Margin/Layout/BoardPanel/TargetRibbon") as Control
	var start_frame = leviathan_page.get_node_or_null("Margin/Layout/BoardPanel/StartButtonFrame") as Control
	var start_button = leviathan_page.get_node_or_null("Margin/Layout/BoardPanel/StartButtonFrame/StartButton") as Control
	_assert_control_inside_parent(layout, leviathan_page, "leviathan select layout")
	_assert_control_inside_parent(board_panel, leviathan_page, "leviathan select board panel")
	_assert_control_inside_viewport(layout, "leviathan select layout")
	_assert_control_inside_viewport(board_panel, "leviathan select board panel")
	_assert_control_inside_viewport(target_ribbon, "leviathan select target ribbon")
	_assert_control_inside_viewport(start_frame, "leviathan select start frame")
	_assert_control_inside_viewport(start_button, "leviathan select looting-start button")
	if target_ribbon != null and board_panel != null:
		_assert(absf(target_ribbon.get_global_rect().position.x - board_panel.get_global_rect().position.x) <= 1.0, "leviathan select target ribbon starts flush with the board panel left edge")
		_assert(absf(target_ribbon.get_global_rect().end.x - board_panel.get_global_rect().end.x) <= 1.0, "leviathan select target ribbon ends flush with the board panel right edge")
		_assert(target_ribbon.get_global_rect().size.y <= 96.0, "leviathan select target ribbon stays a shallow bottom banner instead of expanding to board height")
		_assert(target_ribbon.get_global_rect().position.y >= board_panel.get_global_rect().end.y - 220.0, "leviathan select target ribbon stays in the lower board band")
	if start_frame != null and board_panel != null:
		_assert(start_frame.get_global_rect().size.y <= 86.0, "leviathan select start frame keeps a tighter responsive CTA lane instead of expanding to board height")
		_assert(start_frame.get_global_rect().position.y >= board_panel.get_global_rect().end.y - 128.0, "leviathan select start frame stays pinned to the lower board edge")
	if start_button != null:
		var button_height := start_button.get_global_rect().size.y
		_assert(button_height >= 66.0 and button_height <= 74.0, "leviathan select CTA button resolves near the intended 70px baseline at the canonical viewport (height=%.2f)" % button_height)
	main_instance.queue_free()
	await process_frame
func _assert_defeat_layout(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists for defeat-page layout audit")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return
	var character_page = main_instance.get("character_select_page")
	if character_page != null:
		character_page.color_selected.emit("green")
		character_page.continue_requested.emit()
	await process_frame
	await _advance_story_if_present(main_instance, "leviathan_select")
	await process_frame
	var leviathan_page = main_instance.get("leviathan_select_page")
	if leviathan_page != null:
		leviathan_page.leviathan_selected.emit("filed_lizard")
		leviathan_page.start_requested.emit()
	await process_frame
	await process_frame
	await process_frame
	_press_route_button(main_instance, 0, "defeat-page layout audit")
	await process_frame
	var start_button = main_instance.get("start_button") as Button
	_assert(start_button != null, "start button exists for defeat-page layout audit")
	if start_button != null:
		start_button.pressed.emit()
	await process_frame
	await process_frame
	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "failed"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "defeat", "layout audit reaches the defeat page")
	var page_scenes: Dictionary = main_instance.get("page_scenes")
	var defeat_page = page_scenes.get("defeat", null) as Control
	_assert(defeat_page != null, "defeat page exists for layout audit")
	if defeat_page != null:
		_assert_page_shell_host(main_instance, defeat_page, "meta_page_shell_host", "defeat page", true)
		_assert_control_inside_viewport(defeat_page, "defeat page root")
		_assert_visible_controls_inside_viewport(defeat_page, "defeat page")
	var repair_overlay = main_instance.get("repair_overlay") as Control
	_assert(repair_overlay != null, "repair overlay exists for defeat-page layout audit")
	if repair_overlay != null:
		_assert_eq(repair_overlay.visible, false, "defeat page keeps the legacy repair overlay hidden during full-page layout")
	main_instance.queue_free()
	await process_frame
func _assert_combat_layout(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var controller = await _boot_to_node_select(main_instance, "red", "ossuary_tortoise")
	_assert(controller != null, "main controller exists for combat layout audit")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return
	var start_button = main_instance.get("start_button") as Button
	_assert(start_button != null, "start button exists for combat layout audit")
	if start_button == null:
		main_instance.queue_free()
		await process_frame
		return
	_press_route_button(main_instance, 0, "combat layout audit")
	await process_frame
	await process_frame
	start_button.pressed.emit()
	await process_frame
	await process_frame
	var top_content = main_instance.get("top_content") as HBoxContainer
	var left_column = main_instance.get("left_column") as Control
	var backpack_container = main_instance.get("backpack_container") as Control
	var backpack_host = main_instance.get("backpack_host") as Control
	var right_sidebar = main_instance.get("right_sidebar") as Control
	var active_phase_container = main_instance.get("active_phase_container") as Control
	var action_bar = main_instance.get("action_bar") as Control
	var battlefield_panel = main_instance.call("current_surface_node", "BattlefieldPanel") as Control
	var visual_queue_box = main_instance.call("current_surface_node", "TopContent/LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/QueueRow/QueueStack/QueueShell/QueueMargin/VisualQueueBox") as GridContainer
	var queue_hint_label = main_instance.find_child("QueueHintLabel", true, false) as Label
	var explorer_tab_button = main_instance.call("current_surface_node", "TopContent/RightSidebar/Margin/SidebarBox/TabRow/ExplorerTabButton") as Button
	var log_tab_button = main_instance.call("current_surface_node", "TopContent/RightSidebar/Margin/SidebarBox/TabRow/LogInfoTabButton") as Button
	var explorer_content = main_instance.call("current_surface_node", "TopContent/RightSidebar/Margin/SidebarBox/TabViewport/ExplorerContent") as Control
	var log_content = main_instance.call("current_surface_node", "TopContent/RightSidebar/Margin/SidebarBox/TabViewport/LogContent") as Control
	var info_toggle_button = main_instance.call("current_surface_node", "TopContent/LeftColumn/StatusPanel/Margin/StatusBox/InfoShell/InfoMargin/InfoBox/InfoTitle") as Button
	var info_detail_shell = main_instance.call("current_surface_node", "TopContent/LeftColumn/StatusPanel/Margin/StatusBox/InfoShell/InfoMargin/InfoBox/InfoDetailShell") as Control
	var ops_shell = main_instance.call("current_surface_node", "TopContent/LeftColumn/StatusPanel/Margin/StatusBox/OpsShell") as Control
	var status_title = main_instance.call("current_surface_node", "TopContent/LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/StatusTitle") as Label
	var terrain_copy = main_instance.call("current_surface_node", "TopContent/LeftColumn/StatusPanel/Margin/StatusBox/InfoShell/InfoMargin/InfoBox/TerrainCopy") as Label
	var weakness_card_grid = main_instance.call("current_surface_node", "TopContent/LeftColumn/StatusPanel/Margin/StatusBox/InfoShell/InfoMargin/InfoBox/WeaknessCardGrid") as GridContainer
	var node_card = main_instance.call("current_surface_node", "TopContent/LeftColumn/StatusPanel/Margin/StatusBox/InfoShell/InfoMargin/InfoBox/NodeCard") as Control
	var old_ops_node_card = main_instance.call("current_surface_node", "TopContent/LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/NodeCard") as Control
	_assert(top_content != null, "top-content row exists for combat layout audit")
	_assert(left_column != null, "left sidebar exists for combat layout audit")
	_assert(backpack_container != null, "combat backpack exists for combat layout audit")
	_assert(backpack_host != null, "combat backpack host exists for combat layout audit")
	_assert(right_sidebar != null, "right sidebar exists for combat layout audit")
	_assert(active_phase_container != null, "combat active phase container exists for right-tab stability audit")
	_assert(action_bar != null, "combat action bar exists for right-tab stability audit")
	_assert(battlefield_panel != null, "combat battlefield tile strip exists for floor adjacency audit")
	_assert(visual_queue_box != null, "combat status panel exposes the two-row FIFO energy queue grid")
	var backpack_slot: Control = backpack_host if backpack_host != null else backpack_container
	if top_content != null and left_column != null and backpack_slot != null and backpack_container != null and right_sidebar != null:
		_assert(bool(top_content.visible), "combat keeps the top-content row visible")
		_assert(float(top_content.size.y) >= 510.0, "combat top row consumes the remaining vertical budget so the lower HUD band can sit on the floor (height=%.2f)" % top_content.size.y)
		_assert(absf(float(left_column.size.y) - float(top_content.size.y)) <= 0.5, "combat left status panel matches the top-row height (left=%.2f top=%.2f)" % [left_column.size.y, top_content.size.y])
		_assert(absf(float(backpack_slot.size.y) - float(top_content.size.y)) <= 0.5, "combat backpack host matches the top-row height (backpack=%.2f top=%.2f)" % [backpack_slot.size.y, top_content.size.y])
		_assert(backpack_container.get_parent() == backpack_slot, "combat shared backpack instance lives under the top-content backpack host")
		_assert(absf(float(right_sidebar.size.y) - float(top_content.size.y)) <= 0.5, "combat right panel matches the top-row height (right=%.2f top=%.2f)" % [right_sidebar.size.y, top_content.size.y])
		_assert(float(left_column.position.x) >= -0.5, "combat left column stays inside the top-content row")
		_assert(float(left_column.position.x + left_column.size.x) <= float(backpack_slot.position.x) + 1.0, "combat left column stays left of the backpack slot")
		_assert(float(backpack_slot.position.x + backpack_slot.size.x) <= float(right_sidebar.position.x) + 1.0, "combat backpack stays left of the log sidebar")
		_assert(float(right_sidebar.position.x + right_sidebar.size.x) <= float(top_content.size.x) + 1.0, "combat right sidebar stays inside the top-content row")
		var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
		if MainViewRuntimeScript != null:
			var expected_backpack_width := float(MainViewRuntimeScript.top_content_backpack_width_for_height(backpack_slot.size.y))
			_assert(absf(float(backpack_slot.size.x) - expected_backpack_width) <= 8.0, "combat backpack keeps the priority height-derived width instead of being clamped first (actual=%.2f expected=%.2f)" % [backpack_slot.size.x, expected_backpack_width])
		_assert(float(backpack_slot.size.x) >= 590.0, "combat backpack expands to the largest floor-aligned 8x8 ratio panel at the canonical viewport (width=%.2f)" % backpack_slot.size.x)
		_assert(float(left_column.size.x) >= 440.0 and float(left_column.size.x) <= 460.0, "combat left status column stays at the readable minimum before trimming the right rail (width=%.2f)" % left_column.size.x)
		_assert(float(right_sidebar.size.x) >= 300.0 and float(right_sidebar.size.x) <= 330.0, "combat right sidebar absorbs the remaining side budget while keeping tab controls usable (width=%.2f)" % right_sidebar.size.x)
	if visual_queue_box != null:
		_assert_eq(int(visual_queue_box.columns), 8, "combat energy queue keeps eight columns per row for the two-row FIFO layout")
	_assert(queue_hint_label != null, "combat status panel exposes a queue hint label under the queue hub")
	_assert(info_toggle_button != null, "combat info title is a button so the multiplier details can be toggled in place")
	_assert(info_detail_shell != null, "combat info panel exposes a compact dropdown detail shell")
	_assert(info_detail_shell != null and not info_detail_shell.visible, "combat info dropdown starts collapsed so the compact readout keeps its current density")
	_assert(info_toggle_button != null and info_toggle_button.text.begins_with("노드 정보"), "combat info toggle is renamed to node info")
	_assert(status_title != null and status_title.text == "드릴 정보", "drill operations shell title is renamed to drill info")
	_assert(terrain_copy != null and terrain_copy.visible and not terrain_copy.text.is_empty(), "collapsed node info keeps only the weakness terrain text visible")
	_assert(weakness_card_grid != null and not weakness_card_grid.visible, "collapsed node info hides multiplier cards")
	_assert(node_card != null, "runtime node status card is mounted in the node info area")
	_assert(node_card != null and not node_card.visible, "runtime node status card stays hidden while node info is collapsed")
	_assert(old_ops_node_card == null, "runtime drill info area no longer owns node status")
	_assert(explorer_tab_button != null, "combat right sidebar keeps the explorer tab button mounted")
	_assert(log_tab_button != null, "combat right sidebar keeps the log tab button mounted")
	_assert(explorer_content != null and explorer_content.visible, "combat defaults the right sidebar to explorer status")
	_assert(log_content != null and not log_content.visible, "combat keeps the log body hidden until the tab is pressed")
	if active_phase_container != null and action_bar != null:
		_assert(absf(float(action_bar.get_global_rect().end.y) - float(active_phase_container.get_global_rect().end.y)) <= 1.0, "combat action bar sits on the active phase floor instead of leaving a large bottom gap (action=%.2f active=%.2f)" % [action_bar.get_global_rect().end.y, active_phase_container.get_global_rect().end.y])
		_assert(float(action_bar.size.y) <= 64.0, "combat action bar remains button-height instead of becoming a spacer (height=%.2f)" % action_bar.size.y)
	if battlefield_panel != null and action_bar != null:
		var battle_page = action_bar.get_parent() as VBoxContainer
		var page_gap := float(battle_page.get_theme_constant("separation")) if battle_page != null else 0.0
		var expected_action_y := float(battlefield_panel.get_global_rect().end.y) + page_gap
		_assert(absf(expected_action_y - float(action_bar.global_position.y)) <= 1.0, "combat battlefield tile strip stays directly above the action bar (expected_y=%.2f action_y=%.2f)" % [expected_action_y, action_bar.global_position.y])
	if top_content != null and active_phase_container != null and action_bar != null and log_tab_button != null and explorer_content != null and log_content != null:
		var base_top_height := float(top_content.size.y)
		var base_active_phase_y := float(active_phase_container.global_position.y)
		var base_action_bar_y := float(action_bar.global_position.y)
		log_tab_button.pressed.emit()
		await process_frame
		await process_frame
		_assert(log_content.visible, "log tab reveals the right-sidebar system log body in place")
		_assert(not explorer_content.visible, "log tab hides the explorer-status body instead of stacking another layout row")
		_assert(absf(float(top_content.size.y) - base_top_height) <= 0.5, "switching the right sidebar tab keeps the top-content row height stable")
		_assert(absf(float(active_phase_container.global_position.y) - base_active_phase_y) <= 0.5, "switching the right sidebar tab keeps the battlefield row anchored")
		_assert(absf(float(action_bar.global_position.y) - base_action_bar_y) <= 0.5, "switching the right sidebar tab keeps the action bar floor anchored")
		explorer_tab_button.pressed.emit()
		await process_frame
		await process_frame
		_assert(explorer_content.visible, "explorer tab restores the default right-sidebar body")
		_assert(not log_content.visible, "explorer tab hides the log body again without changing layout ownership")
	if top_content != null and active_phase_container != null and action_bar != null and info_toggle_button != null and info_detail_shell != null:
		var base_toggle_top_height := float(top_content.size.y)
		var base_toggle_action_bar_y := float(action_bar.global_position.y)
		var base_toggle_action_bar_floor := float(action_bar.get_global_rect().end.y)
		info_toggle_button.pressed.emit()
		await process_frame
		await process_frame
		_assert(info_detail_shell.visible, "pressing the combat multiplier title opens the compact detail dropdown")
		_assert(weakness_card_grid != null and weakness_card_grid.visible, "expanded node info reveals the multiplier cards")
		_assert(node_card != null and node_card.visible, "expanded node info reveals the moved node status card")
		_assert(ops_shell != null and not ops_shell.visible, "expanded node info covers the drill info area instead of stacking above it")
		_assert(absf(float(top_content.size.y) - base_toggle_top_height) <= 0.5, "opening the combat info dropdown keeps the equal-height top row stable")
		_assert(absf(float(action_bar.global_position.y) - base_toggle_action_bar_y) <= 0.5, "opening the combat info dropdown keeps the action bar anchored")
		_assert(absf(float(action_bar.get_global_rect().end.y) - base_toggle_action_bar_floor) <= 0.5, "opening the combat info dropdown keeps the action bar floor fixed")
		info_toggle_button.pressed.emit()
		await process_frame
		await process_frame
		_assert(not info_detail_shell.visible, "pressing the combat multiplier title again collapses the detail dropdown")
		_assert(weakness_card_grid != null and not weakness_card_grid.visible, "collapsing node info hides multiplier cards again")
		_assert(ops_shell != null and ops_shell.visible, "collapsing node info restores the drill info area")
	_assert_visible_controls_inside_viewport(main_instance, "combat")
	main_instance.queue_free()
	await process_frame
func _assert_combat_purple_status_overlay_keeps_bottom_gap(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var controller = await _boot_to_node_select(main_instance, "red", "ossuary_tortoise")
	var start_button = main_instance.get("start_button") as Button
	_assert(controller != null, "main controller exists for combat purple-status layout audit")
	_assert(start_button != null, "start button exists for combat purple-status layout audit")
	if controller == null or start_button == null:
		main_instance.queue_free()
		await process_frame
		return
	_press_route_button(main_instance, 0, "combat purple-status layout audit")
	await process_frame
	await process_frame
	start_button.pressed.emit()
	await process_frame
	await process_frame
	var top_content = main_instance.get("top_content") as HBoxContainer
	var active_phase_container = main_instance.get("active_phase_container") as Control
	var action_bar = main_instance.get("action_bar") as Control
	var purple_row = main_instance.call("current_surface_node", "TopContent/LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/StatusFooterSpacer/PurpleStatusRow") as HBoxContainer
	_assert(top_content != null, "combat top-content row exists for purple-status layout audit")
	_assert(active_phase_container != null, "combat active phase container exists for purple-status layout audit")
	_assert(action_bar != null, "combat action bar exists for purple-status layout audit")
	_assert(purple_row != null, "combat status panel keeps the purple status row in the footer spacer lane")
	if top_content == null or active_phase_container == null or action_bar == null or purple_row == null:
		main_instance.queue_free()
		await process_frame
		return
	var base_top_height := float(top_content.size.y)
	var base_active_phase_y := float(active_phase_container.global_position.y)
	var base_action_bar_y := float(action_bar.global_position.y)
	var purple_scene: Dictionary = controller.get("current_scene").duplicate(true)
	var hud: Dictionary = purple_scene.get("hud", {}).duplicate(true)
	hud["purplePressure"] = {"stackCount": 0, "buffCount": 2, "active": true}
	purple_scene["hud"] = hud
	controller.call("_render_scene", purple_scene)
	await process_frame
	await process_frame
	_assert(bool(purple_row.visible), "combat purple-status layout audit triggers the purple status row")
	_assert(absf(float(top_content.size.y) - base_top_height) <= 0.5, "purple status overlay keeps the top-content row height stable instead of pushing the bottom panel down (before=%.2f after=%.2f)" % [base_top_height, top_content.size.y])
	_assert(absf(float(active_phase_container.global_position.y) - base_active_phase_y) <= 0.5, "purple status overlay keeps the active phase container anchored instead of lowering the battlefield (before=%.2f after=%.2f)" % [base_active_phase_y, active_phase_container.global_position.y])
	_assert(absf(float(action_bar.global_position.y) - base_action_bar_y) <= 0.5, "purple status overlay keeps the action bar floor position stable after the first purple-state update (before=%.2f after=%.2f)" % [base_action_bar_y, action_bar.global_position.y])
	main_instance.queue_free()
	await process_frame
func _assert_combat_overlay_pause_behavior(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var controller = await _boot_to_node_select(main_instance, "red", "ossuary_tortoise")
	var start_button = main_instance.get("start_button") as Button
	_assert(controller != null, "main controller exists for combat overlay pause audit")
	_assert(start_button != null, "start button exists for combat overlay pause audit")
	_assert(controller != null and controller.has_method("is_battle_pause_active"), "main controller exposes battle-only overlay pause query for combat overlay audit")
	if controller == null or start_button == null:
		main_instance.queue_free()
		await process_frame
		return
	if not controller.has_method("is_battle_pause_active"):
		main_instance.queue_free()
		await process_frame
		return
	_press_route_button(main_instance, 0, "combat overlay pause audit")
	await process_frame
	await process_frame
	start_button.pressed.emit()
	await process_frame
	await process_frame
	main_instance.call("set_settings_visible", true)
	await process_frame
	_assert(bool(controller.call("is_battle_pause_active")), "opening settings during combat enables battle-only overlay pause")
	main_instance.call("set_settings_visible", false)
	await process_frame
	_assert(not bool(controller.call("is_battle_pause_active")), "closing settings during combat resumes battle-only overlay pause")
	controller.call("_on_codex_open_pressed")
	await process_frame
	_assert(bool(main_instance.call("is_artifact_codex_visible")), "combat overlay pause audit opens the artifact codex")
	_assert(bool(controller.call("is_battle_pause_active")), "opening the codex during combat enables battle-only overlay pause")
	controller.call("_render_scene", controller.get("current_scene"))
	await process_frame
	_assert(bool(main_instance.call("is_artifact_codex_visible")), "combat rerenders keep the artifact codex open instead of force-closing it")
	main_instance.call("set_artifact_codex_visible", false)
	await process_frame
	_assert(not bool(controller.call("is_battle_pause_active")), "closing the codex during combat resumes battle-only overlay pause")
	main_instance.queue_free()
	await process_frame
func _assert_stage_one_node_select_layout(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var controller = await _boot_to_node_select(main_instance)
	_assert(controller != null, "main controller exists for stage-one node-select layout audit")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return
	var gameplay_page_host = main_instance.get("page_shell_host") as Control
	var meta_page_host = main_instance.get("meta_page_shell_host") as Control
	var start_button = main_instance.get("start_button") as Button
	_assert(start_button != null, "stage-one node-select exposes the shared start button")
	_assert(gameplay_page_host != null and bool(gameplay_page_host.visible), "stage-one node select keeps the gameplay page host visible")
	_assert(meta_page_host == null or not bool(meta_page_host.visible), "stage-one node select keeps the meta page host hidden")
	if start_button != null:
		var disabled_style := start_button.get_theme_stylebox("disabled") as StyleBoxFlat
		_assert(disabled_style != null, "stage-one node-select start button defines a disabled style override to avoid default blur/fade")
		var disabled_font: Color = start_button.get_theme_color("font_disabled_color")
		var normal_font: Color = start_button.get_theme_color("font_color")
		var disabled_delta := absf(disabled_font.r - normal_font.r) + absf(disabled_font.g - normal_font.g) + absf(disabled_font.b - normal_font.b) + absf(disabled_font.a - normal_font.a)
		_assert(disabled_font.a <= 0.90, "stage-one node-select start button uses visibly muted disabled text opacity")
		_assert(disabled_delta >= 0.75, "stage-one node-select start button disabled text clearly differs from the live CTA")
	_assert_header_actions_inside_window(main_instance, "stage-one node-select")
	_assert_node_select_layout_inside_window(main_instance, "stage-one node-select", false, 0, true, 0)
	_assert_visible_controls_inside_viewport(main_instance, "stage-one node-select")
	main_instance.queue_free()
	await process_frame
func _assert_stage_two_node_select_layout(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var controller = await _boot_to_node_select(main_instance, "red", "ossuary_tortoise")
	_assert(controller != null, "main controller exists for stage-two node-select layout audit")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return
	var initial_page_scenes: Dictionary = main_instance.get("page_scenes")
	var stage_one_page = initial_page_scenes.get("node_select", null) as Control
	_assert(stage_one_page != null, "stage-one node-select page exists before the stage-two reentry audit")
	var stage_one_page_id := stage_one_page.get_instance_id() if stage_one_page != null else 0
	var start_button = main_instance.get("start_button") as Button
	_assert(start_button != null, "start button exists for stage-two node-select layout audit")
	if start_button == null:
		main_instance.queue_free()
		await process_frame
		return
	_press_route_button(main_instance, 0, "stage-two opening layout audit")
	await process_frame
	start_button.pressed.emit()
	await process_frame
	await process_frame
	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await process_frame
	await process_frame
	controller.call("_proceed_to_node_select")
	await process_frame
	await process_frame
	await process_frame
	var page_scenes: Dictionary = main_instance.get("page_scenes")
	var node_select_page = page_scenes.get("node_select", null) as Control
	_assert(node_select_page != null, "stage-two node-select page still exists after the reward reentry")
	if node_select_page != null and stage_one_page != null:
		_assert_eq(
			int(node_select_page.get_instance_id()),
			int(stage_one_page_id),
			"stage-two node-select reuses the same node-select page instance instead of swapping to a different screen"
		)
	var gameplay_page_host = main_instance.get("page_shell_host") as Control
	var meta_page_host = main_instance.get("meta_page_shell_host") as Control
	_assert_page_shell_host(main_instance, node_select_page, "page_shell_host", "node select page")
	_assert(gameplay_page_host != null and bool(gameplay_page_host.visible), "node select keeps the gameplay page host visible")
	_assert(meta_page_host == null or not bool(meta_page_host.visible), "node select keeps the meta page host hidden")
	_assert_header_actions_inside_window(main_instance, "stage-two node-select")
	_assert_node_select_layout_inside_window(main_instance, "stage-two node-select", false, 5, false, 1)
	_assert_visible_controls_inside_viewport(main_instance, "stage-two node-select")
	main_instance.queue_free()
	await process_frame
func _assert_boss_node_select_layout(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var controller = await _boot_to_node_select(main_instance, "purple", "ossuary_tortoise")
	_assert(controller != null, "main controller exists for boss node-select layout audit")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return
	var initial_page_scenes: Dictionary = main_instance.get("page_scenes")
	var stage_one_page = initial_page_scenes.get("node_select", null) as Control
	_assert(stage_one_page != null, "stage-one node-select page exists before the boss-lock reentry audit")
	var stage_one_page_id := stage_one_page.get_instance_id() if stage_one_page != null else 0
	var start_button = main_instance.get("start_button") as Button
	_assert(start_button != null, "start button exists for boss node-select layout audit")
	if start_button == null:
		main_instance.queue_free()
		await process_frame
		return
	_press_route_button(main_instance, 0, "boss opening layout audit")
	await process_frame
	start_button.pressed.emit()
	await process_frame
	await process_frame
	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await process_frame
	await process_frame
	controller.call("_proceed_to_node_select")
	await process_frame
	await process_frame
	_press_route_button(main_instance, 1, "boss node-select layout audit")
	await process_frame
	await process_frame
	start_button.pressed.emit()
	await process_frame
	await process_frame
	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await process_frame
	await process_frame
	controller.call("_proceed_to_node_select")
	await process_frame
	await process_frame
	await process_frame
	var page_scenes: Dictionary = main_instance.get("page_scenes")
	var node_select_page = page_scenes.get("node_select", null) as Control
	_assert(node_select_page != null, "boss-lock node-select page still exists after the branch-stage reentry")
	if node_select_page != null and stage_one_page != null:
		_assert_eq(
			int(node_select_page.get_instance_id()),
			int(stage_one_page_id),
			"boss-lock node-select reuses the same node-select page instance instead of swapping to a different screen"
		)
	var gameplay_page_host = main_instance.get("page_shell_host") as Control
	var meta_page_host = main_instance.get("meta_page_shell_host") as Control
	_assert_page_shell_host(main_instance, node_select_page, "page_shell_host", "boss node select page")
	_assert(gameplay_page_host != null and bool(gameplay_page_host.visible), "boss node select keeps the gameplay page host visible")
	_assert(meta_page_host == null or not bool(meta_page_host.visible), "boss node select keeps the meta page host hidden")
	_assert_header_actions_inside_window(main_instance, "boss node-select")
	_assert_node_select_layout_inside_window(main_instance, "boss node-select", false, 0, false, 2)
	_assert_visible_controls_inside_viewport(main_instance, "boss node-select")
	main_instance.queue_free()
	await process_frame
func _assert_reward_tray_layout(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var controller = await _boot_to_node_select(main_instance)
	_assert(controller != null, "main controller exists for reward tray layout audit")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return
	var rewards := [
		{"kind": "Vermilion Venting Beacon", "rarity": "rare", "qty": 1, "presentation": {"badge": "rare red beacon"}, "payload": {"item_type": "beacon", "energy_type": "red"}},
		{"kind": "Tremor Heat Post", "rarity": "common", "qty": 1, "presentation": {"badge": "common red beacon"}, "payload": {"item_type": "beacon", "energy_type": "red"}},
		{"kind": "Relic Spur", "rarity": "common", "qty": 1, "presentation": {"badge": "common relic"}, "payload": {"item_type": "relic", "energy_type": ""}},
		{"kind": "Purple Starter Drill", "rarity": "rare", "qty": 1, "presentation": {"badge": "rare purple drill"}, "payload": {"item_type": "drill", "energy_type": "purple"}},
		{"kind": "Blue Starter Beacon", "rarity": "common", "qty": 1, "presentation": {"badge": "common blue beacon"}, "payload": {"item_type": "beacon", "energy_type": "blue"}}
	]
	controller.call("_render_scene", {
		"phase": "reward_loot",
		"pageId": "reward",
		"rewardPresentationStep": "tray_review",
		"reward": {"pendingRewards": rewards},
		"terrain": {"rows": 0, "columns": 0, "cells": []},
		"hud": {},
		"targetPanel": {},
		"stageIndex": 1,
		"maxStages": 5
	})
	await process_frame
	await process_frame
	var reward_panel = main_instance.call("current_surface_node", "RewardPanel") as Control
	var reward_box = main_instance.call("current_surface_node", "RewardPanel/Margin/RewardBox") as VBoxContainer
	var reward_title = main_instance.call("current_surface_node", "RewardPanel/Margin/RewardBox/BoardHead/BoardTitleBox/RewardTitle") as Label
	var reward_grid = main_instance.call("current_surface_node", "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid") as HBoxContainer
	var backpack_host = main_instance.call("current_surface_node", "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/BackpackHost") as Control
	var inspector_zone = main_instance.call("current_surface_node", "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone") as Control
	var discard_zone = main_instance.call("current_surface_node", "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone") as Control
	var confirm_zone = main_instance.call("current_surface_node", "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone") as Control
	_assert(reward_panel != null, "reward panel exists for reward tray layout audit")
	_assert(reward_box != null, "reward tray box exists for reward tray layout audit")
	_assert(reward_title != null, "reward tray title exists for reward tray layout audit")
	_assert(reward_grid != null, "reward tray board grid exists for reward tray layout audit")
	_assert(backpack_host != null, "reward tray workspace host exists for reward tray layout audit")
	_assert(inspector_zone != null, "reward tray inspector exists for reward tray layout audit")
	_assert(discard_zone != null, "discard zone exists for reward tray layout audit")
	_assert(confirm_zone != null, "confirm zone exists for reward tray layout audit")
	if reward_panel != null and reward_box != null and reward_title != null and reward_grid != null and backpack_host != null and inspector_zone != null and discard_zone != null and confirm_zone != null:
		var panel_local_right: float = reward_panel.global_position.x + reward_panel.size.x
		_assert(bool(reward_panel.visible), "reward tray render keeps the reward panel visible")
		_assert(float(reward_grid.size.x) <= float(reward_box.size.x) + 1.0, "reward tray board grid stays inside the reward box width (grid=%.2f box=%.2f)" % [reward_grid.size.x, reward_box.size.x])
		_assert(float(backpack_host.global_position.x) >= float(reward_grid.global_position.x) - 0.5, "reward tray workspace host stays inside the board grid left edge")
		_assert(float(inspector_zone.global_position.x) >= float(backpack_host.global_position.x) - 0.5, "reward tray inspector stays to the right of the shared workspace host")
		_assert(float(confirm_zone.global_position.x) >= float(discard_zone.global_position.x) - 0.5, "reward tray confirm zone stays in the bottom row beside the discard zone")
		_assert(float(discard_zone.position.x + discard_zone.size.x) <= float(reward_box.size.x) + 1.0, "discard zone stays inside the reward panel width (discard=%.2f panel=%.2f)" % [discard_zone.position.x + discard_zone.size.x, reward_box.size.x])
		_assert(float(discard_zone.global_position.x + discard_zone.size.x) <= panel_local_right - 8.0, "discard zone stays inside the live reward panel instead of clipping right (discard=%.2f panel=%.2f)" % [discard_zone.global_position.x + discard_zone.size.x, panel_local_right])
		_assert(float(reward_grid.size.y) >= 280.0, "reward tray board grid reserves a tall central body instead of collapsing to the old shallow strip (grid=%.2f)" % reward_grid.size.y)
		_assert(float(backpack_host.size.y) >= 220.0, "reward tray workspace host keeps a dedicated placement area for the shared backpack (host=%.2f)" % backpack_host.size.y)
	_assert_visible_controls_inside_viewport(main_instance, "reward tray")
	main_instance.queue_free()
	await process_frame
func _assert_reward_reveal_layout(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	await _boot_to_node_select(main_instance)
	var overlay = main_instance.get("reward_reveal_overlay") as Control
	_assert(overlay != null, "reward reveal overlay exists for layout audit")
	if overlay == null:
		main_instance.queue_free()
		await process_frame
		return
	var rewards := [
		{"kind": "Common Drill", "rarity": "common", "qty": 1, "payload": {"item_type": "drill", "energy_type": "red"}},
		{"kind": "Epic Beacon", "rarity": "epic", "qty": 1, "payload": {"item_type": "beacon", "energy_type": "purple"}},
		{"kind": "Legendary Relic", "rarity": "legendary", "qty": 1, "payload": {"item_type": "relic", "energy_type": ""}}
	]
	overlay.call("start_reveal", rewards, Callable(), Callable(), Rect2(Vector2(220.0, 560.0), Vector2(96.0, 60.0)))
	await process_frame
	await process_frame
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	var canvas_size: Vector2 = overlay.size
	_assert(bool(overlay.visible), "reward reveal overlay becomes visible during the layout audit")
	_assert(float(overlay.position.x) >= -0.5 and float(overlay.position.y) >= -0.5, "reward reveal overlay remains anchored to the top-left corner")
	_assert(canvas_size.x > 0.0 and canvas_size.y > 0.0, "reward reveal overlay resolves a non-zero canvas size")
	if RewardRevealOverlayScript != null and canvas_size.x > 0.0 and canvas_size.y > 0.0:
		var safe_layout = RewardRevealOverlayScript.overlay_safe_layout_model(canvas_size)
		var focus_center: Vector2 = safe_layout.get("focusCenter", canvas_size * 0.5)
		var safe_margin := float(safe_layout.get("safeMargin", 24.0))
		var focus_radius := float(safe_layout.get("focusMaxRadius", 0.0))
		var allowed_radius := minf(minf(focus_center.x, canvas_size.x - focus_center.x), minf(focus_center.y, canvas_size.y - focus_center.y)) - safe_margin
		_assert(focus_radius <= allowed_radius + 0.5, "reward reveal focus effects stay inside the shared safe radius during runtime")
		var lid_layout = RewardRevealOverlayScript.center_lid_layout_model(canvas_size)
		var lid_rect: Rect2 = lid_layout.get("closedLidRect", Rect2())
		_assert(float(lid_rect.position.x) >= 24.0, "reward reveal lid stays inside the left screen edge during runtime")
		_assert(float(lid_rect.end.x) <= float(canvas_size.x) - 24.0, "reward reveal lid stays inside the right screen edge during runtime")
		var metrics = RewardRevealOverlayScript.reward_card_layout_metrics(canvas_size)
		var card_size := Vector2(float(metrics.get("cardWidth", 0.0)), float(metrics.get("cardHeight", 0.0))) * 1.06
		var card_rect := Rect2(Vector2(canvas_size.x * 0.50, float(metrics.get("cardCenterY", canvas_size.y * 0.57))) - (card_size * 0.5), card_size)
		_assert(float(card_rect.position.x) >= 24.0, "reward reveal card stays inside the left screen edge during runtime")
		_assert(float(card_rect.end.x) <= float(canvas_size.x) - 24.0, "reward reveal card stays inside the right screen edge during runtime")
		_assert(float(card_rect.end.y) <= float(safe_layout.get("confirmPromptY", canvas_size.y * 0.90)) - 24.0, "reward reveal card stays above the confirm prompt lane during runtime")
		_assert(float(metrics.get("frontProgressY", 0.0)) + 10.0 <= float(safe_layout.get("confirmPromptY", canvas_size.y * 0.90)) - 16.0, "reward reveal front progress bar stays inside the lower safe band during runtime")
		_assert(float(metrics.get("progressY", 0.0)) + float(metrics.get("progressFontSize", 18)) <= float(safe_layout.get("confirmPromptY", canvas_size.y * 0.90)) - 12.0, "reward reveal progress text stays above the confirm prompt lane during runtime")
	_assert_visible_controls_inside_viewport(main_instance, "reward reveal")
	main_instance.queue_free()
	await process_frame
func _assert_overlay_layouts(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	await _boot_to_node_select(main_instance)
	var settings_overlay = main_instance.get("settings_panel") as Control
	var codex_overlay = main_instance.get("codex_panel") as Control
	main_instance.call("set_settings_visible", true)
	await process_frame
	await process_frame
	_assert_visible_controls_inside_viewport(main_instance, "settings overlay")
	_assert_overlay_claims_top_layer(settings_overlay, "settings overlay")
	main_instance.call("set_settings_visible", false)
	main_instance.call("set_shop_visible", true)
	await process_frame
	await process_frame
	_assert_eq(bool(main_instance.call("is_shop_visible")), false, "unfinished shop overlay stays hidden when forced through the view API")
	main_instance.call("set_shop_visible", false)
	main_instance.call("set_artifact_codex_visible", true)
	await process_frame
	await process_frame
	_assert_visible_controls_inside_viewport(main_instance, "artifact codex overlay")
	_assert_overlay_claims_top_layer(codex_overlay, "artifact codex overlay")
	main_instance.call("set_artifact_codex_visible", false)
	var confirm_overlay = main_instance.get("confirm_overlay") as Control
	if confirm_overlay != null:
		confirm_overlay.visible = true
		await process_frame
		_assert_visible_controls_inside_viewport(main_instance, "confirm overlay")
		_assert_overlay_claims_top_layer(confirm_overlay, "confirm overlay")
		confirm_overlay.visible = false
	var repair_overlay = main_instance.get("repair_overlay") as Control
	if repair_overlay != null:
		repair_overlay.visible = true
		await process_frame
		_assert_visible_controls_inside_viewport(main_instance, "repair overlay")
		_assert_overlay_claims_top_layer(repair_overlay, "repair overlay")
		repair_overlay.visible = false
	main_instance.queue_free()
	await process_frame
func _assert_overlay_claims_top_layer(overlay: Control, label: String) -> void:
	_assert(overlay != null, "%s exists for top-layer audit" % label)
	if overlay == null:
		return
	var parent := overlay.get_parent()
	_assert(parent != null, "%s keeps a parent for top-layer audit" % label)
	if parent == null:
		return
	_assert_eq(parent.get_child(parent.get_child_count() - 1), overlay, "%s moves to the last sibling so gameplay nodes cannot cover it" % label)
	_assert(int(overlay.z_index) > 200, "%s claims a popup z-index above combat HUD and damage popups" % label)
func _assert_header_actions_inside_window(main_instance: Node, label: String) -> void:
	var header = main_instance.get_node_or_null("RootMargin/AppShell/Header") as Control
	var header_actions = main_instance.get("header_actions") as HBoxContainer
	var settings_button = main_instance.get("settings_open_button") as Button
	var shop_button = main_instance.get("shop_open_button") as Button
	var codex_button = main_instance.get("codex_open_button") as Button
	_assert(header != null, "header exists for %s layout audit" % label)
	_assert(header_actions != null, "header actions exist for %s layout audit" % label)
	if header == null or header_actions == null:
		return
	var header_right: float = minf(header.global_position.x + header.size.x, _viewport_rect().end.x)
	_assert(float(header_actions.global_position.x) >= header.global_position.x - 0.5, "header actions stay inside the left header edge for %s" % label)
	_assert(float(header_actions.global_position.x + header_actions.size.x) <= header_right + 0.5, "header actions stay inside the right header edge for %s" % label)
	for button in [settings_button, shop_button, codex_button]:
		if button == null or not button.visible:
			continue
		_assert(float(button.global_position.x) >= header.global_position.x - 0.5, "header button stays inside the left shell edge for %s: %s" % [label, button.name])
		_assert(float(button.global_position.x + button.size.x) <= header_right + 0.5, "header button stays inside the right shell edge for %s: %s" % [label, button.name])
func _assert_node_select_layout_inside_window(main_instance: Node, label: String, expect_color_picker: bool, expected_route_button_count: int, expect_future_preview: bool, expected_history_marker_count: int) -> void:
	var page_scenes: Dictionary = main_instance.get("page_scenes")
	var node_select_page: Control = null
	var board_shell: Control = null
	var roadmap_frame: Control = null
	var roadmap_canvas: Control = null
	var info_card: Control = null
	var future_preview: Control = null
	var boss_hotspot: Control = null
	var retired_split_shell: Control = null
	if not page_scenes.is_empty():
		node_select_page = page_scenes.get("node_select", null) as Control
	if node_select_page != null:
		board_shell = node_select_page.get_node_or_null("Margin/VStack/BoardShell") as Control
		roadmap_frame = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame") as Control
		roadmap_canvas = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas") as Control
		info_card = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/InfoCard") as Control
		future_preview = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/NodeLayer/FuturePreviewHotspot") as Control
		boss_hotspot = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/NodeLayer/BossHotspot") as Control
		retired_split_shell = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/RouteSplit") as Control
	var shared_backpack = main_instance.get("backpack_container") as Control
	_assert(node_select_page != null, "node-select runtime page exists for %s" % label)
	_assert(node_select_page == null or node_select_page.get_node_or_null("Margin/VStack/HeroSection") == null, "node-select runtime page removes the retired hero section for %s" % label)
	_assert(board_shell != null, "node-select runtime page exposes the board shell for %s" % label)
	_assert(roadmap_frame != null, "node-select runtime page exposes the roadmap frame for %s" % label)
	_assert(roadmap_canvas != null, "node-select runtime page exposes the roadmap canvas for %s" % label)
	_assert(info_card != null, "node-select runtime page exposes the left-side hover info card for %s" % label)
	_assert(boss_hotspot != null, "node-select runtime page exposes the boss hotspot for %s" % label)
	if expect_future_preview:
		_assert(future_preview != null, "node-select runtime page exposes a separate future preview marker for %s" % label)
	else:
		_assert(future_preview == null, "node-select runtime page removes the future preview marker when no further non-boss stage remains for %s" % label)
	_assert(retired_split_shell == null, "node-select runtime page removes the retired split map/backpack shell for %s" % label)
	if node_select_page == null or board_shell == null or roadmap_frame == null or roadmap_canvas == null or info_card == null or boss_hotspot == null:
		return
	var window_right: float = _viewport_rect().end.x
	_assert(float(node_select_page.global_position.x + node_select_page.size.x) <= window_right + 0.5, "node-select runtime page stays inside the main window for %s" % label)
	_assert(float(board_shell.global_position.x + board_shell.size.x) <= window_right + 0.5, "node-select board shell stays inside the main window for %s" % label)
	_assert_control_inside_parent(roadmap_frame, board_shell, "node-select roadmap frame for %s" % label)
	_assert_control_inside_parent(roadmap_canvas, roadmap_frame, "node-select roadmap canvas for %s" % label)
	_assert_control_inside_parent(info_card, roadmap_canvas, "node-select info card for %s" % label)
	_assert_control_inside_parent(boss_hotspot, roadmap_canvas, "node-select boss hotspot for %s" % label)
	if expect_future_preview and future_preview != null:
		_assert_control_inside_parent(future_preview, roadmap_canvas, "node-select future preview marker for %s" % label)
	var route_button_count := -1
	if node_select_page.has_method("route_button_count"):
		route_button_count = int(node_select_page.call("route_button_count"))
	_assert(route_button_count == expected_route_button_count, "node-select roadmap renders the expected current route count for %s" % label)
	if node_select_page.has_method("history_marker_count"):
		_assert_eq(int(node_select_page.call("history_marker_count")), expected_history_marker_count, "node-select roadmap renders the expected cleared-history count for %s" % label)
	for route_index in range(expected_route_button_count):
		var route_button := node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/NodeLayer/RouteButton%d" % route_index) as Control
		_assert_control_inside_parent(route_button, roadmap_canvas, "node-select route button %d for %s" % [route_index, label])
	_assert(shared_backpack == null or not bool(shared_backpack.visible), "node-select keeps the shared backpack hidden for %s" % label)
	if node_select_page.has_method("start_color_chip_count"):
		_assert_eq(int(node_select_page.call("start_color_chip_count")), 0 if not expect_color_picker else 4, "node-select start-color chip visibility matches the stage contract for %s" % label)
