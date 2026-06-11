class_name RewardCardCloudHost
extends RefCounted

const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const FLOAT_EDGE_PADDING := 9.0
const SEEDED_POSITIONS := [
	Vector2(0.06, 0.08),
	Vector2(0.56, 0.12),
	Vector2(0.22, 0.34),
	Vector2(0.68, 0.42),
	Vector2(0.10, 0.62),
	Vector2(0.48, 0.68),
	Vector2(0.74, 0.62)
]

static func render_cards(reward_card_grid: Control, cards: Array, on_wire_card_interactions: Callable = Callable()) -> Array:
	if reward_card_grid == null:
		return []
	_clear_dynamic_children(reward_card_grid)
	var reward_card_buttons: Array = []
	for card in cards:
		if not (card is Dictionary):
			continue
		var button := _build_reward_card_button(card, on_wire_card_interactions)
		if button == null:
			continue
		reward_card_grid.add_child(button)
		reward_card_buttons.append(button)
	return reward_card_buttons

static func reward_card_anchor_bounds(cloud_size: Vector2, card_size: Vector2, edge_padding: float = FLOAT_EDGE_PADDING) -> Rect2:
	var usable := Vector2(
		maxf(0.0, cloud_size.x - card_size.x - edge_padding * 2.0),
		maxf(0.0, cloud_size.y - card_size.y - edge_padding * 2.0)
	)
	return Rect2(Vector2(edge_padding, edge_padding), usable)

static func clamp_reward_card_anchor(cloud_size: Vector2, card_size: Vector2, anchor: Vector2, edge_padding: float = FLOAT_EDGE_PADDING) -> Vector2:
	var bounds := reward_card_anchor_bounds(cloud_size, card_size, edge_padding)
	return Vector2(
		clampf(anchor.x, bounds.position.x, bounds.position.x + bounds.size.x),
		clampf(anchor.y, bounds.position.y, bounds.position.y + bounds.size.y)
	)

static func prune_manual_anchors(cards: Array, manual_anchor_norms: Dictionary) -> Dictionary:
	var active_indices: Dictionary = {}
	for card in cards:
		if card is Dictionary:
			active_indices[int(card.get("index", -1))] = true
	var pruned := manual_anchor_norms.duplicate()
	for key in manual_anchor_norms.keys():
		var index := int(key)
		if not active_indices.has(index):
			pruned.erase(key)
	return pruned

