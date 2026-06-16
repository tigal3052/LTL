class_name MainViewFeedbackRuntime
extends RefCounted

static func set_confirm_overlay_visible(view, val: bool) -> void:
	view.confirm_overlay.visible = val

static func add_log(view, message: String) -> void:
	for bundle in view.page_shell_bundles.values():
		var console = bundle.get("logConsole", null)
		if console != null and console.has_method("add_log"):
			console.add_log(message)

static func update_discard_zone(view, label_text: String, is_active: bool) -> void:
	view.discard_label.text = label_text
	view.discard_zone.self_modulate = Color.WHITE if is_active else Color(0.82, 0.82, 0.82, 0.78)

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

static func trigger_screenshake(view, duration: float, magnitude: float) -> void:
	view.vfx_manager.trigger_screenshake(duration, magnitude, view)
