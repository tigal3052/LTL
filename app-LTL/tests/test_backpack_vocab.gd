# 계약:
# - 책임: backpack vocabulary의 작은 동사 단위가 inventory/held/reward tray 상태를 예측 가능하게 바꾸는지 검증한다.
# - 입력: InventoryModel, Artifact, pending reward tray fixture.
# - 출력: 각 vocabulary 함수의 성공/실패와 변경된 상태 검증 결과.
# - 금지: SceneTree 접근, UI node 접근, controller 상태 접근.
#
# 실행: define the TestBackpackVocab class.
extends RefCounted

const ArtifactScript = preload("res://src/models/Artifact.gd")
const InventoryScript = preload("res://src/models/InventoryModel.gd")
const PickUpFromInventoryScript = preload("res://src/vocabulary/backpack/PickUpFromInventory.gd")
const PickUpFromRewardTrayScript = preload("res://src/vocabulary/backpack/PickUpFromRewardTray.gd")
const RotateHeldScript = preload("res://src/vocabulary/backpack/RotateHeld.gd")
const PlaceHeldScript = preload("res://src/vocabulary/backpack/PlaceHeld.gd")
const DiscardHeldScript = preload("res://src/vocabulary/backpack/DiscardHeld.gd")
const RecalculateSynergyScript = preload("res://src/vocabulary/backpack/RecalculateSynergy.gd")

var failures: Array[String] = []

# 실행: run all backpack vocabulary tests.
func run_all_tests() -> Dictionary:
	failures.clear()
	test_pick_up_from_inventory_removes_grid_artifact()
	test_pick_up_from_reward_tray_returns_held_without_mutating_inventory()
	test_place_held_rejects_collision_and_out_of_bounds()
	test_place_held_rejects_duplicate_drill_color()
	test_place_reward_removes_reward_only_after_success()
	test_beacon_tick_reduces_adjacent_drill_cooldown_when_charged()
	test_discard_respects_last_artifact_guard()
	test_rotate_held_changes_shape()
	return {"ok": failures.is_empty(), "errors": failures}

# 실행: verify inventory pickup returns a held artifact and clears the grid.
func test_pick_up_from_inventory_removes_grid_artifact() -> void:
	var inv = InventoryScript.new(4, 4)
	var art = _artifact("red_a", "red", [[1]])
	inv.place_artifact(art, 1, 1)
	var result: Dictionary = PickUpFromInventoryScript.pick_up(inv, Vector2(1, 1))
	_assert_eq(result.get("ok", false), true, "pickup inventory succeeds")
	_assert_eq(result.get("held").id, "red_a", "pickup returns held artifact")
	_assert_eq(str(inv.grid[1][1]), "", "pickup clears grid cell")

# 실행: verify reward tray pickup selects one pending reward as held reward data.
func test_pick_up_from_reward_tray_returns_held_without_mutating_inventory() -> void:
	var rewards := [_reward("reward_a"), _reward("reward_b")]
	var result: Dictionary = PickUpFromRewardTrayScript.pick_up(rewards, 1)
	_assert_eq(result.get("ok", false), true, "reward tray pickup succeeds")
	_assert_eq(result.get("heldReward", {}).get("rewardId", ""), "reward_b", "reward tray returns selected reward")
	_assert_eq(result.get("heldRewardIndex", -1), 1, "reward tray returns selected index")
	_assert_eq(result.get("pendingRewards", []).size(), 2, "reward tray pickup does not remove reward yet")

# 실행: verify placement guards for occupied cells and grid bounds.
func test_place_held_rejects_collision_and_out_of_bounds() -> void:
	var inv = InventoryScript.new(2, 2)
	inv.place_artifact(_artifact("red_a", "red", [[1]]), 0, 0)
	var collision = PlaceHeldScript.place(inv, _artifact("blue_a", "blue", [[1]]), 0, 0, [], -1)
	_assert_eq(collision.get("ok", true), false, "place rejects collision")
	var out_of_bounds = PlaceHeldScript.place(inv, _artifact("blue_b", "blue", [[1, 1]]), 1, 0, [], -1)
	_assert_eq(out_of_bounds.get("ok", true), false, "place rejects out of bounds")

