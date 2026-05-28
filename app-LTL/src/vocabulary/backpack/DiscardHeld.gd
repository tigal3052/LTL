# 계약:
# - 책임: held artifact를 버리되 마지막 artifact guard를 적용한다.
# - 입력: InventoryModel, held Artifact, options.
# - 출력: { ok, inventory, held, code } dictionary.
# - 금지: UI 접근, reward effect 적용, phase 전환.
#
# 실행: define the DiscardHeld vocabulary function holder.
class_name DiscardHeld
extends RefCounted

# 실행: discard a held artifact with an optional last-artifact guard.
static func discard(inventory: InventoryModel, held: Artifact, options: Dictionary = {}) -> Dictionary:
	if held == null:
		return {"ok": false, "code": "missing_held", "inventory": inventory, "held": held}
	var guard_last := bool(options.get("guardLastArtifact", false))
	if guard_last and inventory != null and inventory.artifacts.size() <= 1:
		return {"ok": false, "code": "last_artifact_guard", "inventory": inventory, "held": held}
	if inventory != null and inventory.artifacts.has(held.id):
		inventory.remove_artifact(held.id)
	return {"ok": true, "code": "discarded", "inventory": inventory, "held": null}
