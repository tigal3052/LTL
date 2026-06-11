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
signal slot_drag_started(coord: Vector2)

const ArtifactClass = preload("res://src/models/Artifact.gd")
const GridFactory = preload("res://src/ui/presenters/BackpackGridFactory.gd")
const BackpackPinLayoutPolicyScript = preload("res://src/ui/presenters/BackpackPinLayoutPolicy.gd")
const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")
const PIN_1_TEXTURE := preload("res://resources/UI/pin/pin_1.png")
const PIN_2_TEXTURE := preload("res://resources/UI/pin/pin_2.png")
const PIN_3_TEXTURE := preload("res://resources/UI/pin/pin_3.png")
const PIN_4_TEXTURE := preload("res://resources/UI/pin/pin_4.png")
const VISUAL_COOLDOWN_TICKS_PER_SECOND := 20.0
const SLOT_HOVER_FX_ENABLED := false
const SLOT_GRID_SEPARATION := 2
const ARTIFACT_FILL_ALPHA := 0.32
const GHOST_FALLBACK_CELL_SIZE := Vector2(24, 24)
const BACKPACK_BASE_SIDE_MARGIN := 16
const PIN_REMOVAL_ANTICIPATION_SECONDS := 0.07
const PIN_REMOVAL_PULL_SECONDS := 0.20
const PIN_REMOVAL_PULL_RATIO := 0.45
const PIN_REMOVAL_ROTATION_DEGREES := 18.0
const PIN_REMOVAL_ANTICIPATION_SCALE := 0.92
const PIN_Z_INDEX := 24
const PIN_LAYOUT_SETTLE_FRAMES := 8
const PIN_VISIBLE_REGIONS := [
	Rect2(211, 237, 863, 655),
	Rect2(328, 237, 863, 655),
	Rect2(328, 230, 863, 655),
	Rect2(211, 230, 863, 655)
]

@onready var backpack_margin: MarginContainer = $Margin
@onready var backpack_grid_mock: GridContainer = $Margin/EngineBox/GridMock
var ghost_container: GridContainer
var held_artifact: ArtifactClass = null
var current_inventory = null
var cooldown_visuals_enabled: bool = false
var pin_overlay_canvas: Control
var pin_nodes: Array[TextureRect] = []
var visible_pin_count_value: int = 0
var pin_shell_active: bool = false
var pin_state_initialized: bool = false
var pin_removal_tweens: Dictionary = {}
var pin_layout_retry_budget: int = 0
var pin_layout_queued: bool = false
var pin_live_layout_retry_budget: int = 0
var battle_pause_active: bool = false

# 실행: setup ghost container.
func _ready() -> void:
	_apply_grid_shell_layout_policy()
	_setup_ghost_container()
	_setup_pin_overlays()
	resized.connect(func(): _queue_pin_layout())
	backpack_grid_mock.resized.connect(func(): _queue_pin_layout())
	_prime_pin_layout_settle()

# 실행: construct the 10x10 grid slots with border textures and inner input cells.
func setup_grid_slots() -> void:
	for child in backpack_grid_mock.get_children():
		child.queue_free()
	backpack_grid_mock.columns = 10
	backpack_grid_mock.add_theme_constant_override("h_separation", SLOT_GRID_SEPARATION)
	backpack_grid_mock.add_theme_constant_override("v_separation", SLOT_GRID_SEPARATION)
	_apply_grid_shell_layout_policy()
	var textures := _load_textures()
	for row in range(10):
		for column in range(10):
			if row == 0 or row == 9 or column == 0 or column == 9:
				backpack_grid_mock.add_child(GridFactory.border_cell(textures[GridFactory.border_slice(row, column)]))
			else:
				backpack_grid_mock.add_child(_interactive_slot(column - 1, row - 1, textures[5]))
	call_deferred("_install_slot_interactions")
	_prime_pin_layout_settle()

# 실행: initialize the drag-and-drop ghost container.
func _setup_ghost_container() -> void:
	ghost_container = GridContainer.new()
	ghost_container.top_level = true
	ghost_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ghost_container)
	ghost_container.visible = false

