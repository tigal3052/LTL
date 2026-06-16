extends RefCounted

const ReleaseContentVocabScript = preload("res://src/vocabulary/ReleaseContentVocab.gd")
const SelectStorySceneScript = preload("res://src/vocabulary/story/SelectStoryScene.gd")
const StoryHistoryScript = preload("res://src/models/StoryHistory.gd")
const StorySceneReadModelScript = preload("res://src/ui/read_models/StorySceneReadModel.gd")
const BuildStoryTelemetryScript = preload("res://src/vocabulary/story/BuildStoryTelemetry.gd")

var failures: Array[String] = []

# 실행: run focused contracts for VN story scene selection, progress, projection, and telemetry.
func run_all_tests() -> Dictionary:
	failures.clear()
	test_intro_story_selects_after_character_confirm()
	test_seen_once_story_does_not_repeat()
	test_mark_seen_updates_story_history_only()
	test_story_selection_does_not_mutate_scene()
	test_story_read_model_projects_first_step_and_return_page()
	test_story_telemetry_payloads_have_required_fields()
	return {"ok": failures.is_empty(), "errors": failures}

# 실행: verify the first story triggers at the safe meta transition after character selection.
func test_intro_story_selects_after_character_confirm() -> void:
	var scene: Dictionary = SelectStorySceneScript.select({"pageId": "leviathan_select", "phase": "node_select"}, _scenes(), {})
	_assert_eq(str(scene.get("id", "")), "intro_contract_vn", "intro VN story selects on leviathan select entry")
	_assert_eq(str(scene.get("returnPageId", "")), "leviathan_select", "intro VN returns to leviathan selection")

# 실행: verify shown-once story scenes honor storySeenSceneIds history.
func test_seen_once_story_does_not_repeat() -> void:
	var scene: Dictionary = SelectStorySceneScript.select({"pageId": "leviathan_select", "phase": "node_select"}, _scenes(), {"intro_contract_vn": true})
	_assert_eq(scene.is_empty(), true, "seen shown-once story scene does not repeat")

# 실행: verify story progress stays separate from narrative beat history and cleared ids.
func test_mark_seen_updates_story_history_only() -> void:
	var progress := {"clearedLeviathanIds": ["ossuary_tortoise"], "narrativeSeenBeatIds": ["intro_contract"]}
	var next: Dictionary = StoryHistoryScript.mark_seen(progress, "intro_contract_vn")
	_assert_eq(next.get("clearedLeviathanIds", []), ["ossuary_tortoise"], "story mark seen preserves cleared ids")
	_assert_eq(next.get("narrativeSeenBeatIds", []), ["intro_contract"], "story mark seen preserves narrative beat ids")
	_assert(next.get("storySeenSceneIds", []).has("intro_contract_vn"), "story mark seen stores story id")
	_assert_eq(progress.has("storySeenSceneIds"), false, "story mark seen does not mutate original progress")

# 실행: verify story selection is a pure projection over the scene snapshot.
func test_story_selection_does_not_mutate_scene() -> void:
	var state := {"pageId": "leviathan_select", "phase": "node_select", "progress": {}}
	var before := state.duplicate(true)
	var scene: Dictionary = SelectStorySceneScript.select(state, _scenes(), {})
	_assert(not scene.is_empty(), "story scene selected for purity test")
	_assert_eq(state, before, "story selection does not mutate state")

# 실행: verify read-model exposes a localized VN step and routing facts.
func test_story_read_model_projects_first_step_and_return_page() -> void:
	var scene: Dictionary = SelectStorySceneScript.select({"pageId": "leviathan_select", "phase": "node_select"}, _scenes(), {})
	var model: Dictionary = StorySceneReadModelScript.project(scene, 0, "en")
	_assert_eq(bool(model.get("visible", false)), true, "story read model visible for selected scene")
	_assert_eq(str(model.get("sceneId", "")), "intro_contract_vn", "story read model exposes scene id")
	_assert_eq(str(model.get("returnPageId", "")), "leviathan_select", "story read model exposes return page")
	_assert(str(model.get("text", "")).contains("contract"), "story read model projects English text")
	_assert(not str(model.get("portraitPath", "")).is_empty(), "story read model exposes portrait path")
	_assert(not str(model.get("backgroundPath", "")).is_empty(), "story read model exposes background path")

# 실행: verify story telemetry uses stable event names and required fields.
func test_story_telemetry_payloads_have_required_fields() -> void:
	var started: Dictionary = BuildStoryTelemetryScript.build_started("intro_contract_vn", "leviathan_select", 2)
	_assert_eq(str(started.get("event", "")), "story_scene_started", "story started telemetry event name")
	for key in ["scene_id", "return_page_id", "step_count"]:
		_assert(started.has(key), "story started telemetry has %s" % key)
	var step: Dictionary = BuildStoryTelemetryScript.build_step_shown("intro_contract_vn", 1, "Captain")
	_assert_eq(str(step.get("event", "")), "story_step_shown", "story step telemetry event name")
	for key in ["scene_id", "step_index", "speaker"]:
		_assert(step.has(key), "story step telemetry has %s" % key)

func _scenes() -> Array:
	return ReleaseContentVocabScript.load_content_bundle().get("storyScenes", [])

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
