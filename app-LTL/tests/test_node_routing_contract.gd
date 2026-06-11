# 계약:
# - 책임: M4 node routing contract가 deterministic offer, final boss, selected modifier, read-model projection을 보장하는지 검증한다.
# - 입력: formal node table, HeadlessMiniRun snapshot, SceneReadModel projection.
# - 출력: run_all_tests 결과 Dictionary.
# - 금지: SceneTree 의존, prototype runtime 의존, node generator private pool 호출.
#
# 실행: define the TestNodeRoutingContract class.
extends RefCounted

const HeadlessMiniRunScript = preload("res://src/process/HeadlessMiniRun.gd")
const NodeVocabScript = preload("res://src/vocabulary/NodeVocab.gd")
const FormalContractsScript = preload("res://src/domain/FormalContracts.gd")
const SceneReadModelScript = preload("res://src/ui/SceneReadModel.gd")
const NodeSelectReadModelScript = preload("res://src/ui/read_models/NodeSelectReadModel.gd")

var failures: Array[String] = []

# 실행: run every node routing contract test and return aggregate status.
func run_all_tests() -> Dictionary:
	failures.clear()
	test_candidates_are_deterministic_and_include_safe_route()
	test_final_stage_locks_to_boss_candidate_only()
	test_selected_node_modifiers_reach_combat_snapshot()
	test_selected_node_uses_documented_durability_curve()
	test_route_history_persists_selected_nodes_across_stage_advances()
	test_route_history_persists_selected_route_slots()
	test_scene_read_model_projects_route_fields_without_pick_weights()
	test_stage_durability_curve_matches_documented_targets()
	test_offered_candidates_share_documented_stage_durability()
	test_mysterious_crevice_fixture_has_nonzero_combat_stats()
	test_node_validator_requires_route_fields()
	return {"ok": failures.is_empty(), "errors": failures}

# 실행: verify same seed and stage produce the same node candidates with normal included.
func test_candidates_are_deterministic_and_include_safe_route() -> void:
	var tuning := {"nodeRouting": {"minCandidates": 3, "maxCandidates": 5}}
	var first := NodeVocabScript.generate_candidates(404, 1, _node_table(), 4, tuning)
	var second := NodeVocabScript.generate_candidates(404, 1, _node_table(), 4, tuning)
	_assert_eq(_ids(first), _ids(second), "node routing deterministic candidate ids")
	_assert(first.size() >= 3 and first.size() <= 5, "node routing candidate count stays in tuning range")
	_assert(_contains_id(first, "normal"), "node routing includes normal safe candidate")
	_assert(first[0].has("routeHash"), "node routing candidate includes route hash")
	_assert(first[0].has("finalStageDistance"), "node routing candidate includes final stage distance")

# 실행: verify the final stage locks to the boss route only.
func test_final_stage_locks_to_boss_candidate_only() -> void:
	var candidates := NodeVocabScript.generate_candidates(11, 2, _node_table(), 4, {"maxStages": 3, "nodeRouting": {"minCandidates": 3, "maxCandidates": 4}})
	_assert_eq(candidates.size(), 1, "final stage locks to exactly one boss candidate")
	_assert_eq(candidates[0].get("id", ""), "boss_spine", "final stage pins boss candidate first")
	_assert_eq(candidates[0].get("nodeType", ""), "boss", "final stage boss candidate type")
	_assert_eq(candidates[0].get("finalStageDistance", -1), 0, "boss final stage distance is zero")

