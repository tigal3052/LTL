# Contract:
# - Responsibility: project beacon/relic influence cells into backpack slot highlight overlays.
# - Input: BackpackUI owner, optional inventory, and optional held artifact preview origin.
# - Output: Yellow slot backgrounds only; no inventory or artifact state mutation.
# - Forbidden: placement validation changes, cooldown/damage/effect mutation, scene ownership changes.
class_name BackpackInfluenceHighlighter
extends RefCounted

const GridFactory = preload("res://src/ui/presenters/BackpackGridFactory.gd")
const DEFAULT_GRID_SIZE := Vector2i(8, 8)
const INFLUENCE_OVERLAY_NAME := "InfluenceOverlay"

static func refresh(owner, inventory, ghost_artifact = null, ghost_column: int = -1, ghost_row: int = -1) -> void:
	clear(owner)
	var grid_size := _grid_size_for(inventory)
	if _normal_range_visible(owner):
		_apply_placed_ranges(owner, inventory, grid_size)
	if ghost_artifact != null and ghost_column >= 0 and ghost_row >= 0:
		for cell in influence_cells_for(ghost_artifact, ghost_column, ghost_row, grid_size.x, grid_size.y):
			_apply_cell(owner, int((cell as Vector2).x), int((cell as Vector2).y))

static func clear(owner) -> void:
	for row in range(DEFAULT_GRID_SIZE.y):
		for column in range(DEFAULT_GRID_SIZE.x):
			var overlay := slot_influence_overlay(owner, column, row)
			if overlay:
				overlay.add_theme_stylebox_override("panel", StyleBoxEmpty.new())

static func influence_cells_for(artifact, column: int, row: int, width: int = 8, height: int = 8) -> Array:
	if artifact == null:
		return []
	var offsets := _offsets_for(artifact)
	if offsets.is_empty():
		return []
	var occupied := _occupied_cells_for(artifact, column, row)
	var occupied_lookup := {}
	for cell in occupied:
		if _in_bounds(cell, width, height):
			occupied_lookup[_cell_key(cell)] = true
	var target_lookup := {}
	var targets: Array = []
	for cell in occupied:
		if not _in_bounds(cell, width, height):
			continue
		for offset in offsets:
			var target := Vector2i(cell.x + offset.x, cell.y + offset.y)
			if not _in_bounds(target, width, height):
				continue
			var target_key := _cell_key(target)
			if occupied_lookup.has(target_key) or target_lookup.has(target_key):
				continue
			target_lookup[target_key] = true
			targets.append(Vector2(target.x, target.y))
	return targets

static func slot_influence_overlay(owner, column: int, row: int) -> Panel:
	if owner == null or owner.backpack_grid_mock == null:
		return null
	if column < 0 or column >= DEFAULT_GRID_SIZE.x or row < 0 or row >= DEFAULT_GRID_SIZE.y:
		return null
	var slot_idx := (row + 1) * 10 + (column + 1)
	if slot_idx >= owner.backpack_grid_mock.get_child_count():
		return null
	var slot := owner.backpack_grid_mock.get_child(slot_idx) as Panel
	return null if slot == null else slot.get_node_or_null(INFLUENCE_OVERLAY_NAME) as Panel

static func _apply_cell(owner, column: int, row: int) -> void:
	var overlay := slot_influence_overlay(owner, column, row)
	if overlay:
		overlay.add_theme_stylebox_override("panel", GridFactory.influence_range_style())

static func _apply_placed_ranges(owner, inventory, grid_size: Vector2i) -> void:
	if inventory == null:
		return
	for artifact_id in inventory.artifacts:
		var artifact = inventory.artifacts[artifact_id]
		if artifact == null:
			continue
		for cell in influence_cells_for(artifact, int(artifact.x), int(artifact.y), grid_size.x, grid_size.y):
			_apply_cell(owner, int((cell as Vector2).x), int((cell as Vector2).y))

static func _offsets_for(artifact) -> Array:
	var item_type := str(artifact.item_type).to_lower()
	if item_type == "beacon":
		return [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	if item_type != "relic":
		return []
	var link_mode := str(artifact.effect_schema.get("link_mode", "")).to_lower()
	if link_mode.is_empty():
		return []
	var diagonal := [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]
	var skip_two := [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]
	if link_mode == "skip_2":
		return skip_two
	if link_mode == "crown_link":
		return diagonal + skip_two
	return diagonal

static func _occupied_cells_for(artifact, column: int, row: int) -> Array:
	var occupied: Array = []
	var shape: Array = artifact.shape
	for shape_row in range(shape.size()):
		if not shape[shape_row] is Array:
			continue
		var row_cells: Array = shape[shape_row]
		for shape_column in range(row_cells.size()):
			if int(row_cells[shape_column]) == 1:
				occupied.append(Vector2i(column + shape_column, row + shape_row))
	return occupied

static func _grid_size_for(inventory) -> Vector2i:
	if inventory == null:
		return DEFAULT_GRID_SIZE
	return Vector2i(maxi(1, int(inventory.width)), maxi(1, int(inventory.height)))

static func _normal_range_visible(owner) -> bool:
	if owner != null and owner.has_method("get_influence_preview_enabled"):
		return bool(owner.call("get_influence_preview_enabled"))
	return true

static func _in_bounds(cell: Vector2i, width: int, height: int) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height

static func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]
