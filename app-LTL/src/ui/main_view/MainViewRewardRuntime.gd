class_name MainViewRewardRuntime
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const LTLThemeScript = preload("res://src/ui/theme/LTLTheme.gd")
const RewardCardCloudHostScript = preload("res://src/ui/RewardCardCloudHost.gd")

const REWARD_INSPECTOR_FACT_MIN_HEIGHT := 58.0
const REWARD_FOOTPRINT_MIN_COLUMNS := 4
const REWARD_FOOTPRINT_MIN_ROWS := 2
const REWARD_FOOTPRINT_CELL_SIZE := 20.0
const REWARD_FOOTPRINT_CELL_GAP := 6.0

static func render_reward_tray(view, model: Dictionary) -> void:
	var is_boss_reward := str(view._active_surface_bundle_id) == "boss_reward"
	var title_text := str(model.get("title", TextCatalogScript.t("panel.rewards")))
	var subtitle_text := str(model.get("subtitle", ""))
	# [분기] boss_reward 는 modePill 을 강조 배지로 오버라이드한다 (reward.board.mode_pill 원본 값은 변경하지 않음).
	var mode_pill_text := TextCatalogScript.t("main.page.badge.boss_reward") if is_boss_reward else str(model.get("modePill", ""))
	var cloud_note_text := str(model.get("cloudNote", ""))
	var workspace_note_text := str(model.get("workspaceNote", ""))
	view.reward_title.text = title_text
	view.reward_subtitle.text = subtitle_text
	view.reward_mode_pill.text = mode_pill_text
	view.reward_mode_pill.visible = not mode_pill_text.strip_edges().is_empty()
	view.reward_cloud_note.text = cloud_note_text
	view.reward_cloud_note.visible = not cloud_note_text.strip_edges().is_empty()
	view.reward_workspace_note.text = workspace_note_text
	view.reward_workspace_note.visible = not workspace_note_text.strip_edges().is_empty()
	view.claim_card_body.text = str(model.get("claimBody", ""))
	view.claim_inline_button.text = str(model.get("claimButtonText", TextCatalogScript.t("action.claim_rewards")))
	view.update_discard_zone(str(model.get("discardText", "")), bool(model.get("discardActive", false)))
	if is_boss_reward and view.boss_ledger_zone_label != null and view.boss_ledger_value_label != null:
		view.boss_ledger_zone_label.text = TextCatalogScript.t("reward.board.boss_ledger.zone")
		view.boss_ledger_value_label.text = TextCatalogScript.t("main.page.subtitle.boss_reward")
	if is_boss_reward and view.boss_hero_relic != null:
		var relic_badge_label: Label = view.boss_hero_relic.get_node_or_null("RelicBadge") as Label
		if relic_badge_label != null:
			relic_badge_label.text = TextCatalogScript.t("item.relic")
	prune_reward_card_manual_anchors(view, model.get("cards", []))
	render_reward_cards(view, model.get("cards", []))
	render_reward_inspector(view, model.get("inspector", {}))
	view._queue_reward_board_layout_sync()
	view._defer_interaction_fx_install()

static func set_reward_text(view, val: String) -> void:
	view.reward_inspector_summary.text = val

static func render_reward_cards(view, cards: Array) -> void:
	view.reward_card_buttons = RewardCardCloudHostScript.render_cards(
		view.reward_card_grid,
		cards,
		Callable(view, "_wire_reward_card_interactions")
	)
	queue_reward_card_float_layout(view)

static func wire_reward_card_interactions(view, button: Button, index: int) -> void:
	var state := {"pressed": false, "dragging": false, "press_pos": Vector2.ZERO}
	button.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				state["pressed"] = true
				state["dragging"] = false
				state["press_pos"] = event.position
			else:
				var was_pressed := bool(state.get("pressed", false))
				var was_dragging := bool(state.get("dragging", false))
				state["pressed"] = false
				state["dragging"] = false
				if was_pressed and not was_dragging:
					if view.has_method("play_interaction_sfx"):
						view.play_interaction_sfx("item_click")
					view.reward_meta_clicked.emit(index)
		elif event is InputEventMouseMotion and bool(state.get("pressed", false)) and not bool(state.get("dragging", false)):
			var press_pos: Vector2 = state.get("press_pos", Vector2.ZERO)
			if event.position.distance_to(press_pos) >= 10.0:
				state["dragging"] = true
				begin_reward_drag_tracking(view, index, button, press_pos)
				view.reward_meta_drag_started.emit(index)
	)

