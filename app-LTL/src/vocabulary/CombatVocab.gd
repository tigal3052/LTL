# 계약:
# - 책임: 전투 시뮬레이터 상태를 대상으로 순수 전투 함수(전투 준비, 공격 판정, 수리 적용, 시간 경과, 장애물 처리)를 제공한다.
# - 입력: CombatSimulator 인스턴스, 타겟 색상, 타겟 셀 ID, 전투/장애물 튜닝 Dictionary.
# - 출력: 상태가 갱신된 CombatSimulator 인스턴스 또는 결과 정보.
# - 금지: SceneTree 접근, 자체 상태 보존.
#
# 실행: define the CombatVocab static entry.
class_name CombatVocab
extends RefCounted

const ShiftWeaknessMarkersScript = preload("res://src/vocabulary/combat/ShiftWeaknessMarkers.gd")
const SpawnNewTileObstaclesScript = preload("res://src/vocabulary/combat/SpawnNewTileObstacles.gd")

const OBSTACLE_FAMILIES := ["red", "blue", "purple", "green"]
const PURPLE_WEAKENED_EFFECT := "weakened_terrain"
const PURPLE_FORTIFIED_EFFECT := "fortified_terrain"
const OBSTACLE_MIN_REACTION_COLUMNS := 2
const OBSTACLE_WARNING_TICKS_FAST := 10
const OBSTACLE_WARNING_TICKS_NORMAL := 20
const OBSTACLE_AFTERGLOW_TICKS := 12

# 실행: prepare a new combat simulator instance.
static func prepare_combat(choice: Dictionary, tuning: Dictionary, queue_capacity: int) -> CombatSimulator:
	return CombatSimulator.new(choice, tuning, queue_capacity)

static func _equipped_relics(inventory: InventoryModel) -> Array:
	var relics: Array = []
	if inventory == null:
		return relics
	for art_id in inventory.artifacts:
		var art = inventory.artifacts[art_id]
		if art is Artifact and art.item_type == "relic":
			relics.append(art)
	return relics

static func _relics_with_type(inventory: InventoryModel, effect_type: String) -> Array:
	var relics: Array = []
	for relic in _equipped_relics(inventory):
		if str(relic.effect_schema.get("type", "")) == effect_type:
			relics.append(relic)
	return relics

static func _linked_relics_for_artifact(inventory: InventoryModel, artifact: Artifact, effect_type: String = "") -> Array:
	var relics: Array = []
	if inventory == null or artifact == null:
		return relics
	for relic in _equipped_relics(inventory):
		if not effect_type.is_empty() and str(relic.effect_schema.get("type", "")) != effect_type:
			continue
		for linked_artifact in inventory.get_relic_linked_artifacts(relic):
			if linked_artifact is Artifact and linked_artifact.id == artifact.id:
				relics.append(relic)
				break
	return relics

static func _runtime_bucket(sim: CombatSimulator, key: String) -> Dictionary:
	if not sim.relic_runtime.has(key) or not (sim.relic_runtime.get(key) is Dictionary):
		sim.relic_runtime[key] = {}
	return sim.relic_runtime[key]

static func _consume_once(sim: CombatSimulator, relic_id: String) -> bool:
	var consumed := _runtime_bucket(sim, "consumed")
	if consumed.has(relic_id):
		return false
	consumed[relic_id] = true
	return true

static func _increment_relic_counter(sim: CombatSimulator, relic_id: String, amount: int = 1) -> int:
	var counters := _runtime_bucket(sim, "counters")
	var next_value := int(counters.get(relic_id, 0)) + amount
	counters[relic_id] = next_value
	return next_value

static func _set_relic_counter(sim: CombatSimulator, relic_id: String, value: int) -> void:
	var counters := _runtime_bucket(sim, "counters")
	counters[relic_id] = maxi(0, value)

static func _grant_shot_buff(sim: CombatSimulator, source_artifact_id: String, charges: int, damage_multiplier: float) -> void:
	if source_artifact_id.is_empty() or charges <= 0:
		return
	var shot_buffs := _runtime_bucket(sim, "shotBuffs")
	var buff: Dictionary = shot_buffs.get(source_artifact_id, {})
	buff["charges"] = int(buff.get("charges", 0)) + charges
	buff["damageMultiplier"] = maxf(float(buff.get("damageMultiplier", 1.0)), damage_multiplier)
	shot_buffs[source_artifact_id] = buff

static func _consume_shot_buff_multiplier(sim: CombatSimulator, source_artifact_id: String, source_drill: Artifact = null) -> float:
	var artifact_id := source_artifact_id
	if artifact_id.is_empty() and source_drill != null:
		artifact_id = source_drill.id
	if artifact_id.is_empty():
		return 1.0
	var shot_buffs := _runtime_bucket(sim, "shotBuffs")
	if not shot_buffs.has(artifact_id):
		return 1.0
	var buff = shot_buffs.get(artifact_id, {})
	if not (buff is Dictionary):
		shot_buffs.erase(artifact_id)
		return 1.0
	var charges := int(buff.get("charges", 0))
	if charges <= 0:
		shot_buffs.erase(artifact_id)
		return 1.0
	var multiplier := maxf(1.0, float(buff.get("damageMultiplier", 1.5)))
	charges -= 1
	if charges <= 0:
		shot_buffs.erase(artifact_id)
	else:
		buff["charges"] = charges
		shot_buffs[artifact_id] = buff
	return multiplier

