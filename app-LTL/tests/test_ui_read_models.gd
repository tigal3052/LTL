extends RefCounted

const UITextTooltipSuiteScript = preload("res://tests/ui_read_models/ui_text_tooltip_suite.gd")
const UICodexRewardBoardSuiteScript = preload("res://tests/ui_read_models/ui_codex_reward_board_suite.gd")
const UIPhaseLayoutSuiteScript = preload("res://tests/ui_read_models/ui_phase_layout_suite.gd")
const UIBackpackLayoutSuiteScript = preload("res://tests/ui_read_models/ui_backpack_layout_suite.gd")
const UIBattlefieldHudSuiteScript = preload("res://tests/ui_read_models/ui_battlefield_hud_suite.gd")
const UIBattlefieldHudStatusSuiteScript = preload("res://tests/ui_read_models/ui_battlefield_hud_status_suite.gd")
const UIDefeatVisualSuiteScript = preload("res://tests/ui_read_models/ui_defeat_visual_suite.gd")
const UIInteractionControllerSuiteScript = preload("res://tests/ui_read_models/ui_interaction_controller_suite.gd")
const UIInteractionFeedbackAccessibilitySuiteScript = preload("res://tests/ui_read_models/ui_interaction_feedback_accessibility_suite.gd")
const UIAppShellLayoutPolicySuiteScript = preload("res://tests/ui_read_models/ui_app_shell_layout_policy_suite.gd")
const UIOverlayContractSuiteScript = preload("res://tests/ui_read_models/ui_overlay_contract_suite.gd")
const UIPageSceneModelBuilderSuiteScript = preload("res://tests/ui_read_models/ui_page_scene_model_builder_suite.gd")
const UIPageSceneRegistrySuiteScript = preload("res://tests/ui_read_models/ui_page_scene_registry_suite.gd")
const UIRewardCardCloudHostSuiteScript = preload("res://tests/ui_read_models/ui_reward_card_cloud_host_suite.gd")
const UIRewardBoardLayoutPolicySuiteScript = preload("res://tests/ui_read_models/ui_reward_board_layout_policy_suite.gd")
const UIRewardRevealCeremonySuiteScript = preload("res://tests/ui_read_models/ui_reward_reveal_ceremony_suite.gd")
const UIRewardRevealLayoutSuiteScript = preload("res://tests/ui_read_models/ui_reward_reveal_layout_suite.gd")
const UISharedBackpackHostCoordinatorSuiteScript = preload("res://tests/ui_read_models/ui_shared_backpack_host_coordinator_suite.gd")

var failures: Array[String] = []

func run_all_tests() -> Dictionary:
	failures.clear()
	for suite_script in [
		UITextTooltipSuiteScript,
		UICodexRewardBoardSuiteScript,
		UIPhaseLayoutSuiteScript,
		UIBackpackLayoutSuiteScript,
		UIBattlefieldHudSuiteScript,
		UIBattlefieldHudStatusSuiteScript,
		UIDefeatVisualSuiteScript,
		UIInteractionControllerSuiteScript,
		UIInteractionFeedbackAccessibilitySuiteScript,
		UIAppShellLayoutPolicySuiteScript,
		UIOverlayContractSuiteScript,
		UIPageSceneModelBuilderSuiteScript,
		UIPageSceneRegistrySuiteScript,
		UIRewardCardCloudHostSuiteScript,
		UIRewardBoardLayoutPolicySuiteScript,
		UIRewardRevealCeremonySuiteScript,
		UIRewardRevealLayoutSuiteScript,
		UISharedBackpackHostCoordinatorSuiteScript
	]:
		_run_suite(suite_script)
	return {"ok": failures.is_empty(), "errors": failures}

func run_reward_ceremony_tests() -> Dictionary:
	failures.clear()
	_run_suite(UIRewardRevealCeremonySuiteScript)
	_run_suite(UIRewardRevealLayoutSuiteScript)
	return {"ok": failures.is_empty(), "errors": failures}

func test_reward_tray_backpack_inspector_localizes_starter_loadout_artifact() -> void:
	_run_suite_method(UICodexRewardBoardSuiteScript, "test_reward_tray_backpack_inspector_localizes_starter_loadout_artifact")

func test_reward_tray_backpack_inspector_falls_back_to_primary_stats_when_description_is_missing() -> void:
	_run_suite_method(UICodexRewardBoardSuiteScript, "test_reward_tray_backpack_inspector_falls_back_to_primary_stats_when_description_is_missing")

func test_main_view_defeat_page_model_uses_selected_leviathan_art() -> void:
	_run_suite_method(UIDefeatVisualSuiteScript, "test_main_view_defeat_page_model_uses_selected_leviathan_art")

func test_main_view_defeat_page_model_exposes_wireframe_fields() -> void:
	_run_suite_method(UIDefeatVisualSuiteScript, "test_main_view_defeat_page_model_exposes_wireframe_fields")

func test_defeat_page_scene_uses_dedicated_wireframe_layout() -> void:
	_run_suite_method(UIDefeatVisualSuiteScript, "test_defeat_page_scene_uses_dedicated_wireframe_layout")

func _run_suite(suite_script) -> void:
	var suite = suite_script.new()
	if suite == null:
		failures.append("ui read-model suite failed to instantiate: %s" % str(suite_script))
		return
	if not suite.has_method("run_all_tests"):
		failures.append("ui read-model suite is missing run_all_tests(): %s" % str(suite_script))
		return
	var result: Dictionary = suite.run_all_tests()
	failures.append_array(result.get("errors", []))

func _run_suite_method(suite_script, method_name: String) -> void:
	var suite = suite_script.new()
	if suite == null:
		failures.append("ui read-model suite failed to instantiate for %s" % method_name)
		return
	if not suite.has_method(method_name):
		failures.append("ui read-model suite is missing delegated method %s" % method_name)
		return
	suite.call(method_name)
	failures.append_array(suite.failures)
