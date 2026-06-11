extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	test_shared_backpack_host_coordinator_helper_exists()
	test_shared_backpack_host_coordinator_reward_dock_requests_workspace_host()
	test_shared_backpack_host_coordinator_commit_reparent_requests_node_followup_refresh()
	return _result()

func test_shared_backpack_host_coordinator_helper_exists() -> void:
	var helper = load("res://src/ui/SharedBackpackHostCoordinator.gd")
	_assert(helper != null, "shared backpack host coordinator helper exists for MainViewRuntime extraction")

func test_shared_backpack_host_coordinator_reward_dock_requests_workspace_host() -> void:
	var helper = load("res://src/ui/SharedBackpackHostCoordinator.gd")
	_assert(helper != null, "shared backpack host coordinator helper loads for reward dock checks")
	if helper == null:
		return
	var original_parent := Control.new()
	var reward_host := Control.new()
	var backpack_container := AspectRatioContainer.new()
	original_parent.add_child(backpack_container)
	var state := {
		"scheduledParent": null,
		"scheduledIndex": -99,
		"titleState": false
	}
	helper.apply_reward_backpack_dock(
		backpack_container,
		reward_host,
		original_parent,
		3,
		true,
		func(docked: bool):
			state["titleState"] = docked,
		func(target_parent: Node, target_index: int = -1):
			state["scheduledParent"] = target_parent
			state["scheduledIndex"] = target_index
	)
	_assert_eq(bool(state.get("titleState", false)), true, "shared backpack coordinator marks the reward workspace title as docked when the backpack moves onto the reward board")
	_assert_eq(state.get("scheduledParent", null), reward_host, "shared backpack coordinator requests reward-host reparent when docking to the reward board")
	_assert_eq(int(state.get("scheduledIndex", -99)), -1, "reward-host docking keeps the default append index")
	_assert_eq(int(backpack_container.size_flags_horizontal), int(Control.SIZE_SHRINK_CENTER), "reward-host docking centers the shared backpack inside the workspace host")
	_assert_eq(int(backpack_container.size_flags_vertical), int(Control.SIZE_SHRINK_CENTER), "reward-host docking shrink-centers the shared backpack vertically inside the workspace host")

func test_shared_backpack_host_coordinator_commit_reparent_requests_node_followup_refresh() -> void:
	var helper = load("res://src/ui/SharedBackpackHostCoordinator.gd")
	_assert(helper != null, "shared backpack host coordinator helper loads for deferred reparent checks")
	if helper == null:
		return
	var original_parent := Control.new()
	var reward_host := Control.new()
	var node_select_host := Control.new()
	var backpack_container := AspectRatioContainer.new()
	original_parent.add_child(backpack_container)
	var state := {
		"sharedLayoutSyncCalls": 0,
		"rewardLayoutSyncCalls": 0,
		"nodeRefreshCalls": 0,
		"pinFlushCalls": 0
	}
	var result: Dictionary = helper.commit_backpack_reparent(
		backpack_container,
		node_select_host,
		-1,
		original_parent,
		reward_host,
		node_select_host,
		func():
			state["sharedLayoutSyncCalls"] = int(state.get("sharedLayoutSyncCalls", 0)) + 1,
		func():
			state["rewardLayoutSyncCalls"] = int(state.get("rewardLayoutSyncCalls", 0)) + 1,
		func():
			state["nodeRefreshCalls"] = int(state.get("nodeRefreshCalls", 0)) + 1,
		func():
			state["pinFlushCalls"] = int(state.get("pinFlushCalls", 0)) + 1
	)
	_assert_eq(backpack_container.get_parent(), node_select_host, "shared backpack coordinator reparents the shared backpack into the node-select host when requested")
	_assert_eq(int(state.get("sharedLayoutSyncCalls", 0)), 1, "shared backpack coordinator always queues the shared layout sync after reparent")
	_assert_eq(int(state.get("rewardLayoutSyncCalls", 0)), 0, "node-select reparent does not queue reward-board layout sync")
	_assert_eq(int(state.get("nodeRefreshCalls", 0)), 1, "node-select reparent queues a node-map follow-up refresh")
	_assert_eq(int(state.get("pinFlushCalls", 0)), 1, "shared backpack coordinator flushes pending backpack pin overlays after reparent")
	_assert_eq(bool(result.get("nodeMapFollowupRequested", false)), true, "shared backpack coordinator reports that node-select reparent needs a follow-up layout refresh")
