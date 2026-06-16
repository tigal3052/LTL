extends RefCounted

const RewardReadModelScript = preload("res://src/ui/read_models/RewardReadModel.gd")
const ArtifactScript = preload("res://src/models/Artifact.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

var failures: Array[String] = []

func run_all_tests() -> Dictionary:
	failures.clear()
	await test_reward_board_layout_stays_stable_across_live_click_alternation()
	await test_reward_board_keeps_fixed_layout_with_verbose_reward_names()
	await test_reward_workspace_reuses_live_backpack_panel()
	await test_reward_workspace_uses_the_visible_workspace_shell_title()
	await test_reward_workspace_backpack_panel_fills_host_on_first_render()
	await test_live_reward_workspace_keeps_existing_drill_centered_after_dock()
	await test_shared_backpack_returns_to_second_battle_after_reward_claim()
	await test_live_reward_drop_keeps_shared_backpack_visible_and_renders_artifact()
	await test_reward_workspace_image_drill_sits_inside_slot_without_color_overlay()
	await test_reward_workspace_image_drill_tracks_grid_position_changes()
	await test_reward_board_bottom_row_hides_empty_helper_rows_and_scrollbars()
	await test_reward_header_uses_selected_leviathan_name()
	return {"ok": failures.is_empty(), "errors": failures}

func test_reward_board_layout_stays_stable_across_live_click_alternation() -> void:
	var main_instance = await _boot_live_reward_tray()
	if main_instance == null:
		return
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists for live reward-board click contract")
	if controller == null:
		main_instance.queue_free()
		await Engine.get_main_loop().process_frame
		return
	await _settle_frames(2)
	var baseline: Dictionary = _reward_board_metrics(main_instance)
	_assert_reward_board_inside_viewport(main_instance, "reward tray baseline")
	_assert_reward_board_uses_visible_shell_width(baseline, "reward tray baseline")
	var backpack_coord: Vector2 = _first_inventory_coord(controller.get("inventory"))
	_assert(backpack_coord.x >= 0.0 and backpack_coord.y >= 0.0, "reward tray click contract finds at least one backpack artifact to inspect")
	if backpack_coord.x >= 0.0 and backpack_coord.y >= 0.0:
		for cycle in range(3):
			main_instance.emit_signal("reward_meta_clicked", 0)
			await _settle_frames(2)
			var reward_metrics: Dictionary = _reward_board_metrics(main_instance)
			_assert_reward_board_metrics_close(baseline, reward_metrics, "reward-card inspect cycle %d" % cycle)
			_assert_reward_board_inside_viewport(main_instance, "reward-card inspect cycle %d" % cycle)
			_assert_reward_board_uses_visible_shell_width(reward_metrics, "reward-card inspect cycle %d" % cycle)
			main_instance.emit_signal("backpack_slot_clicked", backpack_coord)
			await _settle_frames(2)
			var backpack_metrics: Dictionary = _reward_board_metrics(main_instance)
			_assert_reward_board_metrics_close(baseline, backpack_metrics, "backpack inspect cycle %d" % cycle)
			_assert_reward_board_inside_viewport(main_instance, "backpack inspect cycle %d" % cycle)
			_assert_reward_board_uses_visible_shell_width(backpack_metrics, "backpack inspect cycle %d" % cycle)
	main_instance.queue_free()
	await Engine.get_main_loop().process_frame

func test_reward_board_keeps_fixed_layout_with_verbose_reward_names() -> void:
	var rewards: Array = _verbose_reward_fixture()
	var main_instance = await _instantiate_reward_board_surface(
		rewards,
		RewardReadModelScript.project_tray(rewards)
	)
	if main_instance == null:
		return
	var baseline: Dictionary = _reward_board_metrics(main_instance)
	_assert_reward_board_inside_viewport(main_instance, "verbose reward baseline")
	_assert_reward_board_uses_visible_shell_width(baseline, "verbose reward baseline")
	var starter_loadout: Array = ArtifactScript.get_starter_loadout("purple")
	_assert(starter_loadout.size() > 0, "starter loadout exists for verbose reward-board layout contract")
	var starter_artifact = starter_loadout[0] if starter_loadout.size() > 0 else null
	var inspection_models: Array = [
		RewardReadModelScript.project_tray(rewards, -1, null, false, 0, null),
		RewardReadModelScript.project_tray(rewards, -1, null, false, -1, starter_artifact),
		RewardReadModelScript.project_tray(rewards, -1, null, false, 1, null),
		RewardReadModelScript.project_tray(rewards)
	]
	for index in range(inspection_models.size()):
		main_instance.render_reward_tray(inspection_models[index])
		await _settle_frames(2)
		var metrics: Dictionary = _reward_board_metrics(main_instance)
		_assert_reward_board_metrics_close(baseline, metrics, "verbose reward render %d" % index)
		_assert_reward_board_inside_viewport(main_instance, "verbose reward render %d" % index)
		_assert_reward_board_uses_visible_shell_width(metrics, "verbose reward render %d" % index)
	main_instance.queue_free()
	await Engine.get_main_loop().process_frame

func test_reward_workspace_reuses_live_backpack_panel() -> void:
	var main_instance = await _instantiate_reward_board_surface(
		_verbose_reward_fixture(),
		RewardReadModelScript.project_tray(_verbose_reward_fixture())
	)
	if main_instance == null:
		return
	var reward_backpack_host = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/BackpackHost") as Control
	var backpack_container = main_instance.get("backpack_container") as Control
	_assert(reward_backpack_host != null, "reward workspace exposes the backpack host")
	_assert(backpack_container != null, "main scene exposes the shared backpack container")
	if reward_backpack_host != null and backpack_container != null:
		var host_rect: Rect2 = reward_backpack_host.get_global_rect()
		var backpack_rect: Rect2 = backpack_container.get_global_rect()
		_assert(backpack_container.get_parent() == reward_backpack_host, "reward workspace reparents the shared backpack into the board host")
		_assert(host_rect.has_point(backpack_rect.position), "shared backpack begins inside the reward workspace host")
		_assert(host_rect.has_point(backpack_rect.end - Vector2.ONE), "shared backpack ends inside the reward workspace host")
	main_instance.queue_free()
	await Engine.get_main_loop().process_frame

func test_reward_workspace_uses_the_visible_workspace_shell_title() -> void:
	var main_instance = await _instantiate_reward_board_surface(
		_verbose_reward_fixture(),
		RewardReadModelScript.project_tray(_verbose_reward_fixture())
	)
	if main_instance == null:
		return
	var workspace_head = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/ZoneHead") as Control
	var workspace_title = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/ZoneHead/ZoneTitle") as Label
	var backpack_container = main_instance.get("backpack_container") as Control
	var engine_title = backpack_container.get_node_or_null("BackpackEnginePanel/Margin/EngineBox/EngineTitle") as Control if backpack_container != null else null
	_assert(workspace_head != null, "reward workspace exposes the shell title row for visible panel alignment")
	_assert(workspace_title != null, "reward workspace exposes the shell title label for visible panel alignment")
	_assert(engine_title != null, "shared backpack panel exposes its internal engine title for reward-workspace visibility checks")
	if workspace_head != null:
		_assert(workspace_head.visible, "reward workspace keeps the outer shell title visible so the middle panel aligns with the left/right titled shells")
	if workspace_title != null:
		_assert_eq(workspace_title.text, TextCatalogScript.t("panel.backpack"), "reward workspace shell reuses the backpack engine title copy")
	if engine_title != null:
		_assert_eq(engine_title.visible, false, "reward workspace hides the inner backpack title so the docked panel does not show a second competing heading")
	main_instance.queue_free()
	await Engine.get_main_loop().process_frame

func test_reward_workspace_backpack_panel_fills_host_on_first_render() -> void:
	var main_instance = await _instantiate_reward_board_surface(
		_verbose_reward_fixture(),
		RewardReadModelScript.project_tray(_verbose_reward_fixture())
	)
	if main_instance == null:
		return
	await _settle_frames(2)
	var metrics: Dictionary = _reward_board_metrics(main_instance)
	_assert_reward_board_backpack_panel_uses_workspace_height(metrics, "reward tray initial render")
	main_instance.queue_free()
	await Engine.get_main_loop().process_frame

func test_live_reward_workspace_keeps_existing_drill_centered_after_dock() -> void:
	var main_instance = await _boot_live_reward_tray()
	if main_instance == null:
		return
	await _settle_frames(12)
	var controller = main_instance.get_node_or_null("MainController")
	var backpack_container = main_instance.get("backpack_container") as Control
	var backpack_panel = backpack_container.get_node_or_null("BackpackEnginePanel") as Control if backpack_container != null else null
	_assert(controller != null, "live reward dock image contract has a controller")
	_assert(backpack_panel != null, "live reward dock image contract has the shared backpack panel")
	if controller != null and backpack_panel != null:
		_assert_live_starter_drill_centered(controller, backpack_panel, "live reward dock keeps the existing starter drill image centered without manual render")
	main_instance.queue_free()
	await Engine.get_main_loop().process_frame

func test_shared_backpack_returns_to_second_battle_after_reward_claim() -> void:
	var main_instance = await _boot_live_reward_tray()
	if main_instance == null:
		return
	var controller = main_instance.get_node_or_null("MainController")
	var backpack_container = main_instance.get("backpack_container") as Control
	var first_shared_id := int(backpack_container.get_instance_id()) if backpack_container != null else -1
	_assert(controller != null, "second battle shared-backpack contract has a controller")
	_assert(backpack_container != null, "second battle shared-backpack contract starts with a shared backpack")
	if controller == null or backpack_container == null:
		main_instance.queue_free()
		await Engine.get_main_loop().process_frame
		return
	controller.call("_proceed_to_node_select")
	await _settle_frames(4)
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "reward claim returns to node select before second battle")
	_press_current_node(main_instance, 1, "second battle shared-backpack contract")
	await Engine.get_main_loop().process_frame
	var start_button = main_instance.get("start_button")
	_assert(start_button != null, "start button exists for second battle shared-backpack contract")
	if start_button != null:
		start_button.pressed.emit()
	await _settle_frames(8)
	_assert_eq(str(main_instance.get("active_page_id")), "battle", "second route enters battle for shared-backpack return contract")
	var battle_host = main_instance.call("current_surface_node", "TopContent/BackpackContainer") as Control
	var backpack_panel = backpack_container.get_node_or_null("BackpackEnginePanel") as Control
	var grid = backpack_panel.get_node_or_null("Margin/EngineBox/GridMock") as Control if backpack_panel != null else null
	_assert_eq(int(backpack_container.get_instance_id()), first_shared_id, "second battle keeps the same shared backpack instance id")
	_assert(battle_host != null, "second battle exposes the top backpack host")
	_assert(backpack_panel != null, "second battle shared container still owns the backpack panel")
	_assert(grid != null, "second battle shared backpack still owns the grid")
	if battle_host != null:
		_assert(backpack_container.get_parent() == battle_host, "second battle reparents the shared backpack back into the battle host")
	if backpack_panel != null:
		_assert(backpack_container.visible and backpack_panel.visible, "second battle keeps the shared backpack panel visible")
		_assert(backpack_container.get_global_rect().size.x > 1.0 and backpack_container.get_global_rect().size.y > 1.0, "second battle shared backpack has a visible non-zero rect")
	if grid != null:
		_assert(grid.visible and grid.get_global_rect().size.x > 1.0 and grid.get_global_rect().size.y > 1.0, "second battle grid remains visible with a non-zero rect")
	if backpack_panel != null:
		_assert_live_starter_drill_centered(controller, backpack_panel, "second battle keeps the starter drill image centered after returning from reward")
	main_instance.queue_free()
	await Engine.get_main_loop().process_frame

