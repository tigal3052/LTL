extends Control

var icon_kind := "normal"
var stroke_color := Color(0.96, 0.90, 0.82, 1.0)
var stroke_width := 2.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var center := size * 0.5
	var width := minf(size.x, size.y)
	var radius := width * 0.33
	match icon_kind:
		"start":
			_draw_start(center, radius)
		"repair":
			_draw_repair(center, radius)
		"unknown":
			_draw_unknown(center, radius)
		"danger":
			_draw_danger(center, radius)
		"harpoon":
			_draw_harpoon(center, radius)
		"reef":
			_draw_reef(center, radius)
		"boss":
			_draw_boss(center, radius)
		_:
			_draw_normal(center, radius)

func _draw_start(center: Vector2, radius: float) -> void:
	draw_line(center + Vector2(-radius * 0.55, -radius * 0.36), center + Vector2(-radius * 0.55, radius * 0.70), stroke_color, stroke_width, true)
	draw_line(center + Vector2(radius * 0.55, -radius * 0.36), center + Vector2(radius * 0.55, radius * 0.70), stroke_color, stroke_width, true)
	draw_line(center + Vector2(-radius * 0.88, radius * 0.70), center + Vector2(radius * 0.88, radius * 0.70), stroke_color, stroke_width, true)
	draw_line(center + Vector2(-radius * 0.82, -radius * 0.12), center + Vector2(radius * 0.82, -radius * 0.12), stroke_color, stroke_width, true)
	draw_line(center + Vector2(0.0, -radius * 0.12), center + Vector2(0.0, radius * 0.40), stroke_color, stroke_width, true)
	draw_line(center + Vector2(-radius * 0.20, radius * 0.10), center + Vector2(0.0, -radius * 0.12), stroke_color, stroke_width, true)
	draw_line(center + Vector2(radius * 0.20, radius * 0.10), center + Vector2(0.0, -radius * 0.12), stroke_color, stroke_width, true)

func _draw_normal(center: Vector2, radius: float) -> void:
	var diamond := PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius * 0.90, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius * 0.90, 0.0),
		center + Vector2(0.0, -radius)
	])
	draw_polyline(diamond, stroke_color, stroke_width, true)
	draw_circle(center, radius * 0.18, stroke_color)

func _draw_repair(center: Vector2, radius: float) -> void:
	draw_arc(center + Vector2(0.0, -radius * 0.54), radius * 0.26, 0.0, TAU, 16, stroke_color, stroke_width, true)
	draw_line(center + Vector2(0.0, -radius * 0.26), center + Vector2(0.0, radius * 0.80), stroke_color, stroke_width, true)
	var left_arc := _ellipse_points(center + Vector2(0.0, radius * 0.12), Vector2(radius * 0.74, radius * 0.64), PI * 0.08, PI * 0.92, 18)
	draw_polyline(left_arc, stroke_color, stroke_width, true)
	draw_line(center + Vector2(-radius * 0.54, radius * 0.54), center + Vector2(-radius * 0.78, radius * 0.84), stroke_color, stroke_width, true)
	draw_line(center + Vector2(radius * 0.54, radius * 0.54), center + Vector2(radius * 0.78, radius * 0.84), stroke_color, stroke_width, true)

func _draw_unknown(center: Vector2, radius: float) -> void:
	var outer := _ellipse_points(center + Vector2(-radius * 0.06, -radius * 0.04), Vector2(radius * 0.86, radius * 0.74), PI * 0.20, PI * 1.84, 22)
	draw_polyline(outer, stroke_color, stroke_width, true)
	var inner := _ellipse_points(center + Vector2(0.0, radius * 0.06), Vector2(radius * 0.42, radius * 0.34), PI * 0.24, PI * 1.72, 16)
	draw_polyline(inner, stroke_color, stroke_width, true)
	draw_circle(center + Vector2(0.0, radius * 0.48), radius * 0.08, stroke_color)

