class_name LeviathanSelectChromeBits
extends RefCounted

const TOP_GROUP_SPEC_ID := "ui-issue-6-variant-05"
const TOP_GROUP_HEADER_HEIGHT := 76.0
const TOP_GROUP_HEADER_LEFT_PAD := 24
const TOP_GROUP_HEADER_RIGHT_PAD := 22
const TOP_GROUP_BRAND_FONT_SIZE := 20
const TOP_GROUP_BUTTON_GAP := 14
const TOP_GROUP_MIN_WIDTH := 108.0
const TOP_GROUP_HEIGHT := 40.0
const TOP_GROUP_FONT_SIZE := 14
const TOP_GROUP_FONT_WEIGHT := 800
const TOP_GROUP_TEXT_ACTIVE := Color(39.0 / 255.0, 71.0 / 255.0, 54.0 / 255.0, 1.0)
const TOP_GROUP_TEXT_SECONDARY := Color(39.0 / 255.0, 71.0 / 255.0, 54.0 / 255.0, 0.82)
const TOP_GROUP_UNDERLINE_TRACK := Color(37.0 / 255.0, 72.0 / 255.0, 53.0 / 255.0, 0.18)
const TOP_GROUP_UNDERLINE_ACTIVE := Color(45.0 / 255.0, 95.0 / 255.0, 68.0 / 255.0, 0.88)
const TOP_GROUP_PADDING_X := 14.0
const TOP_GROUP_PADDING_TOP := 8.0
const TOP_GROUP_PADDING_BOTTOM := 8.0
const TOP_GROUP_UNDERLINE_BOTTOM := 9.0
const TOP_GROUP_UNDERLINE_TRACK_HEIGHT := 2.0
const TOP_GROUP_UNDERLINE_ACTIVE_HEIGHT := 3.0

static var _top_group_active_gradient: GradientTexture1D = null
static var _top_group_font: SystemFont = null
static var _cta_micro_font_cache: SystemFont = null
static var _cta_main_font_cache: SystemFont = null
static var _cta_fill_texture: GradientTexture2D = null
static var _cta_fill_texture_disabled: GradientTexture2D = null
static func replace_chrome_buttons(host: Node, specs: Array, page, callback_name: String, theme_script) -> Array[Button]:
	for child in host.get_children():
		host.remove_child(child)
		child.queue_free()
	var buttons: Array[Button] = []
	for spec_value in specs:
		var spec: Dictionary = spec_value if spec_value is Dictionary else {}
		var button := build_chrome_button(theme_script, spec)
		button.name = str(spec.get("name", "ChromeButton"))
		var action_id := str(spec.get("actionId", ""))
		if page != null and page.has_method(callback_name):
			button.pressed.connect(Callable(page, callback_name).bind(action_id))
		host.add_child(button)
		buttons.append(button)
	return buttons
static func build_chrome_button(theme_script, spec: Dictionary) -> Button:
	var button := Button.new()
	button.text = str(spec.get("text", ""))
	button.clip_text = false
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if bool(spec.get("disabled", false)) else Control.CURSOR_POINTING_HAND
	var kind := str(spec.get("kind", "nav"))
	button.flat = kind != "top_group"
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL if kind == "nav" else Control.SIZE_SHRINK_BEGIN
	if kind == "nav":
		button.custom_minimum_size = Vector2(0.0, 48.0)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	elif kind == "tab":
		button.custom_minimum_size = Vector2(112.0, 40.0)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	elif kind == "top_group":
		button.custom_minimum_size = Vector2(TOP_GROUP_MIN_WIDTH, TOP_GROUP_HEIGHT)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		button.custom_minimum_size = Vector2(84.0, 40.0)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.disabled = bool(spec.get("disabled", false))
	button.set_meta("active", bool(spec.get("active", false)))
	button.set_meta("kind", kind)
	apply_chrome_button_theme(button, theme_script, kind, bool(spec.get("active", false)))
	return button
static func apply_chrome_button_theme(button: Button, theme_script, kind: String, active: bool) -> void:
	if kind == "top_group":
		apply_variant05_top_group_theme(button, theme_script, active)
		return
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, chrome_button_style(theme_script, kind, active, state == "hover" or state == "focus", state == "pressed", state == "disabled"))
	var font_size := 13 if kind == "nav" else 12
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_constant_override("h_separation", 8)
	button.add_theme_color_override("font_color", chrome_button_fg(kind, active, false))
	button.add_theme_color_override("font_pressed_color", chrome_button_fg(kind, active, false))
	button.add_theme_color_override("font_hover_color", chrome_button_fg(kind, active, true))
	button.add_theme_color_override("font_focus_color", chrome_button_fg(kind, active, true))
	button.add_theme_color_override("font_disabled_color", Color(0.56, 0.61, 0.58, 0.82))
