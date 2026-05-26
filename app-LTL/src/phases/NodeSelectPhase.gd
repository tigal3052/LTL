# 계약:
# - 책임: 탐험 노드 선택 페이즈(node_select)에서의 상태 전이(reduce)를 개별 관리한다.
# - 입력: 현재 페이즈 상태 Dictionary, 처리할 이벤트 Dictionary.
# - 출력: 전이된 다음 페이즈 상태 Dictionary.
# - 금지: SceneTree 접근, 타 페이즈 상태 직접 변경.
#
# 실행: define the NodeSelectPhase class identity.
class_name NodeSelectPhase
extends RefCounted

# 실행: reduce node selection inputs and transition state to combat phase.
static func reduce(state: Dictionary, event: Dictionary) -> Dictionary:
	var event_type := String(event.get("type", ""))
	# 리플레이 등에서 select_node 또는 choose_node 등으로 혼용하여 전송할 수 있으므로 호환성 처리
	if event_type == "select_node" or event_type == "choose_node" or event.has("index") or event.has("target"):
		var candidates: Array = state.get("candidates", [])
		var idx: int = int(event.get("index", event.get("target", 0)))
		if idx < 0 or idx >= candidates.size():
			return state
		
		# 리사이클링용 active_colors 계산
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
			
		var choice: Dictionary = candidates[idx].duplicate(true)
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
		next_state["combat"] = sim.to_dict()
		next_state["candidates"] = [] # 선택 완료 후 후보 목록 비우기
		return next_state
	return state
