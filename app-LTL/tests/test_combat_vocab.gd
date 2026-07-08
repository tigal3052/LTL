# 계약:
# - 책임: combat vocab focused suites를 aggregate해서 기존 run_test_combat_vocab.gd 계약을 유지한다.
# - 입력: `tests/combat_vocab/*_suite.gd`의 `run_all_tests()` 결과.
# - 출력: 성공 시 ok=true, 실패 시 모든 suite error 병합.
# - 금지: 테스트 본문 직접 소유, SceneTree/UI/controller 상태 접근.
extends RefCounted
const CoreSuiteScript = preload("res://tests/combat_vocab/combat_vocab_core_suite.gd")
const ObstacleSuiteScript = preload("res://tests/combat_vocab/combat_vocab_obstacle_suite.gd")
const SpawnSuiteScript = preload("res://tests/combat_vocab/combat_vocab_spawn_suite.gd")
func run_all_tests() -> Dictionary:
	var errors: Array = []
	for SuiteScript in [CoreSuiteScript, ObstacleSuiteScript, SpawnSuiteScript]:
		var result: Dictionary = SuiteScript.new().run_all_tests()
		for error in result.get("errors", []):
			errors.append(error)
	return {"ok": errors.is_empty(), "errors": errors}