# 실행: process drag ghost position on frame tick.
func _setup_pin_overlays() -> void:
	if pin_overlay_canvas == null:
		pin_overlay_canvas = Control.new()
		pin_overlay_canvas.name = "PinOverlayCanvas"
		pin_overlay_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pin_overlay_canvas.clip_contents = false
		pin_overlay_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(pin_overlay_canvas)
	else:
		for child in pin_overlay_canvas.get_children():
			child.queue_free()
	pin_nodes.clear()
	var textures: Array[Texture2D] = [PIN_1_TEXTURE, PIN_2_TEXTURE, PIN_3_TEXTURE, PIN_4_TEXTURE]
	for index in range(textures.size()):
		var pin := TextureRect.new()
		pin.name = "Pin%d" % [index + 1]
		var atlas := AtlasTexture.new()
		atlas.atlas = textures[index]
		atlas.region = pin_visible_region_for_index(index)
		pin.texture = atlas
		pin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		pin.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		pin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pin.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		pin.top_level = false
		pin.z_index = PIN_Z_INDEX
		pin.visible = false
		pin_overlay_canvas.add_child(pin)
		pin_nodes.append(pin)

func _apply_grid_shell_layout_policy() -> void:
	if backpack_grid_mock == null:
		return
	backpack_grid_mock.size_flags_horizontal = backpack_grid_horizontal_flags()
	_apply_pin_shell_gutter(0.0)

func _process(_delta: float) -> void:
	if battle_pause_active:
		return
	if ghost_container and ghost_container.visible and held_artifact:
		var shape = held_artifact.shape
		var slot_size := _ghost_slot_size()
		ghost_container.global_position = ghost_global_position_for_cursor(get_global_mouse_position(), shape, slot_size)
	if pin_live_layout_retry_budget > 0:
		pin_live_layout_retry_budget -= 1
		_layout_pin_overlays()
	_update_charge_animation(_delta)

func set_battle_pause_active(active: bool) -> void:
	battle_pause_active = active

# 실행: update the visual presentation of the drag-and-drop ghost overlay.
func update_ghost_display(art: ArtifactClass) -> void:
	held_artifact = art
	for child in ghost_container.get_children():
		child.queue_free()
	if held_artifact == null:
		ghost_container.visible = false
		_update_drag_slot_feedback()
		return
	var shape = held_artifact.shape
	var slot_size := _ghost_slot_size()
	ghost_container.columns = shape[0].size() if shape.size() > 0 else 1
	ghost_container.add_theme_constant_override("h_separation", SLOT_GRID_SEPARATION)
	ghost_container.add_theme_constant_override("v_separation", SLOT_GRID_SEPARATION)
	for row in range(shape.size()):
		for column in range(shape[row].size()):
			ghost_container.add_child(_ghost_cell(str(held_artifact.energy_type), int(shape[row][column]) == 1, shape, row, column, slot_size))
	ghost_container.visible = true
	_update_drag_slot_feedback()

# 실행: render active items inside the 8x8 backpack grid using panel overlays.
func render_backpack_items(inventory) -> void:
	current_inventory = inventory
	_clear_overlays()
	if inventory == null:
		return
	for art_id in inventory.artifacts:
		var art = inventory.artifacts[art_id]
		for row in range(art.shape.size()):
			for column in range(art.shape[row].size()):
				if int(art.shape[row][column]) == 1:
					_apply_artifact_overlay(int(art.x) + column, int(art.y) + row, art, art.shape, row, column)

func set_cooldown_visuals_enabled(enabled: bool) -> void:
	if cooldown_visuals_enabled == enabled:
		return
	cooldown_visuals_enabled = enabled
	if current_inventory != null:
		render_backpack_items(current_inventory)

