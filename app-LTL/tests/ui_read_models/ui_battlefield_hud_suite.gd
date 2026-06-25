extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_phase_layout_hides_floating_battlefield_timer()
	test_phase_layout_gives_backpack_more_space_in_combat_and_reward()
	test_phase_layout_hides_backpack_cooldown_visuals_outside_combat()
	test_battlefield_layout_uses_top_left_header_miner_overlay()
	test_cell_view_uses_tile_alpha_for_weakness_readability()
	test_cell_view_uses_active_queue_color_for_tile_alpha_readability()
	test_cell_view_keeps_empty_queue_terrain_tiles_semTransparent()
	test_combat_scene_projects_all_energy_weakness_as_highlighted_tiles()
	test_cell_view_projects_hazard_alpha_by_state()
	test_cell_view_removes_colored_hazard_frame()
	test_cell_view_maps_green_family_to_green_hazard_texture()
	test_cell_view_expands_green_hazard_overlay_and_softens_fill()
	test_obstacle_execution_feedback_flash_and_popup_api_exists()
	test_hazard_model_uses_active_severity_for_live_obstacles()
	test_hazard_model_stays_stable_without_live_obstacles()
	test_battlefield_maps_columns_to_miner_pose_assets()
	test_battlefield_miner_pose_assets_use_trimmed_regions()
	return _result()

func test_phase_layout_hides_floating_battlefield_timer() -> void:
	var model = PhaseLayoutPresenterScript.project({"phase": "combat", "stageIndex": 0, "maxStages": 5, "targetPanel": {"timeLimitTicks": 1200.0, "elapsedTicks": 200.0}}, false)
	_assert_eq(model["combatTimeActive"], true, "combat layout still exposes the countdown as active combat state")
	_assert_eq(model["giantTimerVisible"], false, "combat layout no longer shows the floating battlefield timer above the terrain strip")

func test_phase_layout_gives_backpack_more_space_in_combat_and_reward() -> void:
	var combat = PhaseLayoutPresenterScript.project({"phase": "combat", "stageIndex": 0, "maxStages": 5}, false)
	var reward = PhaseLayoutPresenterScript.project({"phase": "reward_loot", "stageIndex": 0, "maxStages": 5}, false)
	_assert_eq(float(combat.get("leftColumnTopStretchRatio", -1.0)), 0.0, "combat left status column gives up stretch first so the priority backpack panel can grow")
	_assert_eq(float(combat.get("backpackTopStretchRatio", -1.0)), 0.0, "combat backpack container no longer consumes horizontal stretch width")
	_assert_eq(float(combat.get("rightSidebarTopStretchRatio", 0.0)), 1.0, "combat right sidebar absorbs the remaining side budget after the backpack and left rail")
	_assert_eq(float(reward.get("backpackTopStretchRatio", -1.0)), 0.0, "reward layout also keeps the backpack fixed-width instead of stretching its slot")
	_assert(float(combat.get("rightSidebarTopStretchRatio", 0.0)) > 0.0, "combat layout leaves remaining horizontal width to the log sidebar")
	_assert(float(combat.get("leftColumnTopStretchRatio", 0.0)) < float(combat.get("rightSidebarTopStretchRatio", 0.0)), "combat keeps the drill/status side at its readable minimum before trimming the log side")

func test_phase_layout_hides_backpack_cooldown_visuals_outside_combat() -> void:
	var node_select = PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 0, "maxStages": 5}, false)
	var reward = PhaseLayoutPresenterScript.project({"phase": "reward_loot", "stageIndex": 0, "maxStages": 5}, false)
	var combat = PhaseLayoutPresenterScript.project({"phase": "combat", "stageIndex": 0, "maxStages": 5}, false)
	_assert_eq(bool(node_select.get("backpackCooldownVisible", true)), false, "node-select hides cooldown darkness so the starter loadout stays readable")
	_assert_eq(bool(reward.get("backpackCooldownVisible", true)), false, "reward layout hides cooldown darkness while reorganizing loot")
	_assert_eq(bool(combat.get("backpackCooldownVisible", false)), true, "combat keeps cooldown darkness visible")

