extends "res://tests/support/UiReadModelTestSuite.gd"

func run_all_tests() -> Dictionary:
	failures.clear()
	reward_reveal_cancel_done_calls = 0
	test_phase_layout_restores_combat_active_phase_height()
	test_text_catalog_strips_item_implementation_tags()
	test_combat_scene_projects_global_debuff_and_queue_match()
	test_main_controller_projects_split_damage_popups_using_tile_color()
	test_vfx_manager_popup_palette_tracks_tile_color()
	test_interaction_cues_distinguish_hover_press_drag_and_disabled()
	test_backpack_drop_feedback_uses_real_placement_rules()
	test_backpack_drop_feedback_targets_current_footprint_only()
	test_backpack_hover_fx_stays_off()
	test_backpack_ui_exposes_drag_start_signal_for_reward_board_rearrange()
	test_reward_cloud_drag_anchor_clamps_inside_panel_bounds()
	return _result()

# ??쎈뻬: verify reward names hide version, color, and size implementation tags.
# ?ㅽ뻾: verify the expanded active phase is limited to the node-map page.
func test_phase_layout_restores_combat_active_phase_height() -> void:
	var node_model = PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 0, "maxStages": 5}, false)
	var combat_model = PhaseLayoutPresenterScript.project({"phase": "combat", "stageIndex": 0, "maxStages": 5}, false)
	_assert_eq(float(node_model.get("activePhaseStretchRatio", 0.0)), 7.0, "node map can expand active phase")
	_assert_eq(float(combat_model.get("activePhaseStretchRatio", 0.0)), 1.0, "combat restores previous active phase height")

func test_text_catalog_strips_item_implementation_tags() -> void:
	TextCatalogScript.set_locale("en")
	_assert_eq(TextCatalogScript.display_name("Crimson Drill Core v2 (Red)"), "Crimson Drill Core", "display name strips version and color tag")
	_assert_eq(TextCatalogScript.display_name("Anchor Beacon 3x2"), "Anchor Beacon", "display name strips size tag")
	_assert_eq(TextCatalogScript.display_description("Beacon: Large 3x2 module that pulses. (Green)"), "Beacon: that pulses.", "description strips module and color tag")
	TextCatalogScript.set_locale("ko")

# ?ㅽ뻾: verify terrain debuffs are global HUD status and current queue color marks matching cells.
func test_combat_scene_projects_global_debuff_and_queue_match() -> void:
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
				"weaknessMarkers": [{"cellId": "r0c0", "color": "green"}, {"cellId": "r0c1", "color": "red"}],
				"terrainDebuffs": [{"scope": "global", "effect": "weakened_terrain", "energy": "purple", "stacks": 2}],
				"terrainBuffs": [{"scope": "global", "effect": "fortified_terrain", "energy": "purple", "stacks": 1}]
			}
		}
	}
	var scene: Dictionary = model.create(snapshot, {"viewportWidth": 400, "viewportHeight": 200})
	_assert_eq(scene["terrain"].get("activeQueueColor", ""), "green", "terrain exposes active queue color")
	_assert_eq(scene["terrain"]["cells"][0].get("queueMatch", false), true, "matching weakness cell is highlighted")
	_assert_eq(scene["terrain"]["cells"][1].get("queueMatch", true), false, "nonmatching weakness cell is not highlighted")
	_assert(not scene["terrain"]["cells"][0].has("terrainDebuff"), "terrain debuff is not attached to individual cells")
	_assert_eq(scene["hud"].get("terrainDebuffs", []).size(), 1, "hud exposes global terrain debuffs")
	_assert_eq(scene["hud"]["terrainDebuffs"][0].get("stacks", 0), 2, "hud keeps global terrain debuff stacks")
	_assert_eq(scene["hud"].get("terrainBuffs", []).size(), 1, "hud also exposes global purple terrain buffs")
	_assert_eq(scene["hud"]["terrainBuffs"][0].get("stacks", 0), 1, "hud keeps global purple terrain buff stacks")
	_assert_eq(scene["hud"].get("purplePressure", {}).get("stackCount", 0), 2, "hud exposes purple weakened stack count separately")
	_assert_eq(scene["hud"].get("purplePressure", {}).get("buffCount", 0), 1, "hud exposes purple fortified stack count separately")
	_assert_eq(scene["hud"].get("purplePressure", {}).get("active", false), true, "purple pressure flag turns on when weakened or fortified stacks are active")

