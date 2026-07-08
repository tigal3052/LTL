extends SceneTree

const RewardBoardReadModelSuiteScript = preload("res://tests/ui_read_models/ui_reward_board_read_model_suite.gd")
const RewardBoardLayoutPolicySuiteScript = preload("res://tests/ui_read_models/ui_reward_board_layout_policy_suite.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var failures: Array = []
	for suite_script in [RewardBoardReadModelSuiteScript, RewardBoardLayoutPolicySuiteScript]:
		var suite = suite_script.new()
		if suite == null:
			failures.append("reward board focused suite failed to instantiate: %s" % str(suite_script))
			continue
		var result: Dictionary = suite.run_all_tests()
		failures.append_array(result.get("errors", []))
	if failures.is_empty():
		print("REWARD_BOARD_LAYOUT_CONTRACT_OK")
		quit(0)
		return
	for failure in failures:
		push_error("Reward board layout contract failed: %s" % str(failure))
	quit(1)
