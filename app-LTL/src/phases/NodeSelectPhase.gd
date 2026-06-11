# 계약:
# - 책임: 자율 노드 선택 phase에서 상태 전이(reduce)를 개별 관리한다.
# - 입력: 현재 phase 상태 Dictionary, 처리할 event Dictionary.
# - 출력: 선택 결과가 반영된 다음 phase 상태 Dictionary.
# - 금지: SceneTree 접근, 다른 phase 상태 직접 변경.
#
# 실행: define the NodeSelectPhase class identity.
class_name NodeSelectPhase
extends RefCounted
const ArtifactScript = preload("res://src/models/Artifact.gd")
const ApplyNodeModifiersScript = preload("res://src/vocabulary/node/ApplyNodeModifiers.gd")
const CombatVocabScript = preload("res://src/vocabulary/CombatVocab.gd")
const EnergyTempoBalanceScript = preload("res://src/balance/EnergyTempoBalance.gd")

# 실행: reduce node selection inputs and transition state to combat phase.
static func reduce(state: Dictionary, event: Dictionary) -> Dictionary:
	var event_type := String(event.get("type", ""))
	if event_type == "select_node" or event_type == "choose_node" or event.has("index") or event.has("target"):
		var candidates: Array = state.get("candidates", [])
		var idx: int = int(event.get("index", event.get("target", 0)))
		if idx < 0 or idx >= candidates.size():
			return state

		var active_drills: Array = []
		var inv_data = state.get("inventory", {})
		if inv_data is Dictionary and inv_data.has("artifacts"):
			for art in inv_data["artifacts"]:
				var itype = str(art.get("item_type", art.get("itemType", "drill")))
				if itype == "drill" or itype == "":
					var color = str(art.get("energyType", ""))
					var artifact_id = str(art.get("id", ""))
					if color.is_empty():
						continue
					var already_seen := false
					for token in active_drills:
						if str(token.get("color", "")) == color:
							already_seen = true
							break
					if not already_seen:
						active_drills.append({
							"color": color,
							"source_artifact_id": artifact_id,
							"source_item_type": "drill"
						})
		if active_drills.is_empty():
			active_drills.append({
				"color": "red",
				"source_artifact_id": "",
				"source_item_type": "drill"
			})

		var choice: Dictionary = ApplyNodeModifiersScript.apply(candidates[idx], state.get("tuning", {}))
		if not choice.has("combat") or not (choice["combat"] is Dictionary):
			choice["combat"] = {}

		var next_state := state.duplicate(true)
		next_state["phase"] = "combat"
		next_state["lastNodeLabel"] = choice.get("label", "")
		var route_history: Array = next_state.get("routeHistory", []).duplicate(true)
		route_history.append(_history_entry_for_choice(choice, int(state.get("stageIndex", 0)), idx))
		next_state["routeHistory"] = route_history

		var q_capacity: int = int(state.get("queueCapacity", EnergyTempoBalanceScript.DEFAULT_QUEUE_CAPACITY))
		var initial_q = []
		var initial_load := EnergyTempoBalanceScript.initial_queue_loaded_count(q_capacity)
		for i in range(initial_load):
			initial_q.append(active_drills[i % active_drills.size()].duplicate(true))
		choice["combat"]["initialQueue"] = initial_q

		var sim: CombatSimulator = CombatVocabScript.prepare_combat(choice, state.get("tuning", {}), q_capacity)
		var inventory := _restore_inventory(state.get("inventory", {}))
		CombatVocabScript.prime_obstacles(
			sim,
			int(state.get("seed", 1)),
			int(state.get("stageIndex", 0)),
			float(choice.get("combat", {}).get("hazardModifier", 1.0)),
			inventory
		)
		var combat_state: Dictionary = sim.to_dict()
		_copy_node_metadata(combat_state, choice.get("combat", {}))
		next_state["combat"] = combat_state
		next_state["selectedNode"] = choice.get("combat", {}).get("node", {}).duplicate(true)
		next_state["candidates"] = []
		return next_state
	return state

# 실행: preserve selected route metadata after CombatSimulator exports the runtime state.
static func _copy_node_metadata(combat_state: Dictionary, source_combat: Dictionary) -> void:
	for key in ["node", "hazard", "telemetry"]:
		if source_combat.has(key):
			combat_state[key] = source_combat[key].duplicate(true)
	combat_state["rewardModifier"] = float(source_combat.get("rewardModifier", 1.0))
	combat_state["difficultyModifier"] = float(source_combat.get("difficultyModifier", 1.0))
	combat_state["hazardModifier"] = float(source_combat.get("hazardModifier", 1.0))

static func _restore_inventory(inv_data: Variant) -> InventoryModel:
	if not (inv_data is Dictionary):
		return null
	var inventory := InventoryModel.new(int(inv_data.get("width", 8)), int(inv_data.get("height", 8)))
	for art_dict in inv_data.get("artifacts", []):
		var artifact := ArtifactScript.new(art_dict)
		inventory.place_artifact(artifact, artifact.x, artifact.y)
	return inventory

static func _history_entry_for_choice(choice: Dictionary, stage_index: int, route_slot_index: int) -> Dictionary:
	return {
		"stageIndex": stage_index,
		"routeSlotIndex": route_slot_index,
		"id": str(choice.get("id", "")),
		"label": str(choice.get("label", "")),
		"nodeType": str(choice.get("nodeType", "normal")),
		"riskTier": str(choice.get("riskTier", "safe")),
		"rewardBias": str(choice.get("rewardBias", "baseline")),
		"recommendedBuildHint": str(choice.get("recommendedBuildHint", "")),
		"isEvent": bool(choice.get("isEvent", false)),
		"weakness": choice.get("weakness", []).duplicate(true)
	}
