extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	TextCatalogScript.set_locale("ko")
	await _assert_stage_one_contract()
	await _assert_stage_two_contract()
	await _assert_canvas_rebuild_defers_replaced_control_free()
	if failures.is_empty():
		print("NODE_SELECT_RUNTIME_CONTRACT_OK")
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	await process_frame
	quit(1)

func _assert_stage_one_contract() -> void:
	var page := await _instantiate_page()
	if page == null:
		return
	page.apply_state(_stage_one_state())
	await process_frame
	await process_frame
	var hero_section := page.get_node_or_null("Margin/VStack/HeroSection") as Control
	var board_label := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/BoardLabel") as Label
	var board_title := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/LeviathanTitle") as Label
	var shop_button := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/ShopButton") as Button
	var codex_button := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/CodexButton") as Button
	var settings_button := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/SettingsButton") as Button
	var run_chip := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/RunChip") as PanelContainer
	var stage_chip := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/StageChip") as PanelContainer
	var action_bar := page.get_node_or_null("Margin/VStack/ActionBar") as HBoxContainer
	var action_bar_spacer := page.get_node_or_null("Margin/VStack/ActionBar/Spacer") as Control
	_assert(hero_section == null, "stage one removes the retired hero section instead of leaving empty header space")
	_assert(board_label != null, "stage one exposes the board label for copy cleanup")
	_assert(board_title != null, "stage one exposes the board title for copy cleanup")
	if board_label != null:
		_assert_eq(board_label.text, "", "stage one retires the selected-leviathan board kicker copy")
	if board_title != null:
		_assert_eq(board_title.text, TextCatalogScript.display_name("Ossuary Tortoise"), "stage one keeps the board-head Leviathan title")
	_assert(shop_button != null, "stage one exposes an in-frame shop button after retiring the outer header controls")
	_assert(codex_button != null, "stage one exposes an in-frame codex button after retiring the outer header controls")
	_assert(settings_button != null, "stage one exposes an in-frame settings button after retiring the outer header controls")
	if shop_button != null:
		_assert_eq(shop_button.text, TextCatalogScript.t("action.shop"), "stage one localizes the in-frame shop button")
	if codex_button != null:
		_assert_eq(codex_button.text, TextCatalogScript.t("action.codex"), "stage one localizes the in-frame codex button")
	if settings_button != null:
		_assert_eq(settings_button.text, TextCatalogScript.t("action.settings"), "stage one localizes the in-frame settings button")
	_assert(run_chip != null, "stage one exposes the run chip for padding verification")
	_assert(stage_chip != null, "stage one exposes the stage chip for padding verification")
	if run_chip != null:
		var run_style := run_chip.get_theme_stylebox("panel") as StyleBoxFlat
		_assert(run_style != null, "stage one run chip resolves a panel style")
		if run_style != null:
			_assert(run_style.content_margin_left >= 18.0 and run_style.content_margin_right >= 18.0, "stage one run chip adds left/right content padding")
	if stage_chip != null:
		var stage_style := stage_chip.get_theme_stylebox("panel") as StyleBoxFlat
		_assert(stage_style != null, "stage one stage chip resolves a panel style")
		if stage_style != null:
			_assert(stage_style.content_margin_left >= 18.0 and stage_style.content_margin_right >= 18.0, "stage one stage chip adds left/right content padding")
	_assert(action_bar != null, "stage one exposes the node-select action bar")
	_assert(action_bar_spacer != null, "stage one action bar inserts a spacer so reset and start separate to opposite ends")
	if action_bar_spacer != null:
		_assert_eq(bool(action_bar_spacer.size_flags_horizontal & Control.SIZE_EXPAND_FILL), true, "stage one action-bar spacer expands across the free width")
	_assert_eq(int(page.call("route_button_count")), 0, "stage one keeps the opening node fixed instead of rendering branch buttons")
	_assert_eq(int(page.call("start_marker_count")), 1, "stage one renders exactly one start marker")
	_assert_eq(int(page.call("future_marker_count")), 1, "stage one renders exactly one future ? marker for a three-stage leviathan")
	_assert_eq(int(page.call("boss_marker_count")), 1, "stage one renders exactly one boss marker")
	_assert_eq(int(page.call("fixed_entry_marker_count")), 0, "stage one removes the retired fixed-entry hotspot")
	page.queue_free()
	await process_frame

