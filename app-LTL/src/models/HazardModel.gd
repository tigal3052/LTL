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
var families: Array = []
var obstacle_count: int = 0

# 실행: initialize the hazard model.
func _init(act: bool = false, sev: String = "stable", lbl: String = "stable") -> void:
	active = act
	severity = sev
	label = lbl
	families = []
	obstacle_count = 0

# 실행: update the hazard state based on combat failure, active obstacle pressure, and persistent damage reduction pressure.
func update_state(health: float, empty_shots: int, combat_result: String, max_health: float = 100.0, obstacles: Array = [], purple_damage_reduction: float = 0.0) -> void:
	var family_counts := {}
	obstacle_count = 0
	for obstacle in obstacles:
		if not obstacle is Dictionary:
			continue
		var state := str(obstacle.get("state", "active"))
		if state == "warning":
			state = "active"
		if state.begins_with("afterglow"):
			continue
		var family := str(obstacle.get("family", ""))
		if family.is_empty():
			continue
		obstacle_count += 1
		family_counts[family] = int(family_counts.get(family, 0)) + 1
	families = family_counts.keys()
	if combat_result in ["failed", "time_over"]:
		active = true
		severity = "critical"
		label = "critical"
	elif obstacle_count > 0:
		active = true
		severity = "critical" if obstacle_count >= 3 or purple_damage_reduction >= 0.25 else "active"
		label = str(families[0]) if not families.is_empty() else "active"
	else:
		active = false
		severity = "stable"
		label = "stable"
		families = []
		obstacle_count = 0

# 실행: export hazard state to dictionary.
func to_dict() -> Dictionary:
	return {
		"active": active,
		"severity": severity,
		"label": label,
		"families": families.duplicate(true),
		"obstacleCount": obstacle_count
	}
