# 계약:
# - 책임: 전투 종료 페이즈(combat_end)에서의 상태 전이(reduce)를 개별 관리한다.
# - 입력: 현재 페이즈 상태 Dictionary, 처리할 이벤트 Dictionary.
# - 출력: 전이된 다음 페이즈 상태 Dictionary.
# - 금지: SceneTree 접근.
#
# 실행: define the CombatEndPhase class identity.
class_name CombatEndPhase
extends RefCounted

# 실행: transition from combat_end to reward_loot phase.
static func reduce(state: Dictionary, event: Dictionary) -> Dictionary:
	var event_type := String(event.get("type", ""))
	if event_type == "end_combat_confirm":
		var next_state := state.duplicate(true)
		next_state["phase"] = "reward_loot"
		return next_state
	return state
