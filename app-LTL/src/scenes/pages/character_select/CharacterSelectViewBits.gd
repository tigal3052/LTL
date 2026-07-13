class_name CharacterSelectViewBits
extends RefCounted

const META_SKIP_INTERACTION_FX := "_ltl_skip_interaction_fx"
const CARD_NORMAL_INSET := 4.0
const CARD_HOVER_INSET := 0.0

static func hide_scrollbar_chrome(scroll: ScrollContainer) -> void:
	if scroll == null:
		return
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var bar := scroll.get_v_scroll_bar()
	if bar == null:
		return
	var transparent := StyleBoxFlat.new()
	transparent.draw_center = false
	transparent.border_width_left = 0
	transparent.border_width_top = 0
	transparent.border_width_right = 0
	transparent.border_width_bottom = 0
	bar.custom_minimum_size = Vector2.ZERO
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("scroll", transparent)
	bar.add_theme_stylebox_override("grabber", transparent)
	bar.add_theme_stylebox_override("grabber_highlight", transparent)
	bar.add_theme_stylebox_override("grabber_pressed", transparent)
	bar.hide()

static func build_roster_button(character: Dictionary) -> Button:
	var button := _base_card_button(Vector2(0.0, 92.0))
	var frame := _card_frame("CardFrame")
	var margin := MarginContainer.new()
	margin.name = "CardMargin"
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	var row := HBoxContainer.new()
	row.name = "CardRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	var icon_frame := _icon_frame("PortraitIconFrame", Vector2(50.0, 50.0))
	var portrait := TextureRect.new()
	portrait.name = "PortraitIcon"
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture = load(str(character.get("portraitPath", ""))) if not str(character.get("portraitPath", "")).is_empty() else null
	portrait.modulate = Color(1, 1, 1, 1) if bool(character.get("selectable", false)) else Color(0.58, 0.58, 0.54, 0.75)
	icon_frame.add_child(portrait)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vbox := VBoxContainer.new()
	vbox.name = "CardVBox"
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.add_theme_constant_override("separation", 4)
	# Title row: accent marker + name
	var title_row := HBoxContainer.new()
	title_row.name = "TitleRow"
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_theme_constant_override("separation", 7)
	var marker := ColorRect.new()
	marker.name = "NameMarker"
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.custom_minimum_size = Vector2(9.0, 9.0)
	marker.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	marker.rotation_degrees = 45.0
	marker.pivot_offset = Vector2(4.5, 4.5)
	var title := Label.new()
	title.name = "Title"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = str(character.get("name", "Unknown"))
	title.add_theme_font_size_override("font_size", 15)
	title_row.add_child(marker)
	title_row.add_child(title)
	var meta := Label.new()
	meta.name = "Meta"
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var role := str(character.get("role", ""))
	var roster_meta := str(character.get("rosterMeta", ""))
	meta.text = role if roster_meta.is_empty() else "%s  |  %s" % [role, roster_meta]
	meta.add_theme_font_size_override("font_size", 11)
	var body := Label.new()
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.text = str(character.get("rosterLongCopy", character.get("summary", "")))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.max_lines_visible = 2
	body.add_theme_font_size_override("font_size", 10)
	vbox.add_child(title_row)
	vbox.add_child(meta)
	vbox.add_child(body)
	row.add_child(icon_frame)
	row.add_child(vbox)
	margin.add_child(row)
	frame.add_child(margin)
	button.add_child(frame)
	_bind_card_inset_feedback(button)
	return button