static func _consume_linked_relic_once(sim: CombatSimulator, inventory: InventoryModel, artifact: Artifact, effect_type: String) -> bool:
	for relic in _linked_relics_for_artifact(inventory, artifact, effect_type):
		if _consume_once(sim, relic.id):
			return true
	return false

static func _queue_token(color: String, source_artifact_id: String) -> Dictionary:
	return {
		"color": color,
		"source_artifact_id": source_artifact_id,
		"source_item_type": "drill"
	}

# 실행: fire a shot, consume energy from the queue, determine damage, update health/shield, and apply obstacle progress.
static func fire_shot(sim: CombatSimulator, target_color: Variant, target_cell_id: Variant, tuning: Dictionary, inventory: InventoryModel = null) -> void:
	sim.summary_shots_fired += 1
	sim.aim_cell_id = target_cell_id
	sim.aim_target_color = target_color
	var resolved_target_cell_id := str(target_cell_id)

	if sim.queue.is_empty():
		sim.result = "empty_queue"
		sim.summary_shots_fired_empty_queue += 1
		sim.queue_empty_shots += 1
		if not sim.repair_active:
			apply_repair(sim)
		return

	var queue_item: Variant = sim.queue.pop_front()
	var energy_color := _queue_item_color(queue_item)
	var source_artifact_id := _queue_item_source_artifact_id(queue_item)
	var source_drill := _find_source_drill(inventory, source_artifact_id, energy_color)
	if source_artifact_id.is_empty() and source_drill != null:
		source_artifact_id = source_drill.id
	if sim.queue.is_empty() and not sim.repair_active:
		apply_repair(sim)

	var profile := _energy_profile(energy_color)
	var base_shield := float(profile.get("shield", 0.5))
	var base_hp := float(profile.get("health", 1.0))
	var pierces_health := bool(profile.get("pierceHealth", false))
	var applies_terrain_debuff := bool(profile.get("terrainDebuff", false))
	var fortified_stacks := _terrain_buff_stack_count(sim)
	if energy_color == "purple":
		var stack_bonus := float(_terrain_debuff_stack_count(sim)) * 0.20
		base_shield += stack_bonus
		base_hp += stack_bonus

	var damage_multiplier := 1.0
	if source_drill != null:
		damage_multiplier = source_drill.damage
	damage_multiplier *= _consume_shot_buff_multiplier(sim, source_artifact_id, source_drill)
	base_shield *= damage_multiplier
	base_hp *= damage_multiplier

	var fortified_reduction := clampf(float(fortified_stacks) * 0.10, 0.0, 0.75)
	base_shield *= maxf(0.0, 1.0 - fortified_reduction)
	base_hp *= maxf(0.0, 1.0 - fortified_reduction)

	var target_marker := _weakness_marker_for_cell(sim.weakness_markers, resolved_target_cell_id)
	var resolved_target_color := str(target_color)
	var any_energy_weakness := false
	if not target_marker.is_empty():
		any_energy_weakness = bool(target_marker.get("allEnergyWeakness", false))
		if resolved_target_color.is_empty():
			resolved_target_color = str(target_marker.get("color", ""))
	if any_energy_weakness:
		_clear_all_energy_weakness_flags(sim.weakness_markers)
	var is_vulnerable_pulse := not resolved_target_color.is_empty()

	var combat_tuning: Dictionary = tuning.get("combat", tuning)
	var dmg_bonus := float(combat_tuning.get("damage_bonus", 0.0))
	base_shield += dmg_bonus
	base_hp += dmg_bonus

	var dmg_shield := base_shield
	var dmg_hp := base_hp
	var hit_type := "normal"
	if is_vulnerable_pulse:
		if any_energy_weakness or energy_color == resolved_target_color:
			dmg_shield = base_shield * 1.5
			dmg_hp = base_hp * 1.5
			hit_type = "match"
		else:
			dmg_shield = base_shield * 0.2
			dmg_hp = base_hp * 0.5
			hit_type = "mismatch"

	sim.shield = maxf(0.0, sim.shield - dmg_shield)
	if pierces_health or sim.shield <= 0.0:
		sim.health = maxf(0.0, sim.health - dmg_hp)
	if applies_terrain_debuff:
		_apply_purple_terrain_shift(sim, str(target_cell_id), energy_color)

	_apply_obstacle_hit(sim, resolved_target_cell_id, energy_color, inventory, source_artifact_id, source_drill)

	var pin_active := false
	if sim.health <= 0.0:
		sim.result = "clear"
	else:
		sim.result = hit_type
		if hit_type == "mismatch":
			pin_active = true
			if _consume_linked_relic_once(sim, inventory, source_drill, "first_mismatch_cleanse"):
				pin_active = false
		elif hit_type == "match":
			_after_weakness_hit(sim, inventory, resolved_target_color, energy_color)

	if hit_type == "match" or sim.result == "clear":
		sim.summary_shots_hit_match += 1
	else:
		sim.summary_shots_hit_mismatch += 1

	if pin_active:
		sim.queue_pinned_slots = 1
		sim.pin_active = true
	else:
		sim.queue_pinned_slots = 0
		sim.pin_active = false

	sim.repair_available = sim.queue.is_empty() or sim.queue_empty_shots > 0 or sim.result == "mismatch"
	sim.disabled = sim.result in ["clear", "failed", "time_over"]
	sim.aim_can_fire = not sim.disabled

