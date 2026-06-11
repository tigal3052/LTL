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
	test_node_map_scene_exposes_map_page_controls()
	test_node_map_scene_reuses_start_color_panel_when_stage_gate_hides_it()
	test_node_map_scene_keeps_route_text_after_color_rerender()
	test_node_map_color_press_defers_signal_until_button_unlock()
	test_node_map_press_defers_selection_until_button_unlock()
	test_node_map_uses_visual_graph_instead_of_text_list()
	test_node_map_omits_core_marker_for_stage_choices()
	test_node_map_marks_selected_candidate_visually()
	test_node_map_spreads_candidates_without_overlap()
	test_node_map_centers_visual_content_within_canvas()
	test_node_map_keeps_all_node_buttons_inside_canvas_bounds()
	test_node_map_uses_live_canvas_width_for_centering()
	test_node_map_reserves_more_space_for_detail_panel()
	test_node_map_keeps_start_near_map_bottom()
	test_node_map_rerender_defers_old_button_destruction_until_frame_cleanup()
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
	_assert_eq(model["stageText"], TextCatalogScript.t("stage.label", [2, 3]), "node map read model stage text")
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
		"stageText": TextCatalogScript.t("stage.label", [2, 3]),
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "red", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 1, "selected": true},
			{"label": "Hazard Rich", "weaknessLabel": "green", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "finalStageDistance": 1, "selected": false}
		]
	})
	_assert_eq(scene.card_count(), 2, "node map scene renders card count")
	_assert(str(scene.node_button_text(1)).contains(TextCatalogScript.display_name("Hazard Rich")), "node map button includes localized card label")
	_assert(str(scene.node_button_text(1)).contains(TextCatalogScript.enum_label("risk", "danger")), "node map button includes localized risk")

func test_node_map_scene_exposes_map_page_controls() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	_assert(SceneScript != null, "node map scene script loads for page controls")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	scene.render({
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "green",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": true},
			{"label": "Hazard Rich", "weaknessLabel": "red", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "finalStageDistance": 4, "selected": false}
		]
	})
	_assert_eq(scene.loadout_color_count(), 4, "node map page renders four start color controls")
	_assert_eq(scene.map_node_count(), 2, "node map page renders clickable map nodes")
	_assert_eq(scene.map_page_root_name(), "NodeMapPageRoot", "node map page renders through a full-page layout root")
	_assert(not str(scene.summary_text()).contains("Hazard Rich"), "node map page summary does not dump the old route list")
	_assert(str(scene.node_button_text(0)).contains(TextCatalogScript.display_name("Safe Scar")), "node map page keeps route labels on map buttons")
	_assert(str(scene.detail_text()).contains("Safe Scar"), "node map page exposes selected route details")
	_assert(str(scene.summary_text()).contains(TextCatalogScript.t("color.green")), "node map page summary includes selected start color")

func test_node_map_scene_reuses_start_color_panel_when_stage_gate_hides_it() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	_assert(SceneScript != null, "node map scene script loads for start panel reuse")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	_assert(scene.has_method("start_color_panel_instance_id"), "node map exposes the start color panel identity for reuse regression tests")
	_assert(scene.has_method("start_color_panel_visible"), "node map exposes the start color panel visibility for gate regression tests")
	if not scene.has_method("start_color_panel_instance_id") or not scene.has_method("start_color_panel_visible"):
		scene.free()
		return
	var model := {
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "purple",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"allowStartColorSelection": true,
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": true}
		]
	}
	scene.render(model)
	var first_panel_id := int(scene.start_color_panel_instance_id())
	_assert_eq(scene.loadout_color_count(), 4, "stage one node map renders all four start color buttons")
	_assert_eq(bool(scene.start_color_panel_visible()), true, "stage one start color panel is visible")
	model["stageText"] = TextCatalogScript.t("stage.label", [2, 5])
	model["allowStartColorSelection"] = false
	scene.render(model)
	_assert_eq(int(scene.start_color_panel_instance_id()), first_panel_id, "stage two node map reuses the same start color panel object")
	_assert_eq(scene.loadout_color_count(), 0, "stage two hides start color buttons without changing the page object")
	_assert_eq(bool(scene.start_color_panel_visible()), false, "stage two only hides the start color panel")
	_assert(not str(scene.summary_text()).contains("Selected Start Color"), "stage two summary omits starter color copy while keeping the same node map")
	scene.free()

