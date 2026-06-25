extends SceneTree

# Boots the real battle page and samples rendered widths over time so layout
# feedback loops cannot hide behind a single stable screenshot.
const DEFAULT_VIEWPORT_SIZE := Vector2i(1440, 932)
const DEFAULT_FRAMES := 180
const DEFAULT_SETTLE_FRAMES := 24
const DEFAULT_SAVE_EVERY := 30
const DEFAULT_OUTPUT_DIR := "res://.tmp-visual-probe/battle-backpack-visual-width"
const WIDTH_TOLERANCE := 2.0
const SQUARE_ASPECT_TOLERANCE := 0.005
const DEFAULT_SAMPLE_INTERVAL_SECONDS := 1.0 / 60.0

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var viewport_size := _parse_viewport(_arg_value("--viewport", "1440x932"))
	var sample_frames := maxi(1, int(_arg_value("--frames", str(DEFAULT_FRAMES))))
	var settle_frames := maxi(0, int(_arg_value("--settle", str(DEFAULT_SETTLE_FRAMES))))
	var save_every := maxi(0, int(_arg_value("--save-every", str(DEFAULT_SAVE_EVERY))))
	var output_dir := _arg_value("--output-dir", DEFAULT_OUTPUT_DIR)
	var sample_interval := maxf(0.0, float(_arg_value("--interval", str(DEFAULT_SAMPLE_INTERVAL_SECONDS))))
	var print_frames := _arg_value("--print-frames", "false") == "true"
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(viewport_size)
	root.size = viewport_size
	var MainScene: PackedScene = load("res://src/Main.tscn")
	if MainScene == null:
		_fail("main scene failed to load")
		_finish(1)
		return
	var main_instance = MainScene.instantiate()
	if main_instance == null:
		_fail("main scene failed to instantiate")
		_finish(1)
		return
	root.add_child(main_instance)
	await _settle_frames(8)
	if not await _go_to_battle(main_instance):
		_finish(1)
		return
	await _dismiss_narrative_if_active(main_instance)
	await _settle_frames(settle_frames)
	var records: Array[Dictionary] = []
	for frame in range(sample_frames):
		if sample_interval > 0.0:
			await create_timer(sample_interval).timeout
		else:
			await process_frame
		await process_frame
		var image := root.get_texture().get_image()
		if image == null or image.is_empty():
			_fail("empty viewport image at frame %d" % frame)
			continue
		if save_every > 0 and frame % save_every == 0:
			_save_image(image, output_dir, frame)
		records.append(_sample_frame(main_instance, image, frame))
	var summary := _summarize(records)
	print("BATTLE_BACKPACK_VISUAL_WIDTH_CONTRACT_SUMMARY ", JSON.stringify(summary))
	if print_frames:
		for record in records:
			print("BATTLE_BACKPACK_VISUAL_WIDTH_CONTRACT_FRAME ", JSON.stringify(record))
	if float(summary.get("battleBackdropDrawnRange", 0.0)) > WIDTH_TOLERANCE:
		_fail("battle backdrop drawn width changed by %.2f px" % float(summary.get("battleBackdropDrawnRange", 0.0)))
	if float(summary.get("battlefieldPixelRange", 0.0)) > WIDTH_TOLERANCE:
		_fail("battlefield rendered pixel width changed by %.2f px" % float(summary.get("battlefieldPixelRange", 0.0)))
	if float(summary.get("backpackGridRange", 0.0)) > WIDTH_TOLERANCE:
		_fail("backpack grid node width changed by %.2f px" % float(summary.get("backpackGridRange", 0.0)))
	if float(summary.get("backpackGridPixelRange", 0.0)) > WIDTH_TOLERANCE:
		_fail("backpack grid rendered pixel width changed by %.2f px" % float(summary.get("backpackGridPixelRange", 0.0)))
	if float(summary.get("backpackPixelRange", 0.0)) > WIDTH_TOLERANCE:
		_fail("backpack rendered pixel width changed by %.2f px" % float(summary.get("backpackPixelRange", 0.0)))
	if absf(float(summary.get("backpackGridAspectMaxDelta", 0.0))) > SQUARE_ASPECT_TOLERANCE:
		_fail("backpack grid node aspect max delta is %.3f" % float(summary.get("backpackGridAspectMaxDelta", 0.0)))
	if absf(float(summary.get("backpackGridPixelAspectMaxDelta", 0.0))) > SQUARE_ASPECT_TOLERANCE:
		_fail("backpack grid rendered aspect max delta is %.3f" % float(summary.get("backpackGridPixelAspectMaxDelta", 0.0)))
	if float(summary.get("backpackGridWidthShortfallMax", 0.0)) > WIDTH_TOLERANCE:
		_fail("backpack grid node width is %.2f px short of square" % float(summary.get("backpackGridWidthShortfallMax", 0.0)))
	if float(summary.get("backpackGridPixelWidthShortfallMax", 0.0)) > WIDTH_TOLERANCE:
		_fail("backpack grid rendered width is %.2f px short of square" % float(summary.get("backpackGridPixelWidthShortfallMax", 0.0)))
	if failures.is_empty():
		print("BATTLE_BACKPACK_VISUAL_WIDTH_CONTRACT_OK")
		_finish(0)
	else:
		print("BATTLE_BACKPACK_VISUAL_WIDTH_CONTRACT_FAIL")
		_finish(1)

