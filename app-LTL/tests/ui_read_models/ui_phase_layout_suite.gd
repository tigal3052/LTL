extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_phase_layout_projects_visibility_and_timer()
	test_phase_layout_prioritizes_meta_page_over_underlying_phase()
	test_reward_ceremony_keeps_final_combat_snapshot_live()
	test_node_select_layout_is_full_page()
	test_node_select_layout_uses_roadmap_page_shell()
	test_node_select_layout_reuses_palette_when_start_panel_is_hidden()
	test_top_content_backpack_uses_fixed_width_policy()
	test_top_content_backpack_width_tracks_full_row_height()
	test_top_content_backpack_width_ignores_available_space_clamp()
	test_top_content_backpack_height_uses_single_row_source()
	test_top_content_backpack_width_uses_slot_scaled_pin_overhang()
	return _result()

func test_phase_layout_projects_visibility_and_timer() -> void:
	TextCatalogScript.set_locale("ko")
	var scene := {"phase": "combat", "stageIndex": 1, "maxStages": 3, "targetPanel": {"timeLimitTicks": 1200.0, "elapsedTicks": 400.0}}
	var model = PhaseLayoutPresenterScript.project(scene, false)
	_assert_eq(model["phaseText"], TextCatalogScript.t("phase.label", [TextCatalogScript.t("phase.combat", [], "ko")], "ko"), "phase layout text")
	_assert_eq(model["stageText"], TextCatalogScript.t("stage.label", [2, 3], "ko"), "phase layout stage text")
	_assert_eq(model["battlefieldVisible"], true, "phase layout battlefield visible")
	_assert_eq(model["rewardVisible"], false, "phase layout reward hidden during combat")
	_assert_eq(model["timerText"], "00:40", "phase layout timer text")
	_assert_eq(model["combatTimeActive"], true, "phase layout combat time active")

func test_phase_layout_prioritizes_meta_page_over_underlying_phase() -> void:
	var meta_scene := {
		"phase": "node_select",
		"pageId": "character_select",
		"stageIndex": 0,
		"maxStages": 5
	}
	var model = PhaseLayoutPresenterScript.project(meta_scene, false)
	_assert_eq(model["headerVisible"], false, "character select hides the legacy shell header")
	_assert_eq(model["nodeSelectVisible"], false, "character select does not leak the underlying node-select page")
	_assert_eq(model["topContentVisible"], false, "character select hides the combat top-content row")
	_assert_eq(model["backpackVisible"], false, "character select hides the shared backpack surface")
	_assert_eq(model["actionBarVisible"], false, "character select hides the bottom action bar")

# ?ㅽ뻾: verify node selection owns the available page instead of sharing prototype side panels.
# ?ㅽ뻾: verify active reward ceremony beats keep the final combat snapshot visible until tray review begins.
func test_reward_ceremony_keeps_final_combat_snapshot_live() -> void:
	var ceremony_scene := {
		"phase": "reward_loot",
		"rewardPresentationStep": "count_lock",
		"targetPanel": {
			"timeLimitTicks": 480.0,
			"elapsedTicks": 420.0
		}
	}
	var ceremony_layout = PhaseLayoutPresenterScript.project(ceremony_scene, false)
	_assert_eq(ceremony_layout["battlefieldVisible"], true, "reward ceremony keeps battlefield visible")
	_assert_eq(ceremony_layout["statusVisible"], true, "reward ceremony keeps status panel visible")
	_assert_eq(ceremony_layout["rewardVisible"], false, "reward tray stays hidden during active ceremony beats")
	_assert_eq(ceremony_layout["topContentVisible"], true, "reward ceremony keeps the combat shell context visible while the reveal runs")
	_assert_eq(ceremony_layout["backpackVisible"], true, "reward ceremony keeps the shared backpack visible until tray review begins")
	_assert_eq(ceremony_layout["combatTimeActive"], true, "reward ceremony keeps the final combat timer visible")
	_assert_eq(ceremony_layout["timerText"], "00:03", "reward ceremony timer reflects the latest dynamic limit")
	_assert_eq(StatusPanelUIScript.should_render_status_scene(ceremony_scene), true, "status panel keeps rendering during active reward ceremony beats")

	var tray_review_scene := ceremony_scene.duplicate(true)
	tray_review_scene["rewardPresentationStep"] = "tray_review"
	var tray_review_layout = PhaseLayoutPresenterScript.project(tray_review_scene, false)
	_assert_eq(tray_review_layout["rewardVisible"], true, "tray review reopens the reward panel after the ceremony")
	_assert_eq(tray_review_layout["statusVisible"], false, "tray review hides the combat status panel again")
	_assert_eq(tray_review_layout["topContentVisible"], false, "tray review gives the reward-claim board the full shell instead of keeping the combat sidebars")
	_assert_eq(tray_review_layout["backpackVisible"], false, "tray review hides the top-row backpack because the workspace reuses the backpack inside the reward board")
	_assert_eq(tray_review_layout["sidebarsVisible"], false, "tray review hides the legacy sidebars in favor of the fixed inspector board")
	_assert_eq(tray_review_layout["actionBarVisible"], false, "tray review hides the old action bar because claim confirmation lives inside the reward board")
	_assert_eq(tray_review_layout["rewardBackpackDock"], true, "tray review requests the backpack to dock into the board workspace host")
	_assert_eq(tray_review_layout["combatTimeActive"], false, "tray review hides the combat timer again")
	_assert_eq(StatusPanelUIScript.should_render_status_scene(tray_review_scene), false, "status panel stops rendering after the active ceremony ends")

