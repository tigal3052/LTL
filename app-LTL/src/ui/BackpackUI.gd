# 계약:
# - 책임: 백팩 8x8 그리드 내부 슬롯 렌더링, 아이템 배치 비주얼 피드백, 유물 드래그 고스트 포지셔닝을 제어한다. 슬롯 배경의 색감 조절 및 개별 아이템 셀의 외곽 검은색 테두리 연출을 적용한다.
# - 입력: 10x10 GridContainer, 백팩 슬롯 테스쳐 9종, inventory 데이터 스냅샷.
# - 출력: slot_clicked 시그널 발생, 드래그 고스트 표시 및 회전 기능 제공.
# - 금지: 핵심 제어 컨트롤러 및 도메인 시뮬레이터 참조.
# 실행: define the Backpack grid rendering and drag-ghost view with its signals.
extends PanelContainer
signal slot_clicked(coord: Vector2)
const ArtifactClass = preload("res://src/models/Artifact.gd")
@onready var backpack_grid_mock: GridContainer = $Margin/EngineBox/GridMock
var ghost_container: GridContainer
var held_artifact: ArtifactClass = null

# 실행: setup ghost container.
func _ready() -> void:
	_setup_ghost_container()

# 실행: construct the 10x10 grid slots with ivory self-modulate tint.
func setup_grid_slots() -> void:
	for child in backpack_grid_mock.get_children():
		child.queue_free()
	backpack_grid_mock.columns = 10
	backpack_grid_mock.add_theme_constant_override("h_separation", 2)
	backpack_grid_mock.add_theme_constant_override("v_separation", 2)
	var textures = {}
	for i in range(1, 10):
		textures[i] = load("res://resources/UI/backpack_%d.png" % i)
	for r in range(10):
		for c in range(10):
			var is_border = (r == 0 or r == 9 or c == 0 or c == 9)
			if is_border:
				var slice_num = 5
				if r == 0:
					if c == 0: slice_num = 1
					elif c == 9: slice_num = 3
					else: slice_num = 2
				elif r == 9:
					if c == 0: slice_num = 7
					elif c == 9: slice_num = 9
					else: slice_num = 8
				else:
					if c == 0: slice_num = 4
					elif c == 9: slice_num = 6
				var border_rect := TextureRect.new()
				border_rect.custom_minimum_size = Vector2(16, 16)
				border_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				border_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
				border_rect.texture = textures[slice_num]
				border_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				border_rect.stretch_mode = TextureRect.STRETCH_SCALE
				backpack_grid_mock.add_child(border_rect)
			else:
				var grid_r = r - 1
				var grid_c = c - 1
				var slot := Panel.new()
				slot.custom_minimum_size = Vector2(16, 16)
				slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
				
				# Tint slot background into a translucent warm ivory/beige color
				slot.self_modulate = Color(0.95, 0.90, 0.82, 0.65)
				
				var bg_style := StyleBoxTexture.new()
				bg_style.texture = textures[5]
				slot.add_theme_stylebox_override("panel", bg_style)
				
				# Create Panel for overlay to support border styles
				var overlay := Panel.new()
				overlay.name = "Overlay"
				overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
				overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
				overlay.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
				slot.add_child(overlay)
				
				slot.gui_input.connect(func(event: InputEvent):
					if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
						slot_clicked.emit(Vector2(grid_c, grid_r))
				)
				backpack_grid_mock.add_child(slot)

# 실행: initialize the drag-and-drop ghost container.
func _setup_ghost_container() -> void:
	ghost_container = GridContainer.new()
	ghost_container.top_level = true
	ghost_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ghost_container)
	ghost_container.visible = false

# 실행: process drag ghost position on frame tick.
func _process(_delta: float) -> void:
	if ghost_container and ghost_container.visible and held_artifact:
		var shape = held_artifact.shape
		var rows = shape.size()
		var cols = shape[0].size() if rows > 0 else 0
		var expected_size = Vector2(cols * 24 + (cols - 1) * 2, rows * 24 + (rows - 1) * 2)
		ghost_container.global_position = get_global_mouse_position() - expected_size / 2