# ?ㅽ뻾: verify combat feedback presenter converts hit status to screenshake.
func test_battlefield_layout_uses_top_left_header_miner_overlay() -> void:
	var battlefield_ui = BattlefieldUIScript.new()
	_assert(battlefield_ui.has_method("layout_metrics_for_board"), "battlefield ui exposes deterministic terrain layout metrics for regression tests")
	if not battlefield_ui.has_method("layout_metrics_for_board"):
		return
	var metrics: Dictionary = battlefield_ui.call("layout_metrics_for_board", Vector2(1280.0, 220.0))
	var shell_rect: Rect2 = metrics.get("shellRect", Rect2())
	var grid_rect: Rect2 = metrics.get("gridRect", Rect2())
	var header_miner_rect: Rect2 = metrics.get("headerMinerRect", Rect2())
	_assert(abs(header_miner_rect.position.x - 0.0) < 0.1, "header miner now hugs the panel's left edge")
	_assert(abs(header_miner_rect.position.y - 0.0) < 0.1, "header miner now touches the top edge of the battlefield panel")
	_assert(abs(shell_rect.position.x - 20.0) < 0.1, "terrain shell keeps its left margin instead of shifting right to make a miner column")
	_assert(abs(shell_rect.position.y - 8.0) < 0.1, "battlefield shell shifts upward by about 12px so the miner sits closer to the panel ceiling")
	_assert(abs((1280.0 - shell_rect.end.x) - 20.0) < 0.1, "battlefield shell keeps a symmetric right margin while the miner overlays above it")
	_assert(abs((220.0 - shell_rect.end.y) - 8.0) < 0.1, "battlefield shell extends downward by the same amount it moved upward so the tile panel stays vertically balanced")
	_assert(grid_rect.size.y >= 140.0, "battlefield grid gains extra vertical room after the shell expands upward and downward")
	_assert(abs(float(metrics.get("headerMinerWidth", 0.0)) - (1280.0 * 0.1425)) < 0.1, "header miner uses about half of the previous battlefield miner width ratio")

func test_cell_view_uses_tile_alpha_for_weakness_readability() -> void:
	_assert(abs(float(CellViewScript.base_tile_alpha_for(null)) - 0.5) < 0.01, "non-weakness tiles render semi-transparent")
	_assert(abs(float(CellViewScript.base_tile_alpha_for("red")) - 1.0) < 0.01, "weakness tiles render fully opaque")

func test_cell_view_uses_active_queue_color_for_tile_alpha_readability() -> void:
	_assert(abs(float(CellViewScript.base_tile_alpha_for("purple", "purple", "purple")) - 1.0) < 0.01, "queue-matching tiles stay fully opaque")
	_assert(abs(float(CellViewScript.base_tile_alpha_for("red", "red", "purple")) - 0.5) < 0.01, "nonmatching colored tiles fade when another queue color is active")
	_assert(abs(float(CellViewScript.base_tile_alpha_for(null, "blue", "purple")) - 0.5) < 0.01, "nonmatching fallback obstacle tiles also fade against the active queue color")

func test_cell_view_keeps_empty_queue_terrain_tiles_semTransparent() -> void:
	_assert(abs(float(CellViewScript.base_tile_alpha_for("red", false, false)) - 0.5) < 0.01, "empty-queue overload keeps ordinary weakness tiles semi-transparent")
	_assert(abs(float(CellViewScript.base_tile_alpha_for("purple", true, false)) - 0.5) < 0.01, "empty-queue overload also keeps all-energy weakness tiles semi-transparent")

