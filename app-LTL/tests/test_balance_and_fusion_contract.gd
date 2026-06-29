# 계약:
# - 책임: starter color balance, Leviathan stage health scaling, and duplicate reward item fusion stay within the requested playable bounds.
# - 입력: HeadlessMiniRun, NodeVocab, reward-created Artifact instances, and InventoryModel.
# - 출력: deterministic failure labels for the focused balance/fusion contract.
# - 금지: SceneTree node ownership, visual rendering, or direct player input emulation.
#
# 실행: define the focused balance and fusion contract test class.
extends RefCounted

const HeadlessMiniRunScript = preload("res://src/process/HeadlessMiniRun.gd")
const NodeVocabScript = preload("res://src/vocabulary/NodeVocab.gd")
const CreateArtifactFromRewardScript = preload("res://src/vocabulary/reward/CreateArtifactFromReward.gd")
const InventoryModelScript = preload("res://src/models/InventoryModel.gd")
const ArtifactScript = preload("res://src/models/Artifact.gd")
const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")
const MainControllerRewardBackpackFlowScript = preload("res://src/controllers/MainControllerRewardBackpackFlow.gd")

const FIRST_STAGE_EASY_TICK_BUDGET := 620

var failures: Array[String] = []

class FakeRewardRun:
	extends RefCounted
	var state: Dictionary = {"pendingRewards": [], "inventory": {}}

class FakeRewardPreview:
	extends RefCounted
	var run := FakeRewardRun.new()
	func get_scene() -> Dictionary:
		return {"phase": "reward_loot"}

class FakeRewardBackpackView:
	extends RefCounted
	var discard_prompts: Array[String] = []
	var info_toasts: Array[Dictionary] = []
	var ghost_updates: Array = []
	func show_discard_confirmation(artifact_name: String) -> void:
		discard_prompts.append(artifact_name)
	func show_info_toast(message: String, duration_seconds: float = 5.0) -> void:
		info_toasts.append({"message": message, "duration": duration_seconds})
	func update_backpack_ghost(artifact) -> void:
		ghost_updates.append(artifact)
	func render_backpack(_inventory) -> void:
		pass
	func play_interaction_sfx(_category: String) -> void:
		pass

class FakeRewardBackpackController:
	extends RefCounted
	var current_scene: Dictionary = {"phase": "reward_loot"}
	var inventory = InventoryModelScript.new(4, 4)
	var held_artifact = null
	var held_from_rewards := false
	var held_reward_index := -1
	var held_inventory_origin := Vector2(-1, -1)
	var local_rewards_list: Array = []
	var inspected_reward_index := -1
	var inspected_backpack_artifact = null
	var preview_controller := FakeRewardPreview.new()
	var view := FakeRewardBackpackView.new()
	var pending_discard_request: Dictionary = {}
	var logs: Array[String] = []
	var rendered_scene: Dictionary = {}
	func _reward_ceremony_active() -> bool:
		return false
	func _append_localized_log(_color_hex: String, key: String, _args: Array = []) -> void:
		logs.append(key)
	func _emit_ui_telemetry(_payload: Dictionary) -> void:
		pass
	func _render_scene(scene: Dictionary) -> void:
		rendered_scene = scene.duplicate(true)
	func _render_rewards(scene: Dictionary) -> void:
		rendered_scene = scene.duplicate(true)
	func _apply_growth_modifiers() -> void:
		pass
	func _recalculate_queue_colors() -> void:
		pass

# 실행: run every focused balance and fusion regression.
func run_all_tests() -> Dictionary:
	failures.clear()
	test_stage_one_starter_colors_clear_inside_easy_budget()
	test_stage_health_scaling_starts_easy_and_rises_each_stage()
	test_second_run_stage_one_continues_leviathan_difficulty_curve()
	test_duplicate_common_reward_only_fuses_on_exact_grid_overlap()
	test_fusion_uses_both_material_roll_values_without_extra_randomness()
	test_same_name_same_grade_drills_can_be_placed_separately()
	test_invalid_placement_requests_five_second_toast()
	test_discard_requires_confirmation_before_reward_deletion()
	test_reward_visual_id_survives_artifact_creation_and_fusion()
	test_duplicate_common_beacon_fusion_strengthens_beacon_stats()
	test_epic_duplicate_fuses_to_legendary_but_legendary_does_not_fuse()
	return {"ok": failures.is_empty(), "errors": failures}

