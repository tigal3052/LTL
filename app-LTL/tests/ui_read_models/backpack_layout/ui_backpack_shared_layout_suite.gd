extends "res://tests/support/UiReadModelTestSuite.gd"
func run_all_tests() -> Dictionary:
	failures.clear()
	test_surface_pages_expose_backpack_host_without_embedded_engine_panel()
	test_main_view_backpack_runtime_targets_single_shared_panel()
	test_backpack_pin_layout_policy_unifies_backpack_and_main_width_math()
	test_backpack_grid_keeps_expand_fill_layout_with_shell_gutter()
	test_backpack_shell_gutter_uses_side_margin_overhang_only_in_combat()
	test_main_scene_backpack_grid_uses_shell_gutter_layout()
	test_main_scene_shared_layout_text_nodes_do_not_fit_content()
	test_main_scene_reward_tray_row_expands_to_keep_discard_zone_inside_panel()
	test_main_ui_load_chain_survives_reward_reveal_preloads()
	return _result()
func test_surface_pages_expose_backpack_host_without_embedded_engine_panel() -> void:
	for scene_path in [
		"res://src/scenes/pages/BattlePage.tscn",
		"res://src/scenes/pages/RewardPage.tscn",
		"res://src/scenes/pages/BossBattlePage.tscn",
		"res://src/scenes/pages/BossRewardPage.tscn"
	]:
		var page_scene = load(scene_path)
		_assert(page_scene != null, "%s loads for empty backpack host contract" % scene_path)
		if page_scene == null:
			continue
		var page = page_scene.instantiate()
		_assert(page != null, "%s instantiates for empty backpack host contract" % scene_path)
		if page == null:
			continue
		var host = page.get_node_or_null("TopContent/BoardPanel/BoardMargin/BoardBox/BoardArea/BackpackContainer") as AspectRatioContainer
		_assert(host != null, "%s exposes the board-panel BackpackContainer as the shared backpack host" % scene_path)
		_assert(page.get_node_or_null("TopContent/BoardPanel/BoardMargin/BoardBox/BoardArea/BackpackContainer/BackpackEnginePanel") == null, "%s no longer embeds a page-local BackpackEnginePanel" % scene_path)
		page.free()
func test_main_view_backpack_runtime_targets_single_shared_panel() -> void:
	var helper_path := "res://src/ui/main_view/MainViewBackpackRuntime.gd"
	var source := _source_text(helper_path)
	_assert(source.find("static func create_shared_backpack") >= 0, "main view backpack runtime exposes shared backpack creation")
	_assert(source.find("static func connect_shared_backpack_signals") >= 0, "main view backpack runtime exposes one-time shared backpack signal wiring")
	_assert(source.find("for bundle in view.page_shell_bundles.values():") < 0, "main view backpack runtime no longer loops over page-local backpacks for render/setup/ghost updates")
	_assert(source.find("view.backpack_ui.render_backpack_items") >= 0, "main view backpack runtime renders inventory through the single shared backpack ui")
func test_backpack_pin_layout_policy_unifies_backpack_and_main_width_math() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	var BackpackPinLayoutPolicyScript = load("res://src/ui/presenters/BackpackPinLayoutPolicy.gd")
	var backpack_ui = BackpackUIScript.new()
	_assert(BackpackPinLayoutPolicyScript != null, "backpack pin layout policy script exists so repeated pin sizing math has a single owner")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for shared backpack pin policy contract")
	if BackpackPinLayoutPolicyScript == null or MainViewRuntimeScript == null:
		return
	_assert(BackpackPinLayoutPolicyScript.has_method("slot_extent_for_grid_extent"), "pin policy exposes shared slot extent math")
	_assert(BackpackPinLayoutPolicyScript.has_method("top_content_width_for_height"), "pin policy exposes top-content width math")
	if not BackpackPinLayoutPolicyScript.has_method("slot_extent_for_grid_extent") or not BackpackPinLayoutPolicyScript.has_method("top_content_width_for_height"):
		return
	var grid_extent := 548.0
	var policy_slot := float(BackpackPinLayoutPolicyScript.slot_extent_for_grid_extent(grid_extent))
	var policy_outset := float(BackpackPinLayoutPolicyScript.side_outset_for_grid_extent(grid_extent))
	var policy_width := float(BackpackPinLayoutPolicyScript.top_content_width_for_height(grid_extent))
	_assert_close(float(backpack_ui.call("pin_slot_extent_for_grid_extent", grid_extent)), policy_slot, 0.001, "backpack delegates slot extent math to the shared pin policy")
	_assert_close(float(backpack_ui.call("pin_side_outset_for_grid_extent", grid_extent)), policy_outset, 0.001, "backpack delegates side-outset math to the shared pin policy")
	_assert_close(float(MainViewRuntimeScript.top_content_backpack_width_for_height(grid_extent)), policy_width, 0.001, "main view delegates top-content width math to the shared pin policy")
