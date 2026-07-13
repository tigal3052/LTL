class_name MainViewPageShellRuntime
extends RefCounted

const PageSceneRegistryScript = preload("res://src/ui/PageSceneRegistry.gd")
const PageSceneModelBuilderScript = preload("res://src/ui/PageSceneModelBuilder.gd")
const CharacterSelectPageScene = preload("res://src/scenes/pages/CharacterSelectPage.tscn")
const LeviathanSelectPageScene = preload("res://src/scenes/pages/LeviathanSelectPage.tscn")
const StoryScenePageScene = preload("res://src/scenes/pages/StoryScenePage.tscn")
const NodeSelectRuntimePageScene = preload("res://src/scenes/pages/NodeSelectRuntimePage.tscn")
const BattlePageScene = preload("res://src/scenes/pages/BattlePage.tscn")
const BossBattlePageScene = preload("res://src/scenes/pages/BossBattlePage.tscn")
const RewardPageScene = preload("res://src/scenes/pages/RewardPage.tscn")
const BossRewardPageScene = preload("res://src/scenes/pages/BossRewardPage.tscn")
const EventNodePageScene = preload("res://src/scenes/pages/EventNodePage.tscn")
const DefeatPageScene = preload("res://src/scenes/pages/DefeatPage.tscn")
const ClearPageScene = preload("res://src/scenes/pages/ClearPage.tscn")

const META_PAGE_IDS := ["character_select", "leviathan_select", "story_scene", "clear", "defeat"]
const SURFACE_PAGE_IDS := ["battle", "boss_battle", "reward", "boss_reward"]
const ACTION_BAR_PAGE_IDS := ["node_select", "battle", "boss_battle", "reward", "boss_reward"]
const CHARACTER_PORTRAIT_PATH := "res://resources/charactor/charactor1.png"
# 전투 리디자인 2차: 채집낭 보드 패널(제목 행 + 보드 + CTA 기둥)이 top-content 중앙 컬럼을 감싼다.
const BOARD_AREA_PATH := "TopContent/BoardPanel/BoardMargin/BoardBox/BoardArea"

