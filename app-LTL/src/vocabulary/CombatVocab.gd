# 계약:
# - 책임: 전투 시뮬레이터 상태에 대한 순수 동사 함수(전투 준비, 사격 판정, 수리 적용, 시간 경과)를 제공한다.
# - 입력: CombatSimulator 인스턴스, 타겟 색상, 타겟 셀 ID, 튜닝 Dictionary.
# - 출력: 상태가 갱신된 CombatSimulator 인스턴스 또는 결과 정보.
# - 금지: SceneTree 접근, 자체 상태 보존.
#
# 실행: define the CombatVocab static entry.
class_name CombatVocab
extends RefCounted

# 실행: prepare a new combat simulator instance.
static func prepare_combat(choice: Dictionary, tuning: Dictionary, queue_capacity: int) -> CombatSimulator:
	return CombatSimulator.new(choice, tuning, queue_capacity)

# 실행: fire a shot, consume energy from the queue, determine damage, and update health/shield.
static func fire_shot(sim: CombatSimulator, target_color: Variant, target_cell_id: Variant, tuning: Dictionary, inventory: InventoryModel = null) -> void:
	sim.summary_shots_fired += 1
	sim.aim_cell_id = target_cell_id
	sim.aim_target_color = target_color

	if sim.queue.is_empty():
		sim.result = "empty_queue"
		sim.summary_shots_fired_empty_queue += 1
		sim.queue_empty_shots += 1
		if not sim.repair_active:
			apply_repair(sim)
		return

	var energy_color := str(sim.queue.pop_front())
	if sim.queue.is_empty() and not sim.repair_active:
		apply_repair(sim)

	var profile := _energy_profile(energy_color)
	var base_shield := float(profile.get("shield", 0.5))
	var base_hp := float(profile.get("health", 1.0))
	var pierces_health := bool(profile.get("pierceHealth", false))
	var applies_terrain_debuff := bool(profile.get("terrainDebuff", false))

	var damage_multiplier := 1.0
	if inventory != null:
		for art_id in inventory.artifacts:
			var art = inventory.artifacts[art_id]
			if art.energy_type == energy_color and art.item_type == "drill":
				damage_multiplier = art.damage
				break
	base_shield *= damage_multiplier
	base_hp *= damage_multiplier

	var weakness_colors := []
	for marker in sim.weakness_markers:
		if not marker["color"] in weakness_colors:
			weakness_colors.append(marker["color"])
	var is_vulnerable_pulse := str(target_color) in weakness_colors

	var combat_tuning: Dictionary = tuning.get("combat", tuning)
	var dmg_bonus := float(combat_tuning.get("damage_bonus", 0.0))
	base_shield += dmg_bonus
	base_hp += dmg_bonus

	var dmg_shield := base_shield
	var dmg_hp := base_hp
	var hit_type := "normal"
	if is_vulnerable_pulse:
		if energy_color == str(target_color):
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
		_apply_terrain_debuff(sim, str(target_cell_id), energy_color)

	var pin_active := false
	if sim.health <= 0.0:
		sim.result = "clear"
	else:
		sim.result = hit_type
		if hit_type == "mismatch":
			pin_active = true

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
			return {"shield": 0.5, "health": 2.2}
		"blue":
			return {"shield": 3.0, "health": 0.45}
		"green":
			return {"shield": 0.25, "health": 1.0, "pierceHealth": true}
		"purple":
			return {"shield": 0.35, "health": 0.35, "terrainDebuff": true}
	return {"shield": 0.5, "health": 1.0}

# 실행: record a stackable terrain debuff caused by purple energy.
static func _apply_terrain_debuff(sim: CombatSimulator, target_cell_id: String, energy_color: String) -> void:
	if target_cell_id.is_empty():
		return
	for debuff in sim.terrain_debuffs:
		if str(debuff.get("cellId", "")) == target_cell_id and str(debuff.get("effect", "")) == "weakened_terrain":
			debuff["stacks"] = int(debuff.get("stacks", 1)) + 1
			return
	sim.terrain_debuffs.append({"cellId": target_cell_id, "effect": "weakened_terrain", "energy": energy_color, "stacks": 1})

# 실행: apply repair intent to fully reload the energy queue and reset pin/empty-shot states.
static func apply_repair(sim: CombatSimulator) -> void:
	sim.queue.clear()
	sim.queue_pinned_slots = 0
	sim.queue_empty_shots = 0
	sim.pin_active = false
	sim.pin_turns_remaining = 0
	sim.repair_progress = 100
	sim.repair_active = true
	sim.repair_available = false
	sim.disabled = false
	sim.result = "empty_queue"
	sim.aim_can_fire = false

# 실행: update elapsed ticks, progress inventory energy generation, and flag time_over if limits are exceeded.
static func tick_combat(sim: CombatSimulator, ticks: int, inventory: InventoryModel = null) -> void:
	if sim.disabled:
		return
	sim.elapsed_ticks += ticks
	if sim.repair_active:
		sim.repair_progress = maxi(0, sim.repair_progress - ticks)
		if sim.repair_progress <= 0:
			sim.repair_active = false
			sim.repair_available = true
			sim.aim_can_fire = true
			sim.result = "active"

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

	if sim.pin_active:
		sim.pin_active = false
		sim.queue_pinned_slots = 0

	if elapsed_ticks_check(sim):
		return

	if inventory != null:
		for _t in range(ticks):
			var generated_energies = inventory.tick()
			for energy in generated_energies:
				if sim.queue.size() < sim.queue_capacity:
					sim.queue.append(str(energy))

# 실행: check time limits cleanly.
static func elapsed_ticks_check(sim: CombatSimulator) -> bool:
	if sim.elapsed_ticks >= sim.time_limit_ticks:
		sim.result = "time_over"
		sim.disabled = true
		sim.aim_can_fire = false
		return true
	return false