func test_backpack_grid_keeps_expand_fill_layout_with_shell_gutter() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("backpack_grid_horizontal_flags"), "backpack exposes grid horizontal sizing policy")
	if not backpack_ui.has_method("backpack_grid_horizontal_flags"):
		return
	_assert_eq(int(backpack_ui.call("backpack_grid_horizontal_flags")), int(Control.SIZE_EXPAND_FILL), "backpack grid keeps expand-fill layout so only shell margins create the pin gutter")
func test_backpack_shell_gutter_uses_side_margin_overhang_only_in_combat() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("pin_shell_side_margin_for_outset"), "backpack exposes side-margin gutter helper for combat pin shell")
	if not backpack_ui.has_method("pin_shell_side_margin_for_outset"):
		return
	_assert_eq(int(backpack_ui.call("pin_shell_side_margin_for_outset", 24.4, false)), 16, "non-combat backpack keeps the base side margin with no pin gutter")
	_assert_eq(int(backpack_ui.call("pin_shell_side_margin_for_outset", 24.4, true)), 40, "combat backpack converts pin overhang into extra side margin gutter")
func test_main_scene_backpack_grid_uses_shell_gutter_layout() -> void:
	var BackpackEnginePanelScene = load("res://src/scenes/pages/shells/BackpackEnginePanel.tscn")
	_assert(BackpackEnginePanelScene != null, "shared backpack engine panel shell loads for backpack shell gutter layout contract")
	if BackpackEnginePanelScene == null:
		return
	var engine_panel = BackpackEnginePanelScene.instantiate()
	_assert(engine_panel != null, "shared backpack engine panel shell instantiates for backpack shell gutter layout contract")
	if engine_panel == null:
		return
	var grid = engine_panel.get_node_or_null("Margin/EngineBox/GridMock") as GridContainer
	_assert(grid != null, "shared backpack engine panel exposes the backpack grid node")
	if grid != null:
		_assert_eq(int(grid.size_flags_horizontal), int(Control.SIZE_EXPAND_FILL), "shared backpack engine panel grid remains expand-fill and relies on shell margins for pin gutter spacing")
	engine_panel.free()
func test_main_scene_shared_layout_text_nodes_do_not_fit_content() -> void:
	var RewardPanelScene = load("res://src/scenes/pages/shells/RewardPanel.tscn")
	var NodeSelectRuntimePageScene = load("res://src/scenes/pages/NodeSelectRuntimePage.tscn")
	_assert(RewardPanelScene != null, "reward-panel shell loads for shared split-layout text policy")
	_assert(NodeSelectRuntimePageScene != null, "node-select runtime page scene loads for shared split-layout text policy")
	if RewardPanelScene == null or NodeSelectRuntimePageScene == null:
		return
	var reward_panel = RewardPanelScene.instantiate()
	var node_select_page = NodeSelectRuntimePageScene.instantiate()
	_assert(reward_panel != null, "reward-panel shell instantiates for shared split-layout text policy")
	_assert(node_select_page != null, "node-select runtime page instantiates for shared split-layout text policy")
	if reward_panel == null or node_select_page == null:
		return
	var reward_summary = reward_panel.get_node_or_null("Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/InspectorSummary") as RichTextLabel
	var reward_name = reward_panel.get_node_or_null("Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/InspectorName") as Label
	var node_select_name = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/InfoCard/InfoMargin/InfoVBox/InfoName") as Label
	var node_select_body = node_select_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/InfoCard/InfoMargin/InfoVBox/InfoBody") as Label
	_assert(node_select_name != null, "node-select runtime page exposes the info-card title text view")
	_assert(node_select_body != null, "node-select runtime page exposes the info-card body text view")
	_assert(reward_summary != null, "main scene exposes the reward inspector summary view")
	_assert(reward_name != null, "main scene exposes the reward inspector title view")
	if node_select_name != null:
		_assert_eq(int(node_select_name.autowrap_mode), int(TextServer.AUTOWRAP_WORD_SMART), "node-select info-card title wraps inside the shared screen shell")
	if node_select_body != null:
		_assert_eq(int(node_select_body.autowrap_mode), int(TextServer.AUTOWRAP_WORD_SMART), "node-select info-card body wraps inside the shared screen shell")
	if reward_summary != null:
		_assert_eq(bool(reward_summary.fit_content), false, "reward inspector summary does not content-fit and resize the board columns")
		_assert_eq(int(reward_summary.autowrap_mode), int(TextServer.AUTOWRAP_WORD_SMART), "reward inspector summary wraps inside the fixed inspector panel")
	if reward_name != null:
		_assert_eq(int(reward_name.autowrap_mode), int(TextServer.AUTOWRAP_WORD_SMART), "reward inspector title wraps instead of widening the shared reward-board split")
		_assert_eq(int(reward_name.size_flags_horizontal), int(Control.SIZE_EXPAND_FILL), "reward inspector title expands within the fixed panel instead of requesting its own wider column")
	node_select_page.free()
	reward_panel.free()