func test_node_select_layout_is_full_page() -> void:
	var model = PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 0, "maxStages": 5}, false)
	_assert_eq(model["nodeSelectVisible"], true, "node select panel visible")
	_assert_eq(model["nodeMapFullPage"], true, "node select page keeps the full-page layout shell")
	_assert_eq(model["headerVisible"], false, "node select retires the legacy shell header because page-level chrome now owns the controls")
	_assert_eq(model["topContentVisible"], false, "node select page replaces the combat top-content row with a dedicated roadmap page")
	_assert_eq(model["backpackVisible"], false, "node select page does not reuse the combat backpack sidebar")
	_assert_eq(model["sidebarsVisible"], false, "node select page hides nonessential combat sidebars")
	_assert_eq(model["statusVisible"], false, "node select page hides combat target status")

# ?ㅽ뻾: verify node selection requests a left map / right backpack layout.
func test_node_select_layout_uses_roadmap_page_shell() -> void:
	var model = PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 0, "maxStages": 5}, false)
	_assert_eq(model["nodeSelectBackpackDock"], "hidden", "node select disables the old backpack docking path")
	_assert_eq(float(model["nodeMapStretchRatio"]), 0.0, "node select no longer budgets width for the reused node-map split")
	_assert_eq(float(model["backpackStretchRatio"]), 0.0, "node select no longer budgets width for the reused backpack split")
	_assert_eq(model["shopButtonVisible"], false, "node select no longer uses the legacy shell shop button because the page frame owns utility actions")

func test_node_select_layout_reuses_palette_when_start_panel_is_hidden() -> void:
	var controller = MainControllerRuntimeScript.new()
	_assert(controller.has_method("node_map_loadout_colors_for_scene"), "main controller exposes one node-map loadout palette source")
	if controller.has_method("node_map_loadout_colors_for_scene"):
		_assert_eq(controller.call("node_map_loadout_colors_for_scene", {"phase": "node_select", "stageIndex": 1, "allowStartColorSelection": false}), ["red", "blue", "purple", "green"], "stage two keeps the same node-map palette data while the start panel is hidden")
	controller.free()
	var stage_one_layout := PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 0, "maxStages": 5}, false)
	var stage_two_layout := PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 1, "maxStages": 5}, false)
	_assert_eq(stage_one_layout.get("nodeMapFullPage", false), stage_two_layout.get("nodeMapFullPage", true), "node select keeps the same full-page layout shell across stages")
	_assert_eq(stage_one_layout.get("nodeSelectBackpackDock", ""), stage_two_layout.get("nodeSelectBackpackDock", ""), "node select keeps the same backpack dock across stages")

func test_top_content_backpack_uses_fixed_width_policy() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for top-content backpack sizing policy")
	if MainViewRuntimeScript == null:
		return
	_assert(MainViewRuntimeScript.has_method("top_content_backpack_horizontal_flags"), "main view runtime exposes top-content backpack horizontal flag policy")
	_assert(MainViewRuntimeScript.has_method("top_content_side_horizontal_flags"), "main view runtime exposes top-content side-panel horizontal flag policy")
	if not MainViewRuntimeScript.has_method("top_content_backpack_horizontal_flags") or not MainViewRuntimeScript.has_method("top_content_side_horizontal_flags"):
		return
	_assert_eq(int(MainViewRuntimeScript.top_content_backpack_horizontal_flags()), int(Control.SIZE_SHRINK_CENTER), "top-content backpack stays fixed-width and centered instead of consuming expand width")
	_assert_eq(int(MainViewRuntimeScript.top_content_side_horizontal_flags()), int(Control.SIZE_EXPAND_FILL), "top-content side panels keep expand-fill behavior so they absorb the freed width")

func test_top_content_backpack_width_tracks_full_row_height() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for top-content backpack height-baseline policy")
	if MainViewRuntimeScript == null:
		return
	_assert(MainViewRuntimeScript.has_method("top_content_backpack_width_for_height"), "main view runtime exposes top-content backpack width-from-height policy")
	if not MainViewRuntimeScript.has_method("top_content_backpack_width_for_height"):
		return
	_assert_close(float(MainViewRuntimeScript.top_content_backpack_width_for_height(548.0)), 638.779695, 0.001, "top-content backpack width follows the trimmed pin silhouette rather than the old padded canvas width")
	_assert_close(float(MainViewRuntimeScript.top_content_backpack_width_for_height(680.0)), 793.388977, 0.001, "larger rows still add only the trimmed pin outsets on both sides of the square grid baseline")

