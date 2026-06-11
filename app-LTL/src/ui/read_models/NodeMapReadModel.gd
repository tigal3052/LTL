class_name NodeMapReadModel
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const LEVIATHAN_TABLE_PATH := "res://src/data/leviathan-table.json"

static func project(scene: Dictionary, selected_index: int = 0) -> Dictionary:
	var candidates: Array = scene.get("candidates", scene.get("nodeSelect", {}).get("candidates", []))
	var cards: Array = []
	var safe_selected := clampi(selected_index, 0, max(0, candidates.size() - 1))
	for idx in range(candidates.size()):
		var candidate: Dictionary = candidates[idx]
		var weakness: Array = candidate.get("weakness", [])
		cards.append({
			"id": str(candidate.get("id", "")),
			"label": TextCatalogScript.display_name(str(candidate.get("label", candidate.get("id", "")))),
			"nodeType": str(candidate.get("nodeType", "normal")),
			"riskTier": str(candidate.get("riskTier", "safe")),
			"rewardBias": str(candidate.get("rewardBias", "baseline")),
			"recommendedBuildHint": str(candidate.get("recommendedBuildHint", "")),
			"weakness": weakness.duplicate(true),
			"weaknessLabel": str(candidate.get("weaknessLabel", ",".join(weakness))),
			"finalStageDistance": int(candidate.get("finalStageDistance", 0)),
			"routeHash": str(candidate.get("routeHash", "")),
			"shield": float(candidate.get("shield", 0.0)),
			"health": float(candidate.get("health", 0.0)),
			"totalDurability": float(candidate.get("totalDurability", float(candidate.get("shield", 0.0)) + float(candidate.get("health", 0.0)))),
			"selected": idx == safe_selected,
			"disabled": false
		})
	var leviathan := _leviathan_for_scene(scene)
	var selected_card: Dictionary = cards[safe_selected] if not cards.is_empty() else {}
	return {
		"selectedIndex": safe_selected,
		"selectedColor": str(scene.get("selectedStartColor", scene.get("selectedColor", "red"))),
		"loadoutColors": scene.get("loadoutColors", ["red", "blue", "purple", "green"]).duplicate(true),
		"allowStartColorSelection": bool(scene.get("allowStartColorSelection", int(scene.get("stageIndex", 0)) == 0)),
		"stageText": TextCatalogScript.t("stage.label", [int(scene.get("stageIndex", 0)) + 1, maxi(1, int(scene.get("maxStages", 1)))]),
		"runStructure": TextCatalogScript.t("node_map.run_structure", [
			int(scene.get("runIndex", int(scene.get("stageIndex", 0)))) + 1,
			int(leviathan.get("runCount", 1)),
			int(leviathan.get("stageCount", maxi(1, int(scene.get("maxStages", 1))))),
			int(cards.size())
		]),
		"leviathan": leviathan,
		"targetLabel": str(selected_card.get("label", leviathan.get("name", TextCatalogScript.t("node_runtime.leviathan_default")))),
		"targetHint": str(selected_card.get("recommendedBuildHint", leviathan.get("biome", ""))),
		"targetWeakness": str(selected_card.get("weaknessLabel", "")),
		"cards": cards,
		"empty": cards.is_empty(),
		"telemetry": _telemetry(cards)
	}

static func _telemetry(cards: Array) -> Dictionary:
	var ids: Array = []
	var types: Array = []
	var weaknesses: Array = []
	var risks: Array = []
	var route_hashes: Array = []
	for card in cards:
		ids.append(str(card.get("id", "")))
		types.append(str(card.get("nodeType", "")))
		weaknesses.append(card.get("weakness", []).duplicate(true))
		risks.append(str(card.get("riskTier", "")))
		route_hashes.append(str(card.get("routeHash", "")))
	return {
		"event": "node_map_rendered",
		"candidate_ids": ids,
		"candidate_types": types,
		"candidate_weaknesses": weaknesses,
		"candidate_risk_tiers": risks,
		"route_hashes": route_hashes
	}

static func _leviathan_for_scene(scene: Dictionary) -> Dictionary:
	var table := _load_leviathans()
	if table.is_empty():
		return {
			"id": "contract",
			"name": TextCatalogScript.t("node_runtime.leviathan_default"),
			"biome": TextCatalogScript.t("leviathan.biome_unknown"),
			"runCount": 1,
			"stageCount": maxi(1, int(scene.get("maxStages", 1))),
			"imagePath": "res://resources/Leviathan/Leviathan_turtle.png"
		}
	var stage_index := int(scene.get("stageIndex", 0))
	var selected: Dictionary = table[stage_index % table.size()].duplicate(true)
	var image_paths := [
		"res://resources/Leviathan/Leviathan_turtle.png",
		"res://resources/Leviathan/Leviathan_lizard.png",
		"res://resources/Leviathan/Leviathan_golem.png"
	]
	selected["imagePath"] = image_paths[stage_index % image_paths.size()]
	selected["runCount"] = int(selected.get("runCount", selected.get("runCnt", 1)))
	selected["stageCount"] = int(selected.get("stageCount", selected.get("stageCnt", maxi(1, int(scene.get("maxStages", 1))))))
	return selected

static func _load_leviathans() -> Array:
	if not FileAccess.file_exists(LEVIATHAN_TABLE_PATH):
		return []
	var file := FileAccess.open(LEVIATHAN_TABLE_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return []
	var result: Array = []
	for entry in parsed.get("leviathans", []):
		if entry is Dictionary:
			result.append(entry.duplicate(true))
	return result
