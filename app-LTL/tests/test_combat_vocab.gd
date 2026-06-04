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
const ApplyNodeModifiersScript = preload("res://src/vocabulary/node/ApplyNodeModifiers.gd")
const HeadlessMiniRunScript = preload("res://src/process/HeadlessMiniRun.gd")

var failures: Array[String] = []

# 실행: run all combat utility vocabulary tests.
func run_all_tests() -> Dictionary:
	failures.clear()
	test_queue_colors_cycle_active_drill_colors()
	test_queue_items_keep_dictionary_shape_when_inventory_generates_energy()
	test_shift_markers_moves_right_and_inserts_seeded_left_column()
	test_shift_markers_changes_left_column_with_step()
	test_shift_markers_uses_seeded_random_left_column_without_diagonal_pattern()
	test_green_energy_damages_health_through_shield()
	test_red_and_blue_energy_emphasize_health_and_shield_damage()
	test_purple_energy_applies_terrain_debuff()
	test_purple_energy_stack_bonus_has_no_damage_cap_and_hits_hp()
	test_red_energy_hp_damage_is_lower_than_previous_overkill_profile()
	test_beacon_damage_modifier_increases_actual_combat_damage()
	test_mismatch_penalty_is_readable_but_still_costly()
	test_repair_clears_stale_aim_and_recovers_cleanly()
	test_default_run_uses_doubled_queue_capacity_and_preloads_half_tokens()
	test_doubled_queue_keeps_default_time_limit()
	test_initial_terrain_energy_seeds_full_random_grid_independent_of_node_colors()
	test_spawned_obstacles_start_active_without_warning_phase()
	test_red_obstacle_fails_when_host_cell_exits_and_cuts_time()
	test_blue_obstacle_tax_slows_backpack_energy_generation()
	test_warning_bell_blocks_first_obstacle_execute()
	test_spare_fuse_ignores_one_blue_activation_and_execute()
	test_brake_coil_adds_time_when_obstacle_clears()
	test_anchor_oathplate_globalizes_all_weakness_tiles_every_five_hits()
	test_purple_obstacle_active_tick_does_not_decay_terrain_debuff()
	test_purple_obstacle_exit_failure_cleanses_weakened_stack_before_granting_buff()
	test_purple_obstacle_exit_failure_grants_fortified_buff_at_normal()
	test_purple_fortified_buff_reduces_damage()
	test_purple_hit_breaks_fortified_buff_before_adding_debuff()
	test_purple_obstacle_exit_failure_triggers_pressure_pulse()
	test_green_obstacle_exit_failure_heals_leviathan()
	test_cleared_obstacle_without_afterglow_disappears_on_next_tick()
	test_obstacle_spawn_rotation_cycles_families_over_successive_waves()
	test_obstacle_spawn_restricts_families_to_selected_node_colors()
	test_node_modifier_carries_hazard_spawn_profile()
	test_shift_obstacle_spawn_respects_zero_chance_without_backfill()
	test_shift_obstacle_spawn_uses_only_inserted_new_tiles()
	test_shift_obstacle_spawn_can_fill_multiple_new_tiles_with_multiple_families()
	test_prime_obstacles_respects_initial_spawn_cap()
	return {"ok": failures.is_empty(), "errors": failures}

# 실행: verify active drill colors repeat to queue capacity.
func test_queue_colors_cycle_active_drill_colors() -> void:
	var inv = InventoryScript.new(4, 4)
	inv.place_artifact(_artifact("red_a", "red"), 0, 0)
	inv.place_artifact(_artifact("blue_a", "blue"), 1, 0)
	var result = RecalculateQueueColorsScript.recalculate(inv, 5)
	var colors: Array = []
	for item in result["items"]:
		colors.append(str(item.get("color", "")) if item is Dictionary else str(item))
	_assert_eq(result["ok"], true, "queue color calculation succeeds")
	_assert_eq(colors, ["red", "blue", "red", "blue", "red"], "queue colors cycle active drill colors")