static func queue_reward_card_float_layout(view) -> void:
	view.call_deferred("_layout_reward_float_cards")

static func reward_card_anchor_bounds(cloud_size: Vector2, card_size: Vector2) -> Rect2:
	return RewardCardCloudHostScript.reward_card_anchor_bounds(cloud_size, card_size)

static func clamp_reward_card_anchor(cloud_size: Vector2, card_size: Vector2, anchor: Vector2) -> Vector2:
	return RewardCardCloudHostScript.clamp_reward_card_anchor(cloud_size, card_size, anchor)

static func prune_reward_card_manual_anchors(view, cards: Array) -> void:
	view._reward_card_manual_anchor_norms = RewardCardCloudHostScript.prune_manual_anchors(cards, view._reward_card_manual_anchor_norms)

static func layout_reward_float_cards(view) -> void:
	RewardCardCloudHostScript.layout_cards(
		view.reward_card_grid,
		view.reward_card_buttons,
		view._reward_card_manual_anchor_norms,
		view.pulse_time
	)

static func apply_reward_card_idle_transform(view, button: Control) -> void:
	RewardCardCloudHostScript.apply_idle_transform(button, view.pulse_time, view._reward_drag_active, view._reward_drag_button)

static func begin_reward_drag_tracking(view, index: int, button: Control, pointer_offset: Vector2) -> void:
	view._reward_drag_index = index
	view._reward_drag_active = true
	view._reward_drag_button = button
	view._reward_drag_pointer_offset = pointer_offset
	if view.has_method("play_interaction_sfx"):
		view.play_interaction_sfx("drag_start")
	if view._reward_drag_button != null:
		view._reward_drag_button.z_index = 8
		update_reward_drag_card_position(view)

static func end_reward_drag_tracking(view) -> void:
	if view._reward_drag_button != null and is_instance_valid(view._reward_drag_button):
		view._reward_drag_button.z_index = 0
	view._reward_drag_button = null
	view._reward_drag_pointer_offset = Vector2.ZERO
	view._reward_drag_index = -1
	view._reward_drag_active = false

static func update_reward_drag_card_position(view) -> void:
	RewardCardCloudHostScript.update_drag_card_position(
		view.reward_card_grid,
		view._reward_drag_button,
		view._reward_drag_pointer_offset,
		view.get_global_mouse_position()
	)

static func commit_reward_card_manual_anchor(view, index: int) -> void:
	view._reward_card_manual_anchor_norms = RewardCardCloudHostScript.commit_manual_anchor(
		view.reward_card_grid,
		view._reward_drag_button,
		index,
		view._reward_card_manual_anchor_norms
	)

static func begin_backpack_drag_tracking(view, origin_coord: Vector2) -> void:
	view._backpack_drag_origin = origin_coord
	view._backpack_drag_active = true
	if view.has_method("play_interaction_sfx"):
		view.play_interaction_sfx("drag_start")

static func end_backpack_drag_tracking(view) -> void:
	view._backpack_drag_origin = Vector2(-1, -1)
	view._backpack_drag_active = false

static func render_reward_inspector(view, inspector: Dictionary) -> void:
	var empty := bool(inspector.get("empty", true))
	view.reward_inspector_kicker.text = str(inspector.get("kicker", ""))
	view.reward_inspector_name.text = "" if empty else str(inspector.get("name", ""))
	view.reward_inspector_summary.text = str(inspector.get("summary", ""))
	view.reward_inspector_summary.visible = true
	render_reward_inspector_facts(view, inspector.get("facts", []))
	view.reward_footprint_title.text = str(inspector.get("shapeTitle", ""))
	var footprint_parts := PackedStringArray()
	var footprint_text := str(inspector.get("shapeFootprintText", "")).strip_edges()
	var cell_text := str(inspector.get("shapeCellCountText", "")).strip_edges()
	if not footprint_text.is_empty():
		footprint_parts.append(footprint_text)
	if not cell_text.is_empty():
		footprint_parts.append(cell_text)
	view.reward_footprint_info.text = "\n".join(footprint_parts)
	render_reward_footprint(view, inspector.get("shapeMatrix", []), str(inspector.get("shapeEnergyType", "")), str(inspector.get("shapeItemType", "")))

