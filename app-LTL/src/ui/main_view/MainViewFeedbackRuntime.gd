class_name MainViewFeedbackRuntime
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

static func set_confirm_overlay_visible(view, val: bool) -> void:
	if val:
		_apply_confirm_overlay_copy(view)
	var changed: bool = view.confirm_overlay.visible != val
	view.confirm_overlay.visible = val
	if not val:
		view.confirm_overlay_mode = "unclaimed"
		view.confirm_overlay_subject = ""
	if changed and view.has_method("play_interaction_sfx"):
		view.play_interaction_sfx("menu_open" if val else "menu_close")

static func show_unclaimed_reward_confirmation(view) -> void:
	view.confirm_overlay_mode = "unclaimed"
	view.confirm_overlay_subject = ""
	set_confirm_overlay_visible(view, true)

static func show_discard_confirmation(view, artifact_name: String) -> void:
	view.confirm_overlay_mode = "discard"
	view.confirm_overlay_subject = artifact_name
	set_confirm_overlay_visible(view, true)

static func show_info_toast(view, message: String, duration_seconds: float = 5.0) -> void:
	_ensure_info_toast(view)
	if view.info_toast_panel == null or view.info_toast_label == null:
		return
	view.info_toast_label.text = message
	if view.info_toast_hint_label != null:
		view.info_toast_hint_label.text = "0초 뒤 사라집니다."
	view.info_toast_panel.visible = true
	_layout_info_toast(view)
	if view.info_toast_timer != null:
		view.info_toast_timer.stop()
		view.info_toast_timer.wait_time = maxf(0.01, duration_seconds)
		view.info_toast_timer.start()

static func hide_info_toast(view) -> void:
	if view.info_toast_timer != null:
		view.info_toast_timer.stop()
	if view.info_toast_panel != null:
		view.info_toast_panel.visible = false

static func add_log(view, message: String) -> void:
	for bundle in view.page_shell_bundles.values():
		var console = bundle.get("logConsole", null)
		if console != null and console.has_method("add_log"):
			console.add_log(message)

static func update_discard_zone(view, label_text: String, is_active: bool) -> void:
	view.discard_label.text = label_text
	view.discard_zone.self_modulate = Color.WHITE if is_active else Color(0.82, 0.82, 0.82, 0.78)

static func _apply_confirm_overlay_copy(view) -> void:
	var title := TextCatalogScript.t("confirm.unclaimed.title")
	var desc := TextCatalogScript.t("confirm.unclaimed.desc")
	if str(view.confirm_overlay_mode) == "discard":
		title = TextCatalogScript.t("confirm.discard.title")
		desc = TextCatalogScript.t("confirm.discard.desc", [str(view.confirm_overlay_subject)])
	_set_confirm_label_text(view, "WarningTitle", title)
	_set_confirm_label_text(view, "WarningLabel", title)
	_set_confirm_label_text(view, "WarningDescription", desc)
	_set_confirm_label_text(view, "DescriptionLabel", desc)
	view.confirm_proceed_button.text = TextCatalogScript.t("action.confirm" if str(view.confirm_overlay_mode) == "discard" else "action.proceed")
	view.confirm_cancel_button.text = TextCatalogScript.t("action.cancel")

static func _set_confirm_label_text(view, node_name: String, text: String) -> void:
	var node := view.confirm_overlay.get_node_or_null("Center/ConfirmBox/%s" % node_name) as Label
	if node != null:
		node.text = text

static func _ensure_info_toast(view) -> void:
	if view.info_toast_panel != null:
		return
	var panel := Panel.new()
	panel.name = "InfoToast"
	panel.visible = false
	panel.top_level = true
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.z_index = view.popup_overlay_z_index()
	panel.add_theme_stylebox_override("panel", _toast_style())
	panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			MainViewFeedbackRuntime.hide_info_toast(view)
	)
	var label := Label.new()
	label.name = "ToastLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.z_index = 1
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.86, 1.0))
	panel.add_child(label)
	var hint_label := Label.new()
	hint_label.name = "ToastHintLabel"
	hint_label.text = "0초 뒤 사라집니다."
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.z_index = 1
	hint_label.add_theme_font_size_override("font_size", 11)
	hint_label.add_theme_color_override("font_color", Color(0.96, 0.86, 0.66, 0.88))
	panel.add_child(hint_label)
	var timer := Timer.new()
	timer.one_shot = true
	timer.timeout.connect(func():
		MainViewFeedbackRuntime.hide_info_toast(view)
	)
	if view.is_inside_tree():
		view.get_tree().root.add_child(panel)
		var cleanup := func() -> void:
			if is_instance_valid(panel):
				panel.queue_free()
		view.tree_exiting.connect(cleanup, CONNECT_ONE_SHOT)
	else:
		view.add_child(panel)
	view.add_child(timer)
	view.info_toast_panel = panel
	view.info_toast_label = label
	view.info_toast_hint_label = hint_label
	view.info_toast_timer = timer

