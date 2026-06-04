# 계약:
# - 책임: 이전 보상 reveal 연출의 원형/방사형 구현을 복원 가능한 legacy 백업으로 보존한다.
# - 입력: reward payload, overlay size, reveal completion callback.
# - 출력: 이전 연출과 동일한 draw/timeline helper와 callback 흐름.
# - 금지: 현재 기본 reveal 경로로 자동 복귀, combat timer border 책임 혼합.
#
# 실행: define the archived pre-cinematic reward reveal overlay.
class_name LegacyRewardRevealOverlay
extends Control

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const REVEAL_TIMING := {
	"rumble": 1.45,
	"eruption": 1.75,
	"flash": 0.55,
	"silhouetteHold": 1.25,
	"rarityRoll": 1.65,
	"finalReveal": 1.20
}
const RARITY_ROLL_VALUES := ["COMMON", "RARE", "EPIC", "LEGENDARY", "MYTHIC"]

var is_revealing := false
var rewards_count := 0
var rewards: Array = []
var stage := 0
var timer := 0.0
var particles: Array = []
var silhouettes: Array = []
var callback: Callable
var flash_alpha := 0.0

static func reveal_timing_profile() -> Dictionary:
	return REVEAL_TIMING.duplicate()

static func rolling_rarity_label(actual_rarity: String, elapsed: float) -> String:
	var safe_actual := actual_rarity.to_upper()
	if elapsed >= float(REVEAL_TIMING.get("rarityRoll", 1.65)):
		return safe_actual
	var step := int(floor(maxf(0.0, elapsed) / 0.10))
	return RARITY_ROLL_VALUES[step % RARITY_ROLL_VALUES.size()]

# 실행: start the archived reward reveal timeline.
func start_reveal(count: int, reward_list: Array, done: Callable) -> void:
	is_revealing = true
	rewards_count = count
	rewards = reward_list
	_set_stage(0)
	particles.clear()
	silhouettes.clear()
	callback = done
	_timeline()

func _process(delta: float) -> void:
	if not is_revealing:
		return
	timer += delta
	if flash_alpha > 0.0:
		flash_alpha = maxf(0.0, flash_alpha - delta * 1.85)
	_update_particles(delta)
	for silhouette in silhouettes:
		silhouette.pos = silhouette.pos.lerp(silhouette.target_pos, delta * 3.5)
	queue_redraw()

func _draw() -> void:
	if not is_revealing:
		return
	var center := size / 2.0
	draw_circle(center, 69.0, Color(0.12, 0.14, 0.16))
	draw_circle(center, 65.0, Color(0.06, 0.07, 0.09))
	for index in range(12):
		var angle := index * TAU / 12.0
		var start := center + Vector2(cos(angle), sin(angle)) * 8.0
		var endpoint := center + Vector2(cos(angle), sin(angle)) * (65.0 + randf_range(8.0, 24.0))
		draw_line(start, endpoint, Color(0.18, 0.20, 0.24), 2.5)
		draw_line(start, endpoint, Color(0.95, 0.70, 0.20, _glow_alpha()), 1.0 + 3.0 * (stage + 1) * _glow_alpha())
	draw_circle(center, 32.0 + (20.0 * randf() if stage == 1 else 12.0 * abs(sin(timer * 4.0))), Color(0.95, 0.65, 0.15, 0.35))
	for particle in particles:
		draw_circle(particle.pos, particle.size, particle.color)
	for silhouette in silhouettes:
		_draw_silhouette(silhouette)
	if flash_alpha > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 1.0, 1.0, flash_alpha))

# 실행: manage the archived multi-stage reveal timeline.
func _timeline() -> void:
	var profile := reveal_timing_profile()
	get_tree().create_timer(float(profile.get("rumble", 1.45))).timeout.connect(func():
		_set_stage(1)
		get_tree().create_timer(float(profile.get("eruption", 1.75))).timeout.connect(func():
			_set_stage(2)
			_spawn_shards(size / 2.0, 72 if rewards_count >= 4 else 36)
			get_tree().create_timer(float(profile.get("flash", 0.55))).timeout.connect(func():
				_set_stage(25)
				flash_alpha = 1.0
				_spawn_light_burst(size / 2.0)
				queue_redraw()
				get_tree().create_timer(0.42).timeout.connect(func():
					_set_stage(3)
					_spawn_silhouettes(size / 2.0)
					flash_alpha = maxf(flash_alpha, 0.55)
					queue_redraw()
					get_tree().create_timer(float(profile.get("silhouetteHold", 1.25))).timeout.connect(func():
						_set_stage(35)
						get_tree().create_timer(float(profile.get("rarityRoll", 1.65))).timeout.connect(func():
							_set_stage(4)
							get_tree().create_timer(float(profile.get("finalReveal", 1.20))).timeout.connect(func():
								is_revealing = false
								queue_redraw()
								if callback.is_valid():
									callback.call()
							)
						)
					)
				)
			)
		)
	)

