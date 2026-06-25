extends "res://tests/support/UiReadModelTestSuite.gd"

const BackpackPinLayoutPolicyScript = preload("res://src/ui/presenters/BackpackPinLayoutPolicy.gd")

func run_all_tests() -> Dictionary:
	failures.clear()
	test_reward_board_layout_policy_script_exists()
	test_main_view_reward_layout_runtime_helper_exists()
	test_reward_board_available_width_keeps_chrome_cushion()
	test_reward_board_layout_targets_preserve_bottom_row_minimum()
	test_reward_board_runtime_uses_compact_bottom_row_budget()
	test_reward_zone_body_target_height_subtracts_zone_chrome()
	test_reward_backpack_panel_dimensions_respect_height_cap()
	test_reward_backpack_panel_dimensions_keep_square_grid_extent()
	return _result()

func test_reward_board_layout_policy_script_exists() -> void:
	var script = load("res://src/ui/presenters/RewardBoardLayoutPolicy.gd")
	_assert(script != null, "reward board layout policy helper exists for MainViewRuntime extraction")

func test_main_view_reward_layout_runtime_helper_exists() -> void:
	var helper_path := "res://src/ui/main_view/MainViewRewardLayoutRuntime.gd"
	var HelperScript = load(helper_path)
	_assert(HelperScript != null, "MainView reward layout runtime helper exists")
	if HelperScript != null:
		_assert(HelperScript.has_method("apply_node_select_backpack_dock"), "MainView reward layout helper owns node-select backpack docking")
		_assert(HelperScript.has_method("apply_reward_backpack_dock"), "MainView reward layout helper owns reward backpack docking")
		_assert(HelperScript.has_method("sync_reward_board_layout"), "MainView reward layout helper owns reward board sync")
		_assert(HelperScript.has_method("reward_board_available_width"), "MainView reward layout helper owns reward board width projection")
		_assert(HelperScript.has_method("reward_backpack_panel_dimensions_for_host"), "MainView reward layout helper owns reward backpack panel dimensions")
		_assert(HelperScript.has_method("reward_backpack_panel_visible_height_cap"), "MainView reward layout helper owns reward backpack visible-height cap")
		_assert(_source_line_count(helper_path) <= 500, "MainView reward layout helper stays within the 500-line cap")
	_assert(_source_line_count("res://src/ui/MainViewRuntime.gd") <= 1900, "MainViewRuntime delegates reward board layout runtime after the third split checkpoint")

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

func test_reward_board_runtime_uses_compact_bottom_row_budget() -> void:
	var helper_path := "res://src/ui/main_view/MainViewRewardLayoutRuntime.gd"
	var HelperScript = load(helper_path)
	if HelperScript == null:
		_assert(false, "MainView reward layout helper loads for compact bottom-row budget")
		return
	_assert(float(HelperScript.REWARD_BOARD_TOP_ZONE_MIN_HEIGHT) >= 320.0, "reward board top zones reserve more height after the lower band is compressed")
	_assert(float(HelperScript.REWARD_BOARD_BOTTOM_ROW_MIN_HEIGHT) <= 84.0, "reward board bottom row minimum is compact enough to return height to the upper panels")
	_assert(float(HelperScript.REWARD_BOARD_BOTTOM_ROW_RATIO) <= 0.12, "reward board bottom row ratio keeps the lower discard/claim zones visually secondary")

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

func test_reward_backpack_panel_dimensions_keep_square_grid_extent() -> void:
	var script = load("res://src/ui/presenters/RewardBoardLayoutPolicy.gd")
	if script == null:
		_assert(false, "reward board layout policy helper loads for backpack grid aspect")
		return
	var grid_extent := 224.0
	var margin_width := 32.0
	var chrome_height := 56.0
	var dims: Vector2 = script.backpack_panel_dimensions_for_grid_extent(grid_extent, margin_width, chrome_height)
	var projected_grid_width := dims.x - BackpackPinLayoutPolicyScript.extra_width_for_grid_extent(grid_extent) - margin_width
	var projected_grid_height := dims.y - chrome_height
	_assert_close(projected_grid_width, projected_grid_height, 0.01, "reward backpack sizing keeps the 8x8 grid square while resizing")

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