# 실행: return shield/health identity for each energy color.
static func _energy_profile(energy_color: String) -> Dictionary:
	match energy_color:
		"red":
			return {"shield": 0.5, "health": 1.35}
		"blue":
			return {"shield": 2.0, "health": 0.5}
		"green":
			return {"shield": 0.0, "health": 0.9, "pierceHealth": true}
		"purple":
			return {"shield": 0.55, "health": 0.55, "pierceHealth": true, "terrainDebuff": true}
	return {"shield": 0.5, "health": 1.0}

# 실행: record a stackable global terrain debuff caused by purple energy.
static func _terrain_debuff_stack_count(sim: CombatSimulator) -> int:
	var stacks := 0
	for debuff in sim.terrain_debuffs:
		if debuff is Dictionary and str(debuff.get("effect", "")) == PURPLE_WEAKENED_EFFECT:
			stacks += maxi(1, int(debuff.get("stacks", 1)))
	return stacks

static func _terrain_buff_stack_count(sim: CombatSimulator) -> int:
	var stacks := 0
	for buff in sim.terrain_buffs:
		if buff is Dictionary and str(buff.get("effect", "")) == PURPLE_FORTIFIED_EFFECT:
			stacks += maxi(1, int(buff.get("stacks", 1)))
	return stacks

static func _apply_terrain_debuff(sim: CombatSimulator, target_cell_id: String, energy_color: String) -> void:
	for debuff in sim.terrain_debuffs:
		if str(debuff.get("scope", "")) == "global" and str(debuff.get("effect", "")) == PURPLE_WEAKENED_EFFECT:
			debuff["stacks"] = int(debuff.get("stacks", 1)) + 1
			return
	sim.terrain_debuffs.append({"scope": "global", "lastCellId": target_cell_id, "effect": PURPLE_WEAKENED_EFFECT, "energy": energy_color, "stacks": 1})

static func _apply_purple_terrain_shift(sim: CombatSimulator, target_cell_id: String, energy_color: String) -> void:
	if _consume_global_terrain_modifier_stack(sim.terrain_buffs, PURPLE_FORTIFIED_EFFECT):
		return
	_apply_terrain_debuff(sim, target_cell_id, energy_color)

static func _apply_terrain_buff(sim: CombatSimulator, effect_name: String, energy_color: String) -> void:
	for buff in sim.terrain_buffs:
		if str(buff.get("scope", "")) == "global" and str(buff.get("effect", "")) == effect_name:
			buff["stacks"] = int(buff.get("stacks", 1)) + 1
			return
	sim.terrain_buffs.append({"scope": "global", "effect": effect_name, "energy": energy_color, "stacks": 1})

static func _consume_global_terrain_modifier_stack(modifiers: Array, effect_name: String) -> bool:
	for modifier in modifiers:
		if not modifier is Dictionary:
			continue
		if str(modifier.get("scope", "")) != "global":
			continue
		if str(modifier.get("effect", "")) != effect_name:
			continue
		var stacks := maxi(0, int(modifier.get("stacks", 1)) - 1)
		if stacks <= 0:
			modifiers.erase(modifier)
		else:
			modifier["stacks"] = stacks
		return true
	return false

# 실행: apply repair intent to fully reload the energy queue and reset pin/empty-shot states.
static func apply_repair(sim: CombatSimulator) -> void:
	sim.queue.clear()
	sim.queue_pinned_slots = 0
	sim.queue_empty_shots = 0
	sim.pin_active = false
	sim.pin_turns_remaining = 0
	sim.aim_cell_id = null
	sim.aim_target_color = null
	sim.repair_progress = 100
	sim.repair_active = true
	sim.repair_available = false
	sim.disabled = false
	sim.result = "empty_queue"
	sim.aim_can_fire = false
	sim.paused_obstacle_ticks = maxi(sim.paused_obstacle_ticks, 6)

# 실행: update elapsed ticks, progress inventory energy generation, and run obstacle pressure/timer reducers.
static func tick_combat(sim: CombatSimulator, ticks: int, inventory: InventoryModel = null) -> void:
	if sim.disabled:
		return
	for _step in range(maxi(0, ticks)):
		if sim.disabled:
			return
		sim.elapsed_ticks += 1
		if sim.repair_active:
			sim.repair_progress = maxi(0, sim.repair_progress - 1)
			if sim.repair_progress <= 0:
				sim.repair_active = false
				sim.repair_available = true
				sim.aim_can_fire = true
				sim.result = "active"
				_on_repair_end(sim, inventory)

		_tick_obstacles(sim)
		_update_pin_progress(sim)

		if sim.pin_active:
			sim.pin_active = false
			sim.queue_pinned_slots = 0

		if elapsed_ticks_check(sim):
			return

		if inventory != null and not _skip_inventory_tick_due_to_blue(sim):
			for generated in inventory.tick():
				if sim.queue.size() < sim.queue_capacity:
					sim.queue.append(_normalize_queue_item(generated))

# 실행: check time limits cleanly.
static func elapsed_ticks_check(sim: CombatSimulator) -> bool:
	if sim.elapsed_ticks >= sim.time_limit_ticks:
		sim.result = "time_over"
		sim.disabled = true
		sim.aim_can_fire = false
		return true
	return false