# 실행: verify selected node modifiers become explicit combat metadata.
func test_selected_node_modifiers_reach_combat_snapshot() -> void:
	var run = HeadlessMiniRunScript.new({"seed": 19, "maxStages": 3, "candidateCount": 5, "nodeTable": _node_table(), "tuning": {"stageScaling": {"baseShield": 4.0, "baseHealth": 4.0}}})
	var initial: Dictionary = run.snapshot()
	var hazard_index := _index_of_type(initial["candidates"], "hazard_rich")
	_assert(hazard_index >= 0, "hazard rich candidate is offered")
	var combat: Dictionary = run.select_node(hazard_index)
	_assert_eq(combat["phase"], "combat", "hazard node selection enters combat")
	_assert_eq(combat["combat"]["node"]["nodeType"], "hazard_rich", "combat snapshot keeps selected node type")
	_assert(float(combat["combat"]["node"]["difficultyModifier"]) > 1.0, "combat snapshot keeps difficulty modifier")
	_assert(float(combat["combat"]["rewardModifier"]) > 1.0, "combat snapshot keeps reward modifier")
	_assert(float(combat["combat"]["hazard"]["modifier"]) > 1.0, "combat snapshot keeps hazard modifier")
	_assert_eq(combat["combat"]["telemetry"]["event"], "node_modifier_applied", "combat snapshot includes node modifier telemetry")

# 실행: verify the actual selected combat path uses the documented stage-one durability.
func test_selected_node_uses_documented_durability_curve() -> void:
	var run = HeadlessMiniRunScript.new({"seed": 19, "maxStages": 5, "candidateCount": 5, "nodeTable": _node_table()})
	var initial: Dictionary = run.snapshot()
	var hazard_index := _index_of_type(initial["candidates"], "hazard_rich")
	_assert(hazard_index >= 0, "hazard rich candidate is offered for selected durability test")
	if hazard_index < 0:
		return
	var combat: Dictionary = run.select_node(hazard_index)
	_assert_eq(combat["phase"], "combat", "selected durability test enters combat")
	_assert(absf(float(combat["combat"].get("shield", 0.0)) - 28.0) <= 0.05, "selected combat shield matches doubled stage one table")
	_assert(absf(float(combat["combat"].get("health", 0.0)) - 36.0) <= 0.05, "selected combat health matches doubled stage one table")
	_assert(absf(float(combat["combat"].get("maxShield", 0.0)) - 28.0) <= 0.05, "selected combat max shield matches doubled stage one table")
	_assert(absf(float(combat["combat"].get("maxHealth", 0.0)) - 36.0) <= 0.05, "selected combat max health matches doubled stage one table")

# 실행: verify cleared routes persist as history and future unexplored stages stay projected as unknown markers.
func test_route_history_persists_selected_nodes_across_stage_advances() -> void:
	var run = HeadlessMiniRunScript.new({"seed": 73, "maxStages": 5, "candidateCount": 5, "nodeTable": _node_table()})
	var stage_one_snapshot: Dictionary = run.snapshot()
	_assert_eq(stage_one_snapshot.get("routeHistory", []).size(), 0, "stage-one snapshot starts without prior route history")
	var stage_one_label := str(stage_one_snapshot["candidates"][0].get("label", ""))

	run.select_node(0)
	run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	var stage_two_snapshot: Dictionary = run.claim_rewards()
	var stage_two_history: Array = stage_two_snapshot.get("routeHistory", [])
	_assert_eq(stage_two_snapshot["phase"], "node_select", "claiming the stage-one clear returns to node select")
	_assert_eq(stage_two_snapshot["stageIndex"], 1, "claiming the stage-one clear advances to stage two")
	_assert_eq(stage_two_history.size(), 1, "stage-two snapshot keeps the cleared stage-one route in history")
	if not stage_two_history.is_empty():
		_assert_eq(str(stage_two_history[0].get("label", "")), stage_one_label, "stage-two history keeps the cleared stage-one label")

	var stage_two_choice_index := mini(2, stage_two_snapshot.get("candidates", []).size() - 1)
	_assert(stage_two_choice_index >= 0, "stage-two snapshot exposes selectable route candidates for history tracking")
	if stage_two_choice_index < 0:
		return
	var stage_two_label := str(stage_two_snapshot["candidates"][stage_two_choice_index].get("label", ""))
	run.select_node(stage_two_choice_index)
	run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	var stage_three_snapshot: Dictionary = run.claim_rewards()
	var stage_three_history: Array = stage_three_snapshot.get("routeHistory", [])
	_assert_eq(stage_three_snapshot["phase"], "node_select", "claiming the stage-two clear returns to node select")
	_assert_eq(stage_three_snapshot["stageIndex"], 2, "claiming the stage-two clear advances to stage three")
	_assert_eq(stage_three_history.size(), 2, "stage-three snapshot keeps both cleared routes in history")
	if stage_three_history.size() >= 1:
		_assert_eq(str(stage_three_history[0].get("label", "")), stage_one_label, "stage-three history keeps the cleared stage-one label")
	if stage_three_history.size() >= 2:
		_assert_eq(str(stage_three_history[1].get("label", "")), stage_two_label, "stage-three history keeps the cleared stage-two label")

	var scene := SceneReadModelScript.new().create(stage_three_snapshot)
	_assert_eq(scene.get("routeHistory", []).size(), 2, "scene read model projects cleared node history")
	_assert_eq(int(scene.get("futureUnknownCount", -1)), 1, "scene read model keeps one unexplored non-boss stage hidden behind a ? marker at stage three")

