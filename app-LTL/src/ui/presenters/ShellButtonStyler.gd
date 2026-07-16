extends RefCounted

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")

static func apply_button(button: Button, header_actions: HBoxContainer, action_bar: BoxContainer) -> void:
	if button == null:
		return
	if _is_battle_cta(button):
		_apply_battle_cta_button(button)
		return
	if header_actions != null and button.get_parent() == header_actions:
		_apply_header_util_button(button)
		return
	if button.name == "ClaimInlineButton":
		_apply_reward_claim_button(button)
		return
	var accent := _accent(button)
	var normal := _style(accent, "normal")
	var hover := _style(accent, "hover")
	var pressed := _style(accent, "pressed")
	var disabled := _style(accent, "disabled")
	_set_margin(normal)
	_set_margin(hover)
	_set_margin(pressed)
	_set_margin(disabled)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	button.add_theme_color_override("font_hover_color", LTLThemeScript.TEXT_PRIMARY)
	button.add_theme_color_override("font_pressed_color", LTLThemeScript.TEXT_PRIMARY)
	button.add_theme_color_override("font_focus_color", LTLThemeScript.TEXT_PRIMARY)
	button.add_theme_color_override("font_disabled_color", _disabled_text_color(accent))
	button.custom_minimum_size.x = maxf(button.custom_minimum_size.x, _min_width(button, header_actions, action_bar))
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 42.0 if accent == "utility" else 52.0)

# 전투 리디자인: 보드 우측 세로 CTA 기둥 소속 버튼 판별 (VBoxContainer ActionBar 하위)
static func _is_battle_cta(button: Button) -> bool:
	var parent := button.get_parent()
	return parent is VBoxContainer and parent.name == "ActionBar"

# 전투 리디자인: 굴착 포기 = error 톤 / 굴착 시작·보상 = Hero 톤 세로 CTA 스타일
static func _apply_battle_cta_button(button: Button) -> void:
	var is_danger := button.name == "ResetButton"
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := LTLThemeScript.danger_button_style(state) if is_danger else LTLThemeScript.hero_button_style(state)
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 9
		style.content_margin_bottom = 9
		button.add_theme_stylebox_override(state, style)
	button.add_theme_stylebox_override("focus", LTLThemeScript.danger_button_style("hover") if is_danger else LTLThemeScript.hero_button_style("hover"))
	var font_color := LTLThemeScript.ERROR if is_danger else LTLThemeScript.ON_PRIMARY
	button.add_theme_font_size_override("font_size", 14)
	for color_key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_key, font_color)
	button.add_theme_color_override("font_disabled_color", Color(font_color.r, font_color.g, font_color.b, 0.55))
	button.custom_minimum_size.x = maxf(button.custom_minimum_size.x, 96.0)
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 46.0)

# 보상 리디자인: 기록 완료(획득 확정) CTA = Hero 톤 (전투 CTA 기둥의 굴착 시작 버튼과 동일한 라이트 팔레트)
static func _apply_reward_claim_button(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := LTLThemeScript.hero_button_style(state)
		style.content_margin_left = 20
		style.content_margin_right = 20
		style.content_margin_top = 12
		style.content_margin_bottom = 12
		button.add_theme_stylebox_override(state, style)
	button.add_theme_stylebox_override("focus", LTLThemeScript.hero_button_style("hover"))
	button.add_theme_font_size_override("font_size", 14)
	for color_key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_key, LTLThemeScript.ON_PRIMARY)
	button.add_theme_color_override("font_disabled_color", Color(LTLThemeScript.ON_PRIMARY.r, LTLThemeScript.ON_PRIMARY.g, LTLThemeScript.ON_PRIMARY.b, 0.55))
	button.custom_minimum_size.x = maxf(button.custom_minimum_size.x, 156.0)
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 42.0)

