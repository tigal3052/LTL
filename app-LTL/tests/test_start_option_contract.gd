# 계약:
# - 책임: stage-one starter-option selection and combat-start transition stay valid inside the main controller flow.
# - 입력: MainControllerRuntime, preview controller, starter color selection, and a minimal render stub.
# - 출력: starter-option regression verdict dictionary with deterministic failures.
# - 금지: Main scene boot, RewardRevealOverlay dependency, unrelated UI interaction coverage.
#
# 실행: define the starter-option contract test class.
extends RefCounted

const MainControllerRuntimeScript = preload("res://src/MainControllerRuntime.gd")
const CombatScenePreviewControllerScript = preload("res://src/ui/CombatScenePreviewController.gd")
const RunGrowthStateScript = preload("res://src/models/RunGrowthState.gd")

var failures: Array[String] = []

class ViewStub:
	extends RefCounted

	var battlefield_ui = null
	var last_scene: Dictionary = {}
	var battle_pause_active := false

	func add_log(_message: String) -> void:
		pass

	func set_node_select_text(_value: String) -> void:
		pass

	func render_scene(scene: Dictionary, _show_victory_overlay: bool) -> void:
		last_scene = scene.duplicate(true)

	func update_battlefield_disabled(_scene: Dictionary, _disabled_tiles: Array) -> void:
		pass

	func update_action_state(_scene: Dictionary, _show_victory_overlay: bool) -> void:
		pass

	func set_reward_text(_value: String) -> void:
		pass

	func render_reward_tray(_model: Dictionary) -> void:
		pass

	func update_discard_zone(_label_text: String, _is_active: bool) -> void:
		pass

	func render_backpack(_inventory) -> void:
		pass

	func update_backpack_ghost(_artifact) -> void:
		pass

	func set_battle_pause_active(active: bool) -> void:
		battle_pause_active = active

# 실행: run the starter-option regression checks.
func run_all_tests() -> Dictionary:
	failures.clear()
	test_stage_one_start_color_selection_enters_combat_without_terminating()
	test_timer_shift_keeps_advancing_after_match_feedback()
	test_combat_overlay_pause_blocks_shift_until_resume()
	return {"ok": failures.is_empty(), "errors": failures}

# 실행: verify selecting a stage-one starter option still enters combat and keeps the selected queue color.
func test_stage_one_start_color_selection_enters_combat_without_terminating() -> void:
	var controller = MainControllerRuntimeScript.new()
	_assert(controller != null, "main controller runtime instantiates for starter-option regression coverage")
	if controller == null:
		return
	controller.view = ViewStub.new()
	controller.preview_controller = CombatScenePreviewControllerScript.new({
		"seed": 71,
		"maxStages": 3,
		"viewportWidth": 1440,
		"viewportHeight": 900,
		"startColor": "red"
	})
	controller.growth_state = RunGrowthStateScript.new(controller.preview_controller.run.state.get("growth", {}))
	controller.current_scene = controller.preview_controller.reset()
	controller._load_backpack_items_into_inventory()
	controller.page_override_id = ""

	_assert_eq(str(controller.current_scene.get("phase", "")), "node_select", "starter-option contract begins on stage-one node_select")
	controller._on_loadout_color_selected("blue")
	_assert_eq(controller.selected_start_color, "blue", "controller stores the selected starter color before combat")
	var equipped_colors := _equipped_energy_colors(controller.inventory)
	_assert_eq(equipped_colors, ["blue", "blue"], "starter selection replaces inventory with matching-color drill and beacon")

	controller._on_start_pressed()
	_assert_eq(str(controller.current_scene.get("phase", "")), "combat", "starter selection plus start enters combat instead of terminating the run")
	_assert_eq(bool(controller.current_scene.get("runComplete", false)), false, "starter selection plus start does not mark the run complete")
	_assert_eq(bool(controller.current_scene.get("failed", false)), false, "starter selection plus start does not flag failure")
	var queue_items: Array = controller.current_scene.get("hud", {}).get("queue", {}).get("items", [])
	_assert(not queue_items.is_empty(), "combat queue stays populated after starter selection")
	if not queue_items.is_empty():
		var front_color := str(queue_items[0].get("color", "")) if queue_items[0] is Dictionary else str(queue_items[0])
		_assert_eq(front_color, "blue", "combat queue front color matches the selected stage-one starter option")

