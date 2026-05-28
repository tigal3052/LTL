# 계약:
# - 책임: combat utility vocabulary가 inventory와 marker state를 deterministic하게 변환하는지 검증한다.
# - 입력: InventoryModel, combat battlefield marker Array.
# - 출력: queue color Array와 shifted marker Array 검증 결과.
# - 금지: SceneTree 접근, UI 접근, controller 상태 접근.
#
# 실행: define the TestCombatVocab class.
extends RefCounted

const ArtifactScript = preload("res://src/models/Artifact.gd")
const InventoryScript = preload("res://src/models/InventoryModel.gd")
const RecalculateQueueColorsScript = preload("res://src/vocabulary/combat/RecalculateQueueColors.gd")
const ShiftWeaknessMarkersScript = preload("res://src/vocabulary/combat/ShiftWeaknessMarkers.gd")

var failures: Array[String] = []

# 실행: run all combat utility vocabulary tests.
func run_all_tests() -> Dictionary:
	failures.clear()
	test_queue_colors_cycle_active_drill_colors()
	test_shift_markers_moves_right_and_inserts_seeded_left_column()
	test_shift_markers_changes_left_column_with_step()
	return {"ok": failures.is_empty(), "errors": failures}

# 실행: verify active drill colors repeat to queue capacity.
func test_queue_colors_cycle_active_drill_colors() -> void:
	var inv = InventoryScript.new(4, 4)
	inv.place_artifact(_artifact("red_a", "red"), 0, 0)
	inv.place_artifact(_artifact("blue_a", "blue"), 1, 0)
	var result = RecalculateQueueColorsScript.recalculate(inv, 5)
	_assert_eq(result["ok"], true, "queue color calculation succeeds")
	_assert_eq(result["items"], ["red", "blue", "red", "blue", "red"], "queue colors cycle active drill colors")

# 실행: verify marker shift drops right edge and adds deterministic left column.
func test_shift_markers_moves_right_and_inserts_seeded_left_column() -> void:
	var markers := [
		{"cellId": "r0c0", "color": "red"},
		{"cellId": "r1c9", "color": "blue"}
	]
	var result = ShiftWeaknessMarkersScript.shift(markers, 3, 10, 99, ["red", "blue"])
	_assert_eq(result["ok"], true, "marker shift succeeds")
	var shifted: Array = result["markers"]
	_assert(shifted.has({"cellId": "r0c1", "color": "red"}), "marker at c0 moves to c1")
	_assert(not shifted.has({"cellId": "r1c10", "color": "blue"}), "right edge marker is dropped")
	_assert_eq(shifted.size(), 4, "shift inserts one marker per left-column row")
	_assert(str(shifted[1].get("cellId", "")).begins_with("r0c0"), "left column row 0 inserted")

# 실행: verify repeated timer steps do not insert identical left-column colors.
func test_shift_markers_changes_left_column_with_step() -> void:
	var first = ShiftWeaknessMarkersScript.shift([], 3, 10, 99, ["red", "blue", "purple", "green"], 1)
	var second = ShiftWeaknessMarkersScript.shift([], 3, 10, 99, ["red", "blue", "purple", "green"], 2)
	_assert(first["markers"] != second["markers"], "marker shift step changes inserted colors")

# 실행: create a deterministic drill artifact.
func _artifact(id: String, energy: String) -> Artifact:
	return ArtifactScript.new({"id": id, "name": id, "shape": [[1]], "energyType": energy, "item_type": "drill", "baseCooldownTicks": 10})

# 실행: append a failure when condition is false.
func _assert(condition: bool, msg: String) -> void:
	if not condition:
		failures.append(msg)

# 실행: append a deterministic equality failure when values differ.
func _assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])