# 실행: load backpack border textures.
func update_pin_overlays(scene: Dictionary) -> void:
	var phase := str(scene.get("phase", ""))
	var pin_state: Dictionary = scene.get("hud", {}).get("pin", {})
	pin_shell_active = phase == "combat"
	var next_visible_count := pin_visible_count(phase == "combat", float(pin_state.get("progress", 0.0)))
	if phase != "combat":
		pin_shell_active = false
		pin_layout_retry_budget = 0
		pin_live_layout_retry_budget = 0
		_apply_pin_shell_gutter(0.0)
		_reset_pin_vfx_state()
		visible_pin_count_value = 0
		for index in range(pin_nodes.size()):
			pin_nodes[index].visible = false
		_prime_pin_layout_settle()
		return
	if pin_state_initialized:
		for removed_index in removed_pin_indices(visible_pin_count_value, next_visible_count):
			_play_pin_removed_vfx(removed_index)
	else:
		pin_state_initialized = true
	visible_pin_count_value = next_visible_count
	for index in range(pin_nodes.size()):
		if pin_is_visible(index, visible_pin_count_value):
			_reset_pin_visual(pin_nodes[index])
			pin_nodes[index].visible = true
		elif not pin_nodes[index].has_meta("pin_removing"):
			pin_nodes[index].visible = false
	_prime_pin_layout_settle()

func pin_visible_count(active: bool, progress: float) -> int:
	if not active:
		return 0
	var pin_val := clampf(progress, 0.0, 100.0)
	if pin_val >= 100.0:
		return 4
	if pin_val >= 75.0:
		return 3
	if pin_val >= 50.0:
		return 2
	if pin_val >= 25.0:
		return 1
	return 0

func pin_corner_specs() -> Array:
	return [
		{"name": "Pin1", "column": 0, "row": 0, "horizontal": "left", "vertical": "center"},
		{"name": "Pin2", "column": 9, "row": 0, "horizontal": "right", "vertical": "center"},
		{"name": "Pin3", "column": 9, "row": 9, "horizontal": "right", "vertical": "center"},
		{"name": "Pin4", "column": 0, "row": 9, "horizontal": "left", "vertical": "center"}
	]

func backpack_grid_horizontal_flags() -> int:
	return Control.SIZE_EXPAND_FILL

func pin_visible_region_for_index(index: int) -> Rect2:
	if index < 0 or index >= PIN_VISIBLE_REGIONS.size():
		return PIN_VISIBLE_REGIONS[0]
	return PIN_VISIBLE_REGIONS[index]

func pin_shell_side_margin_for_outset(side_outset: float, shell_active: bool) -> int:
	if not shell_active:
		return BACKPACK_BASE_SIDE_MARGIN
	return BACKPACK_BASE_SIDE_MARGIN + int(round(side_outset))

func pin_slot_extent_for_grid_extent(grid_extent: float) -> float:
	return BackpackPinLayoutPolicyScript.slot_extent_for_grid_extent(grid_extent)

func pin_display_extent_for_slot_extent(slot_extent: float) -> float:
	return BackpackPinLayoutPolicyScript.display_extent_for_slot_extent(slot_extent)

func pin_display_size_for_slot_extent(slot_extent: float) -> Vector2:
	return BackpackPinLayoutPolicyScript.display_size_for_slot_extent(slot_extent)

func pin_slot_extent_for_cell_rect(layout_rect: Rect2) -> float:
	return BackpackPinLayoutPolicyScript.slot_extent_for_cell_rect(layout_rect)

func pin_grid_overlap_for_slot_extent(slot_extent: float) -> float:
	return BackpackPinLayoutPolicyScript.grid_overlap_for_slot_extent(slot_extent)

func pin_side_outset_for_slot_extent(slot_extent: float) -> float:
	return BackpackPinLayoutPolicyScript.side_outset_for_slot_extent(slot_extent)

func pin_display_extent_for_grid_extent(grid_extent: float) -> float:
	return BackpackPinLayoutPolicyScript.display_extent_for_grid_extent(grid_extent)

func pin_side_outset_for_grid_extent(grid_extent: float) -> float:
	return BackpackPinLayoutPolicyScript.side_outset_for_grid_extent(grid_extent)