static func apply_roster_button_style(button: Button, selectable: bool, is_selected: bool, accent: Color, theme_script) -> void:
	if button == null:
		return
	var ink_bark := Color(0.12, 0.20, 0.11, 1.0)
	var root_brown := Color(0.30, 0.23, 0.15, 1.0)
	var muted_moss := Color(0.40, 0.48, 0.35, 0.94)
	var border := Color(0.64, 0.70, 0.48, 0.78)
	var bg := Color(0.91, 0.87, 0.72, 0.96)
	if is_selected:
		bg = Color(0.98, 0.91, 0.84, 0.98)
		border = Color(0.22, 0.48, 0.24, 1.0)
	if not selectable:
		bg = Color(0.84, 0.80, 0.66, 0.72)
		border = Color(0.68, 0.68, 0.54, 0.46)
	_apply_shell_button_chrome(button)
	var frame := button.get_node_or_null("CardFrame") as PanelContainer
	if frame != null:
		var normal = theme_script.surface_style(bg, border, 18, 1, 0.0)
		normal.shadow_size = 0
		frame.add_theme_stylebox_override("panel", normal)
	var icon_frame := button.get_node_or_null("CardFrame/CardMargin/CardRow/PortraitIconFrame") as PanelContainer
	if icon_frame != null:
		_apply_icon_frame_style(icon_frame, border, theme_script)
	var title := button.get_node_or_null("CardFrame/CardMargin/CardRow/CardVBox/Title") as Label
	var meta := button.get_node_or_null("CardFrame/CardMargin/CardRow/CardVBox/Meta") as Label
	var body := button.get_node_or_null("CardFrame/CardMargin/CardRow/CardVBox/Body") as Label
	if title != null:
		title.add_theme_color_override("font_color", ink_bark if selectable else Color(0.48, 0.50, 0.42, 0.74))
	if meta != null:
		meta.add_theme_color_override("font_color", Color(0.24, 0.42, 0.22, 0.92) if selectable else Color(0.52, 0.55, 0.46, 0.68))
	if body != null:
		body.add_theme_color_override("font_color", root_brown if selectable else muted_moss)
	_set_card_inset(button, CARD_HOVER_INSET if is_selected else CARD_NORMAL_INSET)

const STARTER_FRAME_DIR := "res://resources/UI/starter/"
# Icon slot center/size per frame kind — measured directly on each frame art's
# dark icon-well (pixel-sampled across all 4 colors). Drill and beacon wells sit
# at different positions/sizes in their source art, so each kind gets its own slot.
const STARTER_SLOT_SIZE := {
	"drill": Vector2(0.231, 0.873),
	"beacon": Vector2(0.186, 0.800),
}
const STARTER_SLOT_CENTER := {
	"drill": Vector2(0.174, 0.519),
	"beacon": Vector2(0.131, 0.521),
}
# Text box left anchor per kind — a bit of left padding off the icon slot's right edge.
const STARTER_TEXT_LEFT := {
	"drill": 0.174 + 0.231 * 0.5 + 0.025,
	"beacon": 0.131 + 0.186 * 0.5 + 0.025,
}
# Frame art canvas aspect ratios (width / height), unified per family so both
# render at the same on-screen width when the card height derives from it.
const STARTER_FRAME_ASPECT := {
	"beacon": 2200.0 / 482.0,
	"drill": 2200.0 / 540.0,
}

static func _starter_frame_kind(item_type: String) -> String:
	return "beacon" if str(item_type).to_lower() == "beacon" else "drill"

static func starter_frame_path(color_name: String, item_type: String) -> String:
	var kind := _starter_frame_kind(item_type)
	var color := str(color_name).to_lower()
	if color not in ["red", "blue", "purple", "green"]:
		color = "red"
	return "%sstarter_%s_card_%s.png" % [STARTER_FRAME_DIR, kind, color]

