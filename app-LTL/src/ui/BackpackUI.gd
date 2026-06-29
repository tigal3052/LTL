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
const BackpackPinOverlayRuntimeScript = preload("res://src/ui/backpack/BackpackPinOverlayRuntime.gd")
const BackpackArtifactRendererScript = preload("res://src/ui/backpack/BackpackArtifactRenderer.gd")
const BackpackFusionVFXScript = preload("res://src/ui/backpack/BackpackFusionVFX.gd")
const BackpackInfluenceToggleRuntimeScript = preload("res://src/ui/backpack/BackpackInfluenceToggleRuntime.gd")
@onready var backpack_margin: MarginContainer = $Margin
@onready var backpack_grid_mock: GridContainer = $Margin/EngineBox/GridMock
var ghost_container: GridContainer
var ghost_texture_rect: TextureRect
var artifact_image_layer: Control
var held_artifact: ArtifactClass = null
var current_inventory = null
var cooldown_visuals_enabled: bool = false
var artifact_image_refresh_queued: bool = false
var artifact_image_refresh_retry_budget: int = 0
var artifact_image_layout_signature: Rect2 = Rect2()
var artifact_image_layout_signature_initialized: bool = false
var drill_texture_cache: Dictionary = {}
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
var influence_preview_enabled: bool = true
var influence_preview_toggle_visible: bool = false
var influence_preview_toggle_button: CheckButton
var influence_preview_toggle_anchor_control: Control

# 실행: setup ghost container.
func _ready() -> void:
	_apply_grid_shell_layout_policy()
	_setup_ghost_container()
	_setup_artifact_image_layer()
	_setup_pin_overlays()
	_setup_influence_preview_toggle()
	resized.connect(func():
		_queue_artifact_image_refresh()
		_queue_pin_layout()
		call_deferred("_position_influence_preview_toggle")
	)
	backpack_grid_mock.resized.connect(func():
		_queue_artifact_image_refresh()
		_queue_pin_layout()
		call_deferred("_position_influence_preview_toggle")
	)
	_prime_pin_layout_settle()

# 실행: construct the 10x10 grid slots with border textures and inner input cells.
func setup_grid_slots() -> void:
	for child in backpack_grid_mock.get_children():
		child.queue_free()
	backpack_grid_mock.columns = 10
	backpack_grid_mock.add_theme_constant_override("h_separation", BackpackArtifactRendererScript.SLOT_GRID_SEPARATION)
	backpack_grid_mock.add_theme_constant_override("v_separation", BackpackArtifactRendererScript.SLOT_GRID_SEPARATION)
	_apply_grid_shell_layout_policy()
	var textures := _load_textures()
	for row in range(10):
		for column in range(10):
			if row == 0 or row == 9 or column == 0 or column == 9:
				backpack_grid_mock.add_child(GridFactory.border_cell(textures[GridFactory.border_slice(row, column)]))
			else:
				backpack_grid_mock.add_child(_interactive_slot(column - 1, row - 1, textures[5]))
	call_deferred("_install_slot_interactions")
	_queue_artifact_image_refresh()
	_prime_pin_layout_settle()

# 실행: initialize the drag-and-drop ghost container.
func _setup_ghost_container() -> void:
	ghost_container = GridContainer.new()
	ghost_container.top_level = true
	ghost_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ghost_container)
	ghost_container.visible = false
	ghost_texture_rect = TextureRect.new()
	ghost_texture_rect.top_level = true
	ghost_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ghost_texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(ghost_texture_rect)
	ghost_texture_rect.visible = false

func _setup_artifact_image_layer() -> void:
	artifact_image_layer = Control.new()
	artifact_image_layer.name = "ArtifactImageLayer"
	artifact_image_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artifact_image_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artifact_image_layer.z_index = 8
	add_child(artifact_image_layer)

# 실행: process drag ghost position on frame tick.
func _setup_pin_overlays() -> void:
	BackpackPinOverlayRuntimeScript.setup(self)

func _setup_influence_preview_toggle() -> void:
	BackpackInfluenceToggleRuntimeScript.setup(self)

func _apply_grid_shell_layout_policy() -> void:
	BackpackPinOverlayRuntimeScript.apply_grid_shell_layout_policy(self)

func _process(_delta: float) -> void:
	BackpackArtifactRendererScript.refresh_artifact_images_if_layout_changed(self)
	if influence_preview_toggle_button != null and influence_preview_toggle_button.visible:
		_position_influence_preview_toggle()
	if battle_pause_active:
		return
	if held_artifact:
		var shape = held_artifact.shape
		var slot_size := _ghost_slot_size()
		var ghost_pos := ghost_global_position_for_cursor(get_global_mouse_position(), shape, slot_size)
		if ghost_container and ghost_container.visible:
			ghost_container.global_position = ghost_pos
		if ghost_texture_rect and ghost_texture_rect.visible:
			BackpackArtifactRendererScript.apply_oriented_item_image_placement(ghost_texture_rect, ghost_texture_rect.texture, Rect2(ghost_pos, _ghost_footprint(shape, slot_size)), int(held_artifact.rotation), true)
		_update_drag_slot_feedback()
	if pin_live_layout_retry_budget > 0:
		pin_live_layout_retry_budget -= 1
		_layout_pin_overlays()
	BackpackArtifactRendererScript.update_charge_animation(self, _delta)

