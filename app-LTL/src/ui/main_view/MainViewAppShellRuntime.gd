class_name MainViewAppShellRuntime
extends RefCounted

const AppShellLayoutPolicyScript = preload("res://src/ui/presenters/AppShellLayoutPolicy.gd")
const BackpackPinLayoutPolicyScript = preload("res://src/ui/presenters/BackpackPinLayoutPolicy.gd")
const SharedBackpackHostCoordinatorScript = preload("res://src/ui/SharedBackpackHostCoordinator.gd")

const VIEWPORT_SAFE_GUTTER := 16.0

# 전투 리디자인: 배틀 CTA 기둥은 top_content 내부로 이동했으므로 앱 셸 세로 예산에서 제외한다.
static func action_bar_in_shell_flow(view) -> bool:
	if view.action_bar == null or not view.action_bar.visible:
		return false
	return view.top_content == null or not view.top_content.is_ancestor_of(view.action_bar)

static func max_safe_active_phase_height(view) -> float:
	var shell_size: Vector2 = viewport_safe_app_shell_size(view)
	var section_gap: float = float(view.app_shell.get_theme_constant("separation")) if view.app_shell != null else 0.0
	var header_height: float = float(view.header_panel.get_combined_minimum_size().y) if view.header_panel != null and view.header_panel.visible else 0.0
	var top_content_height: float = float(view.top_content.get_combined_minimum_size().y) if view.top_content != null and view.top_content.visible else 0.0
	var action_bar_height: float = float(view.action_bar.get_combined_minimum_size().y) if action_bar_in_shell_flow(view) else 0.0
	return AppShellLayoutPolicyScript.max_safe_active_phase_height(shell_size, section_gap, header_height, top_content_height, active_phase_surface_visible(view), action_bar_height)

static func top_content_backpack_height(view) -> float:
	if view.top_content == null:
		return BackpackPinLayoutPolicyScript.MIN_TOP_CONTENT_GRID_EXTENT
	var min_row_height: float = maxf(float(view.top_content.get_combined_minimum_size().y), BackpackPinLayoutPolicyScript.MIN_TOP_CONTENT_GRID_EXTENT)
	var safe_height: float = max_safe_top_content_height(view)
	return BackpackPinLayoutPolicyScript.bounded_top_content_height(view.top_content.size.y, min_row_height, safe_height)

static func top_content_backpack_width(view) -> float:
	return BackpackPinLayoutPolicyScript.top_content_width_for_height(top_content_backpack_height(view))

static func apply_top_content_backpack_bounds(view) -> void:
	if view.top_content == null or view.backpack_container == null:
		return
	# 보드 패널(제목 행 + 마진)이 top-content 행 높이에서 차지하는 크롬을 제외한 나머지가 백팩 높이 예산.
	var board_chrome_y: float = board_panel_vertical_chrome(view)
	var target_height: float = top_content_backpack_height(view)
	var backpack_height: float = maxf(0.0, target_height - board_chrome_y)
	var resolved_width: float = BackpackPinLayoutPolicyScript.top_content_width_for_height(backpack_height)
	var safe_width_cap: float = max_safe_top_content_backpack_width(view)
	if safe_width_cap > 0.0 and resolved_width > safe_width_cap:
		backpack_height = minf(backpack_height, BackpackPinLayoutPolicyScript.top_content_height_for_width(safe_width_cap))
		resolved_width = BackpackPinLayoutPolicyScript.top_content_width_for_height(backpack_height)
		if resolved_width > safe_width_cap:
			resolved_width = safe_width_cap
	view.top_content.custom_minimum_size.y = backpack_height + board_chrome_y
	if view.backpack_host != null:
		view.backpack_host.custom_minimum_size = Vector2(resolved_width, 0.0)
		view.backpack_host.ratio = BackpackPinLayoutPolicyScript.top_content_ratio_for_height(backpack_height)
	view.backpack_container.custom_minimum_size = Vector2(resolved_width, 0.0)
	view.backpack_container.ratio = BackpackPinLayoutPolicyScript.top_content_ratio_for_height(backpack_height)

