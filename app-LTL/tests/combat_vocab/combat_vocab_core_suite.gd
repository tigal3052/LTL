# 계약:
# - 책임: test_combat_vocab.gd에서 분리된 focused combat vocab suite를 실행한다.
extends "res://tests/combat_vocab/combat_vocab_support.gd"
func run_all_tests() -> Dictionary:
	failures.clear()
	test_combat_vocab_extracts_relic_hooks_and_caps_owner()
	test_queue_colors_cycle_active_drill_colors()
	test_queue_items_keep_dictionary_shape_when_inventory_generates_energy()
	test_queue_tokens_keep_same_color_drill_instances_and_average_cooldown()
	test_queue_average_cooldown_keeps_fractional_arithmetic_value()
	test_inventory_generation_uses_average_cooldown_sorted_rotation()
	test_beacon_marks_tokens_without_permanent_drill_damage_mutation()
	test_combat_uses_energy_token_damage_and_source_instance()
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
	return {"ok": failures.is_empty(), "errors": failures}
func test_combat_vocab_extracts_relic_hooks_and_caps_owner() -> void:
	var helper_path := "res://src/vocabulary/combat/CombatRelicHooks.gd"
	_assert(FileAccess.file_exists(helper_path), "combat relic hooks helper exists")
	if FileAccess.file_exists(helper_path):
		var HelperScript = load(helper_path)
		_assert(HelperScript != null, "combat relic hooks helper loads")
		if HelperScript != null:
			_assert(HelperScript.has_method("on_repair_end"), "combat relic hooks owns repair-end effects")
			_assert(HelperScript.has_method("maybe_protect_blue_activation"), "combat relic hooks owns blue activation guard")
			_assert(HelperScript.has_method("before_obstacle_execute"), "combat relic hooks owns execute prevention")
			_assert(HelperScript.has_method("after_obstacle_clear"), "combat relic hooks owns obstacle-clear effects")
			_assert(HelperScript.has_method("after_weakness_hit"), "combat relic hooks owns weakness-hit effects")
		var helper_lines := _source_line_count(helper_path)
		_assert(helper_lines > 0 and helper_lines <= 500, "combat relic hooks helper stays within 500 lines, got %d" % helper_lines)
	var definition_helper_path := "res://src/vocabulary/combat/CombatObstacleDefinitions.gd"
	_assert(FileAccess.file_exists(definition_helper_path), "combat obstacle definitions helper exists")
	if FileAccess.file_exists(definition_helper_path):
		var DefinitionHelperScript = load(definition_helper_path)
		_assert(DefinitionHelperScript != null, "combat obstacle definitions helper loads")
		if DefinitionHelperScript != null:
			_assert(DefinitionHelperScript.has_method("build"), "combat obstacle definitions helper owns obstacle dictionary construction")
		var definition_helper_lines := _source_line_count(definition_helper_path)
		_assert(definition_helper_lines > 0 and definition_helper_lines <= 500, "combat obstacle definitions helper stays within 500 lines, got %d" % definition_helper_lines)
	var vocab_lines := _source_line_count("res://src/vocabulary/CombatVocab.gd")
	_assert(vocab_lines > 0 and vocab_lines <= 500, "CombatVocab.gd stays within 500 lines after relic hook extraction, got %d" % vocab_lines)
# 실행: verify active drill colors repeat to queue capacity.
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

