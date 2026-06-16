extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_backpack_ui_extracts_pin_and_artifact_runtime_helpers()
	test_main_view_backpack_runtime_helper_exists()
	test_shared_backpack_scene_composes_one_engine_panel()
	test_surface_pages_expose_backpack_host_without_embedded_engine_panel()
	test_main_view_backpack_runtime_targets_single_shared_panel()
	test_backpack_pin_layout_policy_unifies_backpack_and_main_width_math()
	test_backpack_grid_keeps_expand_fill_layout_with_shell_gutter()
	test_backpack_shell_gutter_uses_side_margin_overhang_only_in_combat()
	test_main_scene_backpack_grid_uses_shell_gutter_layout()
	test_main_scene_shared_layout_text_nodes_do_not_fit_content()
	test_main_scene_reward_tray_row_expands_to_keep_discard_zone_inside_panel()
	test_main_ui_load_chain_survives_reward_reveal_preloads()
	test_backpack_pin_contract_maps_count_and_corner_order()
	test_backpack_pin_nodes_stay_in_backpack_local_canvas()
	test_backpack_pin_nodes_live_under_overlay_canvas()
	test_backpack_pin_nodes_use_trimmed_atlas_regions()
	test_backpack_pin_corner_anchor_helper_uses_requested_side_centers()
	test_backpack_pin_display_size_stays_small_relative_to_one_slot()
	test_backpack_pin_visibility_removes_in_requested_order()
	test_backpack_pin_vfx_contract_is_localized_pullout()
	return _result()

func test_backpack_ui_extracts_pin_and_artifact_runtime_helpers() -> void:
	var pin_helper_path := "res://src/ui/backpack/BackpackPinOverlayRuntime.gd"
	var artifact_helper_path := "res://src/ui/backpack/BackpackArtifactRenderer.gd"
	var PinHelper = load(pin_helper_path)
	var ArtifactHelper = load(artifact_helper_path)
	_assert(PinHelper != null, "backpack pin overlay runtime helper exists")
	_assert(ArtifactHelper != null, "backpack artifact renderer helper exists")
	if PinHelper != null:
		_assert(PinHelper.has_method("visible_count"), "pin helper owns pin count mapping")
		_assert(PinHelper.has_method("layout"), "pin helper owns pin overlay layout")
		_assert(_source_line_count(pin_helper_path) <= 500, "pin helper stays within the 500-line cap")
	if ArtifactHelper != null:
		_assert(ArtifactHelper.has_method("render_items"), "artifact helper owns backpack item rendering")
		_assert(ArtifactHelper.has_method("control_rect_in_layer_space"), "artifact helper owns transformed rect math")
		_assert(_source_line_count(artifact_helper_path) <= 500, "artifact helper stays within the 500-line cap")
	_assert(_source_line_count("res://src/ui/BackpackUI.gd") <= 500, "BackpackUI delegates runtime helpers and stays within 500 lines")

func test_main_view_backpack_runtime_helper_exists() -> void:
	var helper_path := "res://src/ui/main_view/MainViewBackpackRuntime.gd"
	var Helper = load(helper_path)
	_assert(Helper != null, "main view backpack runtime helper exists")
	if Helper != null:
		_assert(Helper.has_method("create_shared_backpack"), "backpack helper owns the single shared backpack scene creation")
		_assert(Helper.has_method("connect_shared_backpack_signals"), "backpack helper owns one-time shared backpack signal wiring")
		_assert(Helper.has_method("setup_backpack_slots"), "backpack helper owns page backpack slot setup")
		_assert(Helper.has_method("render_backpack"), "backpack helper owns page backpack item rendering")
		_assert(Helper.has_method("schedule_backpack_reparent"), "backpack helper owns shared backpack reparent scheduling")
		_assert(Helper.has_method("commit_backpack_reparent"), "backpack helper owns shared backpack reparent commit")
		_assert(Helper.has_method("flush_pending_backpack_pin_scene"), "backpack helper owns delayed pin-scene flushing")
		_assert(_source_line_count(helper_path) <= 500, "main view backpack runtime helper stays within the 500-line cap")
	_assert(_source_line_count("res://src/ui/MainViewRuntime.gd") <= 965, "MainViewRuntime delegates shared backpack runtime responsibilities")

