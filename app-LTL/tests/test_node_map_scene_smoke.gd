# Contract:
# - Responsibility: verify the M4 node map scene consumes read-model data and input adapters produce phase events.
# - Input: scene-safe node candidate dictionaries and selected candidate index.
# - Output: aggregate smoke-test result dictionary.
# - Prohibited: direct node generation, HeadlessMiniRun mutation, prototype runtime dependencies.
#
# Execute: define the TestNodeMapSceneSmoke class.
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

var failures: Array[String] = []

func run_all_tests() -> Dictionary:
	failures.clear()
	TextCatalogScript.set_locale("ko")
	test_node_input_adapter_normalizes_selection_events()
	test_node_map_read_model_projects_cards_and_status()
	test_node_map_scene_renders_supplied_read_model_without_generator()
	return {"ok": failures.is_empty(), "errors": failures}

func test_node_input_adapter_normalizes_selection_events() -> void:
	var AdapterScript = load("res://src/process/NodeInputAdapter.gd")
	_assert(AdapterScript != null, "node input adapter script loads")
	if AdapterScript == null:
		return
	var adapter = AdapterScript.new()
	_assert_eq(adapter.choose_node(2), {"type": "select_node", "index": 2}, "node input adapter emits select_node event")
	_assert_eq(adapter.choose_node(-1), {"type": "invalid_node_selection", "index": -1}, "node input adapter rejects negative index")

func test_node_map_read_model_projects_cards_and_status() -> void:
	var ReadModelScript = load("res://src/ui/read_models/NodeMapReadModel.gd")
	_assert(ReadModelScript != null, "node map read model script loads")
	if ReadModelScript == null:
		return
	var model: Dictionary = ReadModelScript.project(_scene(), 1)
	_assert_eq(model["selectedIndex"], 1, "node map read model keeps selected index")
	_assert_eq(model["stageText"], "스테이지 2 / 3", "node map read model stage text")
	_assert_eq(model["cards"].size(), 2, "node map read model projects cards")
	_assert_eq(model["cards"][1]["selected"], true, "node map read model marks selected card")
	_assert_eq(model["cards"][1]["riskTier"], "danger", "node map read model exposes risk tier")
	_assert_eq(model["cards"][1]["finalStageDistance"], 1, "node map read model exposes final stage distance")
	_assert(model["telemetry"]["event"] == "node_map_rendered", "node map read model emits render telemetry")
	_assert(not model["cards"][0].has("pickWeight"), "node map read model hides pick weights")

func test_node_map_scene_renders_supplied_read_model_without_generator() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	var SceneResource = load("res://src/scenes/node_map/NodeMapScene.tscn")
	_assert(SceneScript != null, "node map scene script loads")
	_assert(SceneResource != null, "node map scene resource loads")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	scene.render({
		"stageText": "스테이지 2 / 3",
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "red", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 1, "selected": true},
			{"label": "Hazard Rich", "weaknessLabel": "green", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "finalStageDistance": 1, "selected": false}
		]
	})
	_assert_eq(scene.card_count(), 2, "node map scene renders card count")
	_assert(str(scene.summary_text()).contains("위험 밀집지"), "node map scene summary includes localized card label")
	_assert(str(scene.summary_text()).contains("위험: 위험"), "node map scene summary includes localized risk")

func _scene() -> Dictionary:
	return {
		"stageIndex": 1,
		"maxStages": 3,
		"candidates": [
			{"id": "normal", "label": "Safe Scar", "weakness": ["red"], "weaknessLabel": "red", "nodeType": "normal", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 1, "routeHash": "31:1:normal", "pickWeight": 10},
			{"id": "hazard_rich", "label": "Hazard Rich", "weakness": ["green"], "weaknessLabel": "green", "nodeType": "hazard_rich", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "finalStageDistance": 1, "routeHash": "31:1:hazard_rich", "pickWeight": 20}
		]
	}

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
