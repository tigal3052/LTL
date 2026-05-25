# 계약:
# - 책임: formal replay fixture 세트를 headless Godot에서 일괄 실행하는 smoke verification entrypoint 경계를 제공한다.
# - 입력: fixture selection policy, optional seed override policy, ReplayProcess public API.
# - 출력: machine-readable aggregate verdict와 fixture별 summary를 제공하는 headless tool contract.
# - 금지: replay rule을 중복 구현하거나 scene preview 실행, prototype fixture 임의 변경을 하지 않는다.
#
# 실행: define the formal replay runner class identity.
class_name FormalReplayRunner
extends RefCounted

# 실행: preload replay process used for each fixture.
const ReplayProcessScript = preload("res://src/process/ReplayProcess.gd")

# 실행: run all selected fixture paths and aggregate fixture verdicts.
func run_all(options: Dictionary = {}) -> Dictionary:
	var process = ReplayProcessScript.new()
	var fixture_paths: Array = options.get("fixturePaths", _default_fixture_paths())
	var results: Array = []
	var failing: Array = []
	for fixture_path in fixture_paths:
		var result: Dictionary = process.run_replay_file(String(fixture_path))
		var item := {"fixturePath": fixture_path, "ok": bool(result.get("summary", {}).get("ok", false)), "phase": result.get("summary", {}).get("phase", "unknown"), "diagnosticCount": result.get("diagnostics", []).size(), "traceCount": result.get("trace", []).size()}
		results.append(item)
		if not item["ok"]:
			failing.append(item)
	return {"ok": failing.is_empty(), "fixtureCount": results.size(), "failingFixtures": failing, "results": results}

# 실행: discover prototype replay fixture JSON files in deterministic name order.
func _default_fixture_paths() -> Array:
	var base := "res://prototype/browser-p0-p4/tests/fixtures/input_logs"
	var dir := DirAccess.open(base)
	if dir == null:
		return []
	var names: Array = dir.get_files()
	names.sort()
	var paths: Array = []
	for name in names:
		if String(name).ends_with(".json"):
			paths.append("%s/%s" % [base, name])
	return paths
