# 계약:
# - 책임: focused balance and fusion tests run as a deterministic headless Godot contract.
# - 입력: `tests/test_balance_and_fusion_contract.gd` run_all_tests result.
# - 출력: `BALANCE_AND_FUSION_CONTRACT_OK` marker or deterministic failure labels.
# - 금지: production state mutation beyond in-memory test fixtures.
#
# 실행: run the focused balance and fusion contract test file in isolation.
extends SceneTree

# 실행: load the test class, run it, and exit with deterministic status.
func _init() -> void:
	var TestBalanceAndFusionClass = load("res://tests/test_balance_and_fusion_contract.gd")
	if TestBalanceAndFusionClass == null:
		push_error("Balance and fusion contract runner failed to load res://tests/test_balance_and_fusion_contract.gd")
		quit(1)
		return
	var tester = TestBalanceAndFusionClass.new()
	var test_res: Dictionary = tester.run_all_tests()
	if bool(test_res.get("ok", false)):
		print("BALANCE_AND_FUSION_CONTRACT_OK")
		quit(0)
		return
	for err in test_res.get("errors", []):
		push_error("Balance and fusion contract failed: %s" % err)
	quit(1)
