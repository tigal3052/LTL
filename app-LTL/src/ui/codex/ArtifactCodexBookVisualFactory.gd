# 怨꾩빟:
# - 梨낆엫: artifact codex book entry cards, placeholder art, detail chips, shape tiles, and style boxes.
# - ?낅젰: projected codex entry/detail dictionaries and target UI containers.
# - 異쒕젰: interactive entry cards, placeholder art controls, metadata chips, and parchment style boxes.
# - 湲덉?: codex model projection, section selection state, and book safe-area layout math.
#
# ?ㅽ뻾: build reusable codex book visuals while the panel owner handles signals and page placement.
class_name ArtifactCodexBookVisualFactory
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const TILE_TEXTURE = preload("res://resources/UI/tile/tile_panel_nobg.png")
const PIN_TEXTURE = preload("res://resources/UI/pin/pin_1.png")

static func build_entry_card(entry: Dictionary, selected: bool, entry_pressed: Callable) -> Button:
	var button := Button.new()
	button.name = "Entry_%s" % str(entry.get("id", ""))
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_NONE
	button.toggle_mode = false
	button.text = ""
	button.custom_minimum_size = Vector2(168.0, 204.0)
	style_entry_card(button, selected, not bool(entry.get("visible", false)), str(entry.get("rarity", "common")), str(entry.get("energyType", "")))
	button.pressed.connect(func(): entry_pressed.call(str(entry.get("id", ""))))

	var root := Control.new()
	root.name = "CardRoot"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(root)

	var art_shell := PanelContainer.new()
	art_shell.name = "ArtShell"
	art_shell.anchor_left = 0.0
	art_shell.anchor_top = 0.0
	art_shell.anchor_right = 1.0
	art_shell.anchor_bottom = 1.0
	art_shell.offset_left = 14.0
	art_shell.offset_top = 14.0
	art_shell.offset_right = -14.0
	art_shell.offset_bottom = -58.0
	art_shell.clip_contents = true
	art_shell.add_theme_stylebox_override("panel", thumbnail_frame_style(bool(entry.get("visible", false))))
	root.add_child(art_shell)

	var art_host := Control.new()
	art_host.name = "ArtHost"
	art_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art_shell.add_child(art_host)
	render_art_placeholder(art_host, entry.get("thumbArt", {}), str(entry.get("name", "")), false)

	var rarity_plate := PanelContainer.new()
	rarity_plate.name = "RarityPlate"
	rarity_plate.anchor_left = 0.0
	rarity_plate.anchor_top = 1.0
	rarity_plate.anchor_right = 1.0
	rarity_plate.anchor_bottom = 1.0
	rarity_plate.offset_left = 22.0
	rarity_plate.offset_top = -40.0
	rarity_plate.offset_right = -22.0
	rarity_plate.offset_bottom = -14.0
	rarity_plate.add_theme_stylebox_override("panel", rarity_plate_style(str(entry.get("rarity", "common"))))
	root.add_child(rarity_plate)

	var rarity_label := Label.new()
	rarity_label.name = "RarityLabel"
	rarity_label.text = TextCatalogScript.enum_label("rarity", str(entry.get("rarity", "common")))
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rarity_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.add_theme_color_override("font_color", Color(0.98, 0.95, 0.87, 0.98))
	rarity_plate.add_child(rarity_label)

	var pin := TextureRect.new()
	pin.name = "CornerPin"
	pin.texture = PIN_TEXTURE
	pin.texture_filter = Control.TEXTURE_FILTER_NEAREST
	pin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pin.anchor_left = 1.0
	pin.anchor_top = 0.0
	pin.anchor_right = 1.0
	pin.anchor_bottom = 0.0
	pin.offset_left = -32.0
	pin.offset_top = 8.0
	pin.offset_right = -4.0
	pin.offset_bottom = 36.0
	pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(pin)
	set_mouse_passthrough_recursive(root)
	return button

