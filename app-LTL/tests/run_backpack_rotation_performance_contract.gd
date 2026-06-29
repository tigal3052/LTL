# Contract: backpack drill rotation hot path avoids cache misses and node churn.
extends SceneTree

const BackpackRuntimeSuiteScript = preload("res://tests/ui_read_models/backpack_layout/ui_backpack_runtime_suite.gd")

func _init() -> void:
	var tester = BackpackRuntimeSuiteScript.new()
	var test_res: Dictionary = tester.run_rotation_performance_tests()
	if bool(test_res.get("ok", false)):
		print("BACKPACK_ROTATION_PERFORMANCE_CONTRACT_OK")
		quit(0)
		return
	for err in test_res.get("errors", []):
		push_error("Backpack rotation performance contract failed: %s" % err)
	quit(1)