func set_battle_pause_active(active: bool) -> void:
	battle_pause_active = active

# 실행: update the visual presentation of the drag-and-drop ghost overlay.
func update_ghost_display(art: ArtifactClass) -> void:
	held_artifact = art
	for child in ghost_container.get_children():
		child.queue_free()
	ghost_container.visible = false
	if ghost_texture_rect != null:
		ghost_texture_rect.visible = false
		BackpackArtifactRendererScript.reset_item_image_transform(ghost_texture_rect)
	if held_artifact == null:
		_update_drag_slot_feedback()
		return
	var shape = held_artifact.shape
	var slot_size := _ghost_slot_size()
	var item_texture := _item_texture_for_artifact(held_artifact)
	if item_texture != null:
		var ghost_rect := Rect2(ghost_global_position_for_cursor(get_global_mouse_position(), shape, slot_size), _ghost_footprint(shape, slot_size))
		BackpackArtifactRendererScript.apply_oriented_item_image_placement(ghost_texture_rect, item_texture, ghost_rect, int(held_artifact.rotation), true)
		ghost_texture_rect.visible = true
		_update_drag_slot_feedback()
		return
	ghost_container.columns = shape[0].size() if shape.size() > 0 else 1
	ghost_container.add_theme_constant_override("h_separation", BackpackArtifactRendererScript.SLOT_GRID_SEPARATION)
	ghost_container.add_theme_constant_override("v_separation", BackpackArtifactRendererScript.SLOT_GRID_SEPARATION)
	for row in range(shape.size()):
		for column in range(shape[row].size()):
			ghost_container.add_child(_ghost_cell(str(held_artifact.energy_type), int(shape[row][column]) == 1, shape, row, column, slot_size))
	ghost_container.visible = true
	_update_drag_slot_feedback()

# 실행: render active items inside the 8x8 backpack grid using panel overlays.
func render_backpack_items(inventory) -> void:
	BackpackArtifactRendererScript.render_items(self, inventory)

func play_fusion_effect(art: ArtifactClass) -> void:
	BackpackFusionVFXScript.play(self, art)

func set_cooldown_visuals_enabled(enabled: bool) -> void:
	if cooldown_visuals_enabled == enabled:
		return
	cooldown_visuals_enabled = enabled
	if current_inventory != null:
		render_backpack_items(current_inventory)

# 실행: load backpack border textures.
func set_influence_preview_enabled(enabled: bool) -> void:
	if influence_preview_enabled == enabled:
		return
	influence_preview_enabled = enabled
	if influence_preview_toggle_button != null and influence_preview_toggle_button.button_pressed != enabled:
		influence_preview_toggle_button.button_pressed = enabled
	if backpack_grid_mock != null:
		_update_drag_slot_feedback()

func get_influence_preview_enabled() -> bool:
	return influence_preview_enabled
func set_influence_preview_toggle_visible(visible: bool) -> void:
	influence_preview_toggle_visible = visible
	if influence_preview_toggle_button != null:
		influence_preview_toggle_button.visible = visible
		call_deferred("_position_influence_preview_toggle")
func set_influence_preview_toggle_anchor(anchor_control: Control) -> void:
	influence_preview_toggle_anchor_control = anchor_control
	call_deferred("_position_influence_preview_toggle")
func _position_influence_preview_toggle() -> void:
	BackpackInfluenceToggleRuntimeScript.position(self)

func update_pin_overlays(scene: Dictionary) -> void:
	BackpackPinOverlayRuntimeScript.update(self, scene)

func pin_visible_count(active: bool, progress: float) -> int:
	return BackpackPinOverlayRuntimeScript.visible_count(active, progress)

func pin_corner_specs() -> Array:
	return BackpackPinOverlayRuntimeScript.corner_specs()

func backpack_grid_horizontal_flags() -> int:
	return Control.SIZE_EXPAND_FILL

func pin_visible_region_for_index(index: int) -> Rect2:
	return BackpackPinOverlayRuntimeScript.visible_region_for_index(index)

func pin_shell_side_margin_for_outset(side_outset: float, shell_active: bool) -> int:
	return BackpackPinOverlayRuntimeScript.shell_side_margin_for_outset(side_outset, shell_active)

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
	return BackpackPinOverlayRuntimeScript.apply_pin_shell_gutter(self, side_outset)

