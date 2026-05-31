# 계약:
# - 책임: UI read model이 raw domain data를 표시 가능한 text contract로 변환하는지 검증한다.
# - 입력: reward dictionary, Artifact object, node candidate dictionaries.
# - 출력: tooltip lines와 bbcode text.
# - 금지: Control node 생성, SceneTree 접근, gameplay 상태 변경.
#
# 실행: define the TestUiReadModels class.
extends RefCounted

const ArtifactScript = preload("res://src/models/Artifact.gd")
const InventoryScript = preload("res://src/models/InventoryModel.gd")
const TooltipReadModelScript = preload("res://src/ui/read_models/TooltipReadModel.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const NodeSelectReadModelScript = preload("res://src/ui/read_models/NodeSelectReadModel.gd")
const RewardReadModelScript = preload("res://src/ui/read_models/RewardReadModel.gd")
const PhaseLayoutPresenterScript = preload("res://src/ui/presenters/PhaseLayoutPresenter.gd")
const CombatFeedbackPresenterScript = preload("res://src/ui/presenters/CombatFeedbackPresenter.gd")
const ArtifactTooltipUIScript = preload("res://src/ui/ArtifactTooltipUI.gd")
const BackpackGridFactoryScript = preload("res://src/ui/presenters/BackpackGridFactory.gd")
const CombatSceneModelScript = preload("res://src/ui/CombatSceneModel.gd")
const InteractionCuePresenterScript = preload("res://src/ui/presenters/InteractionCuePresenter.gd")
const BackpackUIScript = preload("res://src/ui/BackpackUI.gd")
const InteractionFXScript = preload("res://src/ui/InteractionFX.gd")
const BattlefieldVFXScript = preload("res://src/ui/BattlefieldVFX.gd")
const MainControllerRuntimeScript = preload("res://src/MainControllerRuntime.gd")

var failures: Array[String] = []

# 실행: run all UI read model tests.
func run_all_tests() -> Dictionary:
	failures.clear()
	test_tooltip_projects_reward_dictionary()
	test_tooltip_projects_artifact_object()
	test_text_catalog_switches_korean_and_english()
	test_text_catalog_korean_names_are_readable()
	test_reward_drill_tooltip_compares_same_color_equipped_drill()
	test_reward_beacon_tooltip_does_not_show_equipped_drill_comparison()
	test_node_select_projects_candidates()
	test_node_select_omits_baseline_reward_noise()
	test_reward_tray_projects_lines_and_discard_zone()
	test_phase_layout_projects_visibility_and_timer()
	test_node_select_layout_is_full_page()
	test_node_select_layout_uses_map_backpack_split()
	test_node_select_backpack_width_tracks_left_stack_height()
	test_top_content_backpack_uses_fixed_width_policy()
	test_top_content_backpack_width_tracks_full_row_height()
	test_phase_layout_gives_backpack_more_space_in_combat_and_reward()
	test_phase_layout_hides_backpack_cooldown_visuals_outside_combat()
	test_combat_feedback_projects_screenshake()
	test_tooltip_position_clamps_to_viewport()
	test_backpack_artifact_edges_omit_internal_borders()
	test_backpack_cooldown_charge_ratio_changes_with_current_cooldown()
	test_backpack_cooldown_charge_ratio_smoothly_interpolates()
	test_backpack_cooldown_mask_ratio_decreases_with_frame_time()
	test_backpack_cooldown_display_does_not_backtrack_on_snapshot_refresh()
	test_main_controller_uses_terrain_shift_interval()
	test_main_controller_syncs_combat_ticks_to_shift_interval()
	test_main_controller_starter_loadout_positions_are_adjacent()
	test_phase_layout_restores_combat_active_phase_height()
	test_text_catalog_strips_item_implementation_tags()
	test_combat_scene_projects_global_debuff_and_queue_match()
	test_interaction_cues_distinguish_hover_press_drag_and_disabled()
	test_backpack_drop_feedback_uses_real_placement_rules()
	test_backpack_hover_fx_stays_off()
	test_backpack_drag_feedback_restores_slot_modulate_after_reward_drop()
	test_backpack_drag_feedback_restores_slot_alpha_after_reward_drop()
	test_interaction_fx_preserves_container_layout_children()
	test_interaction_fx_skips_shader_on_panel_slots()
	test_hold_fire_stops_when_overload_repair_starts()
	test_combat_clicks_block_while_repair_or_aim_lock_is_active()
	test_reward_reveal_profile_includes_silhouette_pause_and_rarity_roll()
	return {"ok": failures.is_empty(), "errors": failures}

# 실행: verify reward dictionary tooltip data.
func test_tooltip_projects_reward_dictionary() -> void:
	TextCatalogScript.set_locale("en")
	var reward = {
		"kind": "Azure Beacon",
		"rarity": "rare",
		"payload": {"item_type": "beacon", "energy_type": "blue", "beacon_cooldown_mod": -12, "beacon_damage_mod": 0.4},
		"presentation": {"description": "A test beacon"}
	}
	var model = TooltipReadModelScript.project(reward)
	_assert_eq(model["name"], "Azure Beacon", "tooltip reward name")
	_assert_eq(model["itemType"], "beacon", "tooltip reward item type")
	_assert_eq(model["energyType"], "blue", "tooltip reward energy")
	_assert(str(model["bbcode"]).contains("Azure Beacon"), "tooltip bbcode includes name")
	_assert(str(model["bbcode"]).contains("Beacon pulse effect"), "tooltip bbcode includes beacon effects")
	TextCatalogScript.set_locale("ko")

# 실행: verify Artifact object tooltip data.
func test_tooltip_projects_artifact_object() -> void:
	var artifact = ArtifactScript.new({"id": "ruby", "name": "Ruby Drill", "shape": [[1]], "energyType": "red", "item_type": "drill", "baseCooldownTicks": 80, "damage": 1.5, "grade": "basic"})
	var model = TooltipReadModelScript.project(artifact)
	_assert_eq(model["name"], "루비 드릴", "tooltip artifact name")
	_assert_eq(model["itemType"], "drill", "tooltip artifact item type")
	_assert(str(model["bbcode"]).contains("쿨타임: 80 T"), "tooltip bbcode includes cooldown")
	_assert(str(model["bbcode"]).contains("피해"), "tooltip bbcode includes damage")

# 실행: verify UI strings come from a locale-aware text catalog.
func test_text_catalog_switches_korean_and_english() -> void:
	TextCatalogScript.set_locale("ko")
	_assert_eq(TextCatalogScript.t("action.start"), "전투 시작", "korean text catalog start label")
	TextCatalogScript.set_locale("en")
	_assert_eq(TextCatalogScript.t("action.start"), "Start Combat", "english text catalog start label")
	TextCatalogScript.set_locale("ko")

# 실행: verify Korean display-name mappings are readable.
func test_text_catalog_korean_names_are_readable() -> void:
	TextCatalogScript.set_locale("ko")
	_assert_eq(TextCatalogScript.display_name("Safe Scar"), "안전한 균열", "safe scar korean display name")
	_assert_eq(TextCatalogScript.display_name("Ruby Drill"), "루비 드릴", "ruby drill korean display name")

# 실행: verify reward drill tooltips compare only the equipped drill with the same energy color.
func test_reward_drill_tooltip_compares_same_color_equipped_drill() -> void:
	var red_drill = ArtifactScript.new({"id": "red_now", "name": "현재 루비 드릴", "shape": [[1]], "energyType": "red", "item_type": "drill", "baseCooldownTicks": 80, "damage": 1.5, "grade": "basic"})
	var blue_drill = ArtifactScript.new({"id": "blue_now", "name": "현재 사파이어 드릴", "shape": [[1]], "energyType": "blue", "item_type": "drill", "baseCooldownTicks": 60, "damage": 1.2, "grade": "basic"})
	var reward = {"kind": "보상 루비 드릴", "rarity": "rare", "payload": {"item_type": "drill", "energy_type": "red", "base_cooldown_ticks": 70, "damage": 1.8}, "presentation": {"description": "빨간 보상 드릴"}}
	var model = TooltipReadModelScript.project_reward_comparison(reward, [blue_drill, red_drill], "ko")
	_assert(str(model["bbcode"]).contains("보상 유물"), "comparison shows reward column")
	_assert(str(model["bbcode"]).contains("현재 장착"), "comparison shows equipped column")
	_assert(str(model["bbcode"]).contains("현재 루비 드릴"), "comparison uses same color drill")
	_assert(not str(model["bbcode"]).contains("현재 사파이어 드릴"), "comparison excludes other color drill")
	_assert(str(model["bbcode"]).contains("쿨타임"), "comparison localizes cooldown label")

# 실행: verify beacon rewards do not render a missing-drill comparison column.
func test_reward_beacon_tooltip_does_not_show_equipped_drill_comparison() -> void:
	var red_drill = ArtifactScript.new({"id": "red_now", "name": "현재 루비 드릴", "shape": [[1]], "energyType": "red", "item_type": "drill", "baseCooldownTicks": 80, "damage": 1.5, "grade": "basic"})
	var reward = {"kind": "Amplifying Cooldown Beacon", "rarity": "rare", "payload": {"item_type": "beacon", "energy_type": "red", "beacon_cooldown_mod": -12, "beacon_damage_mod": 0.4}, "presentation": {"description": "Compact 1x1 module. Pulse support."}}
	var model = TooltipReadModelScript.project_reward_comparison(reward, [red_drill], "ko")
	var text := str(model["bbcode"])
	_assert(text.contains("쿨타임 증폭 비콘"), "beacon tooltip shows reward item")
	_assert(not text.contains("현재 장착"), "beacon tooltip does not show equipped column")
	_assert(not text.contains("같은 색상 장착 드릴 없음"), "beacon tooltip does not show missing drill message")
	_assert(not text.contains("1x1"), "beacon tooltip hides size clutter")

# 실행: verify node select read model formats selected candidates.
func test_node_select_projects_candidates() -> void:
	var scene = {"nodeSelect": {"candidates": [{"id": "normal", "label": "Normal Node", "weaknessLabel": "red"}, {"id": "elite", "label": "Elite Node", "weaknessLabel": "blue"}]}}
	var model = NodeSelectReadModelScript.project(scene, 1)
	_assert(str(model["text"]).contains("정예 노드"), "node select includes candidate label")
	_assert(str(model["text"]).contains("[url=1]"), "node select includes candidate link")
	_assert(str(model["text"]).contains("color=#ffd766"), "node select highlights selected candidate")

# 실행: verify baseline node cards do not repeat low-signal reward fields.
func test_node_select_omits_baseline_reward_noise() -> void:
	var scene = {"nodeSelect": {"candidates": [
		{"id": "normal", "label": "Safe Scar", "weaknessLabel": "red", "riskTier": "safe", "rewardBias": "baseline", "recommendedBuildHint": ""},
		{"id": "hazard", "label": "Hazard Rich", "weaknessLabel": "green", "riskTier": "danger", "rewardBias": "rarity_up", "recommendedBuildHint": "Repair-ready queue"}
	]}}
	var text := str(NodeSelectReadModelScript.project(scene, 0)["text"])
	_assert(text.contains("안전한 균열"), "node select localizes baseline label")
	_assert(not text.contains("보상: 기본"), "baseline node omits baseline reward noise")
	_assert(text.contains("보상: 희귀도 상승"), "non-baseline node keeps reward bias")

# 실행: verify reward tray read model formats reward lines and discard state.
func test_reward_tray_projects_lines_and_discard_zone() -> void:
	var rewards := [{"kind": "Ruby Drill", "rarity": "rare", "qty": 1, "presentation": {"badge": "즉시"}}]
	var held = ArtifactScript.new({"id": "held", "name": "Held Drill", "shape": [[1]], "energyType": "red", "item_type": "drill"})
	var model = RewardReadModelScript.project_tray(rewards, 0, held, true)
	_assert(str(model["text"]).contains("루비 드릴"), "reward tray includes reward kind")
	_assert(str(model["text"]).contains("들고 있음"), "reward tray marks held reward")
	_assert_eq(model["discardActive"], true, "reward tray discard active when held")
	_assert(str(model["discardText"]).contains("루비 드릴"), "reward tray discard text uses reward kind")

# 실행: verify phase layout presenter emits visibility and timer model.
func test_phase_layout_projects_visibility_and_timer() -> void:
	var scene := {"phase": "combat", "stageIndex": 1, "maxStages": 3, "targetPanel": {"timeLimitTicks": 1200.0, "elapsedTicks": 400.0}}
	var model = PhaseLayoutPresenterScript.project(scene, false)
	_assert_eq(model["phaseText"], "단계: 전투", "phase layout text")
	_assert_eq(model["stageText"], "스테이지 2 / 3", "phase layout stage text")
	_assert_eq(model["battlefieldVisible"], true, "phase layout battlefield visible")
	_assert_eq(model["rewardVisible"], false, "phase layout reward hidden during combat")
	_assert_eq(model["timerText"], "00:40", "phase layout timer text")
	_assert_eq(model["combatTimeActive"], true, "phase layout combat time active")

# 실행: verify node selection owns the available page instead of sharing prototype side panels.
func test_node_select_layout_is_full_page() -> void:
	var model = PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 0, "maxStages": 5}, false)
	_assert_eq(model["nodeSelectVisible"], true, "node select panel visible")
	_assert_eq(model["nodeMapFullPage"], true, "node map page requests full-page layout")
	_assert_eq(model["topContentVisible"], false, "node map page moves backpack into the map layout")
	_assert_eq(model["backpackVisible"], true, "node map page keeps backpack available for starter placement")
	_assert_eq(model["sidebarsVisible"], false, "node map page hides nonessential sidebars")
	_assert_eq(model["statusVisible"], false, "node map page hides combat target status")

