extends SceneTree

func _init() -> void:
	var TestUiReadModelsClass = load("res://tests/test_ui_read_models.gd")
	if TestUiReadModelsClass == null:
		push_error("Defeat page contract runner failed to load res://tests/test_ui_read_models.gd")
		quit(1)
		return
	var tester = TestUiReadModelsClass.new()
	tester.test_main_view_defeat_page_model_uses_selected_leviathan_art()
	tester.test_main_view_defeat_page_model_exposes_wireframe_fields()
	tester.test_defeat_page_scene_uses_dedicated_wireframe_layout()
	var failures: Array = tester.failures
	if failures.is_empty():
		print("DEFEAT_PAGE_CONTRACT_OK")
		quit(0)
		return
	for failure in failures:
		push_error("Defeat page contract failed: %s" % str(failure))
	quit(1)
