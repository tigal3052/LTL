# 계약:
# - 책임: battlefield combat time border와 reward reveal VFX drawing/animation을 담당한다.
# - 입력: time state, reward reveal payload, completion callback.
# - 출력: draw calls와 reveal_finished signal/callback.
# - 금지: battlefield cell 입력 처리, combat state 변경, reward state 변경.
#
# 실행: define battlefield visual effects overlay.
class_name BattlefieldVFX
extends Control

var is_revealing := false
var rewards_count := 0
var rewards: Array = []
var stage := 0
var timer := 0.0
var particles: Array = []
var silhouettes: Array = []
var callback: Callable
var time_left := 0.0
var time_limit := 0.0
var in_combat := false
var pulse_time := 0.0

# 실행: update combat border time state.
func update_combat_time(left: float, limit: float, active: bool) -> void:
	time_left = left
	time_limit = limit
	in_combat = active
	queue_redraw()

# 실행: start reveal timeline and hide the provided battlefield nodes.
func start_reveal(count: int, reward_list: Array, done: Callable, grid: Control, title: Control) -> void:
	is_revealing = true
	rewards_count = count
	rewards = reward_list
	stage = 0
	timer = 0.0
	particles.clear()
	silhouettes.clear()
	callback = done
	grid.visible = false
	title.visible = false
	_timeline(grid, title)

# 실행: advance reveal particles and combat border pulse.
func _process(delta: float) -> void:
	if is_revealing:
		timer += delta
		_update_particles(delta)
		for silhouette in silhouettes:
			silhouette.pos = silhouette.pos.lerp(silhouette.target_pos, delta * 3.5)
		queue_redraw()
	elif in_combat:
		pulse_time += delta
		queue_redraw()

# 실행: draw combat border or reward reveal VFX.
func _draw() -> void:
	if not is_revealing:
		_draw_combat_border()
		return
	var center := size / 2.0
	draw_circle(center, 69.0, Color(0.12, 0.14, 0.16))
	draw_circle(center, 65.0, Color(0.06, 0.07, 0.09))
	for i in range(12):
		var angle = i * TAU / 12.0
		var start = center + Vector2(cos(angle), sin(angle)) * 8.0
		var end = center + Vector2(cos(angle), sin(angle)) * (65.0 + randf_range(8.0, 24.0))
		draw_line(start, end, Color(0.18, 0.20, 0.24), 2.5)
		draw_line(start, end, Color(0.95, 0.70, 0.20, _glow_alpha()), 1.0 + 3.0 * (stage + 1) * _glow_alpha())
	draw_circle(center, 32.0 + (20.0 * randf() if stage == 1 else 12.0 * abs(sin(timer * 4.0))), Color(0.95, 0.65, 0.15, 0.35))
	for particle in particles:
		draw_circle(particle.pos, particle.size, particle.color)
	for silhouette in silhouettes:
		_draw_silhouette(silhouette)

# 실행: manage reveal timeline timers.
func _timeline(grid: Control, title: Control) -> void:
	get_tree().create_timer(1.25).timeout.connect(func():
		stage = 1
		get_tree().create_timer(1.45).timeout.connect(func():
			stage = 2
			_spawn_shards(size / 2.0, 72 if rewards_count >= 4 else 36)
			get_tree().create_timer(1.15).timeout.connect(func():
				stage = 3
				_spawn_silhouettes(size / 2.0)
				get_tree().create_timer(1.2).timeout.connect(func():
					stage = 4
					get_tree().create_timer(2.0).timeout.connect(func():
						is_revealing = false
						grid.visible = true
						title.visible = true
						queue_redraw()
						callback.call()
					)
				)
			)
		)
	)

# 실행: update active particles and optional fountain.
func _update_particles(delta: float) -> void:
	position = Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5)) if stage == 0 else (Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)) if stage == 1 else Vector2.ZERO)
	var next_particles := []
	for particle in particles:
		particle.pos += particle.vel * delta
		particle.vel.y += 350.0 * delta
		particle.life -= delta
		if particle.life > 0.0:
			next_particles.append(particle)
	particles = next_particles
	if stage == 2 and rewards_count >= 4:
		_spawn_fountain(size / 2.0)
		_spawn_light_burst(size / 2.0)

