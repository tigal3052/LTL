class_name ItemStatRoller
extends RefCounted

const QUALITY_CURVE_EXPONENT := 2.2
const RARITY_SPANS := {
	"common": 0.22,
	"rare": 0.16,
	"epic": 0.11,
	"legendary": 0.07,
	"mythic": 0.04
}

static func roll_payload(base_payload: Dictionary, seed_val: int, slot_index: int, catalog_id: String, rarity: String) -> Dictionary:
	var payload := base_payload.duplicate(true)
	var item_type := str(payload.get("item_type", payload.get("itemType", "drill"))).to_lower()
	if item_type == "relic":
		return payload
	var roll_seed := int(hash("%d:%d:%s:%s" % [seed_val, slot_index, catalog_id, rarity])) & 0x7fffffff
	var rng := RandomNumberGenerator.new()
	rng.seed = roll_seed
	var quality := _skewed_quality(rng)
	return apply_quality(payload, quality, rarity, roll_seed, catalog_id, slot_index)

static func apply_quality(payload: Dictionary, quality: int, rarity: String, roll_seed: int, catalog_id: String, slot_index: int) -> Dictionary:
	var rolled := payload.duplicate(true)
	var item_type := str(rolled.get("item_type", rolled.get("itemType", "drill"))).to_lower()
	if item_type == "relic":
		return rolled
	var clamped_quality := clampi(quality, 1, 100)
	var span := roll_span_for_rarity(rarity)
	var normalized := float(clamped_quality - 1) / 99.0
	var stat_multiplier := 1.0 - span + (2.0 * span * normalized)
	var cooldown_multiplier := 1.0 + span - (2.0 * span * normalized)
	var stat_roll := {
		"quality": clamped_quality,
		"range": span,
		"roll_seed": roll_seed,
		"catalog_id": catalog_id,
		"slot_index": slot_index,
		"quality_curve": QUALITY_CURVE_EXPONENT,
		"stat_multiplier": snappedf(stat_multiplier, 0.001),
		"cooldown_multiplier": snappedf(cooldown_multiplier, 0.001)
	}
	_apply_damage_roll(rolled, stat_roll, stat_multiplier, cooldown_multiplier)
	_apply_cooldown_roll(rolled, stat_roll, cooldown_multiplier)
	_apply_beacon_damage_roll(rolled, stat_roll, stat_multiplier, cooldown_multiplier)
	_apply_beacon_cooldown_roll(rolled, stat_roll, stat_multiplier, cooldown_multiplier)
	rolled["roll_quality"] = clamped_quality
	rolled["rollQuality"] = clamped_quality
	rolled["stat_roll"] = stat_roll
	rolled["statRoll"] = stat_roll.duplicate(true)
	return rolled

static func roll_span_for_rarity(rarity: String) -> float:
	return float(RARITY_SPANS.get(rarity.to_lower(), RARITY_SPANS["common"]))

static func _skewed_quality(rng: RandomNumberGenerator) -> int:
	var curved := pow(rng.randf(), QUALITY_CURVE_EXPONENT)
	return clampi(1 + int(floor(curved * 100.0)), 1, 100)

static func _apply_damage_roll(payload: Dictionary, stat_roll: Dictionary, stat_multiplier: float, penalty_multiplier: float) -> void:
	if not payload.has("damage"):
		return
	var base_damage := float(payload.get("damage", 0.0))
	var multiplier := stat_multiplier if base_damage >= 0.0 else penalty_multiplier
	payload["damage"] = snappedf(base_damage * multiplier, 0.01)
	stat_roll["base_damage"] = base_damage

static func _apply_cooldown_roll(payload: Dictionary, stat_roll: Dictionary, cooldown_multiplier: float) -> void:
	if not (payload.has("base_cooldown_ticks") or payload.has("baseCooldownTicks")):
		return
	var base_cooldown := int(payload.get("base_cooldown_ticks", payload.get("baseCooldownTicks", 1)))
	var rolled_cooldown := maxi(1, int(round(float(base_cooldown) * cooldown_multiplier)))
	payload["base_cooldown_ticks"] = rolled_cooldown
	payload["baseCooldownTicks"] = rolled_cooldown
	stat_roll["base_cooldown_ticks"] = base_cooldown

static func _apply_beacon_damage_roll(payload: Dictionary, stat_roll: Dictionary, stat_multiplier: float, penalty_multiplier: float) -> void:
	if not (payload.has("beacon_damage_mod") or payload.has("beaconDamageMod")):
		return
	var base_beacon_damage := float(payload.get("beacon_damage_mod", payload.get("beaconDamageMod", 0.0)))
	var multiplier := stat_multiplier if base_beacon_damage >= 0.0 else penalty_multiplier
	var rolled_beacon_damage := snappedf(base_beacon_damage * multiplier, 0.01)
	payload["beacon_damage_mod"] = rolled_beacon_damage
	payload["beaconDamageMod"] = rolled_beacon_damage
	stat_roll["base_beacon_damage_mod"] = base_beacon_damage

static func _apply_beacon_cooldown_roll(payload: Dictionary, stat_roll: Dictionary, stat_multiplier: float, penalty_multiplier: float) -> void:
	if not (payload.has("beacon_cooldown_mod") or payload.has("beaconCooldownMod")):
		return
	var base_beacon_cooldown := int(payload.get("beacon_cooldown_mod", payload.get("beaconCooldownMod", 0)))
	var multiplier := stat_multiplier if base_beacon_cooldown < 0 else penalty_multiplier
	var rolled_beacon_cooldown := int(round(float(base_beacon_cooldown) * multiplier))
	payload["beacon_cooldown_mod"] = rolled_beacon_cooldown
	payload["beaconCooldownMod"] = rolled_beacon_cooldown
	stat_roll["base_beacon_cooldown_mod"] = base_beacon_cooldown
