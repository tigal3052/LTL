# 계약:
# - 책임: combat utility vocabulary 단위 테스트만 별도로 실행해 obstacle lifecycle 변경의 red/green 검증 루프를 제공한다.
# - 입력: `tests/test_combat_vocab.gd`의 `run_all_tests()` 결과.
# - 출력: 성공 시 `COMBAT_VOCAB_TESTS_OK`, 실패 시 각 실패 원인과 종료 코드 1.
# - 금지: production state mutation, scene bootstrapping 우회, 테스트 본문 변경.
#
# 실행: run the combat vocabulary contract test file in isolation.
extends SceneTree

# 실행: load the combat vocabulary test class, run it, and exit with deterministic status.
func _init() -> void:
	var TestCombatVocabClass = load("res://tests/test_combat_vocab.gd")
	if TestCombatVocabClass == null:
		push_error("Combat vocab test runner failed to load res://tests/test_combat_vocab.gd")
		quit(1)
		return
	var tester = TestCombatVocabClass.new()
	var test_res: Dictionary = tester.run_all_tests()
	if bool(test_res.get("ok", false)):
		print("COMBAT_VOCAB_TESTS_OK")
		quit(0)
		return
	for err in test_res.get("errors", []):
		push_error("Combat vocab test failed: %s" % err)
	quit(1)
