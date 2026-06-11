extends RefCounted

const BackpackPinLayoutPolicyScript = preload("res://src/ui/presenters/BackpackPinLayoutPolicy.gd")

static func board_available_width(shell_width: float, horizontal_margin: float, chrome_cushion: float = 10.0) -> float:
	return maxf(320.0, shell_width - horizontal_margin - chrome_cushion)

static func board_layout_targets(scroll_height: float, board_gap: float, bottom_min: float, top_min: float, bottom_ratio: float) -> Dictionary:
	var available_height := maxf(0.0, scroll_height - board_gap)
	if available_height <= 1.0:
		return {
			"topZoneHeight": top_min,
			"bottomRowHeight": bottom_min
		}
	var bottom_target := clampf(scroll_height * bottom_ratio, bottom_min, maxf(bottom_min, scroll_height * 0.28))
	var top_target := available_height - bottom_target
	if top_target < top_min:
		top_target = maxf(top_min, available_height - bottom_min)
		bottom_target = maxf(bottom_min, available_height - top_target)
	if top_target + bottom_target > available_height:
		bottom_target = maxf(bottom_min, available_height - top_target)
	if bottom_target < bottom_min:
		bottom_target = bottom_min
		top_target = maxf(220.0, available_height - bottom_target)
	return {
		"topZoneHeight": maxf(220.0, top_target),
		"bottomRowHeight": maxf(bottom_min, bottom_target)
	}

static func zone_body_target_height(zone_min_height: float, body_min_height: float, target_height: float, fallback_min: float) -> float:
	var chrome_height := maxf(0.0, zone_min_height - body_min_height)
	return maxf(fallback_min, target_height - chrome_height)

static func backpack_panel_dimensions_for_host(host_size: Vector2, margin_width: float, chrome_height: float, visible_height_cap: float) -> Vector2:
	var low := 120.0
	var high := maxf(120.0, minf(host_size.x, host_size.y))
	for _step in range(20):
		var mid := (low + high) * 0.5
		var candidate := backpack_panel_dimensions_for_grid_extent(mid, margin_width, chrome_height)
		if candidate.x <= host_size.x and candidate.y <= host_size.y:
			low = mid
		else:
			high = mid
	var panel_dims := backpack_panel_dimensions_for_grid_extent(low, margin_width, chrome_height)
	if visible_height_cap > 0.0 and panel_dims.y > visible_height_cap:
		var scale := visible_height_cap / panel_dims.y
		panel_dims *= scale
	return panel_dims

static func backpack_panel_dimensions_for_grid_extent(grid_extent: float, margin_width: float, chrome_height: float) -> Vector2:
	return Vector2(
		grid_extent + BackpackPinLayoutPolicyScript.extra_width_for_grid_extent(grid_extent) + margin_width,
		grid_extent + chrome_height
	)
