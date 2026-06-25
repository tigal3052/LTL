# 怨꾩빟:
# - Responsibility: orchestrate node-select roadmap rebuilds and interactive marker composition.
# - Input: a NodeSelectRuntimePage owner exposing current state, layers, helpers, and signal callbacks.
# - Output: rebuilt roadmap layers, route buttons, hover hotspots, panel models, and default panel state.
# - Prohibited: changing gameplay phase state beyond the existing owner selection callback contract.
#
# ?ㅽ뻾: define roadmap composition helpers for the node-select runtime page.
class_name NodeSelectRoadmapComposer
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const NodeSelectLayoutPolicyScript = preload("res://src/scenes/pages/node_select/NodeSelectLayoutPolicy.gd")
const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")

const ROUTE_RED := Color(0.82, 0.47, 0.40, 0.88)
const ROUTE_GOLD := Color(0.90, 0.74, 0.43, 0.96)
const ROUTE_FORECAST := Color(0.85, 0.73, 0.55, 0.24)
const ROUTE_MUTED := Color(0.62, 0.54, 0.44, 0.18)

# ?ㅽ뻾: rebuild the roadmap canvas for the supplied runtime page owner.
static func rebuild_canvas(page) -> void:
	page._canvas_layout_pending = false
	if not page.is_inside_tree():
		return
	if page.roadmap_canvas.size.x <= 1.0 or page.roadmap_canvas.size.y <= 1.0:
		return

	page._clear_container(page.canvas_backdrop)
	page._clear_container(page.stage_ruler)
	page._clear_container(page.anatomy_backdrop)
	page._clear_container(page.route_layer)
	page._clear_container(page.node_layer)
	page._route_buttons.clear()
	page._panel_models.clear()
	page._history_hotspots.clear()
	page._future_hotspots.clear()
	page._start_hotspots.clear()
	page._boss_hotspots.clear()
	page._fixed_entry_hotspots.clear()

	page._layout_info_card()
	page._build_canvas_backdrop()
	page._build_stage_ruler()
	page._build_anatomy_backdrop()

	var stage_index: int = page._stage_index()
	var candidates: Array = page._candidates()
	var route_history: Array = page._route_history()
	var selected_index: int = page._selected_candidate_index(candidates.size())
	var start_pos := NodeSelectLayoutPolicyScript.start_position(page.roadmap_canvas.size)
	var boss_pos := NodeSelectLayoutPolicyScript.boss_position(page.roadmap_canvas.size)
	var fixed_stage: bool = page._is_fixed_stage()
	var boss_stage: bool = page._is_boss_stage()

	page._register_panel_model("start", TextCatalogScript.t("node_runtime.start_mark.name"), TextCatalogScript.t("node_runtime.start_mark.body"))
	page._register_panel_model("fixed", TextCatalogScript.t("node_runtime.fixed_entry.name"), TextCatalogScript.t("node_runtime.fixed_entry.body"))
	page._register_panel_model("future", TextCatalogScript.t("node_runtime.future.name"), TextCatalogScript.t("node_runtime.future.body"))
	page._register_panel_model("boss", TextCatalogScript.t("node_runtime.boss.name"), TextCatalogScript.t("node_runtime.boss.body"))

	if fixed_stage or route_history.is_empty():
		var start_selected: bool = fixed_stage and selected_index == 0
		var start_hotspot := add_hover_hotspot(
			page,
			"StartHotspot",
			start_pos,
			72.0,
			page._tone_palette("start"),
			"start",
			"start",
			start_selected,
			false,
			TextCatalogScript.t("node_runtime.start_mark.name")
		)
		if fixed_stage:
			start_hotspot.pressed.connect(func() -> void:
				page._toggle_node_selection(0, "start")
			)
		page._start_hotspots.append(start_hotspot)
	if fixed_stage:
		build_future_chain(page, start_pos)
		page._default_panel_key = "start"
	elif boss_stage:
		var history_anchor := build_history_chain(page, start_pos, route_history)
		page._add_dotted_route("HistoryToBoss", history_anchor, boss_pos, ROUTE_RED, 5.2, 0.10, 0.78)
		page._add_forecast_route("HistoryToBossSelected", history_anchor, boss_pos, ROUTE_GOLD, 3.4, 0.08)
		page._default_panel_key = "boss"
	else:
		var history_anchor := build_history_chain(page, start_pos, route_history)
		var route_centers: Array = page._current_route_positions(stage_index, candidates.size())
		for index in range(candidates.size()):
			var candidate: Dictionary = candidates[index]
			var center: Vector2 = route_centers[index]
			var panel_key := "route_%d" % index
			page._register_panel_model(panel_key, TextCatalogScript.display_name(str(candidate.get("label", candidate.get("id", "?")))), page._candidate_description(candidate))
			page._add_dotted_route("PastRoute%d" % index, history_anchor, center, ROUTE_RED, 4.8, -0.12 + (0.08 * float(index)), 0.86)
			if index == selected_index:
				page._add_forecast_route("SelectedRoute%d" % index, history_anchor, center, ROUTE_GOLD, 3.2, -0.08 + (0.05 * float(index)))
			var route_button := create_route_button(page, index, candidate, center, index == selected_index, panel_key)
			page.node_layer.add_child(route_button)
			page._route_buttons.append(route_button)
		var selected_route_center: Vector2 = route_centers[selected_index] if selected_index >= 0 and selected_index < route_centers.size() else history_anchor
		build_future_chain(page, selected_route_center)
		page._add_ghost_route("SelectedRouteToBoss", selected_route_center, boss_pos, ROUTE_MUTED, 2.8, 0.12)
		page._default_panel_key = "route_%d" % selected_index if selected_index >= 0 and not candidates.is_empty() else page._unselected_default_panel_key()
	var boss_selected: bool = boss_stage and selected_index == 0
	var boss_palette: Dictionary = page._tone_palette("boss") if boss_stage else page._muted_palette(page._tone_palette("boss"))
	var boss_hotspot := add_hover_hotspot(page, "BossHotspot", boss_pos, 82.0, boss_palette, "boss", "boss", boss_selected, false, TextCatalogScript.t("node_runtime.boss.name"), "Boss Core")
	if boss_stage:
		boss_hotspot.pressed.connect(func() -> void:
			page._toggle_node_selection(0, "boss")
		)
	page._boss_hotspots.append(boss_hotspot)
	page._show_panel(page._default_panel_key)

