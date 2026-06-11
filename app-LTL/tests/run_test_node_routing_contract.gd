extends SceneTree

func _init() -> void:
	var TestNodeRoutingClass = load("res://tests/test_node_routing_contract.gd")
	if TestNodeRoutingClass == null:
		push_error("Node routing test runner failed to load res://tests/test_node_routing_contract.gd")
		quit(1)
		return
	var tester = TestNodeRoutingClass.new()
	var test_res: Dictionary = tester.run_all_tests()
	if bool(test_res.get("ok", false)):
		print("NODE_ROUTING_TESTS_OK")
		quit(0)
		return
	for err in test_res.get("errors", []):
		push_error("Node routing test failed: %s" % err)
	quit(1)