# 실행: resolve obstacle failures for every obstacle whose host tile exits the battlefield.
static func resolve_obstacle_shift_exit(sim: CombatSimulator, exiting_obstacle_ids: Array, inventory: InventoryModel = null) -> void:
	if exiting_obstacle_ids.is_empty():
		return
	var exiting := {}
	for obstacle_id in exiting_obstacle_ids:
		exiting[str(obstacle_id)] = true
	var survivors: Array = []
	for obstacle in sim.obstacles:
		if not obstacle is Dictionary:
			continue
		if exiting.has(str(obstacle.get("id", ""))):
			if not _before_obstacle_execute(sim, obstacle, inventory):
				_resolve_obstacle_fail(sim, obstacle)
		else:
			survivors.append(obstacle)
	sim.obstacles = survivors
	_recalculate_purple_damage_reduction(sim)

# 실행: shift weakness markers and obstacle host cells together, then spawn the next obstacle wave.
static func shift_battlefield(sim: CombatSimulator, seed_val: int, colors: Array, shift_step: int, stage_index: int, hazard_modifier: float = 1.0, inventory: InventoryModel = null) -> void:
	var exiting_ids: Array = []
	for obstacle in sim.obstacles:
		if not obstacle is Dictionary:
			continue
		var state := str(obstacle.get("state", "active"))
		if _is_afterglow_state(state):
			continue
		if _cell_column(str(obstacle.get("cellId", ""))) >= sim.battlefield_cols - 1:
			exiting_ids.append(str(obstacle.get("id", "")))
	resolve_obstacle_shift_exit(sim, exiting_ids, inventory)
	_shift_obstacles_forward(sim)

	var shift_result: Dictionary = ShiftWeaknessMarkersScript.shift(sim.weakness_markers, sim.battlefield_rows, sim.battlefield_cols, seed_val, colors, shift_step)
	sim.weakness_markers = shift_result.get("markers", [])
	sim.obstacle_shift_count += 1
	_spawn_shift_wave_from_new_tiles(sim, stage_index, seed_val, shift_step, hazard_modifier, inventory)
	_recalculate_purple_damage_reduction(sim)

# 실행: seed the first obstacle wave for a fresh combat without advancing the battlefield itself.
static func prime_obstacles(sim: CombatSimulator, seed_val: int, stage_index: int, hazard_modifier: float = 1.0, inventory: InventoryModel = null) -> void:
	_spawn_initial_wave_from_new_tiles(sim, stage_index, seed_val, hazard_modifier, inventory)
	_recalculate_purple_damage_reduction(sim)

# 실행: tick purple live-pressure pulses and clear resolved afterglow shells.
static func _tick_obstacles(sim: CombatSimulator) -> void:
	var live_ticks_paused := sim.paused_obstacle_ticks > 0
	if live_ticks_paused:
		sim.paused_obstacle_ticks -= 1

	var next_obstacles: Array = []
	for obstacle in sim.obstacles:
		if not obstacle is Dictionary:
			continue
		var state := str(obstacle.get("state", "active"))
		if state == "warning":
			obstacle["state"] = "active"
			state = "active"
		if _is_afterglow_state(state):
			obstacle["afterglowTicksRemaining"] = maxi(0, int(obstacle.get("afterglowTicksRemaining", 0)) - 1)
			if int(obstacle.get("afterglowTicksRemaining", 0)) > 0:
				next_obstacles.append(obstacle)
			continue

		if live_ticks_paused:
			next_obstacles.append(obstacle)
			continue

		next_obstacles.append(obstacle)

	sim.obstacles = next_obstacles
	_recalculate_purple_damage_reduction(sim)

# 실행: update the visible pin progress buckets from the latest remaining combat time.
static func _update_pin_progress(sim: CombatSimulator) -> void:
	var seconds_remaining = float(sim.time_limit_ticks - sim.elapsed_ticks) / 20.0
	if seconds_remaining >= 70.0:
		sim.pin_progress = 100
	elif seconds_remaining >= 50.0:
		sim.pin_progress = 75
	elif seconds_remaining >= 30.0:
		sim.pin_progress = 50
	elif seconds_remaining >= 10.0:
		sim.pin_progress = 25
	elif seconds_remaining > 0.0:
		sim.pin_progress = 10
	else:
		sim.pin_progress = 0
	sim.pin_turns_remaining = sim.pin_progress

# 실행: apply obstacle clear progress when a shot lands on a live hazard cell.
static func _apply_obstacle_hit(sim: CombatSimulator, target_cell_id: String, energy_color: String, inventory: InventoryModel = null, source_artifact_id: String = "", source_drill: Artifact = null) -> void:
	var clear_immediately := {}
	for obstacle in sim.obstacles:
		if not obstacle is Dictionary:
			continue
		var state := str(obstacle.get("state", "active"))
		if _is_afterglow_state(state):
			continue
		if str(obstacle.get("cellId", "")) != target_cell_id:
			continue
		var required_color := str(obstacle.get("requiredColor", obstacle.get("family", "")))
		var progress_delta := 2 if energy_color == required_color else 1
		for relic in _linked_relics_for_artifact(inventory, source_drill, "obstacle_progress_bonus"):
			if _consume_once(sim, relic.id):
				progress_delta += int(relic.effect_schema.get("value", 1))
		obstacle["progress"] = int(obstacle.get("progress", 0)) + progress_delta
		if int(obstacle.get("progress", 0)) >= int(obstacle.get("clearProgress", 2)):
			_resolve_obstacle_clear(obstacle)
			_after_obstacle_clear(sim, obstacle, inventory, source_artifact_id, energy_color, source_drill)
			if bool(obstacle.get("clearImmediately", false)):
				clear_immediately[str(obstacle.get("id", ""))] = true
	if not clear_immediately.is_empty():
		var survivors: Array = []
		for obstacle in sim.obstacles:
			if not clear_immediately.has(str(obstacle.get("id", ""))):
				survivors.append(obstacle)
		sim.obstacles = survivors
	_recalculate_purple_damage_reduction(sim)

