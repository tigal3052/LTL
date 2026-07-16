extends "res://tests/support/UiReadModelTestSuite.gd"
class FakeDrillTextureOwner:
	extends RefCounted
	var drill_texture_cache: Dictionary = {}
func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_main_view_defeat_page_model_uses_selected_leviathan_art()
	test_main_view_defeat_page_model_exposes_wireframe_fields()
	test_defeat_page_scene_uses_dedicated_wireframe_layout()
	test_main_view_presentation_runtime_helper_exists()
	test_main_scene_exposes_purple_status_row()
	test_battlefield_lane_overlay_keeps_shell_visible_through_transparent_tiles()
	test_combat_feedback_projects_screenshake()
	test_tooltip_position_clamps_to_viewport()
	test_backpack_artifact_edges_omit_internal_borders()
	test_backpack_drill_texture_paths_and_drop_cue_styles()
	test_backpack_beacon_texture_paths_and_render_lookup()
	test_backpack_drill_texture_prefers_artifact_visual_id_after_grade_upgrade()
	test_backpack_drill_display_texture_keeps_centered_square_region()
	test_backpack_item_image_placement_helper_centers_texture_rect_on_footprint()
	test_backpack_image_rect_helper_uses_transformed_slot_corners()
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
	# 실행: fail_r4 목업(hanging parchment board) 적용으로 노드 트리가 BoardRig/BoardTilt/BoardShell
	# 구도로 재구성됨(APPLY_PLAN.md 3절). 아래 경로는 신규 트리 기준이다.
	_assert(defeat_page.get_node_or_null("BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Head") != null, "defeat page exposes the hanging board head section")
	_assert(defeat_page.get_node_or_null("BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Body/PolaroidSlot") != null, "defeat page exposes the polaroid failure-scene frame")
	_assert(defeat_page.get_node_or_null("BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Body/LedgerColumn/CauseRow/FailureCauseLabel") != null, "defeat page exposes the dedicated failure cause label")
	_assert(defeat_page.get_node_or_null("BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/Body/LedgerColumn/TipRow/FailureTipLabel") != null, "defeat page exposes the dedicated retry hint label")
	_assert(defeat_page.get_node_or_null("BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/CtaColumn/RetryButton") != null, "defeat page exposes the same-seed retry CTA inside the board CTA column")
	_assert(defeat_page.get_node_or_null("BoardRig/BoardTilt/BoardShell/ShellMargin/ShellVBox/CtaColumn/NewSeedRetryButton") != null, "defeat page exposes the new-seed retry CTA inside the board CTA column")
	_assert(defeat_page.get_node_or_null("BoardRig/BoardTilt/Pin") != null, "defeat page exposes the board pin sharing the board's tilt coordinate space")
	defeat_page.queue_free()
