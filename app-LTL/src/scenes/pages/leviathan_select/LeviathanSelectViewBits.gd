class_name LeviathanSelectViewBits
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
const RAIL_CARD_VISUAL_FAMILY := "overlay-rail-shared-shell-v1"
const RAIL_CARD_SELECTION_STRIP_WIDTH := 4.0
const RAIL_CARD_CONTENT_MARGIN_LEFT := 18
const RAIL_CARD_CONTENT_MARGIN_TOP := 18
const RAIL_CARD_CONTENT_MARGIN_RIGHT := 18
const RAIL_CARD_CONTENT_MARGIN_BOTTOM := 14
const RAIL_CARD_CONTENT_SEPARATION := 4
const RAIL_CARD_TITLE_FONT_SIZE := 17
const RAIL_CARD_META_FONT_SIZE := 12
const RAIL_CARD_PLACEHOLDER_LOCK_FONT_SIZE := 46
const RAIL_CARD_PLACEHOLDER_DEFAULT_FONT_SIZE := 56
const RAIL_CARD_DRAG_THRESHOLD := 6.0

static var _top_group_active_gradient: GradientTexture1D = null
static var _top_group_font: SystemFont = null
static var _cta_micro_font_cache: SystemFont = null
static var _cta_main_font_cache: SystemFont = null
static var _cta_fill_texture: GradientTexture2D = null
static var _cta_fill_texture_disabled: GradientTexture2D = null

const ChromeBitsScript = preload("res://src/scenes/pages/leviathan_select/LeviathanSelectChromeBits.gd")

static func hero_eyebrow_text(locale: String, unlocked: bool, target_kicker: String) -> String:
	if unlocked:
		return target_kicker
	return "봉인 계약" if locale == "ko" else "LOCKED CONTRACT"

static func hero_summary_text(locale: String, name: String, biome_text: String, unlocked: bool, target_core_text: String) -> String:
	if unlocked:
		return "%s · %s" % [target_core_text, biome_text]
	return ("선행 탐사 기록이 확보되면 %s 계약이 열린다. %s" % [name, biome_text]) if locale == "ko" else ("Secure the prior expedition proof to unlock %s. %s" % [name, biome_text])

static func card_subtitle_text(locale: String, run_count: int, stage_count: int) -> String:
	if run_count <= 0 or stage_count <= 0:
		return "항차 ? · 구간 ?" if locale == "ko" else "Run ? · Stage ?"
	if locale == "ko":
		return "항차 %d · 구간 %d" % [run_count, stage_count]
	return "Run %d · Stage %d" % [run_count, stage_count]

static func run_chip_text(locale: String, value: int) -> String:
	if value <= 0:
		return "항차 ?" if locale == "ko" else "Run ?"
	return ("항차 %d" % value) if locale == "ko" else ("Run %d" % value)

static func stage_chip_text(locale: String, value: int) -> String:
	if value <= 0:
		return "구간 ?" if locale == "ko" else "Stage ?"
	return ("구간 %d" % value) if locale == "ko" else ("Stage %d" % value)

static func clear_label_text(locale: String) -> String:
	return "기록 완료" if locale == "ko" else "LOGGED"

static func locked_badge_text(locale: String) -> String:
	return "잠금" if locale == "ko" else "LOCKED"

static func locked_hint_text(locale: String) -> String:
	return "연구 필요" if locale == "ko" else "RESEARCH REQUIRED"

static func locked_button_text(locale: String) -> String:
	return "잠금됨" if locale == "ko" else "LOCKED"

static func card_state_text(locale: String, selected: bool, unlocked: bool) -> String:
	if selected and unlocked:
		return "현재 선택" if locale == "ko" else "CURRENT"
	if unlocked:
		return "미선택" if locale == "ko" else "AVAILABLE"
	return locked_badge_text(locale)

static func card_state_bg(selected: bool, unlocked: bool) -> Color:
	if selected and unlocked:
		return Color(0.94, 0.97, 0.92, 0.22)
	if unlocked:
		return Color(0.96, 0.97, 0.98, 0.14)
	return Color(0.06, 0.07, 0.08, 0.52)

