class_name MainViewRewardLayoutRuntime
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const AppShellLayoutPolicyScript = preload("res://src/ui/presenters/AppShellLayoutPolicy.gd")
const RewardBoardLayoutPolicyScript = preload("res://src/ui/presenters/RewardBoardLayoutPolicy.gd")
const SharedBackpackHostCoordinatorScript = preload("res://src/ui/SharedBackpackHostCoordinator.gd")

const NODE_SELECT_MAP_MIN_WIDTH := 460.0
const REWARD_BOARD_TOP_ZONE_MIN_HEIGHT := 320.0
const REWARD_BOARD_BOTTOM_ROW_MIN_HEIGHT := 82.0
const REWARD_BOARD_BOTTOM_ROW_RATIO := 0.10

static func apply_node_select_backpack_dock(view, dock: String, map_ratio: float, backpack_ratio: float) -> void:
	SharedBackpackHostCoordinatorScript.apply_node_select_backpack_dock(
		view.backpack_container,
		view.node_select_content_row,
		view.node_select_backpack_host,
		view.backpack_original_parent,
		view.backpack_original_index,
		dock,
		map_ratio,
		backpack_ratio,
		node_select_backpack_width(view),
		Callable(view, "_schedule_backpack_reparent")
	)

static func node_select_backpack_width(view) -> float:
	var row_size := Vector2.ZERO
	if view.node_select_content_row != null:
		row_size = view.node_select_content_row.size
		row_size.x = view._viewport_safe_width_for_control(view.node_select_content_row, row_size.x)
	if row_size.y <= 1.0:
		row_size.y = view.active_phase_container.size.y
	if row_size.x <= 1.0:
		row_size.x = view._viewport_safe_width_for_control(view.active_phase_container, view.active_phase_container.size.x)
	return SharedBackpackHostCoordinatorScript.node_select_backpack_width_for_row(row_size, NODE_SELECT_MAP_MIN_WIDTH)

static func sync_node_select_backpack_width(view) -> void:
	SharedBackpackHostCoordinatorScript.sync_node_select_backpack_width(
		view.backpack_container,
		view.node_select_backpack_host,
		node_select_backpack_width(view)
	)

static func apply_reward_backpack_dock(view, dock_to_board: bool) -> void:
	SharedBackpackHostCoordinatorScript.apply_reward_backpack_dock(
		view.backpack_container,
		view.reward_backpack_host,
		view.backpack_original_parent,
		view.backpack_original_index,
		dock_to_board,
		Callable(view, "_set_reward_workspace_title_state"),
		Callable(view, "_schedule_backpack_reparent")
	)
	if dock_to_board and view.reward_backpack_host != null and view._pending_backpack_parent != null and view._pending_backpack_parent != view.reward_backpack_host:
		view._schedule_backpack_reparent(view.reward_backpack_host)

static func sync_reward_backpack_layout(view) -> void:
	SharedBackpackHostCoordinatorScript.sync_reward_backpack_layout(
		view.backpack_container,
		view.reward_backpack_host,
		view.active_phase_container,
		Callable(view, "_reward_backpack_panel_dimensions_for_host"),
		Callable(view, "_set_custom_minimum_size_if_changed")
	)
	view._queue_backpack_artifact_image_refresh()

static func install_reward_zone_scroll_shells(view) -> void:
	view.reward_cloud_scroll = install_body_scroll_shell(view.reward_cloud_content, "RewardCloudScroll")
	view.discard_card_scroll = install_body_scroll_shell(view.discard_card, "DiscardCardScroll")
	view.claim_card_scroll = install_body_scroll_shell(view.claim_card, "ClaimCardScroll")

static func install_body_scroll_shell(body: Control, shell_name: String) -> ScrollContainer:
	if body == null:
		return null
	var existing_scroll := body.get_parent() as ScrollContainer
	if existing_scroll != null:
		return existing_scroll
	var host := body.get_parent()
	if host == null:
		return null
	var body_index := body.get_index()
	host.remove_child(body)
	var scroll := ScrollContainer.new()
	scroll.name = shell_name
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = 0
	scroll.clip_contents = true
	host.add_child(scroll)
	host.move_child(scroll, body_index)
	scroll.add_child(body)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return scroll

