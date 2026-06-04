# 怨꾩빟:
# - Responsibility: render supplied NodeMapReadModel data into a minimal Control surface.
# - Input: already-projected node-map model dictionary.
# - Output: visible labels and query helpers used by smoke tests.
# - Prohibited: node generation, phase reduction, direct runtime mutation.
#
# ?ㅽ뻾: define the NodeMapScene class identity.
class_name NodeMapScene
extends Control

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
signal node_selected(index: int)
signal color_selected(color: String)

const COLOR_BUTTON_MIN_SIZE := Vector2(108, 42)
const NODE_CARD_SIZE := Vector2(132, 82)
const START_MARKER_SIZE := Vector2(96, 40)
const MAP_CANVAS_FALLBACK_SIZE := Vector2(620, 260)
const MAP_CANVAS_MIN_HEIGHT := 260.0
const DETAIL_PANEL_MIN_HEIGHT := 260.0
const MAP_FRAME_VERTICAL_PADDING := 28.0
const TARGET_START_BOTTOM_GAP := 20.0

# ?ㅽ뻾: store render state and generated label nodes.
var _model: Dictionary = {}
var _root: VBoxContainer = null
var _header_panel: PanelContainer = null
var _summary_label: Label = null
var _summary_hint_label: Label = null
var _color_row: HBoxContainer = null
var _content_row: VBoxContainer = null
var _cards_container: Control = null
var _map_canvas: Control = null
var _detail_panel: PanelContainer = null
var _detail_label: RichTextLabel = null
var _map_lines: Array[ColorRect] = []
var _map_nodes: Array[Button] = []
var _color_buttons: Array[Button] = []
var _layout_refresh_pending := false
var _test_canvas_size := Vector2.ZERO

# ?ㅽ뻾: build child controls when the scene enters the tree.
func _ready() -> void:
	_ensure_children()
	if not _model.is_empty():
		render(_model)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and not _model.is_empty() and is_inside_tree() and not _layout_refresh_pending:
		_layout_refresh_pending = true
		call_deferred("_refresh_layout_after_resize")

# ?ㅽ뻾: render supplied read-model data without calling domain generators.
func render(model: Dictionary) -> void:
	_model = model.duplicate(true)
	_ensure_children()
	for child in _cards_container.get_children():
		_cards_container.remove_child(child)
		child.queue_free()
	for child in _color_row.get_children():
		_color_row.remove_child(child)
		child.queue_free()
	_map_nodes.clear()
	_map_lines.clear()
	_color_buttons.clear()
	var selected_color := str(model.get("selectedColor", "red"))
	var stage_text := str(model.get("stageText", "Node Map"))
	_color_row.visible = _allow_start_color_selection()
	if _color_row.visible:
		for color in model.get("loadoutColors", ["red", "blue", "purple", "green"]):
			var color_button := Button.new()
			color_button.text = _color_text(str(color), str(color) == selected_color)
			color_button.custom_minimum_size = COLOR_BUTTON_MIN_SIZE
			_apply_color_button_style(color_button, str(color), str(color) == selected_color)
			color_button.pressed.connect(func(c = str(color)): call_deferred("_emit_color_selected", c))
			_color_row.add_child(color_button)
			_color_buttons.append(color_button)
	var selected_detail := ""
	var cards: Array = model.get("cards", [])
	_build_map_scaffold(cards.size())
	for index in range(cards.size()):
		var card: Dictionary = cards[index]
		var line := _card_line(card)
		var selected := bool(card.get("selected", false))
		if selected:
			selected_detail = _detail_copy(card)
		var button := Button.new()
		button.text = _node_chip_text(card, selected)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = NODE_CARD_SIZE
		button.size = NODE_CARD_SIZE
		button.position = _candidate_position(index, cards.size(), button.size) - (button.size * 0.5)
		button.tooltip_text = line
		button.set_meta("selected", selected)
		_apply_node_button_style(button, card, selected)
		button.pressed.connect(func(idx = index): call_deferred("_emit_node_selected", idx))
		_cards_container.add_child(button)
		_map_nodes.append(button)
	_summary_label.text = "TACTICAL BRIEFING"
	_summary_hint_label.text = "%s  |  Selected Start Color: %s" % [stage_text, selected_color] if _color_row.visible else stage_text
	_detail_label.text = selected_detail if not selected_detail.is_empty() else stage_text

