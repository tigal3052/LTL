extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_main_view_defeat_page_model_uses_selected_leviathan_art()
	test_main_view_defeat_page_model_exposes_wireframe_fields()
	test_defeat_page_scene_uses_dedicated_wireframe_layout()
	test_main_scene_exposes_purple_status_row()
	test_battlefield_lane_overlay_keeps_shell_visible_through_transparent_tiles()
	test_combat_feedback_projects_screenshake()
	test_tooltip_position_clamps_to_viewport()
	test_backpack_artifact_edges_omit_internal_borders()
	test_backpack_drag_ghost_matches_grid_visual_scale_and_fill()
	test_backpack_drag_ghost_anchors_to_cursor_top_left()
	test_backpack_cooldown_charge_ratio_changes_with_current_cooldown()
	test_backpack_cooldown_charge_ratio_smoothly_interpolates()
	test_backpack_cooldown_mask_ratio_decreases_with_frame_time()
	test_backpack_cooldown_display_does_not_backtrack_on_snapshot_refresh()
	return _result()

func test_main_view_defeat_page_model_uses_selected_leviathan_art() -> void:
	var view = MainViewRuntimeScript.new()
	var defeat_model: Dictionary = view.call("_page_scene_model", "defeat", {
		"selectedLeviathan": {"artPath": "res://resources/Leviathan/Leviathan_lizard.png"},
		"failureReason": "The contract broke."
	})
	_assert_eq(
		str(defeat_model.get("pageHeroPath", "")),
		"res://resources/Leviathan/Leviathan_lizard.png",
		"defeat page model uses the selected leviathan art path instead of a fixed fallback"
	)

func test_main_view_defeat_page_model_exposes_wireframe_fields() -> void:
	TextCatalogScript.set_locale("ko")
	var view = MainViewRuntimeScript.new()
	var defeat_model: Dictionary = view.call("_page_scene_model", "defeat", {
		"phase": "run_complete",
		"failed": true,
		"runIndex": 2,
		"lastNodeLabel": "Storm Wyvern",
		"stageIndex": 2,
		"maxStages": 4,
		"selectedLeviathan": {
			"name": "Ossuary Tortoise",
			"artPath": "res://resources/Leviathan/Leviathan_lizard.png"
		},
		"selectedCharacter": {"portraitPath": "res://resources/charactor/charactor1.png"}
	})
	_assert_eq(str(defeat_model.get("pageTitle", "")), TextCatalogScript.t("failure.run_failed.title", [], "ko"), "defeat page model keeps the wireframe headline")
	_assert_eq(str(defeat_model.get("pageSubtitle", "")), "", "defeat page model removes the explanatory subtitle copy under the headline")
	_assert_eq(str(defeat_model.get("pageBoardTitle", "")), "", "defeat page model removes the board header title copy")
	_assert_eq(str(defeat_model.get("pageBoardHint", "")), "", "defeat page model removes the board header hint copy")
	_assert_eq(str(defeat_model.get("pageCause", "")), TextCatalogScript.t("failure.run_failed.cause", ["Ossuary Tortoise", 3, "Storm Wyvern"], "ko"), "defeat page model formats the failure cause from leviathan name, run number, and stage node name")
	_assert(str(defeat_model.get("pageTip", "")) != "", "defeat page model exposes a dedicated retry hint line for the board footer")
	_assert_eq(str(defeat_model.get("pageButtonText", "")), TextCatalogScript.t("action.retry", [], "ko"), "defeat page model uses the central retry CTA copy from the wireframe")
	_assert_eq(str(defeat_model.get("pageCharacterArtPath", "")), "res://resources/charactor/charactor1.png", "defeat page model projects the selected character art for the hero frame")
	_assert_eq(str(defeat_model.get("pageStageBackdropPath", "")), "res://resources/charactor/background.png", "defeat page model projects the dedicated character-stage backdrop for the hero frame")

