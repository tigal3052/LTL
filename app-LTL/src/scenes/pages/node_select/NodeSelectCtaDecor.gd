# 계약:
# - Responsibility: theme the node-select action buttons with atlas frame art and hover fireflies.
# - Input: a Button (Start/Reset CTA) and a primary/secondary flag.
# - Output: cropped atlas frame textures, weighted fonts, and a firefly hover overlay on primary CTA.
# - Prohibited: mutating gameplay state, wiring hover events more than once per button.
#
# 실행: theme node-select action buttons and drive their firefly hover overlay.
class_name NodeSelectCtaDecor
extends RefCounted

const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const LeviathanSelectChromeBitsScript = preload("res://src/scenes/pages/leviathan_select/LeviathanSelectChromeBits.gd")

const START_TEXTURE_PATH := "res://resources/node_select/atlas/btn_stone_leaf_primary.png"
const RESET_TEXTURE_PATH := "res://resources/node_select/atlas/btn_parchment_secondary.png"
const START_MIN_SIZE := Vector2(271.0, 65.0)   # 1072:257 @ h=65 — 테스트 하한 200x60 충족
const RESET_MIN_SIZE := Vector2(178.0, 58.0)   # 476:155 @ h=58
const BASE_TINT := Color(1.0, 1.0, 1.0, 1.0)
const FIREFLY_FADE_DURATION := 0.4

static var _cached_firefly_texture: Texture2D = null

# 실행: apply the shared atlas-image CTA theme to a Start/Reset action button.
static func apply_action_button_theme(button: Button, primary: bool) -> void:
	var empty_style := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, empty_style)
	button.custom_minimum_size = START_MIN_SIZE if primary else RESET_MIN_SIZE
	button.clip_contents = false
	button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if button.disabled else Control.CURSOR_POINTING_HAND

	if primary:
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_font_override("font", LeviathanSelectChromeBitsScript._copy_weighted_font(LTLThemeScript, 900))
		button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 1))
		# 비활성(노드 미선택)이어도 글자는 활성과 동일하게 선명한 흰색을 유지한다.
		button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 1))
		button.add_theme_color_override("font_focus_color", Color(1, 1, 1, 1))
		button.add_theme_constant_override("outline_size", 4)
		button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	else:
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_font_override("font", LeviathanSelectChromeBitsScript._copy_weighted_font(LTLThemeScript, 700))
		button.add_theme_color_override("font_color", Color(0.145, 0.251, 0.165, 1.0))
		button.add_theme_color_override("font_hover_color", Color(0.10, 0.20, 0.12, 1.0))
		button.add_theme_color_override("font_pressed_color", Color(0.10, 0.20, 0.12, 1.0))
		button.add_theme_color_override("font_disabled_color", Color(0.145, 0.251, 0.165, 1.0))
		button.add_theme_color_override("font_focus_color", Color(0.145, 0.251, 0.165, 1.0))
		button.add_theme_constant_override("outline_size", 0)

	var path := START_TEXTURE_PATH if primary else RESET_TEXTURE_PATH
	_ensure_cta_frame(button, path)
	if primary:
		_ensure_fireflies(button)

static func _ensure_cta_frame(button: Button, path: String) -> void:
	var frame := button.get_node_or_null("CtaFrameBg") as TextureRect
	if frame == null:
		frame = TextureRect.new()
		frame.name = "CtaFrameBg"
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		frame.show_behind_parent = true
		button.add_child(frame)
		button.move_child(frame, 0)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.texture = LTLThemeScript.art_texture(path)
	# CTA 프레임 이미지는 노드 선택/비활성 상태와 무관하게 항상 선명·불투명하게 고정한다.
	frame.modulate = BASE_TINT
	if button.disabled:
		var fireflies := button.get_node_or_null("CtaFireflies") as Control
		if fireflies != null:
			fireflies.modulate.a = 0.0
			button.set_meta("cta_fireflies_active", false)