func test_live_reward_drop_keeps_shared_backpack_visible_and_renders_artifact() -> void:
	var main_instance = await _boot_live_reward_tray()
	if main_instance == null:
		return
	var controller = main_instance.get_node_or_null("MainController")
	var backpack_container = main_instance.get("backpack_container") as Control
	var reward_backpack_host = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/BackpackHost") as Control
	var backpack_panel = backpack_container.get_node_or_null("BackpackEnginePanel") as Control if backpack_container != null else null
	_assert(controller != null, "reward drop render contract has a controller")
	_assert(backpack_container != null, "reward drop render contract has the shared backpack container")
	_assert(reward_backpack_host != null, "reward drop render contract has the reward backpack host")
	_assert(backpack_panel != null, "reward drop render contract has the shared backpack panel")
	if controller == null or backpack_container == null or reward_backpack_host == null or backpack_panel == null:
		main_instance.queue_free()
		await Engine.get_main_loop().process_frame
		return
	var selection := await _select_first_placeable_reward_drag(controller)
	_assert(not selection.is_empty(), "reward drop render contract finds a placeable reward artifact")
	if selection.is_empty():
		main_instance.queue_free()
		await Engine.get_main_loop().process_frame
		return
	var reward_index := int(selection.get("index", -1))
	var coord: Vector2 = selection.get("coord", Vector2(-1, -1))
	var artifact_id := str(selection.get("artifactId", ""))
	main_instance.emit_signal("reward_meta_drop_requested", reward_index, coord)
	await _settle_frames(16)
	_assert_eq(str(main_instance.get("active_page_id")), "reward", "reward drop keeps the reward page active")
	_assert(backpack_container.get_parent() == reward_backpack_host, "reward drop keeps the shared backpack docked in the reward workspace host")
	_assert(backpack_container.visible, "reward drop keeps the shared backpack container visible")
	_assert(backpack_container.get_global_rect().size.x > 1.0 and backpack_container.get_global_rect().size.y > 1.0, "reward drop keeps a non-zero shared backpack rect")
	var grid = backpack_panel.get_node_or_null("Margin/EngineBox/GridMock") as Control
	_assert(grid != null, "reward drop keeps the backpack grid node")
	if grid != null:
		_assert(grid.visible and grid.get_global_rect().size.x > 1.0 and grid.get_global_rect().size.y > 1.0, "reward drop keeps the backpack grid visible with a non-zero rect")
	var inventory = controller.get("inventory")
	var artifact = inventory.artifacts.get(artifact_id, null) if inventory != null else null
	_assert(artifact != null, "reward drop inventory contains the newly placed artifact")
	if artifact != null:
		_assert_artifact_rendered_in_reward_backpack(backpack_panel, artifact, "reward drop renders the newly placed artifact on the reward backpack")
	main_instance.queue_free()
	await Engine.get_main_loop().process_frame

