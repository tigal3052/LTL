# 怨꾩빟:
# - 책임: M8 one-Leviathan vertical slice를 headless runtime으로 완주/패배/재시도 검증할 수 있는 얇은 공개 경계를 제공한다.
# - 입력: seed, optional growth/progress, existing HeadlessMiniRun-compatible fixture options.
# - 출력: run summary, route/combat/reward/hazard/ui/narrative telemetry, progress and growth unlock snapshots.
# - 금지: Main.tscn 대체 scene 생성, UI node 직접 조작, combat/reward reducer rule 재구현.
#
# ?ㅽ뻾: define the M8 vertical-slice runner class identity.
class_name VerticalSliceRunner
extends RefCounted

const HeadlessMiniRunScript = preload("res://src/process/HeadlessMiniRun.gd")
const RunGrowthStateScript = preload("res://src/models/RunGrowthState.gd")
const ReleaseContentVocabScript = preload("res://src/vocabulary/ReleaseContentVocab.gd")

const M8_LEVIATHAN_ID := "ossuary_tortoise"
const M8_STAGE_COUNT := 3
const M8_RUN_COUNT := 1
const M8_BOSS_NODE_ID := "boss_spine"
const DEFAULT_SEEDS := [20260617, 20260618, 20260619]

# ?ㅽ뻾: build the fixed M8 fixture options without widening content scope.
func m8_fixture(options: Dictionary = {}) -> Dictionary:
	var bundle: Dictionary = ReleaseContentVocabScript.load_content_bundle()
	var leviathan: Dictionary = _find_by_id(bundle.get("leviathans", []), M8_LEVIATHAN_ID)
	var growth_value: Variant = options.get("growth", {})
	var growth: Dictionary = RunGrowthStateScript.new(growth_value if growth_value is Dictionary else {}).to_dict()
	var progress_value: Variant = options.get("progress", {"clearedLeviathanIds": []})
	var progress: Dictionary = progress_value.duplicate(true) if progress_value is Dictionary else {"clearedLeviathanIds": []}
	return {
		"seed": int(options.get("seed", DEFAULT_SEEDS[0])),
		"maxStages": maxi(1, int(leviathan.get("stageCount", leviathan.get("stageCnt", M8_STAGE_COUNT)))),
		"runCount": maxi(1, int(leviathan.get("runCount", leviathan.get("runCnt", M8_RUN_COUNT)))),
		"leviathanId": M8_LEVIATHAN_ID,
		"bossNodeId": str(leviathan.get("bossNodeId", M8_BOSS_NODE_ID)),
		"nodeTable": {"nodes": bundle.get("nodes", []).duplicate(true)},
		"startColor": str(options.get("startColor", "red")),
		"progress": progress,
		"growth": growth
	}

# ?ㅽ뻾: run the fixed M8 fixture through all three stages and apply reward effects before claiming each stage.
func run_clear(options: Dictionary = {}) -> Dictionary:
	var fixture: Dictionary = m8_fixture(options)
	var run = HeadlessMiniRunScript.new(fixture)
	var telemetry := _empty_telemetry()
	var reward_phase_count := 0
	var final_node_id := ""
	telemetry["ui"].append({"event": "character_selected", "characterId": "miner"})
	telemetry["ui"].append({"event": "leviathan_selected", "leviathanId": M8_LEVIATHAN_ID})
	for stage_index in range(int(fixture.get("maxStages", M8_STAGE_COUNT))):
		var node_select_snapshot: Dictionary = run.snapshot()
		var candidate_index := _candidate_index_for_stage(node_select_snapshot)
		var candidates: Array = node_select_snapshot.get("candidates", [])
		var selected_node: Dictionary = candidates[candidate_index] if candidate_index >= 0 and candidate_index < candidates.size() else {}
		final_node_id = str(selected_node.get("id", final_node_id))
		telemetry["route"].append(_route_event("node_selected", node_select_snapshot, selected_node, candidate_index))
		run.select_node(candidate_index)
		var reward_snapshot: Dictionary = run.apply_combat_input({"type": "resolve", "outcome": "clear"})
		telemetry["combat"].append(_combat_event(stage_index, reward_snapshot, "clear"))
		telemetry["hazard"].append(_hazard_event(stage_index, reward_snapshot))
		var reward_phase := str(reward_snapshot.get("phase", ""))
		if reward_phase == "run_complete":
			if stage_index < int(fixture.get("maxStages", M8_STAGE_COUNT)) - 1:
				return _build_result(false, fixture, reward_snapshot, telemetry, reward_phase_count, final_node_id, [{"code": "unexpected_early_run_complete", "stageIndex": stage_index}])
			telemetry["ui"].append({"event": "clear_page_shown", "stageIndex": stage_index})
			continue
		if reward_phase != "reward_loot":
			return _build_result(false, fixture, reward_snapshot, telemetry, reward_phase_count, final_node_id, [{"code": "expected_reward_loot", "stageIndex": stage_index}])
		reward_phase_count += 1
		var pending_rewards: Array = reward_snapshot.get("pendingRewards", [])
		telemetry["reward"].append({"event": "reward_phase_opened", "stageIndex": stage_index, "rewardCount": pending_rewards.size()})
		for reward in pending_rewards:
			if reward is Dictionary:
				reward_snapshot = run.apply_combat_input({"type": "claim_reward_effect", "reward": reward})
		reward_snapshot = run.claim_rewards()
		telemetry["ui"].append({"event": "reward_claimed", "stageIndex": stage_index})
	telemetry["narrative"].append({"event": "first_valid_hit_metric_recorded", "ticks": 0, "beatId": "first_valid_hit"})
	var final_snapshot: Dictionary = run.snapshot()
	return _build_result(not bool(final_snapshot.get("failed", false)), fixture, final_snapshot, telemetry, reward_phase_count, final_node_id, [])

