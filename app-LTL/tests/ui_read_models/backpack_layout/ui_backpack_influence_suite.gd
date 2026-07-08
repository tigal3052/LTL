extends "res://tests/support/UiReadModelTestSuite.gd"
func run_all_tests() -> Dictionary:
	failures.clear()
	test_backpack_slots_include_influence_background_layer()
	test_backpack_influence_preview_toggle_exists_on_engine_panel()
	test_backpack_influence_preview_toggle_can_be_hidden_outside_reward()
	test_backpack_influence_preview_toggle_stays_off_slot_click_area()
	test_phase_layout_scopes_influence_preview_toggle_to_reward_pages()
	test_battle_action_bar_removes_manual_hold_and_repair_buttons()
	test_backpack_influence_range_contracts_cover_beacon_and_relic_links()
	test_backpack_influence_overlay_defaults_to_placed_ranges_and_toggle_gates_normal_backpack()
	return _result()
func test_backpack_slots_include_influence_background_layer() -> void:
	var slot := BackpackGridFactoryScript.inner_slot(null)
	var influence := slot.get_node_or_null("InfluenceOverlay") as Panel
	var artifact_overlay := slot.get_node_or_null("Overlay") as Panel
	var drop_cue := slot.get_node_or_null("DropCueOverlay") as Panel
	_assert(influence != null, "backpack slot exposes a yellow influence background overlay")
	if influence != null:
		_assert_eq(int(influence.mouse_filter), int(Control.MOUSE_FILTER_IGNORE), "influence overlay never steals slot pointer input")
		_assert(artifact_overlay == null or int(influence.z_index) < int(artifact_overlay.z_index), "influence overlay renders below artifact fill")
		_assert(drop_cue == null or int(influence.z_index) < int(drop_cue.z_index), "drop validity cue remains readable above influence range")
	slot.free()
func test_backpack_influence_preview_toggle_exists_on_engine_panel() -> void:
	var BackpackEnginePanelScene = load("res://src/scenes/pages/shells/BackpackEnginePanel.tscn")
	_assert(BackpackEnginePanelScene != null, "backpack engine panel scene loads for influence preview toggle contract")
	if BackpackEnginePanelScene == null:
		return
	var engine_panel = BackpackEnginePanelScene.instantiate()
	_assert(engine_panel != null, "backpack engine panel instantiates for influence preview toggle contract")
	if engine_panel == null:
		return
	_assert(engine_panel.has_method("set_influence_preview_enabled"), "backpack panel exposes influence preview toggle setter")
	_assert(engine_panel.has_method("get_influence_preview_enabled"), "backpack panel exposes influence preview toggle getter")
	if engine_panel.has_method("_setup_influence_preview_toggle"):
		engine_panel.call("_setup_influence_preview_toggle")
	var toggle := engine_panel.get_node_or_null("InfluencePreviewToggle") as CheckButton
	_assert(toggle != null, "backpack panel creates a side toggle for influence preview visibility")
	if toggle != null:
		_assert_eq(bool(toggle.button_pressed), true, "influence preview toggle defaults on for active ghost previews")
		engine_panel.call("set_influence_preview_enabled", false)
		_assert_eq(bool(toggle.button_pressed), false, "influence preview toggle stays in sync when previews are disabled")
	engine_panel.free()
func test_backpack_influence_preview_toggle_can_be_hidden_outside_reward() -> void:
	var BackpackEnginePanelScene = load("res://src/scenes/pages/shells/BackpackEnginePanel.tscn")
	_assert(BackpackEnginePanelScene != null, "backpack engine panel scene loads for scoped influence toggle visibility")
	if BackpackEnginePanelScene == null:
		return
	var engine_panel = BackpackEnginePanelScene.instantiate()
	_assert(engine_panel != null, "backpack engine panel instantiates for scoped influence toggle visibility")
	if engine_panel == null:
		return
	_assert(engine_panel.has_method("set_influence_preview_toggle_visible"), "backpack panel exposes a separate visibility setter for the influence toggle")
	if engine_panel.has_method("_setup_influence_preview_toggle"):
		engine_panel.call("_setup_influence_preview_toggle")
	var toggle := engine_panel.get_node_or_null("InfluencePreviewToggle") as CheckButton
	_assert(toggle != null, "backpack panel creates the influence toggle before visibility scoping")
	if toggle != null:
		_assert_eq(bool(toggle.is_set_as_top_level()), true, "influence toggle escapes engine-panel container layout so it can stay in the rendered upper-right")
		if engine_panel.has_method("set_influence_preview_toggle_visible"):
			engine_panel.call("set_influence_preview_toggle_visible", false)
			_assert_eq(bool(toggle.visible), false, "battle and non-reward contexts can hide the influence toggle")
			engine_panel.call("set_influence_preview_toggle_visible", true)
			_assert_eq(bool(toggle.visible), true, "reward contexts can show the influence toggle")
	engine_panel.free()
