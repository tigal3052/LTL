extends RefCounted

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const CharacterSelectLoadoutTextScript = preload("res://src/scenes/pages/character_select/CharacterSelectLoadoutText.gd")

static func build_palette_button(color_name: String) -> Button:
	var model := CharacterSelectLoadoutTextScript.starter_palette_card_model(color_name)
	var meta_text := CharacterSelectLoadoutTextScript.starter_palette_meta(color_name)
	var button := Button.new()
	button.name = "Palette_%s" % color_name
	button.text = ""
	button.custom_minimum_size = Vector2(0.0, 54.0)
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_contents = true
	# Card layout: swatch bar (12px) | name + meta
	var card_margin := MarginContainer.new()
	card_margin.name = "CardMargin"
	card_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_margin.add_theme_constant_override("margin_left", 10)
	card_margin.add_theme_constant_override("margin_top", 10)
	card_margin.add_theme_constant_override("margin_right", 10)
	card_margin.add_theme_constant_override("margin_bottom", 10)
	card_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row := HBoxContainer.new()
	row.name = "CardRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 11)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	# Swatch color bar
	var swatch := ColorRect.new()
	swatch.name = "Swatch"
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch.custom_minimum_size = Vector2(12.0, 38.0)
	swatch.color = _swatch_color(color_name)
	var swatch_container := Control.new()
	swatch_container.name = "SwatchContainer"
	swatch_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swatch_container.custom_minimum_size = Vector2(14.0, 0.0)
	swatch_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swatch_container.add_child(swatch)
	swatch.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	swatch.offset_left = 0.0
	swatch.offset_top = -19.0
	swatch.offset_right = 12.0
	swatch.offset_bottom = 19.0
	var card_vbox := VBoxContainer.new()
	card_vbox.name = "CardVBox"
	card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_vbox.add_theme_constant_override("separation", 2)
	var title := Label.new()
	title.name = "Title"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = str(model.get("title", ""))
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.055, 0.153, 0.086, 1.0))
	var meta := Label.new()
	meta.name = "Meta"
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta.text = meta_text
	meta.add_theme_font_size_override("font_size", 10)
	meta.add_theme_color_override("font_color", Color(0.17, 0.29, 0.19, 0.94))
	card_vbox.add_child(title)
	card_vbox.add_child(meta)
	row.add_child(swatch_container)
	row.add_child(card_vbox)
	# Hover fill overlay — white sweep from left to right (added first = behind content)
	var hover_fill := ColorRect.new()
	hover_fill.name = "HoverFill"
	hover_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_fill.color = Color(1.0, 1.0, 1.0, 0.22)
	hover_fill.anchor_left = 0.0
	hover_fill.anchor_top = 0.0
	hover_fill.anchor_right = 0.0
	hover_fill.anchor_bottom = 1.0
	hover_fill.offset_left = 0.0
	hover_fill.offset_top = 0.0
	hover_fill.offset_right = 0.0
	hover_fill.offset_bottom = 0.0
	button.add_child(hover_fill)
	card_margin.add_child(row)
	button.add_child(card_margin)
	_bind_palette_hover_sweep(button, hover_fill)
	return button

