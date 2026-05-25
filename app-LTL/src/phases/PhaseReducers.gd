# 계약:
# - 책임: 현재 페이즈 상태 문자열(tag)에 맞춰 적절한 개별 페이즈 리듀서(NodeSelect, Combat, RewardLoot 등)로 처리를 분기 위임한다.
# - 입력: 현재 상태 Dictionary, 처리할 이벤트 Dictionary.
# - 출력: 개별 페이즈에서 처리된 결과 다음 상태 Dictionary.
# - 금지: SceneTree 접근, 직접적인 비즈니스 로직 연산.
#
# 실행: define the PhaseReducers class identity.
class_name PhaseReducers
extends RefCounted

# 실행: route the event to the appropriate phase reducer based on current phase state.
static func reduce_phase(state: Dictionary, event: Dictionary) -> Dictionary:
	var phase := String(state.get("phase", "node_select"))
	match phase:
		"node_select":
			return NodeSelectPhase.reduce(state, event)
		"combat_start":
			return CombatStartPhase.reduce(state, event)
		"combat":
			return CombatPhase.reduce(state, event)
		"combat_end":
			return CombatEndPhase.reduce(state, event)
		"reward_loot":
			return RewardLootPhase.reduce(state, event)
		"run_complete":
			return RunCompletePhase.reduce(state, event)
		_:
			push_error("unsupported phase tag: %s" % phase)
			return state
