# 계약:
# - 책임: held artifact를 inventory 좌표에 배치하고 reward tray 제거 시점을 성공 이후로 제한한다.
# - 입력: InventoryModel, held Artifact, 좌표, pending reward Array, held reward index.
# - 출력: { ok, inventory, held, pendingRewards, code } dictionary.
# - 금지: UI 접근, phase 전환, telemetry 출력.
#
# 실행: define the PlaceHeld vocabulary function holder.
class_name PlaceHeld
extends RefCounted

# 실행: place a held artifact and remove a pending reward only after successful placement.
static func place(inventory: InventoryModel, held: Artifact, x: int, y: int, pending_rewards: Array = [], held_reward_index: int = -1) -> Dictionary:
	var next_pending := pending_rewards.duplicate(true)
	if inventory == null:
		return _failure("missing_inventory", inventory, held, next_pending)
	if held == null:
		return _failure("missing_held", inventory, held, next_pending)
	var duplicate_color := _has_duplicate_drill_color(inventory, held)
	if duplicate_color:
		return _failure("duplicate_drill_color", inventory, held, next_pending)
	if not inventory.can_place_artifact(held, x, y):
		return _failure("cannot_place", inventory, held, next_pending)
	inventory.place_artifact(held, x, y)
	if held_reward_index >= 0 and held_reward_index < next_pending.size():
		next_pending.remove_at(held_reward_index)
	return {"ok": true, "code": "placed", "inventory": inventory, "held": null, "pendingRewards": next_pending}

# 실행: detect the single-drill-per-color guard before placement.
static func _has_duplicate_drill_color(inventory: InventoryModel, held: Artifact) -> bool:
	if held.item_type != "drill":
		return false
	for art_id in inventory.artifacts:
		var art: Artifact = inventory.artifacts[art_id]
		if art.item_type == "drill" and art.energy_type == held.energy_type and art.id != held.id:
			return true
	return false

# 실행: build a consistent failure result.
static func _failure(code: String, inventory: InventoryModel, held: Artifact, pending_rewards: Array) -> Dictionary:
	return {"ok": false, "code": code, "inventory": inventory, "held": held, "pendingRewards": pending_rewards}
