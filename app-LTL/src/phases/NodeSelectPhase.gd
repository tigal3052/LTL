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
		
		var choice: Dictionary = candidates[idx]
		var next_state := state.duplicate(true)
		next_state["phase"] = "combat"
		next_state["lastNodeLabel"] = choice.get("label", "")
		
		# 전투 시뮬레이터 생성 및 초기화
		var q_capacity: int = int(state.get("queueCapacity", 8))
		var sim := CombatVocab.prepare_combat(choice, state.get("tuning", {}), q_capacity)
		next_state["combat"] = sim.to_dict()
		next_state["candidates"] = [] # 선택 완료 후 후보 목록 비우기
		return next_state
	return state