static func install_reward_inspector_scroll_shell(view) -> void:
	if view.reward_inspector_stage == null:
		return
	var existing_scroll: ScrollContainer = view.reward_inspector_stage.get_parent() as ScrollContainer
	if existing_scroll != null:
		view.reward_inspector_scroll = existing_scroll
		return
	var zone_box: VBoxContainer = view.reward_inspector_stage.get_parent() as VBoxContainer
	if zone_box == null:
		return
	var stage_index: int = view.reward_inspector_stage.get_index()
	zone_box.remove_child(view.reward_inspector_stage)
	view.reward_inspector_scroll = ScrollContainer.new()
	view.reward_inspector_scroll.name = "InspectorScroll"
	view.reward_inspector_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.reward_inspector_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.reward_inspector_scroll.horizontal_scroll_mode = 0
	view.reward_inspector_scroll.clip_contents = true
	zone_box.add_child(view.reward_inspector_scroll)
	zone_box.move_child(view.reward_inspector_scroll, stage_index)
	view.reward_inspector_scroll.add_child(view.reward_inspector_stage)
	view.reward_inspector_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.reward_inspector_stage.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

static func sync_reward_board_layout(view) -> void:
	view._reward_board_layout_sync_pending = false
	if view.reward_grid == null or view.reward_workspace_zone == null or view.reward_backpack_host == null or view.reward_board_scroll == null:
		return
	install_reward_zone_scroll_shells(view)
	install_reward_inspector_scroll_shell(view)
	set_reward_workspace_title_state(view, true)
	if view.reward_workspace_note != null:
		view.reward_workspace_note.visible = false
	if view.reward_workspace_box != null:
		set_theme_constant_override_if_changed(view.reward_workspace_box, "separation", 8)
	if view.reward_workspace_margin != null:
		set_theme_constant_override_if_changed(view.reward_workspace_margin, "margin_left", 12)
		set_theme_constant_override_if_changed(view.reward_workspace_margin, "margin_top", 12)
		set_theme_constant_override_if_changed(view.reward_workspace_margin, "margin_right", 12)
		set_theme_constant_override_if_changed(view.reward_workspace_margin, "margin_bottom", 12)
	var grid_width: float = reward_board_available_width(view)
	var grid_height: float = view.reward_grid.size.y
	if grid_width <= 1.0 or grid_height <= 1.0:
		return
	var visible_board_height: float = reward_board_visible_height(view)
	set_custom_minimum_height_if_changed(view.reward_board_scroll, visible_board_height)
	var layout_targets: Dictionary = reward_board_layout_targets(view, visible_board_height)
	var top_zone_height: float = float(layout_targets.get("topZoneHeight", maxf(REWARD_BOARD_TOP_ZONE_MIN_HEIGHT, grid_height)))
	var bottom_row_height: float = float(layout_targets.get("bottomRowHeight", REWARD_BOARD_BOTTOM_ROW_MIN_HEIGHT))
	var rewards_body: Control = view.reward_cloud_scroll if view.reward_cloud_scroll != null else view.reward_cloud_box
	var workspace_body_height: float = reward_zone_body_target_height(view.reward_workspace_zone, view.reward_backpack_host, top_zone_height, 220.0)
	var rewards_body_height: float = reward_zone_body_target_height(view.reward_rewards_zone, rewards_body, top_zone_height, 220.0)
	var inspector_body: Control = view.reward_inspector_scroll if view.reward_inspector_scroll != null else view.reward_inspector_stage
	var inspector_body_height: float = reward_zone_body_target_height(view.reward_inspector_zone, inspector_body, top_zone_height, 220.0)
	var discard_body_height: float = reward_zone_body_target_height(view.discard_zone, view.discard_card, bottom_row_height, 34.0)
	var claim_body_height: float = reward_zone_body_target_height(view.confirm_zone, view.claim_card, bottom_row_height, 34.0)
	top_zone_height = maxf(top_zone_height, maxf(view.reward_rewards_zone.get_combined_minimum_size().y, maxf(view.reward_workspace_zone.get_combined_minimum_size().y, view.reward_inspector_zone.get_combined_minimum_size().y)))
	bottom_row_height = maxf(bottom_row_height, view.reward_bottom_row.get_combined_minimum_size().y)
	top_zone_height = maxf(REWARD_BOARD_TOP_ZONE_MIN_HEIGHT, visible_board_height - bottom_row_height - float(view.reward_board.get_theme_constant("separation")))
	rewards_body_height = reward_zone_body_target_height(view.reward_rewards_zone, rewards_body, top_zone_height, 220.0)
	workspace_body_height = reward_zone_body_target_height(view.reward_workspace_zone, view.reward_backpack_host, top_zone_height, 220.0)
	inspector_body_height = reward_zone_body_target_height(view.reward_inspector_zone, inspector_body, top_zone_height, 220.0)
	discard_body_height = reward_zone_body_target_height(view.discard_zone, view.discard_card, bottom_row_height, 34.0)
	claim_body_height = reward_zone_body_target_height(view.confirm_zone, view.claim_card, bottom_row_height, 34.0)
	set_custom_minimum_width_if_changed(view.reward_board, grid_width)
	set_custom_minimum_width_if_changed(view.reward_grid, grid_width)
	set_custom_minimum_height_if_changed(view.reward_board, top_zone_height + bottom_row_height + float(view.reward_board.get_theme_constant("separation")))
	set_custom_minimum_height_if_changed(view.reward_grid, top_zone_height)
	view.reward_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	set_custom_minimum_height_if_changed(view.reward_bottom_row, bottom_row_height)
	view.reward_bottom_row.size_flags_vertical = Control.SIZE_FILL
	apply_reward_board_zone_height(view.reward_rewards_zone, top_zone_height)
	apply_reward_board_zone_height(view.reward_workspace_zone, top_zone_height)
	apply_reward_board_zone_height(view.reward_inspector_zone, top_zone_height)
	apply_reward_board_zone_height(view.discard_zone, bottom_row_height)
	apply_reward_board_zone_height(view.confirm_zone, bottom_row_height)
	if view.reward_cloud_scroll != null:
		set_custom_minimum_height_if_changed(view.reward_cloud_scroll, rewards_body_height)
		view.reward_cloud_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		view.reward_cloud_scroll.scroll_vertical = 0
	if view.reward_cloud_box != null:
		set_custom_minimum_height_if_changed(view.reward_cloud_box, 0.0)
	if view.reward_backpack_host != null:
		set_custom_minimum_height_if_changed(view.reward_backpack_host, workspace_body_height)
		view.reward_backpack_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if view.reward_inspector_scroll != null:
		set_custom_minimum_height_if_changed(view.reward_inspector_scroll, inspector_body_height)
		view.reward_inspector_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		view.reward_inspector_scroll.scroll_vertical = 0
	if view.reward_inspector_stage != null:
		set_custom_minimum_height_if_changed(view.reward_inspector_stage, 0.0)
	if view.discard_card_scroll != null:
		set_custom_minimum_height_if_changed(view.discard_card_scroll, discard_body_height)
		view.discard_card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		view.discard_card_scroll.scroll_vertical = 0
	if view.claim_card_scroll != null:
		set_custom_minimum_height_if_changed(view.claim_card_scroll, claim_body_height)
		view.claim_card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		view.claim_card_scroll.scroll_vertical = 0
	view.reward_board_scroll.scroll_vertical = 0
	var host_height: float = maxf(0.0, view.reward_workspace_zone.size.y - 4.0)
	var desired_panel: Vector2 = reward_backpack_panel_dimensions_for_host(view, Vector2(maxf(0.0, grid_width), maxf(0.0, host_height)))
	var gap: float = float(view.reward_grid.get_theme_constant("separation"))
	var min_side_width: float = clampf(grid_width * 0.17, 168.0, 260.0)
	var desired_middle_width: float = clampf(desired_panel.x + 8.0, 320.0, maxf(320.0, grid_width - gap * 2.0))
	var max_middle_width: float = maxf(320.0, grid_width - gap * 2.0 - min_side_width * 2.0)
	if max_middle_width > 0.0:
		desired_middle_width = minf(desired_middle_width, max_middle_width)
	var remaining_width: float = maxf(0.0, grid_width - desired_middle_width - gap * 2.0)
	var side_width: float = maxf(min_side_width, remaining_width * 0.5)
	set_custom_minimum_width_if_changed(view.reward_rewards_zone, side_width)
	set_custom_minimum_width_if_changed(view.reward_inspector_zone, side_width)
	set_custom_minimum_width_if_changed(view.reward_workspace_zone, desired_middle_width)
	var side_ratio: float = maxf(0.64, side_width / 240.0)
	view.reward_rewards_zone.size_flags_stretch_ratio = side_ratio
	view.reward_inspector_zone.size_flags_stretch_ratio = side_ratio
	view.reward_workspace_zone.size_flags_stretch_ratio = maxf(1.55, desired_middle_width / 240.0)
	sync_reward_backpack_layout(view)

