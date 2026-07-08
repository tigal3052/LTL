# 계약:
# - Responsibility: project starter loadout artifacts into localized character-select copy.
# - Input: starter color ids and optional Artifact rows.
# - Output: localized card/button copy models and bag-detail dictionaries.
# - Forbidden: scene-tree mutation or page layout decisions.
#
# 실행: expose starter loadout copy helpers without owning the page scene.
class_name CharacterSelectLoadoutText
extends RefCounted

const ArtifactScript = preload("res://src/models/Artifact.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

static func detail_for_slot(color_name: String, slot_index: int) -> Dictionary:
	var loadout := starter_loadout_for_color(color_name)
	if slot_index >= 0 and slot_index < loadout.size():
		return detail_for_artifact(loadout[slot_index])
	return empty_bag_detail()

static func starter_item_models(color_name: String) -> Array:
	var models: Array = []
	for artifact in starter_loadout_for_color(color_name):
		models.append({
			"itemId": str(artifact.id),
			"title": starter_artifact_title(artifact),
			"summary": starter_artifact_summary(artifact),
			"metricLine": starter_palette_metric_line(artifact),
			"itemType": str(artifact.item_type),
			"colorName": str(artifact.energy_type),
			"iconPath": starter_artifact_icon_path(artifact)
		})
	return models

static func starter_artifact_icon_path(artifact) -> String:
	if artifact == null:
		return ""
	var color_name := str(artifact.energy_type).to_lower()
	var item_type := str(artifact.item_type).to_lower()
	if item_type == "beacon":
		return "res://resources/items/becon/%s_becon_start.png" % color_name
	if item_type == "drill":
		return "res://resources/items/drill/%s_drill_common.png" % color_name
	return ""

static func detail_for_item_id(color_name: String, item_id: String) -> Dictionary:
	for artifact in starter_loadout_for_color(color_name):
		if str(artifact.id) == item_id:
			return detail_for_artifact(artifact)
	return empty_bag_detail()

static func detail_for_artifact(artifact) -> Dictionary:
	if artifact == null:
		return empty_bag_detail()
	return {
		"title": starter_artifact_title(artifact),
		"body": starter_artifact_summary(artifact),
		"metricLine": starter_palette_metric_line(artifact)
	}

static func starter_palette_text(color_name: String) -> String:
	var loadout := starter_loadout_for_color(color_name)
	var drill = loadout[0] if loadout.size() > 0 else null
	var beacon = loadout[1] if loadout.size() > 1 else null
	return TextCatalogScript.t("character.starter_palette_text", [
		TextCatalogScript.color_label(color_name),
		starter_artifact_title(drill),
		starter_artifact_summary(drill),
		starter_artifact_title(beacon),
		starter_artifact_summary(beacon)
	])

static func starter_loadout_for_color(color_name: String) -> Array:
	var loadout = ArtifactScript.get_starter_loadout(color_name)
	return loadout.duplicate(true) if loadout is Array else []

static func starter_palette_button_text(color_name: String) -> String:
	return starter_palette_card_model(color_name).get("title", "")

static func starter_palette_card_model(color_name: String) -> Dictionary:
	var loadout := starter_loadout_for_color(color_name)
	var drill = loadout[0] if loadout.size() > 0 else null
	var beacon = loadout[1] if loadout.size() > 1 else null
	return {
		"title": TextCatalogScript.t("character.starter_set", [TextCatalogScript.color_label(color_name)]),
		"body": TextCatalogScript.t("character.starter_card.summary", [
			_starter_palette_identity(color_name),
			TextCatalogScript.item_label("drill"),
			TextCatalogScript.item_label("beacon")
		]),
		"tags": starter_palette_tags(color_name, drill, beacon)
	}

static func starter_palette_tags(color_name: String, drill, beacon) -> Array:
	var tags: Array = []
	tags.append(_tag(TextCatalogScript.t("character.tag.role.drill"), "type"))
	tags.append(_tag(_starter_drill_archetype(color_name, drill), "feature"))
	tags.append(_tag(TextCatalogScript.t("character.tag.role.beacon"), "type"))
	tags.append(_tag(TextCatalogScript.t("character.tag.beacon_support"), "support"))
	return tags

static func starter_artifact_title(artifact) -> String:
	if artifact == null:
		return TextCatalogScript.t("character.unknown_item")
	var color_name := TextCatalogScript.color_label(str(artifact.energy_type))
	var item_type := TextCatalogScript.item_label(str(artifact.item_type))
	return TextCatalogScript.t("character.starter_title", [color_name, item_type])

static func starter_artifact_summary(artifact) -> String:
	if artifact == null:
		return TextCatalogScript.t("character.no_data")
	var item_type := str(artifact.item_type)
	if item_type == "drill":
		return TextCatalogScript.t("character.drill_summary", [_format_float(float(artifact.base_damage)), int(artifact.base_cooldown_ticks)])
	if item_type == "beacon":
		var cooldown_effect := beacon_tick_phrase(int(artifact.beacon_cooldown_mod))
		return TextCatalogScript.t("character.beacon_summary", [int(artifact.base_cooldown_ticks), cooldown_effect, _format_float(float(artifact.beacon_damage_mod))])
	return TextCatalogScript.t("character.pending_effect")

static func beacon_tick_phrase(delta: int) -> String:
	if delta < 0:
		return TextCatalogScript.t("character.beacon_tick.down", [abs(delta)])
	if delta > 0:
		return TextCatalogScript.t("character.beacon_tick.up", [delta])
	return TextCatalogScript.t("character.beacon_tick.flat")

static func starter_palette_metric_line(artifact) -> String:
	if artifact == null:
		return TextCatalogScript.t("character.palette_metric.empty")
	var item_type := str(artifact.item_type)
	var item_label := TextCatalogScript.item_label(item_type)
	if item_type == "drill":
		return TextCatalogScript.t("character.palette_metric.drill", [item_label, _format_float(float(artifact.base_damage)), int(artifact.base_cooldown_ticks)])
	if item_type == "beacon":
		return TextCatalogScript.t("character.palette_metric.beacon", [
			item_label,
			int(artifact.base_cooldown_ticks),
			beacon_tick_compact(int(artifact.beacon_cooldown_mod)),
			_format_float(float(artifact.beacon_damage_mod))
		])
	return item_label

static func beacon_tick_compact(delta: int) -> String:
	if delta < 0:
		return TextCatalogScript.t("character.beacon_tick_compact.down", [abs(delta)])
	if delta > 0:
		return TextCatalogScript.t("character.beacon_tick_compact.up", [delta])
	return TextCatalogScript.t("character.beacon_tick_compact.flat")

static func empty_bag_detail() -> Dictionary:
	return {
		"title": TextCatalogScript.t("character.empty_slot.title"),
		"body": TextCatalogScript.t("character.empty_slot.body"),
		"metricLine": ""
	}

static func _tag(text: String, tone: String) -> Dictionary:
	return {
		"text": text,
		"tone": tone
	}

static func _starter_palette_identity(color_name: String) -> String:
	var locale := TextCatalogScript.locale()
	if locale == "en":
		match color_name:
			"red":
				return "red relic"
			"blue":
				return "blue relic"
			"purple":
				return "purple relic"
			"green":
				return "green relic"
		return "starter relic"
	match color_name:
		"red":
			return "붉은 유물"
		"blue":
			return "푸른 유물"
		"purple":
			return "보랏빛 유물"
		"green":
			return "초록 유물"
	return "시작 유물"

static func _starter_drill_archetype(color_name: String, artifact) -> String:
	var suffix := str(color_name).to_lower()
	if artifact != null and str(artifact.energy_type).to_lower() in ["red", "blue", "purple", "green"]:
		suffix = str(artifact.energy_type).to_lower()
	return TextCatalogScript.t("character.tag.archetype.%s" % suffix)

static func _format_float(value: float) -> String:
	var rounded := snappedf(value, 0.1)
	if is_equal_approx(rounded, floor(rounded)):
		return str(int(rounded))
	return str(rounded)

static func _format_signed_float(value: float) -> String:
	var rendered := _format_float(absf(value))
	return "+%s" % rendered if value >= 0.0 else "-%s" % rendered

static func starter_palette_meta(color_name: String) -> String:
	match color_name:
		"red":
			return "강한 피해 · 초반 개방"
		"blue":
			return "파동 안정 · 쿨다운 보정"
		"purple":
			return "디버프 · 상태이상 특화"
		"green":
			return "지속 회복 · 장기전 특화"
	return ""