# 실행: verify each starter color can clear stage one without extra rewards.
func test_stage_one_starter_colors_clear_inside_easy_budget() -> void:
	for color in ["red", "blue", "purple", "green"]:
		var result := _autoplay_first_stage(color)
		_assert(bool(result.get("cleared", false)), "%s starter clears the first stage without reward pickups" % color)
		_assert(
			int(result.get("elapsedTicks", 9999)) <= FIRST_STAGE_EASY_TICK_BUDGET,
			"%s starter clears inside the easy first-stage budget; got %d ticks" % [color, int(result.get("elapsedTicks", 9999))]
		)
		_assert(
			int(result.get("shots", 9999)) <= 28,
			"%s starter clears without excessive opening shots; got %d" % [color, int(result.get("shots", 9999))]
		)

# 실행: verify production stage health starts low and increases through the Leviathan.
func test_stage_health_scaling_starts_easy_and_rises_each_stage() -> void:
	var totals: Array = []
	var node_table := _normal_only_node_table()
	var tuning := {"maxStages": 5}
	for stage_index in range(5):
		var candidates: Array = NodeVocabScript.generate_candidates(101, stage_index, node_table, 1, tuning)
		_assert(not candidates.is_empty(), "stage %d exposes a normal combat candidate" % stage_index)
		if candidates.is_empty():
			continue
		var combat: Dictionary = (candidates[0] as Dictionary).get("combat", {})
		totals.append(float(combat.get("shield", 0.0)) + float(combat.get("health", 0.0)))
	if totals.is_empty():
		return
	_assert(float(totals[0]) <= 50.0, "stage one durability is easy enough for every starter; got %.1f" % float(totals[0]))
	for i in range(1, totals.size()):
		_assert(float(totals[i]) > float(totals[i - 1]), "stage %d durability rises over previous stage" % i)
	if totals.size() >= 5:
		_assert(float(totals[4]) >= float(totals[0]) * 3.0, "late Leviathan durability is meaningfully harder than stage one")

# 실행: verify later runs continue the Leviathan combat curve instead of restarting at stage one.
func test_second_run_stage_one_continues_leviathan_difficulty_curve() -> void:
	var run = HeadlessMiniRunScript.new({
		"seed": 9203,
		"maxStages": 3,
		"runCount": 2,
		"candidateCount": 1,
		"nodeTable": _normal_only_node_table()
	})
	var snapshot: Dictionary = run.snapshot()
	var first_stage_total := _candidate_total(snapshot)
	var final_stage_total := first_stage_total
	for stage in range(3):
		run.select_node(0)
		run.apply_combat_input({"type": "resolve", "outcome": "clear"})
		snapshot = run.claim_rewards()
		if stage == 1:
			final_stage_total = _candidate_total(snapshot)
	var second_run_total := _candidate_total(snapshot)
	_assert_eq(str(snapshot.get("phase", "")), "node_select", "clearing the first run advances to the next run's node select")
	_assert_eq(int(snapshot.get("runIndex", -1)), 1, "second run starts after first run final stage")
	_assert_eq(int(snapshot.get("stageIndex", -1)), 0, "second run still uses local stage one routing")
	_assert(final_stage_total > first_stage_total, "first run final stage is harder than first run stage one")
	_assert(second_run_total > final_stage_total, "second run stage one continues beyond first run final-stage durability")