# ?ㅽ뻾: return the rendered card count for smoke tests.
func card_count() -> int:
	return _map_nodes.size()

# ??쎈뻬: return the rendered map node button count for smoke tests.
func map_node_count() -> int:
	return _map_nodes.size()

# ??쎈뻬: return the rendered start color button count for smoke tests.
func loadout_color_count() -> int:
	return _color_buttons.size()

func start_color_panel_instance_id() -> int:
	_ensure_children()
	return _color_row.get_instance_id() if _color_row != null else 0

func start_color_panel_visible() -> bool:
	return _color_row != null and _color_row.visible

# ?ㅽ뻾: return the current summary text for smoke tests.
# 신규: return the full-page layout root name for smoke tests.
func map_page_root_name() -> String:
	return _root.name if _root != null else ""

func map_canvas_name() -> String:
	return _map_canvas.name if _map_canvas != null else ""

func map_line_count() -> int:
	return _map_lines.size()

func core_marker_present() -> bool:
	return _cards_container != null and _cards_container.has_node("CORENode")

func node_buttons_overlap() -> bool:
	for first in range(_map_nodes.size()):
		for second in range(first + 1, _map_nodes.size()):
			if Rect2(_map_nodes[first].position, _map_nodes[first].size).intersects(Rect2(_map_nodes[second].position, _map_nodes[second].size)):
				return true
	return false

func node_visual_center_x() -> float:
	var centers := _node_visual_centers()
	if centers.is_empty():
		return 0.0
	var total := 0.0
	for center in centers:
		total += float(center.x)
	return total / float(centers.size())

func map_canvas_center_x() -> float:
	return _map_canvas_extent().x * 0.5

func map_canvas_width() -> float:
	return _map_canvas_extent().x

func node_leftmost_edge() -> float:
	if _map_nodes.is_empty():
		return 0.0
	var edge := INF
	for button in _map_nodes:
		edge = minf(edge, button.position.x)
	return edge

func node_rightmost_edge() -> float:
	if _map_nodes.is_empty():
		return 0.0
	var edge := -INF
	for button in _map_nodes:
		edge = maxf(edge, button.position.x + button.size.x)
	return edge

func map_canvas_min_height() -> float:
	return _map_canvas.custom_minimum_size.y if _map_canvas != null else 0.0

func detail_panel_min_height() -> float:
	return _detail_panel.custom_minimum_size.y if _detail_panel != null else 0.0

func start_marker_bottom_gap() -> float:
	if _cards_container == null:
		return 0.0
	var start_marker := _cards_container.get_node_or_null("STARTNode") as Control
	if start_marker == null:
		return 0.0
	return _map_canvas_extent().y - (start_marker.position.y + start_marker.size.y)

func set_map_canvas_test_size(canvas_size: Vector2) -> void:
	_test_canvas_size = canvas_size
	_ensure_children()
	_map_canvas.size = canvas_size

# 신규: return one rendered map-node button label for smoke tests.
func node_button_text(index: int) -> String:
	if index < 0 or index >= _map_nodes.size():
		return ""
	return _map_nodes[index].text

func node_button_selected_state(index: int) -> bool:
	if index < 0 or index >= _map_nodes.size():
		return false
	return bool(_map_nodes[index].get_meta("selected", false))

func press_color_button(index: int) -> void:
	if not _allow_start_color_selection():
		return
	if index < 0 or index >= _color_buttons.size():
		return
	_color_buttons[index].pressed.emit()

func press_node_button(index: int) -> void:
	if index < 0 or index >= _map_nodes.size():
		return
	_map_nodes[index].pressed.emit()

func summary_text() -> String:
	if _summary_label == null:
		return ""
	var parts := [_summary_label.text]
	if _summary_hint_label != null and not _summary_hint_label.text.is_empty():
		parts.append(_summary_hint_label.text)
	return "\n".join(parts)