func test_queue_items_keep_dictionary_shape_when_inventory_generates_energy() -> void:
	var inv := InventoryScript.new(4, 4)
	var drill = ArtifactScript.new({
		"id": "red_cycle",
		"name": "Red Cycle",
		"shape": [[1]],
		"energyType": "red",
		"item_type": "drill",
		"baseCooldownTicks": 1,
		"currentCooldown": 1
	})
	inv.place_artifact(drill, 0, 0)
	var sim := CombatSimulatorScript.new({
		"combat": {
			"shield": 1.0,
			"health": 1.0,
			"maxShield": 1.0,
			"maxHealth": 1.0
		}
	}, {}, 3)
	CombatVocabScript.tick_combat(sim, 1, inv)
	_assert(sim.queue.size() >= 1, "inventory tick produces queue item")
	var queue_item: Variant = sim.queue[0]
	_assert(queue_item is Dictionary, "queue item keeps structured token")
	if queue_item is Dictionary:
		_assert_eq(str(queue_item.get("color", "")), "red", "queue token stores energy color")
		_assert_eq(str(queue_item.get("source_artifact_id", "")), "red_cycle", "queue token stores source artifact id")

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
func test_beacon_damage_modifier_increases_actual_combat_damage() -> void:
	var baseline_inv = InventoryScript.new(4, 4)
	var baseline_drill = ArtifactScript.new({"id": "red_base_drill", "name": "Red Base Drill", "shape": [[1]], "energyType": "red", "item_type": "drill", "baseCooldownTicks": 80, "damage": 1.0})
	baseline_inv.place_artifact(baseline_drill, 0, 0)
	var boosted_inv = InventoryScript.new(4, 4)
	var boosted_drill = ArtifactScript.new({"id": "red_boosted_drill", "name": "Red Boosted Drill", "shape": [[1]], "energyType": "red", "item_type": "drill", "baseCooldownTicks": 80, "damage": 1.0})
	var beacon = ArtifactScript.new({"id": "red_damage_beacon", "name": "Red Damage Beacon", "shape": [[1]], "energyType": "red", "item_type": "beacon", "baseCooldownTicks": 3, "beaconDamageMod": 1.0})
	boosted_inv.place_artifact(boosted_drill, 0, 0)
	boosted_inv.place_artifact(beacon, 1, 0)
	var baseline_sim := _sim_with_queue("red", 0.0, 10.0)
	var boosted_sim := _sim_with_queue("red", 0.0, 10.0)
	CombatVocabScript.fire_shot(baseline_sim, "red", "r0c0", {}, baseline_inv)
	CombatVocabScript.fire_shot(boosted_sim, "red", "r0c0", {}, boosted_inv)
	_assert(boosted_sim.health < baseline_sim.health, "beacon damage modifier increases actual combat HP damage")

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

func test_default_run_uses_doubled_queue_capacity_and_preloads_half_tokens() -> void:
	var run := HeadlessMiniRunScript.new({})
	_assert_eq(int(run.state.get("queueCapacity", 0)), 16, "default run doubles the queue capacity to sixteen")
	var snapshot: Dictionary = run.select_node(0)
	var queue: Dictionary = snapshot.get("combat", {}).get("queue", {})
	_assert_eq(int(queue.get("capacity", 0)), 16, "combat snapshot keeps the doubled queue capacity")
	_assert_eq(int(queue.get("items", []).size()), 8, "combat entry preloads only half of the doubled queue so the faster action tempo still ramps up from a partial start")

func test_doubled_queue_keeps_default_time_limit() -> void:
	var run := HeadlessMiniRunScript.new({})
	var snapshot: Dictionary = run.select_node(0)
	_assert_eq(int(snapshot.get("combat", {}).get("timeLimitTicks", 0)), 1800, "faster queue tempo keeps the default combat time limit unchanged")

