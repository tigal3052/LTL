# 怨꾩빟:
# - 梨낆엫: backpack artifact overlays, drill image overlays, drag ghost geometry, and cooldown masks.
# - ?낅젰: BackpackUI owner nodes, InventoryModel artifact data, and held artifact shape data.
# - 異쒕젰: slot overlay styles, image-backed drill TextureRects, ghost cells, and cooldown mask anchors.
# - 湲덉?: combat pin state, controller inventory mutation, and reward tray ownership.
#
# ?ㅽ뻾: keep backpack item rendering and drag affordance helpers outside the BackpackUI owner.
class_name BackpackArtifactRenderer
extends RefCounted

const ArtifactClass = preload("res://src/models/Artifact.gd")
const GridFactory = preload("res://src/ui/presenters/BackpackGridFactory.gd")
const BackpackInfluenceHighlighterScript = preload("res://src/ui/backpack/BackpackInfluenceHighlighter.gd")
const BackpackArtifactImagePlacementScript = preload("res://src/ui/backpack/BackpackArtifactImagePlacement.gd")
const VISUAL_COOLDOWN_TICKS_PER_SECOND := 20.0
const SLOT_HOVER_FX_ENABLED := false
const SLOT_GRID_SEPARATION := 2
const ARTIFACT_FILL_ALPHA := 0.32
const GHOST_FALLBACK_CELL_SIZE := Vector2(24, 24)
const ARTIFACT_IMAGE_REFRESH_RETRY_FRAMES := 8

static func render_items(owner, inventory) -> void:
	owner.current_inventory = inventory
	clear_overlays(owner)
	clear_artifact_images(owner)
	if inventory == null:
		owner.artifact_image_layout_signature_initialized = false
		return
	for art_id in inventory.artifacts:
		var art = inventory.artifacts[art_id]
		for row in range(art.shape.size()):
			for column in range(art.shape[row].size()):
				if int(art.shape[row][column]) == 1:
					apply_artifact_overlay(owner, int(art.x) + column, int(art.y) + row, art, art.shape, row, column)
		apply_artifact_image_overlay(owner, art)
	BackpackInfluenceHighlighterScript.refresh(owner, inventory)
	owner.artifact_image_layout_signature = artifact_image_layout_signature(owner)
	owner.artifact_image_layout_signature_initialized = true

static func can_drop_artifact(inventory, artifact, column: int, row: int) -> bool:
	if inventory == null or artifact == null:
		return true
	if not inventory.has_method("can_place_artifact"):
		return true
	return inventory.can_place_artifact(artifact, column, row)

static func drop_feedback_cells_for(artifact, column: int, row: int) -> Array:
	if artifact == null or column < 0 or row < 0:
		return []
	var cells: Array = []
	var shape: Array = artifact.shape
	for shape_row in range(shape.size()):
		if not shape[shape_row] is Array:
			continue
		for shape_column in range(shape[shape_row].size()):
			if int(shape[shape_row][shape_column]) == 1:
				cells.append(Vector2(column + shape_column, row + shape_row))
	return cells

static func slot_hover_fx_enabled() -> bool:
	return SLOT_HOVER_FX_ENABLED

static func artifact_fill_alpha() -> float:
	return ARTIFACT_FILL_ALPHA

static func ghost_cell_size_for_slot(slot_size: Vector2) -> Vector2:
	if slot_size.x > 0.0 and slot_size.y > 0.0:
		return slot_size
	return GHOST_FALLBACK_CELL_SIZE

static func ghost_global_position_for_cursor(cursor_global_pos: Vector2, _shape: Array, _slot_size: Vector2) -> Vector2:
	return cursor_global_pos

static func ghost_cell(energy_type: String, filled: bool, shape: Array, row: int, column: int, slot_size: Vector2) -> Control:
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

static func clear_overlays(owner) -> void:
	BackpackInfluenceHighlighterScript.clear(owner)
	for row in range(8):
		for column in range(8):
			var overlay := slot_overlay(owner, column, row)
			if overlay:
				overlay.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			var drop_cue := slot_drop_cue(owner, column, row)
			if drop_cue:
				drop_cue.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			var charge := slot_charge_overlay(owner, column, row)
			if charge:
				charge.visible = false
				charge.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	owner._prime_pin_layout_settle()