# ??쎈뻬: return the selected route detail text for smoke tests.
func detail_text() -> String:
	if _detail_label == null:
		return ""
	return _detail_label.text

func rerender_current_model() -> void:
	if _model.is_empty():
		return
	render(_model)

func _refresh_layout_after_resize() -> void:
	_layout_refresh_pending = false
	if _model.is_empty():
		return
	render(_model)

# ?ㅽ뻾: ensure this scene has stable child controls even when instantiated from script.
func _ensure_children() -> void:
	if _root == null:
		_root = VBoxContainer.new()
		_root.name = "NodeMapPageRoot"
		_root.set_anchors_preset(Control.PRESET_FULL_RECT)
		_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_root.add_theme_constant_override("separation", 14)
		add_child(_root)
	if _header_panel == null:
		_header_panel = PanelContainer.new()
		_header_panel.add_theme_stylebox_override("panel", _surface_style(Color(0.11, 0.14, 0.18, 0.98), Color(0.28, 0.36, 0.44, 1.0)))
		_root.add_child(_header_panel)
		var header_margin := MarginContainer.new()
		header_margin.add_theme_constant_override("margin_left", 16)
		header_margin.add_theme_constant_override("margin_top", 14)
		header_margin.add_theme_constant_override("margin_right", 16)
		header_margin.add_theme_constant_override("margin_bottom", 14)
		_header_panel.add_child(header_margin)
		var header_box := VBoxContainer.new()
		header_box.add_theme_constant_override("separation", 6)
		header_margin.add_child(header_box)
		_summary_label = Label.new()
		_summary_label.name = "SummaryLabel"
		_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_summary_label.add_theme_font_size_override("font_size", 22)
		_summary_label.add_theme_color_override("font_color", Color(0.95, 0.97, 0.98))
		header_box.add_child(_summary_label)
		_summary_hint_label = Label.new()
		_summary_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_summary_hint_label.add_theme_font_size_override("font_size", 13)
		_summary_hint_label.add_theme_color_override("font_color", Color(0.70, 0.78, 0.84))
		header_box.add_child(_summary_hint_label)
	if _color_row == null:
		_color_row = HBoxContainer.new()
		_color_row.name = "StartColors"
		_color_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_color_row.alignment = BoxContainer.ALIGNMENT_CENTER
		_color_row.add_theme_constant_override("separation", 10)
		_root.add_child(_color_row)
	if _content_row == null:
		_content_row = VBoxContainer.new()
		_content_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_content_row.add_theme_constant_override("separation", 16)
		_root.add_child(_content_row)
	if _cards_container == null:
		var map_frame := PanelContainer.new()
		map_frame.add_theme_stylebox_override("panel", _surface_style(Color(0.08, 0.11, 0.14, 0.98), Color(0.19, 0.28, 0.36, 1.0)))
		map_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		map_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		map_frame.custom_minimum_size = Vector2(0, MAP_CANVAS_MIN_HEIGHT + MAP_FRAME_VERTICAL_PADDING)
		_content_row.add_child(map_frame)
		var map_margin := MarginContainer.new()
		map_margin.add_theme_constant_override("margin_left", 14)
		map_margin.add_theme_constant_override("margin_top", 14)
		map_margin.add_theme_constant_override("margin_right", 14)
		map_margin.add_theme_constant_override("margin_bottom", 14)
		map_frame.add_child(map_margin)
		_map_canvas = Control.new()
		_map_canvas.name = "RunMapCanvas"
		_map_canvas.custom_minimum_size = Vector2(0, MAP_CANVAS_MIN_HEIGHT)
		_map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_cards_container = _map_canvas
		_cards_container.name = "RunMapCanvas"
		_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_cards_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		map_margin.add_child(_cards_container)
	if _detail_label == null:
		_detail_panel = PanelContainer.new()
		_detail_panel.add_theme_stylebox_override("panel", _surface_style(Color(0.12, 0.15, 0.19, 0.98), Color(0.34, 0.41, 0.49, 1.0)))
		_detail_panel.custom_minimum_size = Vector2(0, DETAIL_PANEL_MIN_HEIGHT)
		_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_detail_panel.size_flags_stretch_ratio = 1.0
		_content_row.add_child(_detail_panel)
		var detail_margin := MarginContainer.new()
		detail_margin.add_theme_constant_override("margin_left", 14)
		detail_margin.add_theme_constant_override("margin_top", 14)
		detail_margin.add_theme_constant_override("margin_right", 14)
		detail_margin.add_theme_constant_override("margin_bottom", 14)
		_detail_panel.add_child(detail_margin)
		_detail_label = RichTextLabel.new()
		_detail_label.name = "DetailLabel"
		_detail_label.bbcode_enabled = true
		_detail_label.fit_content = false
		_detail_label.scroll_active = true
		_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		detail_margin.add_child(_detail_label)

