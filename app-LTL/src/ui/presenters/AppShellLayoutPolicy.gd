class_name AppShellLayoutPolicy
extends RefCounted

static func viewport_safe_size(viewport_size: Vector2, horizontal_margin: float, vertical_margin: float) -> Vector2:
	return Vector2(
		maxf(0.0, viewport_size.x - maxf(0.0, horizontal_margin)),
		maxf(0.0, viewport_size.y - maxf(0.0, vertical_margin))
	)

static func active_phase_visible(battlefield_visible: bool, reward_visible: bool, page_shell_visible: bool) -> bool:
	return battlefield_visible or reward_visible or page_shell_visible

static func visible_section_count(header_visible: bool, top_content_visible: bool, active_phase_is_visible: bool, action_bar_visible: bool) -> int:
	var count := 0
	if header_visible:
		count += 1
	if top_content_visible:
		count += 1
	if active_phase_is_visible:
		count += 1
	if action_bar_visible:
		count += 1
	return count

static func max_safe_active_phase_height(shell_size: Vector2, section_gap: float, header_height: float, top_content_height: float, active_phase_is_visible: bool, action_bar_height: float) -> float:
	var visible_sections := 0
	var reserved_height := 0.0
	if header_height > 0.0:
		reserved_height += header_height
		visible_sections += 1
	if top_content_height > 0.0:
		reserved_height += top_content_height
		visible_sections += 1
	if active_phase_is_visible:
		visible_sections += 1
	if action_bar_height > 0.0:
		reserved_height += action_bar_height
		visible_sections += 1
	var gap_budget := maxf(0.0, section_gap) * maxf(0.0, float(visible_sections - 1))
	return maxf(0.0, shell_size.y - reserved_height - gap_budget)

static func max_safe_top_content_height(shell_size: Vector2, section_gap: float, header_visible: bool, header_height: float, active_phase_is_visible: bool, active_phase_min_height: float, action_bar_visible: bool, action_bar_height: float, top_content_visible: bool) -> float:
	if not top_content_visible:
		return 0.0
	var visible_sections := visible_section_count(header_visible, top_content_visible, active_phase_is_visible, action_bar_visible)
	var reserved_height := 0.0
	if header_visible:
		reserved_height += maxf(0.0, header_height)
	if action_bar_visible:
		reserved_height += maxf(0.0, action_bar_height)
	if active_phase_is_visible:
		reserved_height += maxf(0.0, active_phase_min_height)
	var gap_budget := maxf(0.0, section_gap) * maxf(0.0, float(visible_sections - 1))
	return maxf(0.0, shell_size.y - reserved_height - gap_budget)

static func max_safe_backpack_width(shell_width: float, row_gap: float, left_min: float, right_min: float) -> float:
	return maxf(0.0, shell_width - maxf(0.0, left_min) - maxf(0.0, right_min) - maxf(0.0, row_gap) * 2.0)

static func reward_backpack_panel_visible_height_cap(panel_height: float, outer_margin: float, reward_box_gap: float, reward_board_gap: float, head_height: float, bottom_row_height: float) -> float:
	return maxf(
		220.0,
		maxf(0.0, panel_height) - maxf(0.0, outer_margin) - maxf(0.0, reward_box_gap) - maxf(0.0, reward_board_gap) - maxf(0.0, head_height) - maxf(0.0, bottom_row_height) - 18.0
	)