static func render_art_placeholder(host: Control, descriptor: Dictionary, label_text: String, large: bool) -> void:
	clear_children(host)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var resolved_path := str(descriptor.get("path", ""))
	var texture := LTLThemeScript.art_texture(resolved_path)
	var source := str(descriptor.get("source", ""))
	if str(descriptor.get("state", "")) != "locked" and source != "fallback" and texture != null:
		var texture_rect := TextureRect.new()
		texture_rect.name = "ResolvedArtTexture"
		texture_rect.texture = texture
		texture_rect.set_meta("resolved_art_path", resolved_path)
		texture_rect.set_meta("resolved_art_source", source)
		texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(texture_rect)
		set_mouse_passthrough_recursive(host)
		return

	var plate := PanelContainer.new()
	plate.name = "PlaceholderPlate"
	plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.add_theme_stylebox_override("panel", placeholder_plate_style(str(descriptor.get("energyType", "")), str(descriptor.get("itemType", "")), str(descriptor.get("state", "")) != "locked"))
	host.add_child(plate)

	var texture_watermark := TextureRect.new()
	texture_watermark.texture = TILE_TEXTURE
	texture_watermark.texture_filter = Control.TEXTURE_FILTER_NEAREST
	texture_watermark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_watermark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_watermark.modulate = Color(1.0, 1.0, 1.0, 0.18)
	texture_watermark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_watermark.anchor_left = 0.0
	texture_watermark.anchor_top = 0.0
	texture_watermark.anchor_right = 1.0
	texture_watermark.anchor_bottom = 1.0
	texture_watermark.offset_left = 20.0
	texture_watermark.offset_top = 20.0
	texture_watermark.offset_right = -20.0
	texture_watermark.offset_bottom = -20.0
	plate.add_child(texture_watermark)

	var glyph := Label.new()
	glyph.name = "PlaceholderGlyph"
	glyph.text = placeholder_glyph(str(descriptor.get("itemType", "")), str(descriptor.get("state", "")))
	glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glyph.add_theme_font_size_override("font_size", 74 if large else 42)
	glyph.add_theme_color_override("font_color", placeholder_text_color(str(descriptor.get("state", "")) == "locked"))
	plate.add_child(glyph)

	var support := Label.new()
	support.name = "PlaceholderSupport"
	support.text = placeholder_support_text(descriptor, label_text)
	support.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	support.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	support.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	support.anchor_left = 0.0
	support.anchor_top = 1.0
	support.anchor_right = 1.0
	support.anchor_bottom = 1.0
	support.offset_left = 12.0
	support.offset_top = -34.0
	support.offset_right = -12.0
	support.offset_bottom = -8.0
	support.add_theme_font_size_override("font_size", 12 if large else 10)
	support.add_theme_color_override("font_color", placeholder_support_color(str(descriptor.get("state", "")) == "locked"))
	plate.add_child(support)
	set_mouse_passthrough_recursive(host)

static func render_fact_chips(fact_row: HBoxContainer, facts: Array) -> void:
	clear_children(fact_row)
	for fact in facts:
		var chip_shell := PanelContainer.new()
		chip_shell.add_theme_stylebox_override("panel", chip_style())
		fact_row.add_child(chip_shell)
		var chip_label := Label.new()
		chip_label.text = str(fact)
		chip_label.add_theme_font_size_override("font_size", 12)
		chip_label.add_theme_color_override("font_color", Color(0.99, 0.95, 0.87, 0.98))
		chip_shell.add_child(chip_label)

static func render_shape_info(owner, left_page_model: Dictionary) -> void:
	clear_children(owner.shape_grid)
	var shape_matrix: Array = left_page_model.get("shapeMatrix", [])
	if shape_matrix.is_empty():
		owner.shape_section.visible = false
		return
	owner.shape_section.visible = true
	owner.shape_title_label.text = str(left_page_model.get("shapeTitle", ""))
	owner.shape_detail_label.text = "%s / %s" % [
		str(left_page_model.get("shapeFootprintText", "")),
		str(left_page_model.get("shapeCellCountText", ""))
	]
	var first_row: Array = shape_matrix[0] if shape_matrix[0] is Array else []
	owner.shape_grid.columns = maxi(1, first_row.size())
	var energy_type := str(left_page_model.get("shapeEnergyType", ""))
	var item_type := str(left_page_model.get("shapeItemType", ""))
	for row in shape_matrix:
		if not (row is Array):
			continue
		for cell in row:
			var tile := PanelContainer.new()
			tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tile.custom_minimum_size = Vector2(18.0, 18.0)
			tile.add_theme_stylebox_override("panel", shape_cell_style(bool(cell), energy_type, item_type))
			owner.shape_grid.add_child(tile)

static func style_small_action_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.31, 0.21, 0.11, 0.92)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.63, 0.47, 0.24, 1.0)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_right = 6
	normal.corner_radius_bottom_left = 6
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 3
	normal.content_margin_bottom = 3
	var hover := normal.duplicate()
	hover.bg_color = Color(0.40, 0.27, 0.14, 0.98)
	hover.border_color = Color(0.82, 0.69, 0.37, 1.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color(0.99, 0.95, 0.87))

static func style_section_button(button: Button, active: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.36, 0.26, 0.16, 0.32) if not active else Color(0.49, 0.34, 0.16, 0.96)
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.border_color = Color(0.51, 0.37, 0.19, 0.64) if not active else Color(0.83, 0.69, 0.36, 1.0)
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_right = 8
	normal.corner_radius_bottom_left = 8
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	var hover := normal.duplicate()
	hover.bg_color = Color(0.56, 0.39, 0.18, 0.94)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color(0.98, 0.95, 0.87, 0.96))

