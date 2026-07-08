# 계약:
# - 책임: inventory synergy 계산을 명시적 vocabulary 동사로 노출한다.
# - 입력: InventoryModel.
# - 출력: { ok, inventory, code } dictionary.
# - 금지: UI 접근, phase 전환, reward tray 변경.
#
# 실행: define the RecalculateSynergy vocabulary function holder.
class_name RecalculateSynergy
extends RefCounted

# 실행: recalculate inventory synergies and return the same inventory boundary.
static func recalculate(inventory: InventoryModel) -> Dictionary:
	if inventory == null:
		return {"ok": false, "code": "missing_inventory", "inventory": inventory}
	inventory.calculate_synergies()
	return {"ok": true, "code": "recalculated", "inventory": inventory}
