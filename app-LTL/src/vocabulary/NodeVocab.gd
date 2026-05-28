# 계약:
# - 책임: 탐험 노드 생성 및 선택에 관한 순수 동사 함수들을 제공한다.
# - 입력: 시드 값, 스테이지 인덱스, 노드 테이블 Dictionary, 후보 수, 튜닝 설정 Dictionary.
# - 출력: 생성된 후보 노드 목록 Array.
# - 금지: SceneTree 접근, 자체 상태 보존 (static func만 가짐).
#
# 실행: define the NodeVocab static entry.
class_name NodeVocab
extends RefCounted

# 실행: generate node candidates ensuring the normal/always-offered node is included.
static func generate_candidates(seed_val: int, stage_index: int, node_table: Dictionary, candidate_count: int, tuning: Dictionary) -> Array:
	var nodes: Array = node_table.get("nodes", [])
	var max_stages := maxi(1, int(tuning.get("maxStages", tuning.get("run", {}).get("maxStages", stage_index + 2))))
	var routing_tuning: Dictionary = tuning.get("nodeRouting", {})
	var min_candidates := maxi(1, int(routing_tuning.get("minCandidates", 1)))
	var max_candidates := maxi(min_candidates, int(routing_tuning.get("maxCandidates", max(candidate_count, min_candidates))))
	var desired_count := clampi(candidate_count, min_candidates, max_candidates)
	var normal_node: Dictionary = {}
	var boss_node: Dictionary = {}
	for node in nodes:
		if node.get("alwaysOffer", false) == true or node.get("id", "") == "normal":
			normal_node = node
		if bool(node.get("isBoss", false)) or str(node.get("nodeType", "")) == "boss":
			boss_node = node
	if normal_node.is_empty():
		push_error("node table must include a normal node")
		return []

	var stage_combat := _compute_stage_combat_params(stage_index, tuning)

	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val + stage_index * 1337

	var selected: Array = []
	var selected_ids = {}
	var is_final_stage := stage_index >= max_stages - 1
	if is_final_stage and not boss_node.is_empty():
		selected.append(boss_node.duplicate(true))
		selected_ids[boss_node.get("id", "")] = true
	selected.append(normal_node.duplicate(true))
	selected_ids[normal_node.get("id", "")] = true

	var available_nodes: Array = []
	for node in nodes:
		if selected_ids.has(node.get("id", "")):
			continue
		available_nodes.append({"node": node, "score": rng.randf() / maxf(0.001, float(node.get("pickWeight", 1.0)))})
	available_nodes.sort_custom(func(a, b): return float(a["score"]) < float(b["score"]))
	for entry in available_nodes:
		if selected.size() >= desired_count:
			break
		selected.append(entry["node"].duplicate(true))
		selected_ids[entry["node"].get("id", "")] = true

	var result: Array = []
	for node in selected:
		var candidate: Dictionary = node.duplicate(true)
		_normalize_route_fields(candidate, seed_val, stage_index, max_stages)
		if node.has("combat") and node["combat"] is Dictionary:
			candidate["combat"] = node["combat"].duplicate(true)
		else:
			candidate["combat"] = {
				"shield": stage_combat["shield"] * float(node.get("shieldMul", 1.0)),
				"health": stage_combat["health"] * float(node.get("healthMul", 1.0)),
				"timeLimitTicks": stage_combat["timeLimitTicks"],
				"weakness": node.get("weakness", []).duplicate(true)
			}
		candidate["telemetry"] = {
			"event": "node_choices_offered",
			"candidate_ids": _candidate_ids(selected),
			"candidate_types": _candidate_types(selected),
			"candidate_weaknesses": _candidate_weaknesses(selected),
			"candidate_risk_tiers": _candidate_risk_tiers(selected),
			"route_hash": candidate["routeHash"]
		}
		result.append(candidate)
	return result

# 실행: normalize candidate route fields used by node map and selection contracts.
static func _normalize_route_fields(candidate: Dictionary, seed_val: int, stage_index: int, max_stages: int) -> void:
	candidate["nodeType"] = str(candidate.get("nodeType", "normal"))
	candidate["riskTier"] = str(candidate.get("riskTier", "safe"))
	candidate["rewardBias"] = str(candidate.get("rewardBias", "baseline"))
	candidate["recommendedBuildHint"] = str(candidate.get("recommendedBuildHint", "Any stable drill line"))
	candidate["difficultyModifier"] = float(candidate.get("difficultyModifier", 1.0))
	candidate["rewardModifier"] = float(candidate.get("rewardModifier", 1.0))
	candidate["hazardModifier"] = float(candidate.get("hazardModifier", 1.0))
	candidate["finalStageDistance"] = maxi(0, max_stages - stage_index - 1)
	candidate["routeHash"] = "%d:%d:%s" % [seed_val, stage_index, str(candidate.get("id", ""))]

# 실행: collect offered candidate identifiers for telemetry payloads.
static func _candidate_ids(candidates: Array) -> Array:
	var result := []
	for candidate in candidates:
		result.append(str(candidate.get("id", "")))
	return result

# 실행: collect offered candidate types for telemetry payloads.
static func _candidate_types(candidates: Array) -> Array:
	var result := []
	for candidate in candidates:
		result.append(str(candidate.get("nodeType", "normal")))
	return result

# 실행: collect offered candidate weaknesses for telemetry payloads.
static func _candidate_weaknesses(candidates: Array) -> Array:
	var result := []
	for candidate in candidates:
		result.append(candidate.get("weakness", []).duplicate(true))
	return result

# 실행: collect offered candidate risk tiers for telemetry payloads.
static func _candidate_risk_tiers(candidates: Array) -> Array:
	var result := []
	for candidate in candidates:
		result.append(str(candidate.get("riskTier", "safe")))
	return result

# 실행: compute scaling parameters for the stage combat nodes using cumulative Gaussian delta bumps.
static func _compute_stage_combat_params(stage_index: int, tuning: Dictionary) -> Dictionary:
	var scaling: Dictionary = tuning.get("stageScaling", {})
	
	var base_shield := float(scaling.get("baseShield", 50.0))
	var base_health := float(scaling.get("baseHealth", 50.0))
	var base_time_limit := int(scaling.get("baseTimeLimitTicks", 2400))
	
	var peak_stage := float(scaling.get("peakStage", 3.25))
	var sigma := float(scaling.get("sigma", 1.65))
	var peak_shield_delta := float(scaling.get("peakShieldDelta", 0.55))
	var peak_health_delta := float(scaling.get("peakHealthDelta", 0.72))
	var peak_time_cut := float(scaling.get("peakTimeCutTicks", 140))
	var min_time_limit := int(scaling.get("minTimeLimitTicks", 360))
	
	var shield := base_shield
	var health := base_health
	var time_limit_ticks := float(base_time_limit)
	
	for k in range(stage_index):
		shield += _gaussian_bump(float(k), peak_stage, sigma, peak_shield_delta)
		health += _gaussian_bump(float(k), peak_stage, sigma, peak_health_delta)
		time_limit_ticks -= _gaussian_bump(float(k), peak_stage, sigma, peak_time_cut)
		
	time_limit_ticks = maxf(float(min_time_limit), floorf(time_limit_ticks))
	
	return {
		"shield": shield,
		"health": health,
		"timeLimitTicks": int(time_limit_ticks)
	}

# 실행: calculate Gaussian bump delta for the given stage index.
static func _gaussian_bump(k: float, peak_stage: float, sigma: float, peak: float) -> float:
	if sigma == 0.0:
		return 0.0
	var z := (k - peak_stage) / sigma
	return peak * exp(-0.5 * z * z)
