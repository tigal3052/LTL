# 怨꾩빟:
# - Responsibility: project scene-safe node candidates into route-card data for NodeMapScene.
# - Input: SceneReadModel-style dictionary and selected index.
# - Output: display cards, route status, and node_map_rendered telemetry.
# - Prohibited: node candidate generation, phase mutation, raw pick-weight exposure.
#
# ?ㅽ뻾: define the NodeMapReadModel class identity.
class_name NodeMapReadModel
extends RefCounted
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

# ?ㅽ뻾: project node-select scene data into node-map card data.
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
			"selected": idx == safe_selected,
			"disabled": false
		})
	return {
		"selectedIndex": safe_selected,
		"stageText": TextCatalogScript.t("stage.label", [int(scene.get("stageIndex", 0)) + 1, maxi(1, int(scene.get("maxStages", 1)))]),
		"cards": cards,
		"empty": cards.is_empty(),
		"telemetry": _telemetry(cards)
	}

# ?ㅽ뻾: build a node_map_rendered telemetry payload from projected cards.
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
