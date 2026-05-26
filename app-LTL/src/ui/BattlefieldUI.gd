# 계약:
# - 책임: 레비아탄 갑각 지형 3x10 그리드 셀의 생성, 해제 및 셀 호버/클릭 입력을 중계하며, 보상 획득 시의 절차적 구덩이 대폭발/실루엣 팡파르 연출을 수행한다.
# - 입력: terrain cells 정보 Dictionary, disabled_tiles 목록, 보상 개수 및 데이터.
# - 출력: cell_hovered, cell_clicked, cell_pressed, cell_released 시그널 포워딩 및 연출 완료 콜백.
# - 금지: 핵심 제어 컨트롤러 및 도메인 시뮬레이터 참조.
# 실행: define the Battlefield panel controller and its signals.
extends PanelContainer
signal cell_hovered(cell_id: String, color_name: String)
signal cell_clicked(cell_id: String, color_name: String)
signal cell_pressed(cell_id: String, color_name: String)
signal cell_released()
const CellViewScript = preload("res://src/ui/CellView.gd")
@onready var battlefield_grid: GridContainer = $Margin/BattlefieldBox/BattlefieldGrid

# VFX variables
var is_revealing: bool = false
var reveal_rewards_count: int = 0
var reveal_rewards: Array = []
var reveal_stage: int = 0 # 0: cracks, 1: intensify, 2: shatter, 3: silhouettes, 4: morph
var reveal_timer: float = 0.0
var reveal_particles: Array = [] # { pos: Vector2, vel: Vector2, color: Color, size: float, life: float }
var reveal_silhouettes: Array = [] # { pos: Vector2, target_pos: Vector2, size: float, color: Color, label: String, rarity: String }
var reveal_callback: Callable

# Combat depleting border variables
var current_time_left: float = 0.0
var current_time_limit: float = 0.0
var is_combat_phase: bool = false
var combat_pulse_time: float = 0.0

# 실행: update the remaining combat time variables for drawing the depleting border.
func update_combat_time(time_left: float, time_limit: float, in_combat: bool) -> void:
	current_time_left = time_left
	current_time_limit = time_limit
	is_combat_phase = in_combat
	queue_redraw()

# 실행: render and wire up grid cells based on terrain data.
func render_battlefield(scene: Dictionary, disabled_tiles: Array) -> void:
	if is_revealing:
		return
	var terrain: Dictionary = scene.get("terrain", {})
	var rows := int(terrain.get("rows", 0))
	var columns := int(terrain.get("columns", 10))
	battlefield_grid.columns = maxi(1, columns)
	if rows <= 0 or not visible:
		for child in battlefield_grid.get_children():
			child.queue_free()
		return
	for child in battlefield_grid.get_children():
		if not (child is CellViewScript):
			child.queue_free()
	var cells: Array = terrain.get("cells", [])
	var existing_count = battlefield_grid.get_child_count()
	if existing_count != cells.size():
		for child in battlefield_grid.get_children():
			child.queue_free()
		for cell in cells:
			var cell_view = CellViewScript.new()
			cell_view.configure(cell, disabled_tiles)
			cell_view.cell_hovered.connect(func(cid, col): cell_hovered.emit(cid, col))
			cell_view.cell_clicked.connect(func(cid, col): cell_clicked.emit(cid, col))
			cell_view.cell_pressed.connect(func(cid, col): cell_pressed.emit(cid, col))
			cell_view.cell_released.connect(func(): cell_released.emit())
			battlefield_grid.add_child(cell_view)
	else:
		for i in range(cells.size()):
			var cell_view = battlefield_grid.get_child(i)
			if cell_view.has_method("configure"):
				cell_view.configure(cells[i], disabled_tiles)

