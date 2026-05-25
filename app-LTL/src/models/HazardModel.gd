# 계약:
# - 책임: 전투 내 방해 요소(위험 등급, 발생 종류, 대기 틱 수 등)의 상태를 관리하는 사물 모델 계약을 제공한다.
# - 입력: 초기화용 설정 Dictionary.
# - 출력: 현재 방해 요소 상태의 Dictionary 스냅샷.
# - 금지: SceneTree 접근, 직접적인 UI 렌더링.
#
# 실행: define the HazardModel class identity.
class_name HazardModel
extends RefCounted

# 실행: store hazard attributes.
var active: bool = false
var severity: String = "stable"
var label: String = "stable"

# 실행: initialize the hazard model.
func _init(act: bool = false, sev: String = "stable", lbl: String = "stable") -> void:
	active = act
	severity = sev
	label = lbl

# 실행: update the hazard state based on combat health and empty shots.
func update_state(health: float, empty_shots: int, combat_result: String, max_health: float = 100.0) -> void:
	if combat_result in ["failed", "time_over"]:
		active = true
		severity = "critical"
		label = "critical"
	elif health <= max_health * 0.15 or empty_shots > 0:
		active = true
		severity = "warning"
		label = "warning"
	else:
		active = false
		severity = "stable"
		label = "stable"

# 실행: export hazard state to dictionary.
func to_dict() -> Dictionary:
	return {
		"active": active,
		"severity": severity,
		"label": label
	}