static func layout_cards(reward_card_grid: Control, reward_card_buttons: Array, manual_anchor_norms: Dictionary, pulse_time: float = 0.0) -> void:
	if reward_card_grid == null or reward_card_buttons.is_empty():
		return
	var cloud_size := reward_card_grid.size
	if cloud_size.x <= 1.0 or cloud_size.y <= 1.0:
		cloud_size = reward_card_grid.custom_minimum_size
	var card_edge := clampf(minf(cloud_size.x * 0.27, cloud_size.y * 0.34), 98.0, 132.0)
	var card_size := Vector2(card_edge, card_edge)
	var usable := Vector2(
		maxf(0.0, cloud_size.x - card_size.x - FLOAT_EDGE_PADDING * 2.0),
		maxf(0.0, cloud_size.y - card_size.y - FLOAT_EDGE_PADDING * 2.0)
	)
	var placement_rects: Array[Rect2] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = int(cloud_size.x * 1003.0 + cloud_size.y * 917.0 + reward_card_buttons.size() * 67.0)
	for index in range(reward_card_buttons.size()):
		var button := reward_card_buttons[index] as Control
		if button == null:
			continue
		var card_index := int(button.get_meta("reward_card_index", index))
		button.size = card_size
		button.pivot_offset = card_size * 0.5
		var manual_norm: Variant = manual_anchor_norms.get(card_index, null)
		var anchor := Vector2.ZERO
		var placed := false
		if manual_norm is Vector2:
			anchor = _reward_card_anchor_from_norm(cloud_size, card_size, manual_norm)
			placement_rects.append(Rect2(anchor, card_size).grow(6.0))
			placed = true
		else:
			for attempt in range(18):
				var norm: Vector2 = SEEDED_POSITIONS[(index + attempt) % SEEDED_POSITIONS.size()]
				if attempt >= SEEDED_POSITIONS.size():
					norm = Vector2(rng.randf_range(0.04, 0.78), rng.randf_range(0.06, 0.72))
				var candidate := Vector2(
					FLOAT_EDGE_PADDING + usable.x * norm.x,
					FLOAT_EDGE_PADDING + usable.y * norm.y
				)
				var candidate_rect := Rect2(candidate, card_size).grow(10.0)
				var collides := false
				for used_rect in placement_rects:
					if used_rect.intersects(candidate_rect):
						collides = true
						break
				if collides:
					continue
				anchor = candidate
				placement_rects.append(candidate_rect)
				placed = true
				break
		if not placed:
			anchor = clamp_reward_card_anchor(
				cloud_size,
				card_size,
				Vector2(
					FLOAT_EDGE_PADDING + usable.x * float(index % 3) / maxf(1.0, minf(2.0, float(reward_card_buttons.size() - 1))),
					FLOAT_EDGE_PADDING + usable.y * float(index / 3) / maxf(1.0, ceil(float(reward_card_buttons.size()) / 3.0) - 1.0)
				)
			)
			placement_rects.append(Rect2(anchor, card_size).grow(6.0))
		button.set_meta("float_anchor", anchor)
		button.set_meta("float_phase", rng.randf_range(0.0, TAU))
		button.set_meta("float_speed", rng.randf_range(0.72, 1.14))
		button.set_meta("float_amplitude", Vector2(rng.randf_range(2.0, 5.0), rng.randf_range(4.0, 8.0)))
		button.set_meta("float_rotation", rng.randf_range(-5.0, 5.0))
		apply_idle_transform(button, pulse_time, false, null)

static func apply_idle_transform(button: Control, pulse_time: float, reward_drag_active: bool, reward_drag_button: Control) -> void:
	if button == null:
		return
	if reward_drag_active and button == reward_drag_button:
		return
	var anchor: Vector2 = button.get_meta("float_anchor", button.position)
	var phase := float(button.get_meta("float_phase", 0.0))
	var speed := float(button.get_meta("float_speed", 1.0))
	var amplitude: Vector2 = button.get_meta("float_amplitude", Vector2(3.0, 6.0))
	var base_rotation := float(button.get_meta("float_rotation", 0.0))
	var offset := Vector2(
		sin(pulse_time * speed + phase) * amplitude.x,
		cos(pulse_time * speed * 0.82 + phase) * amplitude.y
	)
	button.position = anchor + offset
	button.rotation_degrees = base_rotation + sin(pulse_time * speed * 0.66 + phase) * 1.8

static func update_drag_card_position(reward_card_grid: Control, reward_drag_button: Control, reward_drag_pointer_offset: Vector2, global_mouse_position: Vector2) -> void:
	if reward_card_grid == null or reward_drag_button == null or not is_instance_valid(reward_drag_button):
		return
	var local_mouse := global_mouse_position - reward_card_grid.global_position
	var anchor := clamp_reward_card_anchor(
		reward_card_grid.size,
		reward_drag_button.size,
		local_mouse - reward_drag_pointer_offset
	)
	reward_drag_button.position = anchor
	reward_drag_button.rotation_degrees = 0.0

static func commit_manual_anchor(reward_card_grid: Control, reward_drag_button: Control, index: int, manual_anchor_norms: Dictionary) -> Dictionary:
	if reward_card_grid == null or reward_drag_button == null or not is_instance_valid(reward_drag_button):
		return manual_anchor_norms
	var updated := manual_anchor_norms.duplicate()
	var anchor := clamp_reward_card_anchor(reward_card_grid.size, reward_drag_button.size, reward_drag_button.position)
	reward_drag_button.position = anchor
	updated[index] = _reward_card_anchor_to_norm(reward_card_grid.size, reward_drag_button.size, anchor)
	return updated