func test_defeat_page_scene_uses_dedicated_wireframe_layout() -> void:
	var defeat_scene: PackedScene = load("res://src/scenes/pages/DefeatPage.tscn")
	_assert(defeat_scene != null, "defeat page scene loads for dedicated wireframe layout coverage")
	if defeat_scene == null:
		return
	var defeat_page = defeat_scene.instantiate() as Control
	_assert(defeat_page != null, "defeat page instantiates for dedicated wireframe layout coverage")
	if defeat_page == null:
		return
	_assert_eq(str(defeat_page.get("default_subtitle")), "", "defeat page no longer keeps a fallback explanatory subtitle")
	_assert_eq(str(defeat_page.get("default_board_title")), "", "defeat page no longer keeps a fallback board title")
	_assert_eq(str(defeat_page.get("default_board_hint")), "", "defeat page no longer keeps a fallback board hint")
	_assert(defeat_page.get_node_or_null("Margin/VStack/HeroSection") != null, "defeat page exposes the wireframe hero section")
	_assert(defeat_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardHead") != null, "defeat page exposes the board header")
	_assert(defeat_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/HeroFrame") != null, "defeat page exposes the character hero frame")
	_assert(defeat_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FailureCauseLabel") != null, "defeat page exposes the dedicated failure cause label")
	_assert(defeat_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/FailureTipLabel") != null, "defeat page exposes the dedicated retry hint label")
	_assert(defeat_page.get_node_or_null("Margin/VStack/BoardShell/ShellMargin/ShellVBox/BoardBody/RetryButton") != null, "defeat page exposes the centered retry CTA inside the board body")
	defeat_page.queue_free()

func test_main_scene_exposes_purple_status_row() -> void:
	var GameplayTopContentScene = load("res://src/scenes/pages/shells/GameplayTopContent.tscn")
	_assert(GameplayTopContentScene != null, "gameplay top-content shell scene loads for purple status row contract")
	if GameplayTopContentScene == null:
		return
	var gameplay_top_content = GameplayTopContentScene.instantiate()
	_assert(gameplay_top_content != null, "gameplay top-content shell scene instantiates for purple status row contract")
	if gameplay_top_content == null:
		return
	var purple_row = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/StatusFooterSpacer/PurpleStatusRow") as HBoxContainer
	_assert(purple_row != null, "status panel now exposes the purple status row inside the footer spacer lane")
	_assert(gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/PurpleStatusRow") == null, "purple status row no longer sits in the main VBox flow where it could grow combat layout height")
	var purple_value = gameplay_top_content.get_node_or_null("LeftColumn/StatusPanel/Margin/StatusBox/OpsShell/OpsMargin/OpsBox/StatusFooterSpacer/PurpleStatusRow/PurpleStatusValue") as Label
	_assert(purple_value != null, "purple status row exposes a value label for reduction and stack text")
	gameplay_top_content.free()

func test_battlefield_lane_overlay_keeps_shell_visible_through_transparent_tiles() -> void:
	var battlefield_ui = BattlefieldUIScript.new()
	_assert(battlefield_ui.has_method("lane_overlay_color"), "battlefield ui exposes the terrain lane overlay color for transparency regression coverage")
	if not battlefield_ui.has_method("lane_overlay_color"):
		return
	var lane_color: Color = battlefield_ui.call("lane_overlay_color")
	_assert(lane_color.a <= 0.25, "terrain lane overlay stays faint enough that transparent tile edges reveal the stone shell instead of reading as black backing")

func test_combat_feedback_projects_screenshake() -> void:
	var match_feedback = CombatFeedbackPresenterScript.project_screenshake("match")
	var mismatch_feedback = CombatFeedbackPresenterScript.project_screenshake("mismatch")
	var empty_feedback = CombatFeedbackPresenterScript.project_screenshake("empty_queue")
	_assert_eq(match_feedback["duration"], 0.18, "match shake duration")
	_assert_eq(match_feedback["magnitude"], 7.0, "match shake magnitude")
	_assert_eq(mismatch_feedback["duration"], 0.12, "mismatch shake duration")
	_assert_eq(mismatch_feedback["magnitude"], 3.0, "mismatch shake magnitude")
	_assert_eq(empty_feedback["duration"], 0.08, "empty shake duration")
	_assert_eq(empty_feedback["magnitude"], 1.0, "empty shake magnitude")

# ?ㅽ뻾: verify floating tooltip stays within the visible viewport.
func test_tooltip_position_clamps_to_viewport() -> void:
	var pos = ArtifactTooltipUIScript.clamped_position(Vector2(790, 590), Vector2(240, 120), Vector2(800, 600), Vector2(15, 15), 8.0)
	_assert_eq(pos, Vector2(552, 472), "tooltip clamps bottom-right overflow")
	var top_left = ArtifactTooltipUIScript.clamped_position(Vector2(-20, -10), Vector2(240, 120), Vector2(800, 600), Vector2(15, 15), 8.0)
	_assert_eq(top_left, Vector2(8, 8), "tooltip clamps top-left overflow")

# ?ㅽ뻾: verify multi-cell artifacts only draw black borders on the outer perimeter.
func test_backpack_artifact_edges_omit_internal_borders() -> void:
	var shape := [[1, 1], [1, 0]]
	var top_left_edges: Dictionary = BackpackGridFactoryScript.artifact_edge_mask(shape, 0, 0)
	_assert_eq(top_left_edges, {"left": true, "top": true, "right": false, "bottom": false}, "top-left L artifact cell has only outer borders")
	var top_right_edges: Dictionary = BackpackGridFactoryScript.artifact_edge_mask(shape, 0, 1)
	_assert_eq(top_right_edges, {"left": false, "top": true, "right": true, "bottom": true}, "top-right L artifact cell hides shared left border")
	var style := BackpackGridFactoryScript.artifact_style("red", 0.75, top_left_edges)
	_assert_eq(style.border_width_left, 1, "outer left border is visible")
	_assert_eq(style.border_width_top, 1, "outer top border is visible")
	_assert_eq(style.border_width_right, 0, "internal right border is hidden")
	_assert_eq(style.border_width_bottom, 0, "internal bottom border is hidden")

# ?ㅽ뻾: verify a picked-up backpack item keeps the same slot-sized visual language instead of shrinking into a different ghost tile.
func test_backpack_drag_ghost_matches_grid_visual_scale_and_fill() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("ghost_cell_size_for_slot"), "backpack ui exposes a ghost cell sizing helper tied to grid slot size")
	_assert(backpack_ui.has_method("artifact_fill_alpha"), "backpack ui exposes one artifact fill alpha shared by grid and drag ghost")
	if not backpack_ui.has_method("ghost_cell_size_for_slot") or not backpack_ui.has_method("artifact_fill_alpha"):
		return
	var slot_size := Vector2(46.0, 46.0)
	_assert_eq(backpack_ui.call("ghost_cell_size_for_slot", slot_size), slot_size, "selected backpack items keep the same slot-sized footprint when rendered as a ghost")
	_assert_eq(float(backpack_ui.call("artifact_fill_alpha")), 0.32, "selected backpack items keep the same fill alpha as the in-grid artifact overlay")

func test_backpack_drag_ghost_anchors_to_cursor_top_left() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("ghost_global_position_for_cursor"), "backpack ui exposes a drag-ghost cursor anchor helper")
	if not backpack_ui.has_method("ghost_global_position_for_cursor"):
		return
	var cursor_pos := Vector2(320.0, 180.0)
	var slot_size := Vector2(46.0, 46.0)
	var shape := [[1, 1], [1, 1]]
	_assert_eq(backpack_ui.call("ghost_global_position_for_cursor", cursor_pos, shape, slot_size), cursor_pos, "drag ghost keeps its top-left corner on the cursor so release aligns with top-left backpack placement")

# ?ㅽ뻾: verify cooldown charge ratio changes as the artifact cooldown ticks down.
func test_backpack_cooldown_charge_ratio_changes_with_current_cooldown() -> void:
	var early := BackpackGridFactoryScript.cooldown_charge_ratio(75, 100, 0)
	var late := BackpackGridFactoryScript.cooldown_charge_ratio(25, 100, 0)
	_assert(early < late, "cooldown charge ratio increases as cooldown decreases")
	_assert_eq(early, 0.25, "early cooldown charge ratio")
	_assert_eq(late, 0.75, "late cooldown charge ratio")

# ?ㅽ뻾: verify the UI helper eases cooldown fill instead of snapping to the target.
func test_backpack_cooldown_charge_ratio_smoothly_interpolates() -> void:
	var eased := BackpackGridFactoryScript.smooth_charge_ratio(0.2, 0.8, 0.1, 3.0)
	_assert(eased > 0.2, "smooth cooldown ratio moves upward")
	_assert(eased < 0.8, "smooth cooldown ratio does not snap to target")

# ??쎈뻬: verify the visible cooldown mask drains continuously from frame time.
func test_backpack_cooldown_mask_ratio_decreases_with_frame_time() -> void:
	var remaining := BackpackGridFactoryScript.cooldown_remaining_ratio(75, 100, 0)
	var advanced := BackpackGridFactoryScript.advance_visual_cooldown(75.0, 0.25, 20.0)
	_assert_eq(remaining, 0.75, "cooldown remaining mask ratio")
	_assert_eq(advanced, 70.0, "visual cooldown advances by frame delta")
	_assert(BackpackGridFactoryScript.cooldown_remaining_ratio(int(advanced), 100, 0) < remaining, "mask shrinks as frame time advances")

# ?ㅽ뻾: verify terrain marker movement cadence leaves more room after player target selection.
# ?ㅽ뻾: verify model refreshes cannot make an active cooldown mask grow again.
func test_backpack_cooldown_display_does_not_backtrack_on_snapshot_refresh() -> void:
	var stable := BackpackGridFactoryScript.stable_cooldown_display(45.0, 60.0, 80)
	_assert_eq(stable, 45.0, "stale backend refresh does not increase displayed cooldown")
	var reduced := BackpackGridFactoryScript.stable_cooldown_display(45.0, 30.0, 80)
	_assert_eq(reduced, 30.0, "backend cooldown reductions still apply")
	var reset := BackpackGridFactoryScript.stable_cooldown_display(0.0, 80.0, 80)
	_assert_eq(reset, 80.0, "freshly fired drill cooldown can reset to full")