# 실행: verify node selection requests a left map / right backpack layout.
func test_node_select_layout_uses_map_backpack_split() -> void:
	var model = PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 0, "maxStages": 5}, false)
	_assert_eq(model["nodeSelectBackpackDock"], "right", "node map docks backpack on the right")
	_assert_eq(float(model["nodeMapStretchRatio"]), 1.0, "node map consumes the flexible remaining row width")
	_assert_eq(float(model["backpackStretchRatio"]), 0.0, "node-select backpack remains fixed-width and right-docked")

func test_node_select_backpack_width_tracks_left_stack_height() -> void:
	var MainViewRuntimeScript = load("res://src/ui/MainViewRuntime.gd")
	_assert(MainViewRuntimeScript != null, "main view runtime loads for node-select backpack sizing")
	if MainViewRuntimeScript == null:
		return
	_assert(MainViewRuntimeScript.has_method("node_select_backpack_width_for_row"), "main view runtime exposes node-select backpack sizing policy")
	if not MainViewRuntimeScript.has_method("node_select_backpack_width_for_row"):
		return
	var roomy_width := float(MainViewRuntimeScript.node_select_backpack_width_for_row(Vector2(1260, 704), 460.0))
	_assert_eq(roomy_width, 704.0, "roomy node-select layout sizes the backpack from the left stack height")
	var constrained_width := float(MainViewRuntimeScript.node_select_backpack_width_for_row(Vector2(980, 704), 460.0))
	_assert_eq(constrained_width, 500.0, "constrained node-select layout preserves map width before matching backpack height")

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
	_assert_eq(float(MainViewRuntimeScript.top_content_backpack_width_for_height(548.0)), 548.0, "top-content backpack requests the full available row height so the visible backpack panel can match the side-panel heights")
	_assert_eq(float(MainViewRuntimeScript.top_content_backpack_width_for_height(680.0)), 680.0, "top-content backpack does not cap its requested width below the available row height")