static func apply_variant05_top_group_theme(button: Button, theme_script, active: bool) -> void:
	button.set_meta("design_spec", TOP_GROUP_SPEC_ID)
	button.set_meta("variant05_role", "primary" if active else "secondary")
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	style.content_margin_left = TOP_GROUP_PADDING_X
	style.content_margin_right = TOP_GROUP_PADDING_X
	style.content_margin_top = TOP_GROUP_PADDING_TOP
	style.content_margin_bottom = TOP_GROUP_PADDING_BOTTOM
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, style)
	button.add_theme_font_override("font", _variant05_top_group_font(theme_script))
	button.add_theme_font_size_override("font_size", TOP_GROUP_FONT_SIZE)
	button.add_theme_constant_override("h_separation", 0)
	var text_color := TOP_GROUP_TEXT_ACTIVE if active else TOP_GROUP_TEXT_SECONDARY
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)
	button.add_theme_color_override("font_disabled_color", text_color)
	_apply_variant05_underline(button, active)
static func _variant05_top_group_font(theme_script) -> SystemFont:
	if _top_group_font != null:
		return _top_group_font
	var font := SystemFont.new()
	var base_theme: Theme = theme_script.shared_theme() if theme_script != null else null
	if base_theme != null and base_theme.default_font is SystemFont:
		font.font_names = (base_theme.default_font as SystemFont).font_names.duplicate()
	else:
		font.font_names = PackedStringArray(["Malgun Gothic", "맑은 고딕", "Noto Sans CJK KR", "Noto Sans KR", "Apple SD Gothic Neo", "NanumGothic", "Segoe UI", "Arial Unicode MS"])
	font.font_weight = TOP_GROUP_FONT_WEIGHT
	font.font_italic = false
	font.font_stretch = 100
	_top_group_font = font
	return _top_group_font
static func _apply_variant05_underline(button: Button, active: bool) -> void:
	for child in button.get_children():
		if child is CanvasItem and str(child.get_meta("variant05_underline_role", "")) != "":
			child.queue_free()
	if active:
		var underline := TextureRect.new()
		underline.name = "Variant05UnderlineActive"
		underline.set_meta("variant05_underline_role", "active")
		underline.layout_mode = 1
		underline.anchor_top = 1.0
		underline.anchor_right = 1.0
		underline.anchor_bottom = 1.0
		underline.offset_left = TOP_GROUP_PADDING_X
		underline.offset_top = -(TOP_GROUP_UNDERLINE_BOTTOM + TOP_GROUP_UNDERLINE_ACTIVE_HEIGHT)
		underline.offset_right = -TOP_GROUP_PADDING_X
		underline.offset_bottom = -TOP_GROUP_UNDERLINE_BOTTOM
		underline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		underline.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		underline.stretch_mode = TextureRect.STRETCH_SCALE
		underline.texture = _variant05_active_gradient_texture()
		button.add_child(underline)
		return
	var track := ColorRect.new()
	track.name = "Variant05UnderlineTrack"
	track.set_meta("variant05_underline_role", "track")
	track.layout_mode = 1
	track.anchor_top = 1.0
	track.anchor_right = 1.0
	track.anchor_bottom = 1.0
	track.offset_left = TOP_GROUP_PADDING_X
	track.offset_top = -(TOP_GROUP_UNDERLINE_BOTTOM + TOP_GROUP_UNDERLINE_TRACK_HEIGHT)
	track.offset_right = -TOP_GROUP_PADDING_X
	track.offset_bottom = -TOP_GROUP_UNDERLINE_BOTTOM
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.color = TOP_GROUP_UNDERLINE_TRACK
	button.add_child(track)
static func _variant05_active_gradient_texture() -> GradientTexture1D:
	if _top_group_active_gradient != null:
		return _top_group_active_gradient
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	gradient.colors = PackedColorArray([Color(0.0, 0.0, 0.0, 0.0), TOP_GROUP_UNDERLINE_ACTIVE, TOP_GROUP_UNDERLINE_ACTIVE, Color(0.0, 0.0, 0.0, 0.0)])
	var texture := GradientTexture1D.new()
	texture.width = 256
	texture.gradient = gradient
	_top_group_active_gradient = texture
	return _top_group_active_gradient
