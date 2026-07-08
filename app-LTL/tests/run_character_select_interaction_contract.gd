extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const CharacterSelectLoadoutTextScript = preload("res://src/scenes/pages/character_select/CharacterSelectLoadoutText.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	var main_scene := load("res://src/Main.tscn") as PackedScene
	_assert(main_scene != null, "main scene resource loads for character select interaction contract")
	if main_scene == null:
		await _finish()
		return
	var main_instance := main_scene.instantiate()
	root.add_child(main_instance)
	await process_frame
	await process_frame
	await process_frame
	if str(main_instance.get("active_page_id")) == "story_scene":
		await _advance_story_if_present(main_instance, "character_select")
		await process_frame
		await process_frame
	var page := main_instance.get("character_select_page") as Control
	_assert(page != null, "character select page exists for interaction contract")
	if page == null:
		main_instance.queue_free()
		await process_frame
		await _finish()
		return

	# Stage-based node paths
	var drill := page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/BagSection/StarterItemList/StarterItem_starter_red_drill") as Button
	var beacon := page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/BagSection/StarterItemList/StarterItem_starter_red_beacon") as Button
	var preset_grid := page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/PresetSection/PresetGrid") as GridContainer
	var red_palette := page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/PresetSection/PresetGrid/Palette_red") as Button
	var green_palette := page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/PresetSection/PresetGrid/Palette_green") as Button
	var detail_title := page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/DetailSection/ItemDetailTitle") as Label
	var detail_metric := page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/DetailSection/ItemDetailMetric") as Label
	var detail_body := page.get_node_or_null("Stage/Wing/WingMargin/WingVBox/DetailSection/ItemDetailBody") as Label

	_assert(drill != null, "starter drill button exists for interaction contract")
	_assert(beacon != null, "starter beacon button exists for interaction contract")
	_assert(detail_title != null, "item detail title exists for interaction contract")
	_assert(detail_body != null, "item detail body exists for interaction contract")
	if drill != null and beacon != null and detail_title != null and detail_body != null:
		var expected_beacon := CharacterSelectLoadoutTextScript.detail_for_item_id("red", "starter_red_beacon")
		beacon.pressed.emit()
		await process_frame
		_assert_eq(detail_title.text, str(expected_beacon.get("title", "")), "clicked beacon keeps the expected item detail title")
		_assert_eq(detail_body.text, str(expected_beacon.get("body", "")), "clicked beacon keeps the expected item detail body")
		if detail_metric != null:
			_assert_eq(detail_metric.text, str(expected_beacon.get("metricLine", "")), "clicked beacon keeps the expected item detail metric")
		var stable_height := page.size.y
		drill.mouse_entered.emit()
		await process_frame
		_assert_eq(detail_title.text, str(expected_beacon.get("title", "")), "hover alone does not replace the clicked starter-item detail title")
		_assert_eq(detail_body.text, str(expected_beacon.get("body", "")), "hover alone does not replace the clicked starter-item detail body")
		_assert(is_equal_approx(page.size.y, stable_height), "starter-item hover keeps the page height stable after click selection")
		_assert(not detail_body.text.is_empty(), "item detail body remains populated after click selection")

	_assert(preset_grid != null, "preset grid exists for visibility contract")
	_assert(red_palette != null, "red starter-set palette button exists for visibility contract")
	_assert(green_palette != null, "green starter-set palette button exists for visibility contract")
	if preset_grid != null and red_palette != null and green_palette != null:
		green_palette.pressed.emit()
		await process_frame
		await process_frame
		# Verify the palette selection stayed on character select
		_assert_eq(str(main_instance.get("active_page_id")), "character_select", "starter-set palette selection stays on character select without full page handoff")

	main_instance.queue_free()
	await process_frame
	await _finish()

func _advance_story_if_present(main_instance: Node, return_page_id: String) -> void:
	if str(main_instance.get("active_page_id")) != "story_scene":
		return
	var story_page = main_instance.get("story_scene_page")
	var controller = main_instance.get_node_or_null("MainController")
	_assert(story_page != null, "story scene page exists during interaction-contract handoff")
	_assert(controller != null, "main controller exists during interaction-contract handoff")
	if story_page == null or controller == null:
		return
	var story: Dictionary = controller.get("active_story_scene")
	var scene_id := str(story.get("id", ""))
	_assert(scene_id != "", "story scene exposes an active scene id during interaction-contract handoff")
	if scene_id.is_empty():
		return
	story_page.continue_requested.emit(scene_id)
	await process_frame
	story_page.continue_requested.emit(scene_id)
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), return_page_id, "story scene returns to %s during interaction contract" % return_page_id)

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _finish() -> void:
	if failures.is_empty():
		print("CHARACTER_SELECT_INTERACTION_CONTRACT_OK")
		await process_frame
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	await process_frame
	quit(1)