# ?ㅽ뻾: format one node card line for the minimal route panel.
func _card_line(card: Dictionary) -> String:
	var selected_prefix := "* " if bool(card.get("selected", false)) else "- "
	var label := TextCatalogScript.display_name(str(card.get("label", "")))
	var weakness := str(card.get("weaknessLabel", ""))
	if weakness in ["red", "blue", "purple", "green"]:
		weakness = TextCatalogScript.t("color.%s" % weakness)
	var risk := TextCatalogScript.enum_label("risk", str(card.get("riskTier", "safe")))
	var reward := TextCatalogScript.enum_label("reward_bias", str(card.get("rewardBias", "baseline")))
	var hint := TextCatalogScript.hint_label(str(card.get("recommendedBuildHint", "")))
	var durability := int(round(float(card.get("totalDurability", float(card.get("shield", 0.0)) + float(card.get("health", 0.0))))))
	var durability_text := "Durability %d" % durability if durability > 0 else ""
	return "%s%s %s %s %s %s" % [
		selected_prefix,
		TextCatalogScript.t("node.card.base", [label, weakness, risk]),
		TextCatalogScript.t("node.card.reward", [reward]).strip_edges(),
		TextCatalogScript.t("node.card.hint", [hint]).strip_edges(),
		TextCatalogScript.t("node.final_distance", [int(card.get("finalStageDistance", 0))]),
		durability_text
	]

# ??쎈뻬: format a compact start color button label.
func _color_text(color: String, selected: bool) -> String:
	var label := TextCatalogScript.t("color.%s" % color) if color in ["red", "blue", "purple", "green"] else color
	return "[%s]" % label if selected else label

func _emit_color_selected(color: String) -> void:
	if not _allow_start_color_selection():
		return
	color_selected.emit(color)

func _emit_node_selected(index: int) -> void:
	node_selected.emit(index)

func _allow_start_color_selection() -> bool:
	return bool(_model.get("allowStartColorSelection", true))

func _build_map_scaffold(candidate_count: int) -> void:
	var canvas_size := _map_canvas_extent()
	var start_pos := Vector2(canvas_size.x * 0.50, canvas_size.y - (START_MARKER_SIZE.y * 0.5) - TARGET_START_BOTTOM_GAP)
	for index in range(candidate_count):
		var candidate_pos := _candidate_position(index, candidate_count, NODE_CARD_SIZE)
		_add_map_line(start_pos, candidate_pos, Color(0.45, 0.63, 0.71, 0.72), 4.0)
	_add_static_map_node("START", start_pos, Color(0.18, 0.48, 0.40, 0.96))