# 실행: update the archived particle field and optional fountain.
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

# 실행: spawn initial eruption shards for the archived reveal.
func _spawn_shards(center: Vector2, count: int) -> void:
	for _index in range(count):
		var angle := randf_range(0.0, TAU)
		particles.append({"pos": center, "vel": Vector2(cos(angle), sin(angle)) * randf_range(120.0, 320.0), "color": Color(0.95, 0.45, 0.15) if rewards_count >= 4 else Color(0.45, 0.45, 0.48), "size": randf_range(4.0, 8.0), "life": randf_range(0.6, 1.2)})

func _spawn_fountain(center: Vector2) -> void:
	for _index in range(6):
		var angle := randf_range(-PI / 3.0 - 0.2, -2.0 * PI / 3.0 + 0.2)
		particles.append({"pos": center + Vector2(randf_range(-18.0, 18.0), 0.0), "vel": Vector2(cos(angle), sin(angle)) * randf_range(180.0, 430.0), "color": Color(randf_range(0.95, 1.0), randf_range(0.25, 0.85), randf_range(0.05, 0.35), randf_range(0.75, 1.0)), "size": randf_range(3.0, 9.0), "life": randf_range(0.7, 1.45)})

func _spawn_light_burst(center: Vector2) -> void:
	if particles.size() > 180:
		return
	for _index in range(5):
		var angle := randf_range(0.0, TAU)
		particles.append({"pos": center, "vel": Vector2(cos(angle), sin(angle)) * randf_range(90.0, 260.0), "color": Color(1.0, randf_range(0.75, 0.95), randf_range(0.25, 0.55), randf_range(0.45, 0.85)), "size": randf_range(5.0, 12.0), "life": randf_range(0.35, 0.75)})

# 실행: skip the expectation animation and jump to the silhouette-count phase.
func skip_to_silhouettes() -> void:
	if not is_revealing:
		return
	if silhouettes.is_empty():
		_spawn_silhouettes(size / 2.0)
	flash_alpha = 0.0
	_set_stage(maxi(stage, 3))
	queue_redraw()

func _spawn_silhouettes(center: Vector2) -> void:
	var spacing := size.x / (rewards_count + 1)
	for index in range(rewards_count):
		var reward = rewards[index]
		silhouettes.append({"index": index, "pos": center + Vector2(randf_range(-20.0, 20.0), 10.0), "target_pos": Vector2(spacing * (index + 1), size.y / 2 - 10.0), "size": 16.0, "label": TextCatalogScript.reward_name(reward), "rarity": str(reward.get("rarity", "common"))})

func _draw_silhouette(silhouette: Dictionary) -> void:
	if stage < 3:
		return
	var reveal_roll := stage == 35
	var final_reveal := stage == 4
	var color := _rarity_color(str(silhouette.rarity)) if final_reveal else Color.WHITE
	var pulse := 1.0 + 0.15 * sin(timer * 9.0 + silhouette.pos.x)
	draw_circle(silhouette.pos, silhouette.size * pulse + 3.5, Color(color.r, color.g, color.b, 0.35))
	draw_circle(silhouette.pos, silhouette.size, Color.WHITE if stage == 3 else color)
	draw_circle(silhouette.pos, silhouette.size * 0.5, Color.BLACK)
	if reveal_roll:
		var roll_label := rolling_rarity_label(str(silhouette.rarity), timer + float(silhouette.get("index", 0)) * 0.13)
		var roll_color := _rarity_color(str(roll_label).to_lower())
		var font := get_theme_font("font")
		draw_string(font, silhouette.pos + Vector2(-70.0, -22.0), "SIGNAL LOCK", HORIZONTAL_ALIGNMENT_CENTER, 140.0, 10, Color(0.86, 0.89, 0.94, 0.86))
		draw_string(font, silhouette.pos + Vector2(-70.0, 24.0), roll_label, HORIZONTAL_ALIGNMENT_CENTER, 140.0, 11, roll_color)
	elif final_reveal:
		var font := get_theme_font("font")
		draw_string(font, silhouette.pos + Vector2(-60.0, -22.0), silhouette.label, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 11, Color.WHITE)
		draw_string(font, silhouette.pos + Vector2(-60.0, 24.0), str(silhouette.rarity).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 120.0, 9, color)

func _set_stage(next_stage: int) -> void:
	stage = next_stage
	timer = 0.0

func _glow_alpha() -> float:
	return 0.5 + 0.5 * abs(sin(timer * 18.0)) if stage == 1 else 0.2 + 0.65 * abs(sin(timer * 7.0))

func _rarity_color(rarity: String) -> Color:
	match rarity:
		"epic":
			return Color(0.65, 0.25, 0.85)
		"legendary":
			return Color(0.95, 0.75, 0.25)
		"mythic":
			return Color(0.95, 0.45, 0.15)
		"rare":
			return Color(0.25, 0.50, 0.85)
	return Color(0.7, 0.7, 0.7)
