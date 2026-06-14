class_name SharedBackpackHostCoordinator
extends RefCounted

const BackpackPinLayoutPolicyScript = preload("res://src/ui/presenters/BackpackPinLayoutPolicy.gd")

static func node_select_backpack_width_for_row(row_size: Vector2, map_min_width: float) -> float:
	return BackpackPinLayoutPolicyScript.node_select_width_for_row(row_size, map_min_width)

static func top_content_backpack_horizontal_flags() -> int:
	return Control.SIZE_SHRINK_CENTER

static func top_content_side_horizontal_flags() -> int:
	return Control.SIZE_EXPAND_FILL

static func top_content_left_horizontal_flags(left_ratio: float) -> int:
	return Control.SIZE_FILL if left_ratio <= 0.0 else top_content_side_horizontal_flags()

static func apply_node_select_backpack_dock(
	backpack_container: Control,
	node_select_content_row: Control,
	node_select_backpack_host: Control,
	backpack_original_parent: Node,
	backpack_original_index: int,
	dock: String,
	map_ratio: float,
	backpack_ratio: float,
	backpack_width: float,
	schedule_backpack_reparent: Callable
) -> void:
	if backpack_container == null or node_select_content_row == null or node_select_backpack_host == null or backpack_original_parent == null:
		return
	if dock == "right":
		if backpack_container.get_parent() != node_select_backpack_host and not schedule_backpack_reparent.is_null():
			schedule_backpack_reparent.call(node_select_backpack_host)
		node_select_backpack_host.size_flags_horizontal = Control.SIZE_SHRINK_END
		node_select_backpack_host.size_flags_stretch_ratio = backpack_ratio
		node_select_backpack_host.custom_minimum_size = Vector2(backpack_width, 0.0)
		backpack_container.size_flags_stretch_ratio = backpack_ratio
		backpack_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		backpack_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		backpack_container.custom_minimum_size = Vector2(backpack_width, 0.0)
		return
	if backpack_container.get_parent() != backpack_original_parent and not schedule_backpack_reparent.is_null():
		schedule_backpack_reparent.call(backpack_original_parent, backpack_original_index)
	node_select_backpack_host.custom_minimum_size = Vector2.ZERO
	backpack_container.size_flags_stretch_ratio = 0.0
	backpack_container.size_flags_horizontal = top_content_backpack_horizontal_flags()
	backpack_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	backpack_container.custom_minimum_size = Vector2.ZERO

static func sync_node_select_backpack_width(backpack_container: Control, node_select_backpack_host: Control, backpack_width: float) -> void:
	if backpack_container == null or node_select_backpack_host == null or backpack_container.get_parent() != node_select_backpack_host:
		return
	node_select_backpack_host.custom_minimum_size = Vector2(backpack_width, 0.0)
	backpack_container.custom_minimum_size = Vector2(backpack_width, 0.0)
	backpack_container.ratio = 1.0
	backpack_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	backpack_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

static func apply_reward_backpack_dock(
	backpack_container: Control,
	reward_backpack_host: Control,
	backpack_original_parent: Node,
	backpack_original_index: int,
	dock_to_board: bool,
	set_reward_workspace_title_state: Callable,
	schedule_backpack_reparent: Callable
) -> void:
	if backpack_container == null or reward_backpack_host == null or backpack_original_parent == null:
		return
	if not set_reward_workspace_title_state.is_null():
		set_reward_workspace_title_state.call(dock_to_board)
	if dock_to_board:
		if backpack_container.get_parent() != reward_backpack_host and not schedule_backpack_reparent.is_null():
			schedule_backpack_reparent.call(reward_backpack_host)
		backpack_container.ratio = 1.0
		backpack_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		backpack_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return
	if backpack_container.get_parent() == reward_backpack_host and not schedule_backpack_reparent.is_null():
		schedule_backpack_reparent.call(backpack_original_parent, backpack_original_index)

static func sync_reward_backpack_layout(
	backpack_container: Control,
	reward_backpack_host: Control,
	active_phase_container: Control,
	reward_backpack_panel_dimensions_for_host: Callable,
	set_custom_minimum_size_if_changed: Callable
) -> void:
	if backpack_container == null or reward_backpack_host == null or backpack_container.get_parent() != reward_backpack_host:
		return
	var host_size := reward_backpack_host.size
	if active_phase_container != null and (host_size.x <= 1.0 or host_size.y <= 1.0):
		host_size = Vector2(active_phase_container.size.x * 0.40, active_phase_container.size.y * 0.82)
	if reward_backpack_panel_dimensions_for_host.is_null():
		return
	var panel_dims: Vector2 = reward_backpack_panel_dimensions_for_host.call(host_size)
	if panel_dims.x <= 1.0 or panel_dims.y <= 1.0:
		return
	if not set_custom_minimum_size_if_changed.is_null():
		set_custom_minimum_size_if_changed.call(backpack_container, panel_dims)
	backpack_container.ratio = panel_dims.x / maxf(1.0, panel_dims.y)
	backpack_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	backpack_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER

static func sync_top_content_backpack_layout(
	backpack_container: Control,
	backpack_original_parent: Node,
	top_content: Control,
	apply_top_content_backpack_bounds: Callable
) -> void:
	if backpack_container == null or backpack_original_parent == null or backpack_container.get_parent() != backpack_original_parent:
		return
	if top_content == null or not top_content.visible:
		return
	if not apply_top_content_backpack_bounds.is_null():
		apply_top_content_backpack_bounds.call()
	backpack_container.size_flags_horizontal = top_content_backpack_horizontal_flags()
	backpack_container.size_flags_vertical = Control.SIZE_EXPAND_FILL

static func queue_shared_backpack_layout_sync(
	backpack_container: Control,
	reward_backpack_host: Control,
	shared_backpack_layout_sync_pending: bool,
	queue_reward_board_layout_sync: Callable
) -> Dictionary:
	if backpack_container != null and backpack_container.get_parent() == reward_backpack_host:
		if not queue_reward_board_layout_sync.is_null():
			queue_reward_board_layout_sync.call()
		return {
			"sharedLayoutSyncPending": false,
			"shouldDeferSharedSync": false
		}
	if shared_backpack_layout_sync_pending:
		return {
			"sharedLayoutSyncPending": true,
			"shouldDeferSharedSync": false
		}
	return {
		"sharedLayoutSyncPending": true,
		"shouldDeferSharedSync": true
	}

static func sync_shared_backpack_layout(
	backpack_container: Control,
	reward_backpack_host: Control,
	node_select_backpack_host: Control,
	backpack_original_parent: Node,
	sync_node_select_backpack_width: Callable,
	sync_top_content_backpack_layout: Callable
) -> void:
	if backpack_container == null:
		return
	if backpack_container.get_parent() == node_select_backpack_host:
		if not sync_node_select_backpack_width.is_null():
			sync_node_select_backpack_width.call()
		return
	if backpack_container.get_parent() == reward_backpack_host:
		return
	if backpack_container.get_parent() == backpack_original_parent and not sync_top_content_backpack_layout.is_null():
		sync_top_content_backpack_layout.call()

static func apply_top_content_stretch(
	left_column: Control,
	backpack_container: Control,
	backpack_original_parent: Node,
	right_sidebar: Control,
	left_ratio: float,
	backpack_ratio: float,
	right_ratio: float
) -> void:
	if left_column != null:
		left_column.size_flags_horizontal = top_content_left_horizontal_flags(left_ratio)
		left_column.size_flags_stretch_ratio = maxf(0.0, left_ratio)
	if backpack_container != null:
		if backpack_container.get_parent() == backpack_original_parent:
			backpack_container.size_flags_horizontal = top_content_backpack_horizontal_flags()
		backpack_container.size_flags_stretch_ratio = backpack_ratio
	if right_sidebar != null:
		right_sidebar.size_flags_horizontal = top_content_side_horizontal_flags()
		right_sidebar.size_flags_stretch_ratio = right_ratio

static func commit_backpack_reparent(
	backpack_container: Control,
	pending_backpack_parent: Node,
	pending_backpack_parent_index: int,
	backpack_original_parent: Node,
	reward_backpack_host: Control,
	node_select_backpack_host: Control,
	queue_shared_backpack_layout_sync: Callable,
	queue_reward_board_layout_sync: Callable,
	queue_node_map_layout_refresh: Callable,
	flush_pending_backpack_pin_scene: Callable
) -> Dictionary:
	var result := {
		"pendingBackpackParent": pending_backpack_parent,
		"pendingBackpackParentIndex": pending_backpack_parent_index,
		"nodeMapFollowupRequested": false
	}
	if backpack_container == null or pending_backpack_parent == null:
		return result
	var target_parent := pending_backpack_parent
	if backpack_container.get_parent() != pending_backpack_parent:
		var current_parent := backpack_container.get_parent()
		if current_parent != null:
			current_parent.remove_child(backpack_container)
		pending_backpack_parent.add_child(backpack_container)
	if pending_backpack_parent == backpack_original_parent and pending_backpack_parent_index >= 0:
		backpack_original_parent.move_child(backpack_container, pending_backpack_parent_index)
	result["pendingBackpackParent"] = null
	result["pendingBackpackParentIndex"] = -1
	if not queue_shared_backpack_layout_sync.is_null():
		queue_shared_backpack_layout_sync.call()
	if target_parent == reward_backpack_host and not queue_reward_board_layout_sync.is_null():
		queue_reward_board_layout_sync.call()
	if target_parent == node_select_backpack_host:
		result["nodeMapFollowupRequested"] = true
		if not queue_node_map_layout_refresh.is_null():
			queue_node_map_layout_refresh.call()
	if not flush_pending_backpack_pin_scene.is_null():
		flush_pending_backpack_pin_scene.call()
	return result

static func flush_pending_backpack_pin_scene(backpack_ui: Node, pending_backpack_pin_scene: Dictionary) -> Dictionary:
	if backpack_ui == null or not backpack_ui.has_method("update_pin_overlays"):
		return pending_backpack_pin_scene
	if pending_backpack_pin_scene.is_empty():
		return pending_backpack_pin_scene
	backpack_ui.update_pin_overlays(pending_backpack_pin_scene)
	return {}