# ?ㅽ뻾: build the cleared route-history marker chain.
static func build_history_chain(page, start_pos: Vector2, route_history: Array) -> Vector2:
	if route_history.is_empty():
		return start_pos
	var previous_point := start_pos
	var last_point := start_pos
	for history_index in range(route_history.size()):
		var entry: Dictionary = route_history[history_index]
		var stage_slot: Vector2 = page._history_position_for_entry(entry)
		if history_index > 0:
			page._add_dotted_route("HistoryPath%d" % history_index, previous_point, stage_slot, ROUTE_RED, 4.8, 0.08, 0.84)
			page._add_forecast_route("HistoryPathSelected%d" % history_index, previous_point, stage_slot, ROUTE_GOLD, 3.0, 0.06)
		var panel_key := "history_%d" % history_index
		page._register_panel_model(panel_key, page._history_entry_name(entry), page._history_entry_body(entry))
		var history_palette: Dictionary = page._muted_palette(page._tone_palette("start") if int(entry.get("stageIndex", -1)) == 0 else page._candidate_palette(entry))
		var hotspot := add_hover_hotspot(
			page,
			"HistoryHotspot%d" % history_index,
			stage_slot,
			70.0 if int(entry.get("stageIndex", -1)) == 0 else 64.0,
			history_palette,
			page._history_entry_icon_kind(entry),
			panel_key,
			false,
			false,
			page._history_entry_name(entry),
			"?꾨즺"
		)
		page._history_hotspots.append(hotspot)
		var history_sub_label := hotspot.get_node_or_null("SubLabel") as Label
		if history_sub_label != null:
			history_sub_label.text = "Cleared"
		if int(entry.get("stageIndex", -1)) == 0:
			page._start_hotspots.append(hotspot)
		previous_point = stage_slot
		last_point = stage_slot
	return last_point

# ?ㅽ뻾: build preview markers from the current anchor toward the boss route.
static func build_future_chain(page, from_point: Vector2) -> void:
	var future_positions: Array = page._future_slot_positions()
	var previous_point := from_point
	for future_index in range(future_positions.size()):
		var marker_point: Vector2 = future_positions[future_index]
		var line_name := "FutureRoute%d" % future_index
		if future_index == 0:
			page._add_forecast_route(line_name, previous_point, marker_point, ROUTE_FORECAST, 2.6, -0.14 + (0.06 * future_index))
		else:
			page._add_ghost_route(line_name, previous_point, marker_point, ROUTE_MUTED, 2.2, -0.14 + (0.06 * future_index))
		var hotspot := add_hover_hotspot(
			page,
			"FuturePreviewHotspot%d" % future_index,
			marker_point,
			58.0,
			page._tone_palette("future"),
			"future",
			"future",
			false,
			true,
			TextCatalogScript.t("node_runtime.future.name")
		)
		if future_index == 0:
			hotspot.name = "FuturePreviewHotspot"
		page._future_hotspots.append(hotspot)
		previous_point = marker_point
	if not page._is_boss_stage():
		page._add_ghost_route("FutureToBoss", previous_point, NodeSelectLayoutPolicyScript.boss_reference_position(page.roadmap_canvas.size), ROUTE_MUTED, 2.2, 0.16)

