# 계약:
# - 책임: battlefield grid cell 생성/갱신과 cell 입력 signal 중계를 담당한다.
# - 입력: terrain scene snapshot, disabled tile list, reward reveal payload.
# - 출력: cell_hovered/clicked/pressed/released signal과 battlefield visual 갱신.
# - 금지: combat state 변경, reward state 변경, controller 직접 접근.
#
# 실행: define the Battlefield panel controller and its signals.
extends PanelContainer

signal cell_hovered(cell_id: String, color_name: String)
signal cell_clicked(cell_id: String, color_name: String)
signal cell_pressed(cell_id: String, color_name: String)
signal cell_released()

const CellViewScript = preload("res://src/ui/CellView.gd")
const BattlefieldVFXScript = preload("res://src/ui/BattlefieldVFX.gd")

@onready var battlefield_grid: GridContainer = $Margin/BattlefieldBox/BattlefieldGrid
@onready var battlefield_title: Control = $Margin/BattlefieldBox/BattlefieldTitle
var vfx_overlay

# 실행: create the battlefield VFX overlay.
func _ready() -> void:
	vfx_overlay = BattlefieldVFXScript.new()
	vfx_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vfx_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vfx_overlay)

# 실행: update the remaining combat time variables for drawing the depleting border.
func update_combat_time(time_left: float, time_limit: float, in_combat: bool) -> void:
	if vfx_overlay != null:
		vfx_overlay.update_combat_time(time_left, time_limit, in_combat)

# 실행: render and wire up grid cells based on terrain data.
func render_battlefield(scene: Dictionary, disabled_tiles: Array) -> void:
	if vfx_overlay != null and bool(vfx_overlay.is_revealing):
		return
	var terrain: Dictionary = scene.get("terrain", {})
	var rows := int(terrain.get("rows", 0))
	var columns := int(terrain.get("columns", 10))
	battlefield_grid.columns = maxi(1, columns)
	if rows <= 0 or not visible:
		_clear_cells()
		return
	var cells: Array = terrain.get("cells", [])
	if battlefield_grid.get_child_count() != cells.size():
		_rebuild_cells(cells, disabled_tiles)
	else:
		_update_cells(cells, disabled_tiles)

# 실행: start the procedural crater/volcano reveal fanfare sequence.
func start_reveal_vfx(rewards_cnt: int, rewards_list: Array, callback: Callable) -> void:
	if vfx_overlay == null:
		callback.call()
		return
	custom_minimum_size = Vector2(720, 360)
	vfx_overlay.start_reveal(rewards_cnt, rewards_list, func():
		custom_minimum_size = Vector2.ZERO
		callback.call()
	, battlefield_grid, battlefield_title)

# 실행: let a repeated click skip the reveal into the silhouette-count stage.
func skip_reward_reveal_to_silhouettes() -> void:
	if vfx_overlay != null and vfx_overlay.has_method("skip_to_silhouettes"):
		vfx_overlay.skip_to_silhouettes()

# 실행: clear all battlefield cells.
func _clear_cells() -> void:
	for child in battlefield_grid.get_children():
		child.queue_free()

# 실행: rebuild all cells and connect input signals.
func _rebuild_cells(cells: Array, disabled_tiles: Array) -> void:
	_clear_cells()
	for cell in cells:
		var cell_view = CellViewScript.new()
		cell_view.configure(cell, disabled_tiles)
		cell_view.cell_hovered.connect(func(cid, col): cell_hovered.emit(cid, col))
		cell_view.cell_clicked.connect(func(cid, col): cell_clicked.emit(cid, col))
		cell_view.cell_pressed.connect(func(cid, col): cell_pressed.emit(cid, col))
		cell_view.cell_released.connect(func(): cell_released.emit())
		battlefield_grid.add_child(cell_view)

# 실행: update existing cell views in place.
func _update_cells(cells: Array, disabled_tiles: Array) -> void:
	for i in range(cells.size()):
		var cell_view = battlefield_grid.get_child(i)
		if cell_view.has_method("configure"):
			cell_view.configure(cells[i], disabled_tiles)