static func style_entry_card(button: Button, selected: bool, locked: bool, rarity: String, energy_type: String) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.18, 0.12, 0.08, 0.82) if not locked else Color(0.30, 0.28, 0.24, 0.70)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = rarity_border_color(rarity, selected)
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_right = 16
	normal.corner_radius_bottom_left = 16
	normal.shadow_size = 10
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
	normal.shadow_offset = Vector2(0, 4)
	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.08)
	hover.shadow_size = 12
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", energy_color(energy_type, false))

static func hero_frame_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.92, 0.83, 0.62)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.63, 0.49, 0.27, 0.82)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.shadow_size = 12
	style.shadow_color = Color(0.08, 0.04, 0.01, 0.10)
	style.shadow_offset = Vector2(0, 4)
	return style

static func thumbnail_frame_style(known: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.90, 0.80, 0.54) if known else Color(0.84, 0.82, 0.76, 0.44)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.60, 0.46, 0.25, 0.72) if known else Color(0.56, 0.54, 0.48, 0.58)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	return style

static func rarity_plate_style(rarity: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = rarity_border_color(rarity, false).darkened(0.32)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = rarity_border_color(rarity, true)
	style.corner_radius_top_left = 9
	style.corner_radius_top_right = 9
	style.corner_radius_bottom_right = 9
	style.corner_radius_bottom_left = 9
	return style

static func placeholder_plate_style(energy_type: String, item_type: String, discovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = energy_color(energy_type, not discovered)
	if item_type == "relic":
		style.bg_color = Color(0.57, 0.50, 0.37, 0.62) if discovered else Color(0.44, 0.42, 0.38, 0.52)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.97, 0.92, 0.82, 0.44) if discovered else Color(0.86, 0.85, 0.79, 0.28)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	return style

static func chip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.39, 0.26, 0.13, 0.92)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.71, 0.55, 0.31, 0.94)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

static func transparent_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	return style

static func placeholder_glyph(item_type: String, state: String) -> String:
	if state == "locked":
		return "?"
	match item_type:
		"beacon":
			return "B"
		"relic":
			return "R"
		_:
			return "D"

static func placeholder_support_text(descriptor: Dictionary, label_text: String) -> String:
	if str(descriptor.get("state", "")) == "locked":
		return TextCatalogScript.t("codex.state.locked")
	var item_label := TextCatalogScript.t("item.%s" % str(descriptor.get("itemType", "drill")))
	var energy_type := str(descriptor.get("energyType", ""))
	if energy_type.is_empty():
		return item_label
	return "%s ??%s" % [item_label, TextCatalogScript.enum_label("color", energy_type)]

static func placeholder_text_color(locked: bool) -> Color:
	return Color(0.35, 0.28, 0.20, 0.90) if locked else Color(0.96, 0.94, 0.89, 0.98)

static func placeholder_support_color(locked: bool) -> Color:
	return Color(0.36, 0.33, 0.28, 0.86) if locked else Color(0.93, 0.91, 0.84, 0.94)

static func energy_color(energy_type: String, locked: bool) -> Color:
	if locked:
		return Color(0.50, 0.49, 0.45, 0.46)
	match energy_type:
		"red":
			return Color(0.62, 0.23, 0.18, 0.54)
		"blue":
			return Color(0.22, 0.38, 0.59, 0.54)
		"purple":
			return Color(0.47, 0.28, 0.56, 0.52)
		"green":
			return Color(0.28, 0.46, 0.25, 0.54)
		_:
			return Color(0.57, 0.46, 0.26, 0.42)

static func rarity_border_color(rarity: String, selected: bool) -> Color:
	var color := Color(0.62, 0.48, 0.28, 0.84)
	match rarity:
		"rare":
			color = Color(0.42, 0.57, 0.78, 0.92)
		"epic":
			color = Color(0.67, 0.48, 0.86, 0.92)
		"legendary":
			color = Color(0.89, 0.67, 0.28, 0.96)
		"mythic":
			color = Color(0.96, 0.88, 0.54, 0.98)
	if selected:
		return color.lightened(0.16)
	return color

static func shape_cell_style(filled: bool, energy_type: String, item_type: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_right = 4
	style.corner_radius_bottom_left = 4
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	if filled:
		style.bg_color = energy_color(energy_type, false)
		if item_type == "relic":
			style.bg_color = Color(0.62, 0.50, 0.29, 0.74)
		style.border_color = Color(0.95, 0.89, 0.74, 0.98)
		return style
	style.bg_color = Color(0.60, 0.52, 0.39, 0.10)
	style.border_color = Color(0.58, 0.48, 0.33, 0.34)
	return style

static func clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

static func set_mouse_passthrough_recursive(root: Node) -> void:
	if root is Control:
		(root as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in root.get_children():
		set_mouse_passthrough_recursive(child)