func _candidate_position(index: int, count: int, card_size: Vector2) -> Vector2:
	var safe_count := maxi(1, count)
	var canvas_size := _map_canvas_extent()
	if safe_count == 1:
		return Vector2(canvas_size.x * 0.50, canvas_size.y * 0.38)
	var normalized_points := {
		1: [Vector2(0.50, 0.34)],
		2: [Vector2(0.34, 0.34), Vector2(0.66, 0.34)],
		3: [Vector2(0.22, 0.38), Vector2(0.50, 0.24), Vector2(0.78, 0.38)],
		4: [Vector2(0.0, 0.0), Vector2(1.0, 0.0), Vector2(0.25, 0.82), Vector2(0.75, 0.82)],
		5: [Vector2(0.0, 0.0), Vector2(0.50, 0.0), Vector2(1.0, 0.0), Vector2(0.25, 0.82), Vector2(0.75, 0.82)]
	}
	var positions: Array = normalized_points.get(safe_count, [])
	var normalized := Vector2(0.50, 0.32)
	if index >= 0 and index < positions.size():
		normalized = positions[index]
	else:
		normalized = Vector2(float(index + 1) / float(safe_count + 1), 0.34)
	var inset_x := 18.0 + (card_size.x * 0.5)
	var inset_y := 16.0 + (card_size.y * 0.5)
	var x := lerpf(inset_x, maxf(inset_x, canvas_size.x - inset_x), normalized.x)
	var y := lerpf(inset_y, maxf(inset_y, canvas_size.y - inset_y - 44.0), normalized.y)
	return Vector2(x, y)

func _map_canvas_extent() -> Vector2:
	if _map_canvas == null:
		return MAP_CANVAS_FALLBACK_SIZE
	var width := _map_canvas.size.x
	if width <= 1.0:
		var map_parent := _map_canvas.get_parent() as Control
		if map_parent != null and map_parent.size.x > 1.0:
			width = map_parent.size.x
		elif size.x > 1.0:
			width = maxf(_map_canvas.custom_minimum_size.x, size.x - 28.0)
		else:
			width = maxf(_map_canvas.custom_minimum_size.x, MAP_CANVAS_FALLBACK_SIZE.x)
	if _test_canvas_size.x > 1.0:
		width = _test_canvas_size.x
	var height := _map_canvas.size.y
	if height <= 1.0:
		var map_parent_height := _map_canvas.get_parent() as Control
		if map_parent_height != null and map_parent_height.size.y > 1.0:
			height = map_parent_height.size.y
		else:
			height = maxf(_map_canvas.custom_minimum_size.y, MAP_CANVAS_FALLBACK_SIZE.y)
	if _test_canvas_size.y > 1.0:
		height = _test_canvas_size.y
	return Vector2(width, height)

func _node_visual_centers() -> Array[Vector2]:
	var centers: Array[Vector2] = []
	for button in _map_nodes:
		centers.append(button.position + (button.size * 0.5))
	var start_marker := _cards_container.get_node_or_null("STARTNode") as Control
	if start_marker != null:
		centers.append(start_marker.position + (start_marker.size * 0.5))
	return centers

func _add_map_line(start_pos: Vector2, end_pos: Vector2, color: Color, thickness: float) -> void:
	var delta := end_pos - start_pos
	var line := ColorRect.new()
	line.name = "RouteLine"
	line.color = color
	line.position = start_pos
	line.size = Vector2(maxf(1.0, delta.length()), thickness)
	line.pivot_offset = Vector2(0.0, thickness * 0.5)
	line.rotation = atan2(delta.y, delta.x)
	_cards_container.add_child(line)
	_map_lines.append(line)

func _add_static_map_node(label: String, center: Vector2, color: Color) -> void:
	var marker := PanelContainer.new()
	marker.name = "%sNode" % label
	marker.position = center - (START_MARKER_SIZE * 0.5)
	marker.size = START_MARKER_SIZE
	marker.self_modulate = color
	marker.add_theme_stylebox_override("panel", _marker_style())
	var text := Label.new()
	text.text = label
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 16)
	text.add_theme_color_override("font_color", Color(0.96, 0.97, 0.98))
	marker.add_child(text)
	_cards_container.add_child(marker)

func _node_chip_text(card: Dictionary, selected: bool) -> String:
	var icon := _risk_icon(str(card.get("riskTier", "safe")))
	var label := TextCatalogScript.display_name(str(card.get("label", "")))
	var durability := int(round(float(card.get("totalDurability", float(card.get("shield", 0.0)) + float(card.get("health", 0.0))))))
	var suffix := "\n%d" % durability if durability > 0 else ""
	var prefix := ">" if selected else icon
	return "%s\n%s%s" % [prefix, label, suffix]

