# 계약:
# - Responsibility: align the left info panel's visible slots to panel_atlas.png's art slots.
# - Input: a NodeSelectRuntimePage owner exposing info_card, and a rendered panel model dictionary.
# - Output: an opaque, slot-aligned PanelSlotLayer with thumbnail/title/ledger row controls.
# - Prohibited: mutating gameplay state, changing the legacy InfoMargin text-carrier contract.
#
# 실행: lay out and render the atlas-aligned info panel slots.
class_name NodeSelectInfoPanelForm
extends RefCounted

const NodeSelectVisualFactoryScript = preload("res://src/scenes/pages/node_select/NodeSelectVisualFactory.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const LeviathanSelectChromeBitsScript = preload("res://src/scenes/pages/leviathan_select/LeviathanSelectChromeBits.gd")

const PANEL_ART_ASPECT := 551.0 / 884.0
const THUMB_SIZE_RATIO := 0.34
const THUMB_CENTER_Y_RATIO := 0.29
const NAME_RECT := Rect2(0.13, 0.495, 0.74, 0.055)
const ROW_LABEL_RECT := Rect2(0.148, 0.0, 0.148, 0.072)
const ROW_VALUE_RECT := Rect2(0.315, 0.0, 0.560, 0.072)
const ROW_Y_BASE := 0.573
const ROW_Y_STEP := 0.080

# 실행: size and position the info card, then rebuild the atlas-aligned slot layer.
static func layout(page) -> void:
	var card_height := clampf(page.roadmap_canvas.size.y * 0.88, 476.0, 745.0)
	var card_width := card_height * PANEL_ART_ASPECT
	page.info_card.position = Vector2(24.0, maxf(12.0, (page.roadmap_canvas.size.y - card_height) * 0.5))
	page.info_card.size = Vector2(card_width, card_height)
	page.info_card.get_node("InfoMargin").visible = false
	var layer := _ensure_slot_layer(page.info_card)
	_layout_slots(layer, card_width, card_height)

static func _ensure_slot_layer(info_card: Control) -> Control:
	var layer := info_card.get_node_or_null("PanelSlotLayer") as Control
	if layer == null:
		layer = Control.new()
		layer.name = "PanelSlotLayer"
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_card.add_child(layer)
		info_card.move_child(layer, 1)
	return layer

static func _layout_slots(layer: Control, width: float, height: float) -> void:
	layer.position = Vector2.ZERO
	layer.size = Vector2(width, height)

	for stale_name in ["SlotNameEyebrow", "SlotAnalysisEyebrow"]:
		var stale := layer.get_node_or_null(stale_name)
		if stale != null:
			layer.remove_child(stale)
			stale.queue_free()

	var thumb := _ensure_texture_rect(layer, "SlotThumbIcon")
	var thumb_side := THUMB_SIZE_RATIO * width
	thumb.size = Vector2(thumb_side, thumb_side)
	thumb.position = Vector2((width - thumb_side) * 0.5, THUMB_CENTER_Y_RATIO * height - thumb_side * 0.5)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.self_modulate = Color(1.0, 1.0, 1.0, 0.92)

	var name_label := _ensure_label(layer, "SlotName")
	_place(name_label, NAME_RECT, width, height)
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.add_theme_font_override("font", LeviathanSelectChromeBitsScript._copy_weighted_font(LTLThemeScript, 800))
	name_label.add_theme_color_override("font_color", Color(0.10, 0.18, 0.12, 1.0))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF

	var row_captions := [
		TextCatalogScript.t("node_runtime.panel.weakness"),
		TextCatalogScript.t("node_runtime.panel.obstruction").replace("방해요소", "방해\n요소"),
		TextCatalogScript.t("node_runtime.panel.lore"),
		TextCatalogScript.t("node_runtime.panel.status")
	]
	for i in range(4):
		var row_y := (ROW_Y_BASE + ROW_Y_STEP * float(i))
		var row_label := _ensure_label(layer, "SlotRowLabel%d" % i)
		var label_rect := Rect2(ROW_LABEL_RECT.position.x, row_y, ROW_LABEL_RECT.size.x, ROW_LABEL_RECT.size.y)
		_place(row_label, label_rect, width, height)
		row_label.add_theme_font_size_override("font_size", 13)
		row_label.add_theme_font_override("font", LeviathanSelectChromeBitsScript._copy_weighted_font(LTLThemeScript, 800))
		row_label.add_theme_constant_override("line_spacing", -2)
		row_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		row_label.add_theme_color_override("font_color", Color(0.16, 0.24, 0.16, 1.0))
		row_label.text = str(row_captions[i])

		var row_value := _ensure_label(layer, "SlotRowValue%d" % i)
		var value_rect := Rect2(ROW_VALUE_RECT.position.x, row_y, ROW_VALUE_RECT.size.x, ROW_VALUE_RECT.size.y)
		_place(row_value, value_rect, width, height)
		row_value.add_theme_font_size_override("font_size", 12)
		row_value.add_theme_font_override("font", LeviathanSelectChromeBitsScript._copy_weighted_font(LTLThemeScript, 600))
		row_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row_value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row_value.clip_contents = true
		row_value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row_value.add_theme_color_override("font_color", Color(0.10, 0.15, 0.10, 1.0))

# 실행: fill the atlas-aligned slots from a resolved panel model.
static func render(page, model: Dictionary) -> void:
	var layer := page.info_card.get_node_or_null("PanelSlotLayer") as Control
	if layer == null:
		return
	var name_label := layer.get_node_or_null("SlotName") as Label
	if name_label != null:
		name_label.text = str(model.get("name", ""))
	var components: Dictionary = model.get("components", {})
	var row_values := [
		str(components.get("weakness", "")),
		str(components.get("obstruction", "")),
		str(components.get("lore", model.get("body", ""))),
		str(components.get("status", ""))
	]
	for i in range(4):
		var row_value := layer.get_node_or_null("SlotRowValue%d" % i) as Label
		if row_value != null:
			var value := str(row_values[i])
			row_value.text = value if not value.is_empty() else "—"
	var thumb := layer.get_node_or_null("SlotThumbIcon") as TextureRect
	if thumb != null:
		var has_components := not components.is_empty()
		var has_body := not str(model.get("body", "")).is_empty()
		thumb.visible = has_components or has_body
		if thumb.visible:
			thumb.texture = NodeSelectVisualFactoryScript.icon_texture(str(components.get("icon", "normal")))

static func _ensure_texture_rect(layer: Control, node_name: String) -> TextureRect:
	var node := layer.get_node_or_null(node_name) as TextureRect
	if node == null:
		node = TextureRect.new()
		node.name = node_name
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(node)
	return node

static func _ensure_label(layer: Control, node_name: String) -> Label:
	var node := layer.get_node_or_null(node_name) as Label
	if node == null:
		node = Label.new()
		node.name = node_name
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(node)
	return node

static func _place(control: Control, ratio_rect: Rect2, width: float, height: float) -> void:
	control.position = Vector2(ratio_rect.position.x * width, ratio_rect.position.y * height)
	control.size = Vector2(ratio_rect.size.x * width, ratio_rect.size.y * height)
