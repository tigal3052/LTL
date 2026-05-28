# 계약:
# - 책임: inventory의 active drill 색상으로 combat queue item 목록을 만든다.
# - 입력: InventoryModel, queue capacity.
# - 출력: { ok, items, code } dictionary.
# - 금지: run state 직접 변경, UI 접근, phase 전환.
#
# 실행: define the RecalculateQueueColors vocabulary function holder.
class_name RecalculateQueueColors
extends RefCounted

# 실행: calculate a repeated queue color list from placed drill artifacts.
static func recalculate(inventory: InventoryModel, capacity: int = 8) -> Dictionary:
	if inventory == null:
		return {"ok": false, "code": "missing_inventory", "items": []}
	var active_colors: Array[String] = []
	for art_id in inventory.artifacts:
		var art: Artifact = inventory.artifacts[art_id]
		if art.item_type == "drill":
			var color := str(art.energy_type)
			if not color in active_colors:
				active_colors.append(color)
	if active_colors.is_empty():
		active_colors.append("red")
	var items: Array[String] = []
	for i in range(maxi(0, capacity)):
		items.append(active_colors[i % active_colors.size()])
	return {"ok": true, "code": "recalculated", "items": items}
