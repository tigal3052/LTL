# 계약: backpack layout read-model contracts can run in isolation for grid sizing regressions.
# 실행: run the backpack layout suite and emit a deterministic success marker.
extends SceneTree

const UIBackpackLayoutSuiteScript = preload("res://tests/ui_read_models/ui_backpack_layout_suite.gd")

func _init() -> void:
	var tester = UIBackpackLayoutSuiteScript.new()
	var test_res: Dictionary = tester.run_all_tests()
	if bool(test_res.get("ok", false)):
		print("BACKPACK_LAYOUT_CONTRACT_OK")
		quit(0)
		return
	for err in test_res.get("errors", []):
		push_error("Backpack layout contract failed: %s" % err)
	quit(1)