func _sample_frame(main_instance: Node, image: Image, frame: int) -> Dictionary:
	var battlefield = main_instance.get("battlefield_ui")
	var backpack = main_instance.get("backpack_ui")
	var controller := main_instance.get_node_or_null("MainController")
	var current_scene: Dictionary = controller.get("current_scene") if controller != null else {}
	var backpack_container := main_instance.get("backpack_container") as Control
	var backpack_host := main_instance.get("backpack_host") as Control
	var top_content := main_instance.get("top_content") as Control
	var battle_root := _node_or_null(battlefield, "Margin/BattlefieldBox/BattlefieldVisualRoot") as Control
	var panel_shell := _node_or_null(battlefield, "Margin/BattlefieldBox/BattlefieldVisualRoot/PanelShell") as Control
	var battle_backdrop := _node_or_null(battlefield, "Margin/BattlefieldBox/BattlefieldVisualRoot/BattleBackdrop") as Control
	var battlefield_grid := _node_or_null(battlefield, "Margin/BattlefieldBox/BattlefieldVisualRoot/BattlefieldGrid") as Control
	var backpack_grid := _node_or_null(backpack, "Margin/EngineBox/GridMock") as Control
	var backpack_margin := _node_or_null(backpack, "Margin") as MarginContainer
	var backpack_engine_box := _node_or_null(backpack, "Margin/EngineBox") as Control
	var battle_rect := _global_rect(battle_root)
	var backpack_rect := _global_rect(backpack)
	var backpack_grid_rect := _global_rect(backpack_grid)
	var battle_pixels := _significant_pixel_bounds(image, battle_rect)
	var backpack_pixels := _significant_pixel_bounds(image, backpack_rect)
	var backpack_grid_pixels := _significant_pixel_bounds(image, backpack_grid_rect)
	var backpack_grid_width := _control_width(backpack_grid)
	var backpack_grid_height := _control_height(backpack_grid)
	var backpack_grid_pixel_width := float(backpack_grid_pixels.get("width", 0))
	var backpack_grid_pixel_height := float(backpack_grid_pixels.get("height", 0))
	return {
		"frame": frame,
		"page": str(main_instance.get("active_page_id")),
		"scenePhase": str(current_scene.get("phase", "")),
		"scenePageId": str(current_scene.get("pageId", "")),
		"controllerBattlePause": bool(controller.get("battle_pause_active")) if controller != null else false,
		"battlefieldBattlePause": bool(battlefield.get("battle_pause_active")) if battlefield != null else false,
		"battlefieldBackdropDriftTime": float(battlefield.get("backdrop_drift_time")) if battlefield != null else 0.0,
		"battleRootWidth": _control_width(battle_root),
		"battlePanelShellWidth": _control_width(panel_shell),
		"battlePanelShellDrawnWidth": _drawn_width(panel_shell),
		"battleBackdropWidth": _control_width(battle_backdrop),
		"battleBackdropScaleX": _scale_x(battle_backdrop),
		"battleBackdropDrawnWidth": _drawn_width(battle_backdrop),
		"battlefieldGridWidth": _control_width(battlefield_grid),
		"battlefieldPixelWidth": float(battle_pixels.get("width", 0)),
		"battlefieldPixelLeft": float(battle_pixels.get("left", -1)),
		"battlefieldPixelRight": float(battle_pixels.get("right", -1)),
		"backpackPanelWidth": _control_width(backpack),
		"backpackInstanceId": _instance_id(backpack),
		"backpackMarginInstanceId": _instance_id(backpack_margin),
		"backpackGridInstanceId": _instance_id(backpack_grid),
		"backpackContainerInstanceId": _instance_id(backpack_container),
		"backpackPanelCombinedMinWidth": _combined_min_width(backpack),
		"backpackEngineBoxWidth": _control_width(backpack_engine_box),
		"backpackEngineBoxHeight": _control_height(backpack_engine_box),
		"backpackGridWidth": backpack_grid_width,
		"backpackGridHeight": backpack_grid_height,
		"backpackGridAspect": _safe_ratio(backpack_grid_width, backpack_grid_height),
		"backpackGridSizeFlagsHorizontal": _size_flags_horizontal(backpack_grid),
		"backpackGridCustomMinimumWidth": _custom_minimum_width(backpack_grid),
		"backpackGridCombinedMinWidth": _combined_min_width(backpack_grid),
		"backpackMarginLeft": float(backpack_margin.get_theme_constant("margin_left")) if backpack_margin != null else -1.0,
		"backpackMarginRight": float(backpack_margin.get_theme_constant("margin_right")) if backpack_margin != null else -1.0,
		"backpackContainerWidth": _control_width(backpack_container),
		"backpackContainerCustomMinimumWidth": _custom_minimum_width(backpack_container),
		"backpackContainerCombinedMinWidth": _combined_min_width(backpack_container),
		"backpackContainerRatio": float(backpack_container.get("ratio")) if backpack_container != null else 0.0,
		"backpackContainerFlagsH": _size_flags_horizontal(backpack_container),
		"backpackHostWidth": _control_width(backpack_host),
		"backpackHostCustomMinimumWidth": _custom_minimum_width(backpack_host),
		"backpackHostCombinedMinWidth": _combined_min_width(backpack_host),
		"backpackHostRatio": float(backpack_host.get("ratio")) if backpack_host != null else 0.0,
		"topContentWidth": _control_width(top_content),
		"topContentHeight": _control_height(top_content),
		"topContentCustomMinimumHeight": _custom_minimum_height(top_content),
		"sharedBackpackLayoutSyncPending": bool(main_instance.get("_shared_backpack_layout_sync_pending")),
		"pinShellActive": bool(backpack.get("pin_shell_active")) if backpack != null else false,
		"pinLayoutQueued": bool(backpack.get("pin_layout_queued")) if backpack != null else false,
		"pinLayoutRetryBudget": int(backpack.get("pin_layout_retry_budget")) if backpack != null else -1,
		"pinLiveLayoutRetryBudget": int(backpack.get("pin_live_layout_retry_budget")) if backpack != null else -1,
		"artifactImageRefreshQueued": bool(backpack.get("artifact_image_refresh_queued")) if backpack != null else false,
		"artifactImageRefreshRetryBudget": int(backpack.get("artifact_image_refresh_retry_budget")) if backpack != null else -1,
		"backpackPixelWidth": float(backpack_pixels.get("width", 0)),
		"backpackPixelLeft": float(backpack_pixels.get("left", -1)),
		"backpackPixelRight": float(backpack_pixels.get("right", -1)),
		"backpackGridPixelWidth": backpack_grid_pixel_width,
		"backpackGridPixelHeight": backpack_grid_pixel_height,
		"backpackGridPixelAspect": _safe_ratio(backpack_grid_pixel_width, backpack_grid_pixel_height),
		"backpackGridPixelLeft": float(backpack_grid_pixels.get("left", -1)),
		"backpackGridPixelRight": float(backpack_grid_pixels.get("right", -1))
	}