func _draw_danger(center: Vector2, radius: float) -> void:
	var skull := PackedVector2Array([
		center + Vector2(-radius * 0.66, -radius * 0.14),
		center + Vector2(-radius * 0.46, -radius * 0.74),
		center + Vector2(0.0, -radius * 0.94),
		center + Vector2(radius * 0.46, -radius * 0.74),
		center + Vector2(radius * 0.66, -radius * 0.14),
		center + Vector2(radius * 0.52, radius * 0.44),
		center + Vector2(radius * 0.24, radius * 0.78),
		center + Vector2(-radius * 0.24, radius * 0.78),
		center + Vector2(-radius * 0.52, radius * 0.44),
		center + Vector2(-radius * 0.66, -radius * 0.14)
	])
	draw_polyline(skull, stroke_color, stroke_width, true)
	draw_circle(center + Vector2(-radius * 0.28, -radius * 0.10), radius * 0.12, stroke_color)
	draw_circle(center + Vector2(radius * 0.28, -radius * 0.10), radius * 0.12, stroke_color)
	draw_line(center + Vector2(-radius * 0.28, radius * 0.44), center + Vector2(radius * 0.28, radius * 0.44), stroke_color, stroke_width, true)

func _draw_harpoon(center: Vector2, radius: float) -> void:
	draw_line(center + Vector2(-radius * 0.82, radius * 0.80), center + Vector2(radius * 0.74, -radius * 0.78), stroke_color, stroke_width, true)
	draw_line(center + Vector2(radius * 0.22, -radius * 0.78), center + Vector2(radius * 0.74, -radius * 0.78), stroke_color, stroke_width, true)
	draw_line(center + Vector2(radius * 0.74, -radius * 0.78), center + Vector2(radius * 0.74, -radius * 0.24), stroke_color, stroke_width, true)
	draw_line(center + Vector2(-radius * 0.34, radius * 0.34), center + Vector2(-radius * 0.08, radius * 0.88), stroke_color, stroke_width, true)
	draw_line(center + Vector2(-radius * 0.58, radius * 0.58), center + Vector2(-radius * 0.06, radius * 0.84), stroke_color, stroke_width, true)

func _draw_reef(center: Vector2, radius: float) -> void:
	draw_line(center + Vector2(-radius * 0.42, radius * 0.86), center + Vector2(-radius * 0.24, -radius * 0.34), stroke_color, stroke_width, true)
	draw_line(center + Vector2(0.0, radius * 0.88), center + Vector2(0.0, -radius * 0.76), stroke_color, stroke_width, true)
	draw_line(center + Vector2(radius * 0.42, radius * 0.84), center + Vector2(radius * 0.58, -radius * 0.52), stroke_color, stroke_width, true)
	draw_line(center + Vector2(-radius * 0.24, -radius * 0.34), center + Vector2(-radius * 0.48, -radius * 0.76), stroke_color, stroke_width, true)
	draw_line(center + Vector2(0.0, -radius * 0.44), center + Vector2(radius * 0.22, -radius * 0.92), stroke_color, stroke_width, true)

func _draw_boss(center: Vector2, radius: float) -> void:
	var top_arc := _ellipse_points(center, Vector2(radius, radius * 0.60), PI, TAU, 22)
	var bottom_arc := _ellipse_points(center, Vector2(radius, radius * 0.60), 0.0, PI, 22)
	draw_polyline(top_arc, stroke_color, stroke_width, true)
	draw_polyline(bottom_arc, stroke_color, stroke_width, true)
	draw_circle(center, radius * 0.24, stroke_color)
	draw_line(center + Vector2(0.0, -radius * 0.64), center + Vector2(0.0, radius * 0.64), stroke_color, stroke_width * 0.8, true)

func _ellipse_points(center: Vector2, radii: Vector2, start_angle: float, end_angle: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for step in range(segments + 1):
		var t := float(step) / float(maxi(1, segments))
		var angle := lerpf(start_angle, end_angle, t)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points