# 실행: verify duplicate drill energy color guard.
func test_place_held_rejects_duplicate_drill_color() -> void:
	var inv = InventoryScript.new(4, 4)
	inv.place_artifact(_artifact("red_a", "red", [[1]]), 0, 0)
	var result = PlaceHeldScript.place(inv, _artifact("red_b", "red", [[1]]), 1, 0, [], -1)
	_assert_eq(result.get("ok", true), false, "place rejects duplicate drill color")
	_assert_eq(result.get("code", ""), "duplicate_drill_color", "place reports duplicate drill color")

# 실행: verify reward is removed from pending list only after successful placement.
func test_place_reward_removes_reward_only_after_success() -> void:
	var inv = InventoryScript.new(4, 4)
	var pending := [_reward("reward_a")]
	var failed = PlaceHeldScript.place(inv, _artifact("blue_a", "blue", [[1, 1, 1, 1, 1]]), 0, 0, pending, 0)
	_assert_eq(failed.get("ok", true), false, "failed reward placement rejects")
	_assert_eq(failed.get("pendingRewards", []).size(), 1, "failed reward placement keeps pending reward")
	var placed = PlaceHeldScript.place(inv, _artifact("blue_b", "blue", [[1]]), 0, 0, pending, 0)
	_assert_eq(placed.get("ok", false), true, "successful reward placement succeeds")
	_assert_eq(placed.get("pendingRewards", []).size(), 0, "successful reward placement removes pending reward")

# 실행: verify beacon cooldown charges separately before reducing adjacent drill cooldown.
func test_beacon_tick_reduces_adjacent_drill_cooldown_when_charged() -> void:
	var inv := InventoryScript.new(8, 8)
	var drill = _artifact("red_drill", "red", [[1]])
	drill.current_cooldown = 8
	var beacon = ArtifactScript.new({"id": "red_beacon", "name": "Red Beacon", "shape": [[1]], "energyType": "red", "item_type": "beacon", "baseCooldownTicks": 2, "beaconCooldownMod": -3})
	_assert_eq(inv.place_artifact(drill, 2, 2), true, "place drill before beacon")
	_assert_eq(inv.place_artifact(beacon, 3, 2), true, "place adjacent beacon")
	var first_tick := inv.tick()
	_assert_eq(first_tick.size(), 0, "first beacon tick does not emit energy")
	_assert_eq(drill.current_cooldown, 7, "first tick only advances drill cooldown normally")
	var second_tick := inv.tick()
	_assert_eq(second_tick.size(), 0, "beacon tick still does not emit energy")
	_assert_eq(drill.current_cooldown, 3, "charged beacon reduces adjacent drill cooldown after its own cooldown fills")

# 실행: verify discard refuses to remove the final artifact when guarded.
func test_discard_respects_last_artifact_guard() -> void:
	var inv = InventoryScript.new(4, 4)
	var art = _artifact("red_a", "red", [[1]])
	inv.place_artifact(art, 0, 0)
	var result = DiscardHeldScript.discard(inv, art, {"guardLastArtifact": true})
	_assert_eq(result.get("ok", true), false, "discard rejects last artifact")
	_assert_eq(result.get("code", ""), "last_artifact_guard", "discard reports last artifact guard")

# 실행: verify held rotation returns the rotated artifact.
func test_rotate_held_changes_shape() -> void:
	var art = _artifact("shape_a", "blue", [[1, 0], [1, 1]])
	var result = RotateHeldScript.rotate(art)
	_assert_eq(result.get("ok", false), true, "rotate succeeds")
	_assert_eq(result.get("held").shape, [[1, 1], [1, 0]], "rotate changes shape clockwise")

# 실행: create a deterministic artifact fixture.
func _artifact(id: String, energy: String, shape: Array) -> Artifact:
	return ArtifactScript.new({"id": id, "name": id, "shape": shape, "energyType": energy, "item_type": "drill", "baseCooldownTicks": 10})

# 실행: create a deterministic pending reward fixture.
func _reward(id: String) -> Dictionary:
	return {"rewardId": id, "kind": id, "rarity": "common", "qty": 1, "payload": {"energy_type": "red"}, "presentation": {}, "tags": []}

# 실행: append a failure when condition is false.
func _assert(condition: bool, msg: String) -> void:
	if not condition:
		failures.append(msg)

# 실행: append a deterministic equality failure when values differ.
func _assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])