func test_reward_workspace_image_drill_sits_inside_slot_without_color_overlay() -> void:
	var main_instance = await _boot_live_reward_tray()
	if main_instance == null:
		return
	var controller = main_instance.get_node_or_null("MainController")
	var backpack_container = main_instance.get("backpack_container") as Control
	var backpack_panel = backpack_container.get_node_or_null("BackpackEnginePanel") as Control if backpack_container != null else null
	_assert(controller != null, "reward workspace image contract has a live controller")
	_assert(backpack_panel != null, "reward workspace image contract has the shared backpack panel")
	if controller == null or backpack_panel == null:
		main_instance.queue_free()
		await Engine.get_main_loop().process_frame
		return
	var inventory = controller.get("inventory")
	var drill = inventory.artifacts.get("starter_purple_drill", null) if inventory != null else null
	_assert(drill != null, "reward workspace image contract finds the starter drill")
	if drill == null:
		main_instance.queue_free()
		await Engine.get_main_loop().process_frame
		return
	backpack_panel.call("set_cooldown_visuals_enabled", true)
	backpack_panel.call("render_backpack_items", inventory)
	await _settle_frames(3)
	var slot = _backpack_slot_for_artifact(backpack_panel, drill) as Panel
	var image_layer = backpack_panel.get_node_or_null("ArtifactImageLayer") as Control
	var image = image_layer.get_node_or_null("DrillImage_%s" % str(drill.id)) as TextureRect if image_layer != null else null
	_assert(slot != null, "reward workspace image contract finds the starter drill slot")
	_assert(image_layer != null, "reward workspace image contract exposes the artifact image layer")
	_assert(image != null, "reward workspace image contract renders a drill image node")
	if slot != null and image != null:
		var slot_rect: Rect2 = slot.get_global_rect()
		var image_rect: Rect2 = image.get_global_rect()
		_assert(slot_rect.grow(1.0).has_point(image_rect.position), "reward workspace drill image begins inside its backpack slot")
		_assert(slot_rect.grow(1.0).has_point(image_rect.end - Vector2.ONE), "reward workspace drill image ends inside its backpack slot")
		_assert(image_rect.size.x >= slot_rect.size.x * 0.92, "reward workspace drill image fills most of the slot width")
		_assert(image_rect.size.y >= slot_rect.size.y * 0.92, "reward workspace drill image fills most of the slot height")
		_assert_eq(int(image.stretch_mode), int(TextureRect.STRETCH_KEEP_ASPECT_COVERED), "reward workspace drill image uses a cover mode so art fills the slot")
	var overlay = slot.get_node_or_null("Overlay") as Panel if slot != null else null
	var charge = slot.get_node_or_null("ChargeOverlay") as Panel if slot != null else null
	_assert(overlay != null, "reward workspace image contract keeps the base overlay node")
	_assert(charge != null, "reward workspace image contract keeps the cooldown overlay node")
	if overlay != null:
		_assert(overlay.get_theme_stylebox("panel") is StyleBoxEmpty, "image-backed drill suppresses the colored artifact background overlay")
	if charge != null:
		_assert(charge.visible, "image-backed drill keeps cooldown overlay visible when cooldown visuals are enabled")
		_assert(charge.get_theme_stylebox("panel") is StyleBoxFlat, "image-backed drill keeps the existing translucent cooldown mask style")
		if image_layer != null:
			_assert(int(charge.z_index) > int(image_layer.z_index), "image-backed drill keeps cooldown overlay drawn above the item image layer")
	main_instance.queue_free()
	await Engine.get_main_loop().process_frame

