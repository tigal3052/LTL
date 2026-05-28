# 계약:
# - 책임: 자율 노드 선택 phase에서 상태 전이(reduce)를 개별 관리한다.
# - 입력: 현재 phase 상태 Dictionary, 처리할 event Dictionary.
# - 출력: 선택 결과가 반영된 다음 phase 상태 Dictionary.
# - 금지: SceneTree 접근, 다른 phase 상태 직접 변경.
#
# 실행: define the NodeSelectPhase class identity.
class_name NodeSelectPhase
extends RefCounted
const ApplyNodeModifiersScript = preload("res://src/vocabulary/node/ApplyNodeModifiers.gd")

# 실행: reduce node selection inputs and transition state to combat phase.
static func reduce(state: Dictionary, event: Dictionary) -> Dictionary:
	var event_type := String(event.get("type", ""))
	if event_type == "select_node" or event_type == "choose_node" or event.has("index") or event.has("target"):
		var candidates: Array = state.get("candidates", [])
		var idx: int = int(event.get("index", event.get("target", 0)))
		if idx < 0 or idx >= candidates.size():
			return state

		var active_colors: Array = []
		var inv_data = state.get("inventory", {})
		if inv_data is Dictionary and inv_data.has("artifacts"):
			for art in inv_data["artifacts"]:
				var itype = str(art.get("item_type", art.get("itemType", "drill")))
				if itype == "drill" or itype == "":
					var color = str(art.get("energyType", ""))
					if not color.is_empty() and not color in active_colors:
						active_colors.append(color)
		if active_colors.is_empty():
			active_colors.append("red")

		var choice: Dictionary = ApplyNodeModifiersScript.apply(candidates[idx], state.get("tuning", {}))
		if not choice.has("combat") or not (choice["combat"] is Dictionary):
			choice["combat"] = {}

		var next_state := state.duplicate(true)
		next_state["phase"] = "combat"
		next_state["lastNodeLabel"] = choice.get("label", "")

		var q_capacity: int = int(state.get("queueCapacity", 8))
		var initial_q = []
		for i in range(q_capacity):
			initial_q.append(active_colors[i % active_colors.size()])
		choice["combat"]["initialQueue"] = initial_q

		var sim := CombatVocab.prepare_combat(choice, state.get("tuning", {}), q_capacity)
		var combat_state := sim.to_dict()
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
