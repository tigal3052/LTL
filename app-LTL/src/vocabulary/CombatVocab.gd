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
const CombatRelicHooksScript = preload("res://src/vocabulary/combat/CombatRelicHooks.gd")
const CombatTerrainEffectsScript = preload("res://src/vocabulary/combat/CombatTerrainEffects.gd")
const CombatObstacleDefinitionsScript = preload("res://src/vocabulary/combat/CombatObstacleDefinitions.gd")
const CombatObstacleFeedbackScript = preload("res://src/vocabulary/combat/CombatObstacleFeedback.gd")
const EnergyTokenScript = preload("res://src/vocabulary/combat/EnergyToken.gd")

const OBSTACLE_AFTERGLOW_TICKS := 12

# 실행: prepare a new combat simulator instance.
static func prepare_combat(choice: Dictionary, tuning: Dictionary, queue_capacity: int) -> CombatSimulator:
	return CombatSimulator.new(choice, tuning, queue_capacity)

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

	var profile := CombatTerrainEffectsScript.energy_profile(energy_color)
	var base_shield := float(profile.get("shield", 0.5))
	var base_hp := float(profile.get("health", 1.0))
	var pierces_health := bool(profile.get("pierceHealth", false))
	var applies_terrain_debuff := bool(profile.get("terrainDebuff", false))
	var fortified_stacks := CombatTerrainEffectsScript.terrain_buff_stack_count(sim)
	if energy_color == "purple":
		var stack_bonus := float(CombatTerrainEffectsScript.terrain_debuff_stack_count(sim)) * 0.20
		base_shield += stack_bonus
		base_hp += stack_bonus

	var damage_multiplier := EnergyTokenScript.damage_for_token(queue_item, source_drill)
	if not (queue_item is Dictionary) and source_drill != null:
		var inferred_source_id := source_artifact_id
		if inventory != null and inventory.has_method("artifact_key"):
			inferred_source_id = str(inventory.artifact_key(source_drill))
		var inferred_token := EnergyTokenScript.build_token(inventory, source_drill, inferred_source_id)
		damage_multiplier = EnergyTokenScript.damage_for_token(inferred_token, source_drill)
	damage_multiplier *= CombatRelicHooksScript.consume_shot_buff_multiplier(sim, source_artifact_id, source_drill)
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
		CombatTerrainEffectsScript.apply_purple_terrain_shift(sim, str(target_cell_id), energy_color)

	_apply_obstacle_hit(sim, resolved_target_cell_id, energy_color, inventory, source_artifact_id, source_drill)

	var pin_active := false
	if sim.health <= 0.0:
		sim.result = "clear"
	else:
		sim.result = hit_type
		if hit_type == "mismatch":
			pin_active = true
			if CombatRelicHooksScript.consume_linked_relic_once(sim, inventory, source_drill, "first_mismatch_cleanse"):
				pin_active = false
		elif hit_type == "match":
			CombatRelicHooksScript.after_weakness_hit(sim, inventory, resolved_target_color, energy_color)

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
				CombatRelicHooksScript.on_repair_end(sim, inventory)

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
	CombatObstacleFeedbackScript.clear(sim)
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
			if not CombatRelicHooksScript.before_obstacle_execute(sim, obstacle, inventory):
				_resolve_obstacle_fail(sim, obstacle)
		else:
			survivors.append(obstacle)
	sim.obstacles = survivors
	CombatTerrainEffectsScript.recalculate_purple_damage_reduction(sim)

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
	CombatTerrainEffectsScript.recalculate_purple_damage_reduction(sim)

