# 계약:
# - 책임: 전투 시작 전 준비 페이즈(combat_start)에서의 상태 전이(reduce)를 개별 관리한다.
# - 입력: 현재 페이즈 상태 Dictionary, 처리할 이벤트 Dictionary.
# - 출력: 전이된 다음 페이즈 상태 Dictionary.
# - 금지: SceneTree 접근.
#
# 실행: define the CombatStartPhase class identity.
class_name CombatStartPhase
extends RefCounted

# 실행: transition from combat_start to combat phase.
static func reduce(state: Dictionary, event: Dictionary) -> Dictionary:
	var event_type := String(event.get("type", ""))
	if event_type == "start_combat":
		var next_state := state.duplicate(true)
		next_state["phase"] = "combat"
		return next_state
	return state