static func build_starter_item_button(item_model: Dictionary) -> Button:
	var item_id := str(item_model.get("itemId", ""))
	var color_name := str(item_model.get("colorName", "red"))
	var item_type := str(item_model.get("itemType", "drill"))
	var kind := _starter_frame_kind(item_type)
	var aspect: float = STARTER_FRAME_ASPECT.get(kind, STARTER_FRAME_ASPECT["drill"])
	var button := _base_card_button(Vector2(0.0, 84.0))
	button.name = "StarterItem_%s" % item_id
	button.clip_contents = false
	button.set_meta("_frame_aspect", aspect)
	button.resized.connect(_sync_starter_card_height.bind(button))
	# CardRoot — pivot-centered container so hover scale never shifts layout
	var card_root := Control.new()
	card_root.name = "CardFrame"
	card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Ornate frame background — stretched to a uniform card rect
	var frame_bg := TextureRect.new()
	frame_bg.name = "FrameBg"
	frame_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame_bg.stretch_mode = TextureRect.STRETCH_SCALE
	frame_bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var frame_path := starter_frame_path(color_name, item_type)
	if ResourceLoader.exists(frame_path):
		frame_bg.texture = load(frame_path)
	card_root.add_child(frame_bg)
	# Icon centered inside the left slot (proportional anchors)
	var icon := TextureRect.new()
	icon.name = "ItemIcon"
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.texture = load(str(item_model.get("iconPath", ""))) if not str(item_model.get("iconPath", "")).is_empty() else null
	var slot_center: Vector2 = STARTER_SLOT_CENTER.get(kind, STARTER_SLOT_CENTER["drill"])
	var slot_size: Vector2 = STARTER_SLOT_SIZE.get(kind, STARTER_SLOT_SIZE["drill"])
	icon.anchor_left = slot_center.x - slot_size.x * 0.5
	icon.anchor_right = slot_center.x + slot_size.x * 0.5
	icon.anchor_top = slot_center.y - slot_size.y * 0.5
	icon.anchor_bottom = slot_center.y + slot_size.y * 0.5
	icon.offset_left = 0.0
	icon.offset_top = 0.0
	icon.offset_right = 0.0
	icon.offset_bottom = 0.0
	card_root.add_child(icon)
	# Text box in the right open area
	var vbox := VBoxContainer.new()
	vbox.name = "CardVBox"
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 3)
	vbox.anchor_left = STARTER_TEXT_LEFT.get(kind, STARTER_TEXT_LEFT["drill"])
	vbox.anchor_right = 0.955
	vbox.anchor_top = 0.22
	vbox.anchor_bottom = 0.85
	vbox.offset_left = 0.0
	vbox.offset_top = 0.0
	vbox.offset_right = 0.0
	vbox.offset_bottom = 0.0
	var title := Label.new()
	title.name = "Title"
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.text = str(item_model.get("title", ""))
	title.add_theme_font_size_override("font_size", 14)
	var metric := Label.new()
	metric.name = "Metric"
	metric.mouse_filter = Control.MOUSE_FILTER_IGNORE
	metric.text = str(item_model.get("metricLine", ""))
	metric.add_theme_font_size_override("font_size", 11)
	var body := Label.new()
	body.name = "Body"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.text = str(item_model.get("summary", ""))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.max_lines_visible = 1
	body.visible = false
	body.add_theme_font_size_override("font_size", 10)
	vbox.add_child(title)
	vbox.add_child(metric)
	vbox.add_child(body)
	card_root.add_child(vbox)
	button.add_child(card_root)
	_bind_starter_hover_scale(button)
	_sync_starter_card_height(button)
	return button

# Keeps each starter card's height matched to its frame art's aspect ratio so
# beacon and drill cards render at the same on-screen width instead of the
# frame art being non-uniformly stretched by whichever height the row uses.
static func _sync_starter_card_height(button: Button) -> void:
	var aspect: float = button.get_meta("_frame_aspect", 1.0)
	if aspect <= 0.0 or button.size.x <= 0.0:
		return
	var target_height := roundf(button.size.x / aspect)
	if absf(button.custom_minimum_size.y - target_height) < 0.5:
		return
	button.custom_minimum_size.y = target_height

# Hover scale from center — grows the ornate card without shifting its slot alignment
static func _bind_starter_hover_scale(button: Button) -> void:
	button.mouse_entered.connect(func() -> void:
		_scale_starter_card(button, 1.04)
	)
	button.mouse_exited.connect(func() -> void:
		if not bool(button.get_meta("selected", false)):
			_scale_starter_card(button, 1.0)
	)

static func _scale_starter_card(button: Button, target: float) -> void:
	var root := button.get_node_or_null("CardFrame") as Control
	if root == null:
		return
	# Re-derive pivot from the button's current size rather than the CardFrame's
	# (PRESET_FULL_RECT means CardFrame.size can lag a frame behind button.size
	# right after a resize, which throws the pivot off and visibly shifts icons).
	root.pivot_offset = button.size * 0.5
	var tween := root.create_tween()
	tween.tween_property(root, "scale", Vector2(target, target), 0.12).set_ease(Tween.EASE_OUT)