func _significant_pixel_bounds(image: Image, rect: Rect2i) -> Dictionary:
	var image_rect := Rect2i(Vector2i.ZERO, image.get_size())
	var crop := rect.intersection(image_rect)
	if crop.size.x <= 0 or crop.size.y <= 0:
		return {"left": -1, "right": -1, "top": -1, "bottom": -1, "width": 0, "height": 0}
	var left := crop.position.x + crop.size.x
	var right := crop.position.x - 1
	var top := crop.position.y + crop.size.y
	var bottom := crop.position.y - 1
	for y in range(crop.position.y, crop.position.y + crop.size.y):
		for x in range(crop.position.x, crop.position.x + crop.size.x):
			var color := image.get_pixel(x, y)
			var luma := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
			if color.a > 0.05 and (luma > 0.20 or color.r > 0.42 or color.g > 0.42 or color.b > 0.42):
				left = mini(left, x)
				right = maxi(right, x)
				top = mini(top, y)
				bottom = maxi(bottom, y)
	if right < left:
		return {"left": -1, "right": -1, "top": -1, "bottom": -1, "width": 0, "height": 0}
	return {"left": left, "right": right, "top": top, "bottom": bottom, "width": right - left + 1, "height": bottom - top + 1}

func _summarize(records: Array[Dictionary]) -> Dictionary:
	return {
		"frames": records.size(),
		"battleRootRange": _range(records, "battleRootWidth"),
		"battlePanelShellRange": _range(records, "battlePanelShellWidth"),
		"battleBackdropDrawnRange": _range(records, "battleBackdropDrawnWidth"),
		"battleBackdropDrawnTurns": _direction_changes(records, "battleBackdropDrawnWidth"),
		"battleBackdropScaleRange": _range(records, "battleBackdropScaleX"),
		"battlefieldGridRange": _range(records, "battlefieldGridWidth"),
		"battlefieldPixelRange": _range(records, "battlefieldPixelWidth"),
		"battlefieldPixelTurns": _direction_changes(records, "battlefieldPixelWidth"),
		"backpackPanelRange": _range(records, "backpackPanelWidth"),
		"backpackGridRange": _range(records, "backpackGridWidth"),
		"backpackGridHeightRange": _range(records, "backpackGridHeight"),
		"backpackGridAspectMaxDelta": _max_abs_delta_from(records, "backpackGridAspect", 1.0),
		"backpackGridWidthShortfallMax": _max_positive_delta(records, "backpackGridHeight", "backpackGridWidth"),
		"backpackGridTurns": _direction_changes(records, "backpackGridWidth"),
		"backpackMarginLeftRange": _range(records, "backpackMarginLeft"),
		"backpackMarginRightRange": _range(records, "backpackMarginRight"),
		"backpackMarginLeftTurns": _direction_changes(records, "backpackMarginLeft"),
		"backpackPixelRange": _range(records, "backpackPixelWidth"),
		"backpackPixelTurns": _direction_changes(records, "backpackPixelWidth"),
		"backpackGridPixelRange": _range(records, "backpackGridPixelWidth"),
		"backpackGridPixelHeightRange": _range(records, "backpackGridPixelHeight"),
		"backpackGridPixelAspectMaxDelta": _max_abs_delta_from(records, "backpackGridPixelAspect", 1.0),
		"backpackGridPixelWidthShortfallMax": _max_positive_delta(records, "backpackGridPixelHeight", "backpackGridPixelWidth"),
		"backpackGridPixelTurns": _direction_changes(records, "backpackGridPixelWidth")
	}