func test_shared_backpack_scene_composes_one_engine_panel() -> void:
	var SharedBackpackScene = load("res://src/scenes/pages/shells/SharedBackpack.tscn")
	var BackpackUIScript = load("res://src/ui/BackpackUI.gd")
	_assert(SharedBackpackScene != null, "shared backpack scene exists so page shells can host one live backpack instance")
	_assert(BackpackUIScript != null, "backpack ui script loads for shared backpack scene contract")
	if SharedBackpackScene == null:
		return
	var shared = SharedBackpackScene.instantiate()
	_assert(shared is AspectRatioContainer, "shared backpack scene root is the AspectRatioContainer moved between hosts")
	var engine_panel = shared.get_node_or_null("BackpackEnginePanel")
	_assert(engine_panel != null, "shared backpack scene owns exactly one BackpackEnginePanel child")
	if engine_panel != null and BackpackUIScript != null:
		_assert(engine_panel.get_script() == BackpackUIScript, "shared backpack engine panel uses the production BackpackUI script")
	if shared != null:
		shared.free()

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
		var host = page.get_node_or_null("TopContent/BackpackContainer") as AspectRatioContainer
		_assert(host != null, "%s exposes TopContent/BackpackContainer as the shared backpack host" % scene_path)
		_assert(page.get_node_or_null("TopContent/BackpackContainer/BackpackEnginePanel") == null, "%s no longer embeds a page-local BackpackEnginePanel" % scene_path)
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

func test_backpack_pin_contract_maps_count_and_corner_order() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("pin_visible_count"), "backpack ui exposes deterministic pin-count mapping for the combat HUD")
	_assert(backpack_ui.has_method("pin_corner_specs"), "backpack ui exposes deterministic pin corner ordering for the overlay art")
	_assert(backpack_ui.has_method("_setup_pin_overlays"), "backpack ui keeps the pin overlay setup helper so ready-time initialization cannot regress")
	_assert(backpack_ui.has_method("_layout_pin_overlays"), "backpack ui keeps the pin overlay layout helper so corner pins can be repositioned after resize")
	if not backpack_ui.has_method("pin_visible_count") or not backpack_ui.has_method("pin_corner_specs") or not backpack_ui.has_method("_setup_pin_overlays") or not backpack_ui.has_method("_layout_pin_overlays"):
		return
	_assert_eq(int(backpack_ui.call("pin_visible_count", true, 100.0)), 4, "active pin hazard with full progress keeps all four backpack pins visible")
	_assert_eq(int(backpack_ui.call("pin_visible_count", true, 74.9)), 2, "pin count drops one by one as progress crosses the quarter thresholds")
	backpack_ui.call("update_pin_overlays", {"phase": "combat", "hud": {"pin": {"active": false, "progress": 100.0}}})
	_assert_eq(int(backpack_ui.visible_pin_count_value), 4, "combat backpack pins stay visible from progress even when the transient mismatch pin flag is currently false")
	backpack_ui.call("update_pin_overlays", {"phase": "reward_loot", "hud": {"pin": {"active": false, "progress": 100.0}}})
	_assert_eq(int(backpack_ui.visible_pin_count_value), 0, "non-combat phases hide the backpack corner pins entirely")
	var corner_specs: Array = backpack_ui.call("pin_corner_specs")
	_assert_eq(corner_specs.size(), 4, "backpack pin overlay defines exactly four corner specs")
	_assert_eq(corner_specs[0], {"name": "Pin1", "column": 0, "row": 0, "horizontal": "left", "vertical": "center"}, "pin_1 anchors to the left side of backpack_1")
	_assert_eq(corner_specs[1], {"name": "Pin2", "column": 9, "row": 0, "horizontal": "right", "vertical": "center"}, "pin_2 anchors to the right side of backpack_3")
	_assert_eq(corner_specs[2], {"name": "Pin3", "column": 9, "row": 9, "horizontal": "right", "vertical": "center"}, "pin_3 anchors to the right side of backpack_9")
	_assert_eq(corner_specs[3], {"name": "Pin4", "column": 0, "row": 9, "horizontal": "left", "vertical": "center"}, "pin_4 anchors to the left side of backpack_7")