func test_reward_workspace_image_drill_tracks_grid_position_changes() -> void:
	var main_instance = await _boot_live_reward_tray()
	if main_instance == null:
		return
	var controller = main_instance.get_node_or_null("MainController")
	var backpack_container = main_instance.get("backpack_container") as Control
	var backpack_panel = backpack_container.get_node_or_null("BackpackEnginePanel") as Control if backpack_container != null else null
	_assert(controller != null, "reward workspace image drift contract has a live controller")
	_assert(backpack_panel != null, "reward workspace image drift contract has the shared backpack panel")
	if controller == null or backpack_panel == null:
		main_instance.queue_free()
		await Engine.get_main_loop().process_frame
		return
	var inventory = controller.get("inventory")
	var drill = inventory.artifacts.get("starter_purple_drill", null) if inventory != null else null
	var grid = backpack_panel.get_node_or_null("Margin/EngineBox/GridMock") as Control
	_assert(drill != null, "reward workspace image drift contract finds the starter drill")
	_assert(grid != null, "reward workspace image drift contract finds the backpack grid")
	if drill == null or grid == null:
		main_instance.queue_free()
		await Engine.get_main_loop().process_frame
		return
	backpack_panel.call("render_backpack_items", inventory)
	await _settle_frames(2)
	var slot = _backpack_slot_for_artifact(backpack_panel, drill) as Control
	var image_layer = backpack_panel.get_node_or_null("ArtifactImageLayer") as Control
	var image = image_layer.get_node_or_null("DrillImage_%s" % str(drill.id)) as TextureRect if image_layer != null else null
	_assert(slot != null, "reward workspace image drift contract finds the starter drill slot")
	_assert(image != null, "reward workspace image drift contract renders a drill image node")
	if slot == null or image == null:
		main_instance.queue_free()
		await Engine.get_main_loop().process_frame
		return
	var slot_center_before := slot.get_global_rect().get_center()
	_assert_centers_close(image.get_global_rect(), slot.get_global_rect(), 1.0, "reward workspace drill image starts centered in its slot")
	grid.position += Vector2(24.0, 0.0)
	await _settle_frames(4)
	slot = _backpack_slot_for_artifact(backpack_panel, drill) as Control
	image = image_layer.get_node_or_null("DrillImage_%s" % str(drill.id)) as TextureRect if image_layer != null else null
	if slot != null and image != null:
		var slot_center_after := slot.get_global_rect().get_center()
		_assert(slot_center_after.distance_to(slot_center_before) >= 12.0, "reward workspace image drift contract moves the grid slot without resizing it")
		_assert_centers_close(image.get_global_rect(), slot.get_global_rect(), 1.0, "reward workspace drill image follows grid position-only layout drift")
	main_instance.queue_free()
	await Engine.get_main_loop().process_frame

func test_reward_board_bottom_row_hides_empty_helper_rows_and_scrollbars() -> void:
	var main_instance = await _instantiate_reward_board_surface(
		_verbose_reward_fixture(),
		RewardReadModelScript.project_tray(_verbose_reward_fixture())
	)
	if main_instance == null:
		return
	await _settle_frames(2)
	var discard_hint = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/ZoneHead/ZoneHint") as Label
	var confirm_hint = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ZoneHead/ZoneHint") as Label
	var discard_card_title = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/DiscardCardScroll/DiscardCard/Margin/DiscardCardBox/DiscardCardTitle") as Label
	var claim_card_title = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCardScroll/ClaimCard/Margin/ClaimCardBox/ClaimCardTitle") as Label
	var discard_scroll = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/DiscardZone/Margin/ZoneBox/DiscardCardScroll") as ScrollContainer
	var claim_scroll = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/BottomRow/ConfirmZone/Margin/ZoneBox/ClaimCardScroll") as ScrollContainer
	_assert(discard_hint != null, "reward tray discard zone exposes the optional hint label")
	_assert(confirm_hint != null, "reward tray confirm zone exposes the optional hint label")
	_assert(discard_card_title != null, "reward tray discard card exposes the optional inner title label")
	_assert(claim_card_title != null, "reward tray confirm card exposes the optional inner title label")
	_assert(discard_scroll != null, "reward tray discard zone installs a scroll shell")
	_assert(claim_scroll != null, "reward tray confirm zone installs a scroll shell")
	if discard_hint != null:
		_assert_eq(discard_hint.visible, false, "reward tray discard hint hides when helper copy is empty so no blank title row remains")
	if confirm_hint != null:
		_assert_eq(confirm_hint.visible, false, "reward tray confirm hint hides when helper copy is empty so no blank title row remains")
	if discard_card_title != null:
		_assert_eq(discard_card_title.visible, false, "reward tray discard card title hides when helper copy is empty so the label body sits at the top")
	if claim_card_title != null:
		_assert_eq(claim_card_title.visible, false, "reward tray confirm card title hides when helper copy is empty so the claim body sits at the top")
	if discard_scroll != null and discard_scroll.get_v_scroll_bar() != null:
		_assert(not discard_scroll.get_v_scroll_bar().visible, "reward tray discard card avoids a vertical scrollbar once blank helper rows are removed")
	if claim_scroll != null and claim_scroll.get_v_scroll_bar() != null:
		_assert(not claim_scroll.get_v_scroll_bar().visible, "reward tray confirm card avoids a vertical scrollbar once blank helper rows are removed")
	main_instance.queue_free()
	await Engine.get_main_loop().process_frame

