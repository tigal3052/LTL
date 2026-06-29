# 계약:
# - 책임: inventory의 active drill 색상으로 combat queue item 목록을 만든다.
# - 입력: InventoryModel, queue capacity.
# - 출력: { ok, items, code } dictionary.
# - 금지: run state 직접 변경, UI 접근, phase 전환.
#
# 실행: define the RecalculateQueueColors vocabulary function holder.
class_name RecalculateQueueColors
extends RefCounted

const EnergyTempoBalanceScript = preload("res://src/balance/EnergyTempoBalance.gd")
const EnergyTokenScript = preload("res://src/vocabulary/combat/EnergyToken.gd")

# 실행: calculate a repeated queue token list from placed drill artifacts.
static func recalculate(inventory: InventoryModel, capacity: int = EnergyTempoBalanceScript.DEFAULT_QUEUE_CAPACITY, loaded_count: int = -1) -> Dictionary:
	if inventory == null:
		return {"ok": false, "code": "missing_inventory", "items": []}
	var active_drills: Array = EnergyTokenScript.active_drill_records(inventory)
	var average_cooldown := EnergyTokenScript.average_cooldown(active_drills)
	var items: Array = []
	var target_count := maxi(0, capacity)
	if loaded_count >= 0:
		target_count = mini(target_count, maxi(0, loaded_count))
	if active_drills.is_empty():
		active_drills.append({
			"artifact": null,
			"artifact_key": "",
			"cooldown": 1,
			"color": "red",
			"source_id": ""
		})
	for i in range(target_count):
		var drill_record: Dictionary = active_drills[i % active_drills.size()]
		items.append(EnergyTokenScript.build_token(inventory, drill_record.get("artifact", null), str(drill_record.get("artifact_key", ""))))
	return {"ok": true, "code": "recalculated", "items": items, "average_cooldown_ticks": average_cooldown}
