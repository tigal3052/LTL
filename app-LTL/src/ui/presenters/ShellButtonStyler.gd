extends RefCounted

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")

static func apply_button(button: Button, header_actions: HBoxContainer, action_bar: HBoxContainer) -> void:
	if button == null:
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

static func _min_width(button: Button, header_actions: HBoxContainer, action_bar: HBoxContainer) -> float:
	if button.get_parent() == header_actions:
		return 108.0
	if button.get_parent() == action_bar:
		return 180.0 if button.name == "StartButton" else 156.0
	return 112.0
