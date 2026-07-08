extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const META_PAGE_IDS := ["character_select", "leviathan_select", "clear", "defeat"]

class CountingMetaPage:
	extends Control

	var apply_count := 0

	func apply_state(_model: Dictionary) -> void:
		apply_count += 1

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	var main_scene: PackedScene = load("res://src/Main.tscn")
	_assert(main_scene != null, "main scene loads for battle render performance contract")
	if main_scene == null:
		_finish()
		return
	var main_instance = main_scene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame

	var instrumented_pages := _install_instrumented_meta_pages(main_instance)
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists for battle render performance contract")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		_finish()
		return

	controller.set("page_override_id", "")
	for index in range(8):
		var scene := _combat_probe_scene()
		scene["targetPanel"]["elapsedTicks"] = 300.0 + float(index)
		scene["hud"]["aim"] = {"cellId": "r0c%d" % (index % 10), "canFire": true}
		controller.call("_render_scene", scene)
		await process_frame

	_assert_eq(str(main_instance.get("active_page_id")), "battle", "repeated combat render stays on the battle page")
	for page_id in META_PAGE_IDS:
		var page = instrumented_pages.get(page_id, null)
		if page != null:
			_assert_eq(page.apply_count, 0, "battle render does not apply inactive %s meta page state" % page_id)

	main_instance.queue_free()
	await process_frame
	_finish()

func _install_instrumented_meta_pages(main_instance: Node) -> Dictionary:
	var scenes: Dictionary = main_instance.get("page_scenes")
	var instrumented := {}
	for page_id in META_PAGE_IDS:
		var page := CountingMetaPage.new()
		page.name = "Instrumented%sPage" % page_id.capitalize()
		instrumented[page_id] = page
		scenes[page_id] = page
	main_instance.set("page_scenes", scenes)
	return instrumented

func _combat_probe_scene() -> Dictionary:
	var cells: Array = []
	var colors := ["red", "blue", "green", "purple"]
	for row in range(3):
		for column in range(10):
			var weakness: Variant = colors[(row + column) % colors.size()]
			cells.append({
				"id": "r%dc%d" % [row, column],
				"row": row,
				"column": column,
				"weakness": weakness,
				"queueMatch": weakness == "purple",
				"activeQueueColor": "purple",
				"aimed": row == 0 and column == 0
			})
	return {
		"phase": "combat",
		"pageId": "battle",
		"terrain": {
			"rows": 3,
			"columns": 10,
			"cells": cells
		},
		"hud": {
			"aim": {"cellId": "r0c0", "canFire": true},
			"repair": {"active": false, "available": false, "progress": 0.0},
			"queue": {
				"items": ["purple", "blue", "green", "red"],
				"capacity": 16,
				"loaded": 4
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
			"maxShield": 28.0,
			"weakness": ["purple"]
		},
		"feedback": {"status": "active"},
		"lastNodeLabel": "Mythic Fault",
		"stageIndex": 0,
		"maxStages": 4
	}

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _finish() -> void:
	if failures.is_empty():
		print("BATTLE_RENDER_PERFORMANCE_CONTRACT_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
