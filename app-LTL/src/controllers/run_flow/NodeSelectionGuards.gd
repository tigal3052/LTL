extends RefCounted
# ?ㅽ뻾: project the currently selected or active node into page context data.
static func selected_node_context(scene: Dictionary = {}, selected_index: int = -1, selected_run_node: Dictionary = {}) -> Dictionary:
	var phase := str(scene.get("phase", ""))
	if phase == "node_select":
		var candidates: Array = scene.get("nodeSelect", {}).get("candidates", [])
		var index := int(scene.get("selectedNodeIndex", selected_index))
		if not candidates.is_empty() and index >= 0 and index < candidates.size():
			return node_context_from_dict(candidates[index])
		return empty_node_context()
	var combat_payload: Variant = scene.get("combat", {})
	var combat_node: Dictionary = {}
	if combat_payload is Dictionary:
		combat_node = combat_payload.get("node", {})
	if combat_node is Dictionary and not combat_node.is_empty():
		return node_context_from_dict(combat_node, str(scene.get("lastNodeLabel", "")))
	if selected_run_node is Dictionary and not selected_run_node.is_empty():
		return node_context_from_dict(selected_run_node, str(scene.get("lastNodeLabel", "")))
	return empty_node_context()
# ?ㅽ뻾: build the empty selected-node context shape expected by page renderers.
# ?ㅽ뻾: build the empty selected-node context shape expected by page renderers.
static func empty_node_context() -> Dictionary:
	return {
		"node_id": "",
		"node_type": "",
		"label": "",
		"risk_tier": "",
		"weakness": [],
		"shieldMul": 1.0,
		"healthMul": 1.0,
		"rewardBias": "baseline",
		"recommendedBuildHint": "",
		"is_boss": false,
		"is_event": false
	}
# ?ㅽ뻾: decide whether the selected node can start combat for the current scene.
# ?ㅽ뻾: decide whether the selected node can start combat for the current scene.
static func selected_node_start_enabled(scene: Dictionary = {}, selected_index: int = -1) -> bool:
	if str(scene.get("phase", "")) != "node_select":
		return false
	var node_select: Dictionary = scene.get("nodeSelect", {}) if scene.get("nodeSelect", {}) is Dictionary else {}
	var candidates: Array = node_select.get("candidates", [])
	var index := int(scene.get("selectedNodeIndex", selected_index))
	if index < 0 or index >= candidates.size():
		return false
	var candidate: Dictionary = candidates[index]
	if not node_candidate_matches_current_stage(candidate, scene):
		return false
	return not node_candidate_already_cleared(candidate, index, scene)
# ?ㅽ뻾: check whether a candidate belongs to the current stage distance.
# ?ㅽ뻾: check whether a candidate belongs to the current stage distance.
static func node_candidate_matches_current_stage(candidate: Dictionary, scene: Dictionary) -> bool:
	var stage_index := int(scene.get("stageIndex", 0))
	var max_stages := maxi(1, int(scene.get("maxStages", 1)))
	var expected_distance := maxi(0, max_stages - stage_index - 1)
	if candidate.has("finalStageDistance"):
		return int(candidate.get("finalStageDistance", expected_distance)) == expected_distance
	return true
# ?ㅽ뻾: detect whether the current-stage route already cleared this candidate.
# ?ㅽ뻾: detect whether the current-stage route already cleared this candidate.
static func node_candidate_already_cleared(candidate: Dictionary, candidate_index: int, scene: Dictionary) -> bool:
	if bool(candidate.get("cleared", false)) or str(candidate.get("status", "")) == "cleared":
		return true
	var node_select: Dictionary = scene.get("nodeSelect", {}) if scene.get("nodeSelect", {}) is Dictionary else {}
	var route_history: Array = node_select.get("routeHistory", scene.get("routeHistory", []))
	var stage_index := int(scene.get("stageIndex", 0))
	var candidate_id := str(candidate.get("id", ""))
	var candidate_hash := str(candidate.get("routeHash", ""))
	for entry in route_history:
		if not (entry is Dictionary):
			continue
		var history_entry: Dictionary = entry
		if int(history_entry.get("stageIndex", -1)) != stage_index:
			continue
		if not candidate_hash.is_empty() and str(history_entry.get("routeHash", "")) == candidate_hash:
			return true
		if not candidate_id.is_empty() and str(history_entry.get("id", "")) == candidate_id and int(history_entry.get("routeSlotIndex", -1)) == candidate_index:
			return true
	return false
# ?ㅽ뻾: normalize raw node dictionaries into selected-node page context.
# ?ㅽ뻾: normalize raw node dictionaries into selected-node page context.
static func node_context_from_dict(node: Dictionary, fallback_label: String = "") -> Dictionary:
	return {
		"node_id": str(node.get("id", "")),
		"node_type": str(node.get("nodeType", "")),
		"label": str(node.get("label", fallback_label)),
		"risk_tier": str(node.get("riskTier", "")),
		"weakness": node.get("weakness", []).duplicate(true) if node.get("weakness", []) is Array else [],
		"shieldMul": float(node.get("shieldMul", 1.0)),
		"healthMul": float(node.get("healthMul", 1.0)),
		"shieldMulByColor": node.get("shieldMulByColor", node.get("shield_mul_by_color", {})).duplicate(true) if node.get("shieldMulByColor", node.get("shield_mul_by_color", {})) is Dictionary else {},
		"healthMulByColor": node.get("healthMulByColor", node.get("health_mul_by_color", {})).duplicate(true) if node.get("healthMulByColor", node.get("health_mul_by_color", {})) is Dictionary else {},
		"rewardBias": str(node.get("rewardBias", "baseline")),
		"recommendedBuildHint": str(node.get("recommendedBuildHint", "")),
		"is_boss": bool(node.get("isBoss", false)) or str(node.get("nodeType", "")) == "boss" or str(node.get("riskTier", "")) == "boss",
		"is_event": bool(node.get("isEvent", false)) or str(node.get("riskTier", "")) == "event"
	}