func test_phase_layout_gives_backpack_more_space_in_combat_and_reward() -> void:
	var combat = PhaseLayoutPresenterScript.project({"phase": "combat", "stageIndex": 0, "maxStages": 5}, false)
	var reward = PhaseLayoutPresenterScript.project({"phase": "reward_loot", "stageIndex": 0, "maxStages": 5}, false)
	_assert_eq(float(combat.get("leftColumnTopStretchRatio", 0.0)), 2.45, "combat left status column keeps its widened share of the freed top-content width")
	_assert_eq(float(combat.get("backpackTopStretchRatio", -1.0)), 0.0, "combat backpack container no longer consumes horizontal stretch width")
	_assert_eq(float(combat.get("rightSidebarTopStretchRatio", 0.0)), 2.35, "combat log sidebar keeps its widened share while staying right-aligned")
	_assert_eq(float(reward.get("backpackTopStretchRatio", -1.0)), 0.0, "reward layout also keeps the backpack fixed-width instead of stretching its slot")
	_assert(float(combat.get("leftColumnTopStretchRatio", 0.0)) > 0.0, "combat layout leaves remaining horizontal width to the side panels")
	_assert(float(combat.get("rightSidebarTopStretchRatio", 0.0)) > 0.0, "combat layout leaves remaining horizontal width to the log sidebar")