func test_top_content_backpack_width_ignores_available_space_clamp() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	var BackpackPinLayoutPolicyScript = load("res://src/ui/presenters/BackpackPinLayoutPolicy.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for backpack-priority top-content width policy")
	_assert(BackpackPinLayoutPolicyScript != null, "backpack pin layout policy loads for backpack-priority top-content width policy")
	if MainViewRuntimeScript == null or BackpackPinLayoutPolicyScript == null:
		return
	_assert(MainViewRuntimeScript.has_method("top_content_backpack_width_for_height"), "main view runtime exposes the height-derived top-content backpack width policy")
	_assert(MainViewRuntimeScript.has_method("top_content_backpack_ratio_for_height"), "main view runtime exposes the height-derived top-content backpack ratio policy")
	if not MainViewRuntimeScript.has_method("top_content_backpack_width_for_height") or not MainViewRuntimeScript.has_method("top_content_backpack_ratio_for_height"):
		return
	var desired_width := float(MainViewRuntimeScript.top_content_backpack_width_for_height(680.0))
	_assert(not MainViewRuntimeScript.has_method("top_content_backpack_width_for_available"), "main runtime no longer exposes an available-width clamp that can shrink the priority backpack panel first")
	_assert(not MainViewRuntimeScript.has_method("top_content_backpack_ratio_for_size"), "main runtime no longer exposes clamped-width ratio math for the top-content backpack")
	_assert(not BackpackPinLayoutPolicyScript.has_method("top_content_width_for_available"), "shared backpack policy no longer exposes an available-width clamp for top-content backpack sizing")
	_assert(not BackpackPinLayoutPolicyScript.has_method("top_content_ratio_for_size"), "shared backpack policy no longer exposes clamped-width ratio math for top-content backpack sizing")
	_assert_close(desired_width, 793.388977, 0.001, "constrained rows still preserve the intended height-derived backpack width")
	_assert_close(float(MainViewRuntimeScript.top_content_backpack_ratio_for_height(680.0)), desired_width / 680.0, 0.001, "top-content backpack ratio stays tied to the priority height-derived width")

func test_top_content_backpack_height_uses_single_row_source() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for single-source top-content backpack height policy")
	if MainViewRuntimeScript == null:
		return
	_assert(MainViewRuntimeScript.has_method("resolved_top_content_backpack_height"), "main view runtime exposes the resolved top-content backpack height helper")
	if not MainViewRuntimeScript.has_method("resolved_top_content_backpack_height"):
		return
	_assert_eq(
		float(MainViewRuntimeScript.resolved_top_content_backpack_height(548.0, 420.0, 760.0)),
		548.0,
		"reward/backpack layout height follows the shared top-content row height instead of feeding back from the current backpack height"
	)
	_assert_eq(
		float(MainViewRuntimeScript.resolved_top_content_backpack_height(0.0, 420.0, 760.0)),
		420.0,
		"shared top-content backpack height falls back to the row minimum height when the live row has not been laid out yet"
	)

func test_top_content_backpack_width_uses_slot_scaled_pin_overhang() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	var backpack_ui = BackpackUIScript.new()
	_assert(MainViewRuntimeScript != null, "main view runtime loads for slot-scaled pin width policy")
	if MainViewRuntimeScript == null:
		return
	_assert(backpack_ui.has_method("pin_slot_extent_for_grid_extent"), "backpack exposes slot extent helper for pin sizing")
	_assert(backpack_ui.has_method("pin_display_extent_for_slot_extent"), "backpack exposes slot-scaled pin display helper")
	_assert(backpack_ui.has_method("pin_side_outset_for_slot_extent"), "backpack exposes slot-scaled side outset helper")
	_assert(MainViewRuntimeScript.has_method("top_content_backpack_pin_side_outset_for_height"), "main view exposes top-content pin side outset helper")
	if not backpack_ui.has_method("pin_slot_extent_for_grid_extent") or not backpack_ui.has_method("pin_side_outset_for_slot_extent") or not MainViewRuntimeScript.has_method("top_content_backpack_pin_side_outset_for_height"):
		return
	var grid_extent := 548.0
	var slot_extent := float(backpack_ui.call("pin_slot_extent_for_grid_extent", grid_extent))
	var pin_extent := float(backpack_ui.call("pin_display_extent_for_slot_extent", slot_extent))
	var side_outset := float(backpack_ui.call("pin_side_outset_for_slot_extent", slot_extent))
	var main_side_outset := float(MainViewRuntimeScript.top_content_backpack_pin_side_outset_for_height(grid_extent))
	var width := float(MainViewRuntimeScript.top_content_backpack_width_for_height(grid_extent))
	_assert_close(slot_extent, 53.0, 0.001, "548px grid resolves to a 10-column slot extent with 2px separators")
	_assert(pin_extent < 120.0, "pin display extent is slot-scaled rather than 30 percent of the whole grid")
	_assert_close(main_side_outset, side_outset, 0.001, "main view and backpack agree on pin side outset")
	_assert_close(width, grid_extent + side_outset * 2.0, 0.001, "top-content backpack width adds only left and right pin outsets")
	_assert(width < 712.4, "top-content backpack no longer uses the old broad 30 percent full-grid width")

