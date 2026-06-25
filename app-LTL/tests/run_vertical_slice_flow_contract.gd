extends SceneTree

const TestVerticalSliceFlowScript = preload("res://tests/test_vertical_slice_flow.gd")

func _init() -> void:
	var tester = TestVerticalSliceFlowScript.new()
	var result: Dictionary = tester.run_all_tests()
	if bool(result.get("ok", false)):
		print("VERTICAL_SLICE_FLOW_CONTRACT_OK")
		quit(0)
		return
	for error in result.get("errors", []):
		push_error(str(error))
	quit(1)