func test_main_view_presentation_runtime_helper_exists() -> void:
	var helper_path := "res://src/ui/main_view/MainViewPresentationRuntime.gd"
	var HelperScript = load(helper_path)
	_assert(HelperScript != null, "MainView presentation runtime helper exists")
	if HelperScript != null:
		_assert(HelperScript.has_method("install_character_presentation"), "MainView presentation helper owns character presentation installation")
		_assert(HelperScript.has_method("layout_character_presentation"), "MainView presentation helper owns character presentation layout")
		_assert(HelperScript.has_method("install_reward_backdrop"), "MainView presentation helper owns reward backdrop installation")
		_assert(HelperScript.has_method("render_failure_backdrop"), "MainView presentation helper owns failure backdrop rendering")
		_assert(HelperScript.has_method("render_character_status"), "MainView presentation helper owns character status rendering")
		_assert(_source_line_count(helper_path) <= 500, "MainView presentation helper stays within the 500-line cap")
	_assert(_source_line_count("res://src/ui/MainViewRuntime.gd") <= 2200, "MainViewRuntime delegates presentation runtime after the second split checkpoint")
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
func test_tooltip_position_clamps_to_viewport() -> void:
	var pos = ArtifactTooltipUIScript.clamped_position(Vector2(790, 590), Vector2(240, 120), Vector2(800, 600), Vector2(15, 15), 8.0)
	_assert_eq(pos, Vector2(552, 472), "tooltip clamps bottom-right overflow")
	var top_left = ArtifactTooltipUIScript.clamped_position(Vector2(-20, -10), Vector2(240, 120), Vector2(800, 600), Vector2(15, 15), 8.0)
	_assert_eq(top_left, Vector2(8, 8), "tooltip clamps top-left overflow")
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
func test_backpack_drill_texture_paths_and_drop_cue_styles() -> void:
	_assert_eq(BackpackGridFactoryScript.drill_texture_path("red", "common"), "res://resources/items/drill/red_drill_common.png", "common drill texture path points at item PNG")
	_assert_eq(BackpackGridFactoryScript.drill_texture_path("blue", "basic"), "res://resources/items/drill/blue_drill_common.png", "basic starter drill reuses common drill art")
	_assert_eq(BackpackGridFactoryScript.drill_texture_path("green", "rare"), "res://resources/items/drill/green_drill_rare.png", "rare drill texture path points at item PNG")
	_assert_eq(BackpackGridFactoryScript.drill_texture_path("purple", "epic"), "res://resources/items/drill/purple_drill_epic.png", "epic drills use the newly linked item PNG when available")
	var valid_style: StyleBoxFlat = BackpackGridFactoryScript.drop_cue_style(true, {"left": true, "top": true, "right": true, "bottom": true})
	var invalid_style: StyleBoxFlat = BackpackGridFactoryScript.drop_cue_style(false, {"left": true, "top": true, "right": true, "bottom": true})
	_assert(valid_style.bg_color.g > valid_style.bg_color.r, "valid drop cue uses a green fill")
	_assert(invalid_style.bg_color.r > invalid_style.bg_color.g, "invalid drop cue uses a red fill")
func test_backpack_beacon_texture_paths_and_render_lookup() -> void:
	var grid_factory = BackpackGridFactoryScript.new()
	_assert(grid_factory.has_method("beacon_texture_path"), "backpack grid factory exposes beacon texture path lookup")
	_assert(grid_factory.has_method("beacon_texture_path_for_visual_id"), "backpack grid factory resolves beacon visual ids")
	if grid_factory.has_method("beacon_texture_path"):
		_assert_eq(grid_factory.call("beacon_texture_path", "red", "basic"), "res://resources/items/becon/red_becon_start.png", "basic starter beacon uses the supplied start art")
		_assert_eq(grid_factory.call("beacon_texture_path", "blue", "common"), "res://resources/items/becon/blue_becon_common.png", "common beacon path points at item PNG")
		_assert_eq(grid_factory.call("beacon_texture_path", "green", "epic"), "res://resources/items/becon/green_becon_epic.png", "epic green beacon path points at item PNG")
	if grid_factory.has_method("beacon_texture_path_for_visual_id"):
		_assert_eq(grid_factory.call("beacon_texture_path_for_visual_id", "beacon_blue_rare"), "res://resources/items/becon/blue_becon_rare.png", "beacon visual id maps to the becon file naming convention")
	var RendererScript = load("res://src/ui/backpack/BackpackArtifactRenderer.gd")
	_assert(RendererScript != null, "backpack artifact renderer loads for beacon texture coverage")
	if RendererScript == null:
		return
	_assert(RendererScript.has_method("item_texture_for_artifact"), "backpack artifact renderer exposes generic item texture lookup")
	if not RendererScript.has_method("item_texture_for_artifact"):
		return
	var owner := FakeDrillTextureOwner.new()
	var beacon_artifact = ArtifactScript.new({
		"id": "visual_blue_beacon",
		"name": "Azure Beacon",
		"shape": [[1]],
		"energyType": "blue",
		"grade": "common",
		"item_type": "beacon",
		"visualId": "beacon_blue_common"
	})
	var texture = RendererScript.call("item_texture_for_artifact", owner, beacon_artifact)
	_assert(texture is Texture2D, "backpack renderer loads beacon item art as a texture")
