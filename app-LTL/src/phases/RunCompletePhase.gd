# 계약:
# - 책임: 런 종료 페이즈(run_complete)에서의 최종 상태 보존을 담당한다.
# - 입력: 현재 페이즈 상태 Dictionary, 처리할 이벤트 Dictionary.
# - 출력: 변경되지 않는 최종 페이즈 상태 Dictionary.
# - 금지: 추가 상태 전이 허용.
#
# 실행: define the RunCompletePhase class identity.
class_name RunCompletePhase
extends RefCounted

# 실행: return the state as is since run_complete is the terminal phase.
static func reduce(state: Dictionary, _event: Dictionary) -> Dictionary:
	return state