func test_main_controller_projects_split_damage_popups_using_tile_color() -> void:
	var events: Array = MainControllerCombatFlowScript.build_damage_popup_events(
		{"shield": 2.4, "health": 10.0},
		{"shield": 1.6, "health": 9.1},
		"purple",
		"green",
		"match"
	)
	_assert_eq(events.size(), 2, "split damage popups include separate shield and hp entries")
	_assert_eq(str(events[0].get("channel", "")), "shield", "shield popup is emitted first")
	_assert(abs(float(events[0].get("amount", 0.0)) - 0.8) < 0.001, "shield popup keeps exact shield damage")
	_assert_eq(str(events[0].get("color", "")), "purple", "shield popup color follows the hit tile color")
	_assert_eq(str(events[1].get("channel", "")), "health", "health popup is emitted second")
	_assert(abs(float(events[1].get("amount", 0.0)) - 0.9) < 0.001, "health popup keeps exact hp damage")
	_assert_eq(str(events[1].get("color", "")), "purple", "health popup color also follows the hit tile color")
	var fallback_events: Array = MainControllerCombatFlowScript.build_damage_popup_events(
		{"shield": 1.0, "health": 10.0},
		{"shield": 0.5, "health": 10.0},
		"normal",
		"green",
		"match"
	)
	_assert_eq(str(fallback_events[0].get("color", "")), "green", "normal tiles fall back to the active shot color for popup tint")
	var empty_events: Array = MainControllerCombatFlowScript.build_damage_popup_events(
		{"shield": 1.0, "health": 10.0},
		{"shield": 1.0, "health": 10.0},
		"red",
		"red",
		"empty_queue"
	)
	_assert_eq(empty_events.size(), 0, "empty queue does not spawn damage popups")

func test_vfx_manager_popup_palette_tracks_tile_color() -> void:
	var purple_palette: Dictionary = VFXManagerScript.popup_palette_for_color("purple")
	var blue_palette: Dictionary = VFXManagerScript.popup_palette_for_color("blue")
	_assert(purple_palette.has("fill"), "popup palette exposes a fill color")
	_assert(purple_palette.has("shadow"), "popup palette exposes a shadow color")
	_assert_eq(purple_palette.get("fontSize", 0), 20, "natural popup style keeps the shared 20px base font size")
	_assert(purple_palette.get("fill", Color.WHITE) != blue_palette.get("fill", Color.WHITE), "popup fill color changes with the hit tile color")

# ??쎈뻬: verify interactive UI cues communicate affordance and rejection states.
func test_interaction_cues_distinguish_hover_press_drag_and_disabled() -> void:
	var idle := InteractionCuePresenterScript.project_control_state({"hovered": false, "pressed": false, "disabled": false})
	var hover := InteractionCuePresenterScript.project_control_state({"hovered": true, "pressed": false, "disabled": false})
	var pressed := InteractionCuePresenterScript.project_control_state({"hovered": true, "pressed": true, "disabled": false})
	var disabled := InteractionCuePresenterScript.project_control_state({"hovered": true, "pressed": false, "disabled": true})
	var drag_ok := InteractionCuePresenterScript.project_drag_state(true, true)
	var drag_blocked := InteractionCuePresenterScript.project_drag_state(true, false)
	_assert(float(hover.get("glow", 0.0)) > float(idle.get("glow", 0.0)), "hover raises glow affordance")
	_assert(float(pressed.get("scale", 1.0)) < float(hover.get("scale", 1.0)), "press compresses hovered control")
	_assert_eq(disabled.get("cursor", ""), "forbidden", "disabled control reports forbidden cursor")
	_assert(float(disabled.get("alpha", 1.0)) < float(idle.get("alpha", 1.0)), "disabled control is visually dimmer")
	_assert_eq(drag_ok.get("dropState", ""), "valid", "valid drag reports accept state")
	_assert_eq(drag_blocked.get("dropState", ""), "blocked", "invalid drag reports blocked state")
	_assert(str(drag_blocked.get("outlineColor", "")).contains("bf616a"), "invalid drag uses red rejection outline")