# 실행: verify common duplicate drill rewards fuse into a stronger rare artifact.
func test_duplicate_common_reward_only_fuses_on_exact_grid_overlap() -> void:
	var fusion_script = _load_item_fusion_script()
	if fusion_script == null:
		return
	_assert(fusion_script.has_method("try_fuse_exact_overlap"), "ItemFusion exposes exact-overlap fusion API")
	if not fusion_script.has_method("try_fuse_exact_overlap"):
		return
	var reward := _reward_fixture("reward_common_red_drill_a", "Crimson Ember Bit", "common", "drill", "red")
	reward["payload"]["base_cooldown_ticks"] = 105
	reward["payload"]["damage"] = 3.6
	var first_art = CreateArtifactFromRewardScript.create(reward).get("artifact")
	var second_art = CreateArtifactFromRewardScript.create(reward).get("artifact")
	first_art.id = "red_drill_first"
	second_art.id = "red_drill_second"
	var before_damage := float(first_art.damage)
	var before_cooldown := int(first_art.base_cooldown_ticks)
	var inventory = InventoryModelScript.new(4, 4)
	_assert(inventory.place_artifact(first_art, 0, 0), "first common drill reward is placeable before fusion")
	var offset_result: Dictionary = fusion_script.try_fuse_exact_overlap(inventory, second_art, 1, 0)
	_assert(not bool(offset_result.get("ok", true)), "duplicate common drill does not fuse when placed on a different grid origin")
	_assert_eq(str(offset_result.get("code", "")), "no_exact_overlap", "offset duplicate fusion reports exact-overlap miss")
	_assert_eq(inventory.artifacts.size(), 1, "failed offset fusion does not mutate inventory")
	var result: Dictionary = fusion_script.try_fuse_exact_overlap(inventory, second_art, 0, 0)
	_assert(bool(result.get("ok", false)), "duplicate common drill reward fuses on exact grid overlap")
	var fused = result.get("artifact", null)
	_assert(fused != null, "drill fusion returns the fused artifact")
	if fused == null:
		return
	_assert_eq(str(fused.grade), "rare", "common duplicate drill advances to rare")
	_assert(float(fused.damage) > before_damage, "fused drill gains damage")
	_assert(int(fused.base_cooldown_ticks) < before_cooldown, "fused drill gains cooldown performance")
	_assert_eq(inventory.artifacts.size(), 1, "fusion consumes two duplicate drills into one artifact")
	_assert_eq(int(fused.x), 0, "fused drill remains at the overlapped grid x")
	_assert_eq(int(fused.y), 0, "fused drill remains at the overlapped grid y")

func test_fusion_uses_both_material_roll_values_without_extra_randomness() -> void:
	var fusion_script = _load_item_fusion_script()
	if fusion_script == null:
		return
	var base := _rolled_drill("base_roll", 2.0, 100, 20)
	var incoming_low := _rolled_drill("incoming_low", 1.0, 120, 10)
	var incoming_high := _rolled_drill("incoming_high", 5.0, 70, 90)
	var low_material_fused = fusion_script.fuse_pair(base, incoming_low)
	var high_material_fused = fusion_script.fuse_pair(base, incoming_high)
	var high_material_repeat = fusion_script.fuse_pair(base, incoming_high)
	_assert(float(high_material_fused.damage) > float(low_material_fused.damage), "higher incoming roll contributes to fused damage")
	_assert(int(high_material_fused.base_cooldown_ticks) < int(low_material_fused.base_cooldown_ticks), "higher incoming roll contributes to fused cooldown")
	_assert_eq(float(high_material_repeat.damage), float(high_material_fused.damage), "fusion repeats deterministically without a new random damage roll")
	_assert_eq(int(high_material_repeat.base_cooldown_ticks), int(high_material_fused.base_cooldown_ticks), "fusion repeats deterministically without a new random cooldown roll")
	_assert_eq(int(low_material_fused.to_dict().get("rollQuality", -1)), 20, "low material does not add rescue progress over the base roll quality")
	_assert_eq(int(high_material_fused.to_dict().get("rollQuality", -1)), 90, "high material quality is preserved when it supplies the better fused values")

# 실행: verify duplicate beacon rewards use the same fusion API and improve beacon stats.
func test_same_name_same_grade_drills_can_be_placed_separately() -> void:
	var reward := _reward_fixture("reward_common_red_drill_a", "Crimson Ember Bit", "common", "drill", "red")
	var first_art = CreateArtifactFromRewardScript.create(reward).get("artifact")
	var second_art = CreateArtifactFromRewardScript.create(reward).get("artifact")
	first_art.id = "coexist_first"
	second_art.id = "coexist_second"
	var inventory = InventoryModelScript.new(4, 4)
	_assert(inventory.place_artifact(first_art, 0, 0), "first same-name drill can be placed")
	_assert(inventory.can_place_artifact(second_art, 1, 0), "same-name same-grade drill is placeable at a different grid coordinate")
	_assert(inventory.place_artifact(second_art, 1, 0), "same-name same-grade drill placement succeeds at a different coordinate")
	_assert_eq(inventory.artifacts.size(), 2, "two same-name same-grade drills coexist in the backpack")

