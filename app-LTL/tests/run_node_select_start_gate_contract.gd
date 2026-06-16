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
	_assert(MainScene != null, "main scene loads for node-select start gate")
	if MainScene == null:
		_finish()
		return
	var main_instance = MainScene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	await process_frame
	var controller = await _boot_to_node_select(main_instance, "purple", "ossuary_tortoise")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		_finish()
		return

	var start_button = main_instance.get("start_button") as Button
	var node_select_page = _node_select_page(main_instance)
	_assert(start_button != null, "node-select start button exists")
	_assert(node_select_page != null, "node-select page exists")
	if start_button == null or node_select_page == null:
		main_instance.queue_free()
		await process_frame
		_finish()
		return

	_assert_eq(int(controller.get("selected_node_index")), -1, "node select starts without an implicit selected node")
	_assert_eq(bool(start_button.disabled), true, "mining start is disabled before a current node click")
	await _assert_intro_narrative_story_surface(main_instance)
	_assert(node_select_page.has_method("press_start_marker"), "node-select page exposes fixed-start marker automation")
	if node_select_page.has_method("press_start_marker"):
		node_select_page.call("press_start_marker")
	await process_frame
	await process_frame
	_assert_eq(int(controller.get("selected_node_index")), 0, "fixed start marker click selects the stage-one node")
	_assert_eq(bool(start_button.disabled), false, "mining start enables after selecting the fixed current node")

	if node_select_page.has_method("press_start_marker"):
		node_select_page.call("press_start_marker")
	await process_frame
	await process_frame
	_assert_eq(int(controller.get("selected_node_index")), -1, "clicking the selected fixed node again clears selection")
	_assert_eq(bool(start_button.disabled), true, "mining start disables when the selected node is toggled off")

	if node_select_page.has_method("press_start_marker"):
		node_select_page.call("press_start_marker")
	await process_frame
	await process_frame
	await _assert_shop_disabled_on_node_select(main_instance, node_select_page, start_button)
	await _assert_menu_round_trip_keeps_start_ready(main_instance, node_select_page, start_button, "codex")

	start_button.pressed.emit()
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "battle", "selected fixed node starts the normal battle")

	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await process_frame
	await process_frame
	controller.call("_proceed_to_node_select")
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "reward claim returns to node select")
	_assert_eq(int(controller.get("selected_node_index")), -1, "next node-select stage clears the previous selection")
	start_button = main_instance.get("start_button") as Button
	node_select_page = _node_select_page(main_instance)
	_assert(start_button != null, "stage-two start button exists")
	_assert(node_select_page != null, "stage-two node-select page exists")
	if start_button != null:
		_assert_eq(bool(start_button.disabled), true, "stage-two mining start waits for a fresh current-node click")
	if node_select_page != null:
		var route_count := int(node_select_page.call("route_button_count")) if node_select_page.has_method("route_button_count") else 0
		_assert(route_count > 0, "stage-two node select shows current route candidates before shop signal")
		await _assert_forced_shop_purchase_preserves_node_select(main_instance, controller, node_select_page, route_count)
	if node_select_page != null and node_select_page.has_method("press_route_button"):
		node_select_page.call("press_route_button", 1)
	await process_frame
	await process_frame
	if start_button != null:
		_assert_eq(bool(start_button.disabled), false, "stage-two mining start enables after selecting a current route")

	if start_button != null:
		start_button.pressed.emit()
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "battle", "selected stage-two route starts battle")

	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await process_frame
	await process_frame
	controller.call("_proceed_to_node_select")
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "second reward claim returns to boss node select")
	_assert_eq(int(controller.get("selected_node_index")), -1, "boss node-select starts with no implicit selection")
	start_button = main_instance.get("start_button") as Button
	node_select_page = _node_select_page(main_instance)
	_assert(start_button != null, "boss-stage start button exists")
	_assert(node_select_page != null, "boss-stage node-select page exists")
	if start_button != null:
		_assert_eq(bool(start_button.disabled), true, "boss-stage mining start waits for boss node click")
	_assert(node_select_page != null and node_select_page.has_method("press_boss_marker"), "node-select page exposes boss marker automation")
	if node_select_page != null and node_select_page.has_method("press_boss_marker"):
		node_select_page.call("press_boss_marker")
	await process_frame
	await process_frame
	if start_button != null:
		_assert_eq(bool(start_button.disabled), false, "boss-stage mining start enables after selecting the current boss node")
		start_button.pressed.emit()
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "boss_battle", "selected boss node starts boss battle")

	main_instance.queue_free()
	await process_frame
	_finish()

func _boot_to_node_select(main_instance: Node, color: String, leviathan_id: String) -> Node:
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists for node-select start gate")
	if controller == null:
		return null
	var character_page = main_instance.get("character_select_page")
	_assert(character_page != null, "character select page exists for node-select start gate")
	if character_page != null:
		character_page.color_selected.emit(color)
		character_page.continue_requested.emit()
	await process_frame
	await process_frame
	var leviathan_page = main_instance.get("leviathan_select_page")
	_assert(leviathan_page != null, "leviathan select page exists for node-select start gate")
	if leviathan_page != null:
		leviathan_page.leviathan_selected.emit(leviathan_id)
		leviathan_page.start_requested.emit()
	await process_frame
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "leviathan start reaches node-select page")
	return controller

