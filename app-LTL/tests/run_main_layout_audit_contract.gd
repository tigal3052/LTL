extends SceneTree

const VIEWPORT_SIZE := Vector2i(1440, 900)

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = VIEWPORT_SIZE
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene resource loads for gameplay layout audit")
	if MainScene == null:
		_finish()
		return
	await _assert_stage_two_node_select_layout(MainScene)
	await _assert_combat_layout(MainScene)
	await _assert_combat_purple_status_overlay_keeps_bottom_gap(MainScene)
	await _assert_combat_overlay_pause_behavior(MainScene)
	await _assert_reward_tray_layout(MainScene)
	await _assert_reward_reveal_layout(MainScene)
	await _assert_overlay_layouts(MainScene)
	_finish()

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _viewport_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(root.size))

func _assert_control_inside_viewport(control: Control, label: String) -> void:
	_assert(control != null, "%s exists for viewport containment" % label)
	if control == null:
		return
	var rect := control.get_global_rect()
	var viewport := _viewport_rect()
	_assert(rect.position.x >= viewport.position.x - 0.5, "%s stays inside the viewport left edge (rect=%s viewport=%s)" % [label, str(rect), str(viewport)])
	_assert(rect.position.y >= viewport.position.y - 0.5, "%s stays inside the viewport top edge (rect=%s viewport=%s)" % [label, str(rect), str(viewport)])
	_assert(rect.end.x <= viewport.end.x + 0.5, "%s stays inside the viewport right edge (rect=%s viewport=%s)" % [label, str(rect), str(viewport)])
	_assert(rect.end.y <= viewport.end.y + 0.5, "%s stays inside the viewport bottom edge (rect=%s viewport=%s)" % [label, str(rect), str(viewport)])

func _assert_visible_controls_inside_viewport(main_instance: Node, label: String) -> void:
	var viewport := _viewport_rect()
	var stack: Array[Node] = [main_instance]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		for child in current.get_children():
			stack.append(child)
		var control = current as Control
		if control == null or not control.is_visible_in_tree():
			continue
		var rect := control.get_global_rect()
		_assert(rect.position.x >= viewport.position.x - 0.5 and rect.position.y >= viewport.position.y - 0.5 and rect.end.x <= viewport.end.x + 0.5 and rect.end.y <= viewport.end.y + 0.5, "%s visible control stays inside viewport: %s rect=%s viewport=%s" % [label, str(control.get_path()), str(rect), str(viewport)])

func _finish() -> void:
	if failures.is_empty():
		print("MAIN_LAYOUT_AUDIT_CONTRACT_OK")
		call_deferred("quit", 0)
		return
	for failure in failures:
		push_error(failure)
	call_deferred("quit", 1)

func _instantiate_main(MainScene: PackedScene) -> Node:
	root.size = VIEWPORT_SIZE
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for layout audit")
	if main_instance == null:
		return null
	root.add_child(main_instance)
	await process_frame
	await process_frame
	await process_frame
	return main_instance