func backpack_panel_extra_width_for_grid_extent(grid_extent: float) -> float:
	return BackpackPinLayoutPolicyScript.extra_width_for_grid_extent(grid_extent)

func _apply_pin_shell_gutter(side_outset: float) -> bool:
	if backpack_margin == null:
		return false
	var next_margin := pin_shell_side_margin_for_outset(side_outset, pin_shell_active)
	var changed := false
	if backpack_margin.get_theme_constant("margin_left") != next_margin:
		backpack_margin.add_theme_constant_override("margin_left", next_margin)
		changed = true
	if backpack_margin.get_theme_constant("margin_right") != next_margin:
		backpack_margin.add_theme_constant_override("margin_right", next_margin)
		changed = true
	return changed

func pin_visible_indices(visible_count: int, total_count: int = 4) -> Array:
	var safe_total := maxi(0, total_count)
	var safe_count := clampi(visible_count, 0, safe_total)
	var start_index := safe_total - safe_count
	var indices: Array = []
	for index in range(start_index, safe_total):
		indices.append(index)
	return indices

func pin_is_visible(index: int, visible_count: int) -> bool:
	var total_count := pin_nodes.size() if not pin_nodes.is_empty() else 4
	return pin_visible_indices(visible_count, total_count).has(index)

func pin_pull_direction_for_index(index: int) -> Vector2:
	match index:
		0:
			return Vector2(-1, -1).normalized()
		1:
			return Vector2(1, -1).normalized()
		2:
			return Vector2(1, 1).normalized()
		3:
			return Vector2(-1, 1).normalized()
		_:
			return Vector2.ZERO

func pin_removal_vfx_profile_for_index(index: int, pin_extent: float) -> Dictionary:
	return {
		"direction": pin_pull_direction_for_index(index),
		"anticipationDuration": PIN_REMOVAL_ANTICIPATION_SECONDS,
		"pullDuration": PIN_REMOVAL_PULL_SECONDS,
		"pullDistance": maxf(0.0, pin_extent) * PIN_REMOVAL_PULL_RATIO,
		"rotationDegrees": PIN_REMOVAL_ROTATION_DEGREES,
		"anticipationScale": PIN_REMOVAL_ANTICIPATION_SCALE,
		"fadeToAlpha": 0.0,
		"localOnly": true
	}

func removed_pin_indices(previous_count: int, next_count: int) -> Array:
	var previous_indices: Array = pin_visible_indices(previous_count)
	var next_indices: Array = pin_visible_indices(next_count)
	var removed: Array = []
	for index in previous_indices:
		if not next_indices.has(index):
			removed.append(index)
	return removed

func _load_textures() -> Dictionary:
	var textures := {}
	for i in range(1, 10):
		textures[i] = load("res://resources/UI/backpack_%d.png" % i)
	return textures

# 실행: create an input slot and wire signals.
func _interactive_slot(grid_column: int, grid_row: int, texture: Texture2D) -> Panel:
	var slot: Panel = GridFactory.inner_slot(texture)
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not SLOT_HOVER_FX_ENABLED:
		slot.set_meta(InteractionFXScript.META_SKIP, true)
	var state := {"pressed": false, "dragging": false, "press_pos": Vector2.ZERO}
	slot.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				state["pressed"] = true
				state["dragging"] = false
				state["press_pos"] = event.position
			else:
				var was_pressed := bool(state.get("pressed", false))
				var was_dragging := bool(state.get("dragging", false))
				state["pressed"] = false
				state["dragging"] = false
				if was_pressed and not was_dragging:
					slot_clicked.emit(Vector2(grid_column, grid_row))
		elif event is InputEventMouseMotion and bool(state.get("pressed", false)) and not bool(state.get("dragging", false)):
			var press_pos: Vector2 = state.get("press_pos", Vector2.ZERO)
			if event.position.distance_to(press_pos) >= 10.0:
				state["dragging"] = true
				slot_drag_started.emit(Vector2(grid_column, grid_row))
	)
	slot.mouse_entered.connect(func(): slot_hovered.emit(Vector2(grid_column, grid_row)))
	slot.mouse_exited.connect(func(): slot_unhovered.emit(Vector2(grid_column, grid_row)))
	return slot

