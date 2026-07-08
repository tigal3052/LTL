extends Control

var ring_color := Color(0.88, 0.73, 0.45, 0.72)
var fill_color := Color(0.18, 0.12, 0.09, 0.82)
var shadow_color := Color(0.0, 0.0, 0.0, 0.24)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.38
	_draw_shadow(center, radius)
	draw_circle(center, radius, fill_color)
	var dash_count := 18
	for dash_index in range(dash_count):
		if dash_index % 2 != 0:
			continue
		var start_angle := (TAU * float(dash_index) / float(dash_count)) - 0.10
		var end_angle := (TAU * float(dash_index + 1) / float(dash_count)) - 0.22
		draw_arc(center, radius - 1.4, start_angle, end_angle, 7, ring_color, 2.2, true)

func _draw_shadow(center: Vector2, radius: float) -> void:
	for step in range(5):
		var blur := radius + (2.0 * float(step))
		var alpha := shadow_color.a * (1.0 - (float(step) / 5.0))
		draw_circle(center + Vector2(0.0, radius * 0.18), blur, Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha * 0.12))
