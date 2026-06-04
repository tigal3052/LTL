# 계약:
# - 책임: stage-one starter-option regression contract를 isolated headless entrypoint로 실행한다.
# - 입력: `tests/test_start_option_contract.gd`의 `run_all_tests()` 결과.
# - 출력: 성공 시 `START_OPTION_CONTRACT_OK`, 실패 시 deterministic error lines and exit code 1.
# - 금지: production state mutation, unrelated scene boot, reward ceremony coverage.
#
# 실행: run the starter-option regression contract in isolation.
extends SceneTree

func _init() -> void:
	var TestStartOptionContractClass = load("res://tests/test_start_option_contract.gd")
	if TestStartOptionContractClass == null:
		push_error("Starter-option contract runner failed to load res://tests/test_start_option_contract.gd")
		quit(1)
		return
	var tester = TestStartOptionContractClass.new()
	var test_res: Dictionary = tester.run_all_tests()
	if bool(test_res.get("ok", false)):
		print("START_OPTION_CONTRACT_OK")
		quit(0)
		return
	for err in test_res.get("errors", []):
		push_error("Starter-option contract failed: %s" % err)
	quit(1)