static func apply_starter_item_button_style(button: Button, is_selected: bool, accent: Color, theme_script) -> void:
	if button == null:
		return
	_apply_shell_button_chrome(button)
	# Selection highlight — brighten the ornate frame + selected glow
	var frame_bg := button.get_node_or_null("CardFrame/FrameBg") as TextureRect
	if frame_bg != null:
		frame_bg.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_selected else Color(0.92, 0.92, 0.90, 1.0)
	# Text sits on the parchment area — dark ink for legibility
	var ink_bark := Color(0.098, 0.078, 0.043, 1.0)
	var stat_color := Color(0.208, 0.153, 0.086, 1.0)
	var title := button.get_node_or_null("CardFrame/CardVBox/Title") as Label
	var metric := button.get_node_or_null("CardFrame/CardVBox/Metric") as Label
	var body := button.get_node_or_null("CardFrame/CardVBox/Body") as Label
	if title != null:
		title.add_theme_color_override("font_color", ink_bark)
		title.add_theme_constant_override("outline_size", 2)
		title.add_theme_color_override("font_outline_color", Color(1.0, 0.976, 0.902, 0.55))
	if metric != null:
		metric.add_theme_color_override("font_color", stat_color)
	if body != null:
		body.add_theme_color_override("font_color", stat_color)
	# Persist selection so hover-exit keeps the scale for the chosen card
	if is_selected:
		_scale_starter_card(button, 1.03)
	else:
		_scale_starter_card(button, 1.0)

static func card_visual_style(button: Button) -> StyleBoxFlat:
	if button == null:
		return null
	var frame := button.get_node_or_null("CardFrame") as PanelContainer
	if frame == null:
		return button.get_theme_stylebox("normal") as StyleBoxFlat
	return frame.get_theme_stylebox("panel") as StyleBoxFlat