func test_reward_header_uses_selected_leviathan_name() -> void:
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene loads for leviathan header title contract")
	if MainScene == null:
		return
	var main_instance = MainScene.instantiate()
	if main_instance == null:
		return
	Engine.get_main_loop().root.add_child(main_instance)
	await _settle_frames(2)
	var controller = main_instance.get_node_or_null("MainController")
	var title_label = main_instance.get_node_or_null("RootMargin/AppShell/Header/Margin/PhaseRow/TitleLabel") as Label
	if controller != null:
		controller = await _boot_to_node_select(main_instance)
	_assert(controller != null, "main controller exists for leviathan header title contract")
	_assert(title_label != null, "main header exposes the title label for leviathan title contract")
	if controller != null and title_label != null:
		var current_scene: Dictionary = controller.get("current_scene")
		var selected_leviathan: Dictionary = current_scene.get("selectedLeviathan", {})
		var expected_title := str(selected_leviathan.get("name", "")).strip_edges()
		_assert(not expected_title.is_empty(), "reward flow keeps the selected Leviathan name in the decorated scene")
		if not expected_title.is_empty():
			_assert_eq(title_label.text, expected_title, "main header uses the selected Leviathan name instead of the old static app title during reward flow")
	main_instance.queue_free()
	await Engine.get_main_loop().process_frame

func _boot_live_reward_tray() -> Node:
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene loads for live reward-board click contract")
	if MainScene == null:
		return null
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for live reward-board click contract")
	if main_instance == null:
		return null
	Engine.get_main_loop().root.add_child(main_instance)
	await _settle_frames(2)
	var controller = await _boot_to_node_select(main_instance)
	if controller == null:
		main_instance.queue_free()
		await Engine.get_main_loop().process_frame
		return null
	var page_scenes: Dictionary = main_instance.get("page_scenes")
	var node_select_page = page_scenes.get("node_select", null)
	_assert(node_select_page != null, "node select page exists for reward-board click contract")
	if node_select_page != null and node_select_page.has_method("press_start_marker"):
		node_select_page.call("press_start_marker")
	elif node_select_page != null and node_select_page.has_method("route_button_count") and node_select_page.has_method("press_route_button"):
		if int(node_select_page.call("route_button_count")) > 0:
			node_select_page.call("press_route_button", 0)
	await Engine.get_main_loop().process_frame
	await Engine.get_main_loop().process_frame
	var start_button = main_instance.get("start_button")
	_assert(start_button != null, "start button exists for reward-board click contract")
	if start_button != null:
		start_button.pressed.emit()
	await _settle_frames(2)
	_assert_eq(str(main_instance.get("active_page_id")), "battle", "reward-board click contract reaches battle before reward entry")
	controller.preview_controller.run.apply_combat_input({"type": "resolve", "outcome": "clear"})
	controller.call("_render_scene", controller.preview_controller.get_scene())
	await _settle_frames(2)
	var reward_reveal_overlay = main_instance.get_node_or_null("RewardRevealOverlay")
	_assert(reward_reveal_overlay != null, "live reward flow exposes the reward reveal overlay")
	if reward_reveal_overlay != null:
		await _finish_reward_ceremony(controller, reward_reveal_overlay)
	await _settle_frames(10)
	await _dismiss_visible_narrative(main_instance)
	_assert_eq(str(main_instance.get("active_page_id")), "reward", "live reward flow remains on the reward page after ceremony completion")
	_assert_eq(str(controller.get("reward_presentation_step")), "tray_review", "live reward flow advances to tray review before click checks")
	return main_instance

func _dismiss_visible_narrative(main_instance: Node) -> void:
	var toast = main_instance.get("narrative_toast") as Control
	if toast != null and toast.visible and toast.has_method("dismiss"):
		toast.call("dismiss")
	await _settle_frames(2)

func _instantiate_reward_board_surface(rewards: Array, tray_model: Dictionary) -> Node:
	var MainScene = load("res://src/Main.tscn")
	_assert(MainScene != null, "main scene loads for reward-board surface contract")
	if MainScene == null:
		return null
	var main_instance = MainScene.instantiate()
	_assert(main_instance != null, "main scene instantiates for reward-board surface contract")
	if main_instance == null:
		return null
	Engine.get_main_loop().root.add_child(main_instance)
	await _settle_frames(2)
	main_instance.render_scene(_reward_scene_fixture(rewards), false)
	main_instance.render_reward_tray(tray_model)
	await _settle_frames(2)
	return main_instance

func _advance_story_if_present(main_instance: Node, return_page_id: String) -> void:
	if str(main_instance.get("active_page_id")) != "story_scene":
		return
	var story_page = main_instance.get("story_scene_page")
	var controller = main_instance.get_node_or_null("MainController")
	_assert(story_page != null, "story scene page exists during reward-board boot")
	_assert(controller != null, "main controller exists during reward-board story handoff")
	if story_page == null or controller == null:
		return
	var story: Dictionary = controller.get("active_story_scene")
	var scene_id := str(story.get("id", ""))
	_assert(scene_id != "", "story scene exposes an active scene id during reward-board boot")
	story_page.continue_requested.emit(scene_id)
	await _settle_frames(1)
	story_page.continue_requested.emit(scene_id)
	await _settle_frames(2)
	_assert_eq(str(main_instance.get("active_page_id")), return_page_id, "story scene returns to %s during reward-board boot" % return_page_id)

func _boot_to_node_select(main_instance: Node, color: String = "purple", leviathan_id: String = "filed_lizard") -> Node:
	var controller = main_instance.get_node_or_null("MainController")
	_assert(controller != null, "main controller exists during reward-board boot")
	if controller == null:
		return null
	var character_page = main_instance.get("character_select_page")
	_assert(character_page != null, "character select page exists during reward-board boot")
	if character_page != null:
		character_page.color_selected.emit(color)
		character_page.continue_requested.emit()
	await _settle_frames(2)
	await _advance_story_if_present(main_instance, "leviathan_select")
	_assert_eq(str(main_instance.get("active_page_id")), "leviathan_select", "character select advances to leviathan select during reward-board boot")
	var leviathan_page = main_instance.get("leviathan_select_page")
	_assert(leviathan_page != null, "leviathan select page exists during reward-board boot")
	if leviathan_page != null:
		leviathan_page.leviathan_selected.emit(leviathan_id)
		leviathan_page.start_requested.emit()
	await _settle_frames(3)
	_assert_eq(str(main_instance.get("active_page_id")), "node_select", "leviathan select advances to node select during reward-board boot")
	return controller

