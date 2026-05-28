# 계약:
# - 책임: 선택된 node candidate의 M4 route metadata를 combat-safe modifier snapshot으로 변환한다.
# - 입력: NodeVocab candidate Dictionary, formal tuning Dictionary.
# - 출력: combat, node, hazard, reward, telemetry metadata가 정규화된 candidate Dictionary.
# - 금지: SceneTree 접근, reward roll 직접 실행, phase 전환 직접 수행.
#
# 실행: define the ApplyNodeModifiers static entry.
class_name ApplyNodeModifiers
extends RefCounted

# 실행: clone the chosen node and attach explicit combat modifier metadata.
static func apply(choice: Dictionary, tuning: Dictionary = {}) -> Dictionary:
	var result := choice.duplicate(true)
	var combat: Dictionary = result.get("combat", {}).duplicate(true)
	var difficulty_modifier := float(result.get("difficultyModifier", 1.0))
	var reward_modifier := float(result.get("rewardModifier", 1.0))
	var hazard_modifier := float(result.get("hazardModifier", 1.0))
	var node_type := str(result.get("nodeType", result.get("id", "normal")))
	if not combat.has("shield"):
		combat["shield"] = 0.0
	if not combat.has("health"):
		combat["health"] = 0.0
	combat["difficultyModifier"] = difficulty_modifier
	combat["rewardModifier"] = reward_modifier
	combat["hazardModifier"] = hazard_modifier
	combat["node"] = _node_snapshot(result)
	combat["hazard"] = {
		"tier": str(result.get("riskTier", "safe")),
		"modifier": hazard_modifier,
		"sourceNodeId": str(result.get("id", ""))
	}
	combat["telemetry"] = {
		"event": "node_modifier_applied",
		"selected_node_id": str(result.get("id", "")),
		"selected_node_type": node_type,
		"difficulty_modifier": difficulty_modifier,
		"reward_modifier": reward_modifier,
		"hazard_modifier": hazard_modifier,
		"route_hash": str(result.get("routeHash", ""))
	}
	result["combat"] = combat
	return result

# 실행: build the selected node metadata carried by combat snapshots.
static func _node_snapshot(candidate: Dictionary) -> Dictionary:
	return {
		"id": str(candidate.get("id", "")),
		"label": str(candidate.get("label", "")),
		"nodeType": str(candidate.get("nodeType", "normal")),
		"riskTier": str(candidate.get("riskTier", "safe")),
		"weakness": candidate.get("weakness", []).duplicate(true),
		"rewardBias": str(candidate.get("rewardBias", "baseline")),
		"recommendedBuildHint": str(candidate.get("recommendedBuildHint", "")),
		"difficultyModifier": float(candidate.get("difficultyModifier", 1.0)),
		"rewardModifier": float(candidate.get("rewardModifier", 1.0)),
		"hazardModifier": float(candidate.get("hazardModifier", 1.0)),
		"finalStageDistance": int(candidate.get("finalStageDistance", 0)),
		"routeHash": str(candidate.get("routeHash", ""))
	}