static func _ensure_fireflies(button: Button) -> void:
	var fireflies := button.get_node_or_null("CtaFireflies") as Control
	if fireflies == null:
		fireflies = Control.new()
		fireflies.name = "CtaFireflies"
		fireflies.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fireflies.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		fireflies.clip_contents = true
		fireflies.modulate = Color(1, 1, 1, 0)
		button.add_child(fireflies)
		var rng := RandomNumberGenerator.new()
		rng.seed = 20260707
		for i in range(7):
			fireflies.add_child(_make_firefly(rng))

	if button.has_meta("cta_hover_wired"):
		return
	button.set_meta("cta_hover_wired", true)
	button.mouse_entered.connect(func() -> void:
		if button.disabled:
			return
		var fade := button.create_tween()
		fade.tween_property(fireflies, "modulate:a", 1.0, FIREFLY_FADE_DURATION)
		button.set_meta("cta_fireflies_active", true)
	)
	button.mouse_exited.connect(func() -> void:
		var fade := button.create_tween()
		fade.tween_property(fireflies, "modulate:a", 0.0, FIREFLY_FADE_DURATION)
		button.set_meta("cta_fireflies_active", false)
	)

static func _make_firefly(rng: RandomNumberGenerator) -> TextureRect:
	var mote := TextureRect.new()
	mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mote.texture = _firefly_texture()
	mote.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mote.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	var s := rng.randf_range(6.0, 12.0)
	mote.custom_minimum_size = Vector2(s, s)
	mote.size = Vector2(s, s)
	mote.position = Vector2(rng.randf_range(0.08, 0.92), rng.randf_range(0.2, 0.8))
	mote.set_meta("_norm_pos", mote.position)
	mote.modulate = Color(1.0, 0.96, 0.62, rng.randf_range(0.5, 0.95))
	mote.set_meta("_rng_phase", rng.randf_range(0.0, TAU))
	mote.set_meta("_rng_speed", rng.randf_range(0.5, 1.2))
	mote.set_meta("_rng_amp", rng.randf_range(6.0, 16.0))
	return mote

static func _firefly_texture() -> Texture2D:
	if _cached_firefly_texture != null:
		return _cached_firefly_texture
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) * 0.5
	for y in range(size):
		for x in range(size):
			var d := Vector2(x, y).distance_to(center) / (size * 0.5)
			var a: float = clampf(1.0 - d, 0.0, 1.0)
			a = pow(a, 2.2)
			img.set_pixel(x, y, Color(1.0, 0.95, 0.65, a))
	_cached_firefly_texture = ImageTexture.create_from_image(img)
	return _cached_firefly_texture

# 실행: drive the firefly drift animation for the primary CTA while hover is active.
static func process_fireflies(button: Button) -> void:
	if not button.get_meta("cta_fireflies_active", false):
		return
	var fireflies := button.get_node_or_null("CtaFireflies") as Control
	if fireflies == null:
		return
	var rect := fireflies.size
	var t := Time.get_ticks_msec() / 1000.0
	for mote in fireflies.get_children():
		var tr := mote as TextureRect
		if tr == null:
			continue
		var norm: Vector2 = tr.get_meta("_norm_pos", Vector2(0.5, 0.5))
		var phase: float = tr.get_meta("_rng_phase", 0.0)
		var speed: float = tr.get_meta("_rng_speed", 1.0)
		var amp: float = tr.get_meta("_rng_amp", 10.0)
		var base := Vector2(norm.x * rect.x, norm.y * rect.y)
		var drift := Vector2(
			sin(t * speed + phase) * amp,
			cos(t * speed * 0.7 + phase) * amp * 0.6
		)
		tr.position = base + drift - tr.size * 0.5
		tr.modulate.a = 0.5 + 0.45 * (0.5 + 0.5 * sin(t * speed * 1.6 + phase))