static func create_page_scenes(view) -> void:
	view.meta_page_shell_host = PageSceneRegistryScript.build_shell_host("MetaPageShellHost")
	view.add_child(view.meta_page_shell_host)
	view.move_child(view.meta_page_shell_host, view.repair_overlay.get_index())
	view.page_shell_host = PageSceneRegistryScript.build_shell_host("PageShellHost")
	view.active_phase_container.add_child(view.page_shell_host)
	view.active_phase_container.move_child(view.page_shell_host, 0)
	register_page_scene(view, "character_select", CharacterSelectPageScene.instantiate())
	register_page_scene(view, "leviathan_select", LeviathanSelectPageScene.instantiate())
	register_page_scene(view, "story_scene", StoryScenePageScene.instantiate())
	register_page_scene(view, "node_select", NodeSelectRuntimePageScene.instantiate())
	register_page_scene(view, "battle", BattlePageScene.instantiate())
	register_page_scene(view, "boss_battle", BossBattlePageScene.instantiate())
	register_page_scene(view, "reward", RewardPageScene.instantiate())
	register_page_scene(view, "boss_reward", BossRewardPageScene.instantiate())
	register_page_scene(view, "event_node", EventNodePageScene.instantiate())
	register_page_scene(view, "defeat", DefeatPageScene.instantiate())
	register_page_scene(view, "clear", ClearPageScene.instantiate())
	view.character_select_page = view.page_scenes.get("character_select")
	view.leviathan_select_page = view.page_scenes.get("leviathan_select")
	view.story_scene_page = view.page_scenes.get("story_scene")
	view.node_select_runtime_page = view.page_scenes.get("node_select") as Control
	cache_node_select_runtime_hosts(view)
	if view.character_select_page != null and view.character_select_page.has_signal("character_selected"):
		view.character_select_page.connect("character_selected", func(character_id): view.character_selected.emit(character_id))
	if view.character_select_page != null and view.character_select_page.has_signal("color_selected"):
		view.character_select_page.connect("color_selected", func(color): view.loadout_color_selected.emit(color))
	if view.character_select_page != null and view.character_select_page.has_signal("continue_requested"):
		view.character_select_page.connect("continue_requested", func(): view.character_continue_pressed.emit())
	if view.character_select_page != null and view.character_select_page.has_signal("settings_requested"):
		view.character_select_page.connect("settings_requested", func(): view.settings_open_pressed.emit())
	if view.character_select_page != null and view.character_select_page.has_signal("codex_requested"):
		view.character_select_page.connect("codex_requested", func(): view.codex_open_pressed.emit())
	if view.character_select_page != null and view.character_select_page.has_signal("interaction_sfx_requested"):
		view.character_select_page.connect("interaction_sfx_requested", func(category: String): view.play_interaction_sfx(category))
	if view.leviathan_select_page != null and view.leviathan_select_page.has_signal("leviathan_selected"):
		view.leviathan_select_page.connect("leviathan_selected", func(leviathan_id): view.leviathan_selected.emit(leviathan_id))
	if view.leviathan_select_page != null and view.leviathan_select_page.has_signal("start_requested"):
		view.leviathan_select_page.connect("start_requested", func(): view.looting_start_pressed.emit())
	if view.leviathan_select_page != null and view.leviathan_select_page.has_signal("return_to_character_select_requested"):
		view.leviathan_select_page.connect("return_to_character_select_requested", func(): view.return_to_character_select_pressed.emit())
	if view.leviathan_select_page != null and view.leviathan_select_page.has_signal("codex_requested"):
		view.leviathan_select_page.connect("codex_requested", func(): view.codex_open_pressed.emit())
	if view.leviathan_select_page != null and view.leviathan_select_page.has_signal("settings_requested"):
		view.leviathan_select_page.connect("settings_requested", func(): view.settings_open_pressed.emit())
	if view.story_scene_page != null and view.story_scene_page.has_signal("continue_requested"):
		view.story_scene_page.connect("continue_requested", func(scene_id): view.story_continue_requested.emit(scene_id))
	if view.story_scene_page != null and view.story_scene_page.has_signal("skip_requested"):
		view.story_scene_page.connect("skip_requested", func(scene_id): view.story_skip_requested.emit(scene_id))
	if view.story_scene_page != null and view.story_scene_page.has_signal("interaction_sfx_requested"):
		view.story_scene_page.connect("interaction_sfx_requested", func(category: String): view.play_interaction_sfx(category))
	if view.node_select_runtime_page != null and view.node_select_runtime_page.has_signal("node_selected"):
		view.node_select_runtime_page.connect("node_selected", func(index): view.node_meta_clicked.emit(index))
	if view.node_select_runtime_page != null and view.node_select_runtime_page.has_signal("settings_requested"):
		view.node_select_runtime_page.connect("settings_requested", func(): view.settings_open_pressed.emit())
	if view.node_select_runtime_page != null and view.node_select_runtime_page.has_signal("shop_requested"):
		view.node_select_runtime_page.connect("shop_requested", func(): view.shop_open_pressed.emit())
	if view.node_select_runtime_page != null and view.node_select_runtime_page.has_signal("codex_requested"):
		view.node_select_runtime_page.connect("codex_requested", func(): view.codex_open_pressed.emit())
	if view.node_select_runtime_page != null and view.node_select_runtime_page.has_signal("start_color_selected"):
		view.node_select_runtime_page.connect("start_color_selected", func(color): view.loadout_color_selected.emit(color))
	var clear_page: Node = view.page_scenes.get("clear", null) as Node
	if clear_page != null and clear_page.has_signal("return_requested"):
		clear_page.return_requested.connect(func(): view.return_to_character_select_pressed.emit())
	var defeat_page: Node = view.page_scenes.get("defeat", null) as Node
	if defeat_page != null and defeat_page.has_signal("same_seed_retry_requested"):
		defeat_page.same_seed_retry_requested.connect(func(): view.retry_same_seed_pressed.emit())
	if defeat_page != null and defeat_page.has_signal("new_seed_retry_requested"):
		defeat_page.new_seed_retry_requested.connect(func(): view.retry_new_seed_pressed.emit())
	sync_page_scene_bounds(view)