func _press_current_node(main_instance: Node, preferred_route_index: int, label: String) -> void:
	var controller = main_instance.get_node_or_null("MainController")
	var page_scenes: Dictionary = main_instance.get("page_scenes")
	var node_select_page = page_scenes.get("node_select", null)
	_assert(node_select_page != null, "node select page exists for %s" % label)
	if node_select_page == null:
		return
	var route_count := int(node_select_page.call("route_button_count")) if node_select_page.has_method("route_button_count") else 0
	if route_count > 0:
		_assert(node_select_page.has_method("press_route_button"), "node select page exposes route-button helper for %s" % label)
		if node_select_page.has_method("press_route_button"):
			node_select_page.call("press_route_button", clampi(preferred_route_index, 0, route_count - 1))
		return
	var current_scene: Dictionary = controller.get("current_scene") if controller != null else {}
	var is_boss_stage := bool(current_scene.get("nodeSelect", {}).get("isBossStage", false))
	if is_boss_stage:
		_assert(node_select_page.has_method("press_boss_marker"), "node select page exposes boss marker helper for %s" % label)
		if node_select_page.has_method("press_boss_marker"):
			node_select_page.call("press_boss_marker")
		return
	_assert(node_select_page.has_method("press_start_marker"), "node select page exposes fixed-start marker helper for %s" % label)
	if node_select_page.has_method("press_start_marker"):
		node_select_page.call("press_start_marker")

func _finish_reward_ceremony(controller: Node, reward_reveal_overlay: Node) -> void:
	var reward_count: int = max(1, int(Array(controller.get("local_rewards_list")).size()))
	reward_reveal_overlay.set("current_step", "reveal_queue")
	reward_reveal_overlay.set("current_reveal_index", reward_count - 1)
	reward_reveal_overlay.set("readable", true)
	reward_reveal_overlay.call("_handle_confirm_input")
	var settle_frames: int = 0
	while bool(controller.get("is_reveal_vfx_running")) and settle_frames < 16:
		await Engine.get_main_loop().process_frame
		settle_frames += 1
	await _settle_frames(2)

func _reward_scene_fixture(rewards: Array) -> Dictionary:
	return {
		"phase": "reward_loot",
		"pageId": "reward",
		"rewardPresentationStep": "tray_review",
		"reward": {"pendingRewards": rewards},
		"terrain": {"rows": 0, "columns": 0, "cells": []},
		"hud": {},
		"targetPanel": {},
		"stageIndex": 1,
		"maxStages": 5
	}

func _verbose_reward_fixture() -> Array:
	var long_name: String = "Catastrophically Verbose Resonance Fault Seal That Should Wrap Inside The Inspector Instead Of Resizing The Reward Board"
	var long_copy: String = "Stabilizes linked drills, preserves reward cleanup timing, mirrors diagonal relay bonuses, and keeps the inspection panel readable even when the localized name is intentionally long for containment coverage."
	return [
		{
			"kind": long_name,
			"rarity": "common",
			"qty": 1,
			"presentation": {"badge": "common relic"},
			"payload": {
				"item_type": "relic",
				"energy_type": "",
				"shape": [[1]],
				"effect_schema": {
					"link_mode": "reward_tray",
					"summary_i18n": {"en": long_copy, "ko": long_copy}
				}
			},
			"text": {
				"name": {"en": long_name, "ko": long_name},
				"description": {"en": long_copy, "ko": long_copy}
			}
		},
		{
			"kind": "Compact Tide Bit",
			"rarity": "common",
			"qty": 1,
			"presentation": {"badge": "common blue drill"},
			"payload": {
				"item_type": "drill",
				"energy_type": "blue",
				"shape": [[1], [1]],
				"base_cooldown_ticks": 60,
				"damage": 2.2
			},
			"text": {
				"name": {"en": "Compact Tide Bit", "ko": "Compact Tide Bit"},
				"description": {"en": "Compact control drill.", "ko": "Compact control drill."}
			}
		}
	]

func _reward_board_metrics(main_instance: Node) -> Dictionary:
	var viewport_size: Vector2 = main_instance.get_viewport().get_visible_rect().size
	var reward_panel = _reward_node(main_instance, "RewardPanel") as Control
	var reward_box = _reward_node(main_instance, "RewardPanel/Margin/RewardBox") as Control
	var reward_board_scroll = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll") as ScrollContainer
	var reward_grid = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid") as Control
	var rewards_zone = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone") as Control
	var workspace_zone = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone") as Control
	var inspector_zone = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone") as Control
	var backpack_host = _reward_node(main_instance, "RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone/Margin/ZoneBox/BackpackHost") as Control
	var backpack_container = main_instance.get("backpack_container") as Control
	var backpack_grid = backpack_container.get_node_or_null("BackpackEnginePanel/Margin/EngineBox/GridMock") as Control if backpack_container != null else null
	return {
		"viewport_width": viewport_size.x,
		"panel_x": reward_panel.global_position.x if reward_panel != null else -1.0,
		"panel_width": reward_panel.size.x if reward_panel != null else -1.0,
		"box_width": reward_box.size.x if reward_box != null else -1.0,
		"scroll_width": reward_board_scroll.size.x if reward_board_scroll != null else -1.0,
		"scroll_height": reward_board_scroll.size.y if reward_board_scroll != null else -1.0,
		"grid_x": reward_grid.global_position.x if reward_grid != null else -1.0,
		"grid_width": reward_grid.size.x if reward_grid != null else -1.0,
		"grid_end_x": reward_grid.global_position.x + reward_grid.size.x if reward_grid != null else -1.0,
		"rewards_x": rewards_zone.global_position.x if rewards_zone != null else -1.0,
		"rewards_width": rewards_zone.size.x if rewards_zone != null else -1.0,
		"workspace_x": workspace_zone.global_position.x if workspace_zone != null else -1.0,
		"workspace_width": workspace_zone.size.x if workspace_zone != null else -1.0,
		"backpack_host_height": backpack_host.size.y if backpack_host != null else -1.0,
		"inspector_x": inspector_zone.global_position.x if inspector_zone != null else -1.0,
		"inspector_width": inspector_zone.size.x if inspector_zone != null else -1.0,
		"backpack_x": backpack_host.global_position.x if backpack_host != null else -1.0,
		"backpack_width": backpack_host.size.x if backpack_host != null else -1.0,
		"backpack_panel_width": backpack_container.size.x if backpack_container != null else -1.0,
		"backpack_panel_height": backpack_container.size.y if backpack_container != null else -1.0,
		"backpack_grid_width": backpack_grid.size.x if backpack_grid != null else -1.0,
		"backpack_grid_height": backpack_grid.size.y if backpack_grid != null else -1.0
	}