static func _layout_info_toast(view) -> void:
	if view.info_toast_panel == null:
		return
	var viewport_size: Vector2 = view.get_viewport_rect().size if view.is_inside_tree() else view.size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		viewport_size = Vector2(1440, 900)
	var toast_size := Vector2(clampf(viewport_size.x * 0.34, 320.0, 560.0), 96.0)
	view.info_toast_panel.size = toast_size
	view.info_toast_panel.global_position = (viewport_size - toast_size) * 0.5
	if view.info_toast_label != null:
		view.info_toast_label.position = Vector2(18.0, 12.0)
		view.info_toast_label.size = Vector2(toast_size.x - 36.0, 48.0)
	if view.info_toast_hint_label != null:
		view.info_toast_hint_label.position = Vector2(18.0, 68.0)
		view.info_toast_hint_label.size = Vector2(toast_size.x - 36.0, 16.0)

static func _toast_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.12, 0.15, 0.94)
	style.border_color = Color(0.84, 0.67, 0.36, 0.90)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style

static func get_cell_global_pos(view, cell_id: String) -> Vector2:
	var hit_pos = view.global_position + view.size / 2
	for child in view.battlefield_ui.battlefield_grid.get_children():
		if child is CellView and child.cell_id == cell_id:
			hit_pos = child.global_position + child.size / 2
			break
	return hit_pos

static func get_extractor_global_pos(view) -> Vector2:
	return view.status_panel.extractor_visual.global_position + view.status_panel.extractor_visual.size / 2

static func get_health_bar_global_pos(view) -> Vector2:
	return view.status_panel.health_bar.global_position + Vector2(view.status_panel.health_bar.size.x * 0.58, -4.0)

static func get_shield_bar_global_pos(view) -> Vector2:
	return view.status_panel.shield_bar.global_position + Vector2(view.status_panel.shield_bar.size.x * 0.58, -4.0)

static func get_timer_global_pos(view) -> Vector2:
	return view.status_panel.combat_timer_label.global_position + Vector2(view.status_panel.combat_timer_label.size.x * 0.5, -4.0)

static func get_purple_status_global_pos(view) -> Vector2:
	return view.status_panel.purple_status_value.global_position + Vector2(view.status_panel.purple_status_value.size.x * 0.5, -4.0)

static func trigger_resonance_beam(view, start_pos: Vector2, hit_pos: Vector2, color: String) -> void:
	view.vfx_manager.draw_resonance_beam(start_pos, hit_pos, color)

static func trigger_hit_particles(view, hit_pos: Vector2, status: String, color: String) -> void:
	view.vfx_manager.spawn_hit_particles(hit_pos, status, color)

static func trigger_damage_popups(view, events: Array) -> void:
	if events.is_empty():
		return
	var anchored_events: Array = []
	for event in events:
		if not event is Dictionary:
			continue
		var popup: Dictionary = event.duplicate(true)
		var channel := str(popup.get("channel", ""))
		popup["origin"] = get_shield_bar_global_pos(view) if channel == "shield" else get_health_bar_global_pos(view)
		anchored_events.append(popup)
	view.vfx_manager.spawn_damage_popups(anchored_events)

static func trigger_obstacle_feedback(view, events: Array) -> void:
	if events.is_empty():
		return
	var popup_events: Array = []
	for event in events:
		if not event is Dictionary:
			continue
		var family := str(event.get("family", ""))
		if view.battlefield_ui != null and view.battlefield_ui.has_method("trigger_obstacle_flash"):
			view.battlefield_ui.trigger_obstacle_flash(family)
		if not bool(event.get("popup", true)):
			continue
		var popup: Dictionary = event.duplicate(true)
		match str(popup.get("channel", "")):
			"timer":
				popup["origin"] = get_timer_global_pos(view)
			"purple_debuff":
				popup["origin"] = get_purple_status_global_pos(view)
			_:
				popup["origin"] = get_health_bar_global_pos(view)
		popup_events.append(popup)
	if not popup_events.is_empty():
		view.vfx_manager.spawn_obstacle_feedback(popup_events)

static func trigger_screenshake(view, duration: float, magnitude: float) -> void:
	view.vfx_manager.trigger_screenshake(duration, magnitude, view)