func _assert_stage_two_contract() -> void:
	var page := await _instantiate_page()
	if page == null:
		return
	page.apply_state(_stage_two_state())
	await process_frame
	await process_frame
	var hero_section := page.get_node_or_null("Margin/VStack/HeroSection") as Control
	var board_label := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/BoardLabel") as Label
	var board_title := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/LeviathanTitle") as Label
	var start_button := page.get_node_or_null("Margin/VStack/ActionBar/StartButton") as Button
	_assert(hero_section == null, "stage two keeps the retired hero section removed")
	_assert(board_label != null, "stage two exposes the board label for copy cleanup")
	_assert(board_title != null, "stage two exposes the board title for copy cleanup")
	if board_label != null:
		_assert_eq(board_label.text, "", "stage two keeps the selected-leviathan board kicker removed")
	if board_title != null:
		_assert_eq(board_title.text, TextCatalogScript.display_name("Ossuary Tortoise"), "stage two keeps the board-head Leviathan title")
	if start_button != null:
		_assert_eq(start_button.text, "채굴 시작", "stage two renames the node-select start CTA to mining start")
	_assert_eq(int(page.call("route_button_count")), 5, "stage two renders five current branch buttons")
	_assert_eq(int(page.call("history_marker_count")), 1, "stage two keeps the cleared opening node in history")
	_assert_eq(int(page.call("start_marker_count")), 1, "stage two still renders the start marker")
	_assert_eq(int(page.call("future_marker_count")), 0, "stage two renders no future ? markers for a three-stage leviathan")
	_assert_eq(int(page.call("boss_marker_count")), 1, "stage two keeps the boss marker visible")
	_assert_eq(int(page.call("current_unknown_route_count")), 0, "stage two keeps the current branch icons distinct from future ? markers")
	page.queue_free()
	await process_frame

func _assert_canvas_rebuild_defers_replaced_control_free() -> void:
	var page := await _instantiate_page()
	if page == null:
		return
	page.apply_state(_stage_two_state())
	await process_frame
	await process_frame
	var node_layer := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/NodeLayer")
	_assert(node_layer != null, "node-select exposes the canvas node layer for rebuild lifetime verification")
	if node_layer == null:
		page.queue_free()
		await process_frame
		return
	var old_children := node_layer.get_children()
	_assert(old_children.size() > 0, "node-select canvas has replaceable hotspot children before rebuild")
	if old_children.is_empty():
		page.queue_free()
		await process_frame
		return
	var old_hotspot: Node = old_children[0]
	var next_state := _stage_two_state()
	next_state["selectedNodeIndex"] = 1
	page.apply_state(next_state)
	page.call("_rebuild_canvas")
	_assert(is_instance_valid(old_hotspot), "node-select rebuild keeps replaced hotspot valid for Godot deferred mouse-over cleanup")
	if is_instance_valid(old_hotspot):
		_assert(old_hotspot.get_parent() == null, "node-select rebuild detaches replaced hotspot from the live node layer immediately")
	page.queue_free()
	await process_frame

func _instantiate_page() -> Control:
	var scene_resource := load("res://src/scenes/pages/NodeSelectRuntimePage.tscn") as PackedScene
	_assert(scene_resource != null, "node-select runtime page scene resource loads")
	if scene_resource == null:
		return null
	var page := scene_resource.instantiate() as Control
	_assert(page != null, "node-select runtime page instantiates")
	if page == null:
		return null
	root.add_child(page)
	await process_frame
	await process_frame
	return page

func _stage_one_state() -> Dictionary:
	return {
		"phase": "node_select",
		"pageId": "node_select",
		"stageIndex": 0,
		"maxStages": 3,
		"runIndex": 0,
		"runCount": 1,
		"selectedNodeIndex": 0,
		"selectedLeviathan": {"name": "Ossuary Tortoise", "runCount": 1},
		"nodeSelect": {
			"candidates": [
				{
					"id": "normal",
					"label": "Safe Scar",
					"nodeType": "normal",
					"riskTier": "safe",
					"rewardBias": "baseline",
					"recommendedBuildHint": "Any stable drill line",
					"weakness": ["red"]
				}
			],
			"routeHistory": [],
			"isBossStage": false,
			"isFixedStartStage": true
		}
	}

func _stage_two_state() -> Dictionary:
	return {
		"phase": "node_select",
		"pageId": "node_select",
		"stageIndex": 1,
		"maxStages": 3,
		"runIndex": 0,
		"runCount": 1,
		"selectedNodeIndex": 2,
		"selectedLeviathan": {"name": "Ossuary Tortoise", "runCount": 1},
		"nodeSelect": {
			"candidates": [
				{"id": "normal", "label": "Safe Scar", "nodeType": "normal", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Any stable drill line", "weakness": ["red"]},
				{"id": "repair_event", "label": "Repair Event", "nodeType": "repair_event", "riskTier": "support", "rewardBias": "repair", "recommendedBuildHint": "Stabilize damaged route", "weakness": ["blue"], "isEvent": true},
				{"id": "hazard_rich", "label": "Hazard Rich", "nodeType": "hazard_rich", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "weakness": ["green"]},
				{"id": "mysterious_crevice", "label": "Mysterious Crevice", "nodeType": "mysterious_crevice", "riskTier": "unknown", "rewardBias": "mystery", "recommendedBuildHint": "Short volatile encounter", "weakness": [], "isEvent": true},
				{"id": "mixed_fault", "label": "Mixed Fault", "nodeType": "mixed_weakness", "riskTier": "hard", "rewardBias": "multi_energy", "recommendedBuildHint": "Blue or purple coverage", "weakness": ["blue", "purple"]}
			],
			"routeHistory": [
				{
					"stageIndex": 0,
					"routeSlotIndex": 0,
					"id": "normal",
					"label": "Safe Scar",
					"nodeType": "normal",
					"riskTier": "safe",
					"rewardBias": "baseline",
					"recommendedBuildHint": "Any stable drill line",
					"weakness": ["red"]
				}
			],
			"isBossStage": false,
			"isFixedStartStage": false
		}
	}

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