func test_initial_terrain_energy_seeds_full_random_grid_independent_of_node_colors() -> void:
	var sim := CombatSimulatorScript.new({
		"combat": {
			"shield": 10.0,
			"health": 10.0,
			"maxShield": 10.0,
			"maxHealth": 10.0,
			"weakness": ["red", "blue"]
		}
	}, {}, 16)
	_assert_eq(sim.weakness_markers.size(), 30, "initial terrain energy fills the restored 3x10 battlefield")
	var seen_rows := {}
	var seen_columns := {}
	var seen_colors := {}
	for marker in sim.weakness_markers:
		var cell_id := str(marker.get("cellId", ""))
		var parts := cell_id.substr(1).split("c")
		if parts.size() == 2:
			seen_rows[int(parts[0])] = true
			seen_columns[int(parts[1])] = true
		seen_colors[str(marker.get("color", ""))] = true
	_assert_eq(seen_rows.keys().size(), 3, "initial terrain energy fills all three battlefield rows")
	_assert_eq(seen_columns.keys().size(), 10, "initial terrain energy fills all ten battlefield columns")
	for color in ["red", "blue", "purple", "green"]:
		_assert(seen_colors.has(color), "initial terrain energy uses the full terrain color palette, including %s" % color)

func test_spawned_obstacles_start_active_without_warning_phase() -> void:
	var sim := _sim_with_spawn_profile({
		"chance": 1.0,
		"maxPerShift": 1,
		"maxInitialSpawns": 1,
		"allowedFamilies": ["red"]
	}, ["red"])
	CombatVocabScript.prime_obstacles(sim, 17, 0, 1.0)
	_assert(not sim.obstacles.is_empty(), "prime obstacles spawns at least one active hazard")
	if sim.obstacles.is_empty():
		return
	_assert_eq(str(sim.obstacles[0].get("state", "")), "active", "spawned hazards skip warning and start active")

func test_red_obstacle_fails_when_host_cell_exits_and_cuts_time() -> void:
	var sim := _sim_with_queue("red", 10.0, 10.0)
	sim.elapsed_ticks = 100
	sim.time_limit_ticks = 700
	sim.obstacles = [_obstacle("haz_red_exit", "red", "r0c9", {"timeCutTicks": 240})]
	CombatVocabScript.resolve_obstacle_shift_exit(sim, ["haz_red_exit"])
	_assert_eq(sim.time_limit_ticks, 460, "red exit failure cuts remaining time by configured ticks")
	_assert_eq(int(sim.obstacle_miss_debt.get("red", 0)), 1, "red exit failure adds miss debt")
	_assert_eq(sim.obstacles.size(), 0, "failed exit obstacle is removed")

func test_blue_obstacle_tax_slows_backpack_energy_generation() -> void:
	var inv := InventoryScript.new(4, 4)
	var drill = ArtifactScript.new({
		"id": "blue_tax_drill",
		"name": "Blue Tax Drill",
		"shape": [[1]],
		"energyType": "red",
		"item_type": "drill",
		"baseCooldownTicks": 4,
		"currentCooldown": 4
	})
	inv.place_artifact(drill, 0, 0)
	var sim := CombatSimulatorScript.new({"combat": {"shield": 10.0, "health": 10.0, "maxShield": 10.0, "maxHealth": 10.0}}, {}, 8)
	sim.obstacles = [_obstacle("haz_blue_0", "blue", "r1c4", {"warningTicks": 0})]
	CombatVocabScript.tick_combat(sim, 4, inv)
	_assert_eq(sim.queue.size(), 0, "blue obstacle tax delays the first queue charge")
	CombatVocabScript.tick_combat(sim, 1, inv)
	_assert_eq(sim.queue.size(), 1, "taxed drill finally charges on the delayed fifth tick")

func test_warning_bell_blocks_first_obstacle_execute() -> void:
	var inv := InventoryScript.new(6, 6)
	inv.place_artifact(_relic("warning_bell", "Warning Bell", {
		"trigger": "on_obstacle_execute",
		"type": "prevent_first_execute",
		"value": 1
	}), 1, 1)
	var sim := _sim_with_queue("red", 10.0, 10.0)
	sim.elapsed_ticks = 100
	sim.time_limit_ticks = 700
	sim.obstacles = [_obstacle("haz_red_exit", "red", "r0c9", {"timeCutTicks": 240})]
	CombatVocabScript.resolve_obstacle_shift_exit(sim, ["haz_red_exit"], inv)
	_assert_eq(sim.time_limit_ticks, 700, "warning bell blocks the first obstacle execute time cut")
	_assert_eq(int(sim.obstacle_miss_debt.get("red", 0)), 0, "warning bell blocks execute miss debt")
	_assert_eq(sim.obstacles.size(), 0, "warning bell still lets the executed obstacle leave play")

