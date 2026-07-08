extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const TOP_BAR_HEIGHT := 76.0
const WORKSPACE_TOP := 76.0
const TOP_BAR_MARGIN_LEFT := 24
const TOP_BAR_MARGIN_RIGHT := 22
const BRAND_FONT_SIZE := 20
const BUTTON_GAP := 14
const BUTTON_FONT_SIZE := 14
const BUTTON_FONT_WEIGHT := 800
const BUTTON_MIN_WIDTH := 108.0
const BUTTON_HEIGHT := 40.0
const BUTTON_PADDING_X := 14.0
const UNDERLINE_INSET := 14.0
const UNDERLINE_BOTTOM := 9.0
const UNDERLINE_SECONDARY_HEIGHT := 2.0
const UNDERLINE_ACTIVE_HEIGHT := 3.0
const ACTIVE_STOPS := [0.0, 0.2, 0.8, 1.0]

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	var main_scene := load("res://src/Main.tscn") as PackedScene
	_assert(main_scene != null, "main scene loads for top button style audit")
	if main_scene == null:
		_finish()
		return
	await _assert_style_contract(main_scene)
	_finish()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _assert_close(actual: float, expected: float, tolerance: float, label: String) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s: expected %.3f ± %.3f, got %.3f" % [label, expected, tolerance, actual])

func _assert_color_close(actual: Color, expected: Color, tolerance: float, label: String) -> void:
	if absf(actual.r - expected.r) > tolerance or absf(actual.g - expected.g) > tolerance or absf(actual.b - expected.b) > tolerance or absf(actual.a - expected.a) > tolerance:
		failures.append("%s: expected %s ± %.3f, got %s" % [label, str(expected), tolerance, str(actual)])

func _find_variant05_underline(button: Button, role: String) -> CanvasItem:
	for child in button.get_children():
		if child is CanvasItem and str(child.get_meta("variant05_underline_role", "")) == role:
			return child as CanvasItem
	return null

func _finish() -> void:
	if failures.is_empty():
		print("LEVIATHAN_TOP_BUTTON_STYLE_AUDIT_OK")
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
	_assert(story_page != null, "story scene exists during top button style audit")
	_assert(controller != null, "main controller exists during top button style audit story handoff")
	if story_page == null or controller == null:
		return
	var story: Dictionary = controller.get("active_story_scene")
	var scene_id := str(story.get("id", ""))
	_assert(scene_id != "", "story scene exposes a scene id during top button style audit")
	if scene_id.is_empty():
		return
	story_page.continue_requested.emit(scene_id)
	await process_frame
	story_page.continue_requested.emit(scene_id)
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), return_page_id, "story scene returns to %s for top button style audit" % return_page_id)

func _instantiate_main(main_scene: PackedScene) -> Node:
	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	return main_instance

func _go_to_leviathan_select(main_instance: Node) -> Node:
	await _advance_story_if_present(main_instance, "character_select")
	var character_page = main_instance.get("character_select_page")
	_assert(character_page != null, "character select page exists before top button style audit")
	if character_page == null:
		return null
	character_page.color_selected.emit("purple")
	character_page.continue_requested.emit()
	await process_frame
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "leviathan_select", "character select advances to leviathan select for top button style audit")
	return main_instance.get("leviathan_select_page")