static func card_state_border(selected: bool, unlocked: bool) -> Color:
	if selected and unlocked:
		return Color(0.82, 0.94, 0.80, 0.22)
	if unlocked:
		return Color(1.0, 1.0, 1.0, 0.12)
	return Color(1.0, 1.0, 1.0, 0.08)

static func card_state_fg(selected: bool, unlocked: bool) -> Color:
	if selected and unlocked:
		return Color(0.92, 0.98, 0.92, 1.0)
	if unlocked:
		return Color(0.92, 0.96, 0.97, 0.96)
	return Color(0.90, 0.90, 0.90, 0.82)

static func card_veil_color(selected: bool, unlocked: bool) -> Color:
	if selected and unlocked:
		return Color(0.02, 0.08, 0.05, 0.26)
	if unlocked:
		return Color(0.02, 0.03, 0.04, 0.58)
	return Color(0.02, 0.02, 0.03, 0.74)

static func rail_card_visual_family() -> String:
	return RAIL_CARD_VISUAL_FAMILY

static func rail_card_drag_threshold() -> float:
	return RAIL_CARD_DRAG_THRESHOLD

static func apply_rail_card_button_theme(button: Button, theme_script, selected: bool, unlocked: bool) -> void:
	button.add_theme_stylebox_override("normal", card_style(theme_script, selected, unlocked, false))
	button.add_theme_stylebox_override("hover", card_style(theme_script, selected, unlocked, true))
	button.add_theme_stylebox_override("pressed", card_style(theme_script, selected, unlocked, true, true))
	button.add_theme_stylebox_override("focus", card_style(theme_script, selected, unlocked, true))
	button.add_theme_stylebox_override("disabled", card_style(theme_script, selected, unlocked, false))