static func viewport_safe_app_shell_size(view) -> Vector2:
	var horizontal_margin := 0.0
	var vertical_margin := 0.0
	if view.root_margin != null:
		horizontal_margin = float(view.root_margin.get_theme_constant("margin_left") + view.root_margin.get_theme_constant("margin_right"))
		vertical_margin = float(view.root_margin.get_theme_constant("margin_top") + view.root_margin.get_theme_constant("margin_bottom"))
	return AppShellLayoutPolicyScript.viewport_safe_size(view.get_viewport_rect().size, horizontal_margin, vertical_margin)

static func app_shell_visible_section_count(view) -> int:
	return AppShellLayoutPolicyScript.visible_section_count(
		view.header_panel != null and view.header_panel.visible,
		view.top_content != null and view.top_content.visible,
		active_phase_surface_visible(view),
		action_bar_in_shell_flow(view)
	)

static func active_phase_surface_visible(view) -> bool:
	return view.active_phase_container != null and AppShellLayoutPolicyScript.active_phase_visible(
		view.battlefield_ui != null and view.battlefield_ui.visible,
		view.reward_panel != null and view.reward_panel.visible,
		view.page_shell_host != null and view.page_shell_host.visible
	)

static func active_phase_min_height(view) -> float:
	var min_height := 0.0
	if view.battlefield_ui != null and view.battlefield_ui.visible:
		min_height = maxf(min_height, float(view.battlefield_ui.get_combined_minimum_size().y))
	if view.reward_panel != null and view.reward_panel.visible:
		min_height = maxf(min_height, float(view.reward_panel.get_combined_minimum_size().y))
	return min_height

static func max_safe_top_content_height(view) -> float:
	var shell_size: Vector2 = viewport_safe_app_shell_size(view)
	var section_gap: float = float(view.app_shell.get_theme_constant("separation")) if view.app_shell != null else 0.0
	return AppShellLayoutPolicyScript.max_safe_top_content_height(
		shell_size,
		section_gap,
		view.header_panel != null and view.header_panel.visible,
		float(view.header_panel.get_combined_minimum_size().y) if view.header_panel != null else 0.0,
		active_phase_surface_visible(view),
		active_phase_min_height(view),
		action_bar_in_shell_flow(view),
		float(view.action_bar.get_combined_minimum_size().y) if action_bar_in_shell_flow(view) else 0.0,
		view.top_content != null and view.top_content.visible
	)

static func max_safe_top_content_backpack_width(view) -> float:
	if view.top_content == null or not view.top_content.visible:
		return 0.0
	var shell_size: Vector2 = viewport_safe_app_shell_size(view)
	var row_gap: float = float(view.top_content.get_theme_constant("separation"))
	var left_min: float = float(view.left_column.get_combined_minimum_size().x) if view.left_column != null and view.left_column.visible else 0.0
	var right_min: float = float(view.right_sidebar.get_combined_minimum_size().x) if view.right_sidebar != null and view.right_sidebar.visible else 0.0
	# 전투 리디자인: 보드 우측 CTA 기둥 폭도 백팩 가용 폭 예산에서 미리 제외한다.
	var cta_column := find_cta_column(view)
	if cta_column != null and cta_column.visible:
		right_min += float(cta_column.get_combined_minimum_size().x) + row_gap
	# 보드 패널 자체 크롬(좌우 마진 + 보드-CTA 간격)도 예산에서 제외한다.
	right_min += board_panel_horizontal_chrome(view)
	return AppShellLayoutPolicyScript.max_safe_backpack_width(shell_size.x, row_gap, left_min, right_min)

# 전투 리디자인 2차: CTA 기둥은 보드 패널 내부로 이동 — 구/신 트리 어디에 있든 찾는다.
static func find_cta_column(view) -> Control:
	if view.top_content == null:
		return null
	var direct := view.top_content.get_node_or_null("CtaColumn") as Control
	if direct != null:
		return direct
	return view.top_content.find_child("CtaColumn", true, false) as Control