func test_route_history_persists_selected_route_slots() -> void:
	var run = HeadlessMiniRunScript.new({"seed": 73, "maxStages": 5, "candidateCount": 5, "nodeTable": _node_table()})
	run.select_node(0)
	run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	var stage_two_snapshot: Dictionary = run.claim_rewards()
	var selected_slot := mini(3, stage_two_snapshot.get("candidates", []).size() - 1)
	_assert(selected_slot >= 0, "stage-two snapshot exposes a route slot for persistence checks")
	if selected_slot < 0:
		return
	run.select_node(selected_slot)
	run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	var stage_three_snapshot: Dictionary = run.claim_rewards()
	var route_history: Array = stage_three_snapshot.get("routeHistory", [])
	_assert_eq(route_history.size(), 2, "route-slot persistence snapshot keeps two cleared entries")
	if route_history.size() >= 2:
		_assert_eq(int(route_history[1].get("routeSlotIndex", -1)), selected_slot, "route history keeps the selected branch slot index")
	var scene := SceneReadModelScript.new().create(stage_three_snapshot)
	var projected_history: Array = scene.get("routeHistory", [])
	if projected_history.size() >= 2:
		_assert_eq(int(projected_history[1].get("routeSlotIndex", -1)), selected_slot, "scene read model keeps the selected branch slot index")

# 실행: verify scene and text read models expose readable route fields but hide raw pick weights.
func test_scene_read_model_projects_route_fields_without_pick_weights() -> void:
	var run = HeadlessMiniRunScript.new({"seed": 31, "maxStages": 3, "candidateCount": 4, "nodeTable": _node_table()})
	var scene := SceneReadModelScript.new().create(run.snapshot())
	_assert(scene["candidates"].size() >= 3, "scene read model exposes node candidates")
	var candidate: Dictionary = scene["candidates"][0]
	_assert(candidate.has("nodeType"), "scene candidate exposes node type")
	_assert(candidate.has("riskTier"), "scene candidate exposes risk tier")
	_assert(candidate.has("rewardBias"), "scene candidate exposes reward bias")
	_assert(candidate.has("recommendedBuildHint"), "scene candidate exposes build hint")
	_assert(not candidate.has("pickWeight"), "scene candidate hides pick weight")
	var text: String = str(NodeSelectReadModelScript.project({"nodeSelect": {"candidates": scene["candidates"]}}, 0)["text"])
	_assert(str(text).contains("위험:"), "node select text includes risk")
	_assert(str(text).contains("보상:"), "node select text includes non-baseline reward bias")