func test_node_map_scene_keeps_route_text_after_color_rerender() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	_assert(SceneScript != null, "node map scene script loads for color rerender")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	var model := {
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "red",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": true},
			{"label": "Hazard Rich", "weaknessLabel": "red", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "finalStageDistance": 4, "selected": false}
		]
	}
	scene.render(model)
	model["selectedColor"] = "blue"
	scene.render(model)
	_assert_eq(scene.map_node_count(), 2, "node map keeps map nodes after color rerender")
	_assert(str(scene.node_button_text(0)).contains(TextCatalogScript.display_name("Safe Scar")), "node map keeps selected node text after color rerender")
	_assert(str(scene.detail_text()).contains("Safe Scar"), "node map keeps selected route detail after color rerender")
	_assert(str(scene.summary_text()).contains(TextCatalogScript.t("color.blue")), "node map updates selected color summary")
	_assert_eq(scene.card_count(), 2, "node map does not keep queued stale route buttons after color rerender")
	_assert_eq(scene.loadout_color_count(), 4, "node map does not keep queued stale color buttons after color rerender")

func test_node_map_color_press_defers_signal_until_button_unlock() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	_assert(SceneScript != null, "node map scene script loads for deferred color press")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	var emitted: Array = []
	scene.color_selected.connect(func(color): emitted.append(color))
	scene.render({
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "red",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": true}
		]
	})
	scene.press_color_button(1)
	_assert_eq(emitted.size(), 0, "color button press defers color_selected until pressed signal unlocks")

func test_node_map_press_defers_selection_until_button_unlock() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	_assert(SceneScript != null, "node map scene script loads for deferred node press")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	var emitted: Array = []
	scene.node_selected.connect(func(index): emitted.append(index))
	scene.render({
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "red",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": true}
		]
	})
	scene.press_node_button(0)
	_assert_eq(emitted.size(), 0, "node press defers node_selected until pressed signal unlocks")

func test_node_map_uses_visual_graph_instead_of_text_list() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	_assert(SceneScript != null, "node map scene script loads for graph layout")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	scene.render({
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "purple",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": true},
			{"label": "Hazard Rich", "weaknessLabel": "red", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "finalStageDistance": 4, "selected": false},
			{"label": "Mysterious Crevice", "weaknessLabel": "", "riskTier": "unknown", "rewardBias": "mystery", "recommendedBuildHint": "Short volatile encounter", "finalStageDistance": 4, "selected": false}
		]
	})
	_assert_eq(scene.map_canvas_name(), "RunMapCanvas", "node map renders nodes inside a visual map canvas")
	_assert(scene.map_line_count() >= 3, "node map renders route connection lines")
	_assert(scene.node_button_text(0).length() <= 32, "node map node chips use compact labels")
	_assert(not str(scene.node_button_text(0)).contains("Durability"), "node map chip does not render long card text")
	_assert(not str(scene.node_button_text(0)).contains(TextCatalogScript.t("node.card.reward", [TextCatalogScript.enum_label("reward_bias", "baseline")]).strip_edges()), "node map chip does not render reward prose")

func test_node_map_omits_core_marker_for_stage_choices() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	_assert(SceneScript != null, "node map scene script loads for core marker omission")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	scene.render({
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "red",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": true},
			{"label": "Hazard Rich", "weaknessLabel": "red", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "finalStageDistance": 4, "selected": false},
			{"label": "Mysterious Crevice", "weaknessLabel": "", "riskTier": "unknown", "rewardBias": "mystery", "recommendedBuildHint": "Short volatile encounter", "finalStageDistance": 4, "selected": false},
			{"label": "Pulse Colony", "weaknessLabel": "blue", "riskTier": "medium", "rewardBias": "blue_energy", "recommendedBuildHint": "Blue pulse coverage", "finalStageDistance": 4, "selected": false},
			{"label": "Verdant Core", "weaknessLabel": "green", "riskTier": "medium", "rewardBias": "baseline", "recommendedBuildHint": "Any stable drill line", "finalStageDistance": 4, "selected": false}
		]
	})
	_assert_eq(scene.core_marker_present(), false, "node map keeps only the start anchor and five selectable nodes")