func test_spare_fuse_ignores_one_blue_activation_and_execute() -> void:
	var inv := InventoryScript.new(6, 6)
	var drill = ArtifactScript.new({
		"id": "blue_tax_drill",
		"name": "Blue Tax Drill",
		"shape": [[1]],
		"energyType": "red",
		"item_type": "drill",
		"baseCooldownTicks": 4,
		"currentCooldown": 4
	})
	inv.place_artifact(drill, 0, 0)
	inv.place_artifact(_relic("spare_fuse", "Spare Fuse", {
		"trigger": "on_obstacle_activate",
		"type": "ignore_first_blue_obstacle",
		"value": 1
	}), 2, 2)
	var sim := CombatSimulatorScript.new({
		"combat": {
			"shield": 10.0,
			"health": 10.0,
			"maxShield": 10.0,
			"maxHealth": 10.0,
			"hazard": {
				"allowedFamilies": ["blue"],
				"spawn": {"chance": 1.0, "maxPerShift": 1, "maxInitialSpawns": 1, "allowedFamilies": ["blue"]}
			}
		}
	}, {}, 8)
	CombatVocabScript.prime_obstacles(sim, 17, 0, 1.0, inv)
	_assert_eq(sim.obstacles.size(), 1, "spare fuse test primes one blue obstacle")
	CombatVocabScript.tick_combat(sim, 4, inv)
	_assert_eq(sim.queue.size(), 1, "spare fuse ignores the first blue activation slowdown")
	var obstacle_id := str(sim.obstacles[0].get("id", ""))
	CombatVocabScript.resolve_obstacle_shift_exit(sim, [obstacle_id], inv)
	_assert_eq(int(sim.obstacle_miss_debt.get("blue", 0)), 0, "spare fuse ignores the first blue execute debt")
	_assert_eq(sim.obstacles.size(), 0, "ignored blue obstacle still leaves the battlefield cleanly")

func test_brake_coil_adds_time_when_obstacle_clears() -> void:
	var inv := InventoryScript.new(6, 6)
	inv.place_artifact(_relic("brake_coil", "Brake Coil", {
		"trigger": "on_obstacle_clear",
		"type": "clear_add_time",
		"value": 20
	}), 1, 1)
	var sim := _sim_with_queue("red", 10.0, 10.0)
	sim.time_limit_ticks = 600
	sim.obstacles = [_obstacle("haz_red_clear", "red", "r0c1", {"afterglowTicks": 0, "clearProgress": 1})]
	CombatVocabScript.fire_shot(sim, "red", "r0c1", {}, inv)
	_assert_eq(sim.time_limit_ticks, 620, "brake coil adds one second when an obstacle is removed")