# ?ㅽ뻾: add shared hover/click affordance effects to backpack slot panels.
func _install_slot_interactions() -> void:
	if not SLOT_HOVER_FX_ENABLED:
		return
	InteractionFXScript.install_tree(backpack_grid_mock)

# ?ㅽ뻾: mark visible drop slots while an artifact is being dragged.
func _update_drag_slot_feedback() -> void:
	for row in range(8):
		for column in range(8):
			var slot_idx := (row + 1) * 10 + (column + 1)
			if slot_idx < backpack_grid_mock.get_child_count():
				var slot := backpack_grid_mock.get_child(slot_idx) as Control
				if slot != null:
					InteractionFXScript.apply_drag_feedback(slot, held_artifact != null, can_drop_artifact(current_inventory, held_artifact, column, row))

func slot_coord_at_global_pos(global_pos: Vector2) -> Vector2:
	for row in range(8):
		for column in range(8):
			var slot_idx := (row + 1) * 10 + (column + 1)
			if slot_idx >= backpack_grid_mock.get_child_count():
				continue
			var slot := backpack_grid_mock.get_child(slot_idx) as Control
			if slot == null:
				continue
			if slot.get_global_rect().has_point(global_pos):
				return Vector2(column, row)
	return Vector2(-1, -1)

# ?ㅽ뻾: expose the same placement rule for UI drag affordance and tests.
static func can_drop_artifact(inventory, artifact, column: int, row: int) -> bool:
	if inventory == null or artifact == null:
		return true
	if not inventory.has_method("can_place_artifact"):
		return true
	return inventory.can_place_artifact(artifact, column, row)

static func slot_hover_fx_enabled() -> bool:
	return SLOT_HOVER_FX_ENABLED

func artifact_fill_alpha() -> float:
	return ARTIFACT_FILL_ALPHA

func ghost_cell_size_for_slot(slot_size: Vector2) -> Vector2:
	if slot_size.x > 0.0 and slot_size.y > 0.0:
		return slot_size
	return GHOST_FALLBACK_CELL_SIZE

func ghost_global_position_for_cursor(cursor_global_pos: Vector2, _shape: Array, _slot_size: Vector2) -> Vector2:
	return cursor_global_pos

# 실행: create one ghost grid cell.
func _ghost_cell(energy_type: String, filled: bool, shape: Array, row: int, column: int, slot_size: Vector2) -> Control:
	var draw_size := ghost_cell_size_for_slot(slot_size)
	if not filled:
		var empty := Control.new()
		empty.custom_minimum_size = draw_size
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return empty
	var box := Panel.new()
	box.custom_minimum_size = draw_size
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override("panel", GridFactory.artifact_style(energy_type, artifact_fill_alpha(), GridFactory.artifact_edge_mask(shape, row, column)))
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
	_prime_pin_layout_settle()

# 실행: apply artifact overlay to a backpack coordinate.
func _apply_artifact_overlay(column: int, row: int, art: ArtifactClass, shape: Array, shape_row: int, shape_column: int) -> void:
	var overlay := _slot_overlay(column, row)
	if overlay:
		overlay.add_theme_stylebox_override("panel", GridFactory.artifact_style(str(art.energy_type), artifact_fill_alpha(), GridFactory.artifact_edge_mask(shape, shape_row, shape_column)))
	var charge := _slot_charge_overlay(column, row)
	if charge:
		if not cooldown_visuals_enabled:
			charge.visible = false
			charge.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			charge.remove_meta("display_cooldown_ticks")
			charge.remove_meta("effective_cooldown_ticks")
			return
		var cooldown_ticks := float(art.current_cooldown)
		var effective_cooldown := maxi(1, int(art.base_cooldown_ticks) - int(art.synergy_cooldown_reduction))
		var display_ticks := cooldown_ticks
		if charge.has_meta("display_cooldown_ticks"):
			display_ticks = float(charge.get_meta("display_cooldown_ticks"))
			display_ticks = GridFactory.stable_cooldown_display(display_ticks, cooldown_ticks, effective_cooldown)
		charge.visible = true
		charge.set_meta("display_cooldown_ticks", display_ticks)
		charge.set_meta("effective_cooldown_ticks", effective_cooldown)
		charge.add_theme_stylebox_override("panel", GridFactory.cooldown_mask_style(0.46, GridFactory.artifact_edge_mask(shape, shape_row, shape_column)))
		_apply_cooldown_mask(charge, display_ticks / float(effective_cooldown))

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

