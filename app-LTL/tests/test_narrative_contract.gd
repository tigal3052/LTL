extends RefCounted

const ReleaseContentVocabScript = preload("res://src/vocabulary/ReleaseContentVocab.gd")
const SelectNarrativeBeatScript = preload("res://src/vocabulary/narrative/SelectNarrativeBeat.gd")
const MarkNarrativeSeenScript = preload("res://src/vocabulary/narrative/MarkNarrativeSeen.gd")
const NarrativeReadModelScript = preload("res://src/ui/read_models/NarrativeReadModel.gd")
const BuildNarrativeTelemetryScript = preload("res://src/vocabulary/narrative/BuildNarrativeTelemetry.gd")

var failures: Array[String] = []

func run_all_tests() -> Dictionary:
	failures.clear()
	test_intro_contract_selects_only_first_node_select()
	test_seen_once_beat_does_not_repeat()
	test_mark_seen_updates_progress_only()
	test_failure_and_clear_match_run_complete_scene()
	test_narrative_projection_does_not_change_domain_snapshot()
	test_narrative_read_model_projects_locale_text()
	test_narrative_read_model_projects_toast_visual_metadata()
	test_narrative_telemetry_payloads_have_required_fields()
	return {"ok": failures.is_empty(), "errors": failures}

func test_intro_contract_selects_only_first_node_select() -> void:
	var beat: Dictionary = SelectNarrativeBeatScript.select({"phase": "node_select", "stageIndex": 0}, _beats(), {})
	_assert_eq(str(beat.get("id", "")), "intro_contract", "intro contract selected on first node select")
	var later: Dictionary = SelectNarrativeBeatScript.select({"phase": "node_select", "stageIndex": 1}, _beats(), {})
	_assert_eq(later.is_empty(), true, "intro contract does not select on later stages")

func test_seen_once_beat_does_not_repeat() -> void:
	var beat: Dictionary = SelectNarrativeBeatScript.select({"phase": "node_select", "stageIndex": 0}, _beats(), {"intro_contract": true})
	_assert_eq(beat.is_empty(), true, "seen shown-once beat does not repeat")

func test_mark_seen_updates_progress_only() -> void:
	var progress := {"clearedLeviathanIds": ["ossuary_tortoise"]}
	var next: Dictionary = MarkNarrativeSeenScript.mark_seen(progress, "intro_contract")
	_assert_eq(next.get("clearedLeviathanIds", []), ["ossuary_tortoise"], "mark seen preserves cleared ids")
	_assert(next.get("narrativeSeenBeatIds", []).has("intro_contract"), "mark seen stores beat id")
	_assert_eq(progress.has("narrativeSeenBeatIds"), false, "mark seen does not mutate original progress")

func test_failure_and_clear_match_run_complete_scene() -> void:
	var failed: Dictionary = SelectNarrativeBeatScript.select({"phase": "run_complete", "failed": true}, _beats(), {})
	_assert_eq(str(failed.get("id", "")), "first_failure", "failure beat selects on failed run_complete")
	var cleared: Dictionary = SelectNarrativeBeatScript.select({"phase": "run_complete", "failed": false, "runComplete": true}, _beats(), {})
	_assert_eq(str(cleared.get("id", "")), "first_clear", "clear beat selects on successful run_complete")

func test_narrative_projection_does_not_change_domain_snapshot() -> void:
	var state := {"phase": "node_select", "stageIndex": 0, "candidates": [{"id": "normal"}], "progress": {}}
	var before := state.duplicate(true)
	var beat: Dictionary = SelectNarrativeBeatScript.select(state, _beats(), {})
	_assert(not beat.is_empty(), "narrative beat selected for invariance test")
	_assert_eq(state, before, "narrative selection does not mutate state")

func test_narrative_read_model_projects_locale_text() -> void:
	var beat: Dictionary = SelectNarrativeBeatScript.select({"phase": "node_select", "stageIndex": 0}, _beats(), {})
	var model: Dictionary = NarrativeReadModelScript.project(beat, "en")
	_assert_eq(bool(model.get("visible", false)), true, "narrative read model is visible for selected beat")
	_assert_eq(str(model.get("beatId", "")), "intro_contract", "narrative read model exposes beat id")
	_assert(str(model.get("text", "")).contains("does not hunt"), "narrative read model projects English text")

# 실행: verify toast-specific metadata reaches the read model without changing narrative selection.
func test_narrative_read_model_projects_toast_visual_metadata() -> void:
	var beat: Dictionary = SelectNarrativeBeatScript.select({"phase": "node_select", "stageIndex": 0}, _beats(), {})
	var model: Dictionary = NarrativeReadModelScript.project(beat, "ko")
	_assert_eq(str(model.get("anchorPreset", "")), "bottom_center", "narrative read model exposes anchor preset")
	_assert_eq(str(model.get("toastVariant", "")), "operation_log", "narrative read model exposes toast variant")
	_assert(str(model.get("portraitPath", "")).ends_with(".png"), "narrative read model exposes portrait path")
	_assert(str(model.get("visualPath", "")).ends_with(".png"), "narrative read model exposes visual path")
	_assert_eq(str(model.get("portraitSide", "")), "left", "narrative read model exposes portrait side")

func test_narrative_telemetry_payloads_have_required_fields() -> void:
	var payload: Dictionary = BuildNarrativeTelemetryScript.build_shown("intro_contract", "node_select", "node_select", true, 2400, false)
	_assert_eq(str(payload.get("event", "")), "narrative_beat_shown", "shown telemetry event name")
	for key in ["beat_id", "screen_id", "trigger_phase", "shown_once", "display_duration_ms", "skip_input"]:
		_assert(payload.has(key), "shown telemetry has %s" % key)

func _beats() -> Array:
	return ReleaseContentVocabScript.load_content_bundle().get("narrativeBeats", [])

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
