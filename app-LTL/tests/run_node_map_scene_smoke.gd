extends SceneTree

func _init() -> void:
	var TestNodeMapSceneClass = load("res://tests/test_node_map_scene_smoke.gd")
	if TestNodeMapSceneClass == null:
		push_error("Node map smoke runner failed to load res://tests/test_node_map_scene_smoke.gd")
		quit(1)
		return
	var tester = TestNodeMapSceneClass.new()
	var test_res: Dictionary = tester.run_all_tests()
	if bool(test_res.get("ok", false)):
		print("NODE_MAP_SCENE_SMOKE_OK")
		quit(0)
		return
	for err in test_res.get("errors", []):
		push_error("Node map scene smoke failed: %s" % err)
	quit(1)