func test_queue_tokens_keep_same_color_drill_instances_and_average_cooldown() -> void:
	var inv := InventoryScript.new(5, 5)
	inv.place_artifact(_tuned_drill("red_slow", "red", 30, 1.2), 0, 0)
	inv.place_artifact(_tuned_drill("red_fast", "red", 10, 2.4), 2, 0)
	inv.place_artifact(_tuned_drill("blue_mid", "blue", 20, 1.8), 0, 2)
	var result = RecalculateQueueColorsScript.recalculate(inv, 6)
	_assert_eq(bool(result.get("ok", false)), true, "queue token calculation succeeds")
	_assert_eq(int(result.get("average_cooldown_ticks", 0)), 20, "queue reports arithmetic average cooldown")
	var items: Array = result.get("items", [])
	_assert_eq(items.size(), 6, "queue fills requested loaded token count")
	var expected_sources := ["red_fast", "blue_mid", "red_slow", "red_fast", "blue_mid", "red_slow"]
	var expected_damage := {"red_fast": 2.4, "blue_mid": 1.8, "red_slow": 1.2}
	for i in range(items.size()):
		var item: Dictionary = items[i]
		var source_id := str(item.get("source_drill_instance_id", item.get("source_artifact_id", "")))
		_assert_eq(source_id, expected_sources[i], "queue token order follows effective cooldown sort at index %d" % i)
		_assert_eq(str(item.get("color", "")), "blue" if source_id == "blue_mid" else "red", "queue token keeps drill color at index %d" % i)
		_assert(absf(float(item.get("damage", 0.0)) - float(expected_damage[source_id])) <= 0.001, "same-color token keeps per-drill damage at index %d" % i)
		_assert(item.has("attack_style"), "queue token carries attack style at index %d" % i)
		_assert(item.has("modifiers"), "queue token carries modifiers dictionary at index %d" % i)
		_assert(item.has("buff_source_ids"), "queue token carries buff source ids at index %d" % i)

func test_queue_average_cooldown_keeps_fractional_arithmetic_value() -> void:
	var inv := InventoryScript.new(4, 4)
	inv.place_artifact(_tuned_drill("red_ten", "red", 10, 1.0), 0, 0)
	inv.place_artifact(_tuned_drill("blue_eleven", "blue", 11, 1.0), 2, 0)
	var result = RecalculateQueueColorsScript.recalculate(inv, 2)
	_assert(absf(float(result.get("average_cooldown_ticks", 0.0)) - 10.5) <= 0.001, "queue reports fractional arithmetic average cooldown")

func test_inventory_generation_uses_average_cooldown_sorted_rotation() -> void:
	var inv := InventoryScript.new(5, 5)
	inv.place_artifact(_tuned_drill("red_slow", "red", 30, 1.2), 0, 0)
	inv.place_artifact(_tuned_drill("red_fast", "red", 10, 2.4), 2, 0)
	inv.place_artifact(_tuned_drill("blue_mid", "blue", 20, 1.8), 0, 2)
	for _i in range(19):
		_assert_eq(inv.tick().size(), 0, "average cooldown does not generate before tick 20")
	var first: Array = inv.tick()
	_assert_eq(first.size(), 1, "average cooldown generates on tick 20")
	if not first.is_empty():
		_assert_eq(str(first[0].get("source_drill_instance_id", first[0].get("source_artifact_id", ""))), "red_fast", "first generated token uses fastest drill")
	for _i in range(19):
		_assert_eq(inv.tick().size(), 0, "second token waits another average cooldown interval")
	var second: Array = inv.tick()
	_assert_eq(second.size(), 1, "second token generates on the next average interval")
	if not second.is_empty():
		_assert_eq(str(second[0].get("source_drill_instance_id", second[0].get("source_artifact_id", ""))), "blue_mid", "second generated token follows sorted drill rotation")

func test_beacon_marks_tokens_without_permanent_drill_damage_mutation() -> void:
	var inv := InventoryScript.new(4, 4)
	var drill := _tuned_drill("red_base", "red", 1, 1.0)
	var beacon := ArtifactScript.new({
		"id": "red_damage_beacon",
		"name": "Red Damage Beacon",
		"shape": [[1]],
		"energyType": "red",
		"item_type": "beacon",
		"baseCooldownTicks": 99,
		"beaconDamageMod": 0.75
	})
	inv.place_artifact(drill, 0, 0)
	inv.place_artifact(beacon, 1, 0)
	_assert(absf(float(drill.damage) - 1.0) <= 0.001, "beacon placement does not mutate drill damage")
	var generated: Array = inv.tick()
	_assert(absf(float(drill.damage) - 1.0) <= 0.001, "beacon token generation still leaves drill damage unchanged")
	_assert_eq(generated.size(), 1, "single drill produces one token")
	if not generated.is_empty():
		var token: Dictionary = generated[0]
		_assert(absf(float(token.get("damage", 0.0)) - 1.75) <= 0.001, "beacon damage is stamped on token damage")
		var modifiers: Dictionary = token.get("modifiers", {})
		_assert(absf(float(modifiers.get("beacon_damage_bonus", 0.0)) - 0.75) <= 0.001, "token records beacon damage modifier")
		var buff_source_ids: Array = token.get("buff_source_ids", [])
		_assert(buff_source_ids.has("red_damage_beacon"), "token records beacon source id")