func test_anchor_oathplate_globalizes_all_weakness_tiles_every_five_hits() -> void:
	var inv := InventoryScript.new(6, 6)
	inv.place_artifact(_relic("anchor_oathplate", "Anchor Oathplate", {
		"trigger": "on_weakness_hit",
		"type": "globalize_weakness_every_five_hits",
		"threshold": 5
	}), 1, 1)
	var sim := CombatSimulatorScript.new({
		"combat": {
			"shield": 100.0,
			"health": 100.0,
			"maxShield": 100.0,
			"maxHealth": 100.0,
			"weakness": ["red"]
		}
	}, {}, 8)
	sim.weakness_markers = [
		{"cellId": "r0c0", "color": "red"},
		{"cellId": "r0c1", "color": "blue"},
		{"cellId": "r0c2", "color": "green"}
	]
	sim.queue = ["red", "red", "red", "red", "red", "blue"]
	sim.aim_can_fire = true
	for shot_index in range(4):
		CombatVocabScript.fire_shot(sim, "red", "r0c0", {}, inv)
	_assert_eq(bool(sim.weakness_markers[1].get("allEnergyWeakness", false)), false, "anchor oathplate waits until the fifth real weakness hit")
	CombatVocabScript.fire_shot(sim, "red", "r0c0", {}, inv)
	_assert_eq(str(sim.weakness_markers[0].get("color", "")), "red", "anchor oathplate preserves the original red tile color")
	_assert_eq(str(sim.weakness_markers[1].get("color", "")), "blue", "anchor oathplate preserves the original blue tile color")
	_assert_eq(str(sim.weakness_markers[2].get("color", "")), "green", "anchor oathplate preserves the original green tile color")
	for marker in sim.weakness_markers:
		_assert_eq(bool(marker.get("allEnergyWeakness", false)), true, "anchor oathplate marks every visible tile as any-energy weakness after five hits")
	CombatVocabScript.fire_shot(sim, "green", "r0c2", {}, inv)
	_assert_eq(sim.result, "match", "anchor oathplate turns off-color follow-up hits into weakness matches once triggered")
	_assert_eq(sim.queue_pinned_slots, 0, "anchor oathplate follow-up hits do not pin the queue like mismatches")
	for marker in sim.weakness_markers:
		_assert_eq(bool(marker.get("allEnergyWeakness", false)), false, "anchor oathplate spends the all-energy weakness state after one follow-up shot")

func test_purple_obstacle_active_tick_does_not_decay_terrain_debuff() -> void:
	var sim := _sim_with_queue("purple", 10.0, 10.0)
	sim.terrain_debuffs = [{"scope": "global", "effect": "weakened_terrain", "energy": "purple", "stacks": 2}]
	sim.obstacles = [_obstacle("haz_purple_active", "purple", "r1c5", {"warningTicks": 0, "pulseTicksRemaining": 1, "pulseIntervalTicks": 20})]
	CombatVocabScript.tick_combat(sim, 1, null)
	_assert_eq(int(sim.terrain_debuffs[0].get("stacks", 0)), 2, "active purple obstacles no longer strip weakened stacks on a timer")
	_assert_eq(sim.terrain_buffs.size(), 0, "active purple obstacles do not grant fortified stacks before execute")

func test_purple_obstacle_exit_failure_cleanses_weakened_stack_before_granting_buff() -> void:
	var sim := _sim_with_queue("purple", 10.0, 10.0)
	sim.terrain_debuffs = [{"scope": "global", "effect": "weakened_terrain", "energy": "purple", "stacks": 2}]
	sim.obstacles = [_obstacle("haz_purple_cleanse", "purple", "r1c9")]
	CombatVocabScript.resolve_obstacle_shift_exit(sim, ["haz_purple_cleanse"])
	_assert_eq(int(sim.terrain_debuffs[0].get("stacks", 0)), 1, "purple execute removes one weakened stack before any buff is granted")
	_assert_eq(sim.terrain_buffs.size(), 0, "purple execute does not add a fortified stack while weakened terrain remains")

func test_purple_obstacle_exit_failure_grants_fortified_buff_at_normal() -> void:
	var sim := _sim_with_queue("purple", 10.0, 10.0)
	sim.obstacles = [_obstacle("haz_purple_guard", "purple", "r1c9")]
	CombatVocabScript.resolve_obstacle_shift_exit(sim, ["haz_purple_guard"])
	_assert_eq(sim.terrain_debuffs.size(), 0, "purple execute at normal does not create a weakened stack")
	_assert_eq(sim.terrain_buffs.size(), 1, "purple execute at normal creates one fortified stack")
	_assert_eq(str(sim.terrain_buffs[0].get("effect", "")), "fortified_terrain", "purple fortified stack uses the dedicated buff effect")
	_assert_eq(int(sim.terrain_buffs[0].get("stacks", 0)), 1, "purple execute adds exactly one fortified stack")

