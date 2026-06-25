extends "res://tests/support/UiReadModelTestSuite.gd"
const BackpackRuntimeSuiteScript = preload("res://tests/ui_read_models/backpack_layout/ui_backpack_runtime_suite.gd")
const BackpackInfluenceSuiteScript = preload("res://tests/ui_read_models/backpack_layout/ui_backpack_influence_suite.gd")
const BackpackSharedLayoutSuiteScript = preload("res://tests/ui_read_models/backpack_layout/ui_backpack_shared_layout_suite.gd")
func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	for suite_script in [BackpackRuntimeSuiteScript, BackpackInfluenceSuiteScript, BackpackSharedLayoutSuiteScript]:
		var result: Dictionary = suite_script.new().run_all_tests()
		failures.append_array(result.get("errors", []))
	return _result()
