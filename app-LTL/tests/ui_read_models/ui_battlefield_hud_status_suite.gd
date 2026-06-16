extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	test_status_panel_extracts_info_cards_and_caps_owner()
	test_main_view_feedback_runtime_helper_exists()
	test_main_scene_uses_header_miner_status_timer_and_tabbed_sidebar()
	test_status_panel_scene_uses_node_info_and_drill_info_structure()
	test_status_panel_metric_cards_use_health_before_shield_with_round_dots()
	test_main_scene_status_panel_uses_fifo_two_row_energy_queue()
	test_hud_read_model_projects_fifo_queue_slots_and_capacity()
	test_apply_node_modifiers_keeps_weakness_multiplier_metadata_for_hud()
	test_failure_read_model_projects_run_failed_overlay()
	test_status_panel_overlay_honors_explicit_hidden_flag()
	return _result()

func test_status_panel_extracts_info_cards_and_caps_owner() -> void:
	var helper_path := "res://src/ui/status_panel/StatusPanelInfoCards.gd"
	_assert(FileAccess.file_exists(helper_path), "status panel info-card helper exists")
	if FileAccess.file_exists(helper_path):
		var HelperScript = load(helper_path)
		_assert(HelperScript != null, "status panel info-card helper loads")
		if HelperScript != null:
			_assert(HelperScript.has_method("node_meta_text"), "status panel info-card helper owns node metadata copy")
			_assert(HelperScript.has_method("metric_stack"), "status panel info-card helper owns metric card construction")
			_assert(HelperScript.has_method("render_note_row"), "status panel info-card helper owns node info note chips")
		var helper_lines := _source_line_count(helper_path)
		_assert(helper_lines > 0 and helper_lines <= 500, "status panel info-card helper stays within 500 lines, got %d" % helper_lines)
	var status_lines := _source_line_count("res://src/ui/StatusPanelUI.gd")
	_assert(status_lines > 0 and status_lines <= 500, "StatusPanelUI.gd stays within 500 lines after info-card extraction, got %d" % status_lines)

func test_main_view_feedback_runtime_helper_exists() -> void:
	var helper_path := "res://src/ui/main_view/MainViewFeedbackRuntime.gd"
	var HelperScript = load(helper_path)
	_assert(HelperScript != null, "MainView feedback runtime helper exists")
	if HelperScript != null:
		_assert(HelperScript.has_method("add_log"), "feedback helper owns log forwarding")
		_assert(HelperScript.has_method("update_discard_zone"), "feedback helper owns discard zone state")
		_assert(HelperScript.has_method("get_cell_global_pos"), "feedback helper owns battlefield cell positioning")
		_assert(HelperScript.has_method("trigger_damage_popups"), "feedback helper owns damage popup anchoring")
		_assert(HelperScript.has_method("trigger_screenshake"), "feedback helper owns screenshake triggering")
		_assert(_source_line_count(helper_path) <= 500, "MainView feedback helper stays within the 500-line cap")
	_assert(_source_line_count("res://src/ui/MainViewRuntime.gd") <= 946, "MainViewRuntime delegates combat feedback responsibilities")

