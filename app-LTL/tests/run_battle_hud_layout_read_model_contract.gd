extends SceneTree

const UIPhaseLayoutSuiteScript = preload("res://tests/ui_read_models/ui_phase_layout_suite.gd")
const UIBattlefieldHudSuiteScript = preload("res://tests/ui_read_models/ui_battlefield_hud_suite.gd")
const UIBattlefieldHudStatusSuiteScript = preload("res://tests/ui_read_models/ui_battlefield_hud_status_suite.gd")
const UISharedBackpackHostCoordinatorSuiteScript = preload("res://tests/ui_read_models/ui_shared_backpack_host_coordinator_suite.gd")

var failures: Array[String] = []

func _init() -> void:
	var suites := [
		UIPhaseLayoutSuiteScript,
		UIBattlefieldHudSuiteScript,
		UIBattlefieldHudStatusSuiteScript,
		UISharedBackpackHostCoordinatorSuiteScript
	]
	for suite_script in suites:
		var suite = suite_script.new()
		if suite == null or not suite.has_method("run_all_tests"):
			failures.append("battle HUD read-model suite failed to instantiate: %s" % str(suite_script))
			continue
		var result: Dictionary = suite.run_all_tests()
		failures.append_array(result.get("errors", []))
	if failures.is_empty():
		print("BATTLE_HUD_LAYOUT_READ_MODEL_CONTRACT_OK")
		quit(0)
		return
	for failure in failures:
		push_error("Battle HUD read-model contract failed: %s" % failure)
	quit(1)