func _risk_icon(risk: String) -> String:
	match risk:
		"danger":
			return "!"
		"hard":
			return "!!"
		"unknown":
			return "?"
		"medium":
			return "+"
		_:
			return "o"

func _detail_copy(card: Dictionary) -> String:
	var risk := TextCatalogScript.enum_label("risk", str(card.get("riskTier", "safe")))
	var reward := TextCatalogScript.enum_label("reward_bias", str(card.get("rewardBias", "baseline")))
	var weakness := str(card.get("weaknessLabel", ""))
	if weakness in ["red", "blue", "purple", "green"]:
		weakness = TextCatalogScript.t("color.%s" % weakness)
	var hint := TextCatalogScript.hint_label(str(card.get("recommendedBuildHint", "")))
	return "[b]%s[/b]\n\nRisk  %s\nWeakness  %s\nReward Bias  %s\nDurability  %d\nBoss Distance  %d\n\n%s" % [
		str(card.get("label", "")),
		risk,
		weakness if not weakness.is_empty() else "-",
		reward,
		int(round(float(card.get("totalDurability", 0.0)))),
		int(card.get("finalStageDistance", 0)),
		hint
	]

func _apply_color_button_style(button: Button, color_name: String, selected: bool) -> void:
	var base := _surface_style(Color(0.13, 0.16, 0.20, 0.98), Color(0.24, 0.31, 0.38, 1.0))
	base.corner_radius_top_left = 16
	base.corner_radius_top_right = 16
	base.corner_radius_bottom_right = 16
	base.corner_radius_bottom_left = 16
	var active_border := _energy_color(color_name)
	if selected:
		base.border_width_left = 2
		base.border_width_top = 2
		base.border_width_right = 2
		base.border_width_bottom = 2
		base.border_color = active_border
	button.add_theme_stylebox_override("normal", base)
	button.add_theme_stylebox_override("hover", base)
	button.add_theme_stylebox_override("pressed", base)
	button.add_theme_stylebox_override("focus", base)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color(0.95, 0.97, 0.98))

func _apply_node_button_style(button: Button, card: Dictionary, selected: bool) -> void:
	var risk := str(card.get("riskTier", "safe"))
	var normal := _surface_style(Color(0.12, 0.15, 0.19, 0.94), _risk_color(risk))
	normal.corner_radius_top_left = 14
	normal.corner_radius_top_right = 14
	normal.corner_radius_bottom_right = 14
	normal.corner_radius_bottom_left = 14
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	if selected:
		normal.bg_color = Color(0.20, 0.18, 0.12, 0.98)
		normal.border_width_left = 2
		normal.border_width_top = 2
		normal.border_width_right = 2
		normal.border_width_bottom = 2
		normal.border_color = Color(0.92, 0.82, 0.48, 1.0)
	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.08)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", normal)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color(0.95, 0.97, 0.98))

func _surface_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)
	return style

func _marker_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.13, 0.96)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.44, 0.57, 0.66, 0.92)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	return style

func _risk_color(risk: String) -> Color:
	match risk:
		"danger":
			return Color(0.77, 0.34, 0.34, 1.0)
		"hard":
			return Color(0.85, 0.66, 0.34, 1.0)
		"unknown":
			return Color(0.58, 0.55, 0.78, 1.0)
		"medium":
			return Color(0.33, 0.61, 0.72, 1.0)
	return Color(0.42, 0.63, 0.47, 1.0)

func _energy_color(color_name: String) -> Color:
	match color_name:
		"red":
			return Color(0.88, 0.34, 0.31, 1.0)
		"blue":
			return Color(0.34, 0.59, 0.88, 1.0)
		"purple":
			return Color(0.67, 0.40, 0.88, 1.0)
		"green":
			return Color(0.40, 0.77, 0.46, 1.0)
	return Color(0.74, 0.78, 0.82, 1.0)