# ?ㅽ뻾: drive a deterministic defeat path for retry and failure-unlock verification.
func run_defeat(options: Dictionary = {}) -> Dictionary:
	var fixture: Dictionary = m8_fixture(options)
	var run = HeadlessMiniRunScript.new(fixture)
	var telemetry := _empty_telemetry()
	var node_select_snapshot: Dictionary = run.snapshot()
	var candidate_index := _candidate_index_for_stage(node_select_snapshot)
	var candidates: Array = node_select_snapshot.get("candidates", [])
	var selected_node: Dictionary = candidates[candidate_index] if candidate_index >= 0 and candidate_index < candidates.size() else {}
	telemetry["route"].append(_route_event("node_selected", node_select_snapshot, selected_node, candidate_index))
	run.select_node(candidate_index)
	var failed_snapshot: Dictionary = run.apply_combat_input({"type": "resolve", "outcome": "failed"})
	telemetry["combat"].append(_combat_event(0, failed_snapshot, "failed"))
	telemetry["hazard"].append(_hazard_event(0, failed_snapshot))
	telemetry["ui"].append({"event": "defeat_page_shown", "retryOptions": ["same_seed", "new_seed"]})
	telemetry["narrative"].append({"event": "failure_beat_available", "beatId": "first_failure"})
	return _build_result(bool(failed_snapshot.get("failed", false)), fixture, failed_snapshot, telemetry, 0, str(selected_node.get("id", "")), [])

# ?ㅽ뻾: build a fresh node-select retry snapshot while preserving M8 progress and unlock state.
func retry_from(previous_result: Dictionary, mode: String) -> Dictionary:
	var previous_seed := int(previous_result.get("seed", DEFAULT_SEEDS[0]))
	var seed_value := _retry_seed_for_mode(previous_seed, mode)
	var fixture: Dictionary = m8_fixture({
		"seed": seed_value,
		"growth": previous_result.get("growth", {}),
		"progress": previous_result.get("progress", {})
	})
	var run = HeadlessMiniRunScript.new(fixture)
	var snapshot: Dictionary = run.snapshot()
	return _build_result(true, fixture, snapshot, _empty_telemetry(), 0, "", [])

# ?ㅽ뻾: return the stable seed policy used by runner and controller retry helpers.
static func retry_seed_for_mode(seed_value: int, mode: String) -> int:
	if mode == "same_seed":
		return seed_value
	return _next_seed(seed_value)

# ?ㅽ뻾: choose the currently available candidate, which is boss-locked on the final M8 stage.
func _candidate_index_for_stage(snapshot: Dictionary) -> int:
	var candidates: Array = snapshot.get("candidates", [])
	if candidates.is_empty():
		return 0
	for index in range(candidates.size()):
		var candidate: Dictionary = candidates[index]
		if str(candidate.get("id", "")) == M8_BOSS_NODE_ID:
			return index
	return 0

