extends SceneTree

const VerticalSliceRunnerScript = preload("res://src/process/VerticalSliceRunner.gd")
const TelemetryExportScript = preload("res://src/tools/TelemetryExport.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var runner = VerticalSliceRunnerScript.new()
	var exporter = TelemetryExportScript.new()
	var base_dir := ProjectSettings.globalize_path("res://../docs/evidence/m8-vertical-slice-2026-06-17")
	var seeds := [101, 202, 303]
	for index in range(seeds.size()):
		var seed_value := int(seeds[index])
		var result: Dictionary = runner.run_clear({"seed": seed_value})
		var output_dir := "%s/session_%02d_seed_%d" % [base_dir, index + 1, seed_value]
		var bundle: Dictionary = exporter.export_session_bundle(result, output_dir, {
			"sessionId": "m8-internal-%02d-seed-%d" % [index + 1, seed_value],
			"qaRunIndex": index + 1
		})
		_assert(bool(bundle.get("ok", false)), "telemetry export succeeds for seed %d" % seed_value)
		_assert((bundle.get("writtenFiles", []) as Array).has("%s/session_manifest.json" % output_dir), "session manifest written for seed %d" % seed_value)
	if failures.is_empty():
		print("M8_TELEMETRY_EXPORT_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
