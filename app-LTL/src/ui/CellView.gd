# 계약:
# - 책임: 레비아탄 표면의 단단한 갑각, 암석 질감과 유물 균열을 시각화하고 개별 셀의 마우스 입력 이벤트를 처리한다.
# - 입력: 셀 메타데이터 Dictionary (id, row, column, weakness, aimed, disabled 등).
# - 출력: _draw()를 통한 2D 광물/갑각 지형 렌더링 및 hover/click 마우스 입력 상태 방출.
# - 금지: 도메인 시뮬레이터 직접 호출, 씬 트리 외부 상태 수정.
#
# 실행: define the CellView as a Button Control.
class_name CellView
extends Button

# 실행: define signals for mouse interactions.
signal cell_hovered(cell_id, weakness_color)
signal cell_clicked(cell_id, weakness_color)
signal cell_held(cell_id, weakness_color)
signal cell_pressed(cell_id, weakness_color)
signal cell_released()

# 실행: store cell parameters.
var cell_id: String = ""
var row: int = 0
var column: int = 0
var weakness: Variant = null
var terrain_debuff: Dictionary = {}
var aimed: bool = false
var is_disabled_tile: bool = false
var hover_active: bool = false

# 실행: store random rock shape offsets for organic C-type crust aesthetics.
var rock_points: Array[Vector2] = []
var crack_lines: Array[Array] = [] # Array of Array of Vector2

# 실행: generate random rocky carapace outline on creation.
func _ready() -> void:
	custom_minimum_size = Vector2(24, 20)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	mouse_filter = MouseFilter.MOUSE_FILTER_PASS
	focus_mode = FocusMode.FOCUS_NONE
	
	# flat style to disable default button drawings
	var empty_style = StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty_style)
	add_theme_stylebox_override("hover", empty_style)
	add_theme_stylebox_override("pressed", empty_style)
	add_theme_stylebox_override("focus", empty_style)
	add_theme_stylebox_override("disabled", empty_style)
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	# Generate C-type rocky terrain geometries
	_generate_rock_geometry()

# 실행: process mouse hover and click events.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var color_str := str(weakness) if weakness else "normal"
			if event.pressed:
				emit_signal("cell_clicked", cell_id, color_str)
				emit_signal("cell_pressed", cell_id, color_str)
			else:
				emit_signal("cell_released")

# 실행: generate randomized rocky carapace points and crack offsets.
func _generate_rock_geometry() -> void:
	# Carapace outline points (slightly inset polygon with noise, normalized between 0.0 and 1.0)
	rock_points = [
		Vector2(0.03 + randf_range(-0.015, 0.03), 0.04 + randf_range(-0.02, 0.04)),
		Vector2(0.5 + randf_range(-0.05, 0.05), 0.02 + randf_range(-0.02, 0.04)),
		Vector2(0.97 + randf_range(-0.03, 0.015), 0.04 + randf_range(-0.02, 0.04)),
		Vector2(0.98 + randf_range(-0.015, 0.015), 0.5 + randf_range(-0.06, 0.06)),
		Vector2(0.97 + randf_range(-0.03, 0.015), 0.96 + randf_range(-0.04, 0.02)),
		Vector2(0.5 + randf_range(-0.05, 0.05), 0.98 + randf_range(-0.02, 0.04)),
		Vector2(0.03 + randf_range(-0.015, 0.03), 0.96 + randf_range(-0.04, 0.02)),
		Vector2(0.02 + randf_range(-0.015, 0.015), 0.5 + randf_range(-0.06, 0.06))
	]
	
	# Interior cracks normalized (0.0 to 1.0)
	var num_cracks = randi_range(1, 3)
	for i in range(num_cracks):
		var crack: Array[Vector2] = []
		var start := Vector2(randf_range(0.1, 0.9), randf_range(0.1, 0.9))
		crack.append(start)
		var segments = randi_range(2, 4)
		var current = start
		for j in range(segments):
			var angle = randf_range(0, 2 * PI)
			var length = randf_range(0.15, 0.3)
			var next = current + Vector2(cos(angle), sin(angle)) * length
			next.x = clampf(next.x, 0.1, 0.9)
			next.y = clampf(next.y, 0.1, 0.9)
			crack.append(next)
			current = next
		crack_lines.append(crack)

