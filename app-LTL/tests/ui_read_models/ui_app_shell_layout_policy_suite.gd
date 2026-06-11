extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	test_app_shell_layout_policy_script_exists()
	test_app_shell_layout_policy_projects_safe_shell_size()
	test_app_shell_layout_policy_projects_active_phase_budget()
	test_app_shell_layout_policy_projects_top_content_budget()
	test_app_shell_layout_policy_caps_reward_backpack_panel_height()
	return _result()

func test_app_shell_layout_policy_script_exists() -> void:
	var script = load("res://src/ui/presenters/AppShellLayoutPolicy.gd")
	_assert(script != null, "app shell layout policy helper exists for MainViewRuntime extraction")

func test_app_shell_layout_policy_projects_safe_shell_size() -> void:
	var script = load("res://src/ui/presenters/AppShellLayoutPolicy.gd")
	_assert(script != null, "app shell layout policy helper loads for safe shell projection")
	if script == null:
		return
	var safe_size: Vector2 = script.viewport_safe_size(Vector2(1440.0, 900.0), 48.0, 32.0)
	_assert_eq(safe_size, Vector2(1392.0, 868.0), "app shell layout policy subtracts root margins from the viewport size")

func test_app_shell_layout_policy_projects_active_phase_budget() -> void:
	var script = load("res://src/ui/presenters/AppShellLayoutPolicy.gd")
	_assert(script != null, "app shell layout policy helper loads for active-phase budget projection")
	if script == null:
		return
	var max_height := float(script.max_safe_active_phase_height(Vector2(1392.0, 868.0), 18.0, 72.0, 320.0, true, 64.0))
	_assert_close(max_height, 358.0, 0.01, "active-phase height budget subtracts visible section heights and section gaps from the safe shell height")

func test_app_shell_layout_policy_projects_top_content_budget() -> void:
	var script = load("res://src/ui/presenters/AppShellLayoutPolicy.gd")
	_assert(script != null, "app shell layout policy helper loads for top-content budget projection")
	if script == null:
		return
	var max_height := float(script.max_safe_top_content_height(Vector2(1392.0, 868.0), 18.0, true, 72.0, true, 360.0, true, 64.0, true))
	_assert_close(max_height, 318.0, 0.01, "top-content height budget reserves header, action bar, active phase minimum, and section gaps")
	var max_width := float(script.max_safe_backpack_width(1392.0, 20.0, 320.0, 260.0))
	_assert_close(max_width, 772.0, 0.01, "top-content backpack width cap subtracts visible side-panel minima and row gaps")

func test_app_shell_layout_policy_caps_reward_backpack_panel_height() -> void:
	var script = load("res://src/ui/presenters/AppShellLayoutPolicy.gd")
	_assert(script != null, "app shell layout policy helper loads for reward backpack height cap")
	if script == null:
		return
	var cap := float(script.reward_backpack_panel_visible_height_cap(540.0, 32.0, 16.0, 12.0, 44.0, 132.0))
	_assert_close(cap, 286.0, 0.01, "reward backpack height cap subtracts panel chrome from the active reward panel height")