func test_invalid_placement_requests_five_second_toast() -> void:
	var controller := FakeRewardBackpackController.new()
	var occupying := ArtifactScript.new({"id": "occupying", "name": "Blocking Relic", "shape": [[1]], "item_type": "relic", "grade": "common"})
	var held := ArtifactScript.new({"id": "held", "name": "Held Relic", "shape": [[1]], "item_type": "relic", "grade": "common"})
	_assert(controller.inventory.place_artifact(occupying, 0, 0), "blocking artifact is placed for invalid placement contract")
	controller.held_artifact = held
	var placed := MainControllerRewardBackpackFlowScript.place_held_artifact_at(controller, Vector2(0, 0))
	_assert(not placed, "occupied target placement fails")
	_assert_eq(controller.view.info_toasts.size(), 1, "invalid placement requests exactly one info toast")
	if not controller.view.info_toasts.is_empty():
		_assert_eq(str(controller.view.info_toasts[0].get("message", "")), TextCatalogScript.t("log.inventory.invalid_placement"), "invalid placement toast uses the localized placement warning")
		_assert(absf(float(controller.view.info_toasts[0].get("duration", 0.0)) - 5.0) <= 0.01, "invalid placement toast lasts 5 seconds")

func test_discard_requires_confirmation_before_reward_deletion() -> void:
	var controller := FakeRewardBackpackController.new()
	var reward := _reward_fixture("reward_common_blue_beacon_a", "Azure Coolant Post", "common", "beacon", "blue")
	var held = CreateArtifactFromRewardScript.create(reward).get("artifact")
	controller.local_rewards_list = [reward.duplicate(true)]
	controller.preview_controller.run.state["pendingRewards"] = controller.local_rewards_list.duplicate(true)
	controller.held_artifact = held
	controller.held_from_rewards = true
	controller.held_reward_index = 0
	MainControllerRewardBackpackFlowScript.on_reward_meta_discard_requested_v2(controller, 0)
	_assert_eq(controller.local_rewards_list.size(), 1, "discard request does not delete reward before confirmation")
	_assert_eq(controller.view.discard_prompts.size(), 1, "discard request opens a warning confirmation")
	_assert(not controller.pending_discard_request.is_empty(), "discard request records pending confirmation context")
	var flow = MainControllerRewardBackpackFlowScript.new()
	_assert(flow.has_method("confirm_pending_discard"), "reward/backpack flow exposes confirmed discard handler")
	if not flow.has_method("confirm_pending_discard"):
		return
	flow.call("confirm_pending_discard", controller)
	_assert_eq(controller.local_rewards_list.size(), 0, "confirmed discard deletes the reward")
	_assert(controller.pending_discard_request.is_empty(), "confirmed discard clears pending confirmation context")

func test_reward_visual_id_survives_artifact_creation_and_fusion() -> void:
	var fusion_script = _load_item_fusion_script()
	if fusion_script == null:
		return
	var reward := _reward_fixture("reward_common_red_drill_a", "Crimson Ember Bit", "common", "drill", "red")
	reward["presentation"]["icon"] = "drill_red_common"
	var first_art = CreateArtifactFromRewardScript.create(reward).get("artifact")
	var second_art = CreateArtifactFromRewardScript.create(reward).get("artifact")
	_assert(first_art != null, "reward creates the first visual-id artifact")
	_assert(second_art != null, "reward creates the second visual-id artifact")
	if first_art == null or second_art == null:
		return
	_assert_eq(str(first_art.to_dict().get("visualId", "")), "drill_red_common", "reward artifact stores the reward presentation icon as its visual id")
	first_art.id = "visual_red_first"
	second_art.id = "visual_red_second"
	var inventory = InventoryModelScript.new(4, 4)
	_assert(inventory.place_artifact(first_art, 0, 0), "first visual-id artifact is placeable before fusion")
	var result: Dictionary = fusion_script.try_fuse_exact_overlap(inventory, second_art, 0, 0)
	_assert(bool(result.get("ok", false)), "visual-id duplicate reward fuses")
	var fused = result.get("artifact", null)
	_assert(fused != null, "visual-id fusion returns an artifact")
	if fused == null:
		return
	_assert_eq(str(fused.grade), "rare", "visual-id fusion still upgrades rarity")
	_assert_eq(str(fused.to_dict().get("visualId", "")), "drill_red_common", "fused artifact keeps the base item visual id")