static func build_rail_card_visual(host: Control, spec: Dictionary) -> Dictionary:
	host.set_meta("rail_card_visual_family", RAIL_CARD_VISUAL_FAMILY)
	var root := Control.new()
	root.name = "CardVisualRoot"
	root.layout_mode = 1
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(root)
	var backdrop_color: Color = spec.get("backdrop_color", Color(0.0, 0.0, 0.0, 0.0))
	if backdrop_color.a > 0.0:
		var backdrop := ColorRect.new()
		backdrop.name = "CardBackdrop"
		backdrop.layout_mode = 1
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.color = backdrop_color
		root.add_child(backdrop)
	var art_texture = spec.get("art_texture", null)
	if art_texture != null:
		var art := TextureRect.new()
		art.name = "CardArt"
		art.layout_mode = 1
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art.grow_horizontal = Control.GROW_DIRECTION_BOTH
		art.grow_vertical = Control.GROW_DIRECTION_BOTH
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.texture = art_texture
		art.self_modulate = spec.get("art_modulate", Color(1.0, 1.0, 1.0, 1.0))
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(art)
	var placeholder_text := str(spec.get("placeholder_text", ""))
	if not placeholder_text.is_empty():
		var placeholder := Label.new()
		placeholder.name = "PlaceholderIcon"
		placeholder.layout_mode = 1
		placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		placeholder.text = placeholder_text
		placeholder.add_theme_font_size_override("font_size", int(spec.get("placeholder_font_size", RAIL_CARD_PLACEHOLDER_DEFAULT_FONT_SIZE)))
		placeholder.add_theme_color_override("font_color", spec.get("placeholder_color", Color(1.0, 1.0, 1.0, 0.10)))
		placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(placeholder)
	var veil := ColorRect.new()
	veil.name = "CardVeil"
	veil.layout_mode = 1
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.color = spec.get("veil_color", Color(0.02, 0.03, 0.04, 0.58))
	root.add_child(veil)
	var strip_selected := bool(spec.get("selected", false)) and bool(spec.get("show_selection_strip", true))
	if strip_selected and bool(spec.get("show_selection_tint", false)):
		var selection_tint := ColorRect.new()
		selection_tint.name = "SelectionTint"
		selection_tint.layout_mode = 1
		selection_tint.anchor_bottom = 1.0
		selection_tint.offset_right = float(spec.get("selection_tint_width", RAIL_CARD_SELECTION_STRIP_WIDTH))
		selection_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		selection_tint.color = spec.get("selection_tint_color", Color(0.13, 0.27, 0.18, 0.18))
		root.add_child(selection_tint)
	var selection_strip := ColorRect.new()
	selection_strip.name = "SelectionStrip"
	selection_strip.layout_mode = 1
	selection_strip.anchor_bottom = 1.0
	selection_strip.offset_right = RAIL_CARD_SELECTION_STRIP_WIDTH
	selection_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_strip.color = spec.get("selection_strip_color", Color(0.57, 0.82, 0.63, 1.0)) if strip_selected else Color(0.0, 0.0, 0.0, 0.0)
	root.add_child(selection_strip)
	var content_margin := MarginContainer.new()
	content_margin.name = "CardContentMargin"
	content_margin.layout_mode = 1
	content_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_margin.add_theme_constant_override("margin_left", int(spec.get("content_margin_left", RAIL_CARD_CONTENT_MARGIN_LEFT)))
	content_margin.add_theme_constant_override("margin_top", int(spec.get("content_margin_top", RAIL_CARD_CONTENT_MARGIN_TOP)))
	content_margin.add_theme_constant_override("margin_right", int(spec.get("content_margin_right", RAIL_CARD_CONTENT_MARGIN_RIGHT)))
	content_margin.add_theme_constant_override("margin_bottom", int(spec.get("content_margin_bottom", RAIL_CARD_CONTENT_MARGIN_BOTTOM)))
	content_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(content_margin)
	var content_vbox := VBoxContainer.new()
	content_vbox.name = "CardContentVBox"
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL if bool(spec.get("content_expand_horizontal", false)) else Control.SIZE_SHRINK_BEGIN
	content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL if bool(spec.get("content_expand_vertical", false)) else Control.SIZE_SHRINK_CENTER
	content_vbox.add_theme_constant_override("separation", int(spec.get("content_separation", RAIL_CARD_CONTENT_SEPARATION)))
	content_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_margin.add_child(content_vbox)
	var title := Label.new()
	title.name = "CardTitle"
	title.text = str(spec.get("title", ""))
	title.clip_text = bool(spec.get("title_clip_text", false))
	title.autowrap_mode = int(spec.get("title_autowrap_mode", TextServer.AUTOWRAP_OFF))
	title.add_theme_font_size_override("font_size", int(spec.get("title_font_size", RAIL_CARD_TITLE_FONT_SIZE)))
	title.add_theme_color_override("font_color", spec.get("title_color", Color(0.95, 0.96, 0.97, 0.90)))
	if spec.has("title_outline_color"):
		title.add_theme_color_override("font_outline_color", spec.get("title_outline_color"))
	if spec.has("title_outline_size"):
		title.add_theme_constant_override("outline_size", int(spec.get("title_outline_size", 0)))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(title)
	var meta := Label.new()
	meta.name = "CardMeta"
	meta.text = str(spec.get("meta", ""))
	meta.clip_text = bool(spec.get("meta_clip_text", false))
	meta.autowrap_mode = int(spec.get("meta_autowrap_mode", TextServer.AUTOWRAP_OFF))
	meta.add_theme_font_size_override("font_size", int(spec.get("meta_font_size", RAIL_CARD_META_FONT_SIZE)))
	meta.add_theme_color_override("font_color", spec.get("meta_color", Color(0.76, 0.79, 0.82, 0.70)))
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(meta)
	var biome := Label.new()
	biome.name = "CardBiome"
	biome.text = str(spec.get("biome", ""))
	biome.clip_text = bool(spec.get("biome_clip_text", false))
	biome.autowrap_mode = int(spec.get("biome_autowrap_mode", TextServer.AUTOWRAP_OFF))
	biome.add_theme_font_size_override("font_size", int(spec.get("biome_font_size", RAIL_CARD_META_FONT_SIZE)))
	biome.add_theme_color_override("font_color", spec.get("biome_color", Color(0.60, 0.65, 0.69, 0.62)))
	biome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_vbox.add_child(biome)
	return {
		"root": root,
		"content_margin": content_margin,
		"content_vbox": content_vbox,
		"title": title,
		"meta": meta,
		"biome": biome,
	}

