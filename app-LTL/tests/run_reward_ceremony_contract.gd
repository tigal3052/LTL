# 계약:
# - 책임: 보상 세레모니 재설계의 핵심 계약만 독립적으로 검증한다.
# - 입력: `tests/test_ui_read_models.gd`의 보상 세레모니 전용 테스트 결과.
# - 출력: 성공 시 `REWARD_CEREMONY_CONTRACT_OK`, 실패 시 오류와 종료 코드 1.
# - 금지: 전체 계약 스위트 강제 실행, 게임플레이 상태 변경, unrelated scene bootstrapping.
#
# 실행: 보상 세레모니 전용 read-model 및 UI 계약만 분리 실행한다.
extends SceneTree

func _init() -> void:
	var TestUiReadModelsClass = load("res://tests/test_ui_read_models.gd")
	if TestUiReadModelsClass == null:
		push_error("reward ceremony contract runner failed to load res://tests/test_ui_read_models.gd")
		quit(1)
		return
	var tester = TestUiReadModelsClass.new()
	var test_res: Dictionary = tester.run_reward_ceremony_tests()
	if bool(test_res.get("ok", false)):
		print("REWARD_CEREMONY_CONTRACT_OK")
		quit(0)
		return
	for err in test_res.get("errors", []):
		push_error("reward ceremony contract failed: %s" % err)
	quit(1)