func test_phase_layout_hides_backpack_cooldown_visuals_outside_combat() -> void:
	var node_select = PhaseLayoutPresenterScript.project({"phase": "node_select", "stageIndex": 0, "maxStages": 5}, false)
	var reward = PhaseLayoutPresenterScript.project({"phase": "reward_loot", "stageIndex": 0, "maxStages": 5}, false)
	var combat = PhaseLayoutPresenterScript.project({"phase": "combat", "stageIndex": 0, "maxStages": 5}, false)
	_assert_eq(bool(node_select.get("backpackCooldownVisible", true)), false, "node-select hides cooldown darkness so the starter loadout stays readable")
	_assert_eq(bool(reward.get("backpackCooldownVisible", true)), false, "reward layout hides cooldown darkness while reorganizing loot")
	_assert_eq(bool(combat.get("backpackCooldownVisible", false)), true, "combat keeps cooldown darkness visible")

# 실행: verify combat feedback presenter converts hit status to screenshake.
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

# 실행: verify floating tooltip stays within the visible viewport.
func test_tooltip_position_clamps_to_viewport() -> void:
	var pos = ArtifactTooltipUIScript.clamped_position(Vector2(790, 590), Vector2(240, 120), Vector2(800, 600), Vector2(15, 15), 8.0)
	_assert_eq(pos, Vector2(552, 472), "tooltip clamps bottom-right overflow")
	var top_left = ArtifactTooltipUIScript.clamped_position(Vector2(-20, -10), Vector2(240, 120), Vector2(800, 600), Vector2(15, 15), 8.0)
	_assert_eq(top_left, Vector2(8, 8), "tooltip clamps top-left overflow")