static func cache_node_select_runtime_hosts(view) -> void:
	if view.node_select_runtime_page == null:
		view.node_select_content_row = null
		view.node_select_backpack_host = null
		return
	view.node_select_content_row = view.node_select_runtime_page.get_node_or_null("Margin/BoardShell/ShellMargin/ShellVBox/RouteSplit") as HBoxContainer
	view.node_select_backpack_host = view.node_select_runtime_page.get_node_or_null("Margin/BoardShell/ShellMargin/ShellVBox/RouteSplit/BackpackHost") as Control
	if view.node_select_content_row != null:
		view.node_select_content_row.resized.connect(view._queue_shared_backpack_layout_sync)
	if view.node_select_backpack_host != null:
		view.node_select_backpack_host.resized.connect(view._queue_shared_backpack_layout_sync)

static func page_bundle(view, page_id: String) -> Dictionary:
	return view.page_shell_bundles.get(page_id, {})

static func active_surface_bundle(view) -> Dictionary:
	return page_bundle(view, view._active_surface_bundle_id)

static func bundle_node(view, page_id: String, path: String = "") -> Node:
	var bundle: Dictionary = page_bundle(view, page_id)
	var page_root: Node = bundle.get("pageRoot", null) as Node
	if page_root == null:
		page_root = view.page_scenes.get(page_id, null) as Node
	if page_root == null:
		return null
	if path.is_empty():
		return page_root
	return page_root.get_node_or_null(path)

static func current_surface_node(view, path: String = "") -> Node:
	return bundle_node(view, view._active_surface_bundle_id, path)

static func current_action_bar_node(view, path: String = "") -> Node:
	return bundle_node(view, view._active_action_bar_bundle_id, path)

static func cache_page_shell_bundles(view) -> void:
	view.page_shell_bundles.clear()
	for page_id in ACTION_BAR_PAGE_IDS:
		var page_root: Control = view.page_scenes.get(page_id, null) as Control
		if page_root == null:
			continue
		view.page_shell_bundles[page_id] = capture_page_shell_bundle(page_id, page_root)
	if view.page_shell_bundles.has("reward"):
		assign_reward_bundle_refs(view, page_bundle(view, "reward"))
	if view.page_shell_bundles.has("battle"):
		assign_battle_bundle_refs(view, page_bundle(view, "battle"))

static func _first_node(page_root: Control, paths: Array) -> Node:
	for path in paths:
		var node := page_root.get_node_or_null(str(path))
		if node != null:
			return node
	return null