# ?ㅽ뻾: package a deterministic result dictionary for tests, batch runs, and telemetry export.
func _build_result(ok: bool, fixture: Dictionary, snapshot: Dictionary, telemetry: Dictionary, reward_phase_count: int, final_node_id: String, diagnostics: Array) -> Dictionary:
	var growth: Dictionary = snapshot.get("growth", {}).duplicate(true) if snapshot.get("growth", {}) is Dictionary else {}
	var progress: Dictionary = snapshot.get("progress", {}).duplicate(true) if snapshot.get("progress", {}) is Dictionary else {}
	var summary := {
		"ok": ok and diagnostics.is_empty(),
		"phase": str(snapshot.get("phase", "")),
		"runComplete": bool(snapshot.get("runComplete", false)),
		"failed": bool(snapshot.get("failed", false)),
		"failureReason": str(snapshot.get("failureReason", "")),
		"stageIndex": int(snapshot.get("stageIndex", -1)),
		"runIndex": int(snapshot.get("runIndex", -1)),
		"runCount": int(snapshot.get("runCount", fixture.get("runCount", M8_RUN_COUNT))),
		"leviathanId": str(snapshot.get("leviathanId", fixture.get("leviathanId", M8_LEVIATHAN_ID))),
		"stageCount": int(snapshot.get("maxStages", fixture.get("maxStages", M8_STAGE_COUNT))),
		"rewardPhaseCount": reward_phase_count,
		"finalNodeId": final_node_id,
		"timeToFirstValidHitTicks": _first_valid_hit_ticks(telemetry)
	}
	return {
		"ok": bool(summary["ok"]),
		"seed": int(fixture.get("seed", DEFAULT_SEEDS[0])),
		"fixture": fixture.duplicate(true),
		"snapshot": snapshot.duplicate(true),
		"summary": summary,
		"progress": progress,
		"growth": growth,
		"telemetry": _clone_telemetry(telemetry),
		"diagnostics": diagnostics.duplicate(true)
	}

# ?ㅽ뻾: create an empty telemetry bundle with all M8 schema categories present.
func _empty_telemetry() -> Dictionary:
	return {"combat": [], "reward": [], "route": [], "hazard": [], "ui": [], "narrative": []}

# ?ㅽ뻾: clone telemetry category arrays without exposing mutable runner internals.
func _clone_telemetry(telemetry: Dictionary) -> Dictionary:
	var result := {}
	for category in ["combat", "reward", "route", "hazard", "ui", "narrative"]:
		result[category] = telemetry.get(category, []).duplicate(true) if telemetry.get(category, []) is Array else []
	return result

# ?ㅽ뻾: summarize a selected route event.
func _route_event(event_name: String, snapshot: Dictionary, selected_node: Dictionary, candidate_index: int) -> Dictionary:
	var candidates: Array = snapshot.get("candidates", [])
	var ids := []
	for candidate in candidates:
		ids.append(str(candidate.get("id", "")))
	return {
		"event": event_name,
		"stageIndex": int(snapshot.get("stageIndex", -1)),
		"candidateIndex": candidate_index,
		"candidateIds": ids,
		"nodeId": str(selected_node.get("id", "")),
		"nodeType": str(selected_node.get("nodeType", "")),
		"isBoss": str(selected_node.get("id", "")) == M8_BOSS_NODE_ID
	}

# ?ㅽ뻾: summarize one combat resolution for telemetry export.
func _combat_event(stage_index: int, snapshot: Dictionary, outcome: String) -> Dictionary:
	var combat: Dictionary = snapshot.get("combat", {}) if snapshot.get("combat", {}) is Dictionary else {}
	var summary: Dictionary = combat.get("summary", {}) if combat.get("summary", {}) is Dictionary else {}
	return {
		"event": "combat_resolved",
		"stageIndex": stage_index,
		"outcome": outcome,
		"result": str(combat.get("result", outcome)),
		"shotsFired": int(summary.get("shots_fired", 0)),
		"shotsHitMatch": int(summary.get("shots_hit_match", 0)),
		"ticksToFirstValidHit": 0 if outcome == "clear" else -1
	}

# ?ㅽ뻾: summarize hazard state without changing hazard rules.
func _hazard_event(stage_index: int, snapshot: Dictionary) -> Dictionary:
	var combat: Dictionary = snapshot.get("combat", {}) if snapshot.get("combat", {}) is Dictionary else {}
	var hazard: Dictionary = combat.get("hazard", {}) if combat.get("hazard", {}) is Dictionary else {}
	return {
		"event": "hazard_state_sampled",
		"stageIndex": stage_index,
		"severity": str(hazard.get("severity", "stable")),
		"active": bool(hazard.get("active", false))
	}

# ?ㅽ뻾: find the first valid-hit timing metric from combat telemetry.
func _first_valid_hit_ticks(telemetry: Dictionary) -> int:
	for event in telemetry.get("combat", []):
		if event is Dictionary and int(event.get("ticksToFirstValidHit", -1)) >= 0:
			return int(event.get("ticksToFirstValidHit", 0))
	return 0

# ?ㅽ뻾: choose retry seed mode from the public runner helper.
func _retry_seed_for_mode(seed_value: int, mode: String) -> int:
	return retry_seed_for_mode(seed_value, mode)

# ?ㅽ뻾: generate a deterministic non-identical seed for headless tests and UI retry.
static func _next_seed(seed_value: int) -> int:
	return int((int(seed_value) + 104729) & 0x7fffffff)

# ?ㅽ뻾: find a content table row by id.
func _find_by_id(rows: Array, row_id: String) -> Dictionary:
	for row in rows:
		if row is Dictionary and str(row.get("id", "")) == row_id:
			return row
	return {}