# 실행: verify multi-cell artifacts only draw black borders on the outer perimeter.
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

# 실행: verify cooldown charge ratio changes as the artifact cooldown ticks down.
func test_backpack_cooldown_charge_ratio_changes_with_current_cooldown() -> void:
	var early := BackpackGridFactoryScript.cooldown_charge_ratio(75, 100, 0)
	var late := BackpackGridFactoryScript.cooldown_charge_ratio(25, 100, 0)
	_assert(early < late, "cooldown charge ratio increases as cooldown decreases")
	_assert_eq(early, 0.25, "early cooldown charge ratio")
	_assert_eq(late, 0.75, "late cooldown charge ratio")

# 실행: verify the UI helper eases cooldown fill instead of snapping to the target.
func test_backpack_cooldown_charge_ratio_smoothly_interpolates() -> void:
	var eased := BackpackGridFactoryScript.smooth_charge_ratio(0.2, 0.8, 0.1, 3.0)
	_assert(eased > 0.2, "smooth cooldown ratio moves upward")
	_assert(eased < 0.8, "smooth cooldown ratio does not snap to target")

# ?ㅽ뻾: verify the visible cooldown mask drains continuously from frame time.
func test_backpack_cooldown_mask_ratio_decreases_with_frame_time() -> void:
	var remaining := BackpackGridFactoryScript.cooldown_remaining_ratio(75, 100, 0)
	var advanced := BackpackGridFactoryScript.advance_visual_cooldown(75.0, 0.25, 20.0)
	_assert_eq(remaining, 0.75, "cooldown remaining mask ratio")
	_assert_eq(advanced, 70.0, "visual cooldown advances by frame delta")
	_assert(BackpackGridFactoryScript.cooldown_remaining_ratio(int(advanced), 100, 0) < remaining, "mask shrinks as frame time advances")

# 실행: verify terrain marker movement cadence leaves more room after player target selection.
# 실행: verify model refreshes cannot make an active cooldown mask grow again.
func test_backpack_cooldown_display_does_not_backtrack_on_snapshot_refresh() -> void:
	var stable := BackpackGridFactoryScript.stable_cooldown_display(45.0, 60.0, 80)
	_assert_eq(stable, 45.0, "stale backend refresh does not increase displayed cooldown")
	var reduced := BackpackGridFactoryScript.stable_cooldown_display(45.0, 30.0, 80)
	_assert_eq(reduced, 30.0, "backend cooldown reductions still apply")
	var reset := BackpackGridFactoryScript.stable_cooldown_display(0.0, 80.0, 80)
	_assert_eq(reset, 80.0, "freshly fired drill cooldown can reset to full")