func test_backpack_pin_nodes_stay_in_backpack_local_canvas() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("_setup_pin_overlays"), "backpack ui keeps the pin overlay builder for local-canvas layout checks")
	if not backpack_ui.has_method("_setup_pin_overlays"):
		return
	backpack_ui.call("_setup_pin_overlays")
	_assert_eq(backpack_ui.pin_nodes.size(), 4, "backpack builds exactly four pin nodes for combat layout")
	if backpack_ui.pin_nodes.is_empty():
		return
	_assert_eq(bool((backpack_ui.pin_nodes[0] as TextureRect).top_level), false, "backpack pins stay in the backpack local canvas so corner placement cannot drift across other HUD panels")

func test_backpack_pin_nodes_live_under_overlay_canvas() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("_setup_pin_overlays"), "backpack ui keeps the pin overlay builder for overlay-canvas parenting checks")
	if not backpack_ui.has_method("_setup_pin_overlays"):
		return
	backpack_ui.call("_setup_pin_overlays")
	_assert_eq(backpack_ui.pin_nodes.size(), 4, "backpack builds exactly four pin nodes for overlay-canvas parenting checks")
	if backpack_ui.pin_nodes.is_empty():
		return
	var parent := (backpack_ui.pin_nodes[0] as TextureRect).get_parent()
	_assert(parent != backpack_ui, "backpack pins no longer live directly under the PanelContainer, which would force them to full-rect container sizing")
	_assert(parent is Control, "backpack pins mount under a non-container control canvas so explicit size and position survive runtime layout")

func test_backpack_pin_nodes_use_trimmed_atlas_regions() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("_setup_pin_overlays"), "backpack ui keeps the pin overlay builder for trimmed-region checks")
	if not backpack_ui.has_method("_setup_pin_overlays"):
		return
	backpack_ui.call("_setup_pin_overlays")
	var expected_regions := [
		Rect2(211, 237, 863, 655),
		Rect2(328, 237, 863, 655),
		Rect2(328, 230, 863, 655),
		Rect2(211, 230, 863, 655)
	]
	for index in range(mini(backpack_ui.pin_nodes.size(), expected_regions.size())):
		var pin := backpack_ui.pin_nodes[index] as TextureRect
		_assert(pin != null, "backpack pin node exists for trimmed atlas-region validation")
		if pin == null:
			continue
		var atlas := pin.texture as AtlasTexture
		_assert(atlas != null, "backpack pin_%d uses a trimmed atlas texture so transparent padding cannot distort layout" % [index + 1])
		if atlas != null:
			_assert_eq(atlas.region, expected_regions[index], "backpack pin_%d trims to the measured visible bounds before size and anchor math run" % [index + 1])

func test_backpack_pin_corner_anchor_helper_uses_requested_side_centers() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("pin_corner_anchor_for_rect"), "backpack ui exposes a rect-based corner anchor helper for pin placement")
	if not backpack_ui.has_method("pin_corner_anchor_for_rect") or not backpack_ui.has_method("pin_corner_specs"):
		return
	var grid_rect := Rect2(Vector2(120.0, 80.0), Vector2(32.0, 32.0))
	var specs: Array = backpack_ui.call("pin_corner_specs")
	_assert_eq(backpack_ui.call("pin_corner_anchor_for_rect", grid_rect, specs[0]), Vector2(120.0, 96.0), "pin_1 anchor snaps to the left-center of backpack_1")
	_assert_eq(backpack_ui.call("pin_corner_anchor_for_rect", grid_rect, specs[1]), Vector2(152.0, 96.0), "pin_2 anchor snaps to the right-center of backpack_3")
	_assert_eq(backpack_ui.call("pin_corner_anchor_for_rect", grid_rect, specs[2]), Vector2(152.0, 96.0), "pin_3 anchor snaps to the right-center of backpack_9")
	_assert_eq(backpack_ui.call("pin_corner_anchor_for_rect", grid_rect, specs[3]), Vector2(120.0, 96.0), "pin_4 anchor snaps to the left-center of backpack_7")

