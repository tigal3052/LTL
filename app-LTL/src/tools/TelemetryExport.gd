# 怨꾩빟:
# - 책임: M8 vertical-slice 결과를 session manifest와 category별 telemetry JSON artifact로 변환한다.
# - 입력: VerticalSliceRunner result dictionary, optional session metadata and output directory.
# - 출력: manifest, run summary, event category files, optional disk export result.
# - 금지: telemetry schema 누락, runner state mutation, gameplay rule 계산.
#
# ?ㅽ뻾: define the M8 telemetry export helper class identity.
class_name TelemetryExport
extends RefCounted

const SCHEMA_VERSION := "m8.vertical_slice.telemetry.v1"
const EVENT_CATEGORIES := ["combat", "reward", "route", "hazard", "ui", "narrative"]

# ?ㅽ뻾: build an in-memory telemetry artifact bundle with stable file names.
func build_session_bundle(run_result: Dictionary, options: Dictionary = {}) -> Dictionary:
	var summary: Dictionary = run_result.get("summary", {}).duplicate(true) if run_result.get("summary", {}) is Dictionary else {}
	var telemetry: Dictionary = _normalized_events(run_result.get("telemetry", {}))
	var manifest := {
		"schemaVersion": SCHEMA_VERSION,
		"sessionId": str(options.get("sessionId", "m8-session-%d" % int(run_result.get("seed", 0)))),
		"qaRunIndex": int(options.get("qaRunIndex", 0)),
		"seed": int(run_result.get("seed", 0)),
		"leviathanId": str(summary.get("leviathanId", "ossuary_tortoise")),
		"stageCount": int(summary.get("stageCount", 3)),
		"runCount": int(summary.get("runCount", 1)),
		"ok": bool(run_result.get("ok", false)),
		"eventCategories": EVENT_CATEGORIES.duplicate(true),
		"files": _manifest_files()
	}
	var files := {
		"session_manifest.json": JSON.stringify(manifest, "\t"),
		"run_summary.json": JSON.stringify(summary, "\t")
	}
	for category in EVENT_CATEGORIES:
		files["events_%s.json" % category] = JSON.stringify(telemetry.get(category, []), "\t")
	return {
		"ok": bool(run_result.get("ok", false)) and _has_all_categories(telemetry),
		"manifest": manifest,
		"summary": summary,
		"events": telemetry,
		"files": files
	}

# ?ㅽ뻾: write telemetry artifacts to disk when an output directory is supplied.
func export_session_bundle(run_result: Dictionary, output_dir: String, options: Dictionary = {}) -> Dictionary:
	var bundle: Dictionary = build_session_bundle(run_result, options)
	if output_dir.is_empty():
		return bundle
	var make_result := DirAccess.make_dir_recursive_absolute(output_dir)
	if make_result != OK:
		bundle["ok"] = false
		bundle["diagnostics"] = [{"code": "output_dir_failed", "path": output_dir, "error": make_result}]
		return bundle
	var written: Array = []
	var files: Dictionary = bundle.get("files", {})
	for file_name in files.keys():
		var file_path := "%s/%s" % [output_dir.rstrip("/"), str(file_name)]
		var file := FileAccess.open(file_path, FileAccess.WRITE)
		if file == null:
			bundle["ok"] = false
			bundle["diagnostics"] = [{"code": "file_write_failed", "path": file_path}]
			return bundle
		file.store_string(str(files[file_name]))
		written.append(file_path)
	bundle["writtenFiles"] = written
	return bundle

# ?ㅽ뻾: coerce missing telemetry categories into empty arrays without hiding schema gaps.
func _normalized_events(raw_events: Variant) -> Dictionary:
	var source: Dictionary = raw_events if raw_events is Dictionary else {}
	var result := {}
	for category in EVENT_CATEGORIES:
		var value: Variant = source.get(category, [])
		result[category] = value.duplicate(true) if value is Array else []
	return result

# ?ㅽ뻾: list manifest file names in deterministic category order.
func _manifest_files() -> Array:
	var files := ["session_manifest.json", "run_summary.json"]
	for category in EVENT_CATEGORIES:
		files.append("events_%s.json" % category)
	return files

# ?ㅽ뻾: verify that every required event category exists.
func _has_all_categories(events: Dictionary) -> bool:
	for category in EVENT_CATEGORIES:
		if not events.has(category):
			return false
	return true