# 실행: seed the first obstacle wave for a fresh combat without advancing the battlefield itself.
static func prime_obstacles(sim: CombatSimulator, seed_val: int, stage_index: int, hazard_modifier: float = 1.0, inventory: InventoryModel = null) -> void:
	_spawn_initial_wave_from_new_tiles(sim, stage_index, seed_val, hazard_modifier, inventory)
	CombatTerrainEffectsScript.recalculate_purple_damage_reduction(sim)

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
	CombatTerrainEffectsScript.recalculate_purple_damage_reduction(sim)

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
		var progress_delta := 1
		for relic in CombatRelicHooksScript.linked_relics_for_artifact(inventory, source_drill, "obstacle_progress_bonus"):
			if CombatRelicHooksScript.consume_once(sim, relic.id):
				progress_delta += int(relic.effect_schema.get("value", 1))
		obstacle["progress"] = int(obstacle.get("progress", 0)) + progress_delta
		if int(obstacle.get("progress", 0)) >= int(obstacle.get("clearProgress", 2)):
			_resolve_obstacle_clear(obstacle)
			CombatRelicHooksScript.after_obstacle_clear(sim, obstacle, inventory, source_artifact_id, energy_color, source_drill)
			if bool(obstacle.get("clearImmediately", false)):
				clear_immediately[str(obstacle.get("id", ""))] = true
	if not clear_immediately.is_empty():
		var survivors: Array = []
		for obstacle in sim.obstacles:
			if not clear_immediately.has(str(obstacle.get("id", ""))):
				survivors.append(obstacle)
		sim.obstacles = survivors
	CombatTerrainEffectsScript.recalculate_purple_damage_reduction(sim)

# 실행: convert a cleared obstacle into an optional short visual afterglow shell.
static func _resolve_obstacle_clear(obstacle: Dictionary) -> void:
	obstacle["progress"] = int(obstacle.get("clearProgress", 2))
	obstacle["state"] = "afterglow_clear"
	obstacle["afterglowTicksRemaining"] = maxi(0, int(obstacle.get("afterglowTicks", OBSTACLE_AFTERGLOW_TICKS)))

# 실행: apply the family-specific fail consequence when an uncleared obstacle leaves the screen.
static func _resolve_obstacle_fail(sim: CombatSimulator, obstacle: Dictionary) -> void:
	var family := str(obstacle.get("family", ""))
	var feedback_before := CombatObstacleFeedbackScript.snapshot(sim)
	match family:
		"red":
			sim.time_limit_ticks = maxi(sim.elapsed_ticks + 20, sim.time_limit_ticks - int(obstacle.get("timeCutTicks", 200)))
		"green":
			sim.health = minf(sim.max_health, sim.health + float(obstacle.get("healAmount", 1.0)))
		"purple":
			CombatTerrainEffectsScript.apply_purple_pressure_pulse(sim)
		_:
			pass
	if sim.obstacle_miss_debt.has(family):
		sim.obstacle_miss_debt[family] = int(sim.obstacle_miss_debt.get(family, 0)) + 1
	CombatObstacleFeedbackScript.record_failure(sim, obstacle, feedback_before)
	elapsed_ticks_check(sim)

# 실행: remove one weakened-terrain stack, or refresh purple damage reduction when nothing is left to cleanse.
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
		var obstacle := CombatObstacleDefinitionsScript.build(sim, str(request.get("family", "")), str(request.get("cellId", "")), stage_index, ordinal)
		CombatRelicHooksScript.maybe_protect_blue_activation(sim, obstacle, inventory)
		sim.obstacles.append(obstacle)
		ordinal += 1

# 실행: build one obstacle snapshot with stage-scaled family pressure numbers.
# 실행: return the stage-scaled obstacle numbers for one family.
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
	return EnergyTokenScript.source_id(item)

# 실행: normalize generated queue items so combat always sees the same token shape.
static func _normalize_queue_item(item: Variant) -> Dictionary:
	return EnergyTokenScript.normalize(item)

# 실행: resolve the drill that produced the current queue item, falling back to the first matching-color drill.
static func _find_source_drill(inventory: InventoryModel, source_artifact_id: String, energy_color: String) -> Artifact:
	if inventory == null:
		return null
	if not source_artifact_id.is_empty() and inventory.artifacts.has(source_artifact_id):
		var exact = inventory.artifacts[source_artifact_id]
		if exact is Artifact and exact.item_type == "drill":
			return exact
	if not source_artifact_id.is_empty():
		for art_id in inventory.artifacts:
			var exact_by_id = inventory.artifacts[art_id]
			if exact_by_id is Artifact and exact_by_id.item_type == "drill":
				if str(exact_by_id.id) == source_artifact_id or str(exact_by_id.instance_id) == source_artifact_id:
					return exact_by_id
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

static func _weakness_marker_for_cell(markers: Array, cell_id: String) -> Dictionary:
	for marker in markers:
		if marker is Dictionary and str(marker.get("cellId", "")) == cell_id:
			return marker
	return {}

static func _clear_all_energy_weakness_flags(markers: Array) -> void:
	for marker in markers:
		if marker is Dictionary and marker.has("allEnergyWeakness"):
			marker.erase("allEnergyWeakness")
