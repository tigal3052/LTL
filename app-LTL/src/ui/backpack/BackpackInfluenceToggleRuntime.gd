extends RefCounted

static func setup(owner) -> void:
	if owner.influence_preview_toggle_button != null:
		return
	owner.influence_preview_toggle_button = CheckButton.new()
	var toggle: CheckButton = owner.influence_preview_toggle_button
	toggle.name = "InfluencePreviewToggle"
	toggle.text = "범위"
	toggle.tooltip_text = "영향 범위 표시"
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.top_level = true
	toggle.mouse_filter = Control.MOUSE_FILTER_STOP
	toggle.button_pressed = owner.influence_preview_enabled
	toggle.custom_minimum_size = Vector2(72, 28)
	toggle.size = toggle.custom_minimum_size
	toggle.z_index = 32
	toggle.visible = owner.influence_preview_toggle_visible
	toggle.toggled.connect(func(enabled: bool): owner.set_influence_preview_enabled(enabled))
	owner.add_child(toggle)
	position(owner)

static func position(owner) -> void:
	if owner.influence_preview_toggle_button == null:
		return
	var anchor_rect: Rect2 = _anchor_rect(owner)
	if anchor_rect.size.x <= 1.0 or anchor_rect.size.y <= 1.0:
		return
	var toggle_size: Vector2 = _toggle_size(owner)
	owner.influence_preview_toggle_button.size = toggle_size
	var target_x := maxf(anchor_rect.position.x + 4.0, anchor_rect.end.x - toggle_size.x - 2.0)
	var target_y := anchor_rect.position.y + (anchor_rect.size.y - toggle_size.y) * 0.5
	owner.influence_preview_toggle_button.global_position = Vector2(target_x, target_y)

static func _anchor_rect(owner) -> Rect2:
	var anchor: Control = owner.influence_preview_toggle_anchor_control
	if anchor != null and is_instance_valid(anchor) and anchor.visible:
		var anchor_rect := anchor.get_global_rect()
		if anchor_rect.size.x > 1.0 and anchor_rect.size.y > 1.0:
			return anchor_rect
	var title := owner.get_node_or_null("Margin/EngineBox/EngineTitle") as Control
	if title != null and title.visible:
		var title_rect := title.get_global_rect()
		if title_rect.size.x > 1.0 and title_rect.size.y > 1.0:
			return title_rect
	var panel_rect: Rect2 = owner.get_global_rect()
	if panel_rect.size.x <= 1.0 or panel_rect.size.y <= 1.0:
		return Rect2()
	var toggle_size: Vector2 = _toggle_size(owner)
	return Rect2(panel_rect.position + Vector2(0.0, 8.0), Vector2(panel_rect.size.x, maxf(toggle_size.y, 28.0)))

static func _toggle_size(owner) -> Vector2:
	var toggle_size: Vector2 = owner.influence_preview_toggle_button.get_combined_minimum_size()
	toggle_size.x = maxf(maxf(toggle_size.x, owner.influence_preview_toggle_button.custom_minimum_size.x), 72.0)
	toggle_size.y = maxf(maxf(toggle_size.y, owner.influence_preview_toggle_button.custom_minimum_size.y), 28.0)
	return toggle_size