func test_combat_scene_projects_all_energy_weakness_as_highlighted_tiles() -> void:
	var model = CombatSceneModelScript.new()
	var snapshot := {
		"phase": "combat",
		"stageIndex": 0,
		"maxStages": 1,
		"runIndex": 0,
		"runCount": 1,
		"combat": {
			"result": "active",
			"weakness": ["green"],
			"shield": 10.0,
			"health": 10.0,
			"maxShield": 10.0,
			"maxHealth": 10.0,
			"queue": {
				"capacity": 2,
				"loaded": 2,
				"items": [
					{"color": "green", "source_artifact_id": "starter_green_drill", "source_item_type": "drill"},
					{"color": "red", "source_artifact_id": "starter_red_drill", "source_item_type": "drill"}
				]
			},
			"pin": {},
			"repair": {},
			"hazard": {},
			"aim": {"cellId": "r0c0", "canFire": true},
			"battlefield": {
				"rows": 1,
				"columns": 2,
				"weaknessMarkers": [
					{"cellId": "r0c0", "color": "green"},
					{"cellId": "r0c1", "color": "red", "allEnergyWeakness": true}
				],
				"terrainDebuffs": [],
				"terrainBuffs": []
			}
		}
	}
	var scene: Dictionary = model.create(snapshot, {"viewportWidth": 400, "viewportHeight": 200})
	_assert_eq(scene["terrain"]["cells"][0].get("queueMatch", false), true, "baseline matching tile stays highlighted")
	_assert_eq(scene["terrain"]["cells"][1].get("queueMatch", false), true, "all-energy weakness tiles stay highlighted even when their color differs from the active queue")
	_assert_eq(scene["terrain"]["cells"][1].get("weakness", ""), "red", "all-energy weakness projection keeps the cell's original color")

func test_cell_view_projects_hazard_alpha_by_state() -> void:
	_assert(abs(float(CellViewScript.hazard_alpha_for({"state": "active"})) - 1.0) < 0.01, "active hazards render fully opaque")
	_assert(float(CellViewScript.hazard_alpha_for({"state": "afterglow_clear", "afterglowTicksRemaining": 3, "afterglowTicks": 12})) < 0.3, "afterglow hazards render as faint residue")
	_assert_eq(float(CellViewScript.hazard_alpha_for({})), 0.0, "missing hazard state renders with no hazard overlay alpha")

func test_cell_view_removes_colored_hazard_frame() -> void:
	_assert_eq(float(CellViewScript.hazard_frame_margin_for("red", "active")), 0.0, "active hazards no longer reserve a colored outer frame margin")
	_assert_eq(float(CellViewScript.hazard_frame_margin_for("green", "active")), 0.0, "green hazards also remove the old outer frame margin")
	_assert_eq(float(CellViewScript.hazard_frame_margin_for("purple", "afterglow_clear")), 0.0, "afterglow hazards keep no colored outline margin")

func test_cell_view_maps_green_family_to_green_hazard_texture() -> void:
	var green_hazard_texture = CellViewScript._hazard_texture_for_color("green")
	_assert(green_hazard_texture != null, "green hazard family resolves to a dedicated texture")
	_assert_eq(green_hazard_texture, CellViewScript.GREEN_HAZARD_TEXTURE, "green hazards use green_tile_hazard.png instead of a shared fallback")

func test_cell_view_expands_green_hazard_overlay_and_softens_fill() -> void:
	_assert(float(CellViewScript.hazard_texture_margin_for("green", "active")) > float(CellViewScript.hazard_texture_margin_for("red", "active")), "green hazards expand farther so the vine frame stays readable at combat scale")
	_assert(float(CellViewScript.active_hazard_fill_alpha_for("green", 0.8)) < float(CellViewScript.active_hazard_fill_alpha_for("red", 0.8)), "green hazards keep a lighter active fill so the hazard artwork is not washed out")

func test_obstacle_execution_feedback_flash_and_popup_api_exists() -> void:
	var battlefield_vfx = BattlefieldVFXScript.new()
	var battlefield_ui = BattlefieldUIScript.new()
	var vfx_manager = VFXManagerScript.new()
	_assert(battlefield_vfx.has_method("flash_color_for_family"), "battlefield VFX exposes obstacle execution flash colors")
	_assert(battlefield_vfx.has_method("trigger_obstacle_flash"), "battlefield VFX exposes a short obstacle execution flash")
	_assert(battlefield_ui.has_method("trigger_obstacle_flash"), "battlefield UI forwards obstacle execution flashes to the overlay")
	_assert(vfx_manager.has_method("spawn_obstacle_feedback"), "VFX manager exposes obstacle feedback popup spawning")
	if battlefield_vfx.has_method("flash_color_for_family"):
		var red_flash: Color = battlefield_vfx.call("flash_color_for_family", "red")
		var blue_flash: Color = battlefield_vfx.call("flash_color_for_family", "blue")
		_assert(red_flash.g > 0.35 and red_flash.b < 0.35, "red obstacle execution uses an orange/yellow flash instead of another red warning")
		_assert(blue_flash.b > blue_flash.r, "blue obstacle execution flash remains visibly blue")
	battlefield_vfx.free()