static func _copy_weighted_font(theme_script, weight: int) -> SystemFont:
	var font := SystemFont.new()
	var base_theme: Theme = theme_script.shared_theme() if theme_script != null else null
	if base_theme != null and base_theme.default_font is SystemFont:
		font.font_names = (base_theme.default_font as SystemFont).font_names.duplicate()
	else:
		font.font_names = PackedStringArray(["Malgun Gothic", "맑은 고딕", "Noto Sans CJK KR", "Noto Sans KR", "Apple SD Gothic Neo", "NanumGothic", "Segoe UI", "Arial Unicode MS"])
	font.font_weight = weight
	font.font_italic = false
	font.font_stretch = 100
	return font
static func _cta_micro_font_resource(theme_script) -> SystemFont:
	if _cta_micro_font_cache != null:
		return _cta_micro_font_cache
	_cta_micro_font_cache = _copy_weighted_font(theme_script, 800)
	return _cta_micro_font_cache
static func _cta_main_font_resource(theme_script) -> SystemFont:
	if _cta_main_font_cache != null:
		return _cta_main_font_cache
	_cta_main_font_cache = _copy_weighted_font(theme_script, 800)
	return _cta_main_font_cache
static func _cta_fill_texture_resource(disabled: bool) -> GradientTexture2D:
	if disabled:
		if _cta_fill_texture_disabled == null:
			_cta_fill_texture_disabled = _build_cta_fill_texture(Color(0.08, 0.16, 0.10, 1.0), Color(0.08, 0.16, 0.10, 1.0))
		return _cta_fill_texture_disabled
	if _cta_fill_texture == null:
		_cta_fill_texture = _build_cta_fill_texture(Color(0.15, 0.44, 0.24, 1.0), Color(0.15, 0.44, 0.24, 1.0))
	return _cta_fill_texture