static func apply_artifact_overlay(owner, column: int, row: int, art: ArtifactClass, shape: Array, shape_row: int, shape_column: int) -> void:
	var overlay := slot_overlay(owner, column, row)
	if overlay:
		var image_backed := item_texture_for_artifact(owner, art) != null
		if image_backed:
			overlay.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		else:
			overlay.add_theme_stylebox_override("panel", GridFactory.artifact_style(str(art.energy_type), artifact_fill_alpha(), GridFactory.artifact_edge_mask(shape, shape_row, shape_column)))
	var charge := slot_charge_overlay(owner, column, row)
	if charge:
		if not owner.cooldown_visuals_enabled:
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
		apply_cooldown_mask(charge, display_ticks / float(effective_cooldown))

static func item_texture_for_artifact(owner, art: ArtifactClass) -> Texture2D:
	return BackpackArtifactImagePlacementScript.display_texture_for_artifact(owner, art)

static func oriented_display_texture(texture: Texture2D, shape: Array = [], rotation_degrees: int = 0) -> Texture2D:
	var rotated := _rotated_texture(texture, rotation_degrees)
	return drill_display_texture(rotated, shape)

static func drill_texture_for_artifact(owner, art: ArtifactClass) -> Texture2D:
	if art == null or str(art.item_type).to_lower() != "drill":
		return null
	return item_texture_for_artifact(owner, art)

static func drill_display_texture(texture: Texture2D, shape: Array = []) -> Texture2D:
	return BackpackArtifactImagePlacementScript.drill_display_texture(texture, shape)

static func _rotated_texture(texture: Texture2D, rotation_degrees: int) -> Texture2D:
	if texture == null:
		return null
	var rotation := _normalized_rotation(rotation_degrees)
	if rotation == 0:
		return texture
	var source := texture.get_image()
	if source == null or source.is_empty():
		return texture
	source = source.duplicate()
	source.convert(Image.FORMAT_RGBA8)
	var source_width := source.get_width()
	var source_height := source.get_height()
	var output_size := Vector2i(source_height, source_width) if rotation in [90, 270] else Vector2i(source_width, source_height)
	var output := Image.create(output_size.x, output_size.y, false, Image.FORMAT_RGBA8)
	for y in range(source_height):
		for x in range(source_width):
			var target := _rotated_pixel_position(x, y, source_width, source_height, rotation)
			output.set_pixel(target.x, target.y, source.get_pixel(x, y))
	return ImageTexture.create_from_image(output)

static func _rotated_pixel_position(x: int, y: int, width: int, height: int, rotation: int) -> Vector2i:
	match rotation:
		90:
			return Vector2i(height - 1 - y, x)
		180:
			return Vector2i(width - 1 - x, height - 1 - y)
		270:
			return Vector2i(y, width - 1 - x)
	return Vector2i(x, y)

static func _normalized_rotation(rotation_degrees: int) -> int:
	var rotation := rotation_degrees % 360
	if rotation < 0:
		rotation += 360
	return int(round(float(rotation) / 90.0)) * 90 % 360

static func _visible_alpha_region(image: Image, alpha_threshold: float) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a <= alpha_threshold:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

static func clear_artifact_images(owner) -> void:
	if owner.artifact_image_layer == null:
		return
	for child in owner.artifact_image_layer.get_children():
		owner.artifact_image_layer.remove_child(child)
		child.queue_free()

static func apply_artifact_image_overlay(owner, art: ArtifactClass) -> void:
	var texture := item_texture_for_artifact(owner, art)
	if texture == null or owner.artifact_image_layer == null:
		return
	var rect := artifact_footprint_rect_in_layer(owner, art)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var image := TextureRect.new()
	image.name = artifact_image_node_name(art)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	apply_oriented_item_image_placement(image, texture, rect, int(art.rotation))
	owner.artifact_image_layer.add_child(image)

static func artifact_image_node_name(art: ArtifactClass) -> String:
	var prefix := "DrillImage" if art != null and str(art.item_type).to_lower() == "drill" else "ItemImage"
	return "%s_%s" % [prefix, str(art.id) if art != null else "unknown"]

static func apply_item_image_placement(image: TextureRect, texture: Texture2D, footprint_rect: Rect2, use_global_position: bool = false) -> void:
	BackpackArtifactImagePlacementScript.apply_item_image_placement(image, texture, footprint_rect, use_global_position)

static func apply_oriented_item_image_placement(image: TextureRect, texture: Texture2D, footprint_rect: Rect2, rotation_degrees: int, use_global_position: bool = false) -> void:
	BackpackArtifactImagePlacementScript.apply_oriented_item_image_placement(image, texture, footprint_rect, rotation_degrees, use_global_position)

static func reset_item_image_transform(image: TextureRect) -> void:
	BackpackArtifactImagePlacementScript.reset_item_image_transform(image)