# 실행: convert a cleared obstacle into an optional short visual afterglow shell.
static func _resolve_obstacle_clear(obstacle: Dictionary) -> void:
	obstacle["progress"] = int(obstacle.get("clearProgress", 2))
	obstacle["state"] = "afterglow_clear"
	obstacle["afterglowTicksRemaining"] = maxi(0, int(obstacle.get("afterglowTicks", OBSTACLE_AFTERGLOW_TICKS)))

# 실행: apply the family-specific fail consequence when an uncleared obstacle leaves the screen.
static func _resolve_obstacle_fail(sim: CombatSimulator, obstacle: Dictionary) -> void:
	var family := str(obstacle.get("family", ""))
	match family:
		"red":
			sim.time_limit_ticks = maxi(sim.elapsed_ticks + 20, sim.time_limit_ticks - int(obstacle.get("timeCutTicks", 200)))
		"green":
			sim.health = minf(sim.max_health, sim.health + float(obstacle.get("healAmount", 1.0)))
		"purple":
			_apply_purple_pressure_pulse(sim)
		_:
			pass
	if sim.obstacle_miss_debt.has(family):
		sim.obstacle_miss_debt[family] = int(sim.obstacle_miss_debt.get(family, 0)) + 1
	elapsed_ticks_check(sim)

# 실행: remove one weakened-terrain stack, or refresh purple damage reduction when nothing is left to cleanse.
static func _apply_purple_pressure_pulse(sim: CombatSimulator) -> void:
	if _consume_global_terrain_modifier_stack(sim.terrain_debuffs, PURPLE_WEAKENED_EFFECT):
		return
	_apply_terrain_buff(sim, PURPLE_FORTIFIED_EFFECT, "purple")

# 실행: derive the active purple damage-reduction ratio from live purple obstacles.
static func _recalculate_purple_damage_reduction(sim: CombatSimulator) -> void:
	sim.purple_damage_reduction_ratio = 0.0

# 실행: skip some inventory cooldown ticks while frozen blue obstacles remain on the battlefield.
static func _skip_inventory_tick_due_to_blue(sim: CombatSimulator) -> bool:
	var blue_count := 0
	for obstacle in sim.obstacles:
		if not obstacle is Dictionary:
			continue
		if str(obstacle.get("family", "")) != "blue":
			continue
		if _is_afterglow_state(str(obstacle.get("state", "active"))):
			continue
		if bool(obstacle.get("ignoreBlueTax", false)):
			continue
		blue_count += 1
	if blue_count <= 0:
		return false
	var cadence := maxi(2, 5 - blue_count)
	return sim.elapsed_ticks % cadence == 0

# 실행: move every surviving obstacle one battlefield column toward the exit.
static func _shift_obstacles_forward(sim: CombatSimulator) -> void:
	var shifted: Array = []
	for obstacle in sim.obstacles:
		if not obstacle is Dictionary:
			continue
		var next_cell := _shift_cell_right(str(obstacle.get("cellId", "")), sim.battlefield_cols)
		if next_cell.is_empty():
			continue
		obstacle["cellId"] = next_cell
		shifted.append(obstacle)
	sim.obstacles = shifted

# 실행: roll and materialize one shift wave of new-tile-only obstacles from the current hazard profile.
static func _spawn_shift_wave_from_new_tiles(sim: CombatSimulator, stage_index: int, seed_val: int, shift_step: int, hazard_modifier: float, inventory: InventoryModel = null) -> void:
	var requests := SpawnNewTileObstaclesScript.roll_shift_wave(sim, seed_val, shift_step, hazard_modifier)
	_materialize_spawn_requests(sim, requests, stage_index, inventory)

# 실행: roll and materialize one initial-board obstacle seeding pass from the current hazard profile.
static func _spawn_initial_wave_from_new_tiles(sim: CombatSimulator, stage_index: int, seed_val: int, hazard_modifier: float, inventory: InventoryModel = null) -> void:
	var requests := SpawnNewTileObstaclesScript.roll_initial_wave(sim, seed_val, hazard_modifier)
	_materialize_spawn_requests(sim, requests, stage_index, inventory)

# 실행: convert spawn requests into full obstacle dictionaries and apply activation-time relic guards.
static func _materialize_spawn_requests(sim: CombatSimulator, requests: Array, stage_index: int, inventory: InventoryModel = null) -> void:
	var ordinal := 0
	for request in requests:
		if not request is Dictionary:
			continue
		var obstacle := _build_obstacle_definition(sim, str(request.get("family", "")), str(request.get("cellId", "")), stage_index, ordinal)
		_maybe_protect_blue_activation(sim, obstacle, inventory)
		sim.obstacles.append(obstacle)
		ordinal += 1