func test_node_map_marks_selected_candidate_visually() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	_assert(SceneScript != null, "node map scene script loads for selected marker")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	scene.render({
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "purple",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": false},
			{"label": "Hazard Rich", "weaknessLabel": "red", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "finalStageDistance": 4, "selected": true}
		]
	})
	_assert_eq(scene.node_button_selected_state(0), false, "unselected node is not marked selected")
	_assert_eq(scene.node_button_selected_state(1), true, "selected node is marked selected")
	_assert(not scene.node_button_text(0).begins_with("TARGET"), "unselected node chip has no selected target prefix")
	_assert(scene.node_button_text(1).begins_with("TARGET"), "selected node chip uses the target prefix")

func test_node_map_spreads_candidates_without_overlap() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	_assert(SceneScript != null, "node map scene script loads for candidate spacing")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	scene.render({
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "red",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": true},
			{"label": "Hazard Rich", "weaknessLabel": "red", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "finalStageDistance": 4, "selected": false},
			{"label": "Mysterious Crevice", "weaknessLabel": "", "riskTier": "unknown", "rewardBias": "mystery", "recommendedBuildHint": "Short volatile encounter", "finalStageDistance": 4, "selected": false},
			{"label": "Pulse Colony", "weaknessLabel": "blue", "riskTier": "medium", "rewardBias": "blue_energy", "recommendedBuildHint": "Blue pulse coverage", "finalStageDistance": 4, "selected": false},
			{"label": "Verdant Core", "weaknessLabel": "green", "riskTier": "medium", "rewardBias": "baseline", "recommendedBuildHint": "Any stable drill line", "finalStageDistance": 4, "selected": false}
		]
	})
	_assert_eq(scene.node_buttons_overlap(), false, "node map spreads candidate chips so they do not overlap")

func test_node_map_centers_visual_content_within_canvas() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	_assert(SceneScript != null, "node map scene script loads for centered layout")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	scene.render({
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "green",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": true},
			{"label": "Hazard Rich", "weaknessLabel": "red", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "finalStageDistance": 4, "selected": false},
			{"label": "Pulse Colony", "weaknessLabel": "blue", "riskTier": "medium", "rewardBias": "blue_energy", "recommendedBuildHint": "Blue pulse coverage", "finalStageDistance": 4, "selected": false}
		]
	})
	_assert(absf(scene.node_visual_center_x() - scene.map_canvas_center_x()) <= 24.0, "node map keeps the visual node cluster centered inside the panel canvas")

func test_node_map_keeps_all_node_buttons_inside_canvas_bounds() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	_assert(SceneScript != null, "node map scene script loads for button bounds")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	scene.render({
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "red",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": true},
			{"label": "Hazard Rich", "weaknessLabel": "red", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "finalStageDistance": 4, "selected": false},
			{"label": "Mysterious Crevice", "weaknessLabel": "", "riskTier": "unknown", "rewardBias": "mystery", "recommendedBuildHint": "Short volatile encounter", "finalStageDistance": 4, "selected": false},
			{"label": "Pulse Colony", "weaknessLabel": "blue", "riskTier": "medium", "rewardBias": "blue_energy", "recommendedBuildHint": "Blue pulse coverage", "finalStageDistance": 4, "selected": false},
			{"label": "Verdant Core", "weaknessLabel": "green", "riskTier": "medium", "rewardBias": "baseline", "recommendedBuildHint": "Any stable drill line", "finalStageDistance": 4, "selected": false}
		]
	})
	_assert(scene.node_leftmost_edge() >= 0.0, "node map keeps the leftmost node button inside the visible canvas")
	_assert(scene.node_rightmost_edge() <= scene.map_canvas_width(), "node map keeps the rightmost node button inside the visible canvas")