func test_combat_uses_energy_token_damage_and_source_instance() -> void:
	var inv := InventoryScript.new(4, 4)
	var source_drill := _tuned_drill("red_source", "red", 10, 1.0)
	inv.place_artifact(source_drill, 0, 0)
	var sim := _sim_with_queue("red", 0.0, 20.0)
	sim.queue.clear()
	sim.queue.append({
		"color": "red",
		"source_artifact_id": "red_source",
		"source_drill_instance_id": "red_source",
		"source_item_type": "drill",
		"damage": 4.0,
		"attack_style": "red",
		"modifiers": {},
		"buff_source_ids": []
	})
	CombatVocabScript.fire_shot(sim, "red", "r0c0", {}, inv)
	_assert(20.0 - sim.health > 6.0, "combat damage uses token damage rather than mutable source drill damage")

func _tuned_drill(id: String, energy: String, cooldown: int, damage: float) -> Artifact:
	return ArtifactScript.new({
		"id": id,
		"name": id,
		"shape": [[1]],
		"energyType": energy,
		"item_type": "drill",
		"baseCooldownTicks": cooldown,
		"nativeBaseCooldownTicks": cooldown,
		"currentCooldown": cooldown,
		"damage": damage
	})
# 실행: verify marker shift drops right edge and adds deterministic left column.
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
# 실행: verify repeated timer steps do not insert identical left-column colors.
func test_shift_markers_changes_left_column_with_step() -> void:
	var first = ShiftWeaknessMarkersScript.shift([], 3, 10, 99, ["red", "blue", "purple", "green"], 1)
	var second = ShiftWeaknessMarkersScript.shift([], 3, 10, 99, ["red", "blue", "purple", "green"], 2)
	_assert(first["markers"] != second["markers"], "marker shift step changes inserted colors")
# 실행: verify inserted terrain colors come from seeded random draws instead of a repeated diagonal formula.
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
# 실행: verify green energy pierces shield and still reduces health.
func test_green_energy_damages_health_through_shield() -> void:
	var sim := _sim_with_queue("green", 10.0, 10.0)
	CombatVocabScript.fire_shot(sim, "green", "r0c0", {}, null)
	_assert(sim.shield > 0.0, "green leaves shield present")
	_assert(sim.health < 10.0, "green damages health through shield")
# 실행: verify red is health-leaning and blue is shield-leaning.
# 실행: verify red is health-leaning and blue is shield-leaning.
func test_red_and_blue_energy_emphasize_health_and_shield_damage() -> void:
	var red_sim := _sim_with_queue("red", 0.0, 10.0)
	var blue_sim := _sim_with_queue("blue", 10.0, 10.0)
	CombatVocabScript.fire_shot(red_sim, "red", "r0c0", {}, null)
	CombatVocabScript.fire_shot(blue_sim, "blue", "r0c0", {}, null)
	_assert(red_sim.health <= 8.0, "red deals moderate health damage when health is exposed")
	_assert(blue_sim.shield <= 7.1, "blue deals high shield damage")
# 실행: verify purple trades lower damage for terrain debuff metadata.
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
# 실행: verify purple debuff stacks scale damage without a hard cap.
func test_purple_energy_stack_bonus_has_no_damage_cap_and_hits_hp() -> void:
	var sim := _sim_with_queue("purple", 30.0, 30.0)
	sim.terrain_debuffs = [{"scope": "global", "effect": "weakened_terrain", "energy": "purple", "stacks": 24}]
	CombatVocabScript.fire_shot(sim, "purple", "r1c2", {}, null)
	_assert(30.0 - sim.shield > 5.0, "purple stacked debuff can exceed five shield damage")
	_assert(30.0 - sim.health > 5.0, "purple stacked debuff can exceed five health damage")
	_assert_eq(int(sim.terrain_debuffs[0].get("stacks", 0)), 25, "purple stack increments without replacing cap")
# 실행: verify red still leans HP but no longer deals the old near-five HP burst at 1.5 damage.
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