func test_main_controller_uses_terrain_shift_interval() -> void:
	var MainControllerScript = load("res://src/MainControllerRuntime.gd")
	_assert(MainControllerScript != null, "main controller runtime loads")
	if MainControllerScript == null:
		return
	_assert_eq(float(MainControllerScript.TERRAIN_SHIFT_SECONDS), 1.5, "terrain marker shift interval is 1.5 seconds")

# 실행: verify backend cooldown ticks use the same 20 ticks/sec cadence as backpack animation.
func test_main_controller_syncs_combat_ticks_to_shift_interval() -> void:
	var MainControllerScript = load("res://src/MainControllerRuntime.gd")
	_assert(MainControllerScript != null, "main controller runtime loads for shift tick sync")
	if MainControllerScript == null:
		return
	_assert_eq(int(MainControllerScript.TERRAIN_SHIFT_TICKS), 30, "1.5 second shift advances 30 combat ticks")

# 실행: verify starter drill and beacon begin adjacent so stage-one cooldown support can work.
func test_main_controller_starter_loadout_positions_are_adjacent() -> void:
	var MainControllerScript = load("res://src/MainControllerRuntime.gd")
	_assert(MainControllerScript != null, "main controller runtime loads for starter positions")
	if MainControllerScript == null:
		return
	var positions: Array = MainControllerScript.STARTER_LOADOUT_POSITIONS
	_assert_eq(positions.size(), 2, "starter loadout exposes two positions")
	var delta: Vector2 = positions[0] - positions[1]
	_assert_eq(int(abs(delta.x) + abs(delta.y)), 1, "starter drill and beacon begin orthogonally adjacent")

# ?ㅽ뻾: verify reward names hide version, color, and size implementation tags.
# 실행: verify the expanded active phase is limited to the node-map page.
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

