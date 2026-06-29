class_name EnergyToken
extends RefCounted

static func active_drill_records(inventory: InventoryModel) -> Array:
	var records: Array = []
	if inventory == null:
		return records
	for artifact_key in inventory.artifacts:
		var artifact = inventory.artifacts[artifact_key]
		if not artifact is Artifact:
			continue
		if artifact.item_type != "drill" or artifact.is_broken or artifact.freeze_ticks > 0:
			continue
		records.append({
			"artifact": artifact,
			"artifact_key": str(artifact_key),
			"cooldown": effective_cooldown(artifact),
			"color": str(artifact.energy_type),
			"source_id": source_id_for(artifact, str(artifact_key)),
			"order": records.size()
		})
	records.sort_custom(Callable(EnergyToken, "_sort_drill_record"))
	return records

static func effective_cooldown(artifact: Artifact) -> int:
	if artifact == null:
		return 1
	return maxi(1, int(artifact.base_cooldown_ticks) - int(artifact.synergy_cooldown_reduction))

static func average_cooldown(records: Array) -> float:
	if records.is_empty():
		return 0.0
	var total := 0
	for record in records:
		total += int(record.get("cooldown", 1))
	return maxf(1.0, float(total) / float(records.size()))

static func build_token(inventory: InventoryModel, drill: Artifact, artifact_key: String = "") -> Dictionary:
	var source_id := source_id_for(drill, artifact_key)
	var color := str(drill.energy_type) if drill != null else "red"
	var token := {
		"color": color,
		"source_artifact_id": str(drill.id) if drill != null else "",
		"source_drill_instance_id": source_id,
		"source_item_type": "drill",
		"damage": maxf(0.0, float(drill.damage)) if drill != null else 1.0,
		"attack_style": color,
		"modifiers": {},
		"buff_source_ids": []
	}
	_apply_beacon_token_modifiers(token, inventory, drill)
	return token

static func normalize(item: Variant) -> Dictionary:
	var token: Dictionary = item.duplicate(true) if item is Dictionary else {"color": str(item)}
	var color := str(token.get("color", token.get("energy", "")))
	token["color"] = color
	token["source_artifact_id"] = str(token.get("source_artifact_id", ""))
	token["source_drill_instance_id"] = str(token.get("source_drill_instance_id", token.get("source_artifact_id", "")))
	token["source_item_type"] = str(token.get("source_item_type", token.get("item_type", "drill")))
	token["attack_style"] = str(token.get("attack_style", color))
	if not token.has("damage"):
		token["damage"] = 1.0
	if not (token.get("modifiers", {}) is Dictionary):
		token["modifiers"] = {}
	if not (token.get("buff_source_ids", []) is Array):
		token["buff_source_ids"] = []
	return token

static func source_id(item: Variant) -> String:
	if item is Dictionary:
		var instance_id := str(item.get("source_drill_instance_id", ""))
		if not instance_id.is_empty():
			return instance_id
		return str(item.get("source_artifact_id", ""))
	return ""

static func damage_for_token(item: Variant, source_drill: Artifact = null) -> float:
	if item is Dictionary and item.has("damage"):
		return maxf(0.0, float(item.get("damage", 1.0)))
	if source_drill != null:
		return maxf(0.0, float(source_drill.damage))
	return 1.0

static func source_id_for(artifact: Artifact, artifact_key: String = "") -> String:
	if not artifact_key.is_empty():
		return artifact_key
	if artifact == null:
		return ""
	if not str(artifact.instance_id).is_empty():
		return str(artifact.instance_id)
	return str(artifact.id)

static func _apply_beacon_token_modifiers(token: Dictionary, inventory: InventoryModel, drill: Artifact) -> void:
	if inventory == null or drill == null:
		return
	var modifiers: Dictionary = token.get("modifiers", {})
	var buff_source_ids: Array = token.get("buff_source_ids", [])
	for artifact_key in inventory.artifacts:
		var beacon = inventory.artifacts[artifact_key]
		if not beacon is Artifact:
			continue
		if beacon.item_type != "beacon" or beacon.energy_type != drill.energy_type:
			continue
		var adjacent_drills: Array = inventory.get_adjacent_drills(beacon)
		if not adjacent_drills.has(drill):
			continue
		var beacon_source_id := source_id_for(beacon, str(artifact_key))
		if not is_zero_approx(float(beacon.beacon_damage_mod)):
			token["damage"] = maxf(0.0, float(token.get("damage", 0.0)) + float(beacon.beacon_damage_mod))
			modifiers["beacon_damage_bonus"] = float(modifiers.get("beacon_damage_bonus", 0.0)) + float(beacon.beacon_damage_mod)
		if int(beacon.beacon_cooldown_mod) != 0:
			modifiers["beacon_cooldown_mod"] = int(modifiers.get("beacon_cooldown_mod", 0)) + int(beacon.beacon_cooldown_mod)
		if not buff_source_ids.has(beacon_source_id):
			buff_source_ids.append(beacon_source_id)
	token["modifiers"] = modifiers
	token["buff_source_ids"] = buff_source_ids

static func _sort_drill_record(a: Dictionary, b: Dictionary) -> bool:
	var cooldown_a := int(a.get("cooldown", 1))
	var cooldown_b := int(b.get("cooldown", 1))
	if cooldown_a != cooldown_b:
		return cooldown_a < cooldown_b
	var order_a := int(a.get("order", 0))
	var order_b := int(b.get("order", 0))
	if order_a != order_b:
		return order_a < order_b
	return str(a.get("source_id", "")) < str(b.get("source_id", ""))