# ??쎈뻬: verify backpack drag affordance follows the same placement rules as inventory.
func test_backpack_drop_feedback_uses_real_placement_rules() -> void:
	var inventory = InventoryScript.new(8, 8)
	var placed = ArtifactScript.new({"id": "placed_red", "name": "Placed Red", "shape": [[1]], "energyType": "red", "item_type": "drill"})
	var held = ArtifactScript.new({"id": "held_blue", "name": "Held Blue", "shape": [[1, 1]], "energyType": "blue", "item_type": "beacon"})
	inventory.place_artifact(placed, 0, 0)
	_assert_eq(BackpackUIScript.can_drop_artifact(inventory, held, 2, 2), true, "empty space accepts dragged artifact")
	_assert_eq(BackpackUIScript.can_drop_artifact(inventory, held, 0, 0), false, "occupied slot blocks dragged artifact")
	_assert_eq(BackpackUIScript.can_drop_artifact(inventory, held, 7, 7), false, "out of bounds shape blocks dragged artifact")
	var same_color_drill = ArtifactScript.new({"id": "held_red", "name": "Held Red", "shape": [[1]], "energyType": "red", "item_type": "drill"})
	var other_color_drill = ArtifactScript.new({"id": "held_blue_drill", "name": "Held Blue Drill", "shape": [[1]], "energyType": "blue", "item_type": "drill"})
	_assert_eq(BackpackUIScript.can_drop_artifact(inventory, same_color_drill, 2, 2), false, "same-color drill duplicate blocks dragged drill")
	_assert_eq(BackpackUIScript.can_drop_artifact(inventory, other_color_drill, 2, 2), true, "different-color drill remains placeable under the existing duplicate policy")

func test_backpack_drop_feedback_targets_current_footprint_only() -> void:
	var held = ArtifactScript.new({"id": "held_shape", "name": "Held Shape", "shape": [[1, 1], [0, 1]], "energyType": "green", "item_type": "beacon"})
	_assert_eq(
		BackpackUIScript.drop_feedback_cells_for(held, 3, 4),
		[Vector2(3, 4), Vector2(4, 4), Vector2(4, 5)],
		"drop feedback marks only occupied cells in the current hover footprint"
	)
	_assert_eq(BackpackUIScript.drop_feedback_cells_for(held, -1, 4), [], "drop feedback clears when the hover origin is outside the backpack")

func test_backpack_hover_fx_stays_off() -> void:
	_assert_eq(BackpackUIScript.slot_hover_fx_enabled(), false, "backpack slots keep hover wobble disabled so inventory readability stays stable")

func test_backpack_ui_exposes_drag_start_signal_for_reward_board_rearrange() -> void:
	var backpack_ui = BackpackUIScript.new()
	_assert(backpack_ui.has_signal("slot_drag_started"), "backpack ui exposes drag-start signal so reward-board inventory movement can use drag-and-drop")

func test_reward_cloud_drag_anchor_clamps_inside_panel_bounds() -> void:
	_assert(MainViewRuntimeScript != null, "main view runtime loads for reward-cloud drag clamping helpers")
	if MainViewRuntimeScript == null:
		return
	var view = MainViewRuntimeScript.new()
	_assert(view != null, "main view runtime instantiates for reward-cloud drag helper checks")
	if view == null:
		return
	_assert(view.has_method("reward_card_anchor_bounds"), "main view runtime exposes reward-card drag bounds for the reward cloud")
	_assert(view.has_method("clamp_reward_card_anchor"), "main view runtime exposes reward-card drag clamping for the reward cloud")
	if not view.has_method("reward_card_anchor_bounds") or not view.has_method("clamp_reward_card_anchor"):
		view.free()
		return
	var cloud_size := Vector2(320.0, 260.0)
	var card_size := Vector2(120.0, 120.0)
	var bounds: Rect2 = view.call("reward_card_anchor_bounds", cloud_size, card_size)
	var top_left := Vector2(-50.0, -30.0)
	var bottom_right := Vector2(500.0, 420.0)
	_assert(bounds.size.x >= 0.0 and bounds.size.y >= 0.0, "reward-card drag bounds stay non-negative even for smaller reward clouds")
	_assert_eq(view.call("clamp_reward_card_anchor", cloud_size, card_size, top_left), bounds.position, "reward-card drag clamp pins cards to the reward-cloud top-left bound")
	_assert_eq(view.call("clamp_reward_card_anchor", cloud_size, card_size, bottom_right), bounds.position + bounds.size, "reward-card drag clamp pins cards to the reward-cloud bottom-right bound")
	view.free()