func _assert_reward_board_metrics_close(expected: Dictionary, actual: Dictionary, label: String) -> void:
	for key in [
		"panel_x",
		"panel_width",
		"box_width",
		"scroll_width",
		"scroll_height",
		"grid_x",
		"grid_width",
		"grid_end_x",
		"rewards_x",
		"rewards_width",
		"workspace_x",
		"workspace_width",
		"backpack_host_height",
		"inspector_x",
		"inspector_width",
		"backpack_x",
		"backpack_width",
		"backpack_panel_width",
		"backpack_panel_height",
		"backpack_grid_width",
		"backpack_grid_height"
	]:
		_assert_close(float(actual.get(key, -9999.0)), float(expected.get(key, -9999.0)), 3.0, "%s keeps %s stable" % [label, key])

func _assert_reward_board_backpack_panel_uses_workspace_height(metrics: Dictionary, label: String) -> void:
	var host_height: float = float(metrics.get("backpack_host_height", -1.0))
	var panel_height: float = float(metrics.get("backpack_panel_height", -1.0))
	var grid_height: float = float(metrics.get("backpack_grid_height", -1.0))
	_assert(host_height > 0.0, "%s exposes a positive workspace host height for backpack-fit checks" % label)
	_assert(panel_height > 0.0, "%s exposes a positive docked backpack panel height for backpack-fit checks" % label)
	_assert(grid_height > 0.0, "%s exposes a positive docked backpack grid height for backpack-fit checks" % label)
	if host_height <= 0.0 or panel_height <= 0.0 or grid_height <= 0.0:
		return
	_assert(panel_height >= host_height * 0.74, "%s keeps the docked backpack panel tall enough to fill most of the workspace host (panel=%.2f host=%.2f)" % [label, panel_height, host_height])
	_assert(grid_height >= host_height * 0.62, "%s keeps the docked backpack grid tall enough to read as the main workspace immediately on entry (grid=%.2f host=%.2f)" % [label, grid_height, host_height])

func _assert_reward_board_inside_viewport(main_instance: Node, label: String) -> void:
	var viewport: Rect2 = Rect2(Vector2.ZERO, main_instance.get_viewport().get_visible_rect().size)
	for path in [
		"RewardPanel",
		"RewardPanel/Margin/RewardBox",
		"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid",
		"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/RewardsZone",
		"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/WorkspaceZone",
		"RewardPanel/Margin/RewardBox/RewardBoardScroll/RewardBoard/RewardGrid/InspectorZone"
	]:
		var control: Control = _reward_node(main_instance, path) as Control
		_assert(control != null, "%s exposes %s for viewport containment" % [label, path])
		if control == null or not control.visible:
			continue
		var rect: Rect2 = control.get_global_rect()
		_assert(rect.position.x >= viewport.position.x - 0.5, "%s keeps %s inside viewport left edge" % [label, path])
		_assert(rect.position.y >= viewport.position.y - 0.5, "%s keeps %s inside viewport top edge" % [label, path])
		_assert(rect.end.x <= viewport.end.x + 0.5, "%s keeps %s inside viewport right edge (rect=%s viewport=%s)" % [label, path, str(rect), str(viewport)])
		_assert(rect.end.y <= viewport.end.y + 0.5, "%s keeps %s inside viewport bottom edge" % [label, path])

func _assert_reward_board_uses_visible_shell_width(metrics: Dictionary, label: String) -> void:
	var panel_x: float = float(metrics.get("panel_x", -1.0))
	var panel_width: float = float(metrics.get("panel_width", -1.0))
	var grid_end_x: float = float(metrics.get("grid_end_x", -1.0))
	var viewport_width: float = float(metrics.get("viewport_width", -1.0))
	_assert(panel_x >= -0.5, "%s keeps the reward panel anchored within the viewport" % label)
	_assert(grid_end_x <= panel_x + panel_width + 0.5, "%s keeps the reward grid inside the live reward panel width" % label)
	_assert(grid_end_x <= viewport_width + 0.5, "%s keeps the reward grid inside the viewport width" % label)

func _first_inventory_coord(inventory) -> Vector2:
	if inventory == null:
		return Vector2(-1, -1)
	for row in range(8):
		for column in range(8):
			var slot_id: String = str(inventory.grid[row][column])
			if slot_id.is_empty():
				continue
			if inventory.artifacts.has(slot_id):
				return Vector2(column, row)
	return Vector2(-1, -1)

func _backpack_slot_for_artifact(backpack_panel: Control, artifact) -> Control:
	if backpack_panel == null or artifact == null:
		return null
	return _backpack_slot_at(backpack_panel, int(artifact.x), int(artifact.y))

