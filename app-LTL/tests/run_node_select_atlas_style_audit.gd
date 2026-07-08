extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	TextCatalogScript.set_locale("ko")
	var page := await _instantiate_page()
	if page == null:
		_finish()
		return
	page.apply_state(_stage_two_state())
	await process_frame
	await process_frame
	_assert_eq(str(page.get_meta("design_spec", "")), "node-select-atlas-variant-a", "node-select page is tagged with the atlas variant design spec")
	var canvas := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas") as Control
	var board_shell := page.get_node_or_null("Margin/VStack/BoardShell") as PanelContainer
	var roadmap_frame := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame") as PanelContainer
	_assert(canvas != null, "roadmap canvas exists")
	if board_shell != null:
		_assert(board_shell.get_theme_stylebox("panel") is StyleBoxEmpty, "outer board shell is visually removed")
	if roadmap_frame != null:
		var frame_style := roadmap_frame.get_theme_stylebox("panel") as StyleBoxFlat
		_assert(frame_style != null, "roadmap frame keeps a style object for audit")
		if frame_style != null:
			_assert(frame_style.corner_radius_top_left == 0 and frame_style.border_width_left == 0, "roadmap frame has no amateur rounded border")
	if canvas != null:
		_assert_eq(str(canvas.get_meta("atlas_bg_path", "")), "res://resources/node_select/atlas/variant_a_bg_topographic_leviathan_atlas.png", "roadmap canvas owns the atlas background path")
	var backdrop := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/CanvasBackdrop/AtlasMapBackdrop") as TextureRect
	_assert(backdrop != null, "atlas map backdrop texture node is created")
	if backdrop != null:
		_assert(backdrop.texture != null, "atlas map backdrop texture loads")
		_assert_eq(int(backdrop.stretch_mode), int(TextureRect.STRETCH_KEEP_ASPECT_COVERED), "atlas map uses full-fill covered scaling")
	var info_card := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/InfoCard") as Control
	_assert(info_card != null, "atlas inspector card exists")
	if info_card != null:
		_assert_eq(str(info_card.get_meta("design_spec", "")), "node-select-atlas-variant-a", "inspector card keeps atlas design marker")
		_assert(info_card.size.x >= 282.0 and info_card.size.y >= 300.0, "inspector card uses large atlas-panel proportions")
		_assert(info_card.get_theme_stylebox("panel") is StyleBoxEmpty, "inspector card does not add a second visible wrapper panel")
		var info_body := info_card.get_node_or_null("InfoMargin/InfoVBox/InfoBody") as Label
		_assert(info_body != null, "inspector body label exists")
		if info_body != null:
			_assert(info_body.text.find("약점") >= 0, "inspector body includes node weakness section")
			_assert(info_body.text.find("방해요소") >= 0, "inspector body includes obstruction section")
			_assert(info_body.text.find("노드 설명") > info_body.text.find("방해요소"), "node description is rendered after gameplay analysis sections")
	var route_button := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/NodeLayer/RouteButton2") as Button
	_assert(route_button != null, "selected route button exists for icon audit")
	if route_button != null:
		var icon := route_button.get_node_or_null("Icon") as TextureRect
		_assert(icon != null, "route button uses atlas texture icon")
		if icon != null:
			_assert(icon.texture != null, "route button atlas icon texture loads")
			_assert(not str(icon.get_meta("atlas_icon_kind", "")).is_empty(), "route button icon records atlas icon kind")
	var start_button := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/ActionBar/StartButton") as Button
	var reset_button := page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/ActionBar/ResetButton") as Button
	_assert(start_button != null, "start CTA exists")
	_assert(reset_button != null, "reset CTA exists")
	if start_button != null:
		_assert_eq(str(start_button.get_meta("design_spec", "")), "node-select-atlas-variant-a", "start CTA is tagged with atlas design spec")
		_assert(start_button.custom_minimum_size.x >= 200.0 and start_button.custom_minimum_size.y >= 60.0, "start CTA uses large atlas dock sizing")
	if reset_button != null:
		_assert_eq(str(reset_button.get_meta("design_spec", "")), "node-select-atlas-variant-a", "reset CTA is tagged with atlas design spec")
	page.queue_free()
	await process_frame
	_finish()

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
			"routeHistory": [{"stageIndex": 0, "routeSlotIndex": 0, "id": "normal", "label": "Safe Scar", "nodeType": "normal", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Any stable drill line", "weakness": ["red"]}],
			"isBossStage": false,
			"isFixedStartStage": false
		}
	}

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s (expected=%s actual=%s)" % [message, str(expected), str(actual)])

func _finish() -> void:
	if failures.is_empty():
		print("NODE_SELECT_ATLAS_STYLE_AUDIT_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