func test_backpack_pin_display_size_stays_small_relative_to_one_slot() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("pin_display_size_for_slot_extent"), "backpack exposes a concrete display-size helper for the smaller pin art")
	if not backpack_ui.has_method("pin_display_size_for_slot_extent"):
		return
	var pin_size: Vector2 = backpack_ui.call("pin_display_size_for_slot_extent", 53.0)
	_assert_close(pin_size.x, 69.830534, 0.001, "trimmed pin width now follows the visible silhouette instead of the padded PNG canvas")
	_assert_close(pin_size.y, 53.0, 0.001, "trimmed pin height now fits roughly one live grid slot")

func test_backpack_pin_visibility_removes_in_requested_order() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("pin_visible_indices"), "backpack exposes deterministic visible pin index mapping")
	_assert(backpack_ui.has_method("pin_is_visible"), "backpack exposes per-index pin visibility helper")
	if not backpack_ui.has_method("pin_visible_indices") or not backpack_ui.has_method("pin_is_visible"):
		return
	_assert_eq(backpack_ui.call("pin_visible_indices", 4), [0, 1, 2, 3], "all pins visible at full count")
	_assert_eq(backpack_ui.call("pin_visible_indices", 3), [1, 2, 3], "pin_1 is removed first")
	_assert_eq(backpack_ui.call("pin_visible_indices", 2), [2, 3], "pin_2 is removed second")
	_assert_eq(backpack_ui.call("pin_visible_indices", 1), [3], "pin_3 is removed third")
	_assert_eq(backpack_ui.call("pin_visible_indices", 0), [], "pin_4 is removed last")
	_assert_eq(bool(backpack_ui.call("pin_is_visible", 0, 3)), false, "pin_1 hidden when three pins remain")
	_assert_eq(bool(backpack_ui.call("pin_is_visible", 3, 1)), true, "pin_4 remains when one pin remains")

func test_backpack_pin_vfx_contract_is_localized_pullout() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("pin_pull_direction_for_index"), "backpack exposes pull direction helper for pin removal VFX")
	_assert(backpack_ui.has_method("pin_removal_vfx_profile_for_index"), "backpack exposes deterministic removal VFX profile")
	if not backpack_ui.has_method("pin_pull_direction_for_index") or not backpack_ui.has_method("pin_removal_vfx_profile_for_index"):
		return
	_assert_eq(backpack_ui.call("pin_pull_direction_for_index", 0), Vector2(-1, -1).normalized(), "pin_1 pulls out toward the top-left")
	_assert_eq(backpack_ui.call("pin_pull_direction_for_index", 1), Vector2(1, -1).normalized(), "pin_2 pulls out toward the top-right")
	_assert_eq(backpack_ui.call("pin_pull_direction_for_index", 2), Vector2(1, 1).normalized(), "pin_3 pulls out toward the bottom-right")
	_assert_eq(backpack_ui.call("pin_pull_direction_for_index", 3), Vector2(-1, 1).normalized(), "pin_4 pulls out toward the bottom-left")
	var profile: Dictionary = backpack_ui.call("pin_removal_vfx_profile_for_index", 0, 80.0)
	_assert_close(float(profile.get("anticipationDuration", 0.0)), 0.07, 0.001, "pin removal anticipation stays short but readable")
	_assert_close(float(profile.get("pullDuration", 0.0)), 0.20, 0.001, "pin removal pull is visible enough to read")
	_assert_close(float(profile.get("pullDistance", 0.0)), 36.0, 0.001, "pin removal pull distance scales visibly from displayed pin size")
	_assert_eq(float(profile.get("fadeToAlpha", 1.0)), 0.0, "removed pin fades out")
	_assert_eq(bool(profile.get("localOnly", false)), true, "pin removal VFX is localized rather than screen shake")

func _source_line_count(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 999999
	var text := file.get_as_text()
	file.close()
	return text.split("\n").size()

func _source_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text