func test_main_scene_uses_header_miner_status_timer_and_tabbed_sidebar() -> void:
	var BattlefieldPanelScene = load("res://src/scenes/pages/shells/BattlefieldPanel.tscn")
	var GameplayTopContentScene = load("res://src/scenes/pages/shells/GameplayTopContent.tscn")
	_assert(BattlefieldPanelScene != null, "battlefield shell scene loads for battlefield layout structure test")
	_assert(GameplayTopContentScene != null, "gameplay top-content shell scene loads for battlefield layout structure test")
	if BattlefieldPanelScene == null or GameplayTopContentScene == null:
		return
	var battlefield_panel = BattlefieldPanelScene.instantiate()
	var gameplay_top_content = GameplayTopContentScene.instantiate()
	_assert(battlefield_panel != null, "battlefield shell scene instantiates for battlefield layout structure test")
	_assert(gameplay_top_content != null, "gameplay top-content shell scene instantiates for battlefield layout structure test")
	if battlefield_panel == null or gameplay_top_content == null:
		return
	var header_miner = battlefield_panel.get_node_or_null("Margin/BattlefieldBox/BattlefieldVisualRoot/TitleMiner") as TextureRect
	_assert(header_miner != null, "battlefield title area now uses a miner texture instead of plain text")
	var lower_overlay_miner = battlefield_panel.get_node_or_null("Margin/BattlefieldBox/BattlefieldVisualRoot/MinerVisual")
	_assert(lower_overlay_miner == null, "battlefield visual root no longer keeps the old lower-left miner overlay")
	var retired_left_sidebar = gameplay_top_content.get_node_or_null("LeftColumn/LeftSidebar")
	_assert(retired_left_sidebar == null, "top-content shell removes the old left explorer sidebar so the drill/node panel can own the full left column")
	var info_shell = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/InfoShell") as PanelContainer
	var ops_shell = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/OpsShell") as PanelContainer
	var info_toggle_button = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/InfoShell/InfoMargin/InfoBox/InfoTitle") as Button
	var info_detail_shell = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/InfoShell/InfoMargin/InfoBox/InfoDetailShell") as PanelContainer
	var explorer_tab_button = gameplay_top_content.get_node_or_null("RightSidebar/Margin/SidebarBox/TabRow/ExplorerTabButton") as Button
	var log_info_tab_button = gameplay_top_content.get_node_or_null("RightSidebar/Margin/SidebarBox/TabRow/LogInfoTabButton") as Button
	var tab_viewport = gameplay_top_content.get_node_or_null("RightSidebar/Margin/SidebarBox/TabViewport") as Control
	var explorer_content = gameplay_top_content.get_node_or_null("RightSidebar/Margin/SidebarBox/TabViewport/ExplorerContent") as Control
	var log_content = gameplay_top_content.get_node_or_null("RightSidebar/Margin/SidebarBox/TabViewport/LogContent") as Control
	_assert(info_shell != null, "left status shell now exposes a dedicated upper combat-info section")
	_assert(ops_shell != null, "left status shell now exposes a dedicated lower drill-node operations section")
	_assert(info_toggle_button != null, "left combat-info title is a real toggle button instead of a static label")
	_assert(info_detail_shell != null, "left combat-info shell exposes the mockup-inspired dropdown detail panel")
	_assert(info_detail_shell != null and not info_detail_shell.visible, "left combat-info dropdown starts collapsed to preserve the compact runtime readout")
	_assert(explorer_tab_button != null, "right sidebar exposes the explorer-status default tab button")
	_assert(log_info_tab_button != null, "right sidebar exposes the system-log-and-info secondary tab button")
	_assert(tab_viewport != null, "right sidebar routes both tabs through one fixed content viewport instead of separate stacked layout rows")
	_assert(explorer_content != null and explorer_content.visible, "right sidebar keeps explorer status visible by default")
	_assert(log_content != null and not log_content.visible, "right sidebar hides the system log body until the alternate tab is selected")
	var footer_margin = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/CombatTimerFooterMargin") as MarginContainer
	_assert(footer_margin != null, "status panel exposes a dedicated footer margin for the relocated combat timer")
	if footer_margin != null:
		_assert_eq(footer_margin.get_theme_constant("margin_bottom"), 4, "status timer footer keeps a tighter 4px bottom breathing room in the compact battle HUD")
	var footer_timer = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/CombatTimerFooterMargin/CombatTimerFooter/CombatTimerLabel") as Label
	_assert(footer_timer != null, "status panel includes a large footer countdown label")
	if footer_timer != null:
		_assert_eq(footer_timer.get_theme_font_size("font_size"), 22, "status footer countdown uses the compact 22px size required by the battle HUD height budget")
	battlefield_panel.free()
	gameplay_top_content.free()

