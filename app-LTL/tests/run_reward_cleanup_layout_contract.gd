extends SceneTree

const StatusPanelUIScript = preload("res://src/ui/StatusPanelUI.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)

	var status_panel = _build_status_panel()
	host.add_child(status_panel)
	await process_frame
	await process_frame

	var combat_scene := {
		"phase": "combat",
		"hud": {
			"queue": {
				"items": [
					{"color": "red"},
					{"color": "blue"},
					{"color": "green"},
					{"color": "purple"},
					{"color": "red"},
					{"color": "blue"},
					{"color": "green"},
					{"color": "purple"}
				],
				"capacity": 16,
				"loaded": 8
			},
			"pin": {"active": false, "progress": 100, "turnsRemaining": 4},
			"repair": {"active": false, "available": true, "progress": 0, "threshold": 3},
			"hazard": {"severity": "stable"},
			"purplePressure": {"stackCount": 0, "buffCount": 0, "active": false}
		},
		"targetPanel": {"health": 4.0, "maxHealth": 4.0, "shield": 2.0, "maxShield": 2.0}
	}

	status_panel.render_visual_queue(combat_scene)
	_assert_eq(status_panel.visual_queue_box.get_child_count(), 16, "first combat queue render creates exactly one 16-slot grid")

	status_panel.render_visual_queue(combat_scene)
	status_panel.render_visual_queue(combat_scene)
	status_panel.render_visual_queue(combat_scene)
	_assert_eq(status_panel.visual_queue_box.get_child_count(), 16, "repeated same-frame queue renders keep exactly one child per slot instead of accumulating stale gems")

	await process_frame
	_assert_eq(status_panel.visual_queue_box.get_child_count(), 16, "queue render still resolves to sixteen live gems after deferred cleanup")
	_assert(status_panel.get_node_or_null("Margin/StatusBox/PurpleStatusRow") == null, "purple status row no longer sits directly in the status VBox flow")
	var purple_row = status_panel.get_node_or_null("Margin/StatusBox/StatusFooterSpacer/PurpleStatusRow") as HBoxContainer
	_assert(purple_row != null, "purple status row now lives inside the footer spacer overlay lane")
	var collapsed_min_height: float = status_panel.get_combined_minimum_size().y
	status_panel.call("_render_pin_and_repair_status", combat_scene.get("hud", {}))
	await process_frame
	_assert(not bool(purple_row.visible), "purple status row stays hidden when no purple pressure is active")
	var no_purple_min_height: float = status_panel.get_combined_minimum_size().y
	var purple_scene := combat_scene.duplicate(true)
	purple_scene["hud"]["purplePressure"] = {"stackCount": 0, "buffCount": 2, "active": true}
	status_panel.call("_render_pin_and_repair_status", purple_scene.get("hud", {}))
	await process_frame
	_assert(bool(purple_row.visible), "purple status row becomes visible when purple pressure buff text exists")
	_assert_eq(status_panel.get_combined_minimum_size().y, no_purple_min_height, "purple status row overlay does not grow the status panel minimum height when it appears")
	_assert_eq(status_panel.get_combined_minimum_size().y, collapsed_min_height, "purple status row overlay preserves the same minimum height before and after combat-state rerenders")

	_finish()

func _build_status_panel():
	var status_panel = StatusPanelUIScript.new()
	status_panel.name = "StatusPanel"

	var margin := MarginContainer.new()
	margin.name = "Margin"
	status_panel.add_child(margin)

	var status_box := VBoxContainer.new()
	status_box.name = "StatusBox"
	margin.add_child(status_box)

	var node_row := HBoxContainer.new()
	node_row.name = "NodeRow"
	status_box.add_child(node_row)
	var extractor_visual := Panel.new()
	extractor_visual.name = "ExtractorVisual"
	node_row.add_child(extractor_visual)
	var extractor_label := Label.new()
	extractor_label.name = "ExtractorLabel"
	node_row.add_child(extractor_label)

	var hp_box := HBoxContainer.new()
	hp_box.name = "HPBox"
	status_box.add_child(hp_box)
	var health_bar := ProgressBar.new()
	health_bar.name = "HealthBar"
	hp_box.add_child(health_bar)

	var shield_box := HBoxContainer.new()
	shield_box.name = "ShieldBox"
	status_box.add_child(shield_box)
	var shield_bar := ProgressBar.new()
	shield_bar.name = "ShieldBar"
	shield_box.add_child(shield_bar)

	var queue_row := HBoxContainer.new()
	queue_row.name = "QueueRow"
	status_box.add_child(queue_row)
	var visual_queue_box := GridContainer.new()
	visual_queue_box.name = "VisualQueueBox"
	queue_row.add_child(visual_queue_box)

	var timer_row := HBoxContainer.new()
	timer_row.name = "TimerRow"
	status_box.add_child(timer_row)
	var pin_label := Label.new()
	pin_label.name = "PinLabel"
	timer_row.add_child(pin_label)
	var pin_progress_bar := ProgressBar.new()
	pin_progress_bar.name = "PinProgressBar"
	timer_row.add_child(pin_progress_bar)

	var drill_status_row := HBoxContainer.new()
	drill_status_row.name = "DrillStatusRow"
	status_box.add_child(drill_status_row)
	var repair_status_label := Label.new()
	repair_status_label.name = "RepairStatusLabel"
	drill_status_row.add_child(repair_status_label)

	var footer_spacer := Control.new()
	footer_spacer.name = "StatusFooterSpacer"
	status_box.add_child(footer_spacer)
	var purple_status_row := HBoxContainer.new()
	purple_status_row.name = "PurpleStatusRow"
	footer_spacer.add_child(purple_status_row)
	var purple_status_label := Label.new()
	purple_status_label.name = "PurpleStatusLabel"
	purple_status_row.add_child(purple_status_label)
	var purple_status_value := Label.new()
	purple_status_value.name = "PurpleStatusValue"
	purple_status_row.add_child(purple_status_value)

	var footer_margin := MarginContainer.new()
	footer_margin.name = "CombatTimerFooterMargin"
	status_box.add_child(footer_margin)
	var footer := HBoxContainer.new()
	footer.name = "CombatTimerFooter"
	footer_margin.add_child(footer)
	var combat_timer_label := Label.new()
	combat_timer_label.name = "CombatTimerLabel"
	footer.add_child(combat_timer_label)

	return status_panel

func _finish() -> void:
	if failures.is_empty():
		print("REWARD_CLEANUP_LAYOUT_CONTRACT_OK")
		call_deferred("quit", 0)
		return
	for failure in failures:
		push_error(failure)
	call_deferred("quit", 1)

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