func _assert_combat_layout(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists for combat layout audit")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return
	var node_map_scene = main_instance.get("node_map_scene")
	var start_button = main_instance.get("start_button") as Button
	_assert(node_map_scene != null, "node map scene exists for combat layout audit")
	_assert(start_button != null, "start button exists for combat layout audit")
	if node_map_scene == null or start_button == null:
		main_instance.queue_free()
		await process_frame
		return
	node_map_scene.press_color_button(0)
	if node_map_scene.map_node_count() > 0:
		node_map_scene.press_node_button(0)
	await process_frame
	await process_frame
	start_button.pressed.emit()
	await process_frame
	await process_frame
	var top_content = main_instance.get("top_content") as HBoxContainer
	var left_column = main_instance.get("left_column") as Control
	var backpack_container = main_instance.get("backpack_container") as Control
	var right_sidebar = main_instance.get("right_sidebar") as Control
	var visual_queue_box = main_instance.get_node_or_null("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/QueueRow/VisualQueueBox") as GridContainer
	_assert(top_content != null, "top-content row exists for combat layout audit")
	_assert(left_column != null, "left sidebar exists for combat layout audit")
	_assert(backpack_container != null, "combat backpack exists for combat layout audit")
	_assert(right_sidebar != null, "right sidebar exists for combat layout audit")
	_assert(visual_queue_box != null, "combat status panel energy queue uses a grid container for two-row wrapping")
	if top_content != null and left_column != null and backpack_container != null and right_sidebar != null:
		_assert(bool(top_content.visible), "combat keeps the top-content row visible")
		_assert(float(left_column.position.x) >= -0.5, "combat left column stays inside the top-content row")
		_assert(float(left_column.position.x + left_column.size.x) <= float(backpack_container.position.x) + 1.0, "combat left column stays left of the backpack slot")
		_assert(float(backpack_container.position.x + backpack_container.size.x) <= float(right_sidebar.position.x) + 1.0, "combat backpack stays left of the log sidebar")
		_assert(float(right_sidebar.position.x + right_sidebar.size.x) <= float(top_content.size.x) + 1.0, "combat right sidebar stays inside the top-content row")
		var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
		if MainViewRuntimeScript != null:
			var expected_backpack_width := float(MainViewRuntimeScript.top_content_backpack_width_for_height(backpack_container.size.y))
			_assert(absf(float(backpack_container.size.x) - expected_backpack_width) <= 8.0, "combat backpack keeps the priority height-derived width instead of being clamped first (actual=%.2f expected=%.2f)" % [backpack_container.size.x, expected_backpack_width])
		_assert(float(left_column.size.x) <= 500.0, "combat left status column compresses around the priority backpack panel (width=%.2f)" % left_column.size.x)
		_assert(float(right_sidebar.size.x) <= 430.0, "combat log sidebar compresses around the priority backpack panel (width=%.2f)" % right_sidebar.size.x)
	if visual_queue_box != null:
		_assert_eq(int(visual_queue_box.columns), 8, "combat energy queue wraps sixteen slots into two rows of eight")
	_assert_visible_controls_inside_viewport(main_instance, "combat")
	main_instance.queue_free()
	await process_frame

func _assert_combat_purple_status_overlay_keeps_bottom_gap(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var controller = main_instance.get_node_or_null("MainController")
	var node_map_scene = main_instance.get("node_map_scene")
	var start_button = main_instance.get("start_button") as Button
	_assert(controller != null, "main controller exists for combat purple-status layout audit")
	_assert(node_map_scene != null, "node map scene exists for combat purple-status layout audit")
	_assert(start_button != null, "start button exists for combat purple-status layout audit")
	if controller == null or node_map_scene == null or start_button == null:
		main_instance.queue_free()
		await process_frame
		return
	node_map_scene.press_color_button(0)
	if node_map_scene.map_node_count() > 0:
		node_map_scene.press_node_button(0)
	await process_frame
	await process_frame
	start_button.pressed.emit()
	await process_frame
	await process_frame
	var top_content = main_instance.get("top_content") as HBoxContainer
	var active_phase_container = main_instance.get("active_phase_container") as Control
	var action_bar = main_instance.get("action_bar") as Control
	var purple_row = main_instance.get_node_or_null("RootMargin/AppShell/TopContent/LeftColumn/StatusPanel/Margin/StatusBox/StatusFooterSpacer/PurpleStatusRow") as HBoxContainer
	_assert(top_content != null, "combat top-content row exists for purple-status layout audit")
	_assert(active_phase_container != null, "combat active phase container exists for purple-status layout audit")
	_assert(action_bar != null, "combat action bar exists for purple-status layout audit")
	_assert(purple_row != null, "combat status panel keeps the purple status row in the footer spacer lane")
	if top_content == null or active_phase_container == null or action_bar == null or purple_row == null:
		main_instance.queue_free()
		await process_frame
		return
	var base_top_height := float(top_content.size.y)
	var base_active_phase_y := float(active_phase_container.global_position.y)
	var base_action_bar_y := float(action_bar.global_position.y)
	var purple_scene: Dictionary = controller.get("current_scene").duplicate(true)
	var hud: Dictionary = purple_scene.get("hud", {}).duplicate(true)
	hud["purplePressure"] = {"stackCount": 0, "buffCount": 2, "active": true}
	purple_scene["hud"] = hud
	controller.call("_render_scene", purple_scene)
	await process_frame
	await process_frame
	_assert(bool(purple_row.visible), "combat purple-status layout audit triggers the purple status row")
	_assert(absf(float(top_content.size.y) - base_top_height) <= 0.5, "purple status overlay keeps the top-content row height stable instead of pushing the bottom panel down (before=%.2f after=%.2f)" % [base_top_height, top_content.size.y])
	_assert(absf(float(active_phase_container.global_position.y) - base_active_phase_y) <= 0.5, "purple status overlay keeps the active phase container anchored instead of lowering the battlefield (before=%.2f after=%.2f)" % [base_active_phase_y, active_phase_container.global_position.y])
	_assert(absf(float(action_bar.global_position.y) - base_action_bar_y) <= 0.5, "purple status overlay keeps the action bar floor position stable after the first purple-state update (before=%.2f after=%.2f)" % [base_action_bar_y, action_bar.global_position.y])
	main_instance.queue_free()
	await process_frame

func _assert_combat_overlay_pause_behavior(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var controller = main_instance.get_node_or_null("MainController")
	var start_button = main_instance.get("start_button") as Button
	var node_map_scene = main_instance.get("node_map_scene")
	_assert(controller != null, "main controller exists for combat overlay pause audit")
	_assert(start_button != null, "start button exists for combat overlay pause audit")
	_assert(node_map_scene != null, "node map scene exists for combat overlay pause audit")
	_assert(controller != null and controller.has_method("is_battle_pause_active"), "main controller exposes battle-only overlay pause query for combat overlay audit")
	if controller == null or start_button == null or node_map_scene == null:
		main_instance.queue_free()
		await process_frame
		return
	if not controller.has_method("is_battle_pause_active"):
		main_instance.queue_free()
		await process_frame
		return
	node_map_scene.press_color_button(0)
	if node_map_scene.map_node_count() > 0:
		node_map_scene.press_node_button(0)
	await process_frame
	await process_frame
	start_button.pressed.emit()
	await process_frame
	await process_frame
	main_instance.call("set_settings_visible", true)
	await process_frame
	_assert(bool(controller.call("is_battle_pause_active")), "opening settings during combat enables battle-only overlay pause")
	main_instance.call("set_settings_visible", false)
	await process_frame
	_assert(not bool(controller.call("is_battle_pause_active")), "closing settings during combat resumes battle-only overlay pause")
	controller.call("_on_codex_open_pressed")
	await process_frame
	_assert(bool(main_instance.call("is_artifact_codex_visible")), "combat overlay pause audit opens the artifact codex")
	_assert(bool(controller.call("is_battle_pause_active")), "opening the codex during combat enables battle-only overlay pause")
	controller.call("_render_scene", controller.get("current_scene"))
	await process_frame
	_assert(bool(main_instance.call("is_artifact_codex_visible")), "combat rerenders keep the artifact codex open instead of force-closing it")
	main_instance.call("set_artifact_codex_visible", false)
	await process_frame
	_assert(not bool(controller.call("is_battle_pause_active")), "closing the codex during combat resumes battle-only overlay pause")
	main_instance.queue_free()
	await process_frame

func _assert_stage_two_node_select_layout(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists for stage-two node-select layout audit")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return
	controller.call("_render_scene", {
		"phase": "combat",
		"terrain": {"rows": 0, "columns": 0, "cells": []},
		"hud": {
			"aim": {"canFire": true},
			"repair": {"active": false, "available": false},
			"queue": {"items": [], "capacity": 16, "loaded": 8},
			"pin": {"active": false},
			"hazard": {"severity": "stable"}
		},
		"targetPanel": {"timeLimitTicks": 1200.0, "elapsedTicks": 0.0},
		"stageIndex": 0,
		"maxStages": 5
	})
	await process_frame
	await process_frame
	var stage_two_scene: Dictionary = controller.get("current_scene").duplicate(true)
	stage_two_scene["phase"] = "node_select"
	stage_two_scene["stageIndex"] = 1
	stage_two_scene["maxStages"] = maxi(2, int(stage_two_scene.get("maxStages", 5)))
	stage_two_scene["allowStartColorSelection"] = false
	stage_two_scene["selectedStartColor"] = str(stage_two_scene.get("selectedStartColor", "red"))
	stage_two_scene["selectedNodeIndex"] = 0
	controller.call("_render_scene", stage_two_scene)
	await process_frame
	await process_frame
	await process_frame
	_assert_header_actions_inside_window(main_instance, "stage-two node-select")
	_assert_node_select_layout_inside_window(main_instance, "stage-two node-select", false)
	_assert_visible_controls_inside_viewport(main_instance, "stage-two node-select")
	main_instance.queue_free()
	await process_frame

func _assert_reward_tray_layout(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists for reward tray layout audit")
	if controller == null:
		main_instance.queue_free()
		await process_frame
		return
	var rewards := [
		{"kind": "Vermilion Venting Beacon", "rarity": "rare", "qty": 1, "presentation": {"badge": "rare red beacon"}, "payload": {"item_type": "beacon", "energy_type": "red"}},
		{"kind": "Tremor Heat Post", "rarity": "common", "qty": 1, "presentation": {"badge": "common red beacon"}, "payload": {"item_type": "beacon", "energy_type": "red"}},
		{"kind": "Relic Spur", "rarity": "common", "qty": 1, "presentation": {"badge": "common relic"}, "payload": {"item_type": "relic", "energy_type": ""}},
		{"kind": "Purple Starter Drill", "rarity": "rare", "qty": 1, "presentation": {"badge": "rare purple drill"}, "payload": {"item_type": "drill", "energy_type": "purple"}},
		{"kind": "Blue Starter Beacon", "rarity": "common", "qty": 1, "presentation": {"badge": "common blue beacon"}, "payload": {"item_type": "beacon", "energy_type": "blue"}}
	]
	controller.call("_render_scene", {
		"phase": "reward_loot",
		"rewardPresentationStep": "tray_review",
		"reward": {"pendingRewards": rewards},
		"terrain": {"rows": 0, "columns": 0, "cells": []},
		"hud": {},
		"targetPanel": {},
		"stageIndex": 1,
		"maxStages": 5
	})
	await process_frame
	await process_frame
	var reward_panel = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel") as Control
	var reward_box = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox") as VBoxContainer
	var reward_title = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardTitle") as Label
	var reward_row = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow") as HBoxContainer
	var reward_text = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/RewardText") as RichTextLabel
	var discard_zone = main_instance.get_node_or_null("RootMargin/AppShell/ActivePhaseContainer/RewardPanel/Margin/RewardBox/RewardRow/DiscardZone") as Control
	_assert(reward_panel != null, "reward panel exists for reward tray layout audit")
	_assert(reward_box != null, "reward tray box exists for reward tray layout audit")
	_assert(reward_title != null, "reward tray title exists for reward tray layout audit")
	_assert(reward_row != null, "reward tray row exists for reward tray layout audit")
	_assert(reward_text != null, "reward tray text surface exists for reward tray layout audit")
	_assert(discard_zone != null, "discard zone exists for reward tray layout audit")
	if reward_panel != null and reward_box != null and reward_title != null and reward_row != null and reward_text != null and discard_zone != null:
		var row_gap := float(reward_row.get_theme_constant("separation"))
		var reward_box_gap := float(reward_box.get_theme_constant("separation"))
		var panel_local_right: float = reward_panel.global_position.x + reward_panel.size.x
		_assert(bool(reward_panel.visible), "reward tray render keeps the reward panel visible")
		_assert(float(reward_row.size.x) <= float(reward_box.size.x) + 1.0, "reward tray row stays inside the reward box width (row=%.2f box=%.2f)" % [reward_row.size.x, reward_box.size.x])
		_assert(float(reward_text.position.x + reward_text.size.x) <= float(discard_zone.position.x) - row_gap + 1.0, "reward tray text surface stays left of the discard zone gap (text=%.2f discard=%.2f)" % [reward_text.position.x + reward_text.size.x, discard_zone.position.x])
		_assert(float(discard_zone.position.x + discard_zone.size.x) <= float(reward_row.size.x) + 1.0, "discard zone stays inside the reward row width (discard=%.2f row=%.2f)" % [discard_zone.position.x + discard_zone.size.x, reward_row.size.x])
		_assert(float(discard_zone.global_position.x + discard_zone.size.x) <= panel_local_right - 8.0, "discard zone stays inside the live reward panel instead of clipping right (discard=%.2f panel=%.2f)" % [discard_zone.global_position.x + discard_zone.size.x, panel_local_right])
		var expected_row_height := maxf(120.0, float(reward_box.size.y - reward_title.size.y - reward_box_gap))
		_assert(float(reward_row.size.y) >= expected_row_height - 4.0, "reward tray row uses the available panel height instead of collapsing to its minimum (row=%.2f expected=%.2f)" % [reward_row.size.y, expected_row_height])
	_assert_visible_controls_inside_viewport(main_instance, "reward tray")
	main_instance.queue_free()
	await process_frame

func _assert_reward_reveal_layout(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var overlay = main_instance.get("reward_reveal_overlay") as Control
	_assert(overlay != null, "reward reveal overlay exists for layout audit")
	if overlay == null:
		main_instance.queue_free()
		await process_frame
		return
	var rewards := [
		{"kind": "Common Drill", "rarity": "common", "qty": 1, "payload": {"item_type": "drill", "energy_type": "red"}},
		{"kind": "Epic Beacon", "rarity": "epic", "qty": 1, "payload": {"item_type": "beacon", "energy_type": "purple"}},
		{"kind": "Legendary Relic", "rarity": "legendary", "qty": 1, "payload": {"item_type": "relic", "energy_type": ""}}
	]
	overlay.call("start_reveal", rewards, Callable(), Callable(), Rect2(Vector2(220.0, 560.0), Vector2(96.0, 60.0)))
	await process_frame
	await process_frame
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	var canvas_size: Vector2 = overlay.size
	_assert(bool(overlay.visible), "reward reveal overlay becomes visible during the layout audit")
	_assert(float(overlay.position.x) >= -0.5 and float(overlay.position.y) >= -0.5, "reward reveal overlay remains anchored to the top-left corner")
	_assert(canvas_size.x > 0.0 and canvas_size.y > 0.0, "reward reveal overlay resolves a non-zero canvas size")
	if RewardRevealOverlayScript != null and canvas_size.x > 0.0 and canvas_size.y > 0.0:
		var safe_layout = RewardRevealOverlayScript.overlay_safe_layout_model(canvas_size)
		var focus_center: Vector2 = safe_layout.get("focusCenter", canvas_size * 0.5)
		var safe_margin := float(safe_layout.get("safeMargin", 24.0))
		var focus_radius := float(safe_layout.get("focusMaxRadius", 0.0))
		var allowed_radius := minf(minf(focus_center.x, canvas_size.x - focus_center.x), minf(focus_center.y, canvas_size.y - focus_center.y)) - safe_margin
		_assert(focus_radius <= allowed_radius + 0.5, "reward reveal focus effects stay inside the shared safe radius during runtime")
		var lid_layout = RewardRevealOverlayScript.center_lid_layout_model(canvas_size)
		var lid_rect: Rect2 = lid_layout.get("closedLidRect", Rect2())
		_assert(float(lid_rect.position.x) >= 24.0, "reward reveal lid stays inside the left screen edge during runtime")
		_assert(float(lid_rect.end.x) <= float(canvas_size.x) - 24.0, "reward reveal lid stays inside the right screen edge during runtime")
		var metrics = RewardRevealOverlayScript.reward_card_layout_metrics(canvas_size)
		var card_size := Vector2(float(metrics.get("cardWidth", 0.0)), float(metrics.get("cardHeight", 0.0))) * 1.06
		var card_rect := Rect2(Vector2(canvas_size.x * 0.50, float(metrics.get("cardCenterY", canvas_size.y * 0.57))) - (card_size * 0.5), card_size)
		_assert(float(card_rect.position.x) >= 24.0, "reward reveal card stays inside the left screen edge during runtime")
		_assert(float(card_rect.end.x) <= float(canvas_size.x) - 24.0, "reward reveal card stays inside the right screen edge during runtime")
		_assert(float(card_rect.end.y) <= float(safe_layout.get("confirmPromptY", canvas_size.y * 0.90)) - 24.0, "reward reveal card stays above the confirm prompt lane during runtime")
		_assert(float(metrics.get("frontProgressY", 0.0)) + 10.0 <= float(safe_layout.get("confirmPromptY", canvas_size.y * 0.90)) - 16.0, "reward reveal front progress bar stays inside the lower safe band during runtime")
		_assert(float(metrics.get("progressY", 0.0)) + float(metrics.get("progressFontSize", 18)) <= float(safe_layout.get("confirmPromptY", canvas_size.y * 0.90)) - 12.0, "reward reveal progress text stays above the confirm prompt lane during runtime")
	_assert_visible_controls_inside_viewport(main_instance, "reward reveal")
	main_instance.queue_free()
	await process_frame

func _assert_overlay_layouts(MainScene: PackedScene) -> void:
	var main_instance = await _instantiate_main(MainScene)
	if main_instance == null:
		return
	var settings_overlay = main_instance.get("settings_panel") as Control
	var shop_overlay = main_instance.get("shop_panel") as Control
	var codex_overlay = main_instance.get("codex_panel") as Control
	main_instance.call("set_settings_visible", true)
	await process_frame
	await process_frame
	_assert_visible_controls_inside_viewport(main_instance, "settings overlay")
	_assert_overlay_claims_top_layer(settings_overlay, "settings overlay")
	main_instance.call("set_settings_visible", false)
	main_instance.call("set_shop_visible", true)
	await process_frame
	await process_frame
	_assert_visible_controls_inside_viewport(main_instance, "shop overlay")
	_assert_overlay_claims_top_layer(shop_overlay, "shop overlay")
	main_instance.call("set_shop_visible", false)
	main_instance.call("set_artifact_codex_visible", true)
	await process_frame
	await process_frame
	_assert_visible_controls_inside_viewport(main_instance, "artifact codex overlay")
	_assert_overlay_claims_top_layer(codex_overlay, "artifact codex overlay")
	main_instance.call("set_artifact_codex_visible", false)
	var confirm_overlay = main_instance.get("confirm_overlay") as Control
	if confirm_overlay != null:
		confirm_overlay.visible = true
		await process_frame
		_assert_visible_controls_inside_viewport(main_instance, "confirm overlay")
		_assert_overlay_claims_top_layer(confirm_overlay, "confirm overlay")
		confirm_overlay.visible = false
	var repair_overlay = main_instance.get("repair_overlay") as Control
	if repair_overlay != null:
		repair_overlay.visible = true
		await process_frame
		_assert_visible_controls_inside_viewport(main_instance, "repair overlay")
		_assert_overlay_claims_top_layer(repair_overlay, "repair overlay")
		repair_overlay.visible = false
	main_instance.queue_free()
	await process_frame

func _assert_overlay_claims_top_layer(overlay: Control, label: String) -> void:
	_assert(overlay != null, "%s exists for top-layer audit" % label)
	if overlay == null:
		return
	var parent := overlay.get_parent()
	_assert(parent != null, "%s keeps a parent for top-layer audit" % label)
	if parent == null:
		return
	_assert_eq(parent.get_child(parent.get_child_count() - 1), overlay, "%s moves to the last sibling so gameplay nodes cannot cover it" % label)
	_assert(int(overlay.z_index) > 200, "%s claims a popup z-index above combat HUD and damage popups" % label)

func _assert_header_actions_inside_window(main_instance: Node, label: String) -> void:
	var header = main_instance.get_node_or_null("RootMargin/AppShell/Header") as Control
	var header_actions = main_instance.get("header_actions") as HBoxContainer
	var settings_button = main_instance.get("settings_open_button") as Button
	var shop_button = main_instance.get("shop_open_button") as Button
	var codex_button = main_instance.get("codex_open_button") as Button
	_assert(header != null, "header exists for %s layout audit" % label)
	_assert(header_actions != null, "header actions exist for %s layout audit" % label)
	if header == null or header_actions == null:
		return
	var header_right: float = minf(header.global_position.x + header.size.x, _viewport_rect().end.x)
	_assert(float(header_actions.global_position.x) >= header.global_position.x - 0.5, "header actions stay inside the left header edge for %s" % label)
	_assert(float(header_actions.global_position.x + header_actions.size.x) <= header_right + 0.5, "header actions stay inside the right header edge for %s" % label)
	for button in [settings_button, shop_button, codex_button]:
		if button == null or not button.visible:
			continue
		_assert(float(button.global_position.x) >= header.global_position.x - 0.5, "header button stays inside the left shell edge for %s: %s" % [label, button.name])
		_assert(float(button.global_position.x + button.size.x) <= header_right + 0.5, "header button stays inside the right shell edge for %s: %s" % [label, button.name])

func _assert_node_select_layout_inside_window(main_instance: Node, label: String, expect_color_picker: bool) -> void:
	var row = main_instance.get("node_select_content_row") as HBoxContainer
	var panel = main_instance.get("node_select_panel") as Control
	var backpack = main_instance.get("backpack_container") as Control
	var node_map_scene = main_instance.get("node_map_scene")
	_assert(row != null, "node-select content row exists for %s" % label)
	_assert(panel != null, "node-select panel exists for %s" % label)
	_assert(backpack != null, "node-select backpack container exists for %s" % label)
	_assert(node_map_scene != null, "node-select node-map scene exists for %s" % label)
	if row == null or panel == null or backpack == null or node_map_scene == null:
		return
	var row_gap := float(row.get_theme_constant("separation"))
	var window_right: float = _viewport_rect().end.x
	_assert(backpack.get_parent() == row, "node-select backpack is docked into the row for %s" % label)
	_assert(float(panel.global_position.x + panel.size.x) <= window_right + 0.5, "node-select panel stays inside the main window for %s" % label)
	_assert(float(row.global_position.x + row.size.x) <= float(panel.global_position.x + panel.size.x) + 0.5, "node-select content row stays inside the node-select panel for %s" % label)
	_assert(float(backpack.global_position.x + backpack.size.x) <= window_right + 0.5, "node-select backpack stays inside the main window for %s" % label)
	_assert(float(backpack.position.x + backpack.size.x) <= float(row.size.x) + 1.0, "node-select backpack stays inside the row width for %s" % label)
	_assert(float(node_map_scene.size.x) >= 460.0, "node-select node map keeps the explicit map minimum width for %s" % label)
	_assert(float(node_map_scene.size.x + backpack.size.x + row_gap) <= float(row.size.x) + 1.5, "node-select map/backpack split stays within the row width for %s" % label)
	var graph_center_delta := absf(float(node_map_scene.node_visual_center_x()) - float(node_map_scene.map_canvas_center_x()))
	_assert(graph_center_delta <= 24.0, "node-select graph stays centered inside the map canvas for %s (delta=%.3f)" % [label, graph_center_delta])
	_assert_eq(node_map_scene.loadout_color_count(), 4 if expect_color_picker else 0, "node-select color-picker visibility matches the stage contract for %s" % label)
