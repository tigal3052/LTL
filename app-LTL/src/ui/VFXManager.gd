# 계약:
# - 책임: 타격 파티클 스폰, 레이저 빔 그리기(Line2D), 스크린 쉐이크 2D 카메라 오프셋 효과를 관리한다.
# - 입력: particle template 노드, start/end Vector2 포지션, 쉐이크 시간/강도.
# - 출력: CPUParticles2D 생성 및 에미터 제어, Line2D 페이드아웃 트윈, parent 노드 오프셋 이동.
# - 금지: 핵심 제어 컨트롤러 및 도메인 시뮬레이터 참조.
# 실행: define the VFXManager as a Node2D.
extends Node2D
@export var particle_template: CPUParticles2D
var shake_timer: float = 0.0
var shake_intensity: float = 0.0
var shake_enabled: bool = true
var flash_enabled: bool = true
var particles_enabled: bool = true
var target_control: Control = null
var battle_pause_active: bool = false

# 실행: update screenshake offset of the target control on frame tick.
func _process(delta: float) -> void:
	if target_control == null:
		return
	if battle_pause_active:
		target_control.position = Vector2.ZERO
		return
	if shake_timer > 0.0 and shake_enabled:
		shake_timer -= delta
		target_control.position = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		target_control.position = Vector2.ZERO

# 실행: start a screenshake on the target control.
func trigger_screenshake(duration: float, intensity: float, ctrl: Control) -> void:
	if not shake_enabled:
		return
	shake_timer = duration
	shake_intensity = intensity
	target_control = ctrl

func set_battle_pause_active(active: bool) -> void:
	battle_pause_active = active
	if battle_pause_active and target_control != null:
		target_control.position = Vector2.ZERO

# 실행: trigger Line2D magic resonance beam animation.
func draw_resonance_beam(start_pos: Vector2, end_pos: Vector2, color_name: String) -> void:
	var line := Line2D.new()
	line.width = 3.0 if not flash_enabled else 5.0
	var c_color := Color(0.95, 0.75, 0.25, 0.9)
	if color_name == "red":
		c_color = Color(0.9, 0.2, 0.2, 0.9)
	elif color_name == "blue":
		c_color = Color(0.2, 0.5, 0.9, 0.9)
	elif color_name == "green":
		c_color = Color(0.2, 0.8, 0.3, 0.9)
	elif color_name == "purple":
		c_color = Color(0.7, 0.2, 0.8, 0.9)
	line.default_color = c_color if flash_enabled else Color(c_color.r, c_color.g, c_color.b, c_color.a * 0.55)
	var steps = 8
	var dir = end_pos - start_pos
	var perp = Vector2(-dir.y, dir.x).normalized()
	line.add_point(start_pos - global_position)
	for i in range(1, steps):
		var t = float(i) / steps
		var pt = start_pos + dir * t
		var offset = perp * randf_range(-3.0, 3.0) if not flash_enabled else perp * randf_range(-6.0, 6.0)
		line.add_point(pt + offset - global_position)
	line.add_point(end_pos - global_position)
	add_child(line)
	var tween = create_tween()
	tween.tween_property(line, "self_modulate:a", 0.0, 0.12)
	tween.tween_callback(line.queue_free)

# 실행: spawn CPUParticles2D mineral hit burst.
func spawn_hit_particles(pos: Vector2, outcome: String, color_name: String) -> void:
	if particle_template == null or not particles_enabled:
		return
	var p = particle_template.duplicate() as CPUParticles2D
	add_child(p)
	p.global_position = pos
	match outcome:
		"match":
			var c_color := Color(0.9, 0.3, 0.3)
			if color_name == "blue": c_color = Color(0.3, 0.6, 0.9)
			elif color_name == "green": c_color = Color(0.3, 0.8, 0.4)
			elif color_name == "purple": c_color = Color(0.7, 0.3, 0.8)
			p.color = c_color
			p.amount = 10 if not flash_enabled else 20
			p.initial_velocity_min = 120.0
			p.initial_velocity_max = 220.0
		"mismatch":
			p.color = Color(0.65, 0.68, 0.72)
			p.amount = 8 if not flash_enabled else 12
			p.initial_velocity_min = 80.0
			p.initial_velocity_max = 140.0
		_:
			p.color = Color(0.4, 0.35, 0.3, 0.6)
			p.amount = 6 if not flash_enabled else 8
			p.initial_velocity_min = 40.0
			p.initial_velocity_max = 80.0
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)