func pin_visible_indices(visible_count: int, total_count: int = 4) -> Array:
	return BackpackPinOverlayRuntimeScript.visible_indices(visible_count, total_count)

func pin_is_visible(index: int, visible_count: int) -> bool:
	var total_count := pin_nodes.size() if not pin_nodes.is_empty() else 4
	return BackpackPinOverlayRuntimeScript.is_visible(index, visible_count, total_count)

func pin_pull_direction_for_index(index: int) -> Vector2:
	return BackpackPinOverlayRuntimeScript.pull_direction_for_index(index)

func pin_removal_vfx_profile_for_index(index: int, pin_extent: float) -> Dictionary:
	return BackpackPinOverlayRuntimeScript.removal_vfx_profile_for_index(index, pin_extent)

func removed_pin_indices(previous_count: int, next_count: int) -> Array:
	return BackpackPinOverlayRuntimeScript.removed_indices(previous_count, next_count)

func _load_textures() -> Dictionary:
	var textures := {}
	for i in range(1, 10):
		textures[i] = load("res://resources/UI/backpack_%d.png" % i)
	return textures

# 실행: create an input slot and wire signals.
func _interactive_slot(grid_column: int, grid_row: int, texture: Texture2D) -> Panel:
	var slot: Panel = GridFactory.inner_slot(texture)
	slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not BackpackArtifactRendererScript.SLOT_HOVER_FX_ENABLED:
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
	if not BackpackArtifactRendererScript.SLOT_HOVER_FX_ENABLED:
		return
	InteractionFXScript.install_tree(backpack_grid_mock)

# ?ㅽ뻾: mark visible drop slots while an artifact is being dragged.
func _update_drag_slot_feedback() -> void:
	BackpackArtifactRendererScript.refresh_influence_overlays(self, current_inventory)
	_clear_drop_cue_overlays()
	if held_artifact == null:
		return
	var origin := slot_coord_at_global_pos(get_global_mouse_position())
	if origin.x < 0 or origin.y < 0:
		return
	BackpackArtifactRendererScript.apply_ghost_influence_overlays(self, held_artifact, int(origin.x), int(origin.y), current_inventory)
	var valid := can_drop_artifact(current_inventory, held_artifact, int(origin.x), int(origin.y))
	for cell in drop_feedback_cells_for(held_artifact, int(origin.x), int(origin.y)):
		var column := int((cell as Vector2).x)
		var row := int((cell as Vector2).y)
		var drop_cue := _slot_drop_cue(column, row)
		if drop_cue:
			drop_cue.add_theme_stylebox_override("panel", GridFactory.drop_cue_style(valid, GridFactory.artifact_edge_mask(held_artifact.shape, row - int(origin.y), column - int(origin.x))))

func _clear_drop_cue_overlays() -> void:
	for row in range(8):
		for column in range(8):
			var drop_cue := _slot_drop_cue(column, row)
			if drop_cue:
				drop_cue.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

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
	return BackpackArtifactRendererScript.can_drop_artifact(inventory, artifact, column, row)

static func drop_feedback_cells_for(artifact, column: int, row: int) -> Array:
	return BackpackArtifactRendererScript.drop_feedback_cells_for(artifact, column, row)

static func influence_feedback_cells_for(artifact, column: int, row: int) -> Array:
	return BackpackArtifactRendererScript.influence_feedback_cells_for(artifact, column, row)

static func slot_hover_fx_enabled() -> bool:
	return BackpackArtifactRendererScript.slot_hover_fx_enabled()

func artifact_fill_alpha() -> float:
	return BackpackArtifactRendererScript.artifact_fill_alpha()

func ghost_cell_size_for_slot(slot_size: Vector2) -> Vector2:
	return BackpackArtifactRendererScript.ghost_cell_size_for_slot(slot_size)

func ghost_global_position_for_cursor(cursor_global_pos: Vector2, _shape: Array, _slot_size: Vector2) -> Vector2:
	return BackpackArtifactRendererScript.ghost_global_position_for_cursor(cursor_global_pos, _shape, _slot_size)

# 실행: create one ghost grid cell.
func _ghost_cell(energy_type: String, filled: bool, shape: Array, row: int, column: int, slot_size: Vector2) -> Control:
	return BackpackArtifactRendererScript.ghost_cell(energy_type, filled, shape, row, column, slot_size)

# 실행: clear all artifact overlays.
func _clear_overlays() -> void:
	BackpackArtifactRendererScript.clear_overlays(self)

# 실행: apply artifact overlay to a backpack coordinate.
func _apply_artifact_overlay(column: int, row: int, art: ArtifactClass, shape: Array, shape_row: int, shape_column: int) -> void:
	BackpackArtifactRendererScript.apply_artifact_overlay(self, column, row, art, shape, shape_row, shape_column)