func test_hazard_model_uses_active_severity_for_live_obstacles() -> void:
	var model = HazardModelScript.new()
	model.update_state(10.0, 0, "active", 10.0, [{"family": "green", "state": "active"}], 0.0)
	_assert_eq(model.severity, "active", "live hazards no longer project a warning severity tier")
	_assert_eq(model.label, "green", "live hazard label keeps the leading family")

func test_hazard_model_stays_stable_without_live_obstacles() -> void:
	var model = HazardModelScript.new()
	model.update_state(1.0, 2, "active", 10.0, [], 0.0)
	_assert_eq(model.severity, "stable", "hazard severity stays stable when no live obstacles exist")
	_assert_eq(model.active, false, "hazard model deactivates when the battlefield has no live hazards")

func test_battlefield_maps_columns_to_miner_pose_assets() -> void:
	var battlefield_ui = BattlefieldUIScript.new()
	_assert(battlefield_ui.has_method("miner_pose_asset_path_for_column"), "battlefield ui exposes a deterministic miner pose mapper for click-column reactions")
	_assert(battlefield_ui.has_method("miner_pose_asset_path_for_cell_id"), "battlefield ui exposes a cell-id miner pose mapper for combat click routing")
	if not battlefield_ui.has_method("miner_pose_asset_path_for_column") or not battlefield_ui.has_method("miner_pose_asset_path_for_cell_id"):
		return
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_column", 0)), "res://resources/UI/miner/miner_90.png", "leftmost column uses the 90-degree miner pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_column", 1)), "res://resources/UI/miner/miner_90.png", "second column still uses the 90-degree miner pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_column", 2)), "res://resources/UI/miner/miner_60.png", "third column switches to the 60-degree miner pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_column", 5)), "res://resources/UI/miner/miner_60.png", "sixth column keeps the 60-degree miner pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_column", 6)), "res://resources/UI/miner/miner_45.png", "seventh column switches back to the shallow 45-degree miner pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_column", 9)), "res://resources/UI/miner/miner_45.png", "rightmost column keeps the 45-degree miner pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_cell_id", "r0c1")), "res://resources/UI/miner/miner_90.png", "cell ids in the left two columns map to the 90-degree pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_cell_id", "r1c4")), "res://resources/UI/miner/miner_60.png", "middle-band cell ids map to the 60-degree pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_cell_id", "r2c8")), "res://resources/UI/miner/miner_45.png", "right-band cell ids map to the 45-degree pose")
	_assert_eq(String(battlefield_ui.call("miner_pose_asset_path_for_cell_id", "bad-id")), "res://resources/UI/miner/miner_45.png", "invalid cell ids fall back to the default 45-degree pose")

func test_battlefield_miner_pose_assets_use_trimmed_regions() -> void:
	var battlefield_ui = BattlefieldUIScript.new()
	_assert(battlefield_ui.has_method("_texture_for_miner_pose_path"), "battlefield ui keeps the pose-texture resolver available for trimmed miner regions")
	if not battlefield_ui.has_method("_texture_for_miner_pose_path"):
		return
	var expected_regions := {
		"res://resources/UI/miner/miner_45.png": Rect2(91, 201, 1311, 612),
		"res://resources/UI/miner/miner_60.png": Rect2(298, 80, 709, 1024),
		"res://resources/UI/miner/miner_90.png": Rect2(510, 59, 234, 1140)
	}
	for asset_path in expected_regions.keys():
		var atlas := battlefield_ui.call("_texture_for_miner_pose_path", asset_path) as AtlasTexture
		_assert(atlas != null, "battlefield miner pose %s uses a trimmed atlas texture so pose padding cannot push the visible drill away from the panel edge" % asset_path)
		if atlas != null:
			_assert_eq(atlas.region, expected_regions[asset_path], "battlefield miner pose %s trims to the measured visible bounds before layout" % asset_path)