func test_backpack_drill_texture_prefers_artifact_visual_id_after_grade_upgrade() -> void:
	var RendererScript = load("res://src/ui/backpack/BackpackArtifactRenderer.gd")
	_assert(RendererScript != null, "backpack artifact renderer loads for visual-id texture coverage")
	if RendererScript == null:
		return
	_assert(RendererScript.has_method("drill_texture_for_artifact"), "backpack artifact renderer exposes artifact texture lookup")
	if not RendererScript.has_method("drill_texture_for_artifact"):
		return
	var owner := FakeDrillTextureOwner.new()
	var fused_artifact = ArtifactScript.new({
		"id": "visual_epic_drill",
		"name": "Epic Crimson Ember Bit +",
		"shape": [[1]],
		"energyType": "red",
		"grade": "epic",
		"item_type": "drill",
		"visualId": "drill_red_common"
	})
	var texture = RendererScript.call("drill_texture_for_artifact", owner, fused_artifact)
	_assert(texture is Texture2D, "grade-upgraded drill keeps using the reward visual id image instead of falling back to a square")
func test_backpack_drill_display_texture_keeps_centered_square_region() -> void:
	var RendererScript = load("res://src/ui/backpack/BackpackArtifactRenderer.gd")
	var ThemeScript = load("res://src/ui/theme/LTLTheme.gd")
	_assert(RendererScript != null, "backpack artifact renderer loads for centered drill display texture coverage")
	_assert(ThemeScript != null, "theme texture loader loads for centered drill display texture coverage")
	if RendererScript == null or ThemeScript == null:
		return
	_assert(RendererScript.has_method("drill_display_texture"), "backpack artifact renderer exposes one display texture helper for placed and dragged drill images")
	if not RendererScript.has_method("drill_display_texture"):
		return
	var raw_texture: Texture2D = ThemeScript.art_texture("res://resources/items/drill/purple_drill_common.png")
	_assert(raw_texture != null, "purple common drill raw texture loads for centered display-region test")
	if raw_texture == null:
		return
	var display_texture = RendererScript.call("drill_display_texture", raw_texture)
	_assert(display_texture is AtlasTexture, "drill display texture uses an atlas region so transparent source padding cannot shrink the item art")
	if not display_texture is AtlasTexture:
		return
	var atlas := display_texture as AtlasTexture
	_assert_close(atlas.region.size.x, atlas.region.size.y, 0.01, "drill display atlas stays square so square grid slots cannot crop it off-axis")
	_assert(atlas.region.size.x < float(raw_texture.get_width()) * 0.9, "drill display atlas trims transparent padding while preserving source-center alignment")
	_assert(atlas.region.size.x > float(raw_texture.get_width()) * 0.4, "drill display atlas keeps enough source area for the drill head and handle")
	_assert(atlas.region.get_center().distance_to(Vector2(raw_texture.get_width(), raw_texture.get_height()) * 0.5) <= 1.0, "trimmed drill atlas remains centered on the original source texture center")
func test_backpack_item_image_placement_helper_centers_texture_rect_on_footprint() -> void:
	var RendererScript = load("res://src/ui/backpack/BackpackArtifactRenderer.gd")
	_assert(RendererScript != null, "backpack artifact renderer loads for shared item image placement coverage")
	if RendererScript == null:
		return
	_assert(RendererScript.has_method("apply_item_image_placement"), "backpack artifact renderer exposes one placement helper for idle and drag item images")
	if not RendererScript.has_method("apply_item_image_placement"):
		return
	var image := TextureRect.new()
	var footprint := Rect2(Vector2(120.0, 96.0), Vector2(48.0, 48.0))
	RendererScript.call("apply_item_image_placement", image, null, footprint)
	_assert_eq(image.position, footprint.position, "shared image placement uses the footprint top-left in the active coordinate space")
	_assert_eq(image.size, footprint.size, "shared image placement uses the full footprint size")
	_assert_eq(image.position + image.size * 0.5, footprint.position + footprint.size * 0.5, "shared image placement keeps the item centered on the grid footprint")
	_assert_eq(image.expand_mode, TextureRect.EXPAND_IGNORE_SIZE, "shared image placement expands textures to the assigned footprint")
	_assert_eq(image.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED, "shared image placement fills the footprint consistently for placed and dragged item images")
	image.free()