static func reward_board_available_width(view) -> float:
	var shell_width: float = view._viewport_safe_app_shell_size().x
	if shell_width <= 1.0:
		shell_width = view.get_viewport_rect().size.x
	var horizontal_margin := 0.0
	if view.reward_panel_margin != null:
		horizontal_margin = float(view.reward_panel_margin.get_theme_constant("margin_left") + view.reward_panel_margin.get_theme_constant("margin_right"))
	return RewardBoardLayoutPolicyScript.board_available_width(shell_width, horizontal_margin)

static func reward_board_layout_targets(view, scroll_height: float) -> Dictionary:
	var bottom_min := REWARD_BOARD_BOTTOM_ROW_MIN_HEIGHT
	if view.reward_bottom_row != null:
		bottom_min = maxf(bottom_min, view.reward_bottom_row.get_combined_minimum_size().y)
	var board_gap: float = float(view.reward_board.get_theme_constant("separation")) if view.reward_board != null else 0.0
	return RewardBoardLayoutPolicyScript.board_layout_targets(scroll_height, board_gap, bottom_min, REWARD_BOARD_TOP_ZONE_MIN_HEIGHT, REWARD_BOARD_BOTTOM_ROW_RATIO)

static func reward_board_visible_height(view) -> float:
	if view.reward_panel == null or view.reward_panel_margin == null or view.reward_box == null or view.reward_board_head == null:
		return REWARD_BOARD_TOP_ZONE_MIN_HEIGHT + REWARD_BOARD_BOTTOM_ROW_MIN_HEIGHT + 16.0
	var panel_height: float = minf(view.reward_panel.size.y, view._max_safe_active_phase_height())
	if panel_height <= 1.0:
		panel_height = maxf(view._max_safe_active_phase_height(), view.reward_panel.get_combined_minimum_size().y)
	if panel_height <= 1.0:
		return REWARD_BOARD_TOP_ZONE_MIN_HEIGHT + REWARD_BOARD_BOTTOM_ROW_MIN_HEIGHT + 16.0
	var outer_margin: float = float(view.reward_panel_margin.get_theme_constant("margin_top") + view.reward_panel_margin.get_theme_constant("margin_bottom"))
	var reward_box_gap: float = float(view.reward_box.get_theme_constant("separation"))
	var head_height: float = view.reward_board_head.get_combined_minimum_size().y
	var min_board_height: float = REWARD_BOARD_TOP_ZONE_MIN_HEIGHT + REWARD_BOARD_BOTTOM_ROW_MIN_HEIGHT + float(view.reward_board.get_theme_constant("separation"))
	return maxf(min_board_height, panel_height - outer_margin - reward_box_gap - head_height - 2.0)