static func render_reward_inspector_facts(view, facts: Array) -> void:
	clear_dynamic_children(view.reward_inspector_facts)
	view.reward_inspector_facts.columns = 1
	var row := new_reward_fact_row()
	for fact in facts:
		if not (fact is Dictionary):
			continue
		var tile := build_reward_fact_tile(fact)
		if int(fact.get("layoutColumns", 1)) >= 2:
			if row.get_child_count() > 0:
				view.reward_inspector_facts.add_child(row)
				row = new_reward_fact_row()
			view.reward_inspector_facts.add_child(tile)
			continue
		row.add_child(tile)
		if row.get_child_count() >= 2:
			view.reward_inspector_facts.add_child(row)
			row = new_reward_fact_row()
	if row.get_child_count() > 0:
		view.reward_inspector_facts.add_child(row)

static func new_reward_fact_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	return row

static func build_reward_fact_tile(fact: Dictionary) -> PanelContainer:
	var tile := PanelContainer.new()
	tile.custom_minimum_size.y = REWARD_INSPECTOR_FACT_MIN_HEIGHT
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.add_theme_stylebox_override("panel", LTLThemeScript.ledger_card_style())
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	tile.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	var label := Label.new()
	label.text = str(fact.get("label", ""))
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", LTLThemeScript.ON_SURFACE_VARIANT)
	box.add_child(label)
	var value := Label.new()
	value.text = str(fact.get("value", ""))
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.add_theme_font_size_override("font_size", 12)
	value.add_theme_color_override("font_color", LTLThemeScript.ON_SURFACE)
	box.add_child(value)
	return tile

static func render_reward_footprint(view, shape_matrix: Array, energy_type: String, item_type: String) -> void:
	clear_dynamic_children(view.reward_footprint_grid)
	var normalized_shape: Array = []
	if shape_matrix is Array:
		normalized_shape = shape_matrix
	var layout: Dictionary = reward_footprint_layout_policy(normalized_shape)
	var columns := int(layout.get("columns", REWARD_FOOTPRINT_MIN_COLUMNS))
	var rows := int(layout.get("rows", REWARD_FOOTPRINT_MIN_ROWS))
	view.reward_footprint_grid.columns = columns
	view.reward_footprint_grid.custom_minimum_size = Vector2(
		float(columns) * REWARD_FOOTPRINT_CELL_SIZE + float(maxi(0, columns - 1)) * REWARD_FOOTPRINT_CELL_GAP,
		float(rows) * REWARD_FOOTPRINT_CELL_SIZE + float(maxi(0, rows - 1)) * REWARD_FOOTPRINT_CELL_GAP
	)
	var fill_color := reward_footprint_fill_color(energy_type, item_type)
	for row_index in range(rows):
		var row_data: Array = []
		if row_index < normalized_shape.size() and normalized_shape[row_index] is Array:
			row_data = normalized_shape[row_index]
		for column_index in range(columns):
			var tile := Panel.new()
			tile.custom_minimum_size = Vector2(REWARD_FOOTPRINT_CELL_SIZE, REWARD_FOOTPRINT_CELL_SIZE)
			var active := column_index < row_data.size() and int(row_data[column_index]) != 0
			tile.add_theme_stylebox_override("panel", LTLThemeScript.surface_style(
				fill_color if active else LTLThemeScript.SURFACE_CONTAINER_LOW,
				LTLThemeScript.OUTLINE_VARIANT,
				6,
				1,
				0.0
			))
			view.reward_footprint_grid.add_child(tile)

static func reward_footprint_layout_policy(shape_matrix: Array) -> Dictionary:
	var width := 0
	var height := 0
	for row in shape_matrix:
		if row is Array:
			height += 1
			width = maxi(width, row.size())
	return {
		"columns": maxi(REWARD_FOOTPRINT_MIN_COLUMNS, width),
		"rows": maxi(REWARD_FOOTPRINT_MIN_ROWS, height)
	}

static func reward_footprint_fill_color(energy_type: String, item_type: String) -> Color:
	if item_type == "relic":
		return Color(0.88, 0.72, 0.40, 0.98)
	match energy_type:
		"red":
			return Color(0.86, 0.31, 0.29, 0.98)
		"blue":
			return Color(0.35, 0.57, 0.90, 0.98)
		"green":
			return Color(0.36, 0.73, 0.42, 0.98)
		"purple":
			return Color(0.69, 0.42, 0.89, 0.98)
	return Color(0.63, 0.69, 0.76, 0.98)

static func clear_dynamic_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
