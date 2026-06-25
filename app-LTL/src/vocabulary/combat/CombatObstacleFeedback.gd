# 계약:
# - 책임: combat obstacle activation side effects를 UI-safe feedback event로 정규화한다.
# - 입력: CombatSimulator 호환 sim 객체, obstacle Dictionary, obstacle 적용 전 snapshot Dictionary.
# - 출력: sim.obstacle_feedback_events에 deterministic feedback event를 누적한다.
# - 금지: SceneTree/UI node 접근, obstacle 규칙 재계산, 상태 전이 변경.
#
# 실행: define the combat obstacle feedback helper identity.
class_name CombatObstacleFeedback
extends RefCounted

static func clear(sim) -> void:
	if sim != null:
		sim.obstacle_feedback_events = []

static func snapshot(sim) -> Dictionary:
	return {
		"timeLimitTicks": int(sim.time_limit_ticks),
		"health": float(sim.health),
		"purpleDebuffs": _purple_debuff_stacks(sim.terrain_debuffs)
	}

static func record_failure(sim, obstacle: Dictionary, before: Dictionary) -> void:
	if sim == null:
		return
	var family := str(obstacle.get("family", ""))
	var event := {
		"id": "obstacle:%s:%d:%s" % [str(obstacle.get("id", "")), int(sim.obstacle_shift_count), family],
		"family": family,
		"color": family,
		"channel": "battlefield",
		"popup": true,
		"text": "",
		"amount": 0.0
	}
	match family:
		"red":
			var cut_ticks := maxi(0, int(before.get("timeLimitTicks", sim.time_limit_ticks)) - int(sim.time_limit_ticks))
			event["channel"] = "timer"
			event["amount"] = cut_ticks
			event["text"] = "-%02d" % int(ceil(float(cut_ticks) / 20.0))
		"blue":
			event["popup"] = false
		"purple":
			var removed := maxi(0, int(before.get("purpleDebuffs", 0)) - _purple_debuff_stacks(sim.terrain_debuffs))
			event["channel"] = "purple_debuff"
			event["amount"] = removed
			event["popup"] = removed > 0
			event["text"] = "-%d 디버프" % maxi(1, removed)
		"green":
			var healed := maxf(0.0, float(sim.health) - float(before.get("health", sim.health)))
			event["channel"] = "health"
			event["amount"] = healed
			event["text"] = "+%s" % _format_amount(healed)
		_:
			event["popup"] = false
	sim.obstacle_feedback_events.append(event)

static func _purple_debuff_stacks(debuffs: Array) -> int:
	var total := 0
	for debuff in debuffs:
		if debuff is Dictionary and str(debuff.get("effect", "")) == "weakened_terrain":
			total += maxi(1, int(debuff.get("stacks", 1)))
	return total

static func _format_amount(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % int(roundf(value))
	return "%.1f" % value