func test_purple_fortified_buff_reduces_damage() -> void:
	var baseline := _sim_with_queue("red", 0.0, 10.0)
	CombatVocabScript.fire_shot(baseline, "red", "r0c0", {}, null)
	var fortified := _sim_with_queue("red", 0.0, 10.0)
	fortified.terrain_buffs = [{"scope": "global", "effect": "fortified_terrain", "energy": "purple", "stacks": 1}]
	CombatVocabScript.fire_shot(fortified, "red", "r0c0", {}, null)
	_assert(fortified.health > baseline.health, "fortified terrain buff reduces outgoing damage against the leviathan")

func test_purple_hit_breaks_fortified_buff_before_adding_debuff() -> void:
	var sim := _sim_with_queue("purple", 10.0, 10.0)
	sim.terrain_buffs = [{"scope": "global", "effect": "fortified_terrain", "energy": "purple", "stacks": 1}]
	CombatVocabScript.fire_shot(sim, "purple", "r1c2", {}, null)
	_assert_eq(sim.terrain_buffs.size(), 0, "purple hits remove one fortified stack before creating more weakened terrain")
	_assert_eq(sim.terrain_debuffs.size(), 0, "purple hits that only break a fortified stack do not add a weakened stack on the same shot")

func test_purple_obstacle_exit_failure_triggers_pressure_pulse() -> void:
	var sim := _sim_with_queue("purple", 10.0, 10.0)
	sim.terrain_debuffs = [{"scope": "global", "effect": "weakened_terrain", "energy": "purple", "stacks": 1}]
	sim.obstacles = [_obstacle("haz_purple_exit", "purple", "r1c9")]
	CombatVocabScript.resolve_obstacle_shift_exit(sim, ["haz_purple_exit"])
	_assert_eq(sim.terrain_debuffs.size(), 0, "purple exit failure consumes one terrain debuff stack via the execute pulse")
	_assert_eq(sim.terrain_buffs.size(), 0, "purple exit failure that cleanses a debuff does not also create a fortified stack")
	_assert_eq(int(sim.obstacle_miss_debt.get("purple", 0)), 1, "purple exit failure still adds miss debt")

func test_green_obstacle_exit_failure_heals_leviathan() -> void:
	var sim := _sim_with_queue("green", 10.0, 5.0)
	sim.max_health = 10.0
	sim.obstacles = [_obstacle("haz_green_exit", "green", "r2c9", {"healAmount": 1.5})]
	CombatVocabScript.resolve_obstacle_shift_exit(sim, ["haz_green_exit"])
	_assert_eq(sim.health, 6.5, "green exit failure heals leviathan health")
	_assert_eq(int(sim.obstacle_miss_debt.get("green", 0)), 1, "green exit failure adds miss debt")

func test_cleared_obstacle_without_afterglow_disappears_on_next_tick() -> void:
	var sim := _sim_with_queue("red", 10.0, 10.0)
	sim.obstacles = [_obstacle("haz_red_clear", "red", "r0c1", {"afterglowTicks": 0, "clearProgress": 1})]
	CombatVocabScript.fire_shot(sim, "red", "r0c1", {}, null)
	CombatVocabScript.tick_combat(sim, 1, null)
	_assert_eq(sim.obstacles.size(), 0, "zero-afterglow hazards leave no lingering shell")

func test_obstacle_spawn_rotation_cycles_families_over_successive_waves() -> void:
	var sim := _sim_with_spawn_profile({
		"chance": 1.0,
		"maxPerShift": 1,
		"maxInitialSpawns": 0,
		"allowedFamilies": ["red", "blue", "purple", "green"]
	}, ["red", "blue", "purple", "green"])
	var seen := {}
	for step in range(4):
		sim.obstacles.clear()
		CombatVocabScript.shift_battlefield(sim, 17, ["red", "blue", "purple", "green"], step + 1, 0, 1.0)
		_assert(not sim.obstacles.is_empty(), "obstacle wave %d spawns at least one obstacle" % step)
		if sim.obstacles.is_empty():
			continue
		var family := str(sim.obstacles[0].get("family", ""))
		seen[family] = true
	_assert_eq(seen.size(), 4, "successive obstacle waves rotate across all four families at low pressure")

