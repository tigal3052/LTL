extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	test_reward_card_cloud_host_helper_exists()
	test_reward_card_cloud_host_clamps_anchors_inside_cloud()
	test_reward_card_cloud_host_prunes_manual_anchors_to_live_cards()
	test_main_view_reward_runtime_helper_exists()
	return _result()

func test_reward_card_cloud_host_helper_exists() -> void:
	var helper = load("res://src/ui/RewardCardCloudHost.gd")
	_assert(helper != null, "reward-card cloud host helper exists for MainViewRuntime extraction")

func test_reward_card_cloud_host_clamps_anchors_inside_cloud() -> void:
	var helper = load("res://src/ui/RewardCardCloudHost.gd")
	_assert(helper != null, "reward-card cloud host helper loads for drag clamping")
	if helper == null:
		return
	var cloud_size := Vector2(320.0, 260.0)
	var card_size := Vector2(120.0, 120.0)
	var bounds: Rect2 = helper.reward_card_anchor_bounds(cloud_size, card_size)
	_assert(bounds.size.x >= 0.0 and bounds.size.y >= 0.0, "reward-card cloud bounds stay non-negative")
	_assert_eq(helper.clamp_reward_card_anchor(cloud_size, card_size, Vector2(-50.0, -30.0)), bounds.position, "reward-card cloud clamp pins cards to the top-left bound")
	_assert_eq(helper.clamp_reward_card_anchor(cloud_size, card_size, Vector2(500.0, 420.0)), bounds.position + bounds.size, "reward-card cloud clamp pins cards to the bottom-right bound")

func test_reward_card_cloud_host_prunes_manual_anchors_to_live_cards() -> void:
	var helper = load("res://src/ui/RewardCardCloudHost.gd")
	_assert(helper != null, "reward-card cloud host helper loads for manual-anchor pruning")
	if helper == null:
		return
	var manual_anchors := {
		1: Vector2(0.1, 0.2),
		2: Vector2(0.4, 0.5),
		5: Vector2(0.8, 0.7)
	}
	var pruned: Dictionary = helper.prune_manual_anchors([
		{"index": 2},
		{"index": 5}
	], manual_anchors)
	_assert_eq(pruned.has(1), false, "reward-card cloud host drops anchors for cards that are no longer active")
	_assert_eq(pruned.has(2), true, "reward-card cloud host keeps anchors for live cards")
	_assert_eq(pruned.has(5), true, "reward-card cloud host keeps anchors for every live card index")

func test_main_view_reward_runtime_helper_exists() -> void:
	var helper_path := "res://src/ui/main_view/MainViewRewardRuntime.gd"
	var HelperScript = load(helper_path)
	_assert(HelperScript != null, "MainView reward runtime helper exists")
	if HelperScript != null:
		_assert(HelperScript.has_method("render_reward_tray"), "MainView reward helper owns reward tray rendering")
		_assert(HelperScript.has_method("render_reward_cards"), "MainView reward helper owns reward card rendering")
		_assert(HelperScript.has_method("render_reward_inspector"), "MainView reward helper owns reward inspector rendering")
		_assert(HelperScript.has_method("render_reward_footprint"), "MainView reward helper owns footprint rendering")
		_assert(HelperScript.has_method("layout_reward_float_cards"), "MainView reward helper owns reward-card float layout")
		_assert(_source_line_count(helper_path) <= 500, "MainView reward helper stays within the 500-line cap")
	_assert(_source_line_count("res://src/ui/MainViewRuntime.gd") <= 2250, "MainViewRuntime delegates reward tray runtime after the first split checkpoint")

func _source_line_count(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 999999
	var line_count := 0
	while not file.eof_reached():
		file.get_line()
		line_count += 1
	file.close()
	return line_count
