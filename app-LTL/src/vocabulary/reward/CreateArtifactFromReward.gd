# 계약:
# - 책임: reward dictionary를 배치 가능한 Artifact model로 변환한다.
# - 입력: reward Dictionary, optional RunGrowthState.
# - 출력: { ok, artifact, code } dictionary.
# - 금지: inventory 배치, reward tray 변경, UI 접근.
#
# 실행: define the CreateArtifactFromReward vocabulary function holder.
class_name CreateArtifactFromReward
extends RefCounted

const ArtifactScript = preload("res://src/models/Artifact.gd")

# 실행: create an Artifact instance from reward data and active growth modifiers.
static func create(reward: Dictionary, growth_state: RefCounted = null) -> Dictionary:
	if reward.is_empty():
		return {"ok": false, "code": "missing_reward", "artifact": null}
	var payload: Dictionary = reward.get("payload", {})
	var rarity := str(reward.get("rarity", "common")).to_lower()
	var name := _display_artifact_name(str(reward.get("kind", "New Artifact")))
	var item_type := str(payload.get("item_type", payload.get("itemType", "drill")))
	if item_type.is_empty():
		item_type = "drill"
	var base_cooldown := int(payload.get("base_cooldown_ticks", payload.get("baseCooldownTicks", _default_cooldown(rarity))))
	var cooldown_modifier := 1.0
	if growth_state != null and growth_state.has_method("get_cooldown_modifier"):
		cooldown_modifier = float(growth_state.get_cooldown_modifier())
	var artifact = ArtifactScript.new({
		"id": str(reward.get("rewardId", "reward_%d" % randi())),
		"name": name,
		"shape": payload.get("shape", _default_shape(name, item_type)).duplicate(true),
		"energyType": str(payload.get("energy_type", payload.get("energyType", "red"))),
		"baseCooldownTicks": maxi(1, int(base_cooldown * cooldown_modifier)),
		"synergy": payload.get("synergy", {"type": "same_color", "value": 2}),
		"damage": float(payload.get("damage", _default_damage(rarity))),
		"grade": rarity,
		"item_type": item_type,
		"beacon_cooldown_mod": int(payload.get("beacon_cooldown_mod", payload.get("beaconCooldownMod", _default_beacon_cooldown(rarity, item_type)))),
		"beacon_damage_mod": float(payload.get("beacon_damage_mod", payload.get("beaconDamageMod", _default_beacon_damage(rarity, item_type)))),
		"keyword": str(reward.get("presentation", {}).get("description", ""))
	})
	return {"ok": true, "code": "created", "artifact": artifact}

# 실행: return default artifact shape when payload does not provide one.
static func _default_shape(name: String, item_type: String) -> Array:
	if item_type == "beacon":
		return [[1]]
	if "Drill" in name or "Core" in name:
		return [[1, 1]]
	if "Lens" in name or "Capacitor" in name:
		return [[1], [1]]
	if "Resonance" in name or "Reactor" in name:
		return [[1, 1], [1, 1]]
	return [[1]]

# 실행: remove reward-table implementation tags from stored artifact names.
static func _display_artifact_name(raw_name: String) -> String:
	var result := raw_name
	var regex := RegEx.new()
	if regex.compile("\\s+v\\d+\\b") == OK:
		result = regex.sub(result, "", true)
	if regex.compile("\\s*\\((Red|Blue|Purple|Green|red|blue|purple|green|빨강|파랑|보라|초록)\\)\\s*") == OK:
		result = regex.sub(result, " ", true)
	if regex.compile("\\b(Compact|Large|Small|Medium)\\s+\\d+x\\d+\\s+module\\.?\\s*") == OK:
		result = regex.sub(result, "", true)
	if regex.compile("\\s*\\(?\\d+x\\d+\\)?\\s*") == OK:
		result = regex.sub(result, " ", true)
	while result.contains("  "):
		result = result.replace("  ", " ")
	return result.strip_edges()

# 실행: return default cooldown from rarity.
static func _default_cooldown(rarity: String) -> int:
	if rarity == "rare":
		return 70
	if rarity == "epic":
		return 60
	if rarity == "legendary":
		return 50
	if rarity == "mythic":
		return 40
	return 80

# 실행: return default damage from rarity.
static func _default_damage(rarity: String) -> float:
	if rarity == "rare":
		return 1.3
	if rarity == "epic":
		return 1.6
	if rarity == "legendary":
		return 2.0
	if rarity == "mythic":
		return 2.5
	return 1.0

# 실행: return default beacon cooldown modifier.
static func _default_beacon_cooldown(rarity: String, item_type: String) -> int:
	if item_type != "beacon":
		return 0
	if rarity == "rare":
		return -15
	if rarity == "epic":
		return -25
	if rarity == "legendary":
		return -30
	if rarity == "mythic":
		return -40
	return -10

# 실행: return default beacon damage modifier.
static func _default_beacon_damage(rarity: String, item_type: String) -> float:
	if item_type != "beacon":
		return 0.0
	if rarity == "rare":
		return 0.3
	if rarity == "epic":
		return 0.6
	if rarity == "legendary":
		return 1.0
	if rarity == "mythic":
		return 1.5
	return 0.1
