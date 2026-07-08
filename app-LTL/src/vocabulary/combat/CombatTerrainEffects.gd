# 怨꾩빟:
# - Responsibility: own terrain and purple-energy combat modifiers.
# - Input: CombatSimulator terrain modifier arrays and energy color identifiers.
# - Output: Mutated terrain buff/debuff state or deterministic damage profile dictionaries.
# - Forbidden: queue mutation, relic runtime mutation, obstacle spawn policy, or UI access.
#
# ?ㅽ뻾: define the combat terrain effect helper.
class_name CombatTerrainEffects
extends RefCounted

const PURPLE_WEAKENED_EFFECT := "weakened_terrain"
const PURPLE_FORTIFIED_EFFECT := "fortified_terrain"

static func energy_profile(energy_color: String) -> Dictionary:
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

static func terrain_debuff_stack_count(sim: CombatSimulator) -> int:
	var stacks := 0
	for debuff in sim.terrain_debuffs:
		if debuff is Dictionary and str(debuff.get("effect", "")) == PURPLE_WEAKENED_EFFECT:
			stacks += maxi(1, int(debuff.get("stacks", 1)))
	return stacks

static func terrain_buff_stack_count(sim: CombatSimulator) -> int:
	var stacks := 0
	for buff in sim.terrain_buffs:
		if buff is Dictionary and str(buff.get("effect", "")) == PURPLE_FORTIFIED_EFFECT:
			stacks += maxi(1, int(buff.get("stacks", 1)))
	return stacks

static func apply_purple_terrain_shift(sim: CombatSimulator, target_cell_id: String, energy_color: String) -> void:
	if _consume_global_terrain_modifier_stack(sim.terrain_buffs, PURPLE_FORTIFIED_EFFECT):
		return
	_apply_terrain_debuff(sim, target_cell_id, energy_color)

static func apply_purple_pressure_pulse(sim: CombatSimulator) -> void:
	if _consume_global_terrain_modifier_stack(sim.terrain_debuffs, PURPLE_WEAKENED_EFFECT):
		return
	_apply_terrain_buff(sim, PURPLE_FORTIFIED_EFFECT, "purple")

static func recalculate_purple_damage_reduction(sim: CombatSimulator) -> void:
	sim.purple_damage_reduction_ratio = 0.0

static func _apply_terrain_debuff(sim: CombatSimulator, target_cell_id: String, energy_color: String) -> void:
	for debuff in sim.terrain_debuffs:
		if str(debuff.get("scope", "")) == "global" and str(debuff.get("effect", "")) == PURPLE_WEAKENED_EFFECT:
			debuff["stacks"] = int(debuff.get("stacks", 1)) + 1
			return
	sim.terrain_debuffs.append({"scope": "global", "lastCellId": target_cell_id, "effect": PURPLE_WEAKENED_EFFECT, "energy": energy_color, "stacks": 1})

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
