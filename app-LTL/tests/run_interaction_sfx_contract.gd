extends SceneTree

func _init() -> void:
	var TestClass = load("res://tests/test_interaction_sfx_contract.gd")
	if TestClass == null:
		push_error("Interaction SFX contract runner failed to load res://tests/test_interaction_sfx_contract.gd")
		quit(1)
		return
	var tester = TestClass.new()
	var test_res: Dictionary = tester.run_all_tests()
	if bool(test_res.get("ok", false)):
		print("INTERACTION_SFX_CONTRACT_OK")
		quit(0)
		return
	for err in test_res.get("errors", []):
		push_error("Interaction SFX contract failed: %s" % err)
	quit(1)