func test_timer_shift_keeps_advancing_after_match_feedback() -> void:
	var controller = MainControllerRuntimeScript.new()
	_assert(controller != null, "main controller runtime instantiates for shift regression coverage")
	if controller == null:
		return
	controller.view = ViewStub.new()
	controller.preview_controller = CombatScenePreviewControllerScript.new({
		"seed": 91,
		"maxStages": 3,
		"viewportWidth": 1440,
		"viewportHeight": 900,
		"startColor": "red"
	})
	controller.growth_state = RunGrowthStateScript.new(controller.preview_controller.run.state.get("growth", {}))
	controller.current_scene = controller.preview_controller.reset()
	controller._load_backpack_items_into_inventory()
	controller.page_override_id = ""
	controller._on_start_pressed()
	var before_markers: Array = controller.preview_controller.run.state.get("combat", {}).get("battlefield", {}).get("weaknessMarkers", []).duplicate(true)
	controller.current_scene = controller.preview_controller.fire("r0c0", controller._get_active_queue_color())
	_assert(str(controller.current_scene.get("feedback", {}).get("status", "")) != "active", "shot feedback stores a non-active transient result before timer shift")
	controller._on_shift_timer_timeout()
	var after_markers: Array = controller.preview_controller.run.state.get("combat", {}).get("battlefield", {}).get("weaknessMarkers", []).duplicate(true)
	_assert(before_markers != after_markers, "timer shift still advances battlefield markers after non-terminal shot feedback")

func test_combat_overlay_pause_blocks_shift_until_resume() -> void:
	var controller = MainControllerRuntimeScript.new()
	_assert(controller != null, "main controller runtime instantiates for combat overlay pause coverage")
	if controller == null:
		return
	var view_stub := ViewStub.new()
	controller.view = view_stub
	controller.preview_controller = CombatScenePreviewControllerScript.new({
		"seed": 17,
		"maxStages": 3,
		"viewportWidth": 1440,
		"viewportHeight": 900,
		"startColor": "red"
	})
	controller.growth_state = RunGrowthStateScript.new(controller.preview_controller.run.state.get("growth", {}))
	controller.current_scene = controller.preview_controller.reset()
	controller._load_backpack_items_into_inventory()
	controller.page_override_id = ""
	controller._on_start_pressed()
	_assert(controller.has_method("_set_battle_pause_active"), "main controller runtime exposes battle-only overlay pause ownership helper")
	if not controller.has_method("_set_battle_pause_active"):
		return
	var before_markers: Array = controller.preview_controller.run.state.get("combat", {}).get("battlefield", {}).get("weaknessMarkers", []).duplicate(true)
	controller.call("_set_battle_pause_active", true)
	controller._on_shift_timer_timeout()
	var paused_markers: Array = controller.preview_controller.run.state.get("combat", {}).get("battlefield", {}).get("weaknessMarkers", []).duplicate(true)
	_assert_eq(paused_markers, before_markers, "combat overlay pause blocks terrain shifts while the overlay is open")
	_assert_eq(view_stub.battle_pause_active, true, "controller forwards combat overlay pause state to the view")
	controller.call("_set_battle_pause_active", false)
	controller._on_shift_timer_timeout()
	var resumed_markers: Array = controller.preview_controller.run.state.get("combat", {}).get("battlefield", {}).get("weaknessMarkers", []).duplicate(true)
	_assert(resumed_markers != before_markers, "combat terrain shifts resume after closing the overlay pause")
	_assert_eq(view_stub.battle_pause_active, false, "controller clears the forwarded view pause state after resume")

static func _equipped_energy_colors(inventory) -> Array:
	var colors: Array = []
	if inventory == null:
		return colors
	for art_id in inventory.artifacts:
		colors.append(str(inventory.artifacts[art_id].energy_type))
	colors.sort()
	return colors

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		failures.append(msg)

func _assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])
