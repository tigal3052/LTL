# 계약: M8 replay batch and telemetry export expose deterministic three-seed evidence with a stable session manifest schema.
# 실행: run the M8 runner through the batch/export helpers and validate only their public dictionaries.
extends RefCounted

const ReplayBatchRunnerScript = preload("res://src/tools/ReplayBatchRunner.gd")
const TelemetryExportScript = preload("res://src/tools/TelemetryExport.gd")
const VerticalSliceRunnerScript = preload("res://src/process/VerticalSliceRunner.gd")

var failures: Array[String] = []

func run_all_tests() -> Dictionary:
	failures.clear()
	test_replay_batch_runs_three_representative_seeds()
	test_telemetry_export_schema_contains_session_manifest()
	return {"ok": failures.is_empty(), "errors": failures}

func test_replay_batch_runs_three_representative_seeds() -> void:
	var batch = ReplayBatchRunnerScript.new()
	var report: Dictionary = batch.run_m8_seed_batch({"seeds": [101, 202, 303]})
	_assert_eq(bool(report.get("ok", false)), true, "M8 replay batch succeeds")
	_assert_eq(int(report.get("seedCount", 0)), 3, "M8 replay batch counts three seeds")
	_assert_eq(report.get("failedSeeds", []).size(), 0, "M8 replay batch has no failed seeds")
	for item in report.get("results", []):
		_assert_eq(str(item.get("summary", {}).get("phase", "")), "run_complete", "M8 batch seed reaches run_complete")
		_assert_eq(bool(item.get("summary", {}).get("failed", true)), false, "M8 batch seed clears")

func test_telemetry_export_schema_contains_session_manifest() -> void:
	var runner = VerticalSliceRunnerScript.new()
	var clear_result: Dictionary = runner.run_clear({"seed": 404})
	var exporter = TelemetryExportScript.new()
	var bundle: Dictionary = exporter.build_session_bundle(clear_result, {"sessionId": "m8-schema-test", "qaRunIndex": 1})
	_assert_eq(bool(bundle.get("ok", false)), true, "M8 telemetry bundle builds")
	var files: Dictionary = bundle.get("files", {})
	for required_file in ["session_manifest.json", "run_summary.json", "events_combat.json", "events_reward.json", "events_route.json", "events_hazard.json", "events_ui.json", "events_narrative.json"]:
		_assert(files.has(required_file), "M8 telemetry bundle contains %s" % required_file)
	var manifest: Dictionary = bundle.get("manifest", {})
	_assert_eq(str(manifest.get("schemaVersion", "")), "m8.vertical_slice.telemetry.v1", "M8 telemetry manifest schema version")
	_assert_eq(str(manifest.get("leviathanId", "")), "ossuary_tortoise", "M8 telemetry manifest records Leviathan id")
	_assert_eq(int(manifest.get("stageCount", 0)), 3, "M8 telemetry manifest records three stages")
	for category in ["combat", "reward", "route", "hazard", "ui", "narrative"]:
		_assert(manifest.get("eventCategories", []).has(category), "M8 telemetry manifest lists %s category" % category)

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