# 실행: draw the remaining combat timer border.
func _draw_combat_border() -> void:
	if not in_combat or time_limit <= 0.0:
		return
	var ratio := time_left / time_limit
	var inset := 2.0
	var w := size.x - 2.0 * inset
	var h := size.y - 2.0 * inset
	var remaining := ratio * (2.0 * w + 2.0 * h)
	var color := Color(0.25, 0.65, 0.95, 0.8)
	var width := 3.0
	if time_left <= 200.0:
		var pulse = 0.35 + 0.65 * abs(sin(pulse_time * 6.5))
		color = Color(0.9, 0.1, 0.1, 0.4 + 0.6 * pulse)
		width = 3.5 + pulse
	var points = [Vector2(inset, inset), Vector2(inset + w, inset), Vector2(inset + w, inset + h), Vector2(inset, inset + h)]
	var lengths = [w, h, w, h]
	var dirs = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
	for i in range(4):
		if remaining <= 0.0:
			return
		var distance = min(remaining, lengths[i])
		draw_line(points[i], points[i] + dirs[i] * distance, color, width)
		remaining -= distance

# 실행: spawn initial eruption shards.
func _spawn_shards(center: Vector2, count: int) -> void:
	for i in range(count):
		var angle = randf_range(0.0, TAU)
		particles.append({"pos": center, "vel": Vector2(cos(angle), sin(angle)) * randf_range(120.0, 320.0), "color": Color(0.95, 0.45, 0.15) if rewards_count >= 4 else Color(0.45, 0.45, 0.48), "size": randf_range(4.0, 8.0), "life": randf_range(0.6, 1.2)})

# 실행: spawn active fountain particles.
func _spawn_fountain(center: Vector2) -> void:
	for i in range(6):
		var angle = randf_range(-PI / 3.0 - 0.2, -2.0 * PI / 3.0 + 0.2)
		particles.append({"pos": center + Vector2(randf_range(-18.0, 18.0), 0.0), "vel": Vector2(cos(angle), sin(angle)) * randf_range(180.0, 430.0), "color": Color(randf_range(0.95, 1.0), randf_range(0.25, 0.85), randf_range(0.05, 0.35), randf_range(0.75, 1.0)), "size": randf_range(3.0, 9.0), "life": randf_range(0.7, 1.45)})

# 실행: spawn extra bright radial particles for the volcano peak.
func _spawn_light_burst(center: Vector2) -> void:
	if particles.size() > 180:
		return
	for i in range(5):
		var angle = randf_range(0.0, TAU)
		particles.append({"pos": center, "vel": Vector2(cos(angle), sin(angle)) * randf_range(90.0, 260.0), "color": Color(1.0, randf_range(0.75, 0.95), randf_range(0.25, 0.55), randf_range(0.45, 0.85)), "size": randf_range(5.0, 12.0), "life": randf_range(0.35, 0.75)})

# 실행: skip the expectation animation and jump to reward-count silhouettes.
func skip_to_silhouettes() -> void:
	if not is_revealing:
		return
	if silhouettes.is_empty():
		_spawn_silhouettes(size / 2.0)
	stage = maxi(stage, 3)
	timer = 0.0
	queue_redraw()

# 실행: spawn reward silhouette targets.
func _spawn_silhouettes(center: Vector2) -> void:
	var spacing = size.x / (rewards_count + 1)
	for i in range(rewards_count):
		var reward = rewards[i]
		silhouettes.append({"pos": center + Vector2(randf_range(-20, 20), 10), "target_pos": Vector2(spacing * (i + 1), size.y / 2 - 10.0), "size": 16.0, "label": str(reward.get("kind", "Reward")), "rarity": str(reward.get("rarity", "common"))})

# 실행: draw one reward silhouette.
func _draw_silhouette(silhouette: Dictionary) -> void:
	if stage < 3:
		return
	var color := _rarity_color(str(silhouette.rarity)) if stage == 4 else Color.WHITE
	var pulse := 1.0 + 0.15 * sin(timer * 9.0 + silhouette.pos.x)
	draw_circle(silhouette.pos, silhouette.size * pulse + 3.5, Color(color.r, color.g, color.b, 0.35))
	draw_circle(silhouette.pos, silhouette.size, Color.WHITE if stage == 3 else color)
	draw_circle(silhouette.pos, silhouette.size * 0.5, Color.BLACK)
	if stage == 4:
		var font := get_theme_font("font")
		draw_string(font, silhouette.pos + Vector2(-60.0, -22.0), silhouette.label, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 11, Color.WHITE)
		draw_string(font, silhouette.pos + Vector2(-60.0, 24.0), str(silhouette.rarity).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 120.0, 9, color)

# 실행: return current crater glow alpha.
func _glow_alpha() -> float:
	return 0.5 + 0.5 * abs(sin(timer * 18.0)) if stage == 1 else 0.2 + 0.65 * abs(sin(timer * 7.0))

# 실행: map reward rarity to reveal color.
func _rarity_color(rarity: String) -> Color:
	match rarity:
		"epic": return Color(0.65, 0.25, 0.85)
		"legendary": return Color(0.95, 0.75, 0.25)
		"mythic": return Color(0.95, 0.45, 0.15)
		"rare": return Color(0.25, 0.50, 0.85)
	return Color(0.7, 0.7, 0.7)