func test_backpack_influence_preview_toggle_stays_off_slot_click_area() -> void:
	var BackpackEnginePanelScene = load("res://src/scenes/pages/shells/BackpackEnginePanel.tscn")
	_assert(BackpackEnginePanelScene != null, "backpack engine panel scene loads for toggle click-area contract")
	if BackpackEnginePanelScene == null:
		return
	var engine_panel = BackpackEnginePanelScene.instantiate()
	_assert(engine_panel != null, "backpack engine panel instantiates for toggle click-area contract")
	if engine_panel == null:
		return
	if engine_panel.has_method("_setup_influence_preview_toggle"):
		engine_panel.call("_setup_influence_preview_toggle")
	var toggle := engine_panel.get_node_or_null("InfluencePreviewToggle") as CheckButton
	_assert(toggle != null, "backpack panel creates the influence toggle for click-area contract")
	if toggle != null:
		_assert_eq(bool(toggle.is_set_as_top_level()), true, "influence toggle is positioned independently of the slot grid container")
		_assert(engine_panel.has_method("_position_influence_preview_toggle"), "backpack panel exposes a rendered-position helper for the upper-right toggle rail")
		_assert(toggle.custom_minimum_size.x <= 96.0 and toggle.custom_minimum_size.y <= 32.0, "influence toggle remains compact enough for the upper-right rail")
	engine_panel.free()
func test_phase_layout_scopes_influence_preview_toggle_to_reward_pages() -> void:
	var combat = PhaseLayoutPresenterScript.project({"phase": "combat", "pageId": "battle", "stageIndex": 0, "maxStages": 3}, false)
	var reward = PhaseLayoutPresenterScript.project({"phase": "reward_loot", "pageId": "reward", "stageIndex": 0, "maxStages": 3, "rewardPresentationStep": "tray_review"}, false)
	var reward_ceremony = PhaseLayoutPresenterScript.project({"phase": "reward_loot", "pageId": "reward", "stageIndex": 0, "maxStages": 3, "rewardPresentationStep": "count_lock"}, false)
	_assert_eq(bool(combat.get("backpackInfluenceToggleVisible", true)), false, "battle layout hides the reward-only influence range toggle")
	_assert_eq(bool(reward.get("backpackInfluenceToggleVisible", false)), true, "reward tray review layout shows the influence range toggle")
	_assert_eq(bool(reward_ceremony.get("backpackInfluenceToggleVisible", true)), false, "reward reveal ceremony keeps the reward-only influence toggle hidden until the list page is active")
func test_battle_action_bar_removes_manual_hold_and_repair_buttons() -> void:
	var ActionBarScene = load("res://src/scenes/pages/shells/ActionBar.tscn")
	_assert(ActionBarScene != null, "action bar scene loads for manual battle button removal contract")
	if ActionBarScene != null:
		var action_bar = ActionBarScene.instantiate()
		_assert(action_bar.get_node_or_null("HoldFireButton") == null, "battle action bar no longer creates the manual continuous-fire button")
		_assert(action_bar.get_node_or_null("RepairButton") == null, "battle action bar no longer creates the manual repair-start button")
		action_bar.free()
	var runtime_state_text := FileAccess.get_file_as_string("res://src/ui/main_view/MainViewRuntimeState.gd")
	var page_shell_text := FileAccess.get_file_as_string("res://src/ui/main_view/MainViewPageShellRuntime.gd")
	var bootstrap_text := FileAccess.get_file_as_string("res://src/controllers/MainControllerBootstrapFlow.gd")
	var controller_text := FileAccess.get_file_as_string("res://src/MainController.gd")
	var combat_flow_text := FileAccess.get_file_as_string("res://src/controllers/MainControllerCombatFlow.gd")
	_assert(not runtime_state_text.contains("signal hold_fire_pressed"), "view runtime no longer exposes manual continuous-fire signal")
	_assert(not runtime_state_text.contains("signal repair_pressed"), "view runtime no longer exposes manual repair signal")
	_assert(not page_shell_text.contains("holdFireButton"), "page shell no longer captures or wires a manual continuous-fire action button")
	_assert(not page_shell_text.contains("repairButton"), "page shell no longer captures or wires a manual repair action button")
	_assert(not bootstrap_text.contains("_on_hold_fire_pressed"), "bootstrap no longer connects the removed manual continuous-fire button")
	_assert(not bootstrap_text.contains("_on_repair_pressed"), "bootstrap no longer connects the removed manual repair button")
	_assert(not controller_text.contains("func _on_hold_fire_pressed"), "main controller removes the manual continuous-fire wrapper")
	_assert(not controller_text.contains("func _on_repair_pressed"), "main controller removes the manual repair wrapper")
	_assert(not combat_flow_text.contains("static func on_hold_fire_pressed"), "combat flow removes the button-only continuous-fire handler")
	_assert(not combat_flow_text.contains("static func on_repair_pressed"), "combat flow removes the button-only repair handler")
