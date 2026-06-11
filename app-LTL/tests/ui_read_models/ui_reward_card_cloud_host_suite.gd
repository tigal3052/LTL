extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	test_reward_card_cloud_host_helper_exists()
	test_reward_card_cloud_host_clamps_anchors_inside_cloud()
	test_reward_card_cloud_host_prunes_manual_anchors_to_live_cards()
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
