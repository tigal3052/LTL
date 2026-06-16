# 계약:
# - 책임: stabilized root/phase snapshot에서 scene 전체가 읽을 수 있는 public read model 경계를 제공한다.
# - 입력: HeadlessMiniRun public snapshot, FormalContracts validation result, optional static label tables.
# - 출력: node_select/combat/reward_loot/run_complete를 모두 다룰 수 있는 scene-safe Dictionary contract.
# - 금지: private runtime leakage, SceneTree mutation, browser DOM field 의존
#
# 실행: define the scene read model class identity.
class_name SceneReadModel
extends RefCounted

# 실행: preload formal contracts for snapshot validation.
const FormalContractsScript = preload("res://src/domain/FormalContracts.gd")

# 실행: create a contract helper for validating incoming public snapshots.
var contracts := FormalContractsScript.new()

# 실행: validate a run snapshot and project it into scene-safe read data.
func create(run_snapshot: Dictionary, options: Dictionary = {}) -> Dictionary:
	var validation := contracts.validate_public_snapshot(run_snapshot)
	var labels: Dictionary = options.get("labels", {})
	var phase := str(run_snapshot.get("phase", "unknown"))
	var stage_index := int(run_snapshot.get("stageIndex", -1))
	var max_stages := int(run_snapshot.get("maxStages", -1))
	return {
		"ok": validation["ok"],
		"diagnostics": validation["diagnostics"],
		"phase": phase,
		"stageIndex": stage_index,
		"maxStages": max_stages,
		"runIndex": run_snapshot.get("runIndex", -1),
		"runCount": run_snapshot.get("runCount", -1),
		"lastNodeLabel": run_snapshot.get("lastNodeLabel", ""),
		"runComplete": run_snapshot.get("runComplete", false),
		"failed": run_snapshot.get("failed", false),
		"failureReason": run_snapshot.get("failureReason", ""),
		"inventory": _clone_array(run_snapshot.get("inventory", [])),
		"candidates": _project_candidates(run_snapshot.get("candidates", []), labels),
		"routeHistory": _project_route_history(run_snapshot.get("routeHistory", []), labels),
		"futureUnknownCount": _future_unknown_count(phase, stage_index, max_stages),
		"isBossStage": phase == "node_select" and max_stages > 0 and stage_index >= max_stages - 1,
		"isFixedStartStage": phase == "node_select" and stage_index == 0,
		"combat": _project_combat(run_snapshot.get("combat", null)),
		"reward": _project_rewards(run_snapshot.get("pendingRewards", []), run_snapshot.get("held", null)),
		"growth": run_snapshot.get("growth", {}).duplicate(true),
		"progress": run_snapshot.get("progress", {}).duplicate(true)
	}

# 실행: project candidate rows into display-safe node-select data.
func _project_candidates(candidates: Array, labels: Dictionary) -> Array:
	var result: Array = []
	for candidate in candidates:
		result.append(_project_node_entry(candidate, labels))
	return result

# 실행: project cleared node history rows into display-safe data for the runtime page.
func _project_route_history(route_history: Array, labels: Dictionary) -> Array:
	var result: Array = []
	for entry in route_history:
		var projected := _project_node_entry(entry, labels)
		projected["stageIndex"] = int(entry.get("stageIndex", result.size()))
		projected["routeSlotIndex"] = int(entry.get("routeSlotIndex", -1))
		result.append(projected)
	return result

# 실행: project one node-like dictionary into a display-safe entry shared by candidates and route history.
func _project_node_entry(entry: Dictionary, labels: Dictionary) -> Dictionary:
	var combat: Dictionary = entry.get("combat", {}) if entry.get("combat", {}) is Dictionary else {}
	var weakness: Array = _clone_array(entry.get("weakness", combat.get("weakness", [])))
	return {
		"id": entry.get("id", ""),
		"label": _display_label(entry.get("label", entry.get("id", "")), labels),
		"nodeType": entry.get("nodeType", "normal"),
		"riskTier": entry.get("riskTier", "safe"),
		"rewardBias": entry.get("rewardBias", "baseline"),
		"recommendedBuildHint": entry.get("recommendedBuildHint", ""),
		"finalStageDistance": entry.get("finalStageDistance", 0),
		"routeHash": entry.get("routeHash", ""),
		"weakness": weakness,
		"weaknessLabel": _display_label(",".join(weakness), labels),
		"shield": float(combat.get("shield", 0.0)),
		"health": float(combat.get("health", 0.0)),
		"totalDurability": float(combat.get("shield", 0.0)) + float(combat.get("health", 0.0)),
		"isEvent": bool(entry.get("isEvent", false))
	}

# 실행: project combat data without leaking mutable runtime references.
func _project_combat(combat: Variant) -> Variant:
	if combat == null:
		return null
	return {"result": combat.get("result", "unknown"), "weakness": _clone_array(combat.get("weakness", [])), "shield": combat.get("shield", 0.0), "health": combat.get("health", 0.0), "maxShield": combat.get("maxShield", 0.0), "maxHealth": combat.get("maxHealth", 0.0), "timeLimitTicks": combat.get("timeLimitTicks", 0), "elapsedTicks": combat.get("elapsedTicks", 0), "summary": combat.get("summary", {}).duplicate(true), "queue": combat.get("queue", {}).duplicate(true), "pin": combat.get("pin", {}).duplicate(true), "repair": combat.get("repair", {}).duplicate(true), "hazard": combat.get("hazard", {}).duplicate(true), "aim": combat.get("aim", {}).duplicate(true), "battlefield": combat.get("battlefield", {}).duplicate(true), "disabled": combat.get("disabled", false)}

# 실행: project reward state into pending rewards and held item fields.
func _project_rewards(pending_rewards: Array, held: Variant) -> Dictionary:
	return {"pendingRewards": _clone_array(pending_rewards), "held": null if held == null else held.duplicate(true)}

# 실행: replace raw labels through a lookup table when one is available.
func _display_label(raw_label: Variant, labels: Dictionary) -> String:
	var text := String(raw_label)
	return String(labels.get(text, text))

# 실행: clone arrays safely and coerce non-array values to empty arrays.
func _clone_array(value: Variant) -> Array:
	return value.duplicate(true) if value is Array else []

# 실행: calculate how many unexplored non-boss stages remain hidden behind ? markers.
func _future_unknown_count(phase: String, stage_index: int, max_stages: int) -> int:
	if phase != "node_select" or max_stages <= 0:
		return 0
	return maxi(0, max_stages - stage_index - 2)
