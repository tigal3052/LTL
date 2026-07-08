# 怨꾩빟:
# - Responsibility: apply combat relic side effects that hook into repair, obstacle execution,
#   obstacle clearing, weakness hits, and one-shot damage buffs.
# - Input: CombatSimulator, InventoryModel, Artifact, and obstacle dictionaries from CombatVocab.
# - Output: Mutated simulator, inventory artifacts, or obstacle state.
# - Forbidden: scene tree access, UI access, or battlefield spawn policy decisions.
#
# ?ㅽ뻾: define the combat relic hook helper.
class_name CombatRelicHooks
extends RefCounted

static func linked_relics_for_artifact(inventory: InventoryModel, artifact: Artifact, effect_type: String = "") -> Array:
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

static func consume_once(sim: CombatSimulator, relic_id: String) -> bool:
	var consumed := _runtime_bucket(sim, "consumed")
	if consumed.has(relic_id):
		return false
	consumed[relic_id] = true
	return true

static func consume_shot_buff_multiplier(sim: CombatSimulator, source_artifact_id: String, source_drill: Artifact = null) -> float:
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

static func consume_linked_relic_once(sim: CombatSimulator, inventory: InventoryModel, artifact: Artifact, effect_type: String) -> bool:
	for relic in linked_relics_for_artifact(inventory, artifact, effect_type):
		if consume_once(sim, relic.id):
			return true
	return false

static func on_repair_end(sim: CombatSimulator, inventory: InventoryModel) -> void:
	for relic in _relics_with_type(inventory, "next_two_shots_boost"):
		var charges := maxi(1, int(relic.effect_schema.get("value", 2)))
		var damage_multiplier := maxf(1.1, float(relic.effect_schema.get("damage_multiplier", 1.5)))
		for linked_artifact in inventory.get_relic_linked_artifacts(relic):
			if linked_artifact is Artifact and linked_artifact.item_type == "drill":
				_grant_shot_buff(sim, linked_artifact.id, charges, damage_multiplier)

static func maybe_protect_blue_activation(sim: CombatSimulator, obstacle: Dictionary, inventory: InventoryModel) -> void:
	if str(obstacle.get("family", "")) != "blue":
		return
	for relic in _relics_with_type(inventory, "ignore_first_blue_obstacle"):
		if not consume_once(sim, relic.id):
			continue
		obstacle["ignoreBlueTax"] = true
		obstacle["ignoreExecute"] = true
		obstacle["ignoredByRelicId"] = relic.id
		return

static func before_obstacle_execute(sim: CombatSimulator, obstacle: Dictionary, inventory: InventoryModel) -> bool:
	if bool(obstacle.get("ignoreExecute", false)):
		return true
	for relic in _relics_with_type(inventory, "prevent_first_execute"):
		if consume_once(sim, relic.id):
			return true
	return false

static func after_obstacle_clear(sim: CombatSimulator, obstacle: Dictionary, inventory: InventoryModel, source_artifact_id: String, energy_color: String, source_drill: Artifact = null) -> void:
	for relic in _relics_with_type(inventory, "clear_add_time"):
		sim.time_limit_ticks += int(relic.effect_schema.get("value", 20))

	for relic in _relics_with_type(inventory, "clear_skip_afterglow"):
		if not consume_once(sim, relic.id):
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
		if not consume_once(sim, relic.id):
			continue
		if sim.queue.size() < sim.queue_capacity:
			sim.queue.append(_queue_token(energy_color, source_artifact_id))
			if sim.repair_active:
				sim.repair_active = false
				sim.repair_available = true
				sim.aim_can_fire = true
				sim.result = "active"
		break

static func after_weakness_hit(sim: CombatSimulator, inventory: InventoryModel, _target_color: String, _energy_color: String) -> void:
	for relic in _relics_with_type(inventory, "globalize_weakness_every_five_hits"):
		var threshold := maxi(1, int(relic.effect_schema.get("threshold", 5)))
		var hit_count := _increment_relic_counter(sim, relic.id, 1)
		if hit_count < threshold:
			continue
		_set_relic_counter(sim, relic.id, hit_count - threshold)
		for marker in sim.weakness_markers:
			if marker is Dictionary:
				marker["allEnergyWeakness"] = true

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

static func _runtime_bucket(sim: CombatSimulator, key: String) -> Dictionary:
	if not sim.relic_runtime.has(key) or not (sim.relic_runtime.get(key) is Dictionary):
		sim.relic_runtime[key] = {}
	return sim.relic_runtime[key]

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

static func _queue_token(color: String, source_artifact_id: String) -> Dictionary:
	return {
		"color": color,
		"source_artifact_id": source_artifact_id,
		"source_item_type": "drill"
	}

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
