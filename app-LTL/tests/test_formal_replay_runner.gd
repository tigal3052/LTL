# 계약:
# - 책임: formal replay runner가 기본 fixture를 정식 테스트 경로에서만 찾는지 검증한다.
# - 입력: FormalReplayRunner public API.
# - 출력: run_all_tests 결과 Dictionary.
# - 금지: prototype fixture path를 정식 기본 경로로 인정하지 않는다.
#
# 실행: define the TestFormalReplayRunner class.
extends RefCounted

const FormalReplayRunnerScript = preload("res://src/tools/FormalReplayRunner.gd")

var failures: Array[String] = []

# 실행: run replay runner contract tests.
func run_all_tests() -> Dictionary:
	failures.clear()
	test_default_fixture_paths_are_formal()
	return {"ok": failures.is_empty(), "errors": failures}

# 실행: verify the default discovered fixture paths come from the formal test directory.
func test_default_fixture_paths_are_formal() -> void:
	var runner = FormalReplayRunnerScript.new()
	var report: Dictionary = runner.run_all()
	_assert_eq(report.get("fixtureCount", 0), 2, "formal replay runner discovers two promoted fixtures by default")
	for item in report.get("results", []):
		var fixture_path := str(item.get("fixturePath", ""))
		_assert(fixture_path.begins_with("res://tests/fixtures/input_logs/"), "formal replay runner uses formal fixture path: %s" % fixture_path)
		_assert(not fixture_path.contains("prototype/browser-p0-p4"), "formal replay runner avoids prototype fixture path: %s" % fixture_path)

# 실행: append a failure label when condition is false.
func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

# 실행: append a deterministic equality failure label when values differ.
func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])