# 실행: start the procedural crater/volcano reveal fanfare sequence.
func start_reveal_vfx(rewards_cnt: int, rewards_list: Array, callback: Callable) -> void:
	is_revealing = true
	reveal_rewards_count = rewards_cnt
	reveal_rewards = rewards_list
	reveal_stage = 0
	reveal_timer = 0.0
	reveal_particles.clear()
	reveal_silhouettes.clear()
	reveal_callback = callback
	
	# Hide Grid
	battlefield_grid.visible = false
	$Margin/BattlefieldBox/BattlefieldTitle.visible = false
	
	# Timeline sequence via timers
	# Stage 0: Cracks rumble (1.0s)
	get_tree().create_timer(1.0).timeout.connect(func():
		reveal_stage = 1 # Intensify rumble
		
		# Stage 1: Intensify (1.0s)
		get_tree().create_timer(1.0).timeout.connect(func():
			reveal_stage = 2 # Shattered lid / Volcanic blast
			
			# Eruption initial shockwave particles
			var center = Vector2(size.x / 2, size.y / 2)
			var shard_count = 40 if reveal_rewards_count >= 4 else 20
			for j in range(shard_count):
				var angle = randf_range(0.0, 2.0 * PI)
				var speed = randf_range(120.0, 320.0)
				var col = Color(0.95, 0.45, 0.15) if reveal_rewards_count >= 4 else Color(0.45, 0.45, 0.48)
				reveal_particles.append({
					"pos": center,
					"vel": Vector2(cos(angle), sin(angle)) * speed,
					"color": col,
					"size": randf_range(4.0, 8.0),
					"life": randf_range(0.6, 1.2)
				})
			
			# Stage 2: Erupt/Shatter duration (0.8s)
			get_tree().create_timer(0.8).timeout.connect(func():
				reveal_stage = 3 # Silhouettes rise
				
				# Generate white light silhouette destinations
				var spacing = size.x / (reveal_rewards_count + 1)
				for i in range(reveal_rewards_count):
					var reward = reveal_rewards[i]
					var target_x = spacing * (i + 1)
					var target_y = size.y / 2 - 10.0
					reveal_silhouettes.append({
						"pos": center + Vector2(randf_range(-20, 20), 10),
						"target_pos": Vector2(target_x, target_y),
						"size": 16.0,
						"label": str(reward.get("kind", "Reward")),
						"rarity": str(reward.get("rarity", "common"))
					})
				
				# Stage 3: Silhouette float up (1.2s)
				get_tree().create_timer(1.2).timeout.connect(func():
					reveal_stage = 4 # Morphed / Rarity flashes
					
					# Stage 4: Morph duration (2.0s) -> Finish
					get_tree().create_timer(2.0).timeout.connect(func():
						is_revealing = false
						battlefield_grid.visible = true
						$Margin/BattlefieldBox/BattlefieldTitle.visible = true
						custom_minimum_size = Vector2.ZERO
						queue_redraw()
						reveal_callback.call()
					)
				)
			)
		)
	)

# 실행: update reveal particles physics and positions.
func _process(delta: float) -> void:
	if is_revealing:
		reveal_timer += delta
		
		# Simulate screenshake on self during cracks
		if reveal_stage == 0:
			position = Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
		elif reveal_stage == 1:
			position = Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
		else:
			position = Vector2.ZERO
			
		# Update active particles
		var next_p := []
		for p in reveal_particles:
			p.pos += p.vel * delta
			p.vel.y += 350.0 * delta # Gravity pulling shard particles down
			p.life -= delta
			if p.life > 0.0:
				next_p.append(p)
		reveal_particles = next_p
		
		# Volcanic active fountain loop
		if reveal_stage == 2 and reveal_rewards_count >= 4:
			var center = Vector2(size.x / 2, size.y / 2)
			for j in range(3):
				var angle = randf_range(-PI/3.0 - 0.2, -2.0*PI/3.0 + 0.2)
				var speed = randf_range(160.0, 340.0)
				reveal_particles.append({
					"pos": center + Vector2(randf_range(-12.0, 12.0), 0.0),
					"vel": Vector2(cos(angle), sin(angle)) * speed,
					"color": Color(randf_range(0.9, 1.0), randf_range(0.2, 0.45), 0.1, randf_range(0.8, 1.0)),
					"size": randf_range(3.0, 7.0),
					"life": randf_range(0.5, 1.1)
				})
				
		# Move silhouettes smoothly
		for s in reveal_silhouettes:
			s.pos = s.pos.lerp(s.target_pos, delta * 3.5)
			
		queue_redraw()
		return
		
	if is_combat_phase:
		combat_pulse_time += delta
		queue_redraw()