func _range(records: Array[Dictionary], key: String) -> float:
	if records.is_empty():
		return 0.0
	var min_value := INF
	var max_value := -INF
	for record in records:
		var value := float(record.get(key, 0.0))
		min_value = minf(min_value, value)
		max_value = maxf(max_value, value)
	return max_value - min_value

func _direction_changes(records: Array[Dictionary], key: String) -> int:
	var previous_delta := 0
	var previous_value := NAN
	var turns := 0
	for record in records:
		var value := float(record.get(key, 0.0))
		if is_nan(previous_value):
			previous_value = value
			continue
		var delta := 0
		if value > previous_value + 0.25:
			delta = 1
		elif value < previous_value - 0.25:
			delta = -1
		if delta != 0 and previous_delta != 0 and delta != previous_delta:
			turns += 1
		if delta != 0:
			previous_delta = delta
		previous_value = value
	return turns

func _max_abs_delta_from(records: Array[Dictionary], key: String, target: float) -> float:
	var max_delta := 0.0
	for record in records:
		var value := float(record.get(key, target))
		if value <= 0.0:
			continue
		max_delta = maxf(max_delta, absf(value - target))
	return max_delta

func _max_positive_delta(records: Array[Dictionary], minuend_key: String, subtrahend_key: String) -> float:
	var max_delta := 0.0
	for record in records:
		max_delta = maxf(max_delta, float(record.get(minuend_key, 0.0)) - float(record.get(subtrahend_key, 0.0)))
	return max_delta

