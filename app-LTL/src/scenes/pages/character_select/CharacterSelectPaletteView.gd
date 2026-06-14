extends RefCounted

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const CharacterSelectLoadoutTextScript = preload("res://src/scenes/pages/character_select/CharacterSelectLoadoutText.gd")

static func build_palette_button(color_name: String) -> Button:
	var model := CharacterSelectLoadoutTextScript.starter_palette_card_model(color_name)
	var button := Button.new()
	button.name = "Palette_%s" % color_name
	button.text = ""
	button.custom_minimum_size = Vector2(0.0, 84.0)
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_contents = true
	var card_margin := MarginContainer.new()
	card_margin.name = "CardMargin"
	card_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_margin.add_theme_constant_override("margin_left", 16)
	card_margin.add_theme_constant_override("margin_top", 12)
	card_margin.add_theme_constant_override("margin_right", 12)
	card_margin.add_theme_constant_override("margin_bottom", 12)
	card_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var card_vbox := VBoxContainer.new()
	card_vbox.name = "CardVBox"
	card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_vbox.add_theme_constant_override("separation", 6)
	var title := Label.new()
	title.name = "Title"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = str(model.get("title", ""))
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	title.add_theme_constant_override("outline_size", 1)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05, 0.95))
	var tag_row := HFlowContainer.new()
	tag_row.name = "TagRow"
	tag_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag_row.add_theme_constant_override("h_separation", 5)
	tag_row.add_theme_constant_override("v_separation", 5)
	for tag in model.get("tags", []):
		tag_row.add_child(_create_palette_tag_chip(tag))
	var body := Label.new()
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.text = str(model.get("body", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 10)
	body.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED)
	card_vbox.add_child(title)
	card_vbox.add_child(tag_row)
	card_vbox.add_child(body)
	card_margin.add_child(card_vbox)
	button.add_child(card_margin)
	return button

static func refresh_palette_styles(color_buttons: Dictionary, selected_color: String) -> void:
	for color_name in color_buttons.keys():
		var button: Button = color_buttons[color_name]
		var selected: bool = color_name == selected_color
		var accent: Color = LTLThemeScript.accent_color(color_name)
		var normal := LTLThemeScript.surface_style(Color(0.10, 0.13, 0.17, 0.94), accent if selected else Color(0.18, 0.23, 0.30, 1.0), 18, 1, 0.10)
		if selected:
			normal.bg_color = accent.darkened(0.65)
		var hover := normal.duplicate()
		hover.bg_color = normal.bg_color.lightened(0.05)
		var pressed := normal.duplicate()
		pressed.bg_color = normal.bg_color.darkened(0.04)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("focus", hover)
		button.add_theme_font_size_override("font_size", 1)
		button.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.0))
		_refresh_palette_copy_styles(button, selected)
		_refresh_palette_tag_styles(button, accent, selected)

static func _create_palette_tag_chip(tag: Dictionary) -> PanelContainer:
	var shell := PanelContainer.new()
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.name = "Label"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = " %s " % str(tag.get("text", ""))
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	shell.add_child(label)
	shell.set_meta("tone", str(tag.get("tone", "neutral")))
	return shell

static func _refresh_palette_copy_styles(button: Button, selected: bool) -> void:
	var title := button.get_node_or_null("CardMargin/CardVBox/Title") as Label
	if title != null:
		title.add_theme_font_size_override("font_size", 14)
		title.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	var body := button.get_node_or_null("CardMargin/CardVBox/Body") as Label
	if body != null:
		body.add_theme_font_size_override("font_size", 10)
		body.add_theme_color_override("font_color", LTLThemeScript.TEXT_MUTED if not selected else Color(0.91, 0.94, 0.97, 0.96))

static func _refresh_palette_tag_styles(button: Button, accent: Color, selected: bool) -> void:
	var tag_row := button.get_node_or_null("CardMargin/CardVBox/TagRow") as HFlowContainer
	if tag_row == null:
		return
	for chip in tag_row.get_children():
		var chip_panel := chip as PanelContainer
		if chip_panel == null:
			continue
		var tone := str(chip_panel.get_meta("tone", "neutral"))
		var chip_label := chip_panel.get_node_or_null("Label") as Label
		var palette := _palette_chip_palette(tone, accent, selected)
		chip_panel.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(
			palette.get("bg", Color(0.08, 0.10, 0.13, 0.96)),
			palette.get("border", Color(0.18, 0.23, 0.30, 1.0)),
			999,
			1,
			0.04
		))
		if chip_label != null:
			chip_label.add_theme_font_size_override("font_size", 9)
			chip_label.add_theme_color_override("font_color", palette.get("text", LTLThemeScript.TEXT_PRIMARY))

static func _palette_chip_palette(tone: String, accent: Color, selected: bool) -> Dictionary:
	var background := Color(0.08, 0.10, 0.13, 0.96)
	var border := Color(0.18, 0.23, 0.30, 1.0)
	match tone:
		"color":
			background = accent.darkened(0.54) if selected else accent.darkened(0.78)
			border = accent
		"type":
			background = Color(0.11, 0.13, 0.16, 0.98)
			border = Color(0.29, 0.34, 0.40, 1.0)
		"feature":
			background = accent.darkened(0.62) if selected else accent.darkened(0.80)
			border = accent.lightened(0.10)
		"support":
			background = Color(0.12, 0.15, 0.19, 0.98)
			border = Color(0.37, 0.45, 0.54, 1.0)
	return {"bg": background, "border": border, "text": Color(0.95, 0.97, 0.99, 1.0)}
