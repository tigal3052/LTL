extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	var main_scene: PackedScene = load("res://src/Main.tscn")
	_assert(main_scene != null, "main scene loads for combat containment contract")
	if main_scene == null:
		await _finish()
		return
	var main_instance = main_scene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists for combat containment contract")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		await _finish()
		return
	controller.set("page_override_id", "")
	controller.call("_render_scene", _combat_probe_scene())
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "battle", "combat containment contract renders the battle page")
	_assert_control_inside_viewport(main_instance.get("header_panel") as Control, "combat header")
	_assert_control_inside_viewport(main_instance.get("top_content") as Control, "combat top-content")
	_assert_control_inside_viewport(main_instance.get("left_column") as Control, "combat left column")
	_assert_control_inside_viewport(main_instance.get("backpack_container") as Control, "combat backpack")
	_assert_control_inside_viewport(main_instance.get("right_sidebar") as Control, "combat right sidebar")
	_assert_control_inside_viewport(main_instance.get("active_phase_container") as Control, "combat active phase")
	_assert_control_inside_viewport(main_instance.get("battlefield_ui") as Control, "combat battlefield")
	_assert_control_inside_viewport(main_instance.get("action_bar") as Control, "combat action bar")
	main_instance.queue_free()
	await process_frame
	await _finish()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _assert_control_inside_viewport(control: Control, label: String) -> void:
	_assert(control != null, "%s exists" % label)
	if control == null:
		return
	var rect := control.get_global_rect()
	var viewport := Rect2(Vector2.ZERO, Vector2(root.size))
	_assert(rect.position.x >= viewport.position.x - 0.5, "%s stays inside the viewport left edge (rect=%s viewport=%s)" % [label, str(rect), str(viewport)])
	_assert(rect.position.y >= viewport.position.y - 0.5, "%s stays inside the viewport top edge (rect=%s viewport=%s)" % [label, str(rect), str(viewport)])
	_assert(rect.end.x <= viewport.end.x + 0.5, "%s stays inside the viewport right edge (rect=%s viewport=%s)" % [label, str(rect), str(viewport)])
	_assert(rect.end.y <= viewport.end.y + 0.5, "%s stays inside the viewport bottom edge (rect=%s viewport=%s)" % [label, str(rect), str(viewport)])

func _combat_probe_scene() -> Dictionary:
	var cells: Array = []
	var colors := ["red", "blue", "green", "purple"]
	for row in range(10):
		for column in range(10):
			var weakness: Variant = colors[(row + column) % colors.size()]
			if (row + column) % 5 == 0:
				weakness = null
			cells.append({
				"id": "r%dc%d" % [row, column],
				"row": row,
				"column": column,
				"weakness": weakness,
				"queueMatch": weakness == "purple",
				"activeQueueColor": "purple",
				"aimed": row == 4 and column == 4
			})
	return {
		"phase": "combat",
		"terrain": {
			"rows": 10,
			"columns": 10,
			"cells": cells
		},
		"hud": {
			"aim": {"canFire": true},
			"repair": {"active": false, "available": false, "progress": 0.0},
			"queue": {
				"items": ["purple", "purple", "blue", "green", "red", "purple", "blue", "green", "red"],
				"capacity": 16,
				"loaded": 9
			},
			"pin": {"active": false, "progress": 0.0},
			"hazard": {"severity": "stable"}
		},
		"targetPanel": {
			"timeLimitTicks": 1200.0,
			"elapsedTicks": 300.0,
			"health": 34.8,
			"maxHealth": 36.0,
			"shield": 26.8,
			"maxShield": 28.0
		},
		"feedback": {"status": "active"},
		"lastNodeLabel": "Mythic Fault",
		"stageIndex": 0,
		"maxStages": 4
	}

func _finish() -> void:
	if failures.is_empty():
		print("COMBAT_LAYOUT_CONTAINMENT_CONTRACT_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