func test_backpack_image_rect_helper_uses_transformed_slot_corners() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_method("control_rect_in_layer_space"), "backpack exposes transformed rect helper so docked reward backpacks can align image overlays")
	if not backpack_ui.has_method("control_rect_in_layer_space"):
		return
	var slot_transform := Transform2D.IDENTITY.scaled(Vector2(0.5, 0.75))
	slot_transform.origin = Vector2(100.0, 50.0)
	var layer_transform := Transform2D.IDENTITY
	layer_transform.origin = Vector2(20.0, 10.0)
	var rect: Rect2 = backpack_ui.call("control_rect_in_layer_space", slot_transform, layer_transform, Vector2(80.0, 40.0))
	_assert_close(rect.position.x, 80.0, 0.01, "transformed slot rect keeps scaled left edge in layer space")
	_assert_close(rect.position.y, 40.0, 0.01, "transformed slot rect keeps scaled top edge in layer space")
	_assert_close(rect.size.x, 40.0, 0.01, "transformed slot rect uses scaled width instead of raw slot size")
	_assert_close(rect.size.y, 30.0, 0.01, "transformed slot rect uses scaled height instead of raw slot size")
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
func test_backpack_cooldown_charge_ratio_changes_with_current_cooldown() -> void:
	var early := BackpackGridFactoryScript.cooldown_charge_ratio(75, 100, 0)
	var late := BackpackGridFactoryScript.cooldown_charge_ratio(25, 100, 0)
	_assert(early < late, "cooldown charge ratio increases as cooldown decreases")
	_assert_eq(early, 0.25, "early cooldown charge ratio")
	_assert_eq(late, 0.75, "late cooldown charge ratio")
func test_backpack_cooldown_charge_ratio_smoothly_interpolates() -> void:
	var eased := BackpackGridFactoryScript.smooth_charge_ratio(0.2, 0.8, 0.1, 3.0)
	_assert(eased > 0.2, "smooth cooldown ratio moves upward")
	_assert(eased < 0.8, "smooth cooldown ratio does not snap to target")
func test_backpack_cooldown_mask_ratio_decreases_with_frame_time() -> void:
	var remaining := BackpackGridFactoryScript.cooldown_remaining_ratio(75, 100, 0)
	var advanced := BackpackGridFactoryScript.advance_visual_cooldown(75.0, 0.25, 20.0)
	_assert_eq(remaining, 0.75, "cooldown remaining mask ratio")
	_assert_eq(advanced, 70.0, "visual cooldown advances by frame delta")
	_assert(BackpackGridFactoryScript.cooldown_remaining_ratio(int(advanced), 100, 0) < remaining, "mask shrinks as frame time advances")
func test_backpack_cooldown_display_does_not_backtrack_on_snapshot_refresh() -> void:
	var stable := BackpackGridFactoryScript.stable_cooldown_display(45.0, 60.0, 80)
	_assert_eq(stable, 45.0, "stale backend refresh does not increase displayed cooldown")
	var reduced := BackpackGridFactoryScript.stable_cooldown_display(45.0, 30.0, 80)
	_assert_eq(reduced, 30.0, "backend cooldown reductions still apply")
	var reset := BackpackGridFactoryScript.stable_cooldown_display(0.0, 80.0, 80)
	_assert_eq(reset, 80.0, "freshly fired drill cooldown can reset to full")
func _source_line_count(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 999999
	var line_count := 0
	while not file.eof_reached():
		file.get_line()
		line_count += 1
	file.close()
	return line_count