func test_status_panel_scene_uses_node_info_and_drill_info_structure() -> void:
	TextCatalogScript.set_locale("ko")
	_assert_eq(TextCatalogScript.t("panel.info.core"), "노드 정보", "combat info title localizes to node info")
	_assert_eq(TextCatalogScript.t("panel.drill_node_status"), "드릴 정보", "drill panel title no longer includes node status")
	TextCatalogScript.set_locale("en")
	_assert_eq(TextCatalogScript.t("panel.info.core"), "Node Info", "English combat info title localizes to node info")
	_assert_eq(TextCatalogScript.t("panel.drill_node_status"), "Drill Info", "English drill panel title no longer includes node status")
	TextCatalogScript.set_locale("ko")
	var GameplayTopContentScene = load("res://src/scenes/pages/shells/GameplayTopContent.tscn")
	_assert(GameplayTopContentScene != null, "gameplay top-content shell scene loads for node/drill info structure test")
	if GameplayTopContentScene == null:
		return
	var gameplay_top_content = GameplayTopContentScene.instantiate()
	_assert(gameplay_top_content != null, "gameplay top-content shell scene instantiates for node/drill info structure test")
	if gameplay_top_content == null:
		return
	var info_box = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/InfoShell/InfoMargin/InfoBox") as VBoxContainer
	var ops_box = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox") as VBoxContainer
	var node_card = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/InfoShell/InfoMargin/InfoBox/NodeCard") as PanelContainer
	var old_ops_node_card = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/NodeCard")
	var weakness_card_grid = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/InfoShell/InfoMargin/InfoBox/WeaknessCardGrid") as GridContainer
	var health_box = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/HPBox") as HBoxContainer
	var shield_box = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/ShieldBox") as HBoxContainer
	var row_labels := [
		gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/HPBox/HealthLabel") as Label,
		gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/ShieldBox/ShieldLabel") as Label,
		gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/QueueRow/QueueLabel") as Label,
		gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/TimerRow/PinLabel") as Label,
		gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/DrillStatusRow/DrillStatusLabel") as Label
	]
	_assert(info_box != null, "node info box exists for node-card ownership test")
	_assert(ops_box != null, "drill info box exists for row ordering test")
	_assert(node_card != null, "node status card lives under the node info shell")
	_assert(old_ops_node_card == null, "drill info shell no longer owns the node status card")
	_assert(node_card != null and not node_card.visible, "node status card starts hidden while node info is collapsed")
	_assert(weakness_card_grid != null and not weakness_card_grid.visible, "multiplier cards start hidden so collapsed node info is a thin weakness text panel")
	if health_box != null and shield_box != null:
		_assert(health_box.get_index() < shield_box.get_index(), "health row is ordered before shield row in the drill info panel")
	for label in row_labels:
		_assert(label != null, "drill info row label exists for equal-width alignment")
		if label != null:
			_assert_eq(float(label.custom_minimum_size.x), 76.0, "drill info row label uses the shared alignment width")
	gameplay_top_content.free()

func test_status_panel_metric_cards_use_health_before_shield_with_round_dots() -> void:
	var status_panel = StatusPanelUIScript.new()
	var stack := status_panel.call("_metric_stack", 1.35, 1.25) as GridContainer
	_assert(stack != null, "status panel builds multiplier card stack for order test")
	if stack == null:
		status_panel.free()
		return
	_assert_eq(int(stack.columns), 2, "expanded multiplier cards use two columns for health/shield pairs")
	_assert_eq(stack.get_child_count(), 2, "metric stack has one health card and one shield card")
	if stack.get_child_count() >= 2:
		var first_label = stack.get_child(0).find_child("MetricLabel", true, false) as Label
		var second_label = stack.get_child(1).find_child("MetricLabel", true, false) as Label
		var first_dot = stack.get_child(0).find_child("MetricDot", true, false) as Panel
		var second_dot = stack.get_child(1).find_child("MetricDot", true, false) as Panel
		_assert(first_label != null and first_label.text.contains("체력"), "health multiplier card appears before shield")
		_assert(second_label != null and second_label.text.contains("실드"), "shield multiplier card appears after health")
		_assert(first_dot != null, "health multiplier card uses a rounded dot marker")
		_assert(second_dot != null, "shield multiplier card uses a rounded dot marker")
	stack.queue_free()
	status_panel.free()

func test_main_scene_status_panel_uses_fifo_two_row_energy_queue() -> void:
	var status_panel = StatusPanelUIScript.new()
	_assert_eq(int(StatusPanelUIScript.ENERGY_QUEUE_COLUMNS), 8, "status panel energy queue uses eight columns per row for the FIFO layout")
	_assert_eq(int(StatusPanelUIScript.ENERGY_QUEUE_ROWS), 2, "status panel energy queue renders two rows so 8-slot and 16-slot states share one structure")
	_assert_eq(int(StatusPanelUIScript.ENERGY_QUEUE_MAX_SLOTS), 16, "status panel energy queue reserves the full sixteen-slot ceiling for expansion")
	_assert(status_panel != null and status_panel.has_method("render_hud_projection"), "status panel exposes a projected HUD render entry point for the FIFO queue surface")
	status_panel.free()

