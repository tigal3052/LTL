# 계약:
# - 책임: test_combat_vocab.gd에서 분리된 focused combat vocab suite를 실행한다.
extends "res://tests/combat_vocab/combat_vocab_support.gd"
func run_all_tests() -> Dictionary:
	failures.clear()
	test_obstacle_spawn_rotation_cycles_families_over_successive_waves()
	test_obstacle_spawn_restricts_families_to_selected_node_colors()
	test_obstacle_spawn_respects_all_single_and_pair_allowed_families()
	test_normal_obstacles_clear_after_one_hit()
	test_boss_obstacles_require_two_hits()
	test_node_modifier_carries_hazard_spawn_profile()
	test_shift_obstacle_spawn_respects_zero_chance_without_backfill()
	test_shift_obstacle_spawn_uses_only_inserted_new_tiles()
	test_shift_obstacle_spawn_can_fill_multiple_new_tiles_with_multiple_families()
	test_prime_obstacles_respects_initial_spawn_cap()
	return {"ok": failures.is_empty(), "errors": failures}
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
func test_obstacle_spawn_respects_all_single_and_pair_allowed_families() -> void:
	var combos := [
		["red"],
		["blue"],
		["purple"],
		["green"],
		["red", "blue"],
		["red", "purple"],
		["red", "green"],
		["blue", "purple"],
		["blue", "green"],
		["purple", "green"]
	]
	for combo in combos:
		var sim := _sim_with_spawn_profile({
			"chance": 1.0,
			"maxPerShift": 3,
			"maxInitialSpawns": 0,
			"allowedFamilies": combo
		}, combo)
		var seen := {}
		for step in range(6):
			sim.obstacles.clear()
			CombatVocabScript.shift_battlefield(sim, 23, ["red", "blue", "purple", "green"], step + 1, 0, 1.0)
			for obstacle in sim.obstacles:
				var family := str(obstacle.get("family", ""))
				seen[family] = true
				_assert(combo.has(family), "spawned obstacle family %s stays within allowed terrain combo %s" % [family, str(combo)])
		for family in combo:
			_assert(seen.has(str(family)), "allowed terrain combo %s can spawn %s obstacle pressure" % [str(combo), str(family)])
func test_normal_obstacles_clear_after_one_hit() -> void:
	var sim := _sim_with_queue("blue", 10.0, 10.0)
	var obstacle := CombatObstacleDefinitionsScript.build(sim, "red", "r0c1", 8, 0)
	_assert_eq(int(obstacle.get("clearProgress", 0)), 1, "non-boss obstacles require one hit even at later stages")
	sim.obstacles = [obstacle]
	CombatVocabScript.fire_shot(sim, "red", "r0c1", {}, null)
	_assert_eq(str(sim.obstacles[0].get("state", "")), "afterglow_clear", "non-boss obstacle clears after one hit")
func test_boss_obstacles_require_two_hits() -> void:
	var sim := CombatSimulatorScript.new({
		"combat": {
			"shield": 10.0,
			"health": 10.0,
			"maxShield": 10.0,
			"maxHealth": 10.0,
			"weakness": ["red"],
			"hazard": {"tier": "boss", "allowedFamilies": ["red"]}
		}
	}, {}, 8)
	sim.queue.clear()
	sim.queue.append("red")
	sim.queue.append("red")
	sim.aim_can_fire = true
	var obstacle := CombatObstacleDefinitionsScript.build(sim, "red", "r0c1", 0, 0)
	_assert_eq(int(obstacle.get("clearProgress", 0)), 2, "boss obstacles keep two-hit clear progress")
	sim.obstacles = [obstacle]
	CombatVocabScript.fire_shot(sim, "red", "r0c1", {}, null)
	_assert_eq(str(sim.obstacles[0].get("state", "")), "active", "boss obstacle survives the first matching hit")
	_assert_eq(int(sim.obstacles[0].get("progress", 0)), 1, "boss obstacle records first-hit progress")
	CombatVocabScript.fire_shot(sim, "red", "r0c1", {}, null)
	_assert_eq(str(sim.obstacles[0].get("state", "")), "afterglow_clear", "boss obstacle clears on the second matching hit")
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