func test_duplicate_common_beacon_fusion_strengthens_beacon_stats() -> void:
	var fusion_script = _load_item_fusion_script()
	if fusion_script == null:
		return
	_assert(fusion_script.has_method("try_fuse_exact_overlap"), "ItemFusion exposes exact-overlap fusion API for beacon fusion")
	if not fusion_script.has_method("try_fuse_exact_overlap"):
		return
	var reward := _reward_fixture("reward_common_blue_beacon_a", "Azure Coolant Post", "common", "beacon", "blue")
	reward["payload"]["base_cooldown_ticks"] = 86
	reward["payload"]["beacon_cooldown_mod"] = -2
	reward["payload"]["beacon_damage_mod"] = 0.1
	var first_art = CreateArtifactFromRewardScript.create(reward).get("artifact")
	var second_art = CreateArtifactFromRewardScript.create(reward).get("artifact")
	first_art.id = "blue_beacon_first"
	second_art.id = "blue_beacon_second"
	var before_cooldown_mod := int(first_art.beacon_cooldown_mod)
	var before_damage_mod := float(first_art.beacon_damage_mod)
	var inventory = InventoryModelScript.new(4, 4)
	_assert(inventory.place_artifact(first_art, 0, 0), "first common beacon reward is placeable before fusion")
	var result: Dictionary = fusion_script.try_fuse_exact_overlap(inventory, second_art, 0, 0)
	_assert(bool(result.get("ok", false)), "duplicate common beacon reward fuses")
	var fused = result.get("artifact", null)
	_assert(fused != null, "beacon fusion returns the fused artifact")
	if fused == null:
		return
	_assert_eq(str(fused.grade), "rare", "common duplicate beacon advances to rare")
	_assert(int(fused.beacon_cooldown_mod) < before_cooldown_mod, "fused beacon improves cooldown pulse strength")
	_assert(float(fused.beacon_damage_mod) > before_damage_mod, "fused beacon improves damage support")

# 실행: verify epic inputs still fuse once, while legendary and above remain excluded.
func test_epic_duplicate_fuses_to_legendary_but_legendary_does_not_fuse() -> void:
	var fusion_script = _load_item_fusion_script()
	if fusion_script == null:
		return
	_assert(fusion_script.has_method("try_fuse_exact_overlap"), "ItemFusion exposes exact-overlap fusion API for epic fusion")
	if not fusion_script.has_method("try_fuse_exact_overlap"):
		return
	var epic_reward := _reward_fixture("reward_epic_green_drill_1", "Verdant Anchor Thorn", "epic", "drill", "green")
	epic_reward["payload"]["base_cooldown_ticks"] = 82
	epic_reward["payload"]["damage"] = 7.4
	var inventory = InventoryModelScript.new(5, 5)
	var first_epic = CreateArtifactFromRewardScript.create(epic_reward).get("artifact")
	var second_epic = CreateArtifactFromRewardScript.create(epic_reward).get("artifact")
	first_epic.id = "green_epic_first"
	second_epic.id = "green_epic_second"
	_assert(inventory.place_artifact(first_epic, 0, 0), "first epic reward is placeable before fusion")
	var epic_result: Dictionary = fusion_script.try_fuse_exact_overlap(inventory, second_epic, 0, 0)
	_assert(bool(epic_result.get("ok", false)), "duplicate epic reward still fuses")
	_assert_eq(str(epic_result.get("artifact", first_epic).grade), "legendary", "epic duplicate advances to legendary")
	var legendary_clone = CreateArtifactFromRewardScript.create(_reward_fixture("reward_legendary_green_drill_1", "Verdant Crown Bore", "legendary", "drill", "green")).get("artifact")
	legendary_clone.id = "green_legendary_clone"
	var no_fuse: Dictionary = fusion_script.try_fuse_exact_overlap(inventory, legendary_clone, 0, 0)
	_assert(not bool(no_fuse.get("ok", false)), "legendary duplicate input does not fuse")
	_assert_eq(str(no_fuse.get("code", "")), "not_fusible_rarity", "legendary fusion reports the excluded rarity")

