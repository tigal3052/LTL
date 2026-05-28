# 계약:
# - 책임: backpack grid slot 입력, artifact overlay 렌더링, drag ghost 위치/표시를 관리한다.
# - 입력: InventoryModel과 held Artifact.
# - 출력: slot click/hover signal과 grid/ghost visual 갱신.
# - 금지: inventory 변경, reward 상태 변경, controller 직접 접근.
#
# 실행: define the Backpack grid rendering and drag-ghost view with its signals.
extends PanelContainer

signal slot_clicked(coord: Vector2)
signal slot_hovered(coord: Vector2)
signal slot_unhovered(coord: Vector2)

const ArtifactClass = preload("res://src/models/Artifact.gd")
const GridFactory = preload("res://src/ui/presenters/BackpackGridFactory.gd")

@onready var backpack_grid_mock: GridContainer = $Margin/EngineBox/GridMock
var ghost_container: GridContainer
var held_artifact: ArtifactClass = null

# 실행: setup ghost container.
func _ready() -> void:
	_setup_ghost_container()

# 실행: construct the 10x10 grid slots with border textures and inner input cells.
func setup_grid_slots() -> void:
	for child in backpack_grid_mock.get_children():
		child.queue_free()
	backpack_grid_mock.columns = 10
	backpack_grid_mock.add_theme_constant_override("h_separation", 2)
	backpack_grid_mock.add_theme_constant_override("v_separation", 2)
	var textures := _load_textures()
	for row in range(10):
		for column in range(10):
			if row == 0 or row == 9 or column == 0 or column == 9:
				backpack_grid_mock.add_child(GridFactory.border_cell(textures[GridFactory.border_slice(row, column)]))
			else:
				backpack_grid_mock.add_child(_interactive_slot(column - 1, row - 1, textures[5]))

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
		ghost_container.global_position = get_global_mouse_position() - Vector2(cols * 24 + (cols - 1) * 2, rows * 24 + (rows - 1) * 2) / 2

# 실행: update the visual presentation of the drag-and-drop ghost overlay.
func update_ghost_display(art: ArtifactClass) -> void:
	held_artifact = art
	for child in ghost_container.get_children():
		child.queue_free()
	if held_artifact == null:
		ghost_container.visible = false
		return
	var shape = held_artifact.shape
	ghost_container.columns = shape[0].size() if shape.size() > 0 else 1
	ghost_container.add_theme_constant_override("h_separation", 2)
	ghost_container.add_theme_constant_override("v_separation", 2)
	for row in range(shape.size()):
		for column in range(shape[row].size()):
			ghost_container.add_child(_ghost_cell(str(held_artifact.energy_type), int(shape[row][column]) == 1, shape, row, column))
	ghost_container.visible = true

# 실행: render active items inside the 8x8 backpack grid using panel overlays.
func render_backpack_items(inventory) -> void:
	_clear_overlays()
	if inventory == null:
		return
	for art_id in inventory.artifacts:
		var art = inventory.artifacts[art_id]
		for row in range(art.shape.size()):
			for column in range(art.shape[row].size()):
				if int(art.shape[row][column]) == 1:
					_apply_artifact_overlay(int(art.x) + column, int(art.y) + row, art, art.shape, row, column)

# 실행: load backpack border textures.
func _load_textures() -> Dictionary:
	var textures := {}
	for i in range(1, 10):
		textures[i] = load("res://resources/UI/backpack_%d.png" % i)
	return textures

# 실행: create an input slot and wire signals.
func _interactive_slot(grid_column: int, grid_row: int, texture: Texture2D) -> Panel:
	var slot: Panel = GridFactory.inner_slot(texture)
	slot.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			slot_clicked.emit(Vector2(grid_column, grid_row))
	)
	slot.mouse_entered.connect(func(): slot_hovered.emit(Vector2(grid_column, grid_row)))
	slot.mouse_exited.connect(func(): slot_unhovered.emit(Vector2(grid_column, grid_row)))
	return slot

# 실행: create one ghost grid cell.
func _ghost_cell(energy_type: String, filled: bool, shape: Array, row: int, column: int) -> Control:
	if not filled:
		var empty := Control.new()
		empty.custom_minimum_size = Vector2(24, 24)
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return empty
	var box := Panel.new()
	box.custom_minimum_size = Vector2(24, 24)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override("panel", GridFactory.artifact_style(energy_type, 0.5, GridFactory.artifact_edge_mask(shape, row, column)))
	return box

# 실행: clear all artifact overlays.
func _clear_overlays() -> void:
	for row in range(8):
		for column in range(8):
			var overlay := _slot_overlay(column, row)
			if overlay:
				overlay.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			var charge := _slot_charge_overlay(column, row)
			if charge:
				charge.visible = false
				charge.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

# 실행: apply artifact overlay to a backpack coordinate.
func _apply_artifact_overlay(column: int, row: int, art: ArtifactClass, shape: Array, shape_row: int, shape_column: int) -> void:
	var overlay := _slot_overlay(column, row)
	if overlay:
		overlay.add_theme_stylebox_override("panel", GridFactory.artifact_style(str(art.energy_type), 0.32, GridFactory.artifact_edge_mask(shape, shape_row, shape_column)))
	var charge := _slot_charge_overlay(column, row)
	if charge:
		var cooldown := maxi(1, int(art.effective_cooldown))
		var ratio := clampf(1.0 - (float(art.current_cooldown) / float(cooldown)), 0.0, 1.0)
		charge.visible = true
		charge.anchor_left = 0.0
		charge.anchor_right = 1.0
		charge.anchor_top = 1.0 - ratio
		charge.anchor_bottom = 1.0
		charge.offset_left = 0.0
		charge.offset_right = 0.0
		charge.offset_top = 0.0
		charge.offset_bottom = 0.0
		charge.add_theme_stylebox_override("panel", GridFactory.artifact_style(str(art.energy_type), 0.82, GridFactory.artifact_edge_mask(shape, shape_row, shape_column)))

# 실행: return overlay panel for an 8x8 backpack coordinate.
func _slot_overlay(column: int, row: int) -> Panel:
	if column < 0 or column >= 8 or row < 0 or row >= 8:
		return null
	var slot_idx := (row + 1) * 10 + (column + 1)
	if slot_idx >= backpack_grid_mock.get_child_count():
		return null
	var slot := backpack_grid_mock.get_child(slot_idx) as Panel
	return null if slot == null else slot.get_node("Overlay") as Panel

# 실행: return cooldown charge overlay panel for an 8x8 backpack coordinate.
func _slot_charge_overlay(column: int, row: int) -> Panel:
	if column < 0 or column >= 8 or row < 0 or row >= 8:
		return null
	var slot_idx := (row + 1) * 10 + (column + 1)
	if slot_idx >= backpack_grid_mock.get_child_count():
		return null
	var slot := backpack_grid_mock.get_child(slot_idx) as Panel
	return null if slot == null else slot.get_node("ChargeOverlay") as Panel
