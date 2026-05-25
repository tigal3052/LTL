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
	var normal_node: Dictionary = {}
	for node in nodes:
		if node.get("alwaysOffer", false) == true or node.get("id", "") == "normal":
			normal_node = node
			break
	if normal_node.is_empty():
		push_error("node table must include a normal node")
		return []

	var stage_combat := _compute_stage_combat_params(stage_index, tuning)
	var raw: Array = [normal_node.duplicate(true)]
	for node in nodes:
		if raw.size() >= candidate_count:
			break
		if node.get("id", "") != normal_node.get("id", ""):
			raw.append(node.duplicate(true))

	var result: Array = []
	for node in raw:
		var candidate: Dictionary = node.duplicate(true)
		if node.has("combat") and node["combat"] is Dictionary:
			candidate["combat"] = node["combat"].duplicate(true)
		else:
			candidate["combat"] = {
				"shield": stage_combat["shield"] * float(node.get("shieldMul", 1.0)),
				"health": stage_combat["health"] * float(node.get("healthMul", 1.0)),
				"timeLimitTicks": stage_combat["timeLimitTicks"],
				"weakness": node.get("weakness", []).duplicate(true)
			}
		result.append(candidate)
	return result

# 실행: compute scaling parameters for the stage combat nodes using cumulative Gaussian delta bumps.
static func _compute_stage_combat_params(stage_index: int, tuning: Dictionary) -> Dictionary:
	var scaling: Dictionary = tuning.get("stageScaling", {})
	
	var base_shield := float(scaling.get("baseShield", 2.4))
	var base_health := float(scaling.get("baseHealth", 3.2))
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