# 실행: verify terrain debuffs are global HUD status and current queue color marks matching cells.
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
			"queue": {"capacity": 2, "loaded": 2, "items": ["green", "red"]},
			"pin": {},
			"repair": {},
			"hazard": {},
			"aim": {"cellId": "r0c0", "canFire": true},
			"battlefield": {
				"rows": 1,
				"columns": 2,
				"weaknessMarkers": [{"cellId": "r0c0", "color": "green"}, {"cellId": "r0c1", "color": "red"}],
				"terrainDebuffs": [{"scope": "global", "effect": "weakened_terrain", "energy": "purple", "stacks": 2}]
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

# ?ㅽ뻾: verify interactive UI cues communicate affordance and rejection states.
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

# ?ㅽ뻾: verify backpack drag affordance follows the same placement rules as inventory.
func test_backpack_drop_feedback_uses_real_placement_rules() -> void:
	var inventory = InventoryScript.new(8, 8)
	var placed = ArtifactScript.new({"id": "placed_red", "name": "Placed Red", "shape": [[1]], "energyType": "red", "item_type": "drill"})
	var held = ArtifactScript.new({"id": "held_blue", "name": "Held Blue", "shape": [[1, 1]], "energyType": "blue", "item_type": "beacon"})
	inventory.place_artifact(placed, 0, 0)
	_assert_eq(BackpackUIScript.can_drop_artifact(inventory, held, 2, 2), true, "empty space accepts dragged artifact")
	_assert_eq(BackpackUIScript.can_drop_artifact(inventory, held, 0, 0), false, "occupied slot blocks dragged artifact")
	_assert_eq(BackpackUIScript.can_drop_artifact(inventory, held, 7, 7), false, "out of bounds shape blocks dragged artifact")

func test_backpack_hover_fx_stays_off() -> void:
	_assert_eq(BackpackUIScript.slot_hover_fx_enabled(), false, "backpack slots keep hover wobble disabled so inventory readability stays stable")

func test_backpack_drag_feedback_restores_slot_modulate_after_reward_drop() -> void:
	var slot := Panel.new()
	var original := Color(0.95, 0.90, 0.82, 0.65)
	slot.self_modulate = original
	InteractionFXScript.apply_drag_feedback(slot, true, false)
	InteractionFXScript.apply_drag_feedback(slot, false, true)
	_assert_eq(slot.self_modulate, original, "backpack slot drag feedback restores the original slot tint after reward placement")

func test_backpack_drag_feedback_restores_slot_alpha_after_reward_drop() -> void:
	var slot := Panel.new()
	slot.modulate = Color(1.0, 1.0, 1.0, 1.0)
	InteractionFXScript.apply_drag_feedback(slot, true, true)
	InteractionFXScript.apply_drag_feedback(slot, false, true)
	_assert_eq(slot.modulate.a, 1.0, "backpack slot drag feedback resets slot alpha immediately after reward placement")
	_assert_eq(slot.modulate.a, 1.0, "backpack slot drag feedback keeps slot alpha visible after reward placement")

# ?ㅽ뻾: verify hover polish never translates children that are owned by layout containers.
func test_interaction_fx_preserves_container_layout_children() -> void:
	var grid := GridContainer.new()
	var slot := Panel.new()
	grid.add_child(slot)
	var floating := Panel.new()
	_assert_eq(InteractionFXScript.can_translate_control(slot), false, "grid child keeps container-owned position")
	_assert_eq(InteractionFXScript.can_translate_control(floating), true, "free control can use lift translation")

func test_interaction_fx_skips_shader_on_panel_slots() -> void:
	_assert_eq(InteractionFXScript._supports_shader_material(Panel.new()), false, "panel-based slots keep stylebox rendering instead of shader materials")
	_assert_eq(InteractionFXScript._supports_shader_material(Button.new()), true, "buttons still use shader-backed cues")

func test_hold_fire_stops_when_overload_repair_starts() -> void:
	var stopped := MainControllerRuntimeScript.should_continue_hold_fire({
		"phase": "combat",
		"feedback": {"status": "empty_queue"},
		"hud": {"repair": {"active": true}, "queue": {"items": []}}
	}, true)
	var active := MainControllerRuntimeScript.should_continue_hold_fire({
		"phase": "combat",
		"feedback": {"status": "match"},
		"hud": {"repair": {"active": false}, "queue": {"items": ["red"]}}
	}, true)
	_assert_eq(stopped, false, "hold-fire stops once overload repair begins")
	_assert_eq(active, true, "hold-fire continues only while combat can actually keep firing")

func test_combat_clicks_block_while_repair_or_aim_lock_is_active() -> void:
	var blocked := MainControllerRuntimeScript.can_accept_combat_click({
		"phase": "combat",
		"hud": {"repair": {"active": true}, "aim": {"canFire": false}}
	}, "r0c0", [])
	var ready := MainControllerRuntimeScript.can_accept_combat_click({
		"phase": "combat",
		"hud": {"repair": {"active": false}, "aim": {"canFire": true}}
	}, "r0c0", [])
	_assert_eq(blocked, false, "combat clicks stop while overload repair is active")
	_assert_eq(ready, true, "combat clicks resume only when aim can fire again")

func test_reward_reveal_profile_includes_silhouette_pause_and_rarity_roll() -> void:
	var profile := BattlefieldVFXScript.reveal_timing_profile()
	_assert(float(profile.get("silhouetteHold", 0.0)) >= 1.2, "reward reveal keeps silhouettes visible long enough to build anticipation")
	_assert(float(profile.get("rarityRoll", 0.0)) >= 1.4, "reward reveal reserves time for rolling rarity text")
	_assert_eq(BattlefieldVFXScript.rolling_rarity_label("epic", 0.0), "COMMON", "rarity roll starts from a decoy label instead of revealing immediately")
	_assert_eq(BattlefieldVFXScript.rolling_rarity_label("epic", float(profile.get("rarityRoll", 0.0))), "EPIC", "rarity roll settles on the actual reward rarity")

# 실행: verify battlefield cells keep the compact pre-M4 terrain aspect ratio.
# 실행: append a failure when condition is false.
func _assert(condition: bool, msg: String) -> void:
	if not condition:
		failures.append(msg)

# 실행: append a deterministic equality failure when values differ.
func _assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])