func _backpack_slot_at(backpack_panel: Control, column: int, row: int) -> Control:
	if backpack_panel == null:
		return null
	var grid = backpack_panel.get_node_or_null("Margin/EngineBox/GridMock") as GridContainer
	if grid == null:
		return null
	var slot_idx := (row + 1) * 10 + (column + 1)
	if slot_idx < 0 or slot_idx >= grid.get_child_count():
		return null
	return grid.get_child(slot_idx) as Control

func _assert_live_starter_drill_centered(controller: Node, backpack_panel: Control, label: String) -> void:
	var inventory = controller.get("inventory") if controller != null else null
	var drill = inventory.artifacts.get("starter_purple_drill", null) if inventory != null else null
	var slot = _backpack_slot_for_artifact(backpack_panel, drill) as Control
	var image_layer = backpack_panel.get_node_or_null("ArtifactImageLayer") as Control if backpack_panel != null else null
	var image = image_layer.get_node_or_null("DrillImage_%s" % str(drill.id)) as TextureRect if image_layer != null and drill != null else null
	_assert(drill != null, "%s finds the starter drill" % label)
	_assert(slot != null, "%s finds the starter drill slot" % label)
	_assert(image != null, "%s renders the starter drill image node" % label)
	if slot == null or image == null:
		return
	var slot_rect := slot.get_global_rect()
	var image_rect := image.get_global_rect()
	_assert(slot_rect.grow(1.0).has_point(image_rect.position), "%s keeps the starter drill image inside the slot top-left" % label)
	_assert(slot_rect.grow(1.0).has_point(image_rect.end - Vector2.ONE), "%s keeps the starter drill image inside the slot bottom-right" % label)
	_assert_centers_close(image_rect, slot_rect, 1.0, "%s keeps the starter drill image centered in its slot" % label)

func _select_first_placeable_reward_drag(controller: Node) -> Dictionary:
	var rewards: Array = Array(controller.get("local_rewards_list"))
	for index in range(rewards.size()):
		controller.call("_on_reward_meta_drag_started_v2", index)
		await _settle_frames(2)
		var artifact = controller.get("held_artifact")
		if artifact == null:
			continue
		var coord := _first_valid_reward_drop_coord(controller.get("inventory"), artifact)
		if coord.x >= 0.0 and coord.y >= 0.0:
			return {
				"index": index,
				"coord": coord,
				"artifactId": str(artifact.id)
			}
		controller.call("_on_reward_meta_drag_canceled_v2", index)
		await _settle_frames(2)
	return {}

func _first_valid_reward_drop_coord(inventory, artifact) -> Vector2:
	if inventory == null or artifact == null:
		return Vector2(-1, -1)
	if _duplicate_drill_blocked(inventory, artifact):
		return Vector2(-1, -1)
	for row in range(8):
		for column in range(8):
			if inventory.can_place_artifact(artifact, column, row):
				return Vector2(column, row)
	return Vector2(-1, -1)

func _duplicate_drill_blocked(inventory, artifact) -> bool:
	if inventory == null or artifact == null or str(artifact.item_type) != "drill":
		return false
	for art_id in inventory.artifacts:
		var other = inventory.artifacts[art_id]
		if other != null and str(other.item_type) == "drill" and str(other.energy_type) == str(artifact.energy_type) and str(other.id) != str(artifact.id):
			return true
	return false

func _assert_artifact_rendered_in_reward_backpack(backpack_panel: Control, artifact, label: String) -> void:
	var slot = _backpack_slot_for_artifact(backpack_panel, artifact) as Control
	_assert(slot != null, "%s finds the placed artifact slot" % label)
	if slot == null:
		return
	var image_layer = backpack_panel.get_node_or_null("ArtifactImageLayer") as Control if backpack_panel != null else null
	var image = image_layer.get_node_or_null("DrillImage_%s" % str(artifact.id)) as TextureRect if image_layer != null else null
	if image != null:
		_assert_centers_close(image.get_global_rect(), _artifact_footprint_global_rect(backpack_panel, artifact), 1.0, "%s centers the image-backed artifact" % label)
		return
	var overlay = slot.get_node_or_null("Overlay") as Panel
	_assert(overlay != null, "%s finds the placed artifact overlay" % label)
	if overlay != null:
		_assert(not (overlay.get_theme_stylebox("panel") is StyleBoxEmpty), "%s draws the non-image artifact overlay" % label)

func _artifact_footprint_global_rect(backpack_panel: Control, artifact) -> Rect2:
	var rect := Rect2()
	var initialized := false
	var shape: Array = artifact.shape
	for shape_row in range(shape.size()):
		if not shape[shape_row] is Array:
			continue
		for shape_column in range(shape[shape_row].size()):
			if int(shape[shape_row][shape_column]) != 1:
				continue
			var slot = _backpack_slot_at(backpack_panel, int(artifact.x) + shape_column, int(artifact.y) + shape_row) as Control
			if slot == null:
				continue
			rect = slot.get_global_rect() if not initialized else rect.merge(slot.get_global_rect())
			initialized = true
	return rect

func _settle_frames(count: int) -> void:
	for _index in range(count):
		await Engine.get_main_loop().process_frame

func _reward_node(main_instance: Node, path: String = "") -> Node:
	if main_instance == null or not main_instance.has_method("bundle_node"):
		return null
	return main_instance.call("bundle_node", "reward", path)

func _assert(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)

func _assert_eq(actual: Variant, expected: Variant, label: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])

func _assert_close(actual: float, expected: float, tolerance: float, label: String) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s: expected %.2f, got %.2f (tol=%.2f)" % [label, expected, actual, tolerance])

func _assert_centers_close(actual: Rect2, expected: Rect2, tolerance: float, label: String) -> void:
	var distance := actual.get_center().distance_to(expected.get_center())
	if distance > tolerance:
		failures.append("%s: expected center %s, got %s (distance=%.2f tol=%.2f)" % [label, str(expected.get_center()), str(actual.get_center()), distance, tolerance])