static func capture_page_shell_bundle(page_id: String, page_root: Control) -> Dictionary:
	var bundle := {"pageId": page_id, "pageRoot": page_root}
	var action_bar_path := "ActionBar"
	if page_id == "node_select":
		action_bar_path = "Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RoadmapFrame/FrameMargin/FrameVBox/RoadmapCanvas/ActionBar"
		if page_root.get_node_or_null(action_bar_path) == null:
			action_bar_path = "Margin/VStack/ActionBar"
	elif page_id in ["battle", "boss_battle"]:
		# 전투 리디자인: 하단 액션 바 행 폐지 → 채집낭 보드 패널 내부 세로 CTA 기둥
		if page_root.get_node_or_null("%s/CtaColumn/ActionBar" % BOARD_AREA_PATH) != null:
			action_bar_path = "%s/CtaColumn/ActionBar" % BOARD_AREA_PATH
		elif page_root.get_node_or_null("TopContent/CtaColumn/ActionBar") != null:
			action_bar_path = "TopContent/CtaColumn/ActionBar"
	bundle["actionBar"] = page_root.get_node_or_null(action_bar_path) as BoxContainer
	if page_id in ["battle", "boss_battle"]:
		bundle["ctaColumn"] = _first_node(page_root, ["%s/CtaColumn" % BOARD_AREA_PATH, "TopContent/CtaColumn"]) as Control
		bundle["ctaTimerChip"] = page_root.get_node_or_null("%s/TimerChip" % action_bar_path) as PanelContainer
		bundle["ctaTimerLabel"] = page_root.get_node_or_null("%s/TimerChip/CombatTimerLabel" % action_bar_path) as Label
	bundle["resetButton"] = page_root.get_node_or_null("%s/ResetButton" % action_bar_path) as Button
	bundle["startButton"] = page_root.get_node_or_null("%s/StartButton" % action_bar_path) as Button
	bundle["claimRewardsButton"] = page_root.get_node_or_null("%s/ClaimRewardsButton" % action_bar_path) as Button
	if page_id == "node_select":
		bundle["shopButton"] = page_root.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/ShopButton") as Button
		bundle["codexButton"] = page_root.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/CodexButton") as Button
		bundle["settingsButton"] = page_root.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead/TitleChips/SettingsButton") as Button
	if page_id in SURFACE_PAGE_IDS:
		bundle["topContent"] = page_root.get_node_or_null("TopContent") as HBoxContainer
		bundle["leftColumn"] = page_root.get_node_or_null("TopContent/LeftColumn") as VBoxContainer
		bundle["portraitPlaceholder"] = page_root.get_node_or_null("TopContent/RightSidebar/Margin/SidebarBox/TabViewport/ExplorerContent/Margin/CharacterBox/PortraitPlaceholder") as Panel
		bundle["portraitLabel"] = page_root.get_node_or_null("TopContent/RightSidebar/Margin/SidebarBox/TabViewport/ExplorerContent/Margin/CharacterBox/PortraitPlaceholder/PortraitLabel") as Label
		bundle["backpackHost"] = _first_node(page_root, ["%s/BackpackContainer" % BOARD_AREA_PATH, "TopContent/BackpackContainer"]) as AspectRatioContainer
		bundle["boardPanel"] = page_root.get_node_or_null("TopContent/BoardPanel") as PanelContainer
		bundle["boardTitleRow"] = page_root.get_node_or_null("TopContent/BoardPanel/BoardMargin/BoardBox/BoardTitleRow") as HBoxContainer
		bundle["boardTitle"] = page_root.get_node_or_null("TopContent/BoardPanel/BoardMargin/BoardBox/BoardTitleRow/BoardTitle") as Label
		bundle["rightSidebar"] = page_root.get_node_or_null("TopContent/RightSidebar") as PanelContainer
		bundle["statusPanel"] = page_root.get_node_or_null("TopContent/LeftColumn/StatusPanel")
		bundle["logConsole"] = page_root.get_node_or_null("TopContent/RightSidebar/Margin/SidebarBox/TabViewport/LogContent/Margin/LogBox/InspectorText")
		bundle["battlefieldUI"] = page_root.get_node_or_null("BattlefieldPanel")
		bundle["rewardPanel"] = page_root.get_node_or_null("RewardPanel") as PanelContainer
		if bundle.get("rewardPanel", null) != null:
			bundle["rewardPanelMargin"] = page_root.get_node_or_null("RewardPanel/Margin") as MarginContainer
			bundle["rewardBox"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox") as VBoxContainer
			bundle["rewardBoardHead"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/BoardHead") as HBoxContainer
			bundle["rewardBoardScroll"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll") as ScrollContainer
			bundle["rewardBoard"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard") as VBoxContainer
			bundle["rewardGrid"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid") as HBoxContainer
			bundle["rewardRewardsZone"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone") as PanelContainer
			bundle["rewardWorkspaceZone"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone") as PanelContainer
			bundle["rewardWorkspaceMargin"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin") as MarginContainer
			bundle["rewardWorkspaceBox"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox") as VBoxContainer
			bundle["rewardWorkspaceHead"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/ZoneHead") as VBoxContainer
			bundle["rewardWorkspaceTitle"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/ZoneHead/ZoneTitle") as Label
			bundle["rewardInspectorZone"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone") as PanelContainer
			bundle["rewardBottomRow"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow") as HBoxContainer
			bundle["rewardTitle"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/BoardHead/BoardTitleBox/RewardTitle") as Label
			bundle["rewardSubtitle"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/BoardHead/BoardTitleBox/RewardSubtitle") as Label
			bundle["rewardModePill"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/BoardHead/ModePill") as Label
			bundle["rewardCardGrid"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox/CloudMargin/CloudVBox/RewardCardGrid") as Control
			bundle["rewardCloudContent"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox/CloudMargin/CloudVBox") as VBoxContainer
			bundle["rewardCloudBox"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox") as PanelContainer
			bundle["rewardCloudNote"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone/Margin/ZoneBox/RewardCloudBox/CloudMargin/CloudVBox/CloudNote") as Label
			bundle["rewardWorkspaceNote"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/WorkspaceNote") as RichTextLabel
			bundle["rewardBackpackHost"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/BackpackHost") as Control
			bundle["rewardInspectorKicker"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/InspectorKicker") as Label
			bundle["rewardInspectorName"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/InspectorName") as Label
			bundle["rewardInspectorSummary"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/InspectorSummary") as RichTextLabel
			bundle["rewardInspectorFacts"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/InspectorFacts") as GridContainer
			bundle["rewardInspectorStage"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage") as VBoxContainer
			bundle["rewardFootprintTitle"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/FootprintCard/Margin/FootprintBox/FootprintTitle") as Label
			bundle["rewardFootprintInfo"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/FootprintCard/Margin/FootprintBox/FootprintInfo") as Label
			bundle["rewardFootprintGrid"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone/Margin/ZoneBox/InspectorStage/FootprintCard/Margin/FootprintBox/FootprintGrid") as GridContainer
			bundle["discardZone"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone") as PanelContainer
			bundle["confirmZone"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone") as PanelContainer
			bundle["discardCard"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/DiscardCard") as PanelContainer
			bundle["claimCard"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCard") as Control
			bundle["discardLabel"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/DiscardLabel") as Label
			bundle["claimCardBody"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCard/ClaimCardBody") as Label
			bundle["claimInlineButton"] = page_root.get_node_or_null("RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCard/ClaimInlineButton") as Button
	return bundle

static func connect_page_shell_bundle_signals(view) -> void:
	for bundle_value in view.page_shell_bundles.values():
		var bundle: Dictionary = bundle_value
		var reset_btn := bundle.get("resetButton", null) as Button
		if reset_btn != null: reset_btn.pressed.connect(func(): view.reset_pressed.emit())
		var start_btn := bundle.get("startButton", null) as Button
		if start_btn != null: start_btn.pressed.connect(func(): view.call_deferred("_emit_start_combat_pressed"))
		var claim_btn := bundle.get("claimRewardsButton", null) as Button
		if claim_btn != null: claim_btn.pressed.connect(func(): view.claim_rewards_pressed.emit())
		var inline_btn := bundle.get("claimInlineButton", null) as Button
		if inline_btn != null: inline_btn.pressed.connect(func(): view.claim_rewards_pressed.emit())
		var discard_shell := bundle.get("discardZone", null) as PanelContainer
		if discard_shell != null:
			discard_shell.gui_input.connect(func(ev): view.discard_zone_input.emit(ev))
			view._set_descendant_mouse_filter_ignore(discard_shell)
			discard_shell.resized.connect(view._queue_reward_board_layout_sync)
		var confirm_shell := bundle.get("confirmZone", null) as PanelContainer
		if confirm_shell != null: confirm_shell.resized.connect(view._queue_reward_board_layout_sync)
		var battlefield_panel = bundle.get("battlefieldUI", null)
		if battlefield_panel != null:
			battlefield_panel.cell_hovered.connect(func(cid, col): view.cell_hovered.emit(cid, col))
			battlefield_panel.cell_clicked.connect(func(cid, col): view.cell_clicked.emit(cid, col))
			battlefield_panel.cell_pressed.connect(func(cid, col): view.cell_pressed.emit(cid, col))
			battlefield_panel.cell_released.connect(func(): view.cell_released.emit())
		var top_row := bundle.get("topContent", null) as HBoxContainer
		if top_row != null: top_row.resized.connect(view._queue_shared_backpack_layout_sync)
		var reward_grid_node := bundle.get("rewardGrid", null) as HBoxContainer
		if reward_grid_node != null: reward_grid_node.resized.connect(view._queue_reward_board_layout_sync)
		var reward_host := bundle.get("rewardBackpackHost", null) as Control
		if reward_host != null: reward_host.resized.connect(view._queue_reward_board_layout_sync)
		var reward_bottom := bundle.get("rewardBottomRow", null) as HBoxContainer
		if reward_bottom != null: reward_bottom.resized.connect(view._queue_reward_board_layout_sync)
		var reward_cards := bundle.get("rewardCardGrid", null) as Control
		if reward_cards != null: reward_cards.resized.connect(view._queue_reward_card_float_layout)

static func activate_action_bar_bundle(view, page_id: String) -> void:
	var bundle: Dictionary = page_bundle(view, page_id)
	if bundle.is_empty():
		return
	view._active_action_bar_bundle_id = page_id
	view.action_bar = bundle.get("actionBar", null) as BoxContainer
	view.reset_button = bundle.get("resetButton", null) as Button
	view.start_button = bundle.get("startButton", null) as Button
	view.claim_rewards_button = bundle.get("claimRewardsButton", null) as Button

static func activate_surface_bundle(view, page_id: String) -> void:
	var bundle: Dictionary = page_bundle(view, page_id)
	if bundle.is_empty():
		return
	view._active_surface_bundle_id = page_id
	view.top_content = bundle.get("topContent", view.top_content) as HBoxContainer
	view.left_column = bundle.get("leftColumn", view.left_column) as VBoxContainer
	view.portrait_placeholder = bundle.get("portraitPlaceholder", view.portrait_placeholder) as Panel
	view.portrait_label = bundle.get("portraitLabel", view.portrait_label) as Label
	view.backpack_host = bundle.get("backpackHost", view.backpack_host) as Control
	view.right_sidebar = bundle.get("rightSidebar", view.right_sidebar) as PanelContainer
	view.status_panel = bundle.get("statusPanel", view.status_panel)
	view.log_console = bundle.get("logConsole", view.log_console)
	view.backpack_original_parent = view.backpack_host
	view.backpack_original_index = view.backpack_container.get_index() if view.backpack_container != null and view.backpack_container.get_parent() == view.backpack_host else -1
	var reward_backpack_host := bundle.get("rewardBackpackHost", null) as Control
	var already_docked_to_reward: bool = reward_backpack_host != null and view.backpack_container != null and view.backpack_container.get_parent() == reward_backpack_host
	if view.backpack_container != null and view.backpack_host != null and view.backpack_container.get_parent() != view.backpack_host and not already_docked_to_reward:
		view._schedule_backpack_reparent(view.backpack_host, view.backpack_original_index)
	if bundle.get("battlefieldUI", null) != null:
		assign_battle_bundle_refs(view, bundle)
	if bundle.get("rewardPanel", null) != null:
		assign_reward_bundle_refs(view, bundle)
	# 전투 보드 패널 제목 행을 영향 미리보기 토글 앵커로 사용 (mockup .board-title-row 우측 배치)
	var board_title_row := bundle.get("boardTitleRow", null) as Control
	if board_title_row != null and bundle.get("battlefieldUI", null) != null and view.backpack_ui != null and view.backpack_ui.has_method("set_influence_preview_toggle_anchor"):
		view.backpack_ui.set_influence_preview_toggle_anchor(board_title_row)
	view._install_character_presentation()
	if view.reward_panel != null:
		view._install_reward_backdrop()

static func assign_battle_bundle_refs(view, bundle: Dictionary) -> void:
	view.battlefield_ui = bundle.get("battlefieldUI", view.battlefield_ui)

static func assign_reward_bundle_refs(view, bundle: Dictionary) -> void:
	view.reward_panel = bundle.get("rewardPanel", view.reward_panel) as PanelContainer
	view.reward_panel_margin = bundle.get("rewardPanelMargin", view.reward_panel_margin) as MarginContainer
	view.reward_box = bundle.get("rewardBox", view.reward_box) as VBoxContainer
	view.reward_board_head = bundle.get("rewardBoardHead", view.reward_board_head) as HBoxContainer
	view.reward_board_scroll = bundle.get("rewardBoardScroll", view.reward_board_scroll) as ScrollContainer
	view.reward_board = bundle.get("rewardBoard", view.reward_board) as VBoxContainer
	view.reward_grid = bundle.get("rewardGrid", view.reward_grid) as HBoxContainer
	view.reward_rewards_zone = bundle.get("rewardRewardsZone", view.reward_rewards_zone) as PanelContainer
	view.reward_workspace_zone = bundle.get("rewardWorkspaceZone", view.reward_workspace_zone) as PanelContainer
	view.reward_workspace_margin = bundle.get("rewardWorkspaceMargin", view.reward_workspace_margin) as MarginContainer
	view.reward_workspace_box = bundle.get("rewardWorkspaceBox", view.reward_workspace_box) as VBoxContainer
	view.reward_workspace_head = bundle.get("rewardWorkspaceHead", view.reward_workspace_head) as VBoxContainer
	view.reward_workspace_title = bundle.get("rewardWorkspaceTitle", view.reward_workspace_title) as Label
	view.reward_inspector_zone = bundle.get("rewardInspectorZone", view.reward_inspector_zone) as PanelContainer
	view.reward_bottom_row = bundle.get("rewardBottomRow", view.reward_bottom_row) as HBoxContainer
	view.reward_title = bundle.get("rewardTitle", view.reward_title) as Label
	view.reward_subtitle = bundle.get("rewardSubtitle", view.reward_subtitle) as Label
	view.reward_mode_pill = bundle.get("rewardModePill", view.reward_mode_pill) as Label
	view.reward_card_grid = bundle.get("rewardCardGrid", view.reward_card_grid) as Control
	view.reward_cloud_content = bundle.get("rewardCloudContent", view.reward_cloud_content) as VBoxContainer
	view.reward_cloud_box = bundle.get("rewardCloudBox", view.reward_cloud_box) as PanelContainer
	view.reward_cloud_note = bundle.get("rewardCloudNote", view.reward_cloud_note) as Label
	view.reward_workspace_note = bundle.get("rewardWorkspaceNote", view.reward_workspace_note) as RichTextLabel
	view.reward_backpack_host = bundle.get("rewardBackpackHost", view.reward_backpack_host) as Control
	view.reward_inspector_kicker = bundle.get("rewardInspectorKicker", view.reward_inspector_kicker) as Label
	view.reward_inspector_name = bundle.get("rewardInspectorName", view.reward_inspector_name) as Label
	view.reward_inspector_summary = bundle.get("rewardInspectorSummary", view.reward_inspector_summary) as RichTextLabel
	view.reward_inspector_facts = bundle.get("rewardInspectorFacts", view.reward_inspector_facts) as GridContainer
	view.reward_inspector_stage = bundle.get("rewardInspectorStage", view.reward_inspector_stage) as VBoxContainer
	view.reward_footprint_title = bundle.get("rewardFootprintTitle", view.reward_footprint_title) as Label
	view.reward_footprint_info = bundle.get("rewardFootprintInfo", view.reward_footprint_info) as Label
	view.reward_footprint_grid = bundle.get("rewardFootprintGrid", view.reward_footprint_grid) as GridContainer
	view.discard_zone = bundle.get("discardZone", view.discard_zone) as PanelContainer
	view.confirm_zone = bundle.get("confirmZone", view.confirm_zone) as PanelContainer
	view.discard_card = bundle.get("discardCard", view.discard_card) as PanelContainer
	view.claim_card = bundle.get("claimCard", view.claim_card) as Control
	view.discard_label = bundle.get("discardLabel", view.discard_label) as Label
	view.claim_card_body = bundle.get("claimCardBody", view.claim_card_body) as Label
	view.claim_inline_button = bundle.get("claimInlineButton", view.claim_inline_button) as Button
	view.reward_cloud_scroll = bundle.get("rewardCloudScroll", view.reward_cloud_scroll) as ScrollContainer
	view.discard_card_scroll = bundle.get("discardCardScroll", view.discard_card_scroll) as ScrollContainer
	view.claim_card_scroll = bundle.get("claimCardScroll", view.claim_card_scroll) as ScrollContainer
	view.reward_inspector_scroll = bundle.get("rewardInspectorScroll", view.reward_inspector_scroll) as ScrollContainer
	view._install_reward_zone_scroll_shells()
	view._install_reward_inspector_scroll_shell()
	bundle["rewardCloudScroll"] = view.reward_cloud_scroll
	bundle["discardCardScroll"] = view.discard_card_scroll
	bundle["claimCardScroll"] = view.claim_card_scroll
	bundle["rewardInspectorScroll"] = view.reward_inspector_scroll
	view._apply_shared_split_layout_text_policies()

static func register_page_scene(view, page_id: String, page_scene: Node) -> void:
	PageSceneRegistryScript.register_page_scene(view.page_scenes, page_id, page_scene, view.page_shell_host, view.meta_page_shell_host, META_PAGE_IDS)
	sync_page_scene_bounds(view)

static func sync_page_scene_bounds(view) -> void:
	for page_id in view.page_scenes.keys():
		var page_scene := view.page_scenes.get(page_id) as Control
		if page_scene == null:
			continue
		var host: Control = view.meta_page_shell_host if PageSceneRegistryScript.is_meta_page(page_id, META_PAGE_IDS) else view.page_shell_host
		if host != null:
			page_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func render_page_scene(view, scene: Dictionary) -> void:
	var page_id := str(scene.get("pageId", ""))
	view.active_page_id = page_id
	var active_scene = PageSceneRegistryScript.activate_page(view.page_scenes, page_id, view.page_shell_host, view.meta_page_shell_host, META_PAGE_IDS)
	var sfx_category: String = view.page_transition_sfx_category(page_id) if view.has_method("page_transition_sfx_category") else ""
	if not sfx_category.is_empty() and view.has_method("play_interaction_sfx"):
		view.play_interaction_sfx(sfx_category)
	sync_page_scene_bounds(view)
	if active_scene == null or not active_scene.has_method("apply_state"):
		return
	active_scene.apply_state(page_scene_model(page_id, scene))
	if view.settings_panel != null and view.settings_panel.visible:
		PageSceneModelBuilderScript.refresh_inactive_meta_page_models(view.page_scenes, META_PAGE_IDS, page_id, scene, CHARACTER_PORTRAIT_PATH)

static func is_meta_page(page_id: String) -> bool:
	return PageSceneRegistryScript.is_meta_page(page_id, META_PAGE_IDS)

static func page_scene_model(page_id: String, scene: Dictionary) -> Dictionary:
	return PageSceneModelBuilderScript.project(page_id, scene, CHARACTER_PORTRAIT_PATH)