# Hover sweep — the white fill grows left→right on enter, retracts on exit.
# Skipped while the card is the selected preset (it already shows a solid fill).
static func _bind_palette_hover_sweep(button: Button, hover_fill: ColorRect) -> void:
	button.mouse_entered.connect(func() -> void:
		if bool(button.get_meta("selected", false)):
			return
		var old = button.get_meta("_sweep_tween", null)
		if old is Tween and old.is_running():
			old.kill()
		hover_fill.anchor_right = 0.0
		var tween := button.create_tween()
		tween.tween_property(hover_fill, "anchor_right", 1.0, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		button.set_meta("_sweep_tween", tween)
	)
	button.mouse_exited.connect(func() -> void:
		var old = button.get_meta("_sweep_tween", null)
		if old is Tween and old.is_running():
			old.kill()
		var tween := button.create_tween()
		tween.tween_property(hover_fill, "anchor_right", 0.0, 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		button.set_meta("_sweep_tween", tween)
	)

static func _swatch_color(color_name: String) -> Color:
	match color_name:
		"red":
			return Color(0.765, 0.271, 0.227, 1.0)
		"blue":
			return Color(0.239, 0.518, 0.702, 1.0)
		"purple":
			return Color(0.490, 0.333, 0.710, 1.0)
		"green":
			return Color(0.247, 0.561, 0.322, 1.0)
	return Color(0.5, 0.5, 0.5, 1.0)

static func refresh_palette_styles(color_buttons: Dictionary, selected_color: String) -> void:
	for color_name in color_buttons.keys():
		var button: Button = color_buttons[color_name]
		var selected: bool = color_name == selected_color
		var accent: Color = LTLThemeScript.accent_color(color_name)
		var normal := LTLThemeScript.surface_style(Color(0.90, 0.86, 0.70, 0.96), accent if selected else Color(0.58, 0.66, 0.46, 0.78), 18, 1, 0.0)
		normal.shadow_size = 0
		if selected:
			normal.bg_color = Color(0.95, 0.89, 0.75, 0.98)
		var hover := normal.duplicate()
		hover.bg_color = normal.bg_color.lightened(0.03)
		var pressed := normal.duplicate()
		pressed.bg_color = normal.bg_color.darkened(0.025)
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
		title.add_theme_color_override("font_color", Color(0.12, 0.20, 0.11, 1.0))
	var body := button.get_node_or_null("CardMargin/CardVBox/Body") as Label
	if body != null:
		body.add_theme_font_size_override("font_size", 10)
		body.add_theme_color_override("font_color", Color(0.30, 0.23, 0.15, 0.94))

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

static func refresh_palette_styles_glassmorphism(color_buttons: Dictionary, selected_color: String) -> void:
	for color_name in color_buttons.keys():
		var button: Button = color_buttons[color_name]
		var selected: bool = color_name == selected_color
		var normal := StyleBoxFlat.new()
		if selected:
			normal.bg_color = Color(1.0, 1.0, 1.0, 0.42)
			normal.border_color = Color(0.18, 0.35, 0.20, 0.40)
			normal.set_border_width_all(1)
		else:
			normal.bg_color = Color(0, 0, 0, 0)
			normal.set_border_width_all(0)
		normal.set_corner_radius_all(8)
		normal.shadow_size = 0
		# Hover handled by the animated HoverFill overlay; keep button hover style flat
		var hover := normal.duplicate()
		var pressed := normal.duplicate()
		pressed.bg_color = normal.bg_color.darkened(0.03) if selected else Color(1.0, 1.0, 1.0, 0.12)
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("focus", normal)
		button.add_theme_stylebox_override("disabled", normal)
		button.add_theme_font_size_override("font_size", 1)
		button.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.0))
		# Track selection so the hover sweep is suppressed on the chosen card
		button.set_meta("selected", selected)
		var hover_fill := button.get_node_or_null("HoverFill") as ColorRect
		if hover_fill != null:
			hover_fill.anchor_right = 0.0
			hover_fill.visible = not selected
		# Wing internal text colors
		_refresh_palette_copy_styles_glassmorphism(button, selected)

static func _refresh_palette_copy_styles_glassmorphism(button: Button, selected: bool) -> void:
	var title := button.get_node_or_null("CardMargin/CardRow/CardVBox/Title") as Label
	if title == null:
		title = button.get_node_or_null("CardMargin/CardVBox/Title") as Label
	if title != null:
		title.add_theme_font_size_override("font_size", 14)
		title.add_theme_color_override("font_color", Color(0.055, 0.153, 0.086, 1.0))
	var meta := button.get_node_or_null("CardMargin/CardRow/CardVBox/Meta") as Label
	if meta != null:
		meta.add_theme_font_size_override("font_size", 10)
		meta.add_theme_color_override("font_color", Color(0.17, 0.29, 0.19, 0.94))

static func _palette_chip_palette(tone: String, accent: Color, selected: bool) -> Dictionary:
	var background := Color(0.84, 0.82, 0.66, 0.96)
	var border := Color(0.58, 0.66, 0.46, 0.82)
	var text := Color(0.12, 0.20, 0.11, 1.0)
	match tone:
		"color":
			background = Color(0.80, 0.88, 0.66, 0.96) if selected else Color(0.84, 0.82, 0.66, 0.96)
			border = accent
		"type":
			background = Color(0.87, 0.84, 0.68, 0.98)
			border = Color(0.58, 0.62, 0.48, 0.86)
		"feature":
			background = Color(0.78, 0.88, 0.66, 0.96) if selected else Color(0.82, 0.82, 0.64, 0.96)
			border = accent.lightened(0.10)
		"support":
			background = Color(0.86, 0.84, 0.68, 0.98)
			border = Color(0.56, 0.64, 0.48, 0.86)
	return {"bg": background, "border": border, "text": text}
