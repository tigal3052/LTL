extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	test_reward_board_layout_policy_script_exists()
	test_reward_board_available_width_keeps_chrome_cushion()
	test_reward_board_layout_targets_preserve_bottom_row_minimum()
	test_reward_zone_body_target_height_subtracts_zone_chrome()
	test_reward_backpack_panel_dimensions_respect_height_cap()
	return _result()

func test_reward_board_layout_policy_script_exists() -> void:
	var script = load("res://src/ui/presenters/RewardBoardLayoutPolicy.gd")
	_assert(script != null, "reward board layout policy helper exists for MainViewRuntime extraction")

func test_reward_board_available_width_keeps_chrome_cushion() -> void:
	var script = load("res://src/ui/presenters/RewardBoardLayoutPolicy.gd")
	if script == null:
		_assert(false, "reward board layout policy helper loads for width projection")
		return
	var width := float(script.board_available_width(1280.0, 28.0))
	_assert_close(width, 1242.0, 0.01, "reward board width keeps the horizontal margin plus fixed chrome cushion")

func test_reward_board_layout_targets_preserve_bottom_row_minimum() -> void:
	var script = load("res://src/ui/presenters/RewardBoardLayoutPolicy.gd")
	if script == null:
		_assert(false, "reward board layout policy helper loads for target projection")
		return
	var layout: Dictionary = script.board_layout_targets(360.0, 12.0, 160.0, 280.0, 0.22)
	_assert_eq(int(layout.get("bottomRowHeight", 0)), 160, "reward board layout keeps the bottom-row minimum when the board height is tight")
	_assert_eq(int(layout.get("topZoneHeight", 0)), 280, "reward board layout keeps the top-zone minimum when the board height is tight")

func test_reward_zone_body_target_height_subtracts_zone_chrome() -> void:
	var script = load("res://src/ui/presenters/RewardBoardLayoutPolicy.gd")
	if script == null:
		_assert(false, "reward board layout policy helper loads for zone body projection")
		return
	var target_height := float(script.zone_body_target_height(420.0, 300.0, 360.0, 220.0))
	_assert_close(target_height, 240.0, 0.01, "reward zone body target subtracts zone chrome from the requested zone height")

func test_reward_backpack_panel_dimensions_respect_height_cap() -> void:
	var script = load("res://src/ui/presenters/RewardBoardLayoutPolicy.gd")
	if script == null:
		_assert(false, "reward board layout policy helper loads for backpack panel sizing")
		return
	var host_size := Vector2(540.0, 300.0)
	var dims: Vector2 = script.backpack_panel_dimensions_for_host(host_size, 32.0, 56.0, 250.0)
	_assert(dims.x <= host_size.x + 0.01, "reward backpack panel width stays inside the host width cap")
	_assert(dims.y <= 250.0 + 0.01, "reward backpack panel height respects the visible height cap")