# 실행: draw procedural cracks, fire particles, and hovering silhouettes.
func _draw() -> void:
	if not is_revealing:
		if is_combat_phase and current_time_limit > 0.0:
			var ratio = current_time_left / current_time_limit
			var inset = 2.0
			var w = size.x - 2.0 * inset
			var h = size.y - 2.0 * inset
			var P = 2.0 * w + 2.0 * h
			var L = ratio * P
			
			# Decide border color
			var border_color = Color(0.25, 0.65, 0.95, 0.8) # Blue-ish
			var border_width = 3.0
			
			if ratio <= 0.20:
				var pulse = 0.35 + 0.65 * abs(sin(combat_pulse_time * 6.5))
				border_color = Color(0.9, 0.1, 0.1, 0.4 + 0.6 * pulse)
				border_width = 3.5 + 1.0 * pulse
			
			var remaining = L
			var tl = Vector2(inset, inset)
			var tr = Vector2(inset + w, inset)
			var br = Vector2(inset + w, inset + h)
			var bl = Vector2(inset, inset + h)
			
			# Segment 1: Top edge (left to right)
			if remaining > 0.0:
				var d = min(remaining, w)
				draw_line(tl, tl + Vector2(d, 0.0), border_color, border_width)
				remaining -= d
				
			# Segment 2: Right edge (top to bottom)
			if remaining > 0.0:
				var d = min(remaining, h)
				draw_line(tr, tr + Vector2(0.0, d), border_color, border_width)
				remaining -= d
				
			# Segment 3: Bottom edge (right to left)
			if remaining > 0.0:
				var d = min(remaining, w)
				draw_line(br, br - Vector2(d, 0.0), border_color, border_width)
				remaining -= d
				
			# Segment 4: Left edge (bottom to top)
			if remaining > 0.0:
				var d = min(remaining, h)
				draw_line(bl, bl - Vector2(0.0, d), border_color, border_width)
		return
		
	var w = size.x
	var h = size.y
	var center = Vector2(w / 2, h / 2)
	
	# 1. Base dark crater pit
	var circle_center = center
	var radius = 65.0
	draw_circle(circle_center, radius + 4.0, Color(0.12, 0.14, 0.16))
	draw_circle(circle_center, radius, Color(0.06, 0.07, 0.09))
	
	# 2. Draw crack lines leaking heat light
	for i in range(12):
		var angle = i * (2.0 * PI / 12.0)
		var start = circle_center + Vector2(cos(angle), sin(angle)) * 8.0
		var end = circle_center + Vector2(cos(angle), sin(angle)) * (radius + randf_range(8.0, 24.0))
		draw_line(start, end, Color(0.18, 0.20, 0.24), 2.5)
		
		# Glowing thermal overlays
		var glow_alpha = 0.2 + 0.65 * abs(sin(reveal_timer * 7.0))
		if reveal_stage == 1:
			glow_alpha = 0.5 + 0.5 * abs(sin(reveal_timer * 18.0))
		var glow_color = Color(0.95, 0.70, 0.20, glow_alpha)
		draw_line(start, end, glow_color, 1.0 + 3.0 * (reveal_stage + 1) * glow_alpha)
		
	# Crater glow center
	var glow_radius = 20.0 + 12.0 * abs(sin(reveal_timer * 4.0))
	if reveal_stage == 1:
		glow_radius = 32.0 + 20.0 * randf()
	draw_circle(circle_center, glow_radius, Color(0.95, 0.65, 0.15, 0.35))
	
	# 3. Draw active particles
	for p in reveal_particles:
		draw_circle(p.pos, p.size, p.color)
		
	# 4. Draw reward silhouettes & morph titles
	for s in reveal_silhouettes:
		if reveal_stage >= 3:
			# Decide glow colors by rarity
			var glow_color = Color.WHITE
			if reveal_stage == 4:
				match str(s.rarity):
					"epic": glow_color = Color(0.65, 0.25, 0.85) # Purple
					"legendary": glow_color = Color(0.95, 0.75, 0.25) # Yellow/Gold
					"mythic": glow_color = Color(0.95, 0.45, 0.15) # Orange/Mythic
					"rare": glow_color = Color(0.25, 0.50, 0.85) # Blue
					_: glow_color = Color(0.7, 0.7, 0.7)
			
			# Draw background glowing aura
			var pulse_val = 1.0 + 0.15 * sin(reveal_timer * 9.0 + s.pos.x)
			draw_circle(s.pos, s.size * pulse_val + 3.5, Color(glow_color.r, glow_color.g, glow_color.b, 0.35))
			draw_circle(s.pos, s.size, Color.WHITE if reveal_stage == 3 else glow_color)
			
			# Draw inner core
			draw_circle(s.pos, s.size * 0.5, Color.BLACK)
			
			# Render labels at morph stage
			if reveal_stage == 4:
				var font := get_theme_font("font")
				# Item title
				draw_string(font, s.pos + Vector2(-60.0, -22.0), s.label, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 11, Color.WHITE)
				# Rarity badge
				var tier_text = s.rarity.to_upper()
				draw_string(font, s.pos + Vector2(-60.0, 24.0), tier_text, HORIZONTAL_ALIGNMENT_CENTER, 120.0, 9, glow_color)