# 전투 리디자인: 헤더 유틸 버튼 = variant05 언더라인 스타일 (라이트 스트립 위 투명 버튼)
static func _apply_header_util_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.border_width_bottom = 2
	normal.border_color = Color(0.153, 0.278, 0.208, 0.30)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_width_bottom = 3
	hover.border_color = Color(0.176, 0.373, 0.267, 0.88)
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.153, 0.278, 0.208, 0.08)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_font_size_override("font_size", 14)
	for color_key in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_key, Color(0.153, 0.278, 0.212, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.153, 0.278, 0.212, 0.45))
	button.custom_minimum_size.x = maxf(button.custom_minimum_size.x, 108.0)
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 40.0)

static func _accent(button: Button) -> String:
	if button.name == "ResetButton":
		return "reset"
	if button.name == "StartButton":
		return "start"
	return "utility"

static func _style(accent: String, state: String) -> StyleBoxFlat:
	if accent == "reset":
		if state == "hover":
			return LTLThemeScript.surface_style(Color(0.45, 0.31, 0.20, 0.98), Color(0.84, 0.66, 0.42, 1.0), 14, 1, 0.28)
		if state == "pressed":
			return LTLThemeScript.surface_style(Color(0.28, 0.19, 0.11, 0.98), Color(0.63, 0.48, 0.27, 1.0), 14, 1, 0.18)
		if state == "disabled":
			return LTLThemeScript.surface_style(Color(0.34, 0.24, 0.16, 0.98), Color(0.58, 0.45, 0.28, 0.92), 14, 1, 0.20)
		return LTLThemeScript.surface_style(Color(0.36, 0.25, 0.16, 0.98), Color(0.63, 0.49, 0.30, 1.0), 14, 1, 0.24)
	if accent == "start":
		if state == "hover":
			return LTLThemeScript.surface_style(Color(0.64, 0.28, 0.21, 0.98), Color(0.92, 0.66, 0.55, 1.0), 14, 1, 0.30)
		if state == "pressed":
			return LTLThemeScript.surface_style(Color(0.38, 0.14, 0.11, 0.98), Color(0.72, 0.39, 0.31, 1.0), 14, 1, 0.18)
		if state == "disabled":
			return LTLThemeScript.surface_style(Color(0.12, 0.10, 0.10, 0.96), Color(0.31, 0.25, 0.22, 0.86), 14, 1, 0.08)
		return LTLThemeScript.surface_style(Color(0.53, 0.21, 0.16, 0.98), Color(0.77, 0.46, 0.36, 1.0), 14, 1, 0.26)
	if state == "hover":
		return LTLThemeScript.surface_style(Color(0.21, 0.15, 0.11, 0.98), LTLThemeScript.BORDER_WARM, 12, 1, 0.22)
	if state == "pressed":
		return LTLThemeScript.surface_style(Color(0.13, 0.10, 0.07, 0.98), Color(0.47, 0.37, 0.21, 1.0), 12, 1, 0.14)
	if state == "disabled":
		return LTLThemeScript.surface_style(Color(0.17, 0.12, 0.09, 0.98), Color(0.35, 0.28, 0.18, 0.92), 12, 1, 0.14)
	return LTLThemeScript.surface_style(Color(0.18, 0.13, 0.09, 0.98), Color(0.38, 0.31, 0.19, 1.0), 12, 1, 0.18)

static func _disabled_text_color(accent: String) -> Color:
	if accent == "start":
		return Color(0.62, 0.58, 0.54, 0.86)
	if accent == "reset":
		return Color(0.96, 0.92, 0.86, 0.98)
	return Color(0.95, 0.91, 0.84, 0.96)

static func _set_margin(style: StyleBoxFlat) -> void:
	style.content_margin_left = 16
	style.content_margin_right = 16

static func _min_width(button: Button, header_actions: HBoxContainer, action_bar: BoxContainer) -> float:
	if button.get_parent() == header_actions:
		return 108.0
	if button.get_parent() == action_bar:
		return 180.0 if button.name == "StartButton" else 156.0
	return 112.0
