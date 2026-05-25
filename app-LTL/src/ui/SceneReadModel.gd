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
	return {"ok": validation["ok"], "diagnostics": validation["diagnostics"], "phase": run_snapshot.get("phase", "unknown"), "stageIndex": run_snapshot.get("stageIndex", -1), "maxStages": run_snapshot.get("maxStages", -1), "runIndex": run_snapshot.get("runIndex", -1), "runCount": run_snapshot.get("runCount", -1), "lastNodeLabel": run_snapshot.get("lastNodeLabel", ""), "runComplete": run_snapshot.get("runComplete", false), "failed": run_snapshot.get("failed", false), "failureReason": run_snapshot.get("failureReason", ""), "inventory": _clone_array(run_snapshot.get("inventory", [])), "candidates": _project_candidates(run_snapshot.get("candidates", []), labels), "combat": _project_combat(run_snapshot.get("combat", null)), "reward": _project_rewards(run_snapshot.get("pendingRewards", []), run_snapshot.get("held", null)), "progress": run_snapshot.get("progress", {}).duplicate(true)}

# 실행: project candidate rows into display-safe node-select data.
func _project_candidates(candidates: Array, labels: Dictionary) -> Array:
	var result: Array = []
	for candidate in candidates:
		var weakness: Array = _clone_array(candidate.get("weakness", candidate.get("combat", {}).get("weakness", [])))
		result.append({"id": candidate.get("id", ""), "label": _display_label(candidate.get("label", candidate.get("id", "")), labels), "weakness": weakness, "weaknessLabel": _display_label(",".join(weakness), labels)})
	return result

# 실행: project combat data without leaking mutable runtime references.
func _project_combat(combat: Variant) -> Variant:
	if combat == null:
		return null
	return {"result": combat.get("result", "unknown"), "weakness": _clone_array(combat.get("weakness", [])), "shield": combat.get("shield", 0.0), "health": combat.get("health", 0.0), "maxShield": combat.get("maxShield", 0.0), "maxHealth": combat.get("maxHealth", 0.0), "timeLimitTicks": combat.get("timeLimitTicks", 0), "summary": combat.get("summary", {}).duplicate(true), "queue": combat.get("queue", {}).duplicate(true), "pin": combat.get("pin", {}).duplicate(true), "repair": combat.get("repair", {}).duplicate(true), "hazard": combat.get("hazard", {}).duplicate(true), "aim": combat.get("aim", {}).duplicate(true), "battlefield": combat.get("battlefield", {}).duplicate(true), "disabled": combat.get("disabled", false)}

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