func test_backpack_influence_range_contracts_cover_beacon_and_relic_links() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("influence_feedback_cells_for"), "backpack exposes influence range cells for placed and ghost previews")
	if not backpack_ui.has_method("influence_feedback_cells_for"):
		return
	var beacon = ArtifactScript.new({"id": "range_beacon", "shape": [[1]], "energyType": "red", "item_type": "beacon"})
	_assert_eq(_sorted_cell_keys(backpack_ui.call("influence_feedback_cells_for", beacon, 3, 3)), ["2,3", "3,2", "3,4", "4,3"], "beacon influence highlights orthogonal adjacent cells")
	var diagonal_relic = ArtifactScript.new({"id": "diag_relic", "shape": [[1]], "item_type": "relic", "effect_schema": {"link_mode": "diagonal_1"}})
	_assert_eq(_sorted_cell_keys(backpack_ui.call("influence_feedback_cells_for", diagonal_relic, 3, 3)), ["2,2", "2,4", "4,2", "4,4"], "diagonal relic influence highlights the four corner cells")
	var skip_relic = ArtifactScript.new({"id": "skip_relic", "shape": [[1]], "item_type": "relic", "effect_schema": {"link_mode": "skip_2"}})
	_assert_eq(_sorted_cell_keys(backpack_ui.call("influence_feedback_cells_for", skip_relic, 3, 3)), ["1,3", "3,1", "3,5", "5,3"], "skip-two relic influence highlights exact two-cell straight links")
	var crown_relic = ArtifactScript.new({"id": "crown_relic", "shape": [[1]], "item_type": "relic", "effect_schema": {"link_mode": "crown_link"}})
	_assert_eq(_sorted_cell_keys(backpack_ui.call("influence_feedback_cells_for", crown_relic, 3, 3)), ["1,3", "2,2", "2,4", "3,1", "3,5", "4,2", "4,4", "5,3"], "crown relic influence combines diagonal and skip-two links")
func test_backpack_influence_overlay_defaults_to_placed_ranges_and_toggle_gates_normal_backpack() -> void:
	var Helper = load("res://src/ui/backpack/BackpackInfluenceHighlighter.gd")
	_assert(Helper != null, "backpack influence highlighter loads for placed-range contract")
	if Helper == null:
		return
	var owner := InfluenceOverlayOwner.new()
	var inventory := InventoryScript.new(8, 8)
	var beacon = ArtifactScript.new({"id": "preview_beacon", "shape": [[1]], "energyType": "red", "item_type": "beacon"})
	_assert_eq(inventory.place_artifact(beacon, 3, 3), true, "placed-range contract places a beacon fixture")
	Helper.call("refresh", owner, inventory)
	_assert_eq(owner.influenced_cell_keys(), ["2,3", "3,2", "3,4", "4,3"], "placed beacon paints influence cells by default in the normal backpack")
	owner.influence_preview_enabled = false
	Helper.call("refresh", owner, inventory)
	_assert_eq(owner.influenced_cell_keys(), [], "influence toggle off hides normal backpack range cells")
	Helper.call("refresh", owner, inventory, beacon, 1, 1)
	_assert_eq(owner.influenced_cell_keys(), ["0,1", "1,0", "1,2", "2,1"], "ghost influence remains the default drag preview even when normal backpack ranges are hidden")
	owner.influence_preview_enabled = true
	Helper.call("refresh", owner, inventory)
	_assert_eq(owner.influenced_cell_keys(), ["2,3", "3,2", "3,4", "4,3"], "influence toggle on restores normal backpack range cells")
	owner.cleanup()
func _sorted_cell_keys(cells: Array) -> Array:
	var keys: Array = []
	for cell in cells:
		var coord := cell as Vector2
		keys.append("%d,%d" % [int(coord.x), int(coord.y)])
	keys.sort()
	return keys
class InfluenceOverlayOwner:
	extends RefCounted
	var backpack_grid_mock := GridContainer.new()
	var influence_preview_enabled := true
	func _init() -> void:
		for row in range(10):
			for column in range(10):
				if row == 0 or row == 9 or column == 0 or column == 9:
					backpack_grid_mock.add_child(Panel.new())
				else:
					backpack_grid_mock.add_child(BackpackGridFactoryScript.inner_slot(null))
	func influenced_cell_keys() -> Array:
		var keys: Array = []
		for row in range(8):
			for column in range(8):
				var slot_idx := (row + 1) * 10 + (column + 1)
				var slot := backpack_grid_mock.get_child(slot_idx) as Panel
				var influence := slot.get_node_or_null("InfluenceOverlay") as Panel if slot != null else null
				if influence == null:
					continue
				if not (influence.get_theme_stylebox("panel") is StyleBoxEmpty):
					keys.append("%d,%d" % [column, row])
		keys.sort()
		return keys
	func get_influence_preview_enabled() -> bool:
		return influence_preview_enabled
	func cleanup() -> void:
		for child in backpack_grid_mock.get_children():
			backpack_grid_mock.remove_child(child)
			child.free()
		backpack_grid_mock.free()