# 실행: drain visible cooldown masks every frame between backend snapshots.
func _update_charge_animation(delta: float) -> void:
	for row in range(8):
		for column in range(8):
			var charge := _slot_charge_overlay(column, row)
			if charge == null or not charge.visible or not charge.has_meta("display_cooldown_ticks"):
				continue
			var next := GridFactory.advance_visual_cooldown(float(charge.get_meta("display_cooldown_ticks")), delta, VISUAL_COOLDOWN_TICKS_PER_SECOND)
			var effective := float(charge.get_meta("effective_cooldown_ticks", 1.0))
			charge.set_meta("display_cooldown_ticks", next)
			_apply_cooldown_mask(charge, next / maxf(1.0, effective))

# 실행: apply top-down anchors for a shrinking translucent cooldown mask.
func _apply_cooldown_mask(charge: Panel, ratio: float) -> void:
	var remaining := clampf(ratio, 0.0, 1.0)
	charge.anchor_left = 0.0
	charge.anchor_right = 1.0
	charge.anchor_top = 0.0
	charge.anchor_bottom = remaining
	charge.offset_left = 0.0
	charge.offset_right = 0.0
	charge.offset_top = 0.0
	charge.offset_bottom = 0.0

func _layout_pin_overlays() -> void:
	if backpack_grid_mock == null or backpack_grid_mock.get_child_count() == 0 or pin_nodes.is_empty():
		return
	_apply_grid_shell_layout_policy()
	var specs := pin_corner_specs()
	var target_side_outset := 0.0
	for index in range(mini(pin_nodes.size(), specs.size())):
		var spec: Dictionary = specs[index]
		var cell_rect := pin_grid_cell_rect_local(int(spec.get("column", 0)), int(spec.get("row", 0)))
		if cell_rect.size.x <= 0.0 or cell_rect.size.y <= 0.0:
			continue
		target_side_outset = maxf(target_side_outset, pin_side_outset_for_slot_extent(pin_slot_extent_for_cell_rect(cell_rect)))
	var gutter_changed := _apply_pin_shell_gutter(target_side_outset)
	if gutter_changed:
		if pin_layout_retry_budget < 3:
			pin_layout_retry_budget += 1
			_queue_pin_layout()
	else:
		pin_layout_retry_budget = 0
	for index in range(mini(pin_nodes.size(), specs.size())):
		var pin := pin_nodes[index]
		var spec: Dictionary = specs[index]
		var cell_rect := pin_grid_cell_rect_local(int(spec.get("column", 0)), int(spec.get("row", 0)))
		if cell_rect.size.x <= 0.0 or cell_rect.size.y <= 0.0:
			pin.visible = false
			continue
		var slot_extent := pin_slot_extent_for_cell_rect(cell_rect)
		var grid_overlap := pin_grid_overlap_for_slot_extent(slot_extent)
		pin.size = pin_display_size_for_slot_extent(slot_extent)
		pin.pivot_offset = pin.size * 0.5
		var anchor := pin_corner_anchor_for_rect(cell_rect, spec)
		if not pin.has_meta("pin_removing"):
			pin.position = pin_position_for_anchor(anchor, pin.size, spec, grid_overlap)
		pin.z_index = PIN_Z_INDEX
		if pin_is_visible(index, visible_pin_count_value):
			pin.visible = true
		elif not pin.has_meta("pin_removing"):
			pin.visible = false

