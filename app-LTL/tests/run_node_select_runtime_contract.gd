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
	var hero_title := page.get_node_or_null("Margin/VStack/HeroSection/HeroTitle") as Label
	var board_label := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/BoardLabel") as Label
	var board_title := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/LeviathanTitle") as Label
	_assert(hero_title != null, "stage one exposes the hero title label for copy cleanup")
	_assert(board_label != null, "stage one exposes the board label for copy cleanup")
	_assert(board_title != null, "stage one exposes the board title for copy cleanup")
	if hero_title != null:
		_assert_eq(hero_title.text, "", "stage one retires the duplicate hero Leviathan title copy")
	if board_label != null:
		_assert_eq(board_label.text, "", "stage one retires the selected-leviathan board kicker copy")
	if board_title != null:
		_assert_eq(board_title.text, TextCatalogScript.display_name("Ossuary Tortoise"), "stage one keeps the board-head Leviathan title")
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
	var hero_title := page.get_node_or_null("Margin/VStack/HeroSection/HeroTitle") as Label
	var board_label := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/BoardLabel") as Label
	var board_title := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/BoardLead/LeviathanTitle") as Label
	_assert(hero_title != null, "stage two exposes the hero title label for copy cleanup")
	_assert(board_label != null, "stage two exposes the board label for copy cleanup")
	_assert(board_title != null, "stage two exposes the board title for copy cleanup")
	if hero_title != null:
		_assert_eq(hero_title.text, "", "stage two keeps the duplicate hero Leviathan title removed")
	if board_label != null:
		_assert_eq(board_label.text, "", "stage two keeps the selected-leviathan board kicker removed")
	if board_title != null:
		_assert_eq(board_title.text, TextCatalogScript.display_name("Ossuary Tortoise"), "stage two keeps the board-head Leviathan title")
	_assert_eq(int(page.call("route_button_count")), 5, "stage two renders five current branch buttons")
	_assert_eq(int(page.call("history_marker_count")), 1, "stage two keeps the cleared opening node in history")
	_assert_eq(int(page.call("start_marker_count")), 1, "stage two still renders the start marker")
	_assert_eq(int(page.call("future_marker_count")), 0, "stage two renders no future ? markers for a three-stage leviathan")
	_assert_eq(int(page.call("boss_marker_count")), 1, "stage two keeps the boss marker visible")
	_assert_eq(int(page.call("current_unknown_route_count")), 0, "stage two keeps the current branch icons distinct from future ? markers")
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
