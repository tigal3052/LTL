# 계약:
# - Responsibility: render a "cleared" stamp overlay on completed node markers.
# - Input: a host Control (marker hotspot) to attach the stamp to.
# - Output: an attached ClearStamp child that draws an image stamp or a code-drawn fallback.
# - Prohibited: mutating page state, layering above hover/selection visuals unexpectedly.
#
# 실행: attach a rotated clear-stamp overlay to a completed node hotspot.
class_name NodeSelectClearStamp
extends Control

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const SelfScript = preload("res://src/scenes/pages/node_select/NodeSelectClearStamp.gd")
const STAMP_TEXTURE_PATH := "res://resources/node_select/atlas/stamp_cleared.png"
const STAMP_INK := Color(0.70, 0.25, 0.18, 0.90)
const STAMP_ROTATION_DEG := -15.0

var _stamp_texture: Texture2D = null

static func attach(host: Control) -> void:
	if host.get_node_or_null("ClearStamp") != null:
		return
	var stamp: Control = SelfScript.new()
	stamp.name = "ClearStamp"
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamp.size = host.size * 1.05
	stamp.position = (host.size - stamp.size) * 0.5
	stamp.pivot_offset = stamp.size * 0.5
	stamp.rotation = deg_to_rad(STAMP_ROTATION_DEG)
	stamp.z_index = 5
	host.add_child(stamp)

func _ready() -> void:
	_stamp_texture = LTLThemeScript.art_texture(STAMP_TEXTURE_PATH)
	queue_redraw()

func _draw() -> void:
	if _stamp_texture != null:
		draw_texture_rect(_stamp_texture, Rect2(Vector2.ZERO, size), false)
		return
	var center := size * 0.5
	var outer_radius := minf(size.x, size.y) * 0.42
	draw_arc(center, outer_radius, 0.0, TAU, 48, STAMP_INK, 3.0, true)
	draw_arc(center, outer_radius - 6.0, 0.0, TAU, 48, STAMP_INK, 1.5, true)
	var font := get_theme_default_font()
	draw_string(font, Vector2(0.0, center.y + 5.0), "CLEAR",
		HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, STAMP_INK)
