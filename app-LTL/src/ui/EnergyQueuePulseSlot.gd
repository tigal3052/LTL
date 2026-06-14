class_name EnergyQueuePulseSlot
extends Control

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")

var energy_color := ""
var slot_enabled := true
var slot_loaded := false
var front_slot := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(34.0, 22.0)
	queue_redraw()

func configure(color_name: String, is_loaded: bool, is_enabled: bool, is_front: bool) -> void:
	energy_color = color_name
	slot_loaded = is_loaded
	slot_enabled = is_enabled
	front_slot = is_front
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_style_box(_outer_style(), rect)
	draw_style_box(_inner_style(), rect.grow(-3.0))
	var content_rect := rect.grow(-6.0)
	if not slot_enabled:
		_draw_disabled_state(content_rect)
		return
	if slot_loaded and not energy_color.is_empty():
		_draw_loaded_wave(content_rect, LTLThemeScript.accent_color(energy_color))
	else:
		_draw_empty_state(content_rect)
	if front_slot:
		draw_rect(rect.grow(-1.5), Color(0.90, 0.74, 0.34, 0.34), false, 2.0)

func _outer_style() -> StyleBoxFlat:
	var border := Color(0.24, 0.30, 0.38, 1.0) if slot_enabled else Color(0.17, 0.20, 0.24, 1.0)
	if front_slot and slot_enabled:
		border = Color(0.80, 0.62, 0.28, 1.0)
	return LTLThemeScript.surface_style(
		Color(0.08, 0.10, 0.13, 0.98),
		border,
		10,
		1,
		0.16
	)

func _inner_style() -> StyleBoxFlat:
	var bg := Color(0.05, 0.08, 0.11, 0.96)
	if slot_enabled and slot_loaded and not energy_color.is_empty():
		var accent := LTLThemeScript.accent_color(energy_color)
		bg = Color(
			lerpf(0.08, accent.r, 0.16),
			lerpf(0.10, accent.g, 0.12),
			lerpf(0.14, accent.b, 0.16),
			0.96
		)
	elif slot_enabled:
		bg = Color(0.06, 0.08, 0.11, 0.92)
	return LTLThemeScript.surface_style(
		bg,
		Color(0.11, 0.15, 0.19, 0.55),
		8,
		1,
		0.0
	)

func _draw_loaded_wave(content_rect: Rect2, accent: Color) -> void:
	var glow := Color(accent.r, accent.g, accent.b, 0.18)
	var deep_glow := Color(accent.r, accent.g, accent.b, 0.08)
	var points := PackedVector2Array([
		Vector2(content_rect.position.x, content_rect.position.y + content_rect.size.y * 0.55),
		Vector2(content_rect.position.x + content_rect.size.x * 0.17, content_rect.position.y + content_rect.size.y * 0.55),
		Vector2(content_rect.position.x + content_rect.size.x * 0.29, content_rect.position.y + content_rect.size.y * 0.68),
		Vector2(content_rect.position.x + content_rect.size.x * 0.47, content_rect.position.y + content_rect.size.y * 0.18),
		Vector2(content_rect.position.x + content_rect.size.x * 0.63, content_rect.position.y + content_rect.size.y * 0.82),
		Vector2(content_rect.position.x + content_rect.size.x * 0.78, content_rect.position.y + content_rect.size.y * 0.38),
		Vector2(content_rect.position.x + content_rect.size.x, content_rect.position.y + content_rect.size.y * 0.38)
	])
	draw_polyline(points, deep_glow, 10.0, true)
	draw_polyline(points, glow, 6.0, true)
	draw_polyline(points, accent.lightened(0.35), 3.2, true)
	draw_circle(points[0], 2.0, Color(accent.r, accent.g, accent.b, 0.55))
	draw_circle(points[points.size() - 1], 2.0, Color(accent.r, accent.g, accent.b, 0.55))

func _draw_empty_state(content_rect: Rect2) -> void:
	var line_color := Color(0.46, 0.56, 0.66, 0.24)
	var pulse_color := Color(0.74, 0.82, 0.90, 0.14)
	var mid_y := content_rect.position.y + content_rect.size.y * 0.55
	draw_line(
		Vector2(content_rect.position.x, mid_y),
		Vector2(content_rect.position.x + content_rect.size.x, mid_y),
		line_color,
		2.0,
		true
	)
	draw_arc(
		Vector2(content_rect.position.x + content_rect.size.x * 0.38, content_rect.position.y + content_rect.size.y * 0.55),
		5.0,
		0.0,
		TAU,
		18,
		pulse_color,
		1.5,
		true
	)
	draw_arc(
		Vector2(content_rect.position.x + content_rect.size.x * 0.62, content_rect.position.y + content_rect.size.y * 0.55),
		5.0,
		0.0,
		TAU,
		18,
		pulse_color,
		1.5,
		true
	)

func _draw_disabled_state(content_rect: Rect2) -> void:
	var line_color := Color(0.34, 0.39, 0.44, 0.16)
	var slash_color := Color(0.42, 0.47, 0.53, 0.18)
	var mid_y := content_rect.position.y + content_rect.size.y * 0.55
	draw_line(
		Vector2(content_rect.position.x, mid_y),
		Vector2(content_rect.position.x + content_rect.size.x, mid_y),
		line_color,
		1.5,
		true
	)
	draw_line(
		content_rect.position + Vector2(3.0, content_rect.size.y - 3.0),
		content_rect.position + Vector2(content_rect.size.x - 3.0, 3.0),
		slash_color,
		1.5,
		true
	)