func test_node_map_uses_live_canvas_width_for_centering() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	_assert(SceneScript != null, "node map scene script loads for live canvas sizing")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	scene.set_map_canvas_test_size(Vector2(460, 300))
	scene.render({
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "red",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": true},
			{"label": "Hazard Rich", "weaknessLabel": "red", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "finalStageDistance": 4, "selected": false},
			{"label": "Mysterious Crevice", "weaknessLabel": "", "riskTier": "unknown", "rewardBias": "mystery", "recommendedBuildHint": "Short volatile encounter", "finalStageDistance": 4, "selected": false},
			{"label": "Pulse Colony", "weaknessLabel": "blue", "riskTier": "medium", "rewardBias": "blue_energy", "recommendedBuildHint": "Blue pulse coverage", "finalStageDistance": 4, "selected": false},
			{"label": "Verdant Core", "weaknessLabel": "green", "riskTier": "medium", "rewardBias": "baseline", "recommendedBuildHint": "Any stable drill line", "finalStageDistance": 4, "selected": false}
		]
	})
	_assert_eq(scene.map_canvas_width(), 460.0, "node map uses the actual narrow canvas width instead of a larger fallback")
	_assert(scene.node_rightmost_edge() <= scene.map_canvas_width(), "node map keeps right-side buttons clickable on a narrow live canvas")
	_assert(absf(scene.node_visual_center_x() - scene.map_canvas_center_x()) <= 18.0, "node map centers the visual cluster in the live canvas")

func test_node_map_reserves_more_space_for_detail_panel() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	_assert(SceneScript != null, "node map scene script loads for detail panel sizing")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	scene.render({
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "green",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": true}
		]
	})
	_assert_eq(scene.map_canvas_min_height(), 260.0, "node map upper panel is compact enough to remove the dead space under START")
	_assert_eq(scene.detail_panel_min_height(), 260.0, "node map reserves the freed space for readable node information")

func test_node_map_keeps_start_near_map_bottom() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	_assert(SceneScript != null, "node map scene script loads for start bottom gap")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	scene.render({
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "green",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": true},
			{"label": "Hazard Rich", "weaknessLabel": "red", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "finalStageDistance": 4, "selected": false}
		]
	})
	_assert(scene.has_method("start_marker_bottom_gap"), "node map exposes START-to-map-bottom gap for layout contract")
	if scene.has_method("start_marker_bottom_gap"):
		_assert(absf(float(scene.start_marker_bottom_gap()) - 20.0) <= 1.0, "START sits about 20px above the node graph panel bottom")

func test_node_map_rerender_defers_old_button_destruction_until_frame_cleanup() -> void:
	var SceneScript = load("res://src/scenes/node_map/NodeMapScene.gd")
	_assert(SceneScript != null, "node map scene script loads for deferred button destruction")
	if SceneScript == null:
		return
	var scene = SceneScript.new()
	var model := {
		"stageText": TextCatalogScript.t("stage.label", [1, 5]),
		"selectedColor": "red",
		"loadoutColors": ["red", "blue", "purple", "green"],
		"cards": [
			{"label": "Safe Scar", "weaknessLabel": "green", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": "Stable route", "finalStageDistance": 4, "selected": true},
			{"label": "Hazard Rich", "weaknessLabel": "red", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue", "finalStageDistance": 4, "selected": false}
		]
	}
	scene.render(model)
	_assert(scene._color_buttons.size() > 0, "node map exposes start-color buttons for deferred button destruction contract")
	_assert(scene._map_nodes.size() > 0, "node map exposes node buttons for deferred button destruction contract")
	if scene._color_buttons.is_empty() or scene._map_nodes.is_empty():
		return
	var old_color_button: Variant = scene._color_buttons[0]
	var old_node_button: Variant = scene._map_nodes[0]
	_assert(old_color_button is Button, "node map has an initial color button before rerender")
	_assert(old_node_button is Button, "node map has an initial node button before rerender")
	if not (old_color_button is Button) or not (old_node_button is Button):
		return
	model["selectedColor"] = "blue"
	model["cards"][0]["selected"] = false
	model["cards"][1]["selected"] = true
	scene.render(model)
	_assert(is_instance_valid(old_color_button), "rerender keeps replaced color buttons alive until deferred cleanup instead of freeing hovered controls immediately")
	_assert(is_instance_valid(old_node_button), "rerender keeps replaced node buttons alive until deferred cleanup instead of freeing hovered controls immediately")
	_assert_eq(scene.loadout_color_count(), 4, "rerender still rebuilds exactly four live color buttons")
	_assert_eq(scene.map_node_count(), 2, "rerender still rebuilds exactly two live node buttons")

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
