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
const CombatSimulatorScript = preload("res://src/models/CombatSimulator.gd")
const CombatVocabScript = preload("res://src/vocabulary/CombatVocab.gd")
const RecalculateQueueColorsScript = preload("res://src/vocabulary/combat/RecalculateQueueColors.gd")
const ShiftWeaknessMarkersScript = preload("res://src/vocabulary/combat/ShiftWeaknessMarkers.gd")

var failures: Array[String] = []

# 실행: run all combat utility vocabulary tests.
func run_all_tests() -> Dictionary:
	failures.clear()
	test_queue_colors_cycle_active_drill_colors()
	test_shift_markers_moves_right_and_inserts_seeded_left_column()
	test_shift_markers_changes_left_column_with_step()
	test_green_energy_damages_health_through_shield()
	test_red_and_blue_energy_emphasize_health_and_shield_damage()
	test_purple_energy_applies_terrain_debuff()
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

# 실행: verify green energy pierces shield and still reduces health.
func test_green_energy_damages_health_through_shield() -> void:
	var sim := _sim_with_queue("green", 10.0, 10.0)
	CombatVocabScript.fire_shot(sim, "green", "r0c0", {}, null)
	_assert(sim.shield > 0.0, "green leaves shield present")
	_assert(sim.health < 10.0, "green damages health through shield")

# 실행: verify red is health-leaning and blue is shield-leaning.
func test_red_and_blue_energy_emphasize_health_and_shield_damage() -> void:
	var red_sim := _sim_with_queue("red", 0.0, 10.0)
	var blue_sim := _sim_with_queue("blue", 10.0, 10.0)
	CombatVocabScript.fire_shot(red_sim, "red", "r0c0", {}, null)
	CombatVocabScript.fire_shot(blue_sim, "blue", "r0c0", {}, null)
	_assert(red_sim.health <= 7.0, "red deals high health damage when health is exposed")
	_assert(blue_sim.shield <= 6.0, "blue deals high shield damage")

# 실행: verify purple trades lower damage for terrain debuff metadata.
func test_purple_energy_applies_terrain_debuff() -> void:
	var sim := _sim_with_queue("purple", 10.0, 10.0)
	CombatVocabScript.fire_shot(sim, "purple", "r1c2", {}, null)
	_assert(sim.terrain_debuffs.size() == 1, "purple creates one terrain debuff")
	_assert_eq(sim.terrain_debuffs[0].get("cellId", ""), "r1c2", "purple debuff records target cell")
	_assert_eq(sim.terrain_debuffs[0].get("effect", ""), "weakened_terrain", "purple debuff records effect")

# 실행: create a deterministic drill artifact.
func _artifact(id: String, energy: String) -> Artifact:
	return ArtifactScript.new({"id": id, "name": id, "shape": [[1]], "energyType": energy, "item_type": "drill", "baseCooldownTicks": 10})

# 실행: create a combat simulator with a single queued energy.
func _sim_with_queue(energy: String, shield: float, health: float) -> CombatSimulator:
	var sim = CombatSimulatorScript.new({"combat": {"shield": shield, "health": health, "maxShield": shield, "maxHealth": health, "weakness": [energy]}}, {}, 8)
	sim.queue.clear()
	sim.queue.append(energy)
	sim.aim_can_fire = true
	return sim

# 실행: append a failure when condition is false.
func _assert(condition: bool, msg: String) -> void:
	if not condition:
		failures.append(msg)

# 실행: append a deterministic equality failure when values differ.
func _assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])