static func _build_cta_fill_texture(top: Color, bottom: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	gradient.colors = PackedColorArray([top, bottom])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_LINEAR
	texture.fill_from = Vector2(0.5, 0.0)
	texture.fill_to = Vector2(0.5, 1.0)
	return texture
static func chrome_button_fg(kind: String, active: bool, hovered: bool) -> Color:
	if kind == "action":
		return Color(0.98, 0.99, 0.99, 1.0) if hovered else Color(0.95, 0.98, 0.97, 0.98)
	if kind == "top_group":
		if active:
			return Color(0.15, 0.28, 0.21, 1.0)
		return Color(0.15, 0.28, 0.21, 0.96) if hovered else Color(0.15, 0.28, 0.21, 0.82)
	if active:
		return Color(0.12, 0.25, 0.16, 1.0)
	return Color(0.19, 0.31, 0.26, 1.0) if hovered else Color(0.23, 0.36, 0.30, 0.96)
static func chrome_button_style(theme_script, kind: String, active: bool, hovered: bool, pressed: bool, disabled: bool) -> StyleBoxFlat:
	if kind == "top_group":
		var top_group_style := StyleBoxFlat.new()
		var accent := Color(0.15, 0.28, 0.21, 0.18)
		var bg := Color(0.0, 0.0, 0.0, 0.0)
		if active:
			accent = Color(0.18, 0.37, 0.27, 0.92)
		elif hovered and not disabled:
			accent = Color(0.18, 0.37, 0.27, 0.42)
			bg = Color(1.0, 1.0, 1.0, 0.03)
		elif pressed and not disabled:
			accent = Color(0.18, 0.37, 0.27, 0.56)
			bg = Color(0.0, 0.0, 0.0, 0.03)
		elif disabled:
			accent = Color(0.15, 0.28, 0.21, 0.08)
		top_group_style.bg_color = bg
		top_group_style.border_color = accent
		top_group_style.draw_center = bg.a > 0.0
		top_group_style.border_width_bottom = 3 if active else 2
		top_group_style.content_margin_left = 14
		top_group_style.content_margin_right = 14
		top_group_style.content_margin_top = 8
		top_group_style.content_margin_bottom = 8
		return top_group_style
	var bg := Color(1.0, 1.0, 1.0, 0.12)
	var border := Color(0.37, 0.45, 0.42, 0.12)
	var radius := 18
	var shadow_alpha := 0.0
	if kind == "action":
		bg = Color(0.18, 0.38, 0.26, 0.96) if not disabled else Color(0.14, 0.20, 0.17, 0.78)
		border = Color(0.68, 0.90, 0.74, 0.26)
		radius = 999
		shadow_alpha = 0.12
	elif active:
		bg = Color(0.80, 0.94, 0.73, 1.0)
		border = Color(0.58, 0.84, 0.48, 0.24)
		shadow_alpha = 0.10
	elif kind == "nav":
		bg = Color(1.0, 1.0, 1.0, 0.06)
		border = Color(0.37, 0.45, 0.42, 0.08)
	if hovered and not disabled:
		bg = bg.lightened(0.08)
		border = border.lightened(0.10)
	if pressed and not disabled:
		bg = bg.darkened(0.08)
	var style: StyleBoxFlat = theme_script.surface_style(bg, border, radius, 1, shadow_alpha)
	style.shadow_size = 10 if shadow_alpha > 0.0 else 0
	style.shadow_offset = Vector2(0.0, 4.0)
	style.shadow_color = Color(0.0, 0.0, 0.0, shadow_alpha)
	style.content_margin_left = 14 if kind == "nav" else 16
	style.content_margin_right = 14 if kind == "nav" else 16
	style.content_margin_top = 11 if kind == "nav" else 10
	style.content_margin_bottom = 11 if kind == "nav" else 10
	return style
static func cta_style(theme_script, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = theme_script.surface_style(Color(0.0, 0.0, 0.0, 0.0), border, 0, 1, 0.0)
	style.draw_center = false
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_right = 1
	style.shadow_size = 0
	style.shadow_offset = Vector2.ZERO
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.0)
	return style
static func rail_scroll_track_style(theme_script, bg: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = theme_script.surface_style(bg, Color(0.0, 0.0, 0.0, 0.0), 0, 0, 0.0)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.shadow_size = 0
	style.border_width_left = 0
	style.border_width_top = 0
	style.border_width_right = 0
	style.border_width_bottom = 0
	return style
static func rail_scroll_grabber_style(theme_script, bg: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = theme_script.surface_style(bg, Color(1.0, 1.0, 1.0, 0.12), 0, 1, 0.0)
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.shadow_size = 0
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	return style
static func apply_top_bar_theme(page, tab_buttons: Array[Button], action_buttons: Array[Button], theme_script) -> void:
	page.top_bar.offset_bottom = TOP_GROUP_HEADER_HEIGHT
	page.workspace_margin.offset_top = TOP_GROUP_HEADER_HEIGHT
	page.top_bar_margin.add_theme_constant_override("margin_left", TOP_GROUP_HEADER_LEFT_PAD)
	page.top_bar_margin.add_theme_constant_override("margin_right", TOP_GROUP_HEADER_RIGHT_PAD)
	page.brand_label.add_theme_font_size_override("font_size", TOP_GROUP_BRAND_FONT_SIZE)
	page.brand_label.add_theme_color_override("font_color", TOP_GROUP_TEXT_ACTIVE)
	page.tabs_row.add_theme_constant_override("separation", TOP_GROUP_BUTTON_GAP)
	page.top_actions.visible = not action_buttons.is_empty()
	for button in tab_buttons:
		var kind := str(button.get_meta("kind", "tab"))
		apply_chrome_button_theme(button, theme_script, kind, bool(button.get_meta("active", false)))
	for button in action_buttons:
		var kind := str(button.get_meta("kind", "action"))
		apply_chrome_button_theme(button, theme_script, kind, bool(button.get_meta("active", false)))
static func apply_global_rail_theme(page, nav_buttons: Array[Button], theme_script) -> void:
	var portrait_style: StyleBoxFlat = page._surface_style(Color(0.94, 0.86, 0.66, 0.94), Color(0.62, 0.52, 0.35, 0.30), 999, 2, 0.16)
	portrait_style.shadow_size = 10
	portrait_style.shadow_offset = Vector2(0.0, 6.0)
	portrait_style.shadow_color = Color(0.24, 0.18, 0.08, 0.16)
	page.portrait_shell.add_theme_stylebox_override("panel", portrait_style)
	page.portrait_icon.add_theme_font_size_override("font_size", 32)
	page.portrait_icon.add_theme_color_override("font_color", Color(0.27, 0.50, 0.64, 1.0))
	page.leader_title.add_theme_font_size_override("font_size", 14)
	page.leader_title.add_theme_color_override("font_color", Color(0.13, 0.22, 0.18, 1.0))
	page.leader_rank.add_theme_font_size_override("font_size", 11)
	page.leader_rank.add_theme_color_override("font_color", Color(0.49, 0.43, 0.34, 1.0))
	page.rail_divider.modulate = Color(0.32, 0.40, 0.37, 0.16)
	for button in nav_buttons:
		apply_chrome_button_theme(button, theme_script, "nav", bool(button.get_meta("active", false)))
static func apply_hero_theme(page) -> void:
	var eyebrow_style: StyleBoxFlat = page._surface_style(Color(0.95, 0.97, 0.92, 0.82), Color(1.0, 1.0, 1.0, 0.46), 999, 1, 0.0)
	eyebrow_style.shadow_size = 0
	page.hero_eyebrow_shell.add_theme_stylebox_override("panel", eyebrow_style)
	page.hero_eyebrow.add_theme_font_size_override("font_size", 11)
	page.hero_eyebrow.add_theme_color_override("font_color", Color(0.18, 0.30, 0.22, 1.0))
	page.hero_name.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	page.hero_name.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.30))
	page.hero_name.add_theme_constant_override("outline_size", 1)
	page.hero_summary.add_theme_color_override("font_color", Color(0.95, 0.97, 0.98, 0.94))
	var clear_style: StyleBoxFlat = page._surface_style(Color(0.11, 0.38, 0.20, 0.74), Color(0.74, 0.92, 0.75, 0.28), 999, 1, 0.0)
	clear_style.shadow_size = 0
	page.clear_shell.add_theme_stylebox_override("panel", clear_style)
	page.clear_label.add_theme_font_size_override("font_size", 11)
	page.clear_label.add_theme_color_override("font_color", Color(0.88, 0.97, 0.88, 1.0))
static func apply_cards_scroll_theme(page, theme_script) -> void:
	page.cards_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	var bar: VScrollBar = page.cards_scroll.get_v_scroll_bar()
	if bar == null:
		return
	bar.custom_minimum_size = Vector2.ZERO
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("scroll", rail_scroll_track_style(theme_script, Color(0.0, 0.0, 0.0, 0.0)))
	bar.add_theme_stylebox_override("grabber", rail_scroll_grabber_style(theme_script, Color(0.0, 0.0, 0.0, 0.0)))
	bar.add_theme_stylebox_override("grabber_highlight", rail_scroll_grabber_style(theme_script, Color(0.0, 0.0, 0.0, 0.0)))
	bar.add_theme_stylebox_override("grabber_pressed", rail_scroll_grabber_style(theme_script, Color(0.0, 0.0, 0.0, 0.0)))
	bar.hide()
static func apply_cta_theme(page, theme_script) -> void:
	page.start_button.focus_mode = Control.FOCUS_NONE
	page.start_button.flat = false
	page.start_button.mouse_default_cursor_shape = Control.CURSOR_ARROW if page.start_button.disabled else Control.CURSOR_POINTING_HAND
	page.start_button.add_theme_stylebox_override("normal", cta_style(theme_script, Color(0.66, 0.92, 0.72, 0.86)))
	page.start_button.add_theme_stylebox_override("hover", cta_style(theme_script, Color(0.74, 0.96, 0.78, 0.94)))
	page.start_button.add_theme_stylebox_override("pressed", cta_style(theme_script, Color(0.58, 0.84, 0.64, 0.82)))
	page.start_button.add_theme_stylebox_override("focus", cta_style(theme_script, Color(0.74, 0.96, 0.78, 0.94)))
	page.start_button.add_theme_stylebox_override("disabled", cta_style(theme_script, Color(0.32, 0.48, 0.35, 0.56)))
	page.start_button_hint.add_theme_font_override("font", _cta_micro_font_resource(theme_script))
	page.start_button_hint.add_theme_color_override("font_color", Color(0.91, 0.97, 0.91, 0.84) if not page.start_button.disabled else Color(0.76, 0.82, 0.77, 0.62))
	page.start_button_hint.add_theme_font_size_override("font_size", 11)
	page.start_button_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	page.start_button_label.add_theme_font_override("font", _cta_main_font_resource(theme_script))
	page.start_button_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0) if not page.start_button.disabled else Color(0.84, 0.89, 0.84, 0.76))
	page.start_button_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.18))
	page.start_button_label.add_theme_constant_override("outline_size", 1)
	page.start_button_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	page.start_button_margin.add_theme_constant_override("margin_left", 18)
	page.start_button_margin.add_theme_constant_override("margin_right", 76)
	page.start_button_vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	page.start_button_vbox.add_theme_constant_override("separation", 0)
	_ensure_cta_spacer(page)
	_ensure_cta_decor(page)
