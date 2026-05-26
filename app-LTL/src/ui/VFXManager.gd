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
var target_control: Control = null

# 실행: update screenshake offset of the target control on frame tick.
func _process(delta: float) -> void:
	if target_control == null:
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

# 실행: trigger Line2D magic resonance beam animation.
func draw_resonance_beam(start_pos: Vector2, end_pos: Vector2, color_name: String) -> void:
	var line := Line2D.new()
	line.width = 5.0
	var c_color := Color(0.95, 0.75, 0.25, 0.9)
	if color_name == "red":
		c_color = Color(0.9, 0.2, 0.2, 0.9)
	elif color_name == "blue":
		c_color = Color(0.2, 0.5, 0.9, 0.9)
	elif color_name == "green":
		c_color = Color(0.2, 0.8, 0.3, 0.9)
	elif color_name == "purple":
		c_color = Color(0.7, 0.2, 0.8, 0.9)
	line.default_color = c_color
	var steps = 8
	var dir = end_pos - start_pos
	var perp = Vector2(-dir.y, dir.x).normalized()
	line.add_point(start_pos - global_position)
	for i in range(1, steps):
		var t = float(i) / steps
		var pt = start_pos + dir * t
		var offset = perp * randf_range(-6.0, 6.0)
		line.add_point(pt + offset - global_position)
	line.add_point(end_pos - global_position)
	add_child(line)
	var tween = create_tween()
	tween.tween_property(line, "self_modulate:a", 0.0, 0.12)
	tween.tween_callback(line.queue_free)

# 실행: spawn CPUParticles2D mineral hit burst.
func spawn_hit_particles(pos: Vector2, outcome: String, color_name: String) -> void:
	if particle_template == null:
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
			p.amount = 20
			p.initial_velocity_min = 120.0
			p.initial_velocity_max = 220.0
		"mismatch":
			p.color = Color(0.65, 0.68, 0.72)
			p.amount = 12
			p.initial_velocity_min = 80.0
			p.initial_velocity_max = 140.0
		_:
			p.color = Color(0.4, 0.35, 0.3, 0.6)
			p.amount = 8
			p.initial_velocity_min = 40.0
			p.initial_velocity_max = 80.0
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)