# 실행: draw the C-type rock cell, crystals, crosshairs, and disabled overlays.
func _draw() -> void:
	var w = size.x
	var h = size.y
	
	# Base background color
	var bg_color = Color(0.18, 0.20, 0.24) # Dark gray base
	var border_color = Color(0.12, 0.14, 0.16)
	
	if is_disabled_tile:
		bg_color = Color(0.10, 0.11, 0.13) # Dimmed rock
		border_color = Color(0.08, 0.09, 0.10)
	
	# Scale rock points dynamically
	var scaled_rock_points = PackedVector2Array()
	for p in rock_points:
		scaled_rock_points.append(Vector2(p.x * w, p.y * h))
		
	# Draw the rocky polygon
	if scaled_rock_points.size() > 0:
		draw_polygon(scaled_rock_points, PackedColorArray([bg_color]))
		# Draw outer carapace border
		var outline_points = PackedVector2Array(scaled_rock_points)
		outline_points.append(scaled_rock_points[0]) # close loop
		draw_polyline(outline_points, border_color, 2.0)
	
	# Draw mineral crust cracks
	var crack_color = Color(0.28, 0.31, 0.36) if not is_disabled_tile else Color(0.15, 0.16, 0.18)
	for crack in crack_lines:
		var scaled_crack = PackedVector2Array()
		for p in crack:
			scaled_crack.append(Vector2(p.x * w, p.y * h))
		draw_polyline(scaled_crack, crack_color, 1.0)
		
	# Draw embedded artifact crystals (Weakness markers)
	if weakness:
		var crystal_color := Color(0.5, 0.5, 0.5)
		match str(weakness):
			"red":
				crystal_color = Color(0.85, 0.25, 0.25)
			"blue":
				crystal_color = Color(0.25, 0.50, 0.85)
			"green":
				crystal_color = Color(0.25, 0.75, 0.35)
			"purple":
				crystal_color = Color(0.65, 0.25, 0.85)
		
		if is_disabled_tile:
			crystal_color = crystal_color.darkened(0.5)
			
		# Draw crystal shape (Rhombus/Diamond in center)
		var center = Vector2(w/2, h/2)
		var size_factor = minf(w, h)
		var crystal_h = size_factor * 0.25
		var crystal_w = size_factor * 0.17
		
		var crystal_points = PackedVector2Array([
			center + Vector2(0, -crystal_h),
			center + Vector2(crystal_w, 0),
			center + Vector2(0, crystal_h),
			center + Vector2(-crystal_w, 0)
		])
		draw_polygon(crystal_points, PackedColorArray([crystal_color]))
		
		# Inner glow/core of the crystal
		var core_h = crystal_h * 0.4
		var core_w = crystal_w * 0.4
		var core_points = PackedVector2Array([
			center + Vector2(0, -core_h),
			center + Vector2(core_w, 0),
			center + Vector2(0, core_h),
			center + Vector2(-core_w, 0)
		])
		draw_polygon(core_points, PackedColorArray([Color.WHITE.darkened(0.1) if not is_disabled_tile else Color.GRAY]))
	
	# Draw hovering/focused visual ring
	if not terrain_debuff.is_empty():
		var c_debuff := Vector2(w / 2, h / 2)
		var debuff_color := Color(0.82, 0.45, 0.95, 0.82)
		var mark_size := minf(w, h) * 0.22
		draw_arc(c_debuff, mark_size, 0, TAU, 18, debuff_color, 1.25)
		draw_line(c_debuff + Vector2(-mark_size * 0.55, -mark_size * 0.2), c_debuff + Vector2(mark_size * 0.5, mark_size * 0.18), debuff_color, 1.35)
		draw_line(c_debuff + Vector2(-mark_size * 0.15, mark_size * 0.55), c_debuff + Vector2(mark_size * 0.22, -mark_size * 0.48), debuff_color, 1.15)

	# Draw hovering/focused visual ring
	if hover_active and not is_disabled_tile:
		var glow_color = Color(0.29, 0.53, 0.84, 0.7) # Cyan glow
		if weakness:
			match str(weakness):
				"red": glow_color = Color(0.9, 0.3, 0.3, 0.7)
				"blue": glow_color = Color(0.3, 0.6, 0.9, 0.7)
				"green": glow_color = Color(0.3, 0.8, 0.4, 0.7)
				"purple": glow_color = Color(0.7, 0.3, 0.8, 0.7)
		
		# Draw glowing thick border around rock points
		if scaled_rock_points.size() > 0:
			var glow_points = PackedVector2Array(scaled_rock_points)
			glow_points.append(scaled_rock_points[0])
			draw_polyline(glow_points, glow_color, 3.0)
		
	# Draw targeted (aimed) indicator - B-type Resonance Scope
	if aimed and not is_disabled_tile:
		var scope_color = Color(0.95, 0.75, 0.25, 0.9) # Gold targeted reticle
		var c = Vector2(w/2, h/2)
		var scope_size = minf(w, h) * 0.25
		# Crosshair lines
		draw_line(c + Vector2(-scope_size * 1.5, 0), c + Vector2(-scope_size * 0.8, 0), scope_color, 2.0)
		draw_line(c + Vector2(scope_size * 0.8, 0), c + Vector2(scope_size * 1.5, 0), scope_color, 2.0)
		draw_line(c + Vector2(0, -scope_size * 1.5), c + Vector2(0, -scope_size * 0.8), scope_color, 2.0)
		draw_line(c + Vector2(0, scope_size * 0.8), c + Vector2(0, scope_size * 1.5), scope_color, 2.0)
		# Resonance scope circles
		draw_arc(c, scope_size, 0, 2*PI, 16, scope_color, 1.5)
		draw_arc(c, scope_size * 1.4, 0, 2*PI, 16, scope_color.lightened(0.2), 0.75)

	# Disabled tile overlay (cooldown shadow)
	if is_disabled_tile:
		var cooldown_color = Color(0, 0, 0, 0.35)
		if scaled_rock_points.size() > 0:
			draw_polygon(scaled_rock_points, PackedColorArray([cooldown_color]))
		# Cooldown boundary hatchings
		draw_line(Vector2(5, 5), Vector2(15, 15), Color(0.4, 0.1, 0.1, 0.5), 1.5)
		draw_line(Vector2(w - 15, h - 15), Vector2(w - 5, h - 5), Color(0.4, 0.1, 0.1, 0.5), 1.5)

# 실행: update hovered flag and notify controller on mouse entry.
func _on_mouse_entered() -> void:
	hover_active = true
	emit_signal("cell_hovered", cell_id, str(weakness) if weakness else "normal")
	queue_redraw()

# 실행: clear hovered flag on mouse exit.
func _on_mouse_exited() -> void:
	hover_active = false
	queue_redraw()

# 실행: public configuration setter.
func configure(cell_data: Dictionary, disabled_tiles: Array) -> void:
	cell_id = cell_data.get("id", "")
	row = int(cell_data.get("row", 0))
	column = int(cell_data.get("column", 0))
	weakness = cell_data.get("weakness", null)
	terrain_debuff = cell_data.get("terrainDebuff", {})
	aimed = bool(cell_data.get("aimed", false))
	is_disabled_tile = cell_id in disabled_tiles
	queue_redraw()
