class_name MainViewLifecycleRuntime
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")

static func ready(view) -> void:
	view.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	view.theme = LTLThemeScript.shared_theme()
	view._create_page_scenes()
	view._cache_page_shell_bundles()
	view._activate_surface_bundle("battle")
	view._activate_action_bar_bundle("node_select")
	view._create_shared_backpack()
	_connect_static_signals(view)
	view._connect_page_shell_bundle_signals()
	view._connect_shared_backpack_signals()
	view.resized.connect(Callable(view, "_queue_shared_backpack_layout_sync"))
	view.active_phase_container.resized.connect(Callable(view, "_queue_shared_backpack_layout_sync"))
	if view.page_shell_host != null:
		view.page_shell_host.resized.connect(Callable(view, "_sync_page_scene_bounds"))
	if view.meta_page_shell_host != null:
		view.meta_page_shell_host.resized.connect(Callable(view, "_sync_page_scene_bounds"))
	_create_header_buttons(view)
	view._create_shop_panel()
	view._create_artifact_codex_panel()
	view._install_character_presentation()
	view._install_reward_backdrop()
	view._install_failure_backdrop()
	view.backpack_original_parent = view.backpack_host
	view.backpack_original_index = view.backpack_container.get_index() if view.backpack_container != null else -1
	view._create_giant_timer()
	view._create_reward_reveal_overlay()
	view._create_vignette_overlay()
	view._create_tooltip_panel()
	view.settings_panel.volume_changed.connect(view.set_volume)
	view.settings_panel.language_changed.connect(func(_locale): view.apply_locale())
	view._apply_shell_theme()
	view.apply_locale()
	view._defer_interaction_fx_install()
	view._view_layout_ready = true
	view._emit_combat_overlay_pause_visibility_changed()
	view._sync_page_scene_bounds()
	queue_viewport_shell_sync(view)
	view._queue_shared_backpack_layout_sync()
	view._queue_reward_board_layout_sync()

static func apply_shared_split_layout_text_policies(view) -> void:
	apply_wrapping_label_policy(view.reward_inspector_name)
	apply_wrapping_label_policy(view.reward_cloud_note)
	apply_wrapping_label_policy(view.discard_label)
	apply_wrapping_label_policy(view.claim_card_body)
	apply_wrapping_rich_text_policy(view.reward_workspace_note)
	apply_wrapping_rich_text_policy(view.reward_inspector_summary)

static func apply_wrapping_label_policy(label: Label) -> void:
	if label == null:
		return
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

static func apply_wrapping_rich_text_policy(label: RichTextLabel) -> void:
	if label == null:
		return
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.fit_content = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.scroll_active = false

static func handle_notification(view, what: int) -> void:
	if what == view.NOTIFICATION_RESIZED and view._view_layout_ready:
		var viewport_size: Vector2 = view.get_viewport_rect().size
		if view._last_viewport_shell_size.distance_to(viewport_size) > 0.5:
			queue_viewport_shell_sync(view)

static func queue_viewport_shell_sync(view) -> void:
	if view._viewport_shell_sync_pending:
		return
	view._viewport_shell_sync_pending = true
	view.call_deferred("_sync_viewport_shell_bounds")

static func sync_viewport_shell_bounds(view) -> void:
	view._viewport_shell_sync_pending = false
	if not view.is_inside_tree():
		return
	var viewport_size: Vector2 = view.get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	view._last_viewport_shell_size = viewport_size
	view.custom_minimum_size = Vector2.ZERO
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.clip_contents = true
	view._queue_shared_backpack_layout_sync()
	if view.reward_panel != null and view.reward_panel.visible:
		view._queue_reward_board_layout_sync()

static func input(view, event: InputEvent) -> void:
	if not (view._reward_drag_active or view._backpack_drag_active):
		return
	if event is InputEventMouseMotion and view._reward_drag_active:
		view._update_reward_drag_card_position()
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_commit_pointer_release(view)

static func unhandled_input(view, event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		view.key_pressed.emit(event.keycode)

static func _connect_static_signals(view) -> void:
	view.settings_open_button.pressed.connect(func(): view.settings_open_pressed.emit())
	view.confirm_proceed_button.pressed.connect(func(): view.confirm_proceed_pressed.emit())
	view.confirm_cancel_button.pressed.connect(func(): view.confirm_cancel_pressed.emit())
	view.repair_overlay.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			view.repair_overlay_input.emit(ev)
	)
	view.settings_panel.visibility_changed.connect(func():
		view._promote_popup_overlay_when_visible(view.settings_panel)
		view._emit_combat_overlay_pause_visibility_changed()
	)
	view.confirm_overlay.visibility_changed.connect(func(): view._promote_popup_overlay_when_visible(view.confirm_overlay))
	view.repair_overlay.visibility_changed.connect(func(): view._promote_popup_overlay_when_visible(view.repair_overlay))

static func _create_header_buttons(view) -> void:
	view.shop_open_button = Button.new()
	view.shop_open_button.text = TextCatalogScript.t("action.shop")
	view.shop_open_button.disabled = not view.SHOP_ENABLED
	view.shop_open_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN if view.shop_open_button.disabled else Control.CURSOR_POINTING_HAND
	view.shop_open_button.pressed.connect(func(): view.shop_open_pressed.emit())
	view.header_actions.add_child(view.shop_open_button)
	view.codex_open_button = Button.new()
	view.codex_open_button.text = TextCatalogScript.t("action.codex")
	view.codex_open_button.pressed.connect(func(): view.codex_open_pressed.emit())
	view.header_actions.add_child(view.codex_open_button)

static func _commit_pointer_release(view) -> void:
	var mouse_pos: Vector2 = view.get_global_mouse_position()
	var drop_coord: Vector2 = view.backpack_ui.slot_coord_at_global_pos(view.get_global_mouse_position()) if view.backpack_ui != null and view.backpack_ui.has_method("slot_coord_at_global_pos") else Vector2(-1, -1)
	if view._reward_drag_active:
		_finish_reward_drag(view, mouse_pos, drop_coord)
	elif view._backpack_drag_active:
		_finish_backpack_drag(view, drop_coord)

static func _finish_reward_drag(view, mouse_pos: Vector2, drop_coord: Vector2) -> void:
	if drop_coord.x >= 0.0 and drop_coord.y >= 0.0:
		view.reward_meta_drop_requested.emit(view._reward_drag_index, drop_coord)
	elif view.discard_zone != null and view.discard_zone.get_global_rect().has_point(view.get_global_mouse_position()):
		view.reward_meta_discard_requested.emit(view._reward_drag_index)
	elif view.reward_card_grid != null and view.reward_card_grid.get_global_rect().has_point(mouse_pos):
		view._commit_reward_card_manual_anchor(view._reward_drag_index)
		view.reward_meta_drag_canceled.emit(view._reward_drag_index)
	else:
		view.reward_meta_drag_canceled.emit(view._reward_drag_index)
	view._end_reward_drag_tracking()

static func _finish_backpack_drag(view, drop_coord: Vector2) -> void:
	if drop_coord.x >= 0.0 and drop_coord.y >= 0.0:
		view.backpack_slot_drop_requested.emit(view._backpack_drag_origin, drop_coord)
	elif view.discard_zone != null and view.discard_zone.get_global_rect().has_point(view.get_global_mouse_position()):
		view.backpack_slot_discard_requested.emit(view._backpack_drag_origin)
	else:
		view.backpack_slot_drag_canceled.emit(view._backpack_drag_origin)
	view._end_backpack_drag_tracking()