# ?ㅽ뻾: create a selectable current-route button.
static func create_route_button(page, index: int, candidate: Dictionary, center: Vector2, selected: bool, panel_key: String) -> Button:
	var button := Button.new()
	button.name = "RouteButton%d" % index
	button.text = ""
	button.focus_mode = Control.FOCUS_CLICK
	button.flat = true
	button.clip_contents = false
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = page._candidate_tooltip(candidate)
	button.set_meta(InteractionFXScript.META_SFX_CATEGORY, "ui_toggle")
	var size := 82.0 if selected else 74.0
	center = page._clamp_canvas_point(center, size * 0.5, NodeSelectLayoutPolicyScript.HOTSPOT_TAG_DEPTH)
	button.custom_minimum_size = Vector2(size, size)
	button.size = Vector2(size, size)
	button.position = center - (button.size * 0.5)
	var clear_style: StyleBoxFlat = page._transparent_button_style()
	button.add_theme_stylebox_override("normal", clear_style)
	button.add_theme_stylebox_override("hover", clear_style)
	button.add_theme_stylebox_override("pressed", clear_style)
	button.add_theme_stylebox_override("focus", clear_style)
	var icon_kind: String = page._candidate_icon_kind(candidate)
	var palette: Dictionary = page._candidate_palette(candidate)
	var visual_palette: Dictionary = palette if selected else page._muted_palette(palette)
	button.set_meta("icon_kind", icon_kind)
	button.set_meta("active_palette", palette.duplicate(true))
	button.set_meta("palette", visual_palette.duplicate(true))
	button.set_meta("selected_visual", selected)
	page._attach_hotspot_visual(button, visual_palette, icon_kind, selected, false, false)
	page._bind_hover_panel(button, panel_key)
	page._attach_hotspot_tag(button, TextCatalogScript.display_name(str(candidate.get("label", candidate.get("id", "?")))))
	button.mouse_entered.connect(func() -> void:
		page._refresh_hotspot_visual(button, true)
	)
	button.mouse_exited.connect(func() -> void:
		page._refresh_hotspot_visual(button, false)
	)
	button.focus_entered.connect(func() -> void:
		page._refresh_hotspot_visual(button, true)
	)
	button.focus_exited.connect(func() -> void:
		page._refresh_hotspot_visual(button, false)
	)
	button.pressed.connect(func(route_index := index) -> void:
		page._toggle_node_selection(route_index, "route_%d" % route_index)
	)
	return button

# ?ㅽ뻾: create a hoverable non-current marker and add it to the node layer.
static func add_hover_hotspot(page, node_name: String, center: Vector2, size: float, palette: Dictionary, glyph: String, panel_key: String, selected := false, preview := false, tag_text := "", sub_text := "") -> Button:
	var hotspot := Button.new()
	hotspot.name = node_name
	hotspot.text = ""
	hotspot.focus_mode = Control.FOCUS_CLICK
	hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hotspot.flat = true
	hotspot.clip_contents = false
	hotspot.set_meta(InteractionFXScript.META_SFX_CATEGORY, "ui_toggle")
	center = page._clamp_canvas_point(center, size * 0.5, NodeSelectLayoutPolicyScript.HOTSPOT_TAG_DEPTH if not preview else 44.0)
	hotspot.custom_minimum_size = Vector2(size, size)
	hotspot.size = Vector2(size, size)
	hotspot.position = center - (hotspot.size * 0.5)
	hotspot.add_theme_font_size_override("font_size", 26 if size < 70.0 else 30)
	hotspot.add_theme_color_override("font_color", Color(0.96, 0.90, 0.82, 1.0))
	hotspot.set_meta("icon_kind", "future" if preview else glyph)
	hotspot.set_meta("palette", palette.duplicate(true))
	hotspot.set_meta("selected_visual", selected)
	var clear_style: StyleBoxFlat = page._transparent_button_style()
	hotspot.add_theme_stylebox_override("normal", clear_style)
	hotspot.add_theme_stylebox_override("hover", clear_style)
	hotspot.add_theme_stylebox_override("focus", clear_style)
	hotspot.add_theme_stylebox_override("pressed", clear_style)
	page._attach_hotspot_visual(hotspot, palette, glyph, selected, preview, false)
	page._bind_hover_panel(hotspot, panel_key)
	page._attach_hotspot_tag(hotspot, tag_text, sub_text, preview)
	hotspot.mouse_entered.connect(func() -> void:
		page._refresh_hotspot_visual(hotspot, true)
	)
	hotspot.mouse_exited.connect(func() -> void:
		page._refresh_hotspot_visual(hotspot, false)
	)
	hotspot.focus_entered.connect(func() -> void:
		page._refresh_hotspot_visual(hotspot, true)
	)
	hotspot.focus_exited.connect(func() -> void:
		page._refresh_hotspot_visual(hotspot, false)
	)
	page.node_layer.add_child(hotspot)
	return hotspot