static func _build_reward_card_button(card: Dictionary, on_wire_card_interactions: Callable) -> Button:
	var button := Button.new()
	button.text = ""
	button.clip_contents = false
	button.custom_minimum_size = Vector2(122, 122)
	button.focus_mode = Control.FOCUS_NONE
	button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta(InteractionFXScript.META_SKIP, true)
	var rarity := str(card.get("rarity", "common"))
	var selected := bool(card.get("selected", false))
	var normal := LTLThemeScript.surface_style(Color(0.22, 0.28, 0.36, 0.98), _reward_rarity_border_color(rarity), 24, 1, 0.30)
	if selected:
		normal.border_width_left = 2
		normal.border_width_top = 2
		normal.border_width_right = 2
		normal.border_width_bottom = 2
		normal.bg_color = Color(0.24, 0.20, 0.11, 0.98)
	var hover = normal.duplicate()
	var pressed = normal.duplicate()
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	var index := int(card.get("index", -1))
	button.set_meta("reward_card_index", index)
	if on_wire_card_interactions.is_valid():
		on_wire_card_interactions.call(button, index)
	button.pivot_offset = button.custom_minimum_size * 0.5
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	button.add_child(margin)
	var body := VBoxContainer.new()
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 8)
	margin.add_child(body)
	var icon_shell := PanelContainer.new()
	icon_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_shell.custom_minimum_size = Vector2(0, 62)
	icon_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_shell.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(Color(0.29, 0.34, 0.41, 0.92), Color(0.44, 0.50, 0.58, 1.0), 18, 1, 0.12))
	body.add_child(icon_shell)
	var icon_center := CenterContainer.new()
	icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_shell.add_child(icon_center)
	var icon_texture := TextureRect.new()
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_texture.custom_minimum_size = Vector2(42, 42)
	icon_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var art: Dictionary = card.get("art", {})
	icon_texture.texture = LTLThemeScript.art_texture(str(art.get("path", "")))
	if icon_texture.texture == null:
		icon_texture.self_modulate = _reward_rarity_border_color(rarity)
	icon_center.add_child(icon_texture)
	var name_label := Label.new()
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.text = str(card.get("name", ""))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", LTLThemeScript.TEXT_PRIMARY)
	body.add_child(name_label)
	return button

static func _reward_card_anchor_from_norm(cloud_size: Vector2, card_size: Vector2, normalized: Vector2) -> Vector2:
	var bounds := reward_card_anchor_bounds(cloud_size, card_size)
	var safe_norm := Vector2(clampf(normalized.x, 0.0, 1.0), clampf(normalized.y, 0.0, 1.0))
	return bounds.position + Vector2(bounds.size.x * safe_norm.x, bounds.size.y * safe_norm.y)

static func _reward_card_anchor_to_norm(cloud_size: Vector2, card_size: Vector2, anchor: Vector2) -> Vector2:
	var bounds := reward_card_anchor_bounds(cloud_size, card_size)
	var clamped := clamp_reward_card_anchor(cloud_size, card_size, anchor)
	return Vector2(
		0.0 if bounds.size.x <= 0.0 else (clamped.x - bounds.position.x) / bounds.size.x,
		0.0 if bounds.size.y <= 0.0 else (clamped.y - bounds.position.y) / bounds.size.y
	)

static func _reward_rarity_border_color(rarity: String) -> Color:
	match rarity:
		"rare":
			return Color(0.39, 0.69, 0.95, 1.0)
		"epic":
			return Color(0.77, 0.47, 0.92, 1.0)
		"legendary":
			return Color(0.93, 0.78, 0.41, 1.0)
		"mythic":
			return Color(0.90, 0.58, 0.34, 1.0)
	return Color(0.56, 0.77, 0.54, 1.0)

static func _clear_dynamic_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