func test_hud_read_model_projects_fifo_queue_slots_and_capacity() -> void:
	var model := HudReadModelScript.project({
		"hud": {
			"queue": {
				"items": ["green", "blue", "purple", "red"],
				"loaded": 4,
				"capacity": 8
			},
			"aim": {"canFire": true, "cellId": "r1c2", "targetColor": "green"},
			"repair": {"active": false},
			"pin": {"progress": 20.0},
			"hazard": {"active": true, "severity": "active", "label": "green", "obstacleCount": 2}
		},
		"feedback": {"status": "match"},
		"targetPanel": {"weakness": ["green"]}
	})
	var queue: Dictionary = model.get("queue", {})
	_assert_eq(queue.get("activeColor", ""), "green", "hud read model keeps the front token as the active FIFO color")
	_assert_eq(queue.get("slotColors", []), ["green", "blue", "purple", "red"], "hud read model preserves contiguous FIFO slot order without collapsing the middle into reserve")
	_assert_eq(int(queue.get("capacity", -1)), 8, "hud read model keeps the live queue capacity")
	_assert_eq(int(queue.get("maxCapacity", -1)), 16, "hud read model exposes the maximum queue ceiling for disabled-slot rendering")
	_assert_eq(int(queue.get("rowSize", -1)), 8, "hud read model exposes the fixed row size used by the two-row queue")
	_assert_eq(bool(queue.get("queueMatch", false)), true, "hud read model exposes whether the front token matches the target weakness")
	_assert_eq(str(model.get("repair", {}).get("stage", "")), "strained", "hud read model escalates hazard-active combat into strained repair stage")

func test_apply_node_modifiers_keeps_weakness_multiplier_metadata_for_hud() -> void:
	var ApplyNodeModifiersScript = load("res://src/vocabulary/node/ApplyNodeModifiers.gd")
	_assert(ApplyNodeModifiersScript != null, "apply-node-modifiers script loads for HUD multiplier projection test")
	if ApplyNodeModifiersScript == null:
		return
	var applied: Dictionary = ApplyNodeModifiersScript.apply({
		"id": "mixed_fault",
		"label": "Mixed Fault",
		"nodeType": "mixed_weakness",
		"riskTier": "hard",
		"weakness": ["blue", "purple"],
		"shieldMul": 1.35,
		"healthMul": 1.25,
		"shieldMulByColor": {"blue": 1.10, "purple": 1.35},
		"healthMulByColor": {"blue": 1.40, "purple": 1.25},
		"rewardBias": "multi_energy",
		"recommendedBuildHint": "Blue or purple coverage",
		"difficultyModifier": 1.25,
		"rewardModifier": 1.25,
		"hazardModifier": 1.1,
		"combat": {"shield": 12.0, "health": 14.0}
	})
	var node: Dictionary = applied.get("combat", {}).get("node", {})
	_assert_eq(float(node.get("shieldMul", -1.0)), 1.35, "selected node snapshot keeps the shield multiplier for terrain info cards")
	_assert_eq(float(node.get("healthMul", -1.0)), 1.25, "selected node snapshot keeps the health multiplier for terrain info cards")
	_assert_eq(float(node.get("shieldMulByColor", {}).get("blue", -1.0)), 1.10, "selected node snapshot keeps per-color shield multipliers for composite terrain cards")
	_assert_eq(float(node.get("healthMulByColor", {}).get("purple", -1.0)), 1.25, "selected node snapshot keeps per-color health multipliers for composite terrain cards")

func test_failure_read_model_projects_run_failed_overlay() -> void:
	TextCatalogScript.set_locale("en")
	var failure_model := FailureReadModelScript.project({
		"phase": "run_complete",
		"failed": true,
		"lastNodeLabel": "Storm Spine",
		"stageIndex": 2,
		"maxStages": 4
	})
	_assert_eq(str(failure_model.get("mode", "")), "run_failed", "failure read model projects the failed run overlay mode")
	_assert_eq(str(failure_model.get("accent", "")), "danger", "failure read model marks failed runs as danger state")
	_assert(str(failure_model.get("cause", "")).contains("Storm Spine"), "failure read model keeps the last node label in the failure cause")
	_assert_eq(bool(failure_model.get("showResetHint", false)), true, "failure read model prompts reset on failed expeditions")
	TextCatalogScript.set_locale("ko")

func test_status_panel_overlay_honors_explicit_hidden_flag() -> void:
	var status_panel = StatusPanelUIScript.new()
	var overlay := PanelContainer.new()
	var center := CenterContainer.new()
	center.name = "Center"
	overlay.add_child(center)
	var warning_box := VBoxContainer.new()
	warning_box.name = "WarningBox"
	center.add_child(warning_box)
	var warning_label := Label.new()
	warning_label.name = "WarningLabel"
	warning_box.add_child(warning_label)
	var description_label := Label.new()
	description_label.name = "DescriptionLabel"
	warning_box.add_child(description_label)
	status_panel.render_repair_overlay({}, overlay, {
		"mode": "run_failed",
		"visible": false,
		"title": "Expedition Failed",
		"cause": "The contract broke.",
		"tip": "Try a safer route.",
		"accent": "danger"
	})
	_assert_eq(overlay.visible, false, "status panel respects explicit hidden overlay requests so defeat pages can own the full screen")

func _source_line_count(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1
	var count := 0
	while not file.eof_reached():
		file.get_line()
		count += 1
	return count
