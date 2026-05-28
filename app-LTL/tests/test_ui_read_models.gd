# 계약:
# - 책임: UI read model이 raw domain data를 표시 가능한 text contract로 변환하는지 검증한다.
# - 입력: reward dictionary, Artifact object, node candidate dictionaries.
# - 출력: tooltip lines와 bbcode text.
# - 금지: Control node 생성, SceneTree 접근, gameplay 상태 변경.
#
# 실행: define the TestUiReadModels class.
extends RefCounted

const ArtifactScript = preload("res://src/models/Artifact.gd")
const TooltipReadModelScript = preload("res://src/ui/read_models/TooltipReadModel.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const NodeSelectReadModelScript = preload("res://src/ui/read_models/NodeSelectReadModel.gd")
const RewardReadModelScript = preload("res://src/ui/read_models/RewardReadModel.gd")
const PhaseLayoutPresenterScript = preload("res://src/ui/presenters/PhaseLayoutPresenter.gd")
const CombatFeedbackPresenterScript = preload("res://src/ui/presenters/CombatFeedbackPresenter.gd")
const ArtifactTooltipUIScript = preload("res://src/ui/ArtifactTooltipUI.gd")
const BackpackGridFactoryScript = preload("res://src/ui/presenters/BackpackGridFactory.gd")

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
	test_combat_feedback_projects_screenshake()
	test_tooltip_position_clamps_to_viewport()
	test_backpack_artifact_edges_omit_internal_borders()
	test_backpack_cooldown_charge_ratio_changes_with_current_cooldown()
	test_backpack_cooldown_charge_ratio_smoothly_interpolates()
	test_backpack_cooldown_mask_ratio_decreases_with_frame_time()
	test_text_catalog_strips_item_implementation_tags()
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

# ?ㅽ뻾: verify reward names hide version, color, and size implementation tags.
func test_text_catalog_strips_item_implementation_tags() -> void:
	TextCatalogScript.set_locale("en")
	_assert_eq(TextCatalogScript.display_name("Crimson Drill Core v2 (Red)"), "Crimson Drill Core", "display name strips version and color tag")
	_assert_eq(TextCatalogScript.display_name("Anchor Beacon 3x2"), "Anchor Beacon", "display name strips size tag")
	_assert_eq(TextCatalogScript.display_description("Beacon: Large 3x2 module that pulses. (Green)"), "Beacon: that pulses.", "description strips module and color tag")
	TextCatalogScript.set_locale("ko")

# 실행: append a failure when condition is false.
func _assert(condition: bool, msg: String) -> void:
	if not condition:
		failures.append(msg)

# 실행: append a deterministic equality failure when values differ.
func _assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])