# 실행: keep the active obstacle count near the stage target and spend any miss-debt/backlog pressure on the next waves.
static func _spawn_obstacles_to_target(sim: CombatSimulator, stage_index: int, seed_val: int, shift_step: int, hazard_modifier: float, inventory: InventoryModel = null) -> void:
	var target_active := _target_active_obstacle_count(stage_index, hazard_modifier)
	var current_active := _uncleared_obstacle_count(sim)
	var family_order := _spawn_family_order(sim, seed_val, shift_step)
	var family_index := 0
	while family_index < family_order.size():
		var family: String = str(family_order[family_index])
		var request := 0
		if current_active < target_active:
			request += 1
		request += int(sim.obstacle_miss_debt.get(family, 0))
		request += int(sim.obstacle_spawn_backlog.get(family, 0))
		if request <= 0:
			family_index += 1
			continue

		sim.obstacle_miss_debt[family] = 0
		sim.obstacle_spawn_backlog[family] = 0
		var spawned := _spawn_family_obstacles(sim, family, request, stage_index, seed_val, shift_step, inventory)
		current_active += spawned
		if spawned < request:
			sim.obstacle_spawn_backlog[family] = request - spawned
		if current_active >= target_active and _total_spawn_pressure(sim) <= 0:
			break
		family_index += 1

# 실행: choose a deterministic family order that prioritizes the most urgent miss-debt or backlog.
static func _spawn_family_order(sim: CombatSimulator, seed_val: int, shift_step: int) -> Array:
	var weighted: Array = []
	var available_families := _spawnable_families(sim)
	var family_count := maxi(1, available_families.size())
	var rotation_start := posmod(seed_val + sim.obstacle_shift_count, family_count)
	for family in available_families:
		var family_index := available_families.find(family)
		weighted.append({
			"family": family,
			"pressure": int(sim.obstacle_miss_debt.get(family, 0)) + int(sim.obstacle_spawn_backlog.get(family, 0)),
			"order": posmod(family_index - rotation_start, family_count)
		})
	weighted.sort_custom(func(a, b):
		if int(a["pressure"]) == int(b["pressure"]):
			return int(a["order"]) < int(b["order"])
		return int(a["pressure"]) > int(b["pressure"])
	)
	var result: Array = []
	for entry in weighted:
		result.append(str(entry["family"]))
	return result

# 실행: spawn up to the requested number of same-family obstacles onto eligible cells with a minimum immediate-reaction window.
static func _spawn_family_obstacles(sim: CombatSimulator, family: String, request: int, stage_index: int, seed_val: int, shift_step: int, inventory: InventoryModel = null) -> int:
	if request <= 0:
		return 0
	var candidates := _eligible_spawn_cell_ids(sim, family)
	if candidates.is_empty():
		return 0

	var offset := posmod(seed_val + shift_step * 5 + OBSTACLE_FAMILIES.find(family) * 11, candidates.size())
	var spawned := 0
	for index in range(candidates.size()):
		if spawned >= request:
			break
		var cell_id := str(candidates[(offset + index) % candidates.size()])
		var obstacle := _build_obstacle_definition(sim, family, cell_id, stage_index, spawned)
		_maybe_protect_blue_activation(sim, obstacle, inventory)
		sim.obstacles.append(obstacle)
		spawned += 1
	return spawned

# 실행: build one obstacle snapshot with stage-scaled family pressure numbers.
static func _build_obstacle_definition(sim: CombatSimulator, family: String, cell_id: String, stage_index: int, ordinal: int) -> Dictionary:
	var config := _obstacle_config_for_stage(sim, family, stage_index)
	return {
		"id": "obs_%s_%d_%d" % [family, sim.obstacle_shift_count, ordinal],
		"family": family,
		"requiredColor": family,
		"cellId": cell_id,
		"state": "active",
		"progress": 0,
		"clearProgress": int(config.get("clearProgress", 2)),
		"afterglowTicks": int(config.get("afterglowTicks", OBSTACLE_AFTERGLOW_TICKS)),
		"afterglowTicksRemaining": 0,
		"timeCutTicks": int(config.get("timeCutTicks", 200)),
		"healAmount": float(config.get("healAmount", 1.0)),
		"pulseIntervalTicks": int(config.get("pulseIntervalTicks", 20)),
		"pulseTicksRemaining": int(config.get("pulseIntervalTicks", 20)),
		"visual": {
			"family": family,
			"pattern": "single_cell"
		}
	}

# 실행: return the stage-scaled obstacle numbers for one family.
static func _obstacle_config_for_stage(sim: CombatSimulator, family: String, stage_index: int) -> Dictionary:
	var stage_band := 0
	if stage_index >= 8:
		stage_band = 3
	elif stage_index >= 6:
		stage_band = 2
	elif stage_index >= 2:
		stage_band = 1
	var clear_progress := 2
	if stage_index >= 4:
		clear_progress = 3
	if stage_index >= 8:
		clear_progress = 4
	match family:
		"red":
			var time_cuts := [200, 260, 340, 400]
			return {
				"clearProgress": clear_progress,
				"afterglowTicks": OBSTACLE_AFTERGLOW_TICKS,
				"timeCutTicks": time_cuts[stage_band]
			}
		"blue":
			return {
				"clearProgress": clear_progress,
				"afterglowTicks": OBSTACLE_AFTERGLOW_TICKS
			}
		"purple":
			var pulse_intervals := [24, 20, 18, 16]
			return {
				"clearProgress": clear_progress,
				"afterglowTicks": OBSTACLE_AFTERGLOW_TICKS,
				"pulseIntervalTicks": pulse_intervals[stage_band]
			}
		"green":
			var heal_percents := [0.03, 0.05, 0.07, 0.08]
			return {
				"clearProgress": clear_progress,
				"afterglowTicks": OBSTACLE_AFTERGLOW_TICKS,
				"healAmount": maxf(1.0, sim.max_health * heal_percents[stage_band])
			}
	return {
		"clearProgress": clear_progress,
		"afterglowTicks": OBSTACLE_AFTERGLOW_TICKS
	}

