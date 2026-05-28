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
	test_final_stage_pins_boss_candidate_without_losing_safe_route()
	test_selected_node_modifiers_reach_combat_snapshot()
	test_scene_read_model_projects_route_fields_without_pick_weights()
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

# 실행: verify the final stage exposes a boss route and still keeps a normal fallback.
func test_final_stage_pins_boss_candidate_without_losing_safe_route() -> void:
	var candidates := NodeVocabScript.generate_candidates(11, 2, _node_table(), 4, {"maxStages": 3, "nodeRouting": {"minCandidates": 3, "maxCandidates": 4}})
	_assert_eq(candidates[0].get("id", ""), "boss_spine", "final stage pins boss candidate first")
	_assert_eq(candidates[0].get("nodeType", ""), "boss", "final stage boss candidate type")
	_assert(_contains_id(candidates, "normal"), "final stage keeps normal fallback")
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
