extends SceneTree

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var TestUiReadModelsClass = load("res://tests/test_ui_read_models.gd")
	if TestUiReadModelsClass == null:
		push_error("Reward inspector stability runner failed to load res://tests/test_ui_read_models.gd")
		quit(1)
		return
	var tester = TestUiReadModelsClass.new()
	tester.failures.clear()
	tester.test_reward_tray_backpack_inspector_localizes_starter_loadout_artifact()
	tester.test_reward_tray_backpack_inspector_falls_back_to_primary_stats_when_description_is_missing()
	if tester.failures.is_empty():
		print("REWARD_INSPECTOR_STABILITY_CONTRACT_OK")
		await process_frame
		quit(0)
		return
	for failure in tester.failures:
		push_error("Reward inspector stability contract failed: %s" % failure)
	await process_frame
	quit(1)