func pin_grid_cell_rect_local(column: int, row: int) -> Rect2:
	var cell := _grid_cell(column, row)
	if cell == null:
		return Rect2()
	var local_canvas: CanvasItem = pin_overlay_canvas if pin_overlay_canvas != null else self
	var local_origin := local_canvas.get_global_transform_with_canvas().affine_inverse() * cell.get_global_transform_with_canvas().origin
	return Rect2(local_origin, cell.size)

func _queue_pin_layout() -> void:
	if pin_layout_queued:
		return
	if not is_inside_tree():
		call_deferred("_layout_pin_overlays")
		return
	pin_layout_queued = true
	call_deferred("_run_queued_pin_layout")

func _prime_pin_layout_settle() -> void:
	pin_live_layout_retry_budget = max(pin_live_layout_retry_budget, PIN_LAYOUT_SETTLE_FRAMES)
	_queue_pin_layout()

func _run_queued_pin_layout() -> void:
	await get_tree().process_frame
	pin_layout_queued = false
	_layout_pin_overlays()
	if _pins_need_live_layout_retry() and pin_live_layout_retry_budget < 4:
		pin_live_layout_retry_budget += 1
		_queue_pin_layout()
		return
	pin_live_layout_retry_budget = 0

func _pins_need_live_layout_retry() -> bool:
	var specs := pin_corner_specs()
	for index in range(mini(pin_nodes.size(), specs.size())):
		var pin := pin_nodes[index]
		var spec: Dictionary = specs[index]
		if pin == null or (not pin.visible and not pin.has_meta("pin_removing")):
			continue
		var cell_rect := pin_grid_cell_rect_local(int(spec.get("column", 0)), int(spec.get("row", 0)))
		if cell_rect.size.x <= 0.0 or cell_rect.size.y <= 0.0:
			continue
		var slot_extent := pin_slot_extent_for_cell_rect(cell_rect)
		var expected_size := pin_display_size_for_slot_extent(slot_extent)
		var expected_anchor := pin_corner_anchor_for_rect(cell_rect, spec)
		var expected_position := pin_position_for_anchor(expected_anchor, expected_size, spec, pin_grid_overlap_for_slot_extent(slot_extent))
		if pin.size.distance_to(expected_size) > 0.5:
			return true
		if not pin.has_meta("pin_removing") and pin.position.distance_to(expected_position) > 1.0:
			return true
	return false

func pin_corner_anchor_for_rect(layout_rect: Rect2, spec: Dictionary) -> Vector2:
	var horizontal := str(spec.get("horizontal", "left"))
	var vertical := str(spec.get("vertical", "top"))
	return Vector2(
		layout_rect.position.x if horizontal == "left" else layout_rect.end.x,
		layout_rect.position.y if vertical == "top" else (layout_rect.end.y if vertical == "bottom" else layout_rect.position.y + (layout_rect.size.y * 0.5))
	)

func pin_position_for_anchor(anchor: Vector2, pin_size: Vector2, spec: Dictionary, grid_overlap: float) -> Vector2:
	var horizontal := str(spec.get("horizontal", "left"))
	var vertical := str(spec.get("vertical", "top"))
	var x := anchor.x + grid_overlap - pin_size.x if horizontal == "left" else anchor.x - grid_overlap
	var y := anchor.y + grid_overlap - pin_size.y if vertical == "top" else (anchor.y - grid_overlap if vertical == "bottom" else anchor.y - (pin_size.y * 0.5))
	return Vector2(x, y)

func _reset_pin_visual(pin: TextureRect) -> void:
	if pin == null:
		return
	pin.remove_meta("pin_removing")
	pin.modulate = Color(1, 1, 1, 1)
	pin.scale = Vector2.ONE
	pin.rotation_degrees = 0.0

