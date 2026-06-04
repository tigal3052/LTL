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

# 실행: calculate a repeated queue token list from placed drill artifacts.
static func recalculate(inventory: InventoryModel, capacity: int = EnergyTempoBalanceScript.DEFAULT_QUEUE_CAPACITY, loaded_count: int = -1) -> Dictionary:
	if inventory == null:
		return {"ok": false, "code": "missing_inventory", "items": []}
	var active_drills: Array = []
	for art_id in inventory.artifacts:
		var art: Artifact = inventory.artifacts[art_id]
		if art.item_type == "drill":
			var color := str(art.energy_type)
			var already_seen := false
			for token in active_drills:
				if str(token.get("color", "")) == color:
					already_seen = true
					break
			if not already_seen:
				active_drills.append({
					"color": color,
					"source_artifact_id": art.id,
					"source_item_type": "drill"
				})
	if active_drills.is_empty():
		active_drills.append({
			"color": "red",
			"source_artifact_id": "",
			"source_item_type": "drill"
		})
	var items: Array = []
	var target_count := maxi(0, capacity)
	if loaded_count >= 0:
		target_count = mini(target_count, maxi(0, loaded_count))
	for i in range(target_count):
		items.append(active_drills[i % active_drills.size()].duplicate(true))
	return {"ok": true, "code": "recalculated", "items": items}