func test_main_scene_reward_tray_row_expands_to_keep_discard_zone_inside_panel() -> void:
	var RewardPanelScene = load("res://src/scenes/pages/shells/RewardPanel.tscn")
	_assert(RewardPanelScene != null, "reward-panel shell loads for reward tray row expansion policy")
	if RewardPanelScene == null:
		return
	var reward_panel = RewardPanelScene.instantiate()
	_assert(reward_panel != null, "reward-panel shell instantiates for reward tray row expansion policy")
	if reward_panel == null:
		return
	var reward_box = reward_panel.get_node_or_null("Margin/RewardBox") as VBoxContainer
	var reward_board = reward_panel.get_node_or_null("Margin/RewardBox/RewardBoardScroll/RewardBoard") as VBoxContainer
	var reward_grid = reward_panel.get_node_or_null("Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid") as HBoxContainer
	var workspace_note = reward_panel.get_node_or_null("Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/WorkspaceNote") as RichTextLabel
	var backpack_host = reward_panel.get_node_or_null("Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/BackpackHost") as Control
	var bottom_row = reward_panel.get_node_or_null("Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow") as HBoxContainer
	var discard_zone = reward_panel.get_node_or_null("Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone") as PanelContainer
	var confirm_zone = reward_panel.get_node_or_null("Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone") as PanelContainer
	_assert(reward_box != null, "reward-panel shell exposes the reward tray box container")
	_assert(reward_board != null, "reward-panel shell exposes the reward claim board root container")
	_assert(reward_grid != null, "reward-panel shell exposes the reward claim board three-column layout")
	_assert(workspace_note != null, "reward-panel shell exposes the reward workspace note text surface")
	_assert(backpack_host != null, "reward-panel shell exposes the reward board backpack host")
	_assert(bottom_row != null, "reward-panel shell exposes the reward claim bottom row")
	_assert(discard_zone != null, "reward-panel shell exposes the reward tray discard zone")
	_assert(confirm_zone != null, "reward-panel shell exposes the inline claim confirmation zone")
	if reward_box != null:
		_assert_eq(int(reward_box.size_flags_vertical), int(Control.SIZE_EXPAND_FILL), "reward claim box expands vertically so the board can use the full panel height")
	if reward_board != null:
		_assert_eq(int(reward_board.size_flags_vertical), int(Control.SIZE_EXPAND_FILL), "reward claim board expands vertically instead of collapsing into the legacy strip")
	if reward_grid != null:
		_assert_eq(int(reward_grid.size_flags_horizontal), int(Control.SIZE_EXPAND_FILL), "reward claim grid expands horizontally so the three zones stay inside the reward panel width")
		_assert_eq(int(reward_grid.size_flags_vertical), int(Control.SIZE_EXPAND_FILL), "reward claim grid expands vertically so the workspace owns the main board body")
	if workspace_note != null:
		_assert_eq(bool(workspace_note.fit_content), false, "reward workspace note does not content-fit and distort the board height")
		_assert_eq(int(workspace_note.autowrap_mode), int(TextServer.AUTOWRAP_WORD_SMART), "reward workspace note wraps inside the center workspace card")
	if backpack_host != null:
		_assert_eq(int(backpack_host.size_flags_vertical), int(Control.SIZE_EXPAND_FILL), "reward board backpack host stretches to reserve a dedicated placement workspace")
	if bottom_row != null:
		_assert_eq(int(bottom_row.size_flags_horizontal), int(Control.SIZE_EXPAND_FILL), "reward claim bottom row expands horizontally to keep discard and confirm zones on the board")
	if discard_zone != null:
		_assert_eq(int(discard_zone.size_flags_horizontal), int(Control.SIZE_EXPAND_FILL), "reward tray discard zone expands across the left half of the bottom row")
	if confirm_zone != null:
		_assert_eq(int(confirm_zone.size_flags_horizontal), int(Control.SIZE_EXPAND_FILL), "reward tray confirm zone expands across the right half of the bottom row")
	reward_panel.free()
func test_main_ui_load_chain_survives_reward_reveal_preloads() -> void:
	var RewardRevealOverlayScript = load("res://src/ui/RewardRevealOverlay.gd")
	_assert(RewardRevealOverlayScript != null, "reward reveal overlay compiles so main-view preloads do not break the main UI inheritance chain")
	if RewardRevealOverlayScript == null:
		return
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime compiles after the reward reveal overlay preload chain resolves cleanly")
	if MainViewRuntimeScript == null:
		return
	var MainUIScript = load("res://src/ui/MainUI.gd")
	_assert(MainUIScript != null, "main ui facade compiles through the main-view runtime preload chain without parser-resolution failure")
func _source_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text