static func apply_reward_board_zone_height(zone: Control, target_height: float) -> void:
	if zone == null:
		return
	set_custom_minimum_height_if_changed(zone, target_height)
	zone.size_flags_vertical = Control.SIZE_EXPAND_FILL

static func reward_zone_body_target_height(zone: Control, body: Control, target_height: float, fallback_min: float) -> float:
	if zone == null or body == null:
		return maxf(fallback_min, target_height)
	return RewardBoardLayoutPolicyScript.zone_body_target_height(zone.get_combined_minimum_size().y, body.get_combined_minimum_size().y, target_height, fallback_min)

static func set_theme_constant_override_if_changed(control: Control, key: StringName, value: int) -> void:
	if control == null or control.get_theme_constant(key) == value:
		return
	control.add_theme_constant_override(key, value)

static func set_custom_minimum_size_if_changed(control: Control, next_size: Vector2, epsilon: float = 0.5) -> void:
	if control == null or control.custom_minimum_size.distance_to(next_size) <= epsilon:
		return
	control.custom_minimum_size = next_size

static func set_custom_minimum_height_if_changed(control: Control, next_height: float, epsilon: float = 0.5) -> void:
	if control == null or absf(control.custom_minimum_size.y - next_height) <= epsilon:
		return
	control.custom_minimum_size.y = next_height

