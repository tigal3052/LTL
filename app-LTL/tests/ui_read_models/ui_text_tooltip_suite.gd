extends "res://tests/support/UiReadModelTestSuite.gd"
const TooltipProjectionSuiteScript = preload("res://tests/ui_read_models/text_tooltip/ui_tooltip_projection_suite.gd")
const LocaleCatalogSuiteScript = preload("res://tests/ui_read_models/text_tooltip/ui_locale_catalog_suite.gd")
const RewardTooltipComparisonSuiteScript = preload("res://tests/ui_read_models/text_tooltip/ui_reward_tooltip_comparison_suite.gd")
func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	for suite_script in [TooltipProjectionSuiteScript, LocaleCatalogSuiteScript, RewardTooltipComparisonSuiteScript]:
		var result: Dictionary = suite_script.new().run_all_tests()
		failures.append_array(result.get("errors", []))
	return _result()
