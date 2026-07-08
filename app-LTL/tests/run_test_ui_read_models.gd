# 계약:
# - 책임: UI read model 단위 테스트만 별도로 실행해 reward reveal 같은 국소 변경의 red/green 확인 통로를 제공한다.
# - 입력: `tests/test_ui_read_models.gd`의 `run_all_tests()` 결과.
# - 출력: 성공 시 `UI_READ_MODEL_TESTS_OK`, 실패 시 각 실패 라인과 종료 코드 1.
# - 금지: production state mutation, scene bootstrapping 우회, 테스트 의미 변경.
#
# 실행: run the UI read model contract test file in isolation.
extends SceneTree

# 실행: load the UI read model test class, run it, and exit with deterministic status.
func _init() -> void:
	var TestUiReadModelsClass = load("res://tests/test_ui_read_models.gd")
	if TestUiReadModelsClass == null:
		push_error("UI read model test runner failed to load res://tests/test_ui_read_models.gd")
		quit(1)
		return
	var tester = TestUiReadModelsClass.new()
	var test_res: Dictionary = tester.run_all_tests()
	if bool(test_res.get("ok", false)):
		print("UI_READ_MODEL_TESTS_OK")
		quit(0)
		return
	for err in test_res.get("errors", []):
		push_error("UI read model test failed: %s" % err)
	quit(1)