static func _ensure_cta_spacer(page) -> void:
	var spacer := page.start_button_vbox.get_node_or_null("CTAFlexibleSpacer") as Control
	if spacer == null:
		spacer = Control.new()
		spacer.name = "CTAFlexibleSpacer"
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		page.start_button_vbox.add_child(spacer)
	page.start_button_vbox.move_child(spacer, 1)
static func _ensure_cta_decor(page) -> void:
	var fill := page.start_button.get_node_or_null("CTAFill") as TextureRect
	if fill == null:
		fill = TextureRect.new()
		fill.name = "CTAFill"
		fill.layout_mode = 1
		fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fill.stretch_mode = TextureRect.STRETCH_SCALE
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.start_button.add_child(fill)
		page.start_button.move_child(fill, 0)
	fill.texture = _cta_fill_texture_resource(page.start_button.disabled)
	fill.offset_left = 1.0
	fill.offset_top = 1.0
	fill.offset_right = -1.0
	fill.offset_bottom = -1.0
	var accent := page.start_button.get_node_or_null("AccentStrip") as ColorRect
	if accent == null:
		accent = ColorRect.new()
		accent.name = "AccentStrip"
		accent.layout_mode = 1
		accent.anchor_right = 1.0
		accent.offset_bottom = 1.0
		accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.start_button.add_child(accent)
		page.start_button.move_child(accent, 1)
	accent.offset_left = 1.0
	accent.offset_top = 1.0
	accent.offset_right = -1.0
	accent.color = Color(1.0, 1.0, 1.0, 0.08) if not page.start_button.disabled else Color(1.0, 1.0, 1.0, 0.03)
	var arrow_bay := page.start_button.get_node_or_null("ArrowBay") as ColorRect
	if arrow_bay == null:
		arrow_bay = ColorRect.new()
		arrow_bay.name = "ArrowBay"
		arrow_bay.layout_mode = 1
		arrow_bay.anchor_left = 1.0
		arrow_bay.anchor_top = 0.0
		arrow_bay.anchor_right = 1.0
		arrow_bay.anchor_bottom = 1.0
		arrow_bay.offset_left = -62.0
		arrow_bay.offset_right = 0.0
		arrow_bay.offset_bottom = 0.0
		arrow_bay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.start_button.add_child(arrow_bay)
		page.start_button.move_child(arrow_bay, 2)
	arrow_bay.offset_top = 1.0
	arrow_bay.offset_right = -1.0
	arrow_bay.offset_bottom = -1.0
	arrow_bay.color = Color(0.04, 0.06, 0.05, 1.0) if not page.start_button.disabled else Color(0.04, 0.06, 0.05, 0.88)
	var arrow_bay_border := page.start_button.get_node_or_null("ArrowBayBorder") as ColorRect
	if arrow_bay_border == null:
		arrow_bay_border = ColorRect.new()
		arrow_bay_border.name = "ArrowBayBorder"
		arrow_bay_border.layout_mode = 1
		arrow_bay_border.anchor_left = 1.0
		arrow_bay_border.anchor_top = 0.0
		arrow_bay_border.anchor_right = 1.0
		arrow_bay_border.anchor_bottom = 1.0
		arrow_bay_border.offset_left = -63.0
		arrow_bay_border.offset_right = -62.0
		arrow_bay_border.offset_bottom = 0.0
		arrow_bay_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.start_button.add_child(arrow_bay_border)
		page.start_button.move_child(arrow_bay_border, 3)
	arrow_bay_border.offset_top = 1.0
	arrow_bay_border.offset_bottom = -1.0
	arrow_bay_border.color = Color(0.68, 0.92, 0.73, 0.82) if not page.start_button.disabled else Color(0.32, 0.48, 0.35, 0.46)
	var arrow := page.start_button.get_node_or_null("ArrowLabel") as Label
	if arrow == null:
		arrow = Label.new()
		arrow.name = "ArrowLabel"
		arrow.layout_mode = 1
		arrow.anchor_left = 1.0
		arrow.anchor_top = 0.5
		arrow.anchor_right = 1.0
		arrow.anchor_bottom = 0.5
		arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.start_button.add_child(arrow)
	arrow.offset_left = -46.0
	arrow.offset_top = -18.0
	arrow.offset_right = -16.0
	arrow.offset_bottom = 18.0
	arrow.text = "↗"
	arrow.add_theme_font_size_override("font_size", 30)
	arrow.add_theme_color_override("font_color", Color(0.97, 1.0, 0.96, 1.0) if not page.start_button.disabled else Color(0.82, 0.88, 0.83, 0.78))
