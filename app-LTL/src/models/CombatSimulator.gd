# 계약:
# - 책임: 전투 시뮬레이션 상태(체력, 실드, 리미트 틱, 에너지 큐, 핀 상태, 수리 진행도 등)의 보존 및 상태 조회를 제공한다.
# - 입력: 초기화용 설정 Dictionary.
# - 출력: 현재 전투 시뮬레이션 상태의 Dictionary 스냅샷.
# - 금지: 직접적인 input device input 처리, SceneTree 접근.
#
# 실행: define the CombatSimulator class identity.
class_name CombatSimulator
extends RefCounted

# 실행: store core combat attributes.
var result: String = "active"
var shield: float = 0.0
var health: float = 0.0
var max_health: float = 0.0
var max_shield: float = 0.0
var time_limit_ticks: int = 2400
var elapsed_ticks: int = 0
var disabled: bool = false

# 실행: store queue, pin, repair, aim, battlefield, and telemetry summary sub-states.
var queue_capacity: int = 8
var queue: Array[String] = []
var queue_pinned_slots: int = 0
var queue_empty_shots: int = 0

var pin_active: bool = false
var pin_progress: int = 4
var pin_turns_remaining: int = 4

var repair_threshold: int = 3
var repair_progress: int = 0
var repair_active: bool = false
var repair_available: bool = true

var aim_cell_id: Variant = null
var aim_target_color: Variant = null
var aim_can_fire: bool = true

var battlefield_rows: int = 3
var battlefield_cols: int = 10
var weakness_markers: Array = []

var summary_shots_fired: int = 0
var summary_shots_hit_match: int = 0
var summary_shots_hit_mismatch: int = 0
var summary_shots_fired_empty_queue: int = 0

# 실행: initialize combat simulator from choice and tuning data.
func _init(choice: Dictionary, tuning: Dictionary, q_capacity: int) -> void:
	result = "active"
	var combat_data: Dictionary = choice.get("combat", {})
	shield = float(combat_data.get("shield", 0.0))
	health = float(combat_data.get("health", 0.0))
	max_shield = float(combat_data.get("maxShield", shield))
	max_health = float(combat_data.get("maxHealth", health))
	time_limit_ticks = int(combat_data.get("timeLimitTicks", 2400))
	elapsed_ticks = 0
	disabled = false

	queue_capacity = q_capacity
	queue = []
	var init_q = combat_data.get("initialQueue", [])
	if init_q is Array and not init_q.is_empty():
		for item in init_q:
			queue.append(str(item))
	else:
		# Empty queue by default, items in backpack will charge it
		pass
			
	queue_pinned_slots = 0
	queue_empty_shots = 0

	pin_active = false
	pin_progress = 100
	pin_turns_remaining = 100

	var queue_tuning: Dictionary = tuning.get("queue", {"repairThreshold": 3})
	repair_threshold = int(queue_tuning.get("repairThreshold", 3))
	repair_progress = 0
	repair_active = false
	repair_available = queue_capacity <= repair_threshold

	aim_cell_id = null
	aim_target_color = null
	aim_can_fire = true

	battlefield_rows = 3
	battlefield_cols = 10
	weakness_markers = _create_weakness_markers(combat_data.get("weakness", []))

	summary_shots_fired = 0
	summary_shots_hit_match = 0
	summary_shots_hit_mismatch = 0
	summary_shots_fired_empty_queue = 0

# 실행: map weakness colors onto battlefield cells.
func _create_weakness_markers(weakness: Array) -> Array:
	var markers: Array = []
	for index in range(weakness.size()):
		markers.append({"cellId": "r%dc%d" % [int(index / 10), index % 10], "color": weakness[index]})
	return markers

# 실행: export current combat simulator attributes to a clean dictionary.
func to_dict() -> Dictionary:
	return {
		"result": result,
		"shield": shield,
		"health": health,
		"maxShield": max_shield,
		"maxHealth": max_health,
		"timeLimitTicks": time_limit_ticks,
		"elapsedTicks": elapsed_ticks,
		"disabled": disabled,
		"queue": {
			"capacity": queue_capacity,
			"loaded": queue.size(),
			"items": queue.duplicate(true),
			"pinnedSlots": queue_pinned_slots,
			"emptyShots": queue_empty_shots
		},
		"pin": {
			"active": pin_active,
			"progress": pin_progress,
			"turnsRemaining": pin_turns_remaining
		},
		"repair": {
			"threshold": repair_threshold,
			"progress": repair_progress,
			"active": repair_active,
			"available": repair_available
		},
		"aim": {
			"cellId": aim_cell_id,
			"targetColor": aim_target_color,
			"canFire": aim_can_fire
		},
		"battlefield": {
			"rows": battlefield_rows,
			"columns": battlefield_cols,
			"weaknessMarkers": weakness_markers.duplicate(true)
		},
		"summary": {
			"shots_fired": summary_shots_fired,
			"shots_hit_match": summary_shots_hit_match,
			"shots_hit_mismatch": summary_shots_hit_mismatch,
			"shots_fired_empty_queue": summary_shots_fired_empty_queue
		}
	}