func _item_texture_for_artifact(art: ArtifactClass) -> Texture2D:
	return BackpackArtifactRendererScript.item_texture_for_artifact(self, art)

func _clear_artifact_images() -> void:
	BackpackArtifactRendererScript.clear_artifact_images(self)

func _apply_artifact_image_overlay(art: ArtifactClass) -> void:
	BackpackArtifactRendererScript.apply_artifact_image_overlay(self, art)

func _artifact_footprint_rect_in_layer(art: ArtifactClass) -> Rect2:
	return BackpackArtifactRendererScript.artifact_footprint_rect_in_layer(self, art)

func _slot_rect_in_artifact_image_layer(slot: Control) -> Rect2:
	return BackpackArtifactRendererScript.slot_rect_in_artifact_image_layer(self, slot)

func control_rect_in_layer_space(control_transform: Transform2D, layer_transform: Transform2D, control_size: Vector2) -> Rect2:
	return BackpackArtifactRendererScript.control_rect_in_layer_space(control_transform, layer_transform, control_size)

func _queue_artifact_image_refresh() -> void:
	BackpackArtifactRendererScript.queue_artifact_image_refresh(self)

func queue_artifact_image_refresh() -> void:
	_queue_artifact_image_refresh()

func _run_queued_artifact_image_refresh() -> void:
	BackpackArtifactRendererScript.run_queued_artifact_image_refresh(self)

# 실행: return overlay panel for an 8x8 backpack coordinate.
func _slot_overlay(column: int, row: int) -> Panel:
	return BackpackArtifactRendererScript.slot_overlay(self, column, row)

# 실행: return cooldown charge overlay panel for an 8x8 backpack coordinate.
func _slot_charge_overlay(column: int, row: int) -> Panel:
	return BackpackArtifactRendererScript.slot_charge_overlay(self, column, row)

func _slot_drop_cue(column: int, row: int) -> Panel:
	return BackpackArtifactRendererScript.slot_drop_cue(self, column, row)

# 실행: drain visible cooldown masks every frame between backend snapshots.
func _slot_influence_overlay(column: int, row: int) -> Panel:
	return BackpackArtifactRendererScript.slot_influence_overlay(self, column, row)

func _update_charge_animation(delta: float) -> void:
	BackpackArtifactRendererScript.update_charge_animation(self, delta)

# 실행: apply top-down anchors for a shrinking translucent cooldown mask.
func _apply_cooldown_mask(charge: Panel, ratio: float) -> void:
	BackpackArtifactRendererScript.apply_cooldown_mask(charge, ratio)

func _layout_pin_overlays() -> void:
	BackpackPinOverlayRuntimeScript.layout(self)

func pin_grid_cell_rect_local(column: int, row: int) -> Rect2:
	return BackpackPinOverlayRuntimeScript.grid_cell_rect_local(self, column, row)

func _queue_pin_layout() -> void:
	BackpackPinOverlayRuntimeScript.queue_layout(self)

func _prime_pin_layout_settle() -> void:
	BackpackPinOverlayRuntimeScript.prime_layout_settle(self)

func _run_queued_pin_layout() -> void:
	await BackpackPinOverlayRuntimeScript.run_queued_pin_layout(self)

func _pins_need_live_layout_retry() -> bool:
	return BackpackPinOverlayRuntimeScript.pins_need_live_layout_retry(self)

func pin_corner_anchor_for_rect(layout_rect: Rect2, spec: Dictionary) -> Vector2:
	return BackpackPinOverlayRuntimeScript.corner_anchor_for_rect(layout_rect, spec)

func pin_position_for_anchor(anchor: Vector2, pin_size: Vector2, spec: Dictionary, grid_overlap: float) -> Vector2:
	return BackpackPinOverlayRuntimeScript.position_for_anchor(anchor, pin_size, spec, grid_overlap)

func _reset_pin_visual(pin: TextureRect) -> void:
	BackpackPinOverlayRuntimeScript.reset_pin_visual(pin)

func _reset_pin_vfx_state() -> void:
	BackpackPinOverlayRuntimeScript.reset_vfx_state(self)

func _play_pin_removed_vfx(index: int) -> void:
	BackpackPinOverlayRuntimeScript.play_removed_vfx(self, index)

func _slot_panel(column: int, row: int) -> Panel:
	return BackpackArtifactRendererScript.slot_panel(self, column, row)

func _grid_cell(column: int, row: int) -> Control:
	return BackpackArtifactRendererScript.grid_cell(self, column, row)

func _ghost_slot_size() -> Vector2:
	return BackpackArtifactRendererScript.ghost_slot_size(self)

func _ghost_footprint(shape: Array, slot_size: Vector2) -> Vector2:
	return BackpackArtifactRendererScript.ghost_footprint(shape, slot_size)