func _reset_pin_vfx_state() -> void:
	pin_state_initialized = false
	for key in pin_removal_tweens.keys():
		var tween = pin_removal_tweens[key]
		if tween != null and tween is Tween:
			tween.kill()
	pin_removal_tweens.clear()
	for pin in pin_nodes:
		_reset_pin_visual(pin)

func _play_pin_removed_vfx(index: int) -> void:
	if index < 0 or index >= pin_nodes.size():
		return
	var pin := pin_nodes[index]
	if pin == null:
		return
	if pin_removal_tweens.has(index):
		var previous_tween = pin_removal_tweens[index]
		if previous_tween != null and previous_tween is Tween:
			previous_tween.kill()
	var pin_extent := maxf(pin.size.x, pin.size.y)
	var profile := pin_removal_vfx_profile_for_index(index, pin_extent)
	var direction: Vector2 = profile.get("direction", Vector2.ZERO)
	var pull_distance := float(profile.get("pullDistance", 0.0))
	var anticipation_seconds := float(profile.get("anticipationDuration", 0.06))
	var pull_seconds := float(profile.get("pullDuration", 0.18))
	var rotation_degrees := float(profile.get("rotationDegrees", 16.0))
	var base_position := pin.position
	pin.set_meta("pin_removing", true)
	pin.visible = true
	pin.modulate = Color(1, 1, 1, 1)
	pin.scale = Vector2.ONE
	var tween := create_tween().bind_node(pin)
	pin_removal_tweens[index] = tween
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(pin, "scale", Vector2.ONE * float(profile.get("anticipationScale", 0.94)), anticipation_seconds)
	tween.parallel().tween_property(pin, "rotation_degrees", -rotation_degrees * 0.35, anticipation_seconds)
	tween.tween_property(pin, "position", base_position + direction * pull_distance, pull_seconds)
	tween.parallel().tween_property(pin, "rotation_degrees", rotation_degrees, pull_seconds)
	tween.parallel().tween_property(pin, "modulate:a", float(profile.get("fadeToAlpha", 0.0)), pull_seconds)
	tween.finished.connect(func():
		pin_removal_tweens.erase(index)
		_reset_pin_visual(pin)
		pin.visible = pin_is_visible(index, visible_pin_count_value)
		call_deferred("_layout_pin_overlays")
	)

func _slot_panel(column: int, row: int) -> Panel:
	if column < 0 or column >= 8 or row < 0 or row >= 8:
		return null
	var slot_idx := (row + 1) * 10 + (column + 1)
	if slot_idx >= backpack_grid_mock.get_child_count():
		return null
	return backpack_grid_mock.get_child(slot_idx) as Panel

func _grid_cell(column: int, row: int) -> Control:
	if backpack_grid_mock == null:
		return null
	if column < 0 or column >= 10 or row < 0 or row >= 10:
		return null
	var cell_idx := row * 10 + column
	if cell_idx < 0 or cell_idx >= backpack_grid_mock.get_child_count():
		return null
	return backpack_grid_mock.get_child(cell_idx) as Control

func _ghost_slot_size() -> Vector2:
	var slot := _slot_panel(0, 0)
	if slot != null:
		var live_size := slot.size
		if live_size.x > 0.0 and live_size.y > 0.0:
			return ghost_cell_size_for_slot(live_size)
		var min_size := slot.get_combined_minimum_size()
		if min_size.x > 0.0 and min_size.y > 0.0:
			return ghost_cell_size_for_slot(min_size)
	return GHOST_FALLBACK_CELL_SIZE

func _ghost_footprint(shape: Array, slot_size: Vector2) -> Vector2:
	var rows: int = shape.size()
	var cols: int = shape[0].size() if rows > 0 else 0
	var draw_size := ghost_cell_size_for_slot(slot_size)
	if rows <= 0 or cols <= 0:
		return draw_size
	return Vector2(
		float(cols) * draw_size.x + float(maxi(0, cols - 1)) * SLOT_GRID_SEPARATION,
		float(rows) * draw_size.y + float(maxi(0, rows - 1)) * SLOT_GRID_SEPARATION
	)