# 실행: keep new obstacle spawns away from cells that are about to exit or still carrying same-family afterglow.
static func _eligible_spawn_cell_ids(sim: CombatSimulator, family: String) -> Array:
	var min_shift_distance := OBSTACLE_MIN_REACTION_COLUMNS
	var blocked_afterglow := {}
	var occupied_cells := {}
	for obstacle in sim.obstacles:
		if not obstacle is Dictionary:
			continue
		var state := str(obstacle.get("state", "active"))
		var cell_id := str(obstacle.get("cellId", ""))
		if _is_afterglow_state(state) and str(obstacle.get("family", "")) == family:
			blocked_afterglow[cell_id] = true
		elif not _is_afterglow_state(state):
			occupied_cells[cell_id] = true

	var cells: Array = []
	for row in range(sim.battlefield_rows):
		for column in range(sim.battlefield_cols):
			if (sim.battlefield_cols - 1 - column) <= min_shift_distance:
				continue
			var cell_id := "r%dc%d" % [row, column]
			if blocked_afterglow.has(cell_id):
				continue
			if occupied_cells.has(cell_id):
				continue
			cells.append(cell_id)
	return cells

# 실행: compute the desired active obstacle pressure for the current stage and node hazard modifier.
static func _target_active_obstacle_count(stage_index: int, hazard_modifier: float) -> int:
	var target := 1
	if stage_index >= 8:
		target = 3
	elif stage_index >= 4:
		target = 2
	if hazard_modifier >= 1.4:
		target += 1
	elif hazard_modifier <= 0.7:
		target = maxi(1, target - 1)
	return target

# 실행: count only live pressure obstacles, excluding afterglow shells.
static func _uncleared_obstacle_count(sim: CombatSimulator) -> int:
	var count := 0
	for obstacle in sim.obstacles:
		if not obstacle is Dictionary:
			continue
		if not _is_afterglow_state(str(obstacle.get("state", "active"))):
			count += 1
	return count

# 실행: count live obstacles for a specific family, excluding only resolved afterglow shells.
static func _active_obstacle_count(sim: CombatSimulator, family: String) -> int:
	var count := 0
	for obstacle in sim.obstacles:
		if not obstacle is Dictionary:
			continue
		if str(obstacle.get("family", "")) != family:
			continue
		if _is_afterglow_state(str(obstacle.get("state", "active"))):
			continue
		count += 1
	return count

# 실행: sum the remaining backlog and miss-debt still waiting to be spent on future spawns.
static func _total_spawn_pressure(sim: CombatSimulator) -> int:
	var total := 0
	for family in _spawnable_families(sim):
		total += int(sim.obstacle_miss_debt.get(family, 0))
		total += int(sim.obstacle_spawn_backlog.get(family, 0))
	return total

static func _spawnable_families(sim: CombatSimulator) -> Array:
	if sim != null and not sim.obstacle_allowed_families.is_empty():
		return sim.obstacle_allowed_families.duplicate(true)
	return OBSTACLE_FAMILIES.duplicate(true)

# 실행: treat both clear and fail afterglow shells as resolved overlays.
static func _is_afterglow_state(state: String) -> bool:
	return state.begins_with("afterglow")

# 실행: extract the energy color from either a legacy string queue item or a structured queue token.
static func _queue_item_color(item: Variant) -> String:
	if item is Dictionary:
		return str(item.get("color", item.get("energy", "")))
	return str(item)

# 실행: extract the source artifact identifier from a structured queue token when present.
static func _queue_item_source_artifact_id(item: Variant) -> String:
	if item is Dictionary:
		return str(item.get("source_artifact_id", ""))
	return ""

# 실행: normalize generated queue items so combat always sees the same token shape.
static func _normalize_queue_item(item: Variant) -> Dictionary:
	if item is Dictionary:
		var token: Dictionary = item.duplicate(true)
		token["color"] = str(token.get("color", token.get("energy", "")))
		token["source_artifact_id"] = str(token.get("source_artifact_id", ""))
		token["source_item_type"] = str(token.get("source_item_type", token.get("item_type", "drill")))
		return token
	return {
		"color": str(item),
		"source_artifact_id": "",
		"source_item_type": "drill"
	}

# 실행: resolve the drill that produced the current queue item, falling back to the first matching-color drill.
static func _find_source_drill(inventory: InventoryModel, source_artifact_id: String, energy_color: String) -> Artifact:
	if inventory == null:
		return null
	if not source_artifact_id.is_empty() and inventory.artifacts.has(source_artifact_id):
		var exact = inventory.artifacts[source_artifact_id]
		if exact is Artifact and exact.item_type == "drill":
			return exact
	for art_id in inventory.artifacts:
		var art = inventory.artifacts[art_id]
		if art.energy_type == energy_color and art.item_type == "drill":
			return art
	return null

# 실행: parse the zero-based column index from a battlefield cell id like r1c7.
static func _cell_column(cell_id: String) -> int:
	var c_index := cell_id.find("c")
	if c_index == -1 or c_index >= cell_id.length() - 1:
		return -1
	var column_text := cell_id.substr(c_index + 1, cell_id.length() - c_index - 1)
	return int(column_text) if column_text.is_valid_int() else -1

