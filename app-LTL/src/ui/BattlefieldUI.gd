# 계약:
# - 책임: battlefield board를 실제 타일/패널 아트로 배치하고 cell 입력 signal을 중계한다.
# - 입력: terrain scene snapshot, disabled tile list.
# - 출력: 배경 셸, header miner, lane, grid cell 갱신과 cell interaction signal.
# - 금지: combat state 직접 변경, reward state 직접 변경, controller 우회 접근.
#
# 실행: define the Battlefield panel controller and its signals.
extends PanelContainer

signal cell_hovered(cell_id: String, color_name: String)
signal cell_clicked(cell_id: String, color_name: String)
signal cell_pressed(cell_id: String, color_name: String)
signal cell_released()

const CellViewScript = preload("res://src/ui/CellView.gd")
const BattlefieldVFXScript = preload("res://src/ui/BattlefieldVFX.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const MINER_45_TEXTURE_PATH := "res://resources/UI/miner/miner_45.png"
const MINER_60_TEXTURE_PATH := "res://resources/UI/miner/miner_60.png"
const MINER_90_TEXTURE_PATH := "res://resources/UI/miner/miner_90.png"
const MINER_45_TEXTURE := preload("res://resources/UI/miner/miner_45.png")
const MINER_60_TEXTURE := preload("res://resources/UI/miner/miner_60.png")
const MINER_90_TEXTURE := preload("res://resources/UI/miner/miner_90.png")
const MINER_45_VISIBLE_REGION := Rect2(43, 0, 981, 898)
const MINER_60_VISIBLE_REGION := Rect2(43, 0, 981, 960)
const MINER_90_VISIBLE_REGION := Rect2(186, 13, 593, 980)
const HEADER_MINER_WIDTH_RATIO := 0.1425
const MINER_DOCK_MIN_WIDTH := 96.0
const MINER_DOCK_GAP_X := 10.0
const GRID_PADDING_TOP := 7.0
const GRID_PADDING_BOTTOM := 5.0
const LANE_OVERHANG_X := 6.0
const LANE_PAD_Y := 3.0
const LANE_GAP_Y := 4.0
const TITLE_MINER_COMPRESS_SCALE := 0.94
const TITLE_MINER_OVERSHOOT_SCALE := 1.04

@onready var battlefield_visual_root: Control = $Margin/BattlefieldBox/BattlefieldVisualRoot
@onready var battlefield_title: Control = $Margin/BattlefieldBox/BattlefieldTitle
@onready var title_miner: TextureRect = $Margin/BattlefieldBox/BattlefieldVisualRoot/TitleMiner
@onready var panel_shell: TextureRect = $Margin/BattlefieldBox/BattlefieldVisualRoot/PanelShell
@onready var lane_top: ColorRect = $Margin/BattlefieldBox/BattlefieldVisualRoot/LaneTop
@onready var lane_middle: ColorRect = $Margin/BattlefieldBox/BattlefieldVisualRoot/LaneMiddle
@onready var lane_bottom: ColorRect = $Margin/BattlefieldBox/BattlefieldVisualRoot/LaneBottom
@onready var battlefield_grid: GridContainer = $Margin/BattlefieldBox/BattlefieldVisualRoot/BattlefieldGrid

var vfx_overlay
var title_miner_pose_tween: Tween
var miner_pose_textures: Dictionary = {}
var battle_pause_active := false

# 실행: configure the art-backed shell layers and mount the VFX overlay.
# 전투 리디자인: 배경 이미지/패널 셸 텍스처는 폐지 — 이끼 석재 패널 스타일 + 레인 틴트만 유지 (mockup .battlefield).
func _ready() -> void:
	_configure_visual_layers()
	battlefield_visual_root.resized.connect(_layout_battlefield_visuals)
	battlefield_title.resized.connect(_layout_battlefield_visuals)
	call_deferred("_layout_battlefield_visuals")

	vfx_overlay = BattlefieldVFXScript.new()
	vfx_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vfx_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(vfx_overlay)

func set_battle_pause_active(active: bool) -> void:
	battle_pause_active = active
	if vfx_overlay != null and vfx_overlay.has_method("set_battle_pause_active"):
		vfx_overlay.set_battle_pause_active(active)
	for child in battlefield_grid.get_children():
		if child != null and child.has_method("set_battle_pause_active"):
			child.set_battle_pause_active(active)

# 실행: attach textures, lane colors, and grid spacing for the battlefield art shell.
func _configure_visual_layers() -> void:
	if battlefield_title is Label:
		var title_label := battlefield_title as Label
		title_label.text = ""
		title_label.add_theme_font_size_override("font_size", 1)
	battlefield_title.custom_minimum_size = Vector2.ZERO

	title_miner.texture = _texture_for_miner_pose_path(MINER_45_TEXTURE_PATH)
	title_miner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_miner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	title_miner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_miner.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	title_miner.self_modulate = Color.WHITE
	title_miner.z_index = 3

	# 목업 정합: 구 tile_panel 프레임 텍스처 셸은 표시하지 않는다 (노드는 계약상 유지).
	panel_shell.texture = null
	panel_shell.visible = false
	panel_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_shell.z_index = 0

	var lanes: Array[ColorRect] = [lane_top, lane_middle, lane_bottom]
	for lane in lanes:
		lane.color = lane_overlay_color()
		lane.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lane.z_index = 1

	battlefield_grid.columns = 10
	battlefield_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	battlefield_grid.add_theme_constant_override("h_separation", 3)
	battlefield_grid.add_theme_constant_override("v_separation", 5)
	battlefield_grid.z_index = 2

# 실행: expose the board layout policy for regression tests and runtime reuse.
# 목업 준거(.miner-dock 14.25%/min 96px 좌측 도크 + .lane-stack): 마이너가 왼쪽 도크를 점유하고
# 지형 타일 그리드는 도크 오른쪽에서 시작한다 — 캐릭터와 타일이 겹치지 않는다.
func layout_metrics_for_board(board_size: Vector2) -> Dictionary:
	var dock_width := maxf(MINER_DOCK_MIN_WIDTH, board_size.x * HEADER_MINER_WIDTH_RATIO)
	var reference_texture: Texture2D = title_miner.texture if title_miner != null and title_miner.texture != null else _texture_for_miner_pose_path(MINER_45_TEXTURE_PATH)
	var texture_size := _texture_display_size(reference_texture)
	var texture_ratio := texture_size.y / maxf(1.0, texture_size.x)
	var header_miner_width := dock_width
	var header_miner_height := header_miner_width * texture_ratio
	var max_miner_height := maxf(0.0, board_size.y * 0.98)
	if header_miner_height > max_miner_height and texture_ratio > 0.0:
		header_miner_height = max_miner_height
		header_miner_width = header_miner_height / texture_ratio
	# 도크 안 중앙 정렬 + 바닥 정렬 (mockup align-items: flex-end)
	var header_miner_rect := Rect2(
		Vector2(
			maxf(0.0, (dock_width - header_miner_width) * 0.5),
			maxf(0.0, board_size.y - header_miner_height)
		),
		Vector2(header_miner_width, header_miner_height)
	)
	var grid_left := dock_width + MINER_DOCK_GAP_X + LANE_OVERHANG_X
	# 레인 스택: 상단 7 / 하단 5 패딩, 레인 3줄(셀 + 상하 3px 패딩) + 레인 간 4px (mockup .lane-stack/.lane)
	var lane_stack_height := maxf(0.0, board_size.y - GRID_PADDING_TOP - GRID_PADDING_BOTTOM)
	var lane_height := maxf(0.0, (lane_stack_height - LANE_GAP_Y * 2.0) / 3.0)
	var cell_row_height := maxf(0.0, lane_height - LANE_PAD_Y * 2.0)
	var grid_v_separation := int(LANE_GAP_Y + LANE_PAD_Y * 2.0)
	var grid_h_separation := 3
	var grid_rect := Rect2(
		Vector2(grid_left, GRID_PADDING_TOP + LANE_PAD_Y),
		Vector2(
			maxf(0.0, board_size.x - grid_left - LANE_OVERHANG_X),
			cell_row_height * 3.0 + float(grid_v_separation) * 2.0
		)
	)
	# 셸 rect는 장식 텍스처 폐지 후에도 계약 호환을 위해 레인 스택 외곽으로 유지한다.
	var shell_rect := Rect2(
		Vector2(grid_rect.position.x - LANE_OVERHANG_X, GRID_PADDING_TOP),
		Vector2(grid_rect.size.x + LANE_OVERHANG_X * 2.0, lane_stack_height)
	)
	var lane_rects: Array = []
	for index in range(3):
		lane_rects.append(Rect2(
			Vector2(grid_rect.position.x - LANE_OVERHANG_X, GRID_PADDING_TOP + float(index) * (lane_height + LANE_GAP_Y)),
			Vector2(grid_rect.size.x + LANE_OVERHANG_X * 2.0, lane_height)
		))
	return {
		"headerMinerRect": header_miner_rect,
		"shellRect": shell_rect,
		"gridRect": grid_rect,
		"laneRects": lane_rects,
		"headerMinerWidth": header_miner_width,
		"minerDockWidth": dock_width,
		"gridHSeparation": grid_h_separation,
		"gridVSeparation": grid_v_separation
	}

# 실행: map the updated miner/title and stretched shell ratios onto the live board size.
func _layout_battlefield_visuals() -> void:
	var board_size := battlefield_visual_root.size
	if board_size.x <= 0.0 or board_size.y <= 0.0:
		return

	var metrics := layout_metrics_for_board(board_size)
	var header_miner_rect: Rect2 = metrics.get("headerMinerRect", Rect2())
	var shell_rect: Rect2 = metrics.get("shellRect", Rect2())
	var grid_rect: Rect2 = metrics.get("gridRect", Rect2())
	var lane_rects: Array = metrics.get("laneRects", [])
	var grid_h_separation := int(metrics.get("gridHSeparation", 3))
	var grid_v_separation := int(metrics.get("gridVSeparation", 5))

	panel_shell.position = shell_rect.position
	panel_shell.size = shell_rect.size

	var lanes: Array[ColorRect] = [lane_top, lane_middle, lane_bottom]
	for index in range(mini(lanes.size(), lane_rects.size())):
		var lane: ColorRect = lanes[index]
		var lane_rect: Rect2 = lane_rects[index]
		lane.position = lane_rect.position
		lane.size = lane_rect.size

	battlefield_grid.add_theme_constant_override("h_separation", grid_h_separation)
	battlefield_grid.add_theme_constant_override("v_separation", grid_v_separation)
	battlefield_grid.position = grid_rect.position
	battlefield_grid.size = grid_rect.size

	battlefield_title.custom_minimum_size = Vector2.ZERO
	title_miner.position = header_miner_rect.position
	title_miner.size = header_miner_rect.size
	title_miner.pivot_offset = title_miner.size * 0.5

# 실행: map a zero-based battlefield column index to the matching miner pose asset path.
func miner_pose_asset_path_for_column(column_index: int) -> String:
	if column_index >= 0 and column_index <= 1:
		return MINER_90_TEXTURE_PATH
	if column_index >= 2 and column_index <= 5:
		return MINER_60_TEXTURE_PATH
	return MINER_45_TEXTURE_PATH

# 실행: map a battlefield cell id like r0c7 to the matching miner pose asset path.
func miner_pose_asset_path_for_cell_id(cell_id: String) -> String:
	return miner_pose_asset_path_for_column(_column_index_from_cell_id(cell_id))

# 실행: expose the lane overlay tint so regression tests can keep transparent tile edges readable.
func lane_overlay_color() -> Color:
	return Color(0.07, 0.10, 0.14, 0.18)

# 실행: animate the shared title miner toward the pose associated with the attacked cell.
func play_miner_pose_for_cell(cell_id: String) -> void:
	if title_miner == null:
		return
	var column_index := _column_index_from_cell_id(cell_id)
	var target_texture := _texture_for_miner_pose_path(miner_pose_asset_path_for_column(column_index))
	if target_texture == null:
		return
	if title_miner_pose_tween != null:
		title_miner_pose_tween.kill()
	title_miner.scale = Vector2.ONE
	title_miner.self_modulate = Color.WHITE
	title_miner.pivot_offset = title_miner.size * 0.5
	var accent := _accent_color_for_column(column_index)
	title_miner_pose_tween = create_tween()
	title_miner_pose_tween.set_trans(Tween.TRANS_SINE)
	title_miner_pose_tween.set_ease(Tween.EASE_OUT)
	title_miner_pose_tween.parallel().tween_property(title_miner, "scale", Vector2.ONE * TITLE_MINER_COMPRESS_SCALE, 0.05)
	title_miner_pose_tween.parallel().tween_property(title_miner, "self_modulate", Color(1.0, 1.0, 1.0, 0.78), 0.05)
	title_miner_pose_tween.tween_callback(func():
		title_miner.texture = target_texture
		_layout_battlefield_visuals()
		title_miner.pivot_offset = title_miner.size * 0.5
		title_miner.self_modulate = accent
	)
	title_miner_pose_tween.parallel().tween_property(title_miner, "scale", Vector2.ONE * TITLE_MINER_OVERSHOOT_SCALE, 0.08)
	title_miner_pose_tween.parallel().tween_property(title_miner, "self_modulate", accent, 0.08)
	title_miner_pose_tween.tween_interval(0.02)
	title_miner_pose_tween.parallel().tween_property(title_miner, "scale", Vector2.ONE, 0.16)
	title_miner_pose_tween.parallel().tween_property(title_miner, "self_modulate", Color.WHITE, 0.16)

# 실행: forward combat timer state to the battlefield VFX overlay.
func update_combat_time(time_left: float, time_limit: float, in_combat: bool) -> void:
	if vfx_overlay != null:
		vfx_overlay.update_combat_time(time_left, time_limit, in_combat)

func trigger_obstacle_flash(family: String) -> void:
	if vfx_overlay != null and vfx_overlay.has_method("trigger_obstacle_flash"):
		vfx_overlay.trigger_obstacle_flash(family)

func reward_lid_source_global_rect() -> Rect2:
	if battlefield_grid != null and battlefield_grid.get_child_count() > 0:
		var child_count := battlefield_grid.get_child_count()
		var columns := maxi(1, int(battlefield_grid.columns))
		var rows := maxi(1, int(ceil(float(child_count) / float(columns))))
		var source_row := clampi(int(floor(float(rows) * 0.5)), 0, rows - 1)
		var source_column := clampi(int(floor(float(columns) * 0.5)), 0, columns - 1)
		var source_index := clampi(source_row * columns + source_column, 0, child_count - 1)
		var source_cell := battlefield_grid.get_child(source_index) as Control
		if source_cell != null:
			return Rect2(source_cell.global_position, source_cell.size)
	if panel_shell != null:
		var fallback_size := Vector2(96.0, 60.0)
		return Rect2(panel_shell.global_position + (panel_shell.size * 0.5) - (fallback_size * 0.5), fallback_size)
	var default_size := Vector2(96.0, 60.0)
	return Rect2(global_position + (size * 0.5) - (default_size * 0.5), default_size)

# 실행: render and refresh the live battlefield cells against the decorative shell.
func render_battlefield(scene: Dictionary, disabled_tiles: Array) -> void:
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
	call_deferred("_layout_battlefield_visuals")

# 실행: remove all existing battlefield cell nodes.
func _clear_cells() -> void:
	for child in battlefield_grid.get_children():
		child.queue_free()

# 실행: rebuild the battlefield grid from scratch and reconnect cell signals.
func _rebuild_cells(cells: Array, disabled_tiles: Array) -> void:
	_clear_cells()
	for cell in cells:
		var cell_view = CellViewScript.new()
		cell_view.configure(cell, disabled_tiles)
		cell_view.set_battle_pause_active(battle_pause_active)
		cell_view.cell_hovered.connect(func(cid, col): cell_hovered.emit(cid, col))
		cell_view.cell_clicked.connect(func(cid, col): cell_clicked.emit(cid, col))
		cell_view.cell_pressed.connect(func(cid, col): cell_pressed.emit(cid, col))
		cell_view.cell_released.connect(func(): cell_released.emit())
		battlefield_grid.add_child(cell_view)

# 실행: refresh existing battlefield cell nodes in place.
func _update_cells(cells: Array, disabled_tiles: Array) -> void:
	for i in range(cells.size()):
		var cell_view = battlefield_grid.get_child(i)
		if cell_view.has_method("configure"):
			cell_view.configure(cells[i], disabled_tiles)
		if cell_view.has_method("set_battle_pause_active"):
			cell_view.set_battle_pause_active(battle_pause_active)

# 실행: parse a battlefield cell id into a safe zero-based column index with a shallow-pose fallback.
func _column_index_from_cell_id(cell_id: String) -> int:
	if not cell_id.begins_with("r"):
		return 6
	var c_index := cell_id.find("c")
	if c_index == -1 or c_index >= cell_id.length() - 1:
		return 6
	var column_text := cell_id.substr(c_index + 1, cell_id.length() - c_index - 1)
	if not column_text.is_valid_int():
		return 6
	return clampi(int(column_text), 0, 9)

# 실행: resolve the preloaded texture object for a mapped miner pose path.
func _texture_for_miner_pose_path(asset_path: String) -> Texture2D:
	match asset_path:
		MINER_90_TEXTURE_PATH:
			return _trimmed_miner_texture(asset_path, MINER_90_TEXTURE, MINER_90_VISIBLE_REGION)
		MINER_60_TEXTURE_PATH:
			return _trimmed_miner_texture(asset_path, MINER_60_TEXTURE, MINER_60_VISIBLE_REGION)
		MINER_45_TEXTURE_PATH:
			return _trimmed_miner_texture(asset_path, MINER_45_TEXTURE, MINER_45_VISIBLE_REGION)
	return _trimmed_miner_texture(MINER_45_TEXTURE_PATH, MINER_45_TEXTURE, MINER_45_VISIBLE_REGION)

func _trimmed_miner_texture(asset_path: String, base_texture: Texture2D, visible_region: Rect2) -> Texture2D:
	if miner_pose_textures.has(asset_path):
		return miner_pose_textures[asset_path]
	var atlas := AtlasTexture.new()
	atlas.atlas = base_texture
	atlas.region = visible_region
	miner_pose_textures[asset_path] = atlas
	return atlas

func _texture_display_size(texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ZERO
	if texture is AtlasTexture:
		return (texture as AtlasTexture).region.size
	return Vector2(float(texture.get_width()), float(texture.get_height()))

# 실행: tint each miner pose transition with a restrained impact color by column band.
func _accent_color_for_column(column_index: int) -> Color:
	if column_index >= 0 and column_index <= 1:
		return Color(1.0, 0.93, 0.80, 1.0)
	if column_index >= 2 and column_index <= 5:
		return Color(0.95, 0.97, 1.0, 1.0)
	return Color(1.0, 0.98, 0.93, 1.0)
