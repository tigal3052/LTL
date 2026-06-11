extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)
const TRAY_REVIEW_SETTLE_FRAMES := 24
const RewardCeremonyPolicyScript = preload("res://src/ui/presenters/RewardCeremonyPolicy.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	var keepalive := Node.new()
	root.add_child(keepalive)
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene resource loads for reward handoff contract")
	if MainScene == null:
		_finish()
		return
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for reward handoff contract")
	if main_instance == null:
		_finish()
		return
	root.add_child(main_instance)
	await process_frame
	await process_frame
	print("REWARD_HANDOFF_STEP: main_scene_ready")

	var controller = await _boot_to_node_select(main_instance)
	if controller == null:
		main_instance.queue_free()
		await process_frame
		_finish()
		return
	print("REWARD_HANDOFF_STEP: node_select_ready")

	var page_scenes: Dictionary = main_instance.get("page_scenes")
	var node_select_page = page_scenes.get("node_select", null)
	if node_select_page != null and node_select_page.has_method("route_button_count") and node_select_page.has_method("press_route_button"):
		if int(node_select_page.call("route_button_count")) > 0:
			node_select_page.call("press_route_button", 0)
	else:
		_assert(false, "node select page exposes route-button helpers for reward-handoff automation")
	await process_frame

	var start_button = main_instance.get("start_button")
	_assert(start_button != null, "start button exists for reward-handoff automation")
	if start_button != null:
		start_button.pressed.emit()
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "battle", "normal route enters battle before reward handoff checks")
	print("REWARD_HANDOFF_STEP: battle_ready")

	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await process_frame
	await process_frame
	print("REWARD_HANDOFF_STEP: reward_page_entered")

	_assert_eq(str(main_instance.get("active_page_id")), "reward", "combat clear enters the reward page before ceremony completion")
	var reward_step := str(controller.get("reward_presentation_step"))
	_assert(RewardCeremonyPolicyScript.is_active_step(reward_step), "combat clear enters an active reward ceremony step before tray review")
	_assert_eq(bool(controller.get("is_reveal_vfx_running")), true, "combat clear starts the reward reveal flow before tray review")
	var reward_reveal_overlay = main_instance.get_node_or_null("RewardRevealOverlay")
	_assert(reward_reveal_overlay != null, "reward handoff flow exposes the reward reveal overlay during ceremony playback")
	if reward_reveal_overlay != null:
		print("REWARD_HANDOFF_STEP: confirm_final_overlay")
		await _confirm_reward_reveal_handoff(controller, reward_reveal_overlay)
	await process_frame
	await process_frame
	print("REWARD_HANDOFF_STEP: overlay_finished")
	await _await_tray_review_stability(main_instance, controller)
	print("REWARD_HANDOFF_STEP: tray_review_ready")

	_assert_eq(str(main_instance.get("active_page_id")), "reward", "ceremony completion keeps the reward page active for tray review")
	_assert_eq(str(controller.get("reward_presentation_step")), "tray_review", "ceremony completion advances to tray review")
	_assert_eq(bool(controller.get("is_reveal_vfx_running")), false, "ceremony completion clears the reveal-running flag")
	var current_scene: Dictionary = controller.get("current_scene")
	_assert_eq(str(current_scene.get("rewardPresentationStep", "")), "tray_review", "current reward scene records tray review after ceremony completion")

	var reward_panel = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel") as Control
	var reward_backpack_host = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/BackpackHost") as Control
	var backpack_container = main_instance.get("backpack_container") as Control
	_assert(reward_panel != null, "reward page exposes the reward panel after ceremony completion")
	_assert(reward_backpack_host != null, "reward page exposes the workspace backpack host after ceremony completion")
	_assert(backpack_container != null, "main scene exposes the shared backpack container for reward handoff")
	if reward_panel != null:
		_assert_eq(reward_panel.visible, true, "tray review makes the reward page visible after ceremony completion")
	if reward_backpack_host != null and backpack_container != null:
		var host_rect := reward_backpack_host.get_global_rect()
		var backpack_rect := backpack_container.get_global_rect()
		_assert(backpack_container.get_parent() == reward_backpack_host, "tray review reparents the shared backpack into the reward workspace host")
		_assert(host_rect.has_point(backpack_rect.position), "shared backpack begins inside the reward workspace host after ceremony completion")
		_assert(host_rect.has_point(backpack_rect.end - Vector2.ONE), "shared backpack ends inside the reward workspace host after ceremony completion")

	main_instance.queue_free()
	await process_frame
	_finish()