static func set_custom_minimum_width_if_changed(control: Control, next_width: float, epsilon: float = 0.5) -> void:
	if control == null or absf(control.custom_minimum_size.x - next_width) <= epsilon:
		return
	control.custom_minimum_size.x = next_width

static func reward_backpack_panel_dimensions_for_host(view, host_size: Vector2) -> Vector2:
	var chrome: Vector2 = reward_backpack_panel_chrome_dimensions(view)
	return RewardBoardLayoutPolicyScript.backpack_panel_dimensions_for_host(host_size, chrome.x, chrome.y, reward_backpack_panel_visible_height_cap(view))

static func reward_backpack_panel_chrome_dimensions(view) -> Vector2:
	var margin_width := 32.0
	var chrome_height := 56.0
	if view.backpack_ui == null:
		return Vector2(margin_width, chrome_height)
	var margin: MarginContainer = view.backpack_ui.get_node_or_null("Margin") as MarginContainer
	if margin != null:
		margin_width = float(margin.get_theme_constant("margin_left") + margin.get_theme_constant("margin_right"))
		chrome_height = float(margin.get_theme_constant("margin_top") + margin.get_theme_constant("margin_bottom"))
	var engine_box: VBoxContainer = view.backpack_ui.get_node_or_null("Margin/EngineBox") as VBoxContainer
	var title: Control = view.backpack_ui.get_node_or_null("Margin/EngineBox/EngineTitle") as Control
	if engine_box != null and title != null and title.visible:
		chrome_height += float(engine_box.get_theme_constant("separation"))
	if title != null and title.visible:
		chrome_height += title.get_combined_minimum_size().y
	return Vector2(margin_width, chrome_height)

static func set_reward_workspace_title_state(view, dock_to_board: bool) -> void:
	if view.reward_workspace_head != null:
		view.reward_workspace_head.visible = dock_to_board
	if view.reward_workspace_title != null and dock_to_board:
		view.reward_workspace_title.text = TextCatalogScript.t("panel.backpack")
	apply_reward_backpack_padding_for_workspace(view, dock_to_board)
	if view.backpack_ui == null:
		return
	if view.backpack_ui.has_method("set_influence_preview_toggle_anchor"):
		view.backpack_ui.set_influence_preview_toggle_anchor(view.reward_workspace_title if dock_to_board else null)
	var backpack_engine_title: Control = view.backpack_ui.get_node_or_null("Margin/EngineBox/EngineTitle") as Control
	if backpack_engine_title != null:
		backpack_engine_title.visible = not dock_to_board

static func apply_reward_backpack_padding_for_workspace(view, dock_to_board: bool) -> void:
	if view.backpack_ui == null:
		return
	var margin: MarginContainer = view.backpack_ui.get_node_or_null("Margin") as MarginContainer
	if margin == null:
		return
	var padding := 10 if dock_to_board else 16
	set_theme_constant_override_if_changed(margin, "margin_left", padding)
	set_theme_constant_override_if_changed(margin, "margin_top", padding)
	set_theme_constant_override_if_changed(margin, "margin_right", padding)
	set_theme_constant_override_if_changed(margin, "margin_bottom", padding)

static func reward_backpack_panel_visible_height_cap(view) -> float:
	if view.reward_panel == null or view.reward_panel_margin == null or view.reward_box == null or view.reward_board_head == null or view.reward_board == null or view.reward_bottom_row == null:
		return 0.0
	var panel_height: float = minf(view.reward_panel.size.y, view._max_safe_active_phase_height())
	if panel_height <= 1.0:
		panel_height = view._max_safe_active_phase_height()
	if panel_height <= 1.0:
		return 0.0
	var outer_margin: float = float(view.reward_panel_margin.get_theme_constant("margin_top") + view.reward_panel_margin.get_theme_constant("margin_bottom"))
	var reward_box_gap: float = float(view.reward_box.get_theme_constant("separation"))
	var reward_board_gap: float = float(view.reward_board.get_theme_constant("separation"))
	var head_height: float = view.reward_board_head.get_combined_minimum_size().y
	var bottom_row_height: float = maxf(view.reward_bottom_row.get_combined_minimum_size().y, view.reward_bottom_row.custom_minimum_size.y)
	return AppShellLayoutPolicyScript.reward_backpack_panel_visible_height_cap(panel_height, outer_margin, reward_box_gap, reward_board_gap, head_height, bottom_row_height)
