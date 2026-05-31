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
	test_shift_markers_uses_seeded_random_left_column_without_diagonal_pattern()
	test_green_energy_damages_health_through_shield()
	test_red_and_blue_energy_emphasize_health_and_shield_damage()
	test_purple_energy_applies_terrain_debuff()
	test_purple_energy_stack_bonus_has_no_damage_cap_and_hits_hp()
	test_red_energy_hp_damage_is_lower_than_previous_overkill_profile()
	test_mismatch_penalty_is_readable_but_still_costly()
	test_repair_clears_stale_aim_and_recovers_cleanly()
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

# 실행: verify inserted terrain colors come from seeded random draws instead of a repeated diagonal formula.
func test_shift_markers_uses_seeded_random_left_column_without_diagonal_pattern() -> void:
	var columns := []
	for step in range(1, 7):
		var shifted = ShiftWeaknessMarkersScript.shift([], 3, 10, 99, ["red", "blue", "purple", "green"], step)
		var inserted := []
		for marker in shifted["markers"]:
			inserted.append(str(marker.get("color", "")))
		columns.append(inserted)
	var unique_columns := {}
	for column in columns:
		unique_columns[str(column)] = true
	_assert(unique_columns.size() >= 4, "shifted left columns vary across repeated shifts")
	_assert(columns[0] != ["green", "red", "blue"], "first shifted column avoids the old arithmetic diagonal")

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
	_assert(red_sim.health <= 8.0, "red deals moderate health damage when health is exposed")
	_assert(blue_sim.shield <= 7.1, "blue deals high shield damage")

# 실행: verify purple trades lower damage for terrain debuff metadata.
func test_purple_energy_applies_terrain_debuff() -> void:
	var sim := _sim_with_queue("purple", 10.0, 10.0)
	CombatVocabScript.fire_shot(sim, "purple", "r1c2", {}, null)
	_assert(sim.terrain_debuffs.size() == 1, "purple creates one terrain debuff")
	_assert_eq(sim.terrain_debuffs[0].get("scope", ""), "global", "purple debuff is global")
	_assert_eq(sim.terrain_debuffs[0].get("effect", ""), "weakened_terrain", "purple debuff records effect")
	_assert(sim.shield < 10.0, "purple damages shield")
	_assert(sim.health < 10.0, "purple damages health through shield")

# 실행: verify purple debuff stacks scale damage without a hard cap.
func test_purple_energy_stack_bonus_has_no_damage_cap_and_hits_hp() -> void:
	var sim := _sim_with_queue("purple", 30.0, 30.0)
	sim.terrain_debuffs = [{"scope": "global", "effect": "weakened_terrain", "energy": "purple", "stacks": 24}]
	CombatVocabScript.fire_shot(sim, "purple", "r1c2", {}, null)
	_assert(30.0 - sim.shield > 5.0, "purple stacked debuff can exceed five shield damage")
	_assert(30.0 - sim.health > 5.0, "purple stacked debuff can exceed five health damage")
	_assert_eq(int(sim.terrain_debuffs[0].get("stacks", 0)), 25, "purple stack increments without replacing cap")

# 실행: verify red still leans HP but no longer deals the old near-five HP burst at 1.5 damage.
func test_red_energy_hp_damage_is_lower_than_previous_overkill_profile() -> void:
	var inv = InventoryScript.new(4, 4)
	var red_drill = ArtifactScript.new({"id": "red_drill", "name": "Red Drill", "shape": [[1]], "energyType": "red", "item_type": "drill", "baseCooldownTicks": 80, "damage": 1.5})
	inv.place_artifact(red_drill, 0, 0)
	var sim := _sim_with_queue("red", 0.0, 10.0)
	CombatVocabScript.fire_shot(sim, "red", "r0c0", {}, inv)
	var hp_damage := 10.0 - sim.health
	_assert(hp_damage < 3.25, "red 1.5 damage drill HP burst is reduced below old 4.95 profile")
	_assert(hp_damage > 1.5, "red still deals meaningful HP damage")

# ?ㅽ뻾: verify mismatch feedback costs tempo without deleting a full pin by hazard side effect.
func test_mismatch_penalty_is_readable_but_still_costly() -> void:
	var sim = CombatSimulatorScript.new({"combat": {"shield": 10.0, "health": 10.0, "maxShield": 10.0, "maxHealth": 10.0, "weakness": ["blue"]}}, {}, 8)
	sim.queue.clear()
	sim.queue.append("red")
	sim.aim_can_fire = true
	CombatVocabScript.fire_shot(sim, "blue", "r0c0", {}, null)
	_assert_eq(sim.result, "mismatch", "mismatch records readable result")
	_assert(sim.shield < 10.0, "mismatch still chips shield")
	_assert(sim.shield > 9.7, "mismatch does not over-punish with full shield damage")
	_assert_eq(sim.queue_pinned_slots, 1, "mismatch pin comes from player error path")

func test_repair_clears_stale_aim_and_recovers_cleanly() -> void:
	var sim := CombatSimulatorScript.new({"combat": {"shield": 10.0, "health": 10.0, "maxShield": 10.0, "maxHealth": 10.0, "weakness": ["red"]}}, {}, 8)
	sim.queue.clear()
	sim.aim_cell_id = "r0c0"
	sim.aim_target_color = "red"
	sim.aim_can_fire = true
	CombatVocabScript.fire_shot(sim, "red", "r0c0", {}, null)
	_assert_eq(sim.repair_active, true, "empty queue starts automatic repair")
	_assert_eq(sim.aim_cell_id, null, "repair clears stale aimed cell")
	_assert_eq(sim.aim_target_color, null, "repair clears stale aimed color")
	CombatVocabScript.tick_combat(sim, 100, null)
	_assert_eq(sim.repair_active, false, "repair countdown can finish")
	_assert_eq(sim.aim_can_fire, true, "repair completion re-enables aiming without restarting repair")

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
