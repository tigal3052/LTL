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
		"candidates": NodeVocab.generate_candidates(seed_val, 0, node_table, int(options.get("candidateCount", 3)), tuning),
		"combat": null,
		"pendingRewards": [],
		"held": null,
		"lastNodeLabel": "",
		"runComplete": false,
		"failed": false,
		"failureReason": "",
		"nodeTable": node_table.duplicate(true),
		"candidateCount": maxi(1, int(options.get("candidateCount", 3))),
		"queueCapacity": maxi(0, int(options.get("queueCapacity", int(tuning["queue"]["capacity"])))),
		"tuning": tuning
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
		"failureReason": state["failureReason"]
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
	return {"nodes": [{"id": "normal", "label": "Normal Node", "weakness": ["red"], "pickWeight": 1, "shieldMul": 1, "healthMul": 1, "alwaysOffer": true}]}

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
	var items = [
		{"name": "Ruby Drill Core", "color": "red", "shape": [[1, 1]], "pos": Vector2(1, 2)},
		{"name": "Sapphire Lens", "color": "blue", "shape": [[1], [1]], "pos": Vector2(4, 1)},
		{"name": "Amethyst Resonance", "color": "purple", "shape": [[1, 1], [1, 1]], "pos": Vector2(2, 4)},
		{"name": "Emerald Capacitor", "color": "green", "shape": [[1]], "pos": Vector2(6, 5)}
	]
	var id_counter = 1
	for item in items:
		var art_data = {
			"id": "art_%d" % id_counter,
			"name": item["name"],
			"shape": item["shape"],
			"energyType": item["color"],
			"baseCooldownTicks": 100,
			"synergy": {"type": "same_color", "value": 2}
		}
		var art = Artifact.new(art_data)
		inv.place_artifact(art, int(item["pos"].x), int(item["pos"].y))
		id_counter += 1
	return inv.to_dict()
