# 계약:
# - 책임: Artifact 또는 reward dictionary를 tooltip 표시용 read model과 BBCode text로 변환한다.
# - 입력: Artifact object 또는 reward Dictionary.
# - 출력: { name, grade, itemType, energyType, bbcode } dictionary.
# - 금지: UI node 접근, gameplay 상태 변경, inventory 변경.
#
# 실행: define the TooltipReadModel class.
class_name TooltipReadModel
extends RefCounted

# 실행: project tooltip-safe display data from artifact-like input.
static func project(value: Variant) -> Dictionary:
	var data := _normalize(value)
	var bbcode := _build_bbcode(data)
	data["bbcode"] = bbcode
	return data

# 실행: normalize reward dictionaries and Artifact objects into one shape.
static func _normalize(value: Variant) -> Dictionary:
	if value is Dictionary:
		var payload: Dictionary = value.get("payload", {})
		var name_val := str(value.get("kind", "Unknown Item"))
		var grade_val := str(value.get("rarity", "common")).to_lower()
		var item_type_val := str(payload.get("item_type", payload.get("itemType", "drill")))
		if payload.get("item_type", "") == "beacon" or "Beacon" in name_val or "beacon" in name_val:
			item_type_val = "beacon"
		return {
			"name": name_val,
			"grade": grade_val,
			"itemType": item_type_val,
			"energyType": str(payload.get("energy_type", payload.get("energyType", "red"))),
			"baseCooldownTicks": int(payload.get("base_cooldown_ticks", payload.get("baseCooldownTicks", _default_cooldown(grade_val)))),
			"synergyCooldownReduction": 0,
			"damage": float(payload.get("damage", _default_damage(grade_val))),
			"beaconCooldownMod": int(payload.get("beacon_cooldown_mod", payload.get("beaconCooldownMod", _default_beacon_cooldown(grade_val, item_type_val)))),
			"beaconDamageMod": float(payload.get("beacon_damage_mod", payload.get("beaconDamageMod", _default_beacon_damage(grade_val, item_type_val)))),
			"keyword": str(value.get("presentation", {}).get("description", ""))
		}
	return {
		"name": str(value.name),
		"grade": str(value.grade).to_lower(),
		"itemType": str(value.item_type),
		"energyType": str(value.energy_type),
		"baseCooldownTicks": int(value.base_cooldown_ticks),
		"synergyCooldownReduction": int(value.synergy_cooldown_reduction),
		"damage": float(value.damage),
		"beaconCooldownMod": int(value.beacon_cooldown_mod),
		"beaconDamageMod": float(value.beacon_damage_mod),
		"keyword": str(value.keyword)
	}

# 실행: build the BBCode tooltip body.
static func _build_bbcode(data: Dictionary) -> String:
	var rarity_color := _rarity_color(str(data["grade"]))
	var energy_color := _energy_color(str(data["energyType"]))
	var lines: Array[String] = []
	lines.append("[b][size=14][color=%s]%s[/color][/size][/b]" % [rarity_color, data["name"]])
	lines.append("[color=#7f848e]%s - %s[/color]" % [str(data["grade"]).capitalize(), str(data["itemType"]).capitalize()])
	lines.append("[color=%s]Energy: %s[/color]" % [energy_color, str(data["energyType"]).to_upper()])
	if str(data["itemType"]) == "drill":
		var eff_cd := maxi(1, int(data["baseCooldownTicks"]) - int(data["synergyCooldownReduction"]))
		lines.append("Cooldown: %d T" % eff_cd)
		lines.append("Damage: [color=#e06c75]%.1f[/color]" % float(data["damage"]))
		if int(data["synergyCooldownReduction"]) > 0:
			lines.append("[color=#98c379]Synergy CDR: -%d T[/color]" % int(data["synergyCooldownReduction"]))
	elif str(data["itemType"]) == "beacon":
		lines.append("[color=#61afef]Beacon Effects on adjacent drills:[/color]")
		if int(data["beaconCooldownMod"]) != 0:
			var cd_sign := "+" if int(data["beaconCooldownMod"]) > 0 else ""
			var cd_color := "#e06c75" if int(data["beaconCooldownMod"]) > 0 else "#98c379"
			lines.append("- Cooldown: [color=%s]%s%d T[/color]" % [cd_color, cd_sign, int(data["beaconCooldownMod"])])
		if float(data["beaconDamageMod"]) != 0.0:
			var dmg_sign := "+" if float(data["beaconDamageMod"]) > 0.0 else ""
			var dmg_color := "#98c379" if float(data["beaconDamageMod"]) > 0.0 else "#e06c75"
			lines.append("- Damage: [color=%s]%s%.1f[/color]" % [dmg_color, dmg_sign, float(data["beaconDamageMod"])])
	if not str(data["keyword"]).is_empty():
		lines.append("\n[color=#5c6370][i]%s[/i][/color]" % str(data["keyword"]))
	return "\n".join(lines)

# 실행: return display color for rarity.
static func _rarity_color(grade: String) -> String:
	return {"basic": "#abb2bf", "common": "#a3be8c", "rare": "#61afef", "epic": "#c678dd", "legendary": "#e5c07b", "mythic": "#d19a66"}.get(grade.to_lower(), "#abb2bf")

# 실행: return display color for energy type.
static func _energy_color(energy: String) -> String:
	return {"red": "#e06c75", "blue": "#61afef", "purple": "#c678dd", "green": "#98c379"}.get(energy.to_lower(), "#abb2bf")

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