func _global_rect(control: Control) -> Rect2i:
	if control == null:
		return Rect2i()
	var rect := Rect2(control.global_position, control.size)
	return Rect2i(Vector2i(floori(rect.position.x), floori(rect.position.y)), Vector2i(ceili(rect.size.x), ceili(rect.size.y)))

func _control_width(control: Control) -> float:
	return 0.0 if control == null else float(control.size.x)

func _control_height(control: Control) -> float:
	return 0.0 if control == null else float(control.size.y)

func _custom_minimum_width(control: Control) -> float:
	return 0.0 if control == null else float(control.custom_minimum_size.x)

func _custom_minimum_height(control: Control) -> float:
	return 0.0 if control == null else float(control.custom_minimum_size.y)

func _combined_min_width(control: Control) -> float:
	return 0.0 if control == null else float(control.get_combined_minimum_size().x)

func _size_flags_horizontal(control: Control) -> int:
	return -1 if control == null else int(control.size_flags_horizontal)

func _instance_id(node) -> int:
	var object := node as Object
	return 0 if object == null else int(object.get_instance_id())

func _scale_x(control: Control) -> float:
	return 0.0 if control == null else float(control.scale.x)

func _drawn_width(control: Control) -> float:
	if control == null:
		return 0.0
	return float(control.size.x) * absf(float(control.scale.x))

func _safe_ratio(numerator: float, denominator: float) -> float:
	return 0.0 if denominator <= 0.0 else numerator / denominator

func _node_or_null(root_node, path: String) -> Node:
	var node := root_node as Node
	if node == null:
		return null
	return node.get_node_or_null(path)

func _save_image(image: Image, output_dir: String, frame: int) -> void:
	var dir_path := ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(dir_path)
	var path := "%s/frame_%04d.png" % [dir_path, frame]
	var err := image.save_png(path)
	if err != OK:
		_fail("failed to save screenshot %s: %s" % [path, str(err)])

func _go_to_battle(main_instance: Node) -> bool:
	if not await _go_to_node_select(main_instance):
		return false
	_press_current_node(main_instance, 0, "battle visual width probe")
	await _settle_frames(2)
	var start_button = main_instance.get("start_button")
	if start_button == null:
		_fail("start button missing before battle visual width probe")
		return false
	start_button.pressed.emit()
	await _settle_frames(12)
	return _expect_active(main_instance, "battle", "battle visual width probe")

