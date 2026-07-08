# 怨꾩빟:
# - 梨낆엫: artifact codex book safe-area metrics and viewport fit math.
# - ?낅젰: native book texture rectangle and current viewport size.
# - 異쒕젰: page safe-area dimensions, grid/card metrics, and centered book transform.
# - 湲덉?: UI node construction, reward-table reads, and codex selection state mutation.
#
# ?ㅽ뻾: expose deterministic layout policy functions for the artifact codex panel.
class_name ArtifactCodexLayoutPolicy
extends RefCounted

const BOOK_PIXEL_SIZE := Vector2(1464.0, 1074.0)

static func book_layout_metrics_for_rect(book_rect: Rect2) -> Dictionary:
	var outer_left := book_rect.size.x * 0.072
	var outer_right := book_rect.size.x * 0.072
	var outer_top := book_rect.size.y * 0.105
	var outer_bottom := book_rect.size.y * 0.095
	var gutter := book_rect.size.x * 0.045
	var safe_width := maxf(0.0, book_rect.size.x - outer_left - outer_right)
	var safe_height := maxf(0.0, book_rect.size.y - outer_top - outer_bottom)
	var page_width := maxf(0.0, (safe_width - gutter) / 2.0)
	var page_height := safe_height
	var page_padding_x := page_width * 0.036
	var page_padding_y := page_height * 0.030
	var header_height := book_rect.size.y * 0.056
	var tabs_height := page_height * 0.046
	var summary_height := page_height * 0.040
	var page_gap := page_height * 0.014
	var grid_gap := minf(24.0, page_width * 0.040)
	var grid_columns := 3
	var card_width := maxf(84.0, (page_width - page_padding_x * 2.0 - grid_gap * float(grid_columns - 1)) / float(grid_columns))
	var card_height := maxf(116.0, card_width * 1.18)
	return {
		"outerLeft": outer_left,
		"outerRight": outer_right,
		"outerTop": outer_top,
		"outerBottom": outer_bottom,
		"gutter": gutter,
		"safeWidth": safe_width,
		"safeHeight": safe_height,
		"pageWidth": page_width,
		"pageHeight": page_height,
		"pagePaddingX": page_padding_x,
		"pagePaddingY": page_padding_y,
		"headerHeight": header_height,
		"tabsHeight": tabs_height,
		"summaryHeight": summary_height,
		"pageGap": page_gap,
		"gridGap": grid_gap,
		"gridColumns": grid_columns,
		"cardWidth": card_width,
		"cardHeight": card_height,
		"heroHeight": page_height * 0.380
	}

static func book_transform_for_viewport(view_size: Vector2) -> Dictionary:
	var margin := Vector2(view_size.x * 0.032, view_size.y * 0.052)
	var available := Vector2(
		maxf(240.0, view_size.x - margin.x * 2.0),
		maxf(180.0, view_size.y - margin.y * 2.0)
	)
	var scale := minf(available.x / BOOK_PIXEL_SIZE.x, available.y / BOOK_PIXEL_SIZE.y)
	var fitted_size := BOOK_PIXEL_SIZE * scale
	var fitted_position := Vector2(
		(view_size.x - fitted_size.x) * 0.5,
		(view_size.y - fitted_size.y) * 0.5
	)
	return {"position": fitted_position, "scale": scale, "size": fitted_size}