# 실행: run a simple deterministic stage-one autoplay against production starter stats.
func _autoplay_first_stage(color: String) -> Dictionary:
	var run = HeadlessMiniRunScript.new({
		"seed": 7101,
		"maxStages": 3,
		"candidateCount": 1,
		"startColor": color,
		"nodeTable": _normal_only_node_table()
	})
	var snapshot: Dictionary = run.select_node(0)
	var shots := 0
	var elapsed := 0
	for _step in range(200):
		if str(snapshot.get("phase", "")) == "reward_loot":
			return {"cleared": true, "elapsedTicks": elapsed, "shots": shots}
		var combat: Dictionary = snapshot.get("combat", {})
		if str(combat.get("result", "")) in ["failed", "time_over"]:
			return {"cleared": false, "elapsedTicks": int(combat.get("elapsedTicks", elapsed)), "shots": shots}
		elapsed = int(combat.get("elapsedTicks", elapsed))
		if elapsed > FIRST_STAGE_EASY_TICK_BUDGET:
			return {"cleared": false, "elapsedTicks": elapsed, "shots": shots}
		var queue: Array = combat.get("queue", {}).get("items", [])
		var repair: Dictionary = combat.get("repair", {})
		if not queue.is_empty() and not bool(repair.get("active", false)):
			var energy_color := _queue_item_color(queue[0])
			var target_cell := _marker_cell_for_color(combat, energy_color)
			snapshot = run.apply_combat_input({"type": "fire", "targetCellId": target_cell, "targetColor": energy_color})
			shots += 1
		else:
			snapshot = run.apply_combat_input({"type": "tick", "ticks": 10})
	return {"cleared": false, "elapsedTicks": elapsed, "shots": shots}

# 실행: build a safe normal-only node table with hazards disabled for clean balance checks.
func _normal_only_node_table() -> Dictionary:
	return {
		"nodes": [
			{
				"id": "normal",
				"label": "Safe Scar",
				"nodeType": "normal",
				"riskTier": "safe",
				"weakness": [],
				"pickWeight": 1,
				"shieldMul": 1.0,
				"healthMul": 1.0,
				"alwaysOffer": true,
				"rewardBias": "baseline",
				"recommendedBuildHint": "Any stable drill line",
				"difficultyModifier": 1.0,
				"rewardModifier": 1.0,
				"hazardModifier": 0.0,
				"hazardSpawn": {"chance": 0.0, "maxPerShift": 0, "maxInitialSpawns": 0}
			}
		]
	}

# 실행: create a small reward dictionary with a stable catalog identity.
func _rolled_drill(id: String, damage: float, cooldown: int, roll_quality: int) -> Artifact:
	return ArtifactScript.new({
		"id": id,
		"name": "Roll Probe",
		"shape": [[1]],
		"energyType": "red",
		"item_type": "drill",
		"grade": "common",
		"catalogId": "roll_probe",
		"fusionKey": "roll_probe",
		"baseCooldownTicks": cooldown,
		"nativeBaseCooldownTicks": cooldown,
		"damage": damage,
		"rollQuality": roll_quality,
		"statRoll": {"quality": roll_quality}
	})

func _reward_fixture(catalog_id: String, kind: String, rarity: String, item_type: String, color: String) -> Dictionary:
	return {
		"rewardId": "%s_offer" % catalog_id,
		"catalogId": catalog_id,
		"kind": kind,
		"rarity": rarity,
		"payload": {
			"item_type": item_type,
			"energy_type": color,
			"shape": [[1]],
			"base_cooldown_ticks": 90,
			"damage": 2.0,
			"beacon_cooldown_mod": -1,
			"beacon_damage_mod": 0.1,
			"synergy": {"type": "same_color", "value": 2}
		},
		"presentation": {"description": kind},
		"text": {"name": {"ko": kind, "en": kind}, "description": {"ko": kind, "en": kind}}
	}

func _load_item_fusion_script():
	var script = load("res://src/vocabulary/reward/ItemFusion.gd")
	_assert(script != null, "ItemFusion reward vocabulary exists")
	return script

func _queue_item_color(item: Variant) -> String:
	if item is Dictionary:
		return str(item.get("color", item.get("energy", "")))
	return str(item)

func _marker_cell_for_color(combat: Dictionary, color: String) -> String:
	for marker in combat.get("battlefield", {}).get("weaknessMarkers", []):
		if marker is Dictionary and str(marker.get("color", "")) == color:
			return str(marker.get("cellId", "r0c0"))
	return "r0c0"

func _candidate_total(snapshot: Dictionary) -> float:
	var candidates: Array = snapshot.get("candidates", [])
	if candidates.is_empty():
		return -1.0
	var combat: Dictionary = (candidates[0] as Dictionary).get("combat", {})
	return float(combat.get("shield", 0.0)) + float(combat.get("health", 0.0))

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		failures.append(msg)

func _assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])
