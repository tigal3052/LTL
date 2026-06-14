extends SceneTree

const GameplayTopContentScene = preload("res://src/scenes/pages/shells/GameplayTopContent.tscn")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var host := Control.new()
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(host)

	var gameplay_top_content = GameplayTopContentScene.instantiate()
	host.add_child(gameplay_top_content)
	var status_panel = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel")
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
	var purple_row = status_panel.get_node_or_null("Margin/StatusBox/OpsShell/OpsMargin/OpsBox/StatusFooterSpacer/PurpleStatusRow") as HBoxContainer
	_assert(purple_row != null, "purple status row now lives inside the footer spacer overlay lane")
	var collapsed_min_height: float = status_panel.get_combined_minimum_size().y
	await process_frame
	_assert(not bool(purple_row.visible), "purple status row stays hidden when no purple pressure is active")
	var no_purple_min_height: float = status_panel.get_combined_minimum_size().y
	var purple_scene := combat_scene.duplicate(true)
	purple_scene["hud"]["purplePressure"] = {"stackCount": 0, "buffCount": 2, "active": true}
	status_panel.render_visual_queue(purple_scene)
	await process_frame
	_assert(bool(purple_row.visible), "purple status row becomes visible when purple pressure buff text exists")
	_assert_eq(status_panel.get_combined_minimum_size().y, no_purple_min_height, "purple status row overlay does not grow the status panel minimum height when it appears")
	_assert_eq(status_panel.get_combined_minimum_size().y, collapsed_min_height, "purple status row overlay preserves the same minimum height before and after combat-state rerenders")

	_finish()

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
