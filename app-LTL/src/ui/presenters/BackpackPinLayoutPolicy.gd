class_name BackpackPinLayoutPolicy
extends RefCounted

const GRID_COLUMNS := 10.0
const GRID_SEPARATION := 2.0
const DISPLAY_SLOT_RATIO := 863.0 / 655.0
const DISPLAY_HEIGHT_SLOT_RATIO := 1.0
const GRID_OVERLAP_RATIO := 0.35
const MIN_TOP_CONTENT_GRID_EXTENT := 420.0
const NODE_SELECT_ROW_GAP := 20.0
const NODE_SELECT_BACKPACK_MIN_WIDTH := 480.0
const NODE_SELECT_BACKPACK_MAX_WIDTH := 860.0

static func slot_extent_for_grid_extent(grid_extent: float) -> float:
	var safe_extent := maxf(0.0, grid_extent)
	if safe_extent <= 0.0:
		return 0.0
	var total_separator := GRID_SEPARATION * maxf(0.0, GRID_COLUMNS - 1.0)
	return maxf(0.0, (safe_extent - total_separator) / GRID_COLUMNS)

static func display_extent_for_slot_extent(slot_extent: float) -> float:
	return maxf(0.0, slot_extent) * DISPLAY_SLOT_RATIO

static func display_size_for_slot_extent(slot_extent: float) -> Vector2:
	var safe_slot_extent := maxf(0.0, slot_extent)
	return Vector2(
		display_extent_for_slot_extent(safe_slot_extent),
		safe_slot_extent * DISPLAY_HEIGHT_SLOT_RATIO
	)

static func slot_extent_for_cell_rect(layout_rect: Rect2) -> float:
	return minf(maxf(0.0, layout_rect.size.x), maxf(0.0, layout_rect.size.y))

static func grid_overlap_for_slot_extent(slot_extent: float) -> float:
	return display_extent_for_slot_extent(slot_extent) * GRID_OVERLAP_RATIO

static func side_outset_for_slot_extent(slot_extent: float) -> float:
	return display_extent_for_slot_extent(slot_extent) - grid_overlap_for_slot_extent(slot_extent)

static func display_extent_for_grid_extent(grid_extent: float) -> float:
	return display_extent_for_slot_extent(slot_extent_for_grid_extent(grid_extent))

static func side_outset_for_grid_extent(grid_extent: float) -> float:
	return side_outset_for_slot_extent(slot_extent_for_grid_extent(grid_extent))

static func extra_width_for_grid_extent(grid_extent: float) -> float:
	return side_outset_for_grid_extent(grid_extent) * 2.0

static func node_select_width_for_row(row_size: Vector2, map_min_width: float) -> float:
	var target_height := maxf(0.0, row_size.y)
	var available_width := NODE_SELECT_BACKPACK_MAX_WIDTH
	if row_size.x > 1.0:
		available_width = maxf(0.0, row_size.x - map_min_width - NODE_SELECT_ROW_GAP)
	var upper_bound := minf(NODE_SELECT_BACKPACK_MAX_WIDTH, available_width)
	var lower_bound := minf(NODE_SELECT_BACKPACK_MIN_WIDTH, upper_bound)
	if upper_bound <= 0.0:
		return 0.0
	return clampf(target_height, lower_bound, upper_bound)

static func resolved_top_content_height(row_height: float, min_row_height: float) -> float:
	if row_height > 0.0:
		return row_height
	return maxf(0.0, min_row_height)

static func top_content_grid_extent_for_height(target_height: float) -> float:
	return maxf(maxf(0.0, target_height), MIN_TOP_CONTENT_GRID_EXTENT)

static func top_content_slot_extent_for_height(target_height: float) -> float:
	return slot_extent_for_grid_extent(top_content_grid_extent_for_height(target_height))

static func top_content_side_outset_for_height(target_height: float) -> float:
	return side_outset_for_grid_extent(top_content_grid_extent_for_height(target_height))

static func top_content_width_for_height(target_height: float) -> float:
	var safe_height := maxf(0.0, target_height)
	if safe_height <= 0.0:
		return 0.0
	var grid_extent := top_content_grid_extent_for_height(safe_height)
	return grid_extent + extra_width_for_grid_extent(grid_extent)

static func top_content_ratio_for_height(target_height: float) -> float:
	var safe_height := maxf(0.0, target_height)
	if safe_height <= 0.0:
		return 1.0
	var grid_extent := top_content_grid_extent_for_height(safe_height)
	return top_content_width_for_height(grid_extent) / grid_extent