static func artifact_footprint_rect_in_layer(owner, art: ArtifactClass) -> Rect2:
	var rect := Rect2()
	var initialized := false
	var shape: Array = art.shape
	for shape_row in range(shape.size()):
		if not shape[shape_row] is Array:
			continue
		for shape_column in range(shape[shape_row].size()):
			if int(shape[shape_row][shape_column]) != 1:
				continue
			var slot := slot_panel(owner, int(art.x) + shape_column, int(art.y) + shape_row)
			if slot == null:
				continue
			var slot_rect := slot_rect_in_artifact_image_layer(owner, slot)
			if not initialized:
				rect = slot_rect
				initialized = true
			else:
				rect = rect.merge(slot_rect)
	return rect if initialized else Rect2()

static func slot_rect_in_artifact_image_layer(owner, slot: Control) -> Rect2:
	var layer_item: CanvasItem = owner.artifact_image_layer if owner.artifact_image_layer != null else owner
	return control_rect_in_layer_space(slot.get_global_transform_with_canvas(), layer_item.get_global_transform_with_canvas(), slot.size)

static func control_rect_in_layer_space(control_transform: Transform2D, layer_transform: Transform2D, control_size: Vector2) -> Rect2:
	var to_layer := layer_transform.affine_inverse() * control_transform
	var points := [
		to_layer * Vector2.ZERO,
		to_layer * Vector2(control_size.x, 0.0),
		to_layer * Vector2(0.0, control_size.y),
		to_layer * control_size
	]
	var min_point: Vector2 = points[0]
	var max_point: Vector2 = points[0]
	for point in points:
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	return Rect2(min_point, max_point - min_point)

static func artifact_image_layout_signature(owner) -> Rect2:
	if owner == null or owner.backpack_grid_mock == null or owner.artifact_image_layer == null:
		return Rect2()
	var signature := control_rect_in_layer_space(owner.backpack_grid_mock.get_global_transform_with_canvas(), owner.artifact_image_layer.get_global_transform_with_canvas(), owner.backpack_grid_mock.size)
	var first_slot := slot_panel(owner, 0, 0)
	var last_slot := slot_panel(owner, 7, 7)
	if first_slot != null:
		signature = signature.merge(slot_rect_in_artifact_image_layer(owner, first_slot))
	if last_slot != null:
		signature = signature.merge(slot_rect_in_artifact_image_layer(owner, last_slot))
	return signature

static func refresh_artifact_images_if_layout_changed(owner) -> void:
	if owner == null or owner.current_inventory == null or owner.artifact_image_layer == null or owner.backpack_grid_mock == null:
		return
	var signature := artifact_image_layout_signature(owner)
	if not owner.artifact_image_layout_signature_initialized:
		owner.artifact_image_layout_signature = signature
		owner.artifact_image_layout_signature_initialized = true
		return
	if _rect_close(signature, owner.artifact_image_layout_signature, 0.5):
		return
	owner.render_backpack_items(owner.current_inventory)

static func _rect_close(a: Rect2, b: Rect2, tolerance: float) -> bool:
	return a.position.distance_to(b.position) <= tolerance and a.size.distance_to(b.size) <= tolerance

static func queue_artifact_image_refresh(owner) -> void:
	owner.artifact_image_refresh_retry_budget = maxi(owner.artifact_image_refresh_retry_budget, ARTIFACT_IMAGE_REFRESH_RETRY_FRAMES)
	if owner.artifact_image_refresh_queued:
		return
	owner.artifact_image_refresh_queued = true
	owner.call_deferred("_run_queued_artifact_image_refresh")

static func run_queued_artifact_image_refresh(owner) -> void:
	owner.artifact_image_refresh_queued = false
	if owner.current_inventory != null:
		owner.render_backpack_items(owner.current_inventory)
	if owner.artifact_image_refresh_retry_budget <= 0:
		return
	owner.artifact_image_refresh_retry_budget -= 1
	owner.artifact_image_refresh_queued = true
	owner.call_deferred("_run_queued_artifact_image_refresh")

static func slot_overlay(owner, column: int, row: int) -> Panel:
	if column < 0 or column >= 8 or row < 0 or row >= 8:
		return null
	var slot_idx := (row + 1) * 10 + (column + 1)
	if slot_idx >= owner.backpack_grid_mock.get_child_count():
		return null
	var slot := owner.backpack_grid_mock.get_child(slot_idx) as Panel
	return null if slot == null else slot.get_node("Overlay") as Panel