# 실행: verify the five-stage durability curve follows the documented balance formula.
func test_stage_durability_curve_matches_documented_targets() -> void:
	var expected_totals := [64.0, 108.0, 156.0, 200.0, 240.0]
	var expected_shields := [28.0, 46.0, 70.0, 94.0, 116.0]
	var expected_health := [36.0, 62.0, 86.0, 106.0, 124.0]
	for stage_index in range(expected_totals.size()):
		var candidates := NodeVocabScript.generate_candidates(101, stage_index, _normal_only_table(), 1, {"maxStages": 5})
		_assert(candidates.size() >= 1, "durability curve candidate exists for stage %d" % stage_index)
		if candidates.is_empty():
			continue
		var combat: Dictionary = candidates[0].get("combat", {})
		var total := float(combat.get("shield", 0.0)) + float(combat.get("health", 0.0))
		_assert(absf(total - expected_totals[stage_index]) <= 1.0, "stage %d durability total near %.1f, got %.2f" % [stage_index + 1, expected_totals[stage_index], total])
		_assert(absf(float(combat.get("shield", 0.0)) - expected_shields[stage_index]) <= 0.05, "stage %d shield matches documented table" % [stage_index + 1])
		_assert(absf(float(combat.get("health", 0.0)) - expected_health[stage_index]) <= 0.05, "stage %d health matches documented table" % [stage_index + 1])

# 실행: verify route labels and rewards differ without changing the documented displayed durability table.
func test_offered_candidates_share_documented_stage_durability() -> void:
	var candidates := NodeVocabScript.generate_candidates(101, 0, _node_table(), 5, {"maxStages": 5, "nodeRouting": {"minCandidates": 5, "maxCandidates": 5}})
	_assert(candidates.size() >= 3, "rich node table offers multiple candidates")
	for candidate in candidates:
		var combat: Dictionary = candidate.get("combat", {})
		_assert(absf(float(combat.get("shield", 0.0)) - 28.0) <= 0.05, "candidate %s shield matches doubled stage one table" % str(candidate.get("id", "")))
		_assert(absf(float(combat.get("health", 0.0)) - 36.0) <= 0.05, "candidate %s health matches doubled stage one table" % str(candidate.get("id", "")))

# 실행: verify the mysterious crevice route cannot clear from zero health/shield.
func test_mysterious_crevice_fixture_has_nonzero_combat_stats() -> void:
	var node := _find_node(_node_table(), "mysterious_crevice")
	_assert(not node.is_empty(), "mysterious crevice exists")
	_assert(float(node.get("shieldMul", 0.0)) > 0.0, "mysterious crevice shield multiplier is nonzero")
	_assert(float(node.get("healthMul", 0.0)) > 0.0, "mysterious crevice health multiplier is nonzero")

# 실행: verify formal node validation rejects missing M4 route fields.
func test_node_validator_requires_route_fields() -> void:
	var contracts = FormalContractsScript.new()
	var validation := contracts.validate_node_table({"nodes": [{"id": "normal", "label": "Normal Node", "weakness": ["red"], "pickWeight": 1, "shieldMul": 1, "healthMul": 1, "alwaysOffer": true}]})
	_assert_eq(validation["ok"], false, "node validator rejects missing M4 route fields")
	_assert_eq(validation["errors"][0]["path"], "nodes[0].nodeType", "node validator reports missing nodeType first")

