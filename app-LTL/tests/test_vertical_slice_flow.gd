# 계약: M8 vertical-slice runner proves one full ossuary_tortoise run, defeat retry choices, reward reflection, and starter unlocks.
# 실행: drive public runner/read-model helpers only, without mutating scene nodes or creating a separate vertical-slice scene.
extends RefCounted

const VerticalSliceRunnerScript = preload("res://src/process/VerticalSliceRunner.gd")
const FailureReadModelScript = preload("res://src/ui/read_models/FailureReadModel.gd")
const MainControllerRunFlowScript = preload("res://src/controllers/MainControllerRunFlow.gd")
const HeadlessMiniRunScript = preload("res://src/process/HeadlessMiniRun.gd")
const PhaseLayoutPresenterScript = preload("res://src/ui/presenters/PhaseLayoutPresenter.gd")

var failures: Array[String] = []

func run_all_tests() -> Dictionary:
	failures.clear()
	test_m8_fixture_is_locked_to_one_ossuary_run()
	test_final_boss_clear_keeps_reward_phase_before_clear()
	test_non_final_run_boss_clear_keeps_reward_phase_and_advances_run()
	test_non_boss_final_clear_keeps_reward_phase()
	test_full_clear_applies_rewards_progress_and_unlocks()
	test_defeat_applies_repair_unlock_and_retry_seed_modes()
	test_failure_read_model_exposes_retry_choices()
	return {"ok": failures.is_empty(), "errors": failures}

func test_m8_fixture_is_locked_to_one_ossuary_run() -> void:
	var runner = VerticalSliceRunnerScript.new()
	var fixture: Dictionary = runner.m8_fixture({"seed": 20260617})
	_assert_eq(str(fixture.get("leviathanId", "")), "ossuary_tortoise", "M8 fixture uses ossuary_tortoise")
	_assert_eq(int(fixture.get("maxStages", 0)), 3, "M8 fixture uses three stages")
	_assert_eq(int(fixture.get("runCount", 0)), 1, "M8 fixture uses one run")
	_assert_eq(str(fixture.get("bossNodeId", "")), "boss_spine", "M8 fixture locks the final boss node")

func test_final_boss_clear_keeps_reward_phase_before_clear() -> void:
	var run = HeadlessMiniRunScript.new({"seed": 1, "maxStages": 1, "nodeTable": _normal_and_boss_table()})
	run.select_node(0)
	var snapshot: Dictionary = run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	_assert_eq(str(snapshot.get("phase", "")), "reward_loot", "final boss clear enters reward loot before clear")
	_assert_eq(bool(snapshot.get("runComplete", false)), false, "final boss reward phase does not mark run complete yet")
	_assert(snapshot.get("pendingRewards", []).size() > 0, "final boss clear exposes pending rewards")
	var completed: Dictionary = run.claim_rewards()
	_assert_eq(str(completed.get("phase", "")), "run_complete", "final boss reward claim enters run_complete")
	_assert_eq(bool(completed.get("runComplete", false)), true, "final boss reward claim marks run complete")
	_assert(completed.get("progress", {}).get("clearedLeviathanIds", []).has("training_leviathan"), "final boss reward claim records the cleared Leviathan")
	var layout: Dictionary = PhaseLayoutPresenterScript.project(completed, false)
	_assert_eq(bool(layout.get("rewardVisible", true)), false, "final boss completed layout does not show reward UI")
	_assert_eq(str(layout.get("stageText", "unexpected")), "", "final boss completed layout uses the meta clear-page shell")

func test_non_final_run_boss_clear_keeps_reward_phase_and_advances_run() -> void:
	var run = HeadlessMiniRunScript.new({"seed": 3, "maxStages": 1, "runCount": 2, "nodeTable": _normal_and_boss_table()})
	var initial: Dictionary = run.snapshot()
	_assert_eq(str(initial.get("candidates", [{}])[0].get("id", "")), "boss_spine", "multi-run final-stage candidate is the boss")
	run.select_node(0)
	var snapshot: Dictionary = run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	_assert_eq(str(snapshot.get("phase", "")), "reward_loot", "non-final run boss clear still enters reward loot")
	_assert_eq(bool(snapshot.get("runComplete", false)), false, "non-final run boss clear does not mark run complete")
	_assert(snapshot.get("pendingRewards", []).size() > 0, "non-final run boss clear exposes pending rewards")
	var next_run: Dictionary = run.claim_rewards()
	_assert_eq(str(next_run.get("phase", "")), "node_select", "claiming non-final boss rewards advances to node select")
	_assert_eq(int(next_run.get("runIndex", -1)), 1, "claiming non-final boss rewards advances to the next run")
	_assert_eq(int(next_run.get("stageIndex", -1)), 0, "next run starts from stage zero")
	_assert_eq(bool(next_run.get("runComplete", false)), false, "next run remains incomplete after non-final boss rewards")

func test_non_boss_final_clear_keeps_reward_phase() -> void:
	var run = HeadlessMiniRunScript.new({"seed": 2, "maxStages": 1, "nodeTable": _normal_only_table()})
	run.select_node(0)
	var snapshot: Dictionary = run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	_assert_eq(str(snapshot.get("phase", "")), "reward_loot", "non-boss final clear still enters reward loot")
	_assert(snapshot.get("pendingRewards", []).size() > 0, "non-boss final clear still exposes pending rewards")