func _boot_to_node_select(main_instance: Node, color := "purple", leviathan_id := "storm_wyvern") -> Node:
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists during reward handoff boot")
	if controller == null:
		return null
	var character_page = main_instance.get("character_select_page")
	_assert(character_page != null, "character select page exists during reward handoff boot")
	if character_page != null:
		character_page.color_selected.emit(color)
		character_page.continue_requested.emit()
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "leviathan_select", "character select advances to leviathan select during reward handoff boot")
	var leviathan_page = main_instance.get("leviathan_select_page")
	_assert(leviathan_page != null, "leviathan select page exists during reward handoff boot")
	if leviathan_page != null:
		leviathan_page.leviathan_selected.emit(leviathan_id)
		leviathan_page.start_requested.emit()
	await process_frame
	await process_frame
	await process_frame
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "leviathan select advances to node select during reward handoff boot")
	_assert_eq(str(controller.get("current_scene").get("phase", "")), "node_select", "reward handoff boot lands in node select")
	return controller

func _confirm_reward_reveal_handoff(controller: Node, reward_reveal_overlay: Node) -> void:
	var reward_count: int = max(1, int(Array(controller.get("local_rewards_list")).size()))
	reward_reveal_overlay.set("current_step", "reveal_queue")
	reward_reveal_overlay.set("current_reveal_index", reward_count - 1)
	reward_reveal_overlay.set("readable", true)
	reward_reveal_overlay.call("_handle_confirm_input")
	var settle_frames := 0
	while bool(controller.get("is_reveal_vfx_running")) and settle_frames < 12:
		await process_frame
		settle_frames += 1
	await process_frame
	_assert_eq(bool(controller.get("is_reveal_vfx_running")), false, "final reward reveal confirm clears the reveal-running flag before tray review handoff")

func _await_tray_review_stability(main_instance: Node, controller: Node) -> void:
	var reward_panel = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel") as Control
	var reward_backpack_host = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/BackpackHost") as Control
	var backpack_container = main_instance.get("backpack_container") as Control
	for _frame in range(TRAY_REVIEW_SETTLE_FRAMES):
		await process_frame
		if reward_panel == null or reward_backpack_host == null or backpack_container == null:
			continue
		_assert_eq(str(main_instance.get("active_page_id")), "reward", "tray review remains on the reward page throughout the settle window")
		_assert_eq(str(controller.get("reward_presentation_step")), "tray_review", "tray review remains the active reward step throughout the settle window")
		_assert_eq(bool(controller.get("is_reveal_vfx_running")), false, "tray review settle window keeps reveal VFX inactive")
		_assert_eq(reward_panel.visible, true, "tray review panel stays visible throughout the settle window")
		_assert(backpack_container.get_parent() == reward_backpack_host, "shared backpack stays docked to the reward workspace host throughout the settle window")
		var host_rect := reward_backpack_host.get_global_rect()
		var backpack_rect := backpack_container.get_global_rect()
		_assert(host_rect.has_point(backpack_rect.position), "shared backpack top-left stays inside the reward workspace host throughout the settle window")
		_assert(host_rect.has_point(backpack_rect.end - Vector2.ONE), "shared backpack bottom-right stays inside the reward workspace host throughout the settle window")

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _finish() -> void:
	if failures.is_empty():
		print("REWARD_HANDOFF_CONTRACT_OK")
		call_deferred("quit", 0)
		return
	for failure in failures:
		push_error(failure)
	call_deferred("quit", 1)