# 실행: return a rich node table fixture for M4 routing tests.
func _node_table() -> Dictionary:
	return {"nodes": [
		{"id": "normal", "label": "Safe Scar", "nodeType": "normal", "riskTier": "safe", "weakness": ["red"], "pickWeight": 10, "shieldMul": 1.0, "healthMul": 1.0, "alwaysOffer": true, "rewardBias": "baseline", "recommendedBuildHint": "Any stable drill line", "difficultyModifier": 1.0, "rewardModifier": 1.0, "hazardModifier": 1.0},
		{"id": "red_vein", "label": "Red Vein", "nodeType": "weakness_red", "riskTier": "medium", "weakness": ["red"], "pickWeight": 8, "shieldMul": 1.1, "healthMul": 1.0, "rewardBias": "red_energy", "recommendedBuildHint": "Red pulse drill", "difficultyModifier": 1.05, "rewardModifier": 1.1, "hazardModifier": 1.0},
		{"id": "mixed_fault", "label": "Mixed Fault", "nodeType": "mixed_weakness", "riskTier": "hard", "weakness": ["blue", "purple"], "pickWeight": 6, "shieldMul": 1.35, "healthMul": 1.25, "rewardBias": "multi_energy", "recommendedBuildHint": "Blue or purple coverage", "difficultyModifier": 1.25, "rewardModifier": 1.25, "hazardModifier": 1.1},
		{"id": "hazard_rich", "label": "Hazard Rich", "nodeType": "hazard_rich", "riskTier": "danger", "weakness": ["green"], "pickWeight": 20, "shieldMul": 1.2, "healthMul": 1.2, "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "difficultyModifier": 1.3, "rewardModifier": 1.35, "hazardModifier": 1.5},
		{"id": "repair_event", "label": "Repair Event", "nodeType": "repair_event", "riskTier": "support", "weakness": ["blue"], "pickWeight": 3, "shieldMul": 0.8, "healthMul": 0.8, "isEvent": true, "rewardBias": "repair", "recommendedBuildHint": "Stabilize damaged route", "difficultyModifier": 0.85, "rewardModifier": 0.9, "hazardModifier": 0.75},
		{"id": "mysterious_crevice", "label": "Mysterious Crevice", "nodeType": "mysterious_crevice", "riskTier": "unknown", "weakness": [], "pickWeight": 5, "shieldMul": 0.75, "healthMul": 0.75, "isEvent": true, "rewardBias": "mystery", "recommendedBuildHint": "Short volatile encounter", "difficultyModifier": 0.85, "rewardModifier": 1.2, "hazardModifier": 0.9},
		{"id": "boss_spine", "label": "Spine Anchor", "nodeType": "boss", "riskTier": "boss", "weakness": ["red", "blue", "purple"], "pickWeight": 1, "shieldMul": 1.6, "healthMul": 1.8, "isBoss": true, "rewardBias": "run_clear", "recommendedBuildHint": "Bring mixed coverage", "difficultyModifier": 1.7, "rewardModifier": 1.8, "hazardModifier": 1.4}
	]}

# 실행: return only the normal route so base durability is measured without route multipliers.
func _normal_only_table() -> Dictionary:
	return {"nodes": [
		{"id": "normal", "label": "Safe Scar", "nodeType": "normal", "riskTier": "safe", "weakness": ["red"], "pickWeight": 10, "shieldMul": 1.0, "healthMul": 1.0, "alwaysOffer": true, "rewardBias": "baseline", "recommendedBuildHint": "Any stable drill line", "difficultyModifier": 1.0, "rewardModifier": 1.0, "hazardModifier": 1.0}
	]}

# 실행: collect candidate identifiers.
func _ids(candidates: Array) -> Array:
	var result := []
	for candidate in candidates:
		result.append(str(candidate.get("id", "")))
	return result

# 실행: check whether candidates include the requested id.
func _contains_id(candidates: Array, id: String) -> bool:
	return _ids(candidates).has(id)

# 실행: find the first candidate with the requested node type.
func _index_of_type(candidates: Array, node_type: String) -> int:
	for index in range(candidates.size()):
		if str(candidates[index].get("nodeType", "")) == node_type:
			return index
	return -1

# 실행: find a node fixture by id.
func _find_node(table: Dictionary, id: String) -> Dictionary:
	for node in table.get("nodes", []):
		if str(node.get("id", "")) == id:
			return node
	return {}

# 실행: append a failure label when condition is false.
func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

# 실행: append a deterministic equality failure label when values differ.
func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
