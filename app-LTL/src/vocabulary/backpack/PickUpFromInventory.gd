# 계약:
# - 책임: backpack grid 좌표에서 artifact를 집어 held 상태로 만든다.
# - 입력: InventoryModel, grid coordinate.
# - 출력: { ok, inventory, held, code } dictionary.
# - 금지: UI 접근, SceneTree 접근, reward tray 변경.
#
# 실행: define the PickUpFromInventory vocabulary function holder.
class_name PickUpFromInventory
extends RefCounted

# 실행: pick up the artifact occupying a grid coordinate.
static func pick_up(inventory: InventoryModel, coord: Vector2) -> Dictionary:
	if inventory == null:
		return {"ok": false, "code": "missing_inventory", "inventory": inventory, "held": null}
	var x := int(coord.x)
	var y := int(coord.y)
	if x < 0 or x >= inventory.width or y < 0 or y >= inventory.height:
		return {"ok": false, "code": "out_of_bounds", "inventory": inventory, "held": null}
	var art_id := str(inventory.grid[y][x])
	if art_id.is_empty() or not inventory.artifacts.has(art_id):
		return {"ok": false, "code": "empty_slot", "inventory": inventory, "held": null}
	var held: Artifact = inventory.artifacts[art_id]
	inventory.remove_artifact(art_id)
	return {"ok": true, "code": "picked_up", "inventory": inventory, "held": held}
