class_name MainViewBackpackRuntime
extends RefCounted

const SharedBackpackHostCoordinatorScript = preload("res://src/ui/SharedBackpackHostCoordinator.gd")
const SharedBackpackScene = preload("res://src/scenes/pages/shells/SharedBackpack.tscn")

static func node_select_backpack_width_for_row(row_size: Vector2, map_min_width: float) -> float:
	return SharedBackpackHostCoordinatorScript.node_select_backpack_width_for_row(row_size, map_min_width)

static func top_content_backpack_horizontal_flags() -> int:
	return SharedBackpackHostCoordinatorScript.top_content_backpack_horizontal_flags()

static func top_content_side_horizontal_flags() -> int:
	return SharedBackpackHostCoordinatorScript.top_content_side_horizontal_flags()

static func create_shared_backpack(view) -> void:
	if view.backpack_container != null and view.backpack_ui != null:
		return
	var shared_backpack := SharedBackpackScene.instantiate() as AspectRatioContainer
	if shared_backpack == null:
		return
	shared_backpack.name = "SharedBackpackContainer"
	shared_backpack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shared_backpack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.backpack_container = shared_backpack
	view.backpack_ui = shared_backpack.get_node_or_null("BackpackEnginePanel")
	if view.backpack_host != null:
		view.backpack_host.add_child(shared_backpack)
		view.backpack_original_parent = view.backpack_host
		view.backpack_original_index = shared_backpack.get_index()

static func connect_shared_backpack_signals(view) -> void:
	if view._shared_backpack_signals_connected or view.backpack_ui == null:
		return
	view._shared_backpack_signals_connected = true
	view.backpack_ui.slot_clicked.connect(func(coord): view.backpack_slot_clicked.emit(coord))
	view.backpack_ui.slot_hovered.connect(func(coord): view.backpack_slot_hovered.emit(coord))
	view.backpack_ui.slot_unhovered.connect(func(coord): view.backpack_slot_unhovered.emit(coord))
	view.backpack_ui.slot_drag_started.connect(func(coord):
		view._begin_backpack_drag_tracking(coord)
		view.backpack_slot_drag_started.emit(coord)
	)

static func setup_backpack_slots(view) -> void:
	if view.backpack_ui != null and view.backpack_ui.has_method("setup_grid_slots"):
		view.backpack_ui.setup_grid_slots()

static func render_backpack(view, inventory) -> void:
	if view.backpack_ui != null and view.backpack_ui.has_method("render_backpack_items"):
		view.backpack_ui.render_backpack_items(inventory)

static func queue_artifact_image_refresh(view) -> void:
	if view.backpack_ui != null and view.backpack_ui.has_method("queue_artifact_image_refresh"):
		view.backpack_ui.queue_artifact_image_refresh()

static func update_backpack_ghost(view, artifact) -> void:
	if view.backpack_ui != null and view.backpack_ui.has_method("update_ghost_display"):
		view.backpack_ui.update_ghost_display(artifact)

static func schedule_backpack_reparent(view, target_parent: Node, target_index: int = -1) -> void:
	if view.backpack_container == null or target_parent == null:
		return
	view._pending_backpack_parent = target_parent
	view._pending_backpack_parent_index = target_index
	if view._backpack_reparent_pending:
		return
	view._backpack_reparent_pending = true
	view.call_deferred("_commit_backpack_reparent")

static func commit_backpack_reparent(view) -> void:
	view._backpack_reparent_pending = false
	var reparent_state: Dictionary = SharedBackpackHostCoordinatorScript.commit_backpack_reparent(
		view.backpack_container,
		view._pending_backpack_parent,
		view._pending_backpack_parent_index,
		view.backpack_original_parent,
		view.reward_backpack_host,
		view.node_select_backpack_host,
		Callable(view, "_queue_shared_backpack_layout_sync"),
		Callable(view, "_queue_reward_board_layout_sync"),
		Callable(),
		Callable(view, "_flush_pending_backpack_pin_scene")
	)
	view._pending_backpack_parent = reparent_state.get("pendingBackpackParent", null)
	view._pending_backpack_parent_index = int(reparent_state.get("pendingBackpackParentIndex", -1))
	queue_artifact_image_refresh(view)

static func flush_pending_backpack_pin_scene(view) -> void:
	if view._backpack_reparent_pending:
		return
	view._pending_backpack_pin_scene = SharedBackpackHostCoordinatorScript.flush_pending_backpack_pin_scene(
		view.backpack_ui,
		view._pending_backpack_pin_scene
	)