static func board_panel_margin(view) -> MarginContainer:
	if view.top_content == null:
		return null
	return view.top_content.get_node_or_null("BoardPanel/BoardMargin") as MarginContainer

static func board_panel_horizontal_chrome(view) -> float:
	var margin := board_panel_margin(view)
	if margin == null:
		return 0.0
	var chrome := float(margin.get_theme_constant("margin_left") + margin.get_theme_constant("margin_right"))
	var board_area := margin.get_node_or_null("BoardBox/BoardArea") as BoxContainer
	if board_area != null:
		chrome += float(board_area.get_theme_constant("separation"))
	return chrome

static func board_panel_vertical_chrome(view) -> float:
	var margin := board_panel_margin(view)
	if margin == null:
		return 0.0
	var chrome := float(margin.get_theme_constant("margin_top") + margin.get_theme_constant("margin_bottom"))
	var board_box := margin.get_node_or_null("BoardBox") as BoxContainer
	if board_box != null:
		chrome += float(board_box.get_theme_constant("separation"))
		var title_row := board_box.get_node_or_null("BoardTitleRow") as Control
		if title_row != null and title_row.visible:
			chrome += float(title_row.get_combined_minimum_size().y)
	return chrome

static func viewport_safe_width_for_control(view, control: Control, fallback_width: float) -> float:
	var width := maxf(0.0, fallback_width)
	if control == null or not view.is_inside_tree():
		return width
	var viewport_width: float = view.get_viewport_rect().size.x
	if viewport_width <= 1.0:
		return width
	var left_edge: float = maxf(0.0, control.global_position.x)
	var safe_right: float = maxf(0.0, viewport_width - VIEWPORT_SAFE_GUTTER)
	var viewport_width_from_control: float = maxf(0.0, safe_right - left_edge)
	if width <= 1.0:
		return viewport_width_from_control
	return minf(width, viewport_width_from_control)

static func sync_top_content_backpack_layout(view) -> void:
	SharedBackpackHostCoordinatorScript.sync_top_content_backpack_layout(
		view.backpack_container,
		view.backpack_original_parent,
		view.top_content,
		Callable(view, "_apply_top_content_backpack_bounds")
	)
	view._queue_backpack_artifact_image_refresh()

static func queue_shared_backpack_layout_sync(view) -> void:
	var queue_state: Dictionary = SharedBackpackHostCoordinatorScript.queue_shared_backpack_layout_sync(
		view.backpack_container,
		view.reward_backpack_host,
		view._shared_backpack_layout_sync_pending,
		Callable(view, "_queue_reward_board_layout_sync")
	)
	view._shared_backpack_layout_sync_pending = bool(queue_state.get("sharedLayoutSyncPending", false))
	if bool(queue_state.get("shouldDeferSharedSync", false)):
		view.call_deferred("_sync_shared_backpack_layout")

static func sync_shared_backpack_layout(view) -> void:
	view._shared_backpack_layout_sync_pending = false
	SharedBackpackHostCoordinatorScript.sync_shared_backpack_layout(
		view.backpack_container,
		view.reward_backpack_host,
		view.node_select_backpack_host,
		view.backpack_original_parent,
		Callable(view, "_sync_node_select_backpack_width"),
		Callable(view, "_sync_top_content_backpack_layout")
	)
	view._queue_backpack_artifact_image_refresh()

static func apply_top_content_stretch(view, left_ratio: float, backpack_ratio: float, right_ratio: float) -> void:
	SharedBackpackHostCoordinatorScript.apply_top_content_stretch(
		view.left_column,
		view.backpack_host,
		view.top_content,
		view.right_sidebar,
		left_ratio,
		backpack_ratio,
		right_ratio
	)
	if view.backpack_container != null:
		view.backpack_container.size_flags_stretch_ratio = backpack_ratio
