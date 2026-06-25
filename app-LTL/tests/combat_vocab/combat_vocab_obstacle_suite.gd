# 계약:
# - 책임: test_combat_vocab.gd에서 분리된 focused combat vocab suite를 실행한다.
extends "res://tests/combat_vocab/combat_vocab_support.gd"
func run_all_tests() -> Dictionary:
	failures.clear()
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
	test_obstacle_exit_failures_emit_feedback_events()
	test_cleared_obstacle_without_afterglow_disappears_on_next_tick()
	return {"ok": failures.is_empty(), "errors": failures}
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
func test_obstacle_exit_failures_emit_feedback_events() -> void:
	var red_sim := _sim_with_queue("red", 10.0, 10.0)
	red_sim.elapsed_ticks = 100
	red_sim.time_limit_ticks = 700
	red_sim.obstacles = [_obstacle("haz_red_feedback", "red", "r0c9", {"timeCutTicks": 240})]
	CombatVocabScript.resolve_obstacle_shift_exit(red_sim, ["haz_red_feedback"])
	var red_event := _first_obstacle_feedback_event(red_sim)
	_assert_eq(str(red_event.get("family", "")), "red", "red feedback records the obstacle family")
	_assert_eq(str(red_event.get("channel", "")), "timer", "red feedback anchors near the combat timer")
	_assert(str(red_event.get("text", "")).begins_with("-"), "red feedback text shows the timer cut")
	_assert_eq(bool(red_event.get("popup", false)), true, "red feedback emits popup text")
	var blue_sim := _sim_with_queue("blue", 10.0, 10.0)
	blue_sim.obstacles = [_obstacle("haz_blue_feedback", "blue", "r1c9")]
	CombatVocabScript.resolve_obstacle_shift_exit(blue_sim, ["haz_blue_feedback"])
	var blue_event := _first_obstacle_feedback_event(blue_sim)
	_assert_eq(str(blue_event.get("family", "")), "blue", "blue feedback records the obstacle family")
	_assert_eq(bool(blue_event.get("popup", true)), false, "blue feedback flashes without popup text")
	var purple_sim := _sim_with_queue("purple", 10.0, 10.0)
	purple_sim.terrain_debuffs = [{"scope": "global", "effect": "weakened_terrain", "energy": "purple", "stacks": 1}]
	purple_sim.obstacles = [_obstacle("haz_purple_feedback", "purple", "r1c9")]
	CombatVocabScript.resolve_obstacle_shift_exit(purple_sim, ["haz_purple_feedback"])
	var purple_event := _first_obstacle_feedback_event(purple_sim)
	_assert_eq(str(purple_event.get("family", "")), "purple", "purple feedback records the obstacle family")
	_assert_eq(str(purple_event.get("channel", "")), "purple_debuff", "purple feedback anchors near the debuff stack")
	_assert_eq(str(purple_event.get("text", "")), "-1 디버프", "purple feedback reports one debuff stack cleanse")
	var green_sim := _sim_with_queue("green", 10.0, 5.0)
	green_sim.max_health = 10.0
	green_sim.obstacles = [_obstacle("haz_green_feedback", "green", "r2c9", {"healAmount": 1.5})]
	CombatVocabScript.resolve_obstacle_shift_exit(green_sim, ["haz_green_feedback"])
	var green_event := _first_obstacle_feedback_event(green_sim)
	_assert_eq(str(green_event.get("family", "")), "green", "green feedback records the obstacle family")
	_assert_eq(str(green_event.get("channel", "")), "health", "green feedback anchors near Leviathan health")
	_assert(str(green_event.get("text", "")).begins_with("+"), "green feedback text shows the healing amount")
func test_cleared_obstacle_without_afterglow_disappears_on_next_tick() -> void:
	var sim := _sim_with_queue("red", 10.0, 10.0)
	sim.obstacles = [_obstacle("haz_red_clear", "red", "r0c1", {"afterglowTicks": 0, "clearProgress": 1})]
	CombatVocabScript.fire_shot(sim, "red", "r0c1", {}, null)
	CombatVocabScript.tick_combat(sim, 1, null)
	_assert_eq(sim.obstacles.size(), 0, "zero-afterglow hazards leave no lingering shell")
