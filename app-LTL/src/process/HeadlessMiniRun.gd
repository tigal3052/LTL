# 계약:
# - 책임: formal root state가 node_select -> combat -> reward_loot -> run_complete 순서로 전이하는 headless orchestration 경계를 제공한다.
# - 입력: seed, run metadata, validated node data, validated reward/progress data, normalized combat event.
# - 출력: phase-safe public snapshot을 만들어 내는 headless runtime contract.
# - 금지: scene rendering, direct input device handling, browser object shape를 무비판적으로 복사하지 않는다.
#
# 실행: define the headless mini-run class identity.
class_name HeadlessMiniRun
extends RefCounted

# 실행: preload formal contracts for cloning and tuning helpers.
const FormalContractsScript = preload("res://src/domain/FormalContracts.gd")
const ArtifactScript = preload("res://src/models/Artifact.gd")

# 실행: hold the contract helper and private runtime state.
var contracts := FormalContractsScript.new()
var state: Dictionary = {}

# 실행: initialize root state, tuning, candidates, and the first node_select phase.
func _init(options: Dictionary = {}) -> void:
	var seed_val: int = int(options.get("seed", 1)) & 0x7fffffff
	var max_stages: int = maxi(1, int(options.get("maxStages", 5)))
	var run_count: int = maxi(1, int(options.get("runCount", 1)))
	var node_table: Dictionary = options.get("nodeTable", _default_node_table())
	var tuning: Dictionary = contracts.create_game_tuning(options.get("tuning", {}))
	tuning["maxStages"] = max_stages
	
	state = {
		"seed": seed_val,
		"stageIndex": 0,
		"maxStages": max_stages,
		"leviathanId": str(options.get("leviathanId", "training_leviathan")),
		"runIndex": int(options.get("runIndex", 0)),
		"runCount": run_count,
		"inventory": options.get("inventory", _default_inventory()),
		"progress": options.get("progress", {"clearedLeviathanIds": []}).duplicate(true),
		"phase": "node_select",
		"candidates": NodeVocab.generate_candidates(seed_val, 0, node_table, int(options.get("candidateCount", 5)), tuning),
		"combat": null,
		"pendingRewards": [],
		"held": null,
		"lastNodeLabel": "",
		"runComplete": false,
		"failed": false,
		"failureReason": "",
		"nodeTable": node_table.duplicate(true),
		"candidateCount": maxi(1, int(options.get("candidateCount", 5))),
		"queueCapacity": maxi(0, int(options.get("queueCapacity", int(tuning["queue"]["capacity"])))),
		"tuning": tuning,
		"growth": options.get("growth", _load_default_growth())
	}

# 실행: clone private state into a public snapshot boundary.
func snapshot() -> Dictionary:
	return {
		"seed": state["seed"],
		"stageIndex": state["stageIndex"],
		"maxStages": state["maxStages"],
		"leviathanId": state["leviathanId"],
		"runIndex": state["runIndex"],
		"runCount": state["runCount"],
		"inventory": state["inventory"].duplicate(true) if state["inventory"] is Dictionary else {},
		"progress": state["progress"].duplicate(true),
		"phase": state["phase"],
		"candidates": _clone_array(state["candidates"]),
		"combat": _clone_nullable(state["combat"]),
		"pendingRewards": _clone_array(state["pendingRewards"]),
		"held": _clone_nullable(state["held"]),
		"lastNodeLabel": state["lastNodeLabel"],
		"runComplete": state["runComplete"],
		"failed": state["failed"],
		"failureReason": state["failureReason"],
		"growth": state["growth"].duplicate(true) if state["growth"] is Dictionary else {}
	}

# 실행: select a node and transition state via PhaseReducers.
func select_node(candidate_index: int) -> Dictionary:
	state = PhaseReducers.reduce_phase(state, {"type": "select_node", "index": candidate_index})
	return snapshot()

# 실행: apply a combat input event and transition state via PhaseReducers.
func apply_combat_input(input: Dictionary) -> Dictionary:
	state = PhaseReducers.reduce_phase(state, input)
	return snapshot()

# 실행: claim stage rewards and transition state via PhaseReducers.
func claim_rewards() -> Dictionary:
	state = PhaseReducers.reduce_phase(state, {"type": "claim_rewards"})
	return snapshot()

# 실행: remove an inventory artifact and transition state via PhaseReducers.
func remove_inventory_artifact(artifact_id: String) -> Dictionary:
	state = PhaseReducers.reduce_phase(state, {"type": "remove_inventory_artifact", "artifactId": artifact_id})
	return snapshot()

# 실행: provide a default minimal node table.
func _default_node_table() -> Dictionary:
	var file := FileAccess.open("res://src/data/node-table.json", FileAccess.READ)
	if file != null:
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.get_data()
			if data is Dictionary and data.has("nodes"):
				return data
	return {"nodes": [{"id": "normal", "label": "Normal Node", "nodeType": "normal", "riskTier": "safe", "weakness": ["red"], "pickWeight": 1, "shieldMul": 1, "healthMul": 1, "alwaysOffer": true, "rewardBias": "baseline", "recommendedBuildHint": "Any stable drill line", "difficultyModifier": 1.0, "rewardModifier": 1.0, "hazardModifier": 1.0}]}

# 실행: clone nullable values safely.
func _clone_nullable(value: Variant) -> Variant:
	if value == null:
		return null
	return contracts.clone_value(value)

# 실행: clone arrays safely.
func _clone_array(value: Variant) -> Array:
	return value.duplicate(true) if value is Array else []

# 실행: provide a default starting inventory setup.
func _default_inventory() -> Dictionary:
	var inv = InventoryModel.new(8, 8)
	var drills = ArtifactScript.get_basic_drills()
	var positions = [
		Vector2(1, 2),
		Vector2(4, 1),
		Vector2(2, 4),
		Vector2(6, 5)
	]
	for i in range(drills.size()):
		var art = drills[i]
		var pos = positions[i]
		inv.place_artifact(art, int(pos.x), int(pos.y))
	return inv.to_dict()

# 실행: load the default progression from progression-default.json.
func _load_default_growth() -> Dictionary:
	var file := FileAccess.open("res://src/data/progression-default.json", FileAccess.READ)
	if file != null:
		var json_text := file.get_as_text()
		var json := JSON.new()
		var parse_err = json.parse(json_text)
		if parse_err == OK:
			var data = json.get_data()
			if data is Dictionary:
				return data
	# Fallback
	return {
		"gold": 100,
		"xp": 0,
		"purchasedPassives": {
			"starting_gold_boost": 0,
			"cooldown_reduction": 0,
			"aim_damage_boost": 0
		},
		"temporaryModifiers": {},
		"runModifiers": {},
		"rewardHistory": []
	}
