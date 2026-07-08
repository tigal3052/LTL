class_name LeviathanSelectRailCardFactory
extends RefCounted

static func build_preview_card(theme_script, view_bits_script, spec: Dictionary, on_gui_input: Callable = Callable()) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.clip_contents = true
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0.0, float(spec.get("height", 86.0)))
	panel.set_meta("rail_card_height_scale", float(spec.get("scale", 0.95)))
	panel.set_meta("leviathan_preview_card", true)
	if on_gui_input.is_valid():
		panel.gui_input.connect(on_gui_input.bind(panel))
	var preview_style := (view_bits_script.card_style(theme_script, false, false, false) as StyleBoxFlat).duplicate() as StyleBoxFlat
	if preview_style != null:
		preview_style.shadow_size = 0
		preview_style.border_width_left = 0
		preview_style.border_width_top = 0
		preview_style.border_width_right = 0
		preview_style.border_width_bottom = 0
		preview_style.corner_radius_top_left = 0
		preview_style.corner_radius_top_right = 0
		preview_style.corner_radius_bottom_left = 0
		preview_style.corner_radius_bottom_right = 0
	panel.add_theme_stylebox_override("panel", preview_style)
	view_bits_script.build_rail_card_visual(panel, {
		"backdrop_color": Color(0.02, 0.03, 0.04, 1.0),
		"veil_color": Color(0.02, 0.02, 0.03, 0.84),
		"title": str(spec.get("title", "")),
		"title_clip_text": true,
		"title_color": Color(0.92, 0.92, 0.92, 0.9),
		"meta": str(spec.get("meta", "")),
		"meta_clip_text": true,
		"meta_color": Color(0.72, 0.73, 0.75, 0.76),
		"biome": str(spec.get("biome", "")),
		"biome_clip_text": true,
		"biome_color": Color(0.64, 0.65, 0.67, 0.64),
		"content_margin_right": 16,
		"placeholder_text": str(spec.get("placeholder_text", "")),
		"placeholder_font_size": 46 if str(spec.get("placeholder_text", "")).to_upper() == "LOCK" else 56,
		"placeholder_color": Color(0.94, 0.94, 0.94, 0.10) if str(spec.get("placeholder_text", "")).to_upper() == "LOCK" else Color(0.96, 0.96, 0.96, 0.12),
	})
	return panel

static func build_leviathan_card(
	theme_script,
	text_catalog_script,
	view_bits_script,
	leviathan: Dictionary,
	selected_id: String,
	hero_height: float,
	card_height_ratio: float,
	card_height_min: float,
	card_height_max: float,
	unlocked: bool,
	cleared: bool,
	on_pressed: Callable,
	on_gui_input: Callable
) -> Button:
	var locale = text_catalog_script.locale()
	var leviathan_id := str(leviathan.get("id", ""))
	var selected := leviathan_id == selected_id
	var button := Button.new()
	button.text = ""
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if unlocked else Control.CURSOR_ARROW
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.set_meta("rail_card_height_scale", 1.0)
	button.custom_minimum_size = Vector2(0.0, clampf(hero_height * card_height_ratio, card_height_min, card_height_max))
	button.disabled = not unlocked
	view_bits_script.apply_rail_card_button_theme(button, theme_script, selected, unlocked)
	if on_gui_input.is_valid():
		button.gui_input.connect(on_gui_input.bind(button))
	if on_pressed.is_valid():
		button.pressed.connect(on_pressed.bind(leviathan_id, unlocked))
	view_bits_script.build_rail_card_visual(button, {
		"art_texture": theme_script.art_texture(str(leviathan.get("artPath", ""))),
		"art_modulate": Color(1.0, 1.0, 1.0, 1.0) if (selected and unlocked) else (Color(0.60, 0.63, 0.64, 1.0) if unlocked else Color(0.42, 0.42, 0.42, 1.0)),
		"veil_color": view_bits_script.card_veil_color(selected, unlocked),
		"selected": selected and unlocked,
		"selection_tint_color": Color(0.16, 0.33, 0.22, 0.20),
		"selection_strip_color": Color(0.57, 0.82, 0.63, 1.0),
		"title": str(leviathan.get("name", leviathan_id)),
		"title_autowrap_mode": TextServer.AUTOWRAP_WORD_SMART,
		"title_color": Color(1.0, 1.0, 1.0, 0.98) if unlocked else Color(0.82, 0.82, 0.82, 0.92),
		"title_outline_color": Color(0.0, 0.0, 0.0, 0.24),
		"title_outline_size": 1,
		"meta": view_bits_script.card_subtitle_text(locale, int(leviathan.get("runCount", leviathan.get("runCnt", 1))), int(leviathan.get("stageCount", leviathan.get("stageCnt", 1)))),
		"meta_color": Color(0.89, 0.93, 0.94, 0.84) if unlocked else Color(0.75, 0.77, 0.78, 0.84),
		"biome": str(leviathan.get("biome", text_catalog_script.t("leviathan.biome_unknown"))),
		"biome_autowrap_mode": TextServer.AUTOWRAP_WORD_SMART,
		"biome_color": Color(0.84, 0.87, 0.88, 0.72) if unlocked else Color(0.74, 0.75, 0.76, 0.72),
		"content_expand_horizontal": true,
		"content_expand_vertical": true,
	})
	if cleared and unlocked and not selected:
		button.add_child(view_bits_script.build_abs_pill(
			theme_script,
			view_bits_script.clear_label_text(locale),
			Vector2(-82.0, 12.0),
			Vector2(70.0, 26.0),
			Color(0.10, 0.31, 0.16, 0.54),
			Color(0.78, 0.92, 0.76, 0.16),
			Color(0.90, 0.98, 0.90, 1.0),
			10,
			true
		))
	if not unlocked:
		button.add_child(view_bits_script.build_abs_pill(
			theme_script,
			view_bits_script.locked_badge_text(locale),
			Vector2(-80.0, 12.0),
			Vector2(66.0, 28.0),
			Color(0.05, 0.06, 0.07, 0.58),
			Color(1.0, 1.0, 1.0, 0.08),
			Color(0.96, 0.96, 0.96, 0.82),
			10,
			true
		))
	return button