func set_accessibility_state(state: Dictionary) -> void:
	shake_enabled = bool(state.get("screenshake", shake_enabled))
	flash_enabled = not bool(state.get("reducedFlash", false))
	particles_enabled = not bool(state.get("reducedParticles", false))

func spawn_damage_popups(events: Array) -> void:
	for index in range(events.size()):
		var event = events[index]
		if not event is Dictionary:
			continue
		_spawn_damage_popup(event, index)

static func popup_palette_for_color(color_name: String) -> Dictionary:
	match color_name:
		"blue":
			return {
				"fill": Color(0.86, 0.93, 1.0, 1.0),
				"shadow": Color(0.08, 0.18, 0.32, 0.96),
				"glow": Color(0.33, 0.58, 0.94, 0.18),
				"fontSize": 20
			}
		"green":
			return {
				"fill": Color(0.90, 1.0, 0.90, 1.0),
				"shadow": Color(0.10, 0.26, 0.12, 0.96),
				"glow": Color(0.34, 0.76, 0.40, 0.18),
				"fontSize": 20
			}
		"purple":
			return {
				"fill": Color(0.93, 0.86, 1.0, 1.0),
				"shadow": Color(0.22, 0.10, 0.30, 0.96),
				"glow": Color(0.72, 0.42, 0.95, 0.20),
				"fontSize": 20
			}
	return {
		"fill": Color(1.0, 0.88, 0.88, 1.0),
		"shadow": Color(0.34, 0.10, 0.10, 0.96),
		"glow": Color(0.86, 0.32, 0.32, 0.18),
		"fontSize": 20
	}

func _spawn_damage_popup(event: Dictionary, index: int) -> void:
	var origin: Vector2 = event.get("origin", Vector2.ZERO)
	if not origin is Vector2:
		return
	var amount := float(event.get("amount", 0.0))
	if amount <= 0.0:
		return
	var channel := str(event.get("channel", "health"))
	var prefix := str(event.get("prefix", "HP"))
	var palette: Dictionary = popup_palette_for_color(str(event.get("color", "")))
	var root := Control.new()
	root.top_level = true
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.z_index = 200 + index
	root.scale = Vector2.ONE * 0.96
	root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	add_child(root)
	var text := "%s -%.1f" % [prefix, amount]
	var font_size := int(palette.get("fontSize", 20)) + (1 if channel == "health" else 0)
	var base_size: Vector2 = _damage_label_size(text, font_size)
	var center_offset := Vector2(base_size.x * 0.5, base_size.y * 0.55)
	root.position = origin - center_offset + Vector2(0.0, 6.0)
	for outline_offset in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		var outline := _make_damage_label(text, font_size, palette.get("shadow", Color(0.0, 0.0, 0.0, 0.9)))
		outline.position = outline_offset
		root.add_child(outline)
	var glow := _make_damage_label(text, font_size, palette.get("glow", Color(1.0, 1.0, 1.0, 0.18)))
	glow.position = Vector2.ZERO
	glow.scale = Vector2.ONE * 1.02
	root.add_child(glow)
	var main := _make_damage_label(text, font_size, palette.get("fill", Color.WHITE))
	main.position = Vector2.ZERO
	root.add_child(main)
	var rise_distance := 22.0 if channel == "shield" else 26.0
	var delay := 0.0 if channel == "shield" else 0.05
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.parallel().tween_property(root, "modulate:a", 1.0, 0.06)
	tween.parallel().tween_property(root, "scale", Vector2.ONE * 1.02, 0.08)
	tween.parallel().tween_property(root, "position:y", root.position.y - 10.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.10)
	tween.parallel().tween_property(root, "position:y", root.position.y - rise_distance, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(root, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(root, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(root.queue_free)

func _make_damage_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.position = -_damage_label_size(text, font_size) * 0.5
	return label

func _damage_label_size(text: String, font_size: int) -> Vector2:
	var probe := Label.new()
	probe.text = text
	probe.add_theme_font_size_override("font_size", font_size)
	return probe.get_combined_minimum_size()