static func slot_charge_overlay(owner, column: int, row: int) -> Panel:
	if column < 0 or column >= 8 or row < 0 or row >= 8:
		return null
	var slot_idx := (row + 1) * 10 + (column + 1)
	if slot_idx >= owner.backpack_grid_mock.get_child_count():
		return null
	var slot := owner.backpack_grid_mock.get_child(slot_idx) as Panel
	return null if slot == null else slot.get_node("ChargeOverlay") as Panel

static func slot_drop_cue(owner, column: int, row: int) -> Panel:
	if column < 0 or column >= 8 or row < 0 or row >= 8:
		return null
	var slot_idx := (row + 1) * 10 + (column + 1)
	if slot_idx >= owner.backpack_grid_mock.get_child_count():
		return null
	var slot := owner.backpack_grid_mock.get_child(slot_idx) as Panel
	if slot == null:
		return null
	return slot.get_node_or_null("DropCueOverlay") as Panel

static func slot_influence_overlay(owner, column: int, row: int) -> Panel:
	return BackpackInfluenceHighlighterScript.slot_influence_overlay(owner, column, row)

static func refresh_influence_overlays(owner, inventory) -> void:
	BackpackInfluenceHighlighterScript.refresh(owner, inventory)

static func apply_ghost_influence_overlays(owner, artifact, column: int, row: int, inventory = null) -> void:
	BackpackInfluenceHighlighterScript.refresh(owner, inventory, artifact, column, row)

static func influence_feedback_cells_for(artifact, column: int, row: int, width: int = 8, height: int = 8) -> Array:
	return BackpackInfluenceHighlighterScript.influence_cells_for(artifact, column, row, width, height)

static func update_charge_animation(owner, delta: float) -> void:
	for row in range(8):
		for column in range(8):
			var charge := slot_charge_overlay(owner, column, row)
			if charge == null or not charge.visible or not charge.has_meta("display_cooldown_ticks"):
				continue
			var next := GridFactory.advance_visual_cooldown(float(charge.get_meta("display_cooldown_ticks")), delta, VISUAL_COOLDOWN_TICKS_PER_SECOND)
			var effective := float(charge.get_meta("effective_cooldown_ticks", 1.0))
			charge.set_meta("display_cooldown_ticks", next)
			apply_cooldown_mask(charge, next / maxf(1.0, effective))

static func apply_cooldown_mask(charge: Panel, ratio: float) -> void:
	var remaining := clampf(ratio, 0.0, 1.0)
	charge.anchor_left = 0.0
	charge.anchor_right = 1.0
	charge.anchor_top = 0.0
	charge.anchor_bottom = remaining
	charge.offset_left = 0.0
	charge.offset_right = 0.0
	charge.offset_top = 0.0
	charge.offset_bottom = 0.0

static func slot_panel(owner, column: int, row: int) -> Panel:
	if column < 0 or column >= 8 or row < 0 or row >= 8:
		return null
	var slot_idx := (row + 1) * 10 + (column + 1)
	if slot_idx >= owner.backpack_grid_mock.get_child_count():
		return null
	return owner.backpack_grid_mock.get_child(slot_idx) as Panel

static func grid_cell(owner, column: int, row: int) -> Control:
	if owner.backpack_grid_mock == null:
		return null
	if column < 0 or column >= 10 or row < 0 or row >= 10:
		return null
	var cell_idx := row * 10 + column
	if cell_idx < 0 or cell_idx >= owner.backpack_grid_mock.get_child_count():
		return null
	return owner.backpack_grid_mock.get_child(cell_idx) as Control

static func ghost_slot_size(owner) -> Vector2:
	var slot := slot_panel(owner, 0, 0)
	if slot != null:
		var live_size := slot.size
		if live_size.x > 0.0 and live_size.y > 0.0:
			return ghost_cell_size_for_slot(live_size)
		var min_size := slot.get_combined_minimum_size()
		if min_size.x > 0.0 and min_size.y > 0.0:
			return ghost_cell_size_for_slot(min_size)
	return GHOST_FALLBACK_CELL_SIZE

static func ghost_footprint(shape: Array, slot_size: Vector2) -> Vector2:
	var rows: int = shape.size()
	var cols: int = shape[0].size() if rows > 0 else 0
	var draw_size := ghost_cell_size_for_slot(slot_size)
	if rows <= 0 or cols <= 0:
		return draw_size
	return Vector2(
		float(cols) * draw_size.x + float(maxi(0, cols - 1)) * SLOT_GRID_SEPARATION,
		float(rows) * draw_size.y + float(maxi(0, rows - 1)) * SLOT_GRID_SEPARATION
	)