func _assert_style_contract(main_scene: PackedScene) -> void:
	var main_instance := await _instantiate_main(main_scene)
	var page = await _go_to_leviathan_select(main_instance)
	_assert(page != null, "leviathan select page exists for top button style audit")
	if page == null:
		main_instance.queue_free()
		await process_frame
		return
	await process_frame
	await process_frame
	var top_bar := page.get_node_or_null("TopBar") as Control
	var top_bar_margin := page.get_node_or_null("TopBar/TopBarMargin") as MarginContainer
	var workspace_margin := page.get_node_or_null("WorkspaceMargin") as MarginContainer
	var brand_label := page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/BrandLabel") as Label
	var tabs_row := page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow") as HBoxContainer
	var buttons: Array[Button] = [
		page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow/CharacterTabButton") as Button,
		page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow/LeviathanTabButton") as Button,
		page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow/CodexActionButton") as Button,
		page.get_node_or_null("TopBar/TopBarMargin/TopBarRow/BrandRow/TabsRow/SettingsActionButton") as Button,
	]
	_assert(top_bar != null and top_bar_margin != null and workspace_margin != null and brand_label != null and tabs_row != null, "top bar nodes exist for style audit")
	for button in buttons:
		_assert(button != null, "all four top buttons exist for style audit")
	if top_bar == null or top_bar_margin == null or workspace_margin == null or brand_label == null or tabs_row == null:
		main_instance.queue_free()
		await process_frame
		return
	_assert_close(top_bar.size.y, TOP_BAR_HEIGHT, 0.5, "top bar height matches Variant-05 header height")
	_assert_close(workspace_margin.offset_top, WORKSPACE_TOP, 0.5, "workspace top offset follows Variant-05 header height")
	_assert_eq(top_bar_margin.get_theme_constant("margin_left"), TOP_BAR_MARGIN_LEFT, "top bar left padding matches HTML mockup")
	_assert_eq(top_bar_margin.get_theme_constant("margin_right"), TOP_BAR_MARGIN_RIGHT, "top bar right padding matches HTML mockup")
	_assert_eq(brand_label.get_theme_font_size("font_size"), BRAND_FONT_SIZE, "brand label font size matches HTML mockup")
	_assert_color_close(brand_label.get_theme_color("font_color"), Color(39.0 / 255.0, 71.0 / 255.0, 54.0 / 255.0, 1.0), 0.015, "brand label color matches HTML mockup")
	_assert_eq(tabs_row.get_theme_constant("separation"), BUTTON_GAP, "top button gap matches HTML mockup")
	_assert_eq(tabs_row.get_child_count(), 4, "top button row keeps four buttons during style audit")
	var expected_names := ["CharacterTabButton", "LeviathanTabButton", "CodexActionButton", "SettingsActionButton"]
	for i in range(min(buttons.size(), expected_names.size())):
		var button := buttons[i]
		if button == null:
			continue
		_assert_eq(button.name, expected_names[i], "button order stays stable for style audit")
		_assert_eq(str(button.get_meta("kind", "")), "top_group", "%s keeps top_group kind" % button.name)
		_assert_eq(str(button.get_meta("design_spec", "")), "ui-issue-6-variant-05", "%s records its design-spec id" % button.name)
		_assert(not button.flat, "%s is not a plain flat text tab" % button.name)
		_assert_eq(button.get_theme_font_size("font_size"), BUTTON_FONT_SIZE, "%s font size matches HTML mockup" % button.name)
		var font_override := button.get_theme_font("font") as SystemFont
		_assert(font_override != null, "%s installs a dedicated top-group font override" % button.name)
		if font_override != null:
			_assert_eq(font_override.font_weight, BUTTON_FONT_WEIGHT, "%s font weight matches Variant-05 action text" % button.name)
		_assert_close(button.custom_minimum_size.x, BUTTON_MIN_WIDTH, 0.5, "%s min width matches HTML mockup" % button.name)
		_assert_close(button.custom_minimum_size.y, BUTTON_HEIGHT, 0.5, "%s height matches HTML mockup" % button.name)
		var style := button.get_theme_stylebox("normal") as StyleBoxFlat
		_assert(style != null, "%s normal stylebox exists for style audit" % button.name)
		if style != null:
			_assert_eq(style.border_width_left, 0, "%s has no box border left" % button.name)
			_assert_eq(style.border_width_top, 0, "%s has no box border top" % button.name)
			_assert_eq(style.border_width_right, 0, "%s has no box border right" % button.name)
			_assert_eq(style.border_width_bottom, 0, "%s underline is not implemented as full bottom border" % button.name)
			_assert_close(style.content_margin_left, BUTTON_PADDING_X, 0.5, "%s left padding matches HTML mockup" % button.name)
			_assert_close(style.content_margin_right, BUTTON_PADDING_X, 0.5, "%s right padding matches HTML mockup" % button.name)
		var expected_text := Color(39.0 / 255.0, 71.0 / 255.0, 54.0 / 255.0, 1.0 if button.name == "LeviathanTabButton" else 0.82)
		_assert_color_close(button.get_theme_color("font_color"), expected_text, 0.03, "%s text color/alpha matches Variant-05 role" % button.name)
		var inactive_track := _find_variant05_underline(button, "track") as ColorRect
		var active_fill := _find_variant05_underline(button, "active") as TextureRect
		if button.name == "LeviathanTabButton":
			_assert(active_fill != null, "%s exposes active underline texture node" % button.name)
			_assert(inactive_track == null, "%s does not keep inactive underline track while active" % button.name)
			if active_fill != null:
				_assert_close(active_fill.position.x, UNDERLINE_INSET, 0.5, "%s active underline left inset matches HTML mockup" % button.name)
				_assert_close(button.size.x - (active_fill.position.x + active_fill.size.x), UNDERLINE_INSET, 0.5, "%s active underline right inset matches HTML mockup" % button.name)
				_assert_close(active_fill.size.y, UNDERLINE_ACTIVE_HEIGHT, 0.5, "%s active underline height matches HTML mockup" % button.name)
				_assert_close(active_fill.position.y, button.size.y - UNDERLINE_BOTTOM - UNDERLINE_ACTIVE_HEIGHT, 0.6, "%s active underline bottom offset matches HTML mockup" % button.name)
				var gradient := (active_fill.texture as GradientTexture1D).gradient if active_fill.texture is GradientTexture1D else null
				_assert(gradient != null, "%s active underline uses a gradient texture" % button.name)
				if gradient != null:
					_assert_eq(gradient.offsets.size(), ACTIVE_STOPS.size(), "%s active underline stop count matches HTML mockup" % button.name)
					for stop_index in range(min(gradient.offsets.size(), ACTIVE_STOPS.size())):
						_assert_close(gradient.offsets[stop_index], ACTIVE_STOPS[stop_index], 0.01, "%s active underline stop %d matches HTML mockup" % [button.name, stop_index])
					if gradient.colors.size() == 4:
						_assert_color_close(gradient.colors[0], Color(0.0, 0.0, 0.0, 0.0), 0.02, "%s active underline start fades to transparent" % button.name)
						_assert_color_close(gradient.colors[1], Color(45.0 / 255.0, 95.0 / 255.0, 68.0 / 255.0, 0.88), 0.03, "%s active underline core color matches HTML mockup" % button.name)
						_assert_color_close(gradient.colors[2], Color(45.0 / 255.0, 95.0 / 255.0, 68.0 / 255.0, 0.88), 0.03, "%s active underline core color stays stable" % button.name)
						_assert_color_close(gradient.colors[3], Color(0.0, 0.0, 0.0, 0.0), 0.02, "%s active underline end fades to transparent" % button.name)
		else:
			_assert(active_fill == null, "%s does not use active underline texture while inactive" % button.name)
			_assert(inactive_track != null, "%s exposes inactive underline track" % button.name)
			if inactive_track != null:
				_assert_close(inactive_track.position.x, UNDERLINE_INSET, 0.5, "%s inactive underline left inset matches HTML mockup" % button.name)
				_assert_close(button.size.x - (inactive_track.position.x + inactive_track.size.x), UNDERLINE_INSET, 0.5, "%s inactive underline right inset matches HTML mockup" % button.name)
				_assert_close(inactive_track.size.y, UNDERLINE_SECONDARY_HEIGHT, 0.5, "%s inactive underline height matches HTML mockup" % button.name)
				_assert_close(inactive_track.position.y, button.size.y - UNDERLINE_BOTTOM - UNDERLINE_SECONDARY_HEIGHT, 0.6, "%s inactive underline bottom offset matches HTML mockup" % button.name)
				_assert_color_close(inactive_track.color, Color(37.0 / 255.0, 72.0 / 255.0, 53.0 / 255.0, 0.18), 0.03, "%s inactive underline color matches HTML mockup" % button.name)
	main_instance.queue_free()
	await process_frame