static func build_fact_pill(theme_script, text: String, active: bool, font_size: int = 11) -> PanelContainer:
	var shell := PanelContainer.new()
	shell.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = theme_script.surface_style(
		Color(0.95, 0.98, 0.98, 0.18) if active else Color(0.08, 0.09, 0.10, 0.46),
		Color(1.0, 1.0, 1.0, 0.12),
		999,
		1,
		0.0
	)
	style.shadow_size = 0
	shell.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 7)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.add_child(margin)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.96, 0.98, 0.99, 0.96) if active else Color(0.78, 0.80, 0.82, 0.88))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(label)
	return shell

static func build_abs_pill(theme_script, text: String, top_left: Vector2, size_hint: Vector2, bg: Color, border: Color, fg: Color, font_size: int = 11, stick_right: bool = false) -> PanelContainer:
	var shell := PanelContainer.new()
	shell.layout_mode = 1
	if stick_right:
		shell.anchor_left = 1.0
		shell.anchor_right = 1.0
		shell.offset_left = top_left.x
		shell.offset_right = top_left.y
	else:
		shell.offset_left = top_left.x
		shell.offset_right = top_left.x + size_hint.x
	shell.offset_top = top_left.y
	shell.offset_bottom = top_left.y + size_hint.y
	shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = theme_script.surface_style(bg, border, 999, 1, 0.0)
	style.shadow_size = 0
	shell.add_theme_stylebox_override("panel", style)
	var margin := MarginContainer.new()
	margin.layout_mode = 1
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shell.add_child(margin)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", fg)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(label)
	return shell

static func card_style(theme_script, selected: bool, unlocked: bool, hovered: bool, pressed := false) -> StyleBoxFlat:
	var style: StyleBoxFlat = theme_script.surface_style(Color(0.0, 0.0, 0.0, 0.0), Color(1.0, 1.0, 1.0, 0.08), 0, 0, 0.0)
	style.shadow_size = 0
	style.corner_radius_top_left = 0
	style.corner_radius_top_right = 0
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.border_width_left = 0
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.content_margin_left = 0
	style.content_margin_top = 0
	style.content_margin_right = 0
	style.content_margin_bottom = 0
	if selected and unlocked:
		style.border_color = Color(1.0, 1.0, 1.0, 0.10)
		style.bg_color = Color(1.0, 1.0, 1.0, 0.02)
	elif hovered and unlocked:
		style.border_color = Color(1.0, 1.0, 1.0, 0.12)
		style.bg_color = Color(1.0, 1.0, 1.0, 0.03)
	elif not unlocked:
		style.border_color = Color(1.0, 1.0, 1.0, 0.06)
		style.bg_color = Color(0.0, 0.0, 0.0, 0.06)
	else:
		style.border_color = Color(1.0, 1.0, 1.0, 0.08)
	if pressed:
		style.bg_color = Color(0.0, 0.0, 0.0, 0.10)
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

static func replace_chrome_buttons(host: Node, specs: Array, page, callback_name: String, theme_script) -> Array[Button]:
	return ChromeBitsScript.replace_chrome_buttons(host, specs, page, callback_name, theme_script)

static func apply_top_bar_theme(page, tab_buttons: Array[Button], action_buttons: Array[Button], theme_script) -> void:
	ChromeBitsScript.apply_top_bar_theme(page, tab_buttons, action_buttons, theme_script)

static func apply_global_rail_theme(page, nav_buttons: Array[Button], theme_script) -> void:
	ChromeBitsScript.apply_global_rail_theme(page, nav_buttons, theme_script)

static func apply_hero_theme(page) -> void:
	ChromeBitsScript.apply_hero_theme(page)

static func apply_cards_scroll_theme(page, theme_script) -> void:
	ChromeBitsScript.apply_cards_scroll_theme(page, theme_script)

static func apply_cta_theme(page, theme_script) -> void:
	ChromeBitsScript.apply_cta_theme(page, theme_script)