# 실행: shift a cell id one column toward the right edge, returning an empty string when it would leave the board.
static func _shift_cell_right(cell_id: String, max_columns: int) -> String:
	var column := _cell_column(cell_id)
	if column < 0:
		return ""
	var row_text := cell_id.substr(1, cell_id.find("c") - 1)
	if not row_text.is_valid_int():
		return ""
	var next_column := column + 1
	if next_column >= max_columns:
		return ""
	return "r%dc%d" % [int(row_text), next_column]

static func _on_repair_end(sim: CombatSimulator, inventory: InventoryModel) -> void:
	for relic in _relics_with_type(inventory, "next_two_shots_boost"):
		var charges := maxi(1, int(relic.effect_schema.get("value", 2)))
		var damage_multiplier := maxf(1.1, float(relic.effect_schema.get("damage_multiplier", 1.5)))
		for linked_artifact in inventory.get_relic_linked_artifacts(relic):
			if linked_artifact is Artifact and linked_artifact.item_type == "drill":
				_grant_shot_buff(sim, linked_artifact.id, charges, damage_multiplier)

static func _maybe_protect_blue_activation(sim: CombatSimulator, obstacle: Dictionary, inventory: InventoryModel) -> void:
	if str(obstacle.get("family", "")) != "blue":
		return
	for relic in _relics_with_type(inventory, "ignore_first_blue_obstacle"):
		if not _consume_once(sim, relic.id):
			continue
		obstacle["ignoreBlueTax"] = true
		obstacle["ignoreExecute"] = true
		obstacle["ignoredByRelicId"] = relic.id
		return

static func _before_obstacle_execute(sim: CombatSimulator, obstacle: Dictionary, inventory: InventoryModel) -> bool:
	if bool(obstacle.get("ignoreExecute", false)):
		return true
	for relic in _relics_with_type(inventory, "prevent_first_execute"):
		if _consume_once(sim, relic.id):
			return true
	return false

static func _after_obstacle_clear(sim: CombatSimulator, obstacle: Dictionary, inventory: InventoryModel, source_artifact_id: String, energy_color: String, source_drill: Artifact = null) -> void:
	for relic in _relics_with_type(inventory, "clear_add_time"):
		sim.time_limit_ticks += int(relic.effect_schema.get("value", 20))

	for relic in _relics_with_type(inventory, "clear_skip_afterglow"):
		if not _consume_once(sim, relic.id):
			continue
		obstacle["afterglowTicksRemaining"] = 0
		obstacle["clearImmediately"] = true
		break

	for relic in _relics_with_type(inventory, "clear_paint_cell"):
		_paint_weakness_cell(sim, str(obstacle.get("cellId", "")), energy_color)
		var refund := maxi(0, int(relic.effect_schema.get("value", 0)))
		if refund > 0 and source_drill != null:
			source_drill.current_cooldown = clampi(int(source_drill.current_cooldown) - refund, 0, maxi(1, int(source_drill.base_cooldown_ticks) - int(source_drill.synergy_cooldown_reduction)))

	for relic in _relics_with_type(inventory, "clear_refund_cooldown"):
		_refund_all_drill_cooldowns(inventory, maxi(0, int(relic.effect_schema.get("value", 4))))

	for relic in _relics_with_type(inventory, "first_clear_refund_queue"):
		if not _consume_once(sim, relic.id):
			continue
		if sim.queue.size() < sim.queue_capacity:
			sim.queue.append(_queue_token(energy_color, source_artifact_id))
			if sim.repair_active:
				sim.repair_active = false
				sim.repair_available = true
				sim.aim_can_fire = true
				sim.result = "active"
		break

static func _after_weakness_hit(sim: CombatSimulator, inventory: InventoryModel, _target_color: String, _energy_color: String) -> void:
	for relic in _relics_with_type(inventory, "globalize_weakness_every_five_hits"):
		var threshold := maxi(1, int(relic.effect_schema.get("threshold", 5)))
		var hit_count := _increment_relic_counter(sim, relic.id, 1)
		if hit_count < threshold:
			continue
		_set_relic_counter(sim, relic.id, hit_count - threshold)
		for marker in sim.weakness_markers:
			if marker is Dictionary:
				marker["allEnergyWeakness"] = true

static func _weakness_marker_for_cell(markers: Array, cell_id: String) -> Dictionary:
	for marker in markers:
		if marker is Dictionary and str(marker.get("cellId", "")) == cell_id:
			return marker
	return {}

static func _clear_all_energy_weakness_flags(markers: Array) -> void:
	for marker in markers:
		if marker is Dictionary and marker.has("allEnergyWeakness"):
			marker.erase("allEnergyWeakness")

static func _paint_weakness_cell(sim: CombatSimulator, cell_id: String, color: String) -> void:
	for marker in sim.weakness_markers:
		if marker is Dictionary and str(marker.get("cellId", "")) == cell_id:
			marker["color"] = color
			return

static func _refund_all_drill_cooldowns(inventory: InventoryModel, amount: int) -> void:
	if inventory == null or amount <= 0:
		return
	for art_id in inventory.artifacts:
		var art = inventory.artifacts[art_id]
		if not (art is Artifact) or art.item_type != "drill":
			continue
		var effective_cooldown := maxi(1, int(art.base_cooldown_ticks) - int(art.synergy_cooldown_reduction))
		art.current_cooldown = clampi(int(art.current_cooldown) - amount, 0, effective_cooldown)
