# 계약:
# - 책임: Artifact 또는 reward dictionary를 tooltip 표시용 read model과 BBCode text로 변환한다.
# - 입력: Artifact object 또는 reward Dictionary.
# - 출력: { name, grade, itemType, energyType, bbcode } dictionary.
# - 금지: UI node 접근, gameplay 상태 변경, inventory 변경.
#
# 실행: define the TooltipReadModel class.
class_name TooltipReadModel
extends RefCounted
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

# 실행: project tooltip-safe display data from artifact-like input.
static func project(value: Variant) -> Dictionary:
	var data := _normalize(value)
	var bbcode := _build_bbcode(data, TextCatalogScript.locale())
	data["bbcode"] = bbcode
	return data

# 실행: build a reward tooltip that compares a reward drill with the same-color equipped drill.
static func project_reward_comparison(reward: Dictionary, equipped_artifacts: Array, locale := "") -> Dictionary:
	var loc := locale if not locale.is_empty() else TextCatalogScript.locale()
	var reward_data := _normalize(reward)
	var equipped_data := {}
	if str(reward_data.get("itemType", "")) == "drill":
		equipped_data = _same_color_drill(equipped_artifacts, str(reward_data.get("energyType", "")))
	var bbcode := _build_comparison_bbcode(reward_data, equipped_data, loc)
	reward_data["comparison"] = equipped_data
	reward_data["bbcode"] = bbcode
	return reward_data

# 실행: normalize reward dictionaries and Artifact objects into one shape.
static func _normalize(value: Variant) -> Dictionary:
	if value is Dictionary:
		var payload: Dictionary = value.get("payload", {})
		var name_val := TextCatalogScript.display_name(str(value.get("kind", "알 수 없는 아이템")))
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
		"name": TextCatalogScript.display_name(str(value.name)),
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
static func _build_bbcode(data: Dictionary, locale := "ko") -> String:
	var rarity_color := _rarity_color(str(data["grade"]))
	var energy_color := _energy_color(str(data["energyType"]))
	var lines: Array[String] = []
	lines.append("[b][size=14][color=%s]%s[/color][/size][/b]" % [rarity_color, data["name"]])
	lines.append("[color=#7f848e]%s - %s[/color]" % [_label("rarity", str(data["grade"]), locale), _label("item", str(data["itemType"]), locale)])
	lines.append("[color=%s]%s: %s[/color]" % [energy_color, TextCatalogScript.t("tooltip.energy", [], locale), _label("color", str(data["energyType"]), locale)])
	if str(data["itemType"]) == "drill":
		var eff_cd := maxi(1, int(data["baseCooldownTicks"]) - int(data["synergyCooldownReduction"]))
		lines.append("%s: %d T" % [TextCatalogScript.t("tooltip.cooldown", [], locale), eff_cd])
		lines.append("%s: [color=#e06c75]%.1f[/color]" % [TextCatalogScript.t("tooltip.damage", [], locale), float(data["damage"])])
		if int(data["synergyCooldownReduction"]) > 0:
			lines.append("[color=#98c379]%s: -%d T[/color]" % [TextCatalogScript.t("tooltip.synergy_cdr", [], locale), int(data["synergyCooldownReduction"])])
	elif str(data["itemType"]) == "beacon":
		lines.append("[color=#61afef]%s:[/color]" % TextCatalogScript.t("tooltip.beacon_effects", [], locale))
		if int(data["beaconCooldownMod"]) != 0:
			var cd_sign := "+" if int(data["beaconCooldownMod"]) > 0 else ""
			var cd_color := "#e06c75" if int(data["beaconCooldownMod"]) > 0 else "#98c379"
			lines.append("- %s: [color=%s]%s%d T[/color]" % [TextCatalogScript.t("tooltip.cooldown", [], locale), cd_color, cd_sign, int(data["beaconCooldownMod"])])
		if float(data["beaconDamageMod"]) != 0.0:
			var dmg_sign := "+" if float(data["beaconDamageMod"]) > 0.0 else ""
			var dmg_color := "#98c379" if float(data["beaconDamageMod"]) > 0.0 else "#e06c75"
			lines.append("- %s: [color=%s]%s%.1f[/color]" % [TextCatalogScript.t("tooltip.damage", [], locale), dmg_color, dmg_sign, float(data["beaconDamageMod"])])
	if not str(data["keyword"]).is_empty():
		lines.append("\n[color=#5c6370][i]%s[/i][/color]" % str(data["keyword"]))
	return "\n".join(lines)

# 실행: render reward and equipped artifact stats side by side in one tooltip body.
static func _build_comparison_bbcode(reward_data: Dictionary, equipped_data: Dictionary, locale: String) -> String:
	var left_title := TextCatalogScript.t("tooltip.reward_artifact", [], locale)
	var right_title := TextCatalogScript.t("tooltip.equipped_artifact", [], locale)
	var reward_lines := _compact_lines(reward_data, locale)
	var equipped_lines := [TextCatalogScript.t("tooltip.no_same_color_drill", [], locale)]
	if not equipped_data.is_empty():
		equipped_lines = _compact_lines(equipped_data, locale)
	var lines: Array[String] = []
	lines.append("[table=2]")
	lines.append("[cell][b][color=#e5c07b]%s[/color][/b]\n%s[/cell]" % [left_title, "\n".join(reward_lines)])
	lines.append("[cell][b][color=#98c379]%s[/color][/b]\n%s[/cell]" % [right_title, "\n".join(equipped_lines)])
	lines.append("[/table]")
	return "\n".join(lines)

# 실행: turn normalized artifact data into compact comparison rows.
static func _compact_lines(data: Dictionary, locale: String) -> Array[String]:
	var item_type := str(data.get("itemType", "drill"))
	var eff_cd := maxi(1, int(data.get("baseCooldownTicks", 1)) - int(data.get("synergyCooldownReduction", 0)))
	return [
		str(data.get("name", "")),
		"%s / %s" % [_label("rarity", str(data.get("grade", "common")), locale), _label("item", item_type, locale)],
		"%s: %s" % [TextCatalogScript.t("tooltip.energy", [], locale), _label("color", str(data.get("energyType", "")), locale)],
		"%s: %d T" % [TextCatalogScript.t("tooltip.cooldown", [], locale), eff_cd],
		"%s: %.1f" % [TextCatalogScript.t("tooltip.damage", [], locale), float(data.get("damage", 0.0))]
	]

# 실행: find the currently equipped drill with the same energy color as the reward.
static func _same_color_drill(equipped_artifacts: Array, energy_type: String) -> Dictionary:
	for artifact in equipped_artifacts:
		var data := _normalize(artifact)
		if str(data.get("itemType", "")) == "drill" and str(data.get("energyType", "")) == energy_type:
			return data
	return {}

# 실행: resolve rarity, item, and color labels through the text catalog.
static func _label(group: String, value: String, locale: String) -> String:
	var key := "%s.%s" % [group, value.to_lower()]
	return TextCatalogScript.t(key, [], locale)

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