func test_full_clear_applies_rewards_progress_and_unlocks() -> void:
	var runner = VerticalSliceRunnerScript.new()
	var result: Dictionary = runner.run_clear({"seed": 20260617})
	var summary: Dictionary = result.get("summary", {})
	_assert_eq(bool(result.get("ok", false)), true, "M8 clear result is ok")
	_assert_eq(str(summary.get("phase", "")), "run_complete", "M8 clear reaches run_complete")
	_assert_eq(bool(summary.get("failed", true)), false, "M8 clear is not failed")
	_assert_eq(int(summary.get("stageIndex", -1)), 2, "M8 clear ends on the third stage index")
	_assert_eq(int(summary.get("rewardPhaseCount", 0)), 3, "M8 clear includes the final boss reward phase before clear")
	_assert_eq(str(summary.get("finalNodeId", "")), "boss_spine", "M8 clear finishes on boss_spine")

	var progress: Dictionary = result.get("progress", {})
	_assert(progress.get("clearedLeviathanIds", []).has("ossuary_tortoise"), "M8 clear records the cleared Leviathan id")
	var growth: Dictionary = result.get("growth", {})
	var unlocked: Array = growth.get("unlockedStarterItems", [])
	_assert(unlocked.has("starter_drill_blue"), "M8 clear unlocks the blue starter drill")
	_assert(unlocked.has("starter_beacon_blue"), "M8 clear unlocks the blue starter beacon")
	_assert(int(growth.get("rewardHistory", []).size()) >= 3, "M8 clear applies all stage rewards to growth history")

	var telemetry: Dictionary = result.get("telemetry", {})
	for category in ["combat", "reward", "route", "hazard", "ui", "narrative"]:
		_assert(telemetry.has(category), "M8 telemetry contains %s events" % category)
	_assert(int(summary.get("timeToFirstValidHitTicks", -1)) >= 0, "M8 clear exposes first-valid-hit timing metric")

func test_defeat_applies_repair_unlock_and_retry_seed_modes() -> void:
	var runner = VerticalSliceRunnerScript.new()
	var failed: Dictionary = runner.run_defeat({"seed": 8801})
	var summary: Dictionary = failed.get("summary", {})
	_assert_eq(bool(summary.get("failed", false)), true, "M8 defeat marks the run failed")
	_assert_eq(str(summary.get("failureReason", "")), "failed", "M8 defeat preserves the failure reason")
	_assert(failed.get("growth", {}).get("unlockedStarterItems", []).has("starter_repair_kit"), "M8 defeat unlocks the repair kit")

	var same_retry: Dictionary = runner.retry_from(failed, "same_seed")
	var new_retry: Dictionary = runner.retry_from(failed, "new_seed")
	_assert_eq(int(same_retry.get("seed", -1)), int(failed.get("seed", -2)), "same-seed retry preserves the failed seed")
	_assert(int(new_retry.get("seed", -1)) != int(failed.get("seed", -1)), "new-seed retry changes the seed")
	_assert_eq(str(same_retry.get("summary", {}).get("phase", "")), "node_select", "same-seed retry returns to node_select")
	_assert(same_retry.get("growth", {}).get("unlockedStarterItems", []).has("starter_repair_kit"), "same-seed retry preserves repair unlock")

	_assert_eq(MainControllerRunFlowScript.retry_seed_for_mode(17, "same_seed"), 17, "controller retry policy keeps same seed")
	_assert(MainControllerRunFlowScript.retry_seed_for_mode(17, "new_seed") != 17, "controller retry policy creates new seed")

func test_failure_read_model_exposes_retry_choices() -> void:
	var model: Dictionary = FailureReadModelScript.project({
		"phase": "run_complete",
		"failed": true,
		"seed": 42,
		"selectedLeviathan": {"name": "Ossuary Tortoise"},
		"lastNodeLabel": "Safe Scar"
	})
	var options: Array = model.get("retryOptions", [])
	_assert_eq(options.size(), 2, "failure read model exposes two retry options")
	if options.size() == 2:
		_assert_eq(str(options[0].get("id", "")), "same_seed", "first retry option is same seed")
		_assert_eq(str(options[1].get("id", "")), "new_seed", "second retry option is new seed")

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _normal_only_table() -> Dictionary:
	return {"nodes": [_normal_node()]}

func _normal_and_boss_table() -> Dictionary:
	return {"nodes": [_normal_node(), _boss_node()]}

func _normal_node() -> Dictionary:
	return {"id": "normal", "label": "Normal Node", "nodeType": "normal", "riskTier": "safe", "weakness": ["red"], "pickWeight": 1, "shieldMul": 1, "healthMul": 1, "alwaysOffer": true, "rewardBias": "baseline", "recommendedBuildHint": "Any stable drill line", "difficultyModifier": 1.0, "rewardModifier": 1.0, "hazardModifier": 1.0}

func _boss_node() -> Dictionary:
	return {"id": "boss_spine", "label": "Boss Spine", "nodeType": "boss", "riskTier": "boss", "weakness": ["red"], "pickWeight": 1, "shieldMul": 1.6, "healthMul": 1.8, "isBoss": true, "rewardBias": "run_clear", "recommendedBuildHint": "Bring mixed coverage", "difficultyModifier": 1.7, "rewardModifier": 1.8, "hazardModifier": 1.4}