func _go_to_node_select(main_instance: Node) -> bool:
	var character_page = main_instance.get("character_select_page")
	if character_page == null:
		_fail("character page missing")
		return false
	character_page.color_selected.emit("purple")
	character_page.continue_requested.emit()
	await _settle_frames(4)
	await _skip_story_scene_if_active(main_instance)
	await _settle_frames(2)
	if not _expect_active(main_instance, "leviathan_select", "leviathan_select"):
		return false
	var leviathan_page = main_instance.get("leviathan_select_page")
	if leviathan_page == null:
		_fail("leviathan page missing")
		return false
	leviathan_page.leviathan_selected.emit("storm_wyvern")
	leviathan_page.start_requested.emit()
	await _settle_frames(5)
	await _skip_story_scene_if_active(main_instance)
	await _settle_frames(2)
	return _expect_active(main_instance, "node_select", "node_select")

func _skip_story_scene_if_active(main_instance: Node) -> void:
	if str(main_instance.get("active_page_id")) != "story_scene":
		return
	var story_page = main_instance.get("story_scene_page")
	if story_page == null:
		_fail("story scene page missing while story_scene is active")
		return
	if story_page.has_method("_handle_skip_pressed"):
		story_page.call("_handle_skip_pressed")
		await _settle_frames(6)
		return
	var scene_id := str(story_page.get("_scene_id"))
	if story_page.has_signal("skip_requested"):
		story_page.skip_requested.emit(scene_id)
	await _settle_frames(6)

func _dismiss_narrative_if_active(main_instance: Node) -> void:
	var toast = main_instance.get("narrative_toast")
	if toast != null and bool(toast.get("visible")) and toast.has_method("dismiss"):
		toast.call("dismiss", false)
		await _settle_frames(4)
		return
	var controller := main_instance.get_node_or_null("MainController")
	if controller == null:
		return
	var model: Dictionary = controller.get("active_narrative_model")
	if bool(model.get("visible", false)) and controller.has_method("_on_narrative_continue_requested"):
		controller.call("_on_narrative_continue_requested", str(model.get("beatId", "")))
		await _settle_frames(4)

func _press_current_node(main_instance: Node, preferred_route_index: int, label: String) -> void:
	var controller = main_instance.get_node_or_null("MainController")
	var page_scenes: Dictionary = main_instance.get("page_scenes")
	var node_select_page = page_scenes.get("node_select", null)
	if node_select_page == null:
		_fail("node select page missing for %s" % label)
		return
	var route_count := int(node_select_page.call("route_button_count")) if node_select_page.has_method("route_button_count") else 0
	if route_count > 0:
		if node_select_page.has_method("press_route_button"):
			node_select_page.call("press_route_button", clampi(preferred_route_index, 0, route_count - 1))
		else:
			_fail("node select page lacks route-button helper for %s" % label)
		return
	var current_scene: Dictionary = controller.get("current_scene") if controller != null else {}
	if bool(current_scene.get("nodeSelect", {}).get("isBossStage", false)):
		if node_select_page.has_method("press_boss_marker"):
			node_select_page.call("press_boss_marker")
		else:
			_fail("node select page lacks boss-marker helper for %s" % label)
		return
	if node_select_page.has_method("press_start_marker"):
		node_select_page.call("press_start_marker")
	else:
		_fail("node select page lacks start-marker helper for %s" % label)

func _expect_active(main_instance: Node, expected: String, label: String) -> bool:
	var active := str(main_instance.get("active_page_id"))
	if active != expected:
		_fail("%s expected active page %s, got %s" % [label, expected, active])
		return false
	return true

func _parse_viewport(raw: String) -> Vector2i:
	var parts := raw.split("x")
	if parts.size() != 2:
		return DEFAULT_VIEWPORT_SIZE
	return Vector2i(maxi(1, int(parts[0])), maxi(1, int(parts[1])))

func _arg_value(prefix: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix + "="):
			return arg.substr(prefix.length() + 1)
	return fallback

func _settle_frames(count: int) -> void:
	for _index in range(count):
		await process_frame

func _fail(message: String) -> void:
	failures.append(message)
	push_error(message)

func _finish(code: int) -> void:
	call_deferred("quit", code)
