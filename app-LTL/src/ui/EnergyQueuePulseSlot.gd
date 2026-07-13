class_name EnergyQueuePulseSlot
extends Control

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")

var energy_color := ""
var slot_enabled := true
var slot_loaded := false
var front_slot := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(26.0, 18.0)
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

# 목업 .pulse-slot 준거: 흰 슬롯 + 1px 보더 + 파형만 — 내부 이중 패널/장식 없이 심플하게 유지한다.
func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_style_box(_outer_style(), rect)
	if not slot_enabled:
		_draw_disabled_stripes(rect.grow(-1.0))
		return
	if slot_loaded and not energy_color.is_empty():
		_draw_loaded_wave(rect.grow(-4.0), LTLThemeScript.accent_color(energy_color))

func _outer_style() -> StyleBoxFlat:
	var bg := LTLThemeScript.SURFACE_CONTAINER_LOWEST
	var border := Color(0.659, 0.69, 0.627, 1.0)
	var shadow_alpha := 0.0
	if not slot_enabled:
		bg = Color(0.933, 0.902, 0.855, 0.55)
		border = Color(0.659, 0.69, 0.627, 0.55)
	elif front_slot:
		border = LTLThemeScript.WARNING_GOLD
		shadow_alpha = 0.30
	var style := LTLThemeScript.surface_style(bg, border, 6, 1, 0.0)
	if shadow_alpha > 0.0:
		style.shadow_color = Color(LTLThemeScript.WARNING_GOLD.r, LTLThemeScript.WARNING_GOLD.g, LTLThemeScript.WARNING_GOLD.b, shadow_alpha)
		style.shadow_size = 4
	return style

# 전투 리디자인: 라이트 배경에서 가독되는 딥 파형 색 (mockup waveColor 준거)
static func _wave_color(color_name: String) -> Color:
	match color_name:
		"red":
			return Color("#c0392b")
		"blue":
			return Color("#2f6fb2")
		"green":
			return Color("#3b692a")
		"purple":
			return Color("#7b4a9e")
	return Color(0.30, 0.33, 0.29, 1.0)

# 전투 리디자인: mockup SVG 파형(60×24 viewBox, stroke 2.4) 등가 — 슬롯 크기에 비례한
# 얇은 스트로크 + 미세 글로우로 소형 슬롯에서도 파형이 뭉개지지 않는다.
func _draw_loaded_wave(content_rect: Rect2, accent: Color) -> void:
	accent = _wave_color(energy_color) if not energy_color.is_empty() else accent
	var stroke := clampf(content_rect.size.y * 0.18, 1.2, 2.4)
	var glow := Color(accent.r, accent.g, accent.b, 0.20)
	var points := PackedVector2Array([
		Vector2(content_rect.position.x, content_rect.position.y + content_rect.size.y * 0.50),
		Vector2(content_rect.position.x + content_rect.size.x * 0.17, content_rect.position.y + content_rect.size.y * 0.50),
		Vector2(content_rect.position.x + content_rect.size.x * 0.25, content_rect.position.y + content_rect.size.y * 0.17),
		Vector2(content_rect.position.x + content_rect.size.x * 0.37, content_rect.position.y + content_rect.size.y * 0.83),
		Vector2(content_rect.position.x + content_rect.size.x * 0.47, content_rect.position.y + content_rect.size.y * 0.25),
		Vector2(content_rect.position.x + content_rect.size.x * 0.57, content_rect.position.y + content_rect.size.y * 0.75),
		Vector2(content_rect.position.x + content_rect.size.x * 0.65, content_rect.position.y + content_rect.size.y * 0.50),
		Vector2(content_rect.position.x + content_rect.size.x, content_rect.position.y + content_rect.size.y * 0.50)
	])
	draw_polyline(points, glow, stroke * 2.2, true)
	draw_polyline(points, accent, stroke, true)

# 목업 .pulse-slot.off 준거: 45° 반복 빗금 텍스처 + 저채도(전체 55% 톤)로 비활성 칸을 표기한다.
func _draw_disabled_stripes(content_rect: Rect2) -> void:
	var stripe_color := Color(0.886, 0.847, 0.784, 0.55)
	var band := 4.0
	var travel := content_rect.size.x + content_rect.size.y
	var offset := band
	while offset < travel:
		var start := Vector2(content_rect.position.x + maxf(0.0, offset - content_rect.size.y), content_rect.position.y + minf(offset, content_rect.size.y))
		var end := Vector2(content_rect.position.x + minf(offset, content_rect.size.x), content_rect.position.y + maxf(0.0, offset - content_rect.size.x))
		draw_line(start, end, stripe_color, 1.6, true)
		offset += band * 2.0