func test_obstacle_spawn_restricts_families_to_selected_node_colors() -> void:
	var sim := CombatSimulatorScript.new({
		"combat": {
			"shield": 10.0,
			"health": 10.0,
			"maxShield": 10.0,
			"maxHealth": 10.0,
			"hazard": {
				"allowedFamilies": ["red", "blue"],
				"spawn": {"chance": 1.0, "maxPerShift": 1, "maxInitialSpawns": 0, "allowedFamilies": ["red", "blue"]}
			}
		}
	}, {}, 16)
	var seen := {}
	for step in range(6):
		sim.obstacles.clear()
		CombatVocabScript.shift_battlefield(sim, 17, ["red", "blue", "purple", "green"], step + 1, 0, 1.0)
		_assert(not sim.obstacles.is_empty(), "restricted obstacle wave %d still spawns at least one hazard" % step)
		for obstacle in sim.obstacles:
			seen[str(obstacle.get("family", ""))] = true
	var terrain_colors := {}
	for marker in sim.weakness_markers:
		terrain_colors[str(marker.get("color", ""))] = true
	_assert(seen.has("red"), "restricted obstacle spawns still include red when the node allows it")
	_assert(seen.has("blue"), "restricted obstacle spawns still include blue when the node allows it")
	_assert(not seen.has("purple"), "restricted obstacle spawns exclude colors missing from the selected node")
	_assert(not seen.has("green"), "restricted obstacle spawns exclude unrelated terrain colors")
	_assert(terrain_colors.has("purple") or terrain_colors.has("green"), "hazard family restriction does not collapse terrain energy to the node colors")

func test_node_modifier_carries_hazard_spawn_profile() -> void:
	var applied := ApplyNodeModifiersScript.apply({
		"id": "boss_spine",
		"label": "Spine Anchor",
		"nodeType": "boss",
		"riskTier": "boss",
		"weakness": ["red", "blue", "purple"],
		"pickWeight": 1,
		"shieldMul": 1.6,
		"healthMul": 1.8,
		"rewardBias": "run_clear",
		"recommendedBuildHint": "Bring mixed coverage",
		"difficultyModifier": 1.7,
		"rewardModifier": 1.8,
		"hazardModifier": 1.4,
		"hazardSpawn": {
			"chance": 0.72,
			"maxPerShift": 3,
			"maxInitialSpawns": 6,
			"allowedFamilies": ["red", "blue", "purple"]
		}
	}, {})
	var spawn: Dictionary = applied.get("combat", {}).get("hazard", {}).get("spawn", {})
	_assert_eq(float(spawn.get("chance", -1.0)), 0.72, "node modifiers carry hazard spawn chance")
	_assert_eq(int(spawn.get("maxPerShift", 0)), 3, "node modifiers carry hazard per-shift cap")
	_assert_eq(int(spawn.get("maxInitialSpawns", 0)), 6, "node modifiers carry hazard initial spawn cap")

func test_shift_obstacle_spawn_respects_zero_chance_without_backfill() -> void:
	var sim := _sim_with_spawn_profile({
		"chance": 0.0,
		"maxPerShift": 3,
		"maxInitialSpawns": 0,
		"allowedFamilies": ["red"]
	}, ["red"])
	CombatVocabScript.shift_battlefield(sim, 17, ["red", "blue", "purple", "green"], 1, 0, 1.0)
	_assert_eq(sim.obstacles.size(), 0, "zero spawn chance prevents target-count backfill on shifted terrain")

func test_shift_obstacle_spawn_uses_only_inserted_new_tiles() -> void:
	var sim := _sim_with_spawn_profile({
		"chance": 1.0,
		"maxPerShift": 3,
		"maxInitialSpawns": 0,
		"allowedFamilies": ["red", "blue", "purple"]
	}, ["red", "blue", "purple"])
	CombatVocabScript.shift_battlefield(sim, 17, ["red", "blue", "purple", "green"], 1, 0, 1.0)
	_assert_eq(sim.obstacles.size(), 3, "full-chance wave can fill all inserted tiles")
	for obstacle in sim.obstacles:
		_assert(str(obstacle.get("cellId", "")).ends_with("c0"), "shift spawn only uses the newly inserted left-column tiles")