# 실행: update the visual presentation of the drag-and-drop ghost overlay with black outlines.
func update_ghost_display(art: ArtifactClass) -> void:
	held_artifact = art
	for child in ghost_container.get_children():
		child.queue_free()
	if held_artifact == null:
		ghost_container.visible = false
		return
	var shape = held_artifact.shape
	var rows = shape.size()
	var cols = shape[0].size() if rows > 0 else 0
	ghost_container.columns = cols
	ghost_container.add_theme_constant_override("h_separation", 2)
	ghost_container.add_theme_constant_override("v_separation", 2)
	var color: Color = Color.WHITE
	match str(held_artifact.energy_type):
		"red": color = Color(0.85, 0.25, 0.25, 0.5)
		"blue": color = Color(0.25, 0.50, 0.85, 0.5)
		"purple": color = Color(0.65, 0.25, 0.85, 0.5)
		"green": color = Color(0.25, 0.75, 0.35, 0.5)
	for r in range(rows):
		for c in range(cols):
			if shape[r][c] == 1:
				var box = Panel.new()
				box.custom_minimum_size = Vector2(24, 24)
				
				# Style with black outline
				var style = StyleBoxFlat.new()
				style.bg_color = color
				style.border_width_left = 1
				style.border_width_top = 1
				style.border_width_right = 1
				style.border_width_bottom = 1
				style.border_color = Color.BLACK
				box.add_theme_stylebox_override("panel", style)
				
				box.mouse_filter = Control.MOUSE_FILTER_IGNORE
				ghost_container.add_child(box)
			else:
				var empty = Control.new()
				empty.custom_minimum_size = Vector2(24, 24)
				empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
				ghost_container.add_child(empty)
	ghost_container.visible = true

# 실행: render active items inside the 8x8 backpack grid using Panel overlays with black border lines.
func render_backpack_items(inventory) -> void:
	# Clear previous overlays
	for r in range(8):
		for c in range(8):
			var slot_idx = (r + 1) * 10 + (c + 1)
			if slot_idx < backpack_grid_mock.get_child_count():
				var slot = backpack_grid_mock.get_child(slot_idx) as Panel
				if slot:
					var overlay = slot.get_node("Overlay") as Panel
					if overlay:
						overlay.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	if inventory == null:
		return
	for art_id in inventory.artifacts:
		var art = inventory.artifacts[art_id]
		var color: Color = Color.WHITE
		match str(art.energy_type):
			"red": color = Color(0.85, 0.25, 0.25, 0.75)
			"blue": color = Color(0.25, 0.50, 0.85, 0.75)
			"purple": color = Color(0.65, 0.25, 0.85, 0.75)
			"green": color = Color(0.25, 0.75, 0.35, 0.75)
		var pos = Vector2(art.x, art.y)
		var rows = art.shape.size()
		var cols = art.shape[0].size() if rows > 0 else 0
		for r in range(rows):
			for c in range(cols):
				if art.shape[r][c] == 1:
					var cell_col = int(pos.x) + c
					var cell_row = int(pos.y) + r
					if cell_col >= 0 and cell_col < 8 and cell_row >= 0 and cell_row < 8:
						var slot_idx = (cell_row + 1) * 10 + (cell_col + 1)
						if slot_idx < backpack_grid_mock.get_child_count():
							var slot = backpack_grid_mock.get_child(slot_idx) as Panel
							if slot:
								var overlay = slot.get_node("Overlay") as Panel
								if overlay:
									# Style with solid fill and thin black border lines
									var style = StyleBoxFlat.new()
									style.bg_color = color
									style.border_width_left = 1
									style.border_width_top = 1
									style.border_width_right = 1
									style.border_width_bottom = 1
									style.border_color = Color.BLACK
									overlay.add_theme_stylebox_override("panel", style)