func _assert_shop_disabled_on_node_select(main_instance: Node, node_select_page: Node, start_button: Button) -> void:
	var shop_button = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/ShopButton") as Button
	_assert(shop_button != null, "node-select shop button exists for disabled-state verification")
	if shop_button != null:
		_assert_eq(bool(shop_button.disabled), true, "unfinished shop button is disabled on node select")
		shop_button.pressed.emit()
	await process_frame
	await process_frame
	_assert_eq(bool(main_instance.call("is_shop_visible")), false, "disabled shop button does not open the shop overlay")
	main_instance.call("set_shop_visible", true)
	await process_frame
	_assert_eq(bool(main_instance.call("is_shop_visible")), false, "unfinished shop cannot be forced visible through the view API")
	_assert_eq(bool(start_button.disabled), false, "disabled shop interaction keeps selected current node ready to start")

func _assert_forced_shop_purchase_preserves_node_select(main_instance: Node, controller: Node, node_select_page: Node, expected_route_count: int) -> void:
	var shop_panel = main_instance.get("shop_panel")
	_assert(shop_panel != null, "shop panel exists for forced-signal guard verification")
	if shop_panel != null and shop_panel.has_signal("buy_passive"):
		shop_panel.buy_passive.emit("starting_gold_boost", 0)
	await process_frame
	await process_frame
	var current_scene: Dictionary = controller.get("current_scene")
	_assert(current_scene.has("nodeSelect"), "rejected shop purchase keeps decorated nodeSelect scene model")
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "rejected shop purchase keeps the active page on node select")
	if node_select_page.has_method("route_button_count"):
		_assert_eq(int(node_select_page.call("route_button_count")), expected_route_count, "rejected shop purchase preserves visible current route candidates")
	_assert_eq(bool(main_instance.call("is_shop_visible")), false, "forced shop purchase does not open the shop overlay")

func _assert_menu_round_trip_keeps_start_ready(main_instance: Node, node_select_page: Node, start_button: Button, menu: String) -> void:
	if menu == "codex":
		var codex_button = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/CodexButton") as Button
		_assert(codex_button != null, "node-select codex button exists for start gate")
		if codex_button != null:
			codex_button.pressed.emit()
		await process_frame
		_assert_eq(bool(main_instance.call("is_artifact_codex_visible")), true, "artifact codex opens from node-select frame")
		main_instance.call("set_artifact_codex_visible", false)
	else:
		_assert(false, "unsupported node-select menu round trip: %s" % menu)
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "%s round trip stays on node select" % menu)
	_assert_eq(bool(start_button.disabled), false, "%s round trip keeps selected current node ready to start" % menu)

func _node_select_page(main_instance: Node) -> Node:
	var page_scenes: Dictionary = main_instance.get("page_scenes")
	return page_scenes.get("node_select", null)

func _assert_intro_narrative_story_surface(main_instance: Node) -> void:
	var toast = main_instance.get("narrative_toast") as Control
	_assert(toast != null, "intro narrative story surface exists on first node select")
	if toast == null:
		return
	_assert_eq(toast.visible, true, "intro narrative story surface is visible on first node select")
	var visual_area = toast.get_node_or_null("StoryFrame/VisualArea") as Control
	var dialog_panel = toast.get_node_or_null("StoryFrame/DialogPanel") as Control
	var body_label = toast.get_node_or_null("StoryFrame/DialogPanel/DialogMargin/DialogBox/BodyLabel") as Label
	var continue_prompt = toast.get_node_or_null("StoryFrame/DialogPanel/DialogMargin/DialogBox/PromptRow/ContinuePrompt") as Label
	var continue_icon = toast.get_node_or_null("StoryFrame/DialogPanel/DialogMargin/DialogBox/PromptRow/ContinueIcon") as Label
	_assert(visual_area != null, "intro narrative story surface exposes an upper visual area")
	_assert(dialog_panel != null, "intro narrative story surface exposes a lower dialogue area")
	_assert(body_label != null, "intro narrative dialogue area exposes body text")
	_assert(continue_prompt != null, "intro narrative exposes a visible continue prompt")
	_assert(continue_icon != null, "intro narrative exposes a visible continue icon")
	_assert(toast.get_global_rect().size.x >= 640.0, "intro narrative story surface has readable screen width")
	_assert(toast.get_global_rect().size.y >= 300.0, "intro narrative story surface has readable screen height")
	_assert(toast.get_global_rect().size.x <= 1100.0, "intro narrative story surface does not cover the full screen width")
	_assert(toast.get_global_rect().size.y <= 560.0, "intro narrative story surface does not cover the full screen height")
	if visual_area != null:
		_assert(visual_area.get_global_rect().size.y >= 100.0, "intro narrative visual area has visible height")
	if dialog_panel != null:
		_assert(dialog_panel.get_global_rect().size.y >= 120.0, "intro narrative dialogue area has visible height")
	if body_label != null:
		_assert(str(body_label.text).contains("채집") or str(body_label.text).contains("collect"), "intro narrative explains collection framing")
	if continue_prompt != null:
		_assert(str(continue_prompt.text).contains("클릭") or str(continue_prompt.text).to_lower().contains("click"), "intro narrative prompt tells the player to click or continue")
	if continue_icon != null:
		_assert(not str(continue_icon.text).strip_edges().is_empty(), "intro narrative continue icon is visible")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	_assert(toast.has_method("consume_continue_input"), "intro narrative exposes click/continue input handling")
	if toast.has_method("consume_continue_input"):
		var consumed := bool(toast.call("consume_continue_input", click))
		await process_frame
		_assert_eq(consumed, true, "intro narrative click input is consumed as continue")
		_assert_eq(toast.visible, false, "intro narrative story surface hides after click")

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _finish() -> void:
	if failures.is_empty():
		print("NODE_SELECT_START_GATE_CONTRACT_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