func test_shift_obstacle_spawn_can_fill_multiple_new_tiles_with_multiple_families() -> void:
	var sim := _sim_with_spawn_profile({
		"chance": 1.0,
		"maxPerShift": 3,
		"maxInitialSpawns": 0,
		"allowedFamilies": ["red", "blue", "purple"]
	}, ["red", "blue", "purple"])
	CombatVocabScript.shift_battlefield(sim, 17, ["red", "blue", "purple", "green"], 1, 0, 1.0)
	var seen := {}
	for obstacle in sim.obstacles:
		seen[str(obstacle.get("family", ""))] = true
	_assert(seen.size() >= 2, "boss-like shift can emit multiple hazard families in one wave")

func test_prime_obstacles_respects_initial_spawn_cap() -> void:
	var sim := _sim_with_spawn_profile({
		"chance": 1.0,
		"maxPerShift": 3,
		"maxInitialSpawns": 5,
		"allowedFamilies": ["red", "blue", "purple"]
	}, ["red", "blue", "purple"])
	CombatVocabScript.prime_obstacles(sim, 17, 0, 1.0)
	_assert_eq(sim.obstacles.size(), 5, "initial board seeding respects the explicit maxInitialSpawns cap")

# 실행: create a deterministic drill artifact.
func _artifact(id: String, energy: String) -> Artifact:
	return ArtifactScript.new({"id": id, "name": id, "shape": [[1]], "energyType": energy, "item_type": "drill", "baseCooldownTicks": 10})

func _relic(id: String, name: String, effect_schema: Dictionary, shape: Array = [[1]]) -> Artifact:
	return ArtifactScript.new({
		"id": id,
		"name": name,
		"shape": shape,
		"energyType": "",
		"item_type": "relic",
		"baseCooldownTicks": 1,
		"damage": 0.0,
		"effect_schema": effect_schema
	})

# 실행: create a combat simulator with a single queued energy.
func _sim_with_queue(energy: String, shield: float, health: float) -> CombatSimulator:
	var sim = CombatSimulatorScript.new({"combat": {"shield": shield, "health": health, "maxShield": shield, "maxHealth": health, "weakness": [energy]}}, {}, 8)
	sim.queue.clear()
	sim.queue.append(energy)
	sim.aim_can_fire = true
	return sim

func _sim_with_spawn_profile(spawn_profile: Dictionary, allowed_families: Array) -> CombatSimulator:
	return CombatSimulatorScript.new({
		"combat": {
			"shield": 10.0,
			"health": 10.0,
			"maxShield": 10.0,
			"maxHealth": 10.0,
			"hazard": {
				"allowedFamilies": allowed_families,
				"spawn": spawn_profile
			}
		}
	}, {}, 8)

func _obstacle(id: String, family: String, cell_id: String, overrides: Dictionary = {}) -> Dictionary:
	var obstacle := {
		"id": id,
		"family": family,
		"requiredColor": family,
		"cellId": cell_id,
		"state": "active",
		"progress": 0,
		"clearProgress": 2,
		"warningTicks": 20,
		"warningTicksRemaining": int(overrides.get("warningTicks", 20)),
		"afterglowTicksRemaining": 0,
		"pulseIntervalTicks": int(overrides.get("pulseIntervalTicks", 20)),
		"pulseTicksRemaining": int(overrides.get("pulseTicksRemaining", 20)),
		"timeCutTicks": int(overrides.get("timeCutTicks", 240)),
		"healAmount": float(overrides.get("healAmount", 1.0))
	}
	for key in overrides.keys():
		obstacle[key] = overrides[key]
	return obstacle

# 실행: append a failure when condition is false.
func _assert(condition: bool, msg: String) -> void:
	if not condition:
		failures.append(msg)

# 실행: append a deterministic equality failure when values differ.
func _assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])
