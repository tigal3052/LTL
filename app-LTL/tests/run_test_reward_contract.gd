# 怨꾩빟:
# - 梨낆엫: reward/progression ?⑥쐞 ?뚯뒪?몃쭔 蹂꾨룄濡??ㅽ뻾??relic pool 諛?蹂댁긽 怨꾩빟 蹂寃쎌쓽 red/green ?뺤씤 寃쎈줈瑜??쒓났?쒕떎.
# - ?낅젰: `tests/test_reward_contract.gd`??`run_all_tests()` 寃곌낵.
# - 異쒕젰: ?깃났 ??`REWARD_CONTRACT_TESTS_OK`, ?ㅽ뙣 ??媛??ㅽ뙣 ?먯씤怨?醫낅즺 肄붾뱶 1.
# - 湲덉?: production state mutation, scene bootstrapping ?고쉶, ?뚯뒪??蹂몃Ц 蹂寃?
#
# ?ㅽ뻾: run the reward contract test file in isolation.
extends SceneTree

# ?ㅽ뻾: load the reward contract test class, run it, and exit with deterministic status.
func _init() -> void:
	var TestRewardContractClass = load("res://tests/test_reward_contract.gd")
	if TestRewardContractClass == null:
		push_error("Reward contract test runner failed to load res://tests/test_reward_contract.gd")
		quit(1)
		return
	var tester = TestRewardContractClass.new()
	var test_res: Dictionary = tester.run_all_tests()
	if bool(test_res.get("ok", false)):
		print("REWARD_CONTRACT_TESTS_OK")
		quit(0)
		return
	for err in test_res.get("errors", []):
		push_error("Reward contract test failed: %s" % err)
	quit(1)