static func _base_card_button(minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.clip_contents = false
	button.set_meta(META_SKIP_INTERACTION_FX, true)
	_apply_shell_button_chrome(button)
	return button

static func _card_frame(frame_name: String) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.name = frame_name
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_set_offsets(frame, CARD_NORMAL_INSET)
	return frame

static func _icon_frame(frame_name: String, minimum_size: Vector2) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.name = frame_name
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.custom_minimum_size = minimum_size
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return frame

static func _apply_shell_button_chrome(button: Button) -> void:
	var transparent := StyleBoxFlat.new()
	transparent.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	transparent.border_width_left = 0
	transparent.border_width_top = 0
	transparent.border_width_right = 0
	transparent.border_width_bottom = 0
	transparent.shadow_size = 0
	button.add_theme_stylebox_override("normal", transparent)
	button.add_theme_stylebox_override("hover", transparent)
	button.add_theme_stylebox_override("pressed", transparent)
	button.add_theme_stylebox_override("focus", transparent)
	button.add_theme_stylebox_override("disabled", transparent)
	button.add_theme_color_override("font_color", Color(0.0, 0.0, 0.0, 0.0))
	button.add_theme_color_override("font_disabled_color", Color(0.0, 0.0, 0.0, 0.0))
	button.add_theme_font_size_override("font_size", 1)

static func _apply_icon_frame_style(frame: PanelContainer, border: Color, theme_script) -> void:
	var style = theme_script.surface_style(Color(0.96, 0.94, 0.82, 0.96), border, 7, 1, 0.0)
	style.shadow_size = 0
	frame.add_theme_stylebox_override("panel", style)

static func _bind_card_inset_feedback(button: Button) -> void:
	button.mouse_entered.connect(func() -> void:
		_set_card_inset(button, CARD_HOVER_INSET)
	)
	button.mouse_exited.connect(func() -> void:
		if not bool(button.get_meta("selected", false)):
			_set_card_inset(button, CARD_NORMAL_INSET)
	)

static func _set_card_inset(button: Button, inset: float) -> void:
	var frame := button.get_node_or_null("CardFrame") as Control
	if frame == null:
		return
	_set_offsets(frame, inset)

static func apply_roster_button_style_dark(button: Button, selectable: bool, is_selected: bool, accent: Color, theme_script) -> void:
	if button == null:
		return
	_apply_shell_button_chrome(button)
	var bg: Color
	var border: Color
	if is_selected:
		bg = Color(0.216, 0.451, 0.216, 0.62)
		border = Color(0.749, 0.902, 0.631, 1.0)
	elif selectable:
		bg = Color(0.086, 0.129, 0.078, 0.55)
		border = Color(0.843, 0.894, 0.773, 0.42)
	else:
		bg = Color(0.086, 0.106, 0.078, 0.55)
		border = Color(0.50, 0.50, 0.42, 0.32)
	var frame := button.get_node_or_null("CardFrame") as PanelContainer
	if frame != null:
		var normal := StyleBoxFlat.new()
		normal.bg_color = bg
		normal.shadow_size = 0
		# Sharp rectangle — no rounded corners
		normal.set_corner_radius_all(0)
		normal.set_border_width_all(0)
		normal.border_width_left = 2
		normal.border_color = border
		if is_selected:
			normal.border_width_left = 3
			normal.border_color = Color(0.749, 0.902, 0.631, 1.0)
		frame.add_theme_stylebox_override("panel", normal)
	var icon_frame := button.get_node_or_null("CardFrame/CardMargin/CardRow/PortraitIconFrame") as PanelContainer
	if icon_frame != null:
		var icon_style := StyleBoxFlat.new()
		icon_style.bg_color = Color(0.055, 0.086, 0.051, 0.85)
		icon_style.shadow_size = 0
		icon_style.set_corner_radius_all(0)
		icon_style.set_border_width_all(1)
		icon_style.border_color = border
		icon_frame.add_theme_stylebox_override("panel", icon_style)
	# Accent name marker
	var marker := button.get_node_or_null("CardFrame/CardMargin/CardRow/CardVBox/TitleRow/NameMarker") as ColorRect
	if marker != null:
		marker.color = accent if selectable else Color(0.50, 0.52, 0.44, 0.60)
	var title := button.get_node_or_null("CardFrame/CardMargin/CardRow/CardVBox/TitleRow/Title") as Label
	var meta := button.get_node_or_null("CardFrame/CardMargin/CardRow/CardVBox/Meta") as Label
	var body := button.get_node_or_null("CardFrame/CardMargin/CardRow/CardVBox/Body") as Label
	# Bright, fully-opaque text for legibility
	if title != null:
		title.add_theme_color_override("font_color", Color(1.0, 0.988, 0.933, 1.0) if selectable else Color(0.62, 0.64, 0.56, 0.85))
		title.add_theme_constant_override("outline_size", 4)
		title.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.80))
	if meta != null:
		meta.add_theme_color_override("font_color", Color(0.855, 0.929, 0.792, 1.0) if selectable else Color(0.56, 0.60, 0.50, 0.75))
		meta.add_theme_constant_override("outline_size", 3)
		meta.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.65))
	if body != null:
		body.add_theme_color_override("font_color", Color(0.820, 0.878, 0.769, 1.0) if selectable else Color(0.50, 0.54, 0.46, 0.70))
		body.add_theme_constant_override("outline_size", 3)
		body.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.60))
	var portrait := button.get_node_or_null("CardFrame/CardMargin/CardRow/PortraitIconFrame/PortraitIcon") as TextureRect
	if portrait != null:
		# Fully opaque for selectable, dimmed for locked
		portrait.modulate = Color(1, 1, 1, 1) if selectable else Color(0.45, 0.45, 0.42, 0.75)
	_set_card_inset(button, CARD_HOVER_INSET if is_selected else CARD_NORMAL_INSET)

static func _set_offsets(control: Control, inset: float) -> void:
	control.offset_left = inset
	control.offset_top = inset
	control.offset_right = -inset
	control.offset_bottom = -inset
