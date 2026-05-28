# 계약:
# - 책임: combat feedback status를 화면 피드백 primitive 모델로 변환한다.
# - 입력: combat result status string.
# - 출력: screenshake duration/magnitude dictionary.
# - 금지: VFX 직접 실행, UI node 접근, combat state 변경.
#
# 실행: define a stateless presenter for combat feedback decisions.
class_name CombatFeedbackPresenter
extends RefCounted

# 실행: project combat status into screenshake parameters.
static func project_screenshake(status: String) -> Dictionary:
	if status in ["match", "clear"]:
		return {"duration": 0.18, "magnitude": 7.0}
	if status == "mismatch":
		return {"duration": 0.12, "magnitude": 3.0}
	return {"duration": 0.08, "magnitude": 1.0}
