# 계약:
# - 책임: 백팩 정리 동작들(들기, 회전, 배치, 버리기 등)에 대한 순수 동사 함수들을 제공한다.
# - 입력: InventoryModel 인스턴스, Artifact 인스턴스, 좌표.
# - 출력: 성공 여부 및 갱신된 상태.
# - 금지: SceneTree 접근, 자체 상태 보존 (static func만 가짐).
#
# 실행: define the BackpackVocab static entry.
class_name BackpackVocab
extends RefCounted

# 실행: pick up an artifact from the backpack grid, removing it from placement.
static func pick_up_item(inv: InventoryModel, art_id: String) -> Artifact:
	if not inv.artifacts.has(art_id):
		return null
	var art: Artifact = inv.artifacts[art_id]
	inv.remove_artifact(art_id)
	return art

# 실행: place a held artifact on the backpack grid at specific coordinates.
static func place_held_item(inv: InventoryModel, art: Artifact, x: int, y: int) -> bool:
	return inv.place_artifact(art, x, y)

# 실행: rotate a held artifact 90 degrees clockwise.
static func rotate_held_item(art: Artifact) -> void:
	if art != null:
		art.rotate_shape()

# 실행: discard a held artifact entirely.
static func discard_held_item(inv: InventoryModel, art: Artifact) -> void:
	if art != null and inv.artifacts.has(art.id):
		inv.remove_artifact(art.id)
