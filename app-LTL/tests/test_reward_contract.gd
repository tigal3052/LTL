# 계약:
# - 책임: M3 보상 및 진행 상태 계약(데이터 결정론, 스키마 유효성 검증, 상점/재화 전이 및 변경자 반환 등)을 헤드리스 유닛 테스트로 검증한다.
# - 입력: RewardVocab, RewardValidator, RunGrowthState, RewardLootPhase API.
# - 출력: 개별 테스트 통과 여부 및 실패 메시지 배열.
# - 금지: SceneTree 활성 노드 직접 변형.
#
# 실행: define the TestRewardContract class.
extends RefCounted
const RewardVocabScript = preload("res://src/vocabulary/RewardVocab.gd")
const RewardValidatorScript = preload("res://src/validation/RewardValidator.gd")
const RunGrowthStateScript = preload("res://src/models/RunGrowthState.gd")
const RewardLootPhaseScript = preload("res://src/phases/RewardLootPhase.gd")
const CreateArtifactFromRewardScript = preload("res://src/vocabulary/reward/CreateArtifactFromReward.gd")
const ApplyRewardEffectScript = preload("res://src/vocabulary/reward/ApplyRewardEffect.gd")
const ApplyGrowthModifiersScript = preload("res://src/vocabulary/progression/ApplyGrowthModifiers.gd")
const ArtifactCodexReadModelScript = preload("res://src/ui/read_models/ArtifactCodexReadModel.gd")
const ArtifactCodexArtResolverScript = preload("res://src/ui/ArtifactCodexArtResolver.gd")
var failures: Array[String] = []
# 실행: run all unit tests for rewards and progression.
func run_all_tests() -> Dictionary:
	failures.clear()
	test_seed_determinism()
	test_validator()
	test_reward_database_cross_validation()
	test_reward_count_tuning()
	test_reward_offer_metadata_and_preview()
	test_reward_pool_has_drills_and_beacons_per_rolled_rarity()
	test_reward_table_has_balanced_expanded_artifact_pool()
	test_reward_table_includes_launch_relic_slice()
	test_reward_table_uses_beacon_heavy_type_distribution()
	test_common_and_rare_drill_shapes_match_drill_art()
	test_requested_epic_and_mythic_drill_shapes_match_backpack_footprints()
	test_requested_relay_beacons_are_common_single_cell()
	test_reward_table_uses_localized_text_contract()
	test_reward_table_korean_localized_text_is_readable()
	test_epic_plus_rewards_define_special_effect_schema()
	test_reward_type_mix_does_not_inject_cross_rarity_beacons()
	test_reward_type_ratio_prefers_beacons()
	test_reward_roll_can_offer_mythic()
	test_reward_read_model_hides_private_offer_metadata()
	test_reward_telemetry_payloads()
	test_reward_table_authoring_order_matches_codex_contract()
	test_growth_state_updates()
	test_apply_reward_effect_records_artifact_discovery()
	test_artifact_codex_projects_discovered_and_debug_entries()
	test_artifact_codex_projects_book_sections_selection_and_art_descriptors()
	test_artifact_codex_drill_descriptor_prefers_raw_common_rare_png()
	test_artifact_codex_beacon_descriptor_prefers_raw_item_png()
	test_artifact_codex_drill_descriptor_resolves_new_epic_legendary_item_pngs()
	test_artifact_codex_selection_normalizes_when_filtered_out()
	test_artifact_codex_sorts_entries_by_rarity_color_type_name()
	test_reward_artifact_creation_vocab()
	test_apply_reward_effect_vocab()
	test_apply_growth_modifiers_vocab()
	test_passive_purchase()
	test_passive_modifiers()
	return {"ok": failures.is_empty(), "errors": failures}
func _project_artifact_codex(
	table: Dictionary,
	growth_state: Dictionary,
	debug_all: bool = false,
	locale := "",
	selected_entry_id := "",
	active_section := "all"
) -> Dictionary:
	var read_model_script = load("res://src/ui/read_models/ArtifactCodexReadModel.gd")
	_assert(read_model_script != null, "artifact codex read model loads dynamically")
	if read_model_script == null:
		return {}
	return read_model_script.project(table, growth_state, debug_all, locale, selected_entry_id, active_section)
func _load_reward_catalog_order_script():
	var order_script = load("res://src/vocabulary/reward/RewardCatalogOrder.gd")
	_assert(order_script != null, "reward catalog order helper loads dynamically")
	return order_script
func _assert(condition: bool, msg: String) -> void:
	if not condition:
		failures.append(msg)
func _assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])
# 실행: verify seed-based determinism yields exact same rewards.
func _load_reward_table_fixture() -> Dictionary:
	var file := FileAccess.open("res://src/data/reward-table.json", FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		return {}
	var data = json.get_data()
	return data if data is Dictionary else {}
func test_seed_determinism() -> void:
	var seed_val := 777
	var stage_idx := 2
	var weaknesses := ["red", "blue"]
	var tuning := {}
	var roll1 = RewardVocabScript.roll_stage_rewards(seed_val, stage_idx, weaknesses, tuning)
	var roll2 = RewardVocabScript.roll_stage_rewards(seed_val, stage_idx, weaknesses, tuning)
	var roll3 = RewardVocabScript.roll_stage_rewards(seed_val, stage_idx + 1, weaknesses, tuning)
	_assert_eq(roll1.size(), roll2.size(), "determinisim: counts match")
	for i in range(roll1.size()):
		_assert_eq(roll1[i]["rewardId"], roll2[i]["rewardId"], "determinism: rewardId match")
		_assert_eq(roll1[i]["kind"], roll2[i]["kind"], "determinism: kind match")
		_assert_eq(roll1[i]["rarity"], roll2[i]["rarity"], "determinism: rarity match")
	# Ensure different stage index yields different rewards or at least different ids
	if roll1.size() > 0 and roll3.size() > 0:
		_assert(roll1[0]["rewardId"] != roll3[0]["rewardId"], "different stage gives different ids")
# 실행: verify validation constraints for rewards, rarities, and states.
func test_validator() -> void:
	# Correct table
	var good_reward_table = {
		"rewards": [
			{
				"id": "item1",
				"kind": "Gold Core",
				"rarity": "legendary",
				"weight": 10,
				"payload": {},
				"presentation": {"badge": "즉시"},
				"tags": []
			}
		]
	}
	var res1 = RewardValidatorScript.validate_reward_table(good_reward_table)
	_assert(res1["ok"], "validator accepts valid reward table")
	# Bad reward table
	var bad_reward_table = {
		"rewards": [
			{
				"kind": "Missing ID"
			}
		]
	}
	var res2 = RewardValidatorScript.validate_reward_table(bad_reward_table)
	_assert(not res2["ok"], "validator rejects table with missing fields")
	# Correct rarity table
	var good_rarity_table = {
		"rarities": [
			{
				"id": "common",
				"label": "Common",
				"weightMul": 1.0,
				"presentationTier": "tier_1"
			}
		]
	}
	var res3 = RewardValidatorScript.validate_rarity_table(good_rarity_table)
	_assert(res3["ok"], "validator accepts valid rarity table")
	# Bad growth state
	var bad_growth_state = {
		"gold": 100
	}
	var res4 = RewardValidatorScript.validate_growth_state(bad_growth_state)
	_assert(not res4["ok"], "validator rejects incomplete growth state")
# 실행: verify reward and rarity tables are cross-validated together.
func test_reward_database_cross_validation() -> void:
	var rarity_table = {
		"rarities": [
			{"id": "common", "label": "Common", "weightMul": 1.0, "presentationTier": "tier_1"}
		]
	}
	var bad_reward_table = {
		"rewards": [
			{
				"id": "bad_unknown_rarity",
				"kind": "Bad Unknown",
				"rarity": "void",
				"weight": 10,
				"payload": {},
				"presentation": {"badge": "안정"},
				"tags": []
			},
			{
				"id": "bad_weight",
				"kind": "Bad Weight",
				"rarity": "common",
				"weight": 0,
				"payload": {},
				"presentation": {"badge": "안정"},
				"tags": []
			}
		]
	}
	var validator = RewardValidatorScript.new()
	_assert(validator.has_method("validate_reward_database"), "cross validator API exists")
	if not validator.has_method("validate_reward_database"):
		return
	var result = validator.call("validate_reward_database", bad_reward_table, rarity_table)
	_assert(not result["ok"], "cross validator rejects unknown rarity and non-positive weight")
	var codes := []
	for error in result["errors"]:
		codes.append(error.get("code", ""))
	_assert(codes.has("unknown_rarity"), "cross validator reports unknown rarity")
	_assert(codes.has("positive_weight_required"), "cross validator reports non-positive weight")
# 실행: verify reward roll count is bounded between 1 and 5.
func test_reward_count_tuning() -> void:
	for s in range(1, 20):
		var rolls = RewardVocabScript.roll_stage_rewards(s, 0, [], {})
		_assert(rolls.size() >= 2 and rolls.size() <= 5, "roll count bound to [2, 5]")
# 실행: verify reward offers carry deterministic private metadata and public preview.
func test_reward_offer_metadata_and_preview() -> void:
	var roll1 = RewardVocabScript.roll_stage_rewards(31337, 2, ["red"], {})
	var roll2 = RewardVocabScript.roll_stage_rewards(31337, 2, ["red"], {})
	_assert(roll1.size() > 0, "reward offer metadata sample has rewards")
	_assert_eq(roll1[0].get("offer_weights_hash", ""), roll2[0].get("offer_weights_hash", ""), "offer weights hash is deterministic")
	_assert(str(roll1[0].get("offer_weights_hash", "")).length() >= 8, "offer weights hash is present")
	_assert(roll1[0].has("next_combat_modifier_preview"), "reward includes next combat modifier preview")
	_assert(roll1[0].get("next_combat_modifier_preview", {}) is Dictionary, "reward preview is dictionary")
# 실행: verify reward type weighting favors beacons at roughly 40:60 drill/beacon.
func test_reward_pool_has_drills_and_beacons_per_rolled_rarity() -> void:
	var table := _load_reward_table_fixture()
	var rarities := ["common", "rare", "epic", "legendary", "mythic"]
	for rarity in rarities:
		var has_drill := false
		var has_beacon := false
		var has_relic := false
		for item in table.get("rewards", []):
			if str(item.get("rarity", "")).to_lower() != rarity:
				continue
			var item_type := str(item.get("payload", {}).get("item_type", "drill")).to_lower()
			if item_type == "beacon":
				has_beacon = true
			elif item_type == "relic":
				has_relic = true
			else:
				has_drill = true
		_assert(has_drill, "%s reward pool has drill-like candidates" % rarity)
		_assert(has_beacon, "%s reward pool has beacon candidates" % rarity)
		if rarity in ["common", "rare", "epic"]:
			_assert(has_relic, "%s reward pool has relic candidates" % rarity)
# 실행: verify the expanded artifact table has the requested rarity and color distribution.
func test_reward_table_has_balanced_expanded_artifact_pool() -> void:
	var table := _load_reward_table_fixture()
	var rewards: Array = table.get("rewards", [])
	var expected_counts := {"common": 15, "rare": 14, "epic": 18, "legendary": 13, "mythic": 8}
	var expected_color_counts := {
		"common": {"red": 3, "blue": 2, "purple": 3, "green": 2},
		"rare": {"red": 2, "blue": 3, "purple": 2, "green": 3},
		"epic": {"red": 4, "blue": 4, "purple": 4, "green": 4},
		"legendary": {"red": 3, "blue": 3, "purple": 3, "green": 3},
		"mythic": {"red": 2, "blue": 2, "purple": 2, "green": 2}
	}
	var seen_ids := {}
	var counts := {}
	var color_counts := {}
	for rarity in expected_counts.keys():
		counts[rarity] = 0
		color_counts[rarity] = {"red": 0, "blue": 0, "purple": 0, "green": 0}
	_assert_eq(rewards.size(), 68, "expanded reward table has exactly 68 artifacts")
	for i in range(rewards.size()):
		var reward: Dictionary = rewards[i]
		var reward_id := str(reward.get("id", ""))
		var rarity := str(reward.get("rarity", ""))
		var payload: Dictionary = reward.get("payload", {})
		var item_type := str(payload.get("item_type", "drill")).to_lower()
		var color := str(payload.get("energy_type", ""))
		_assert(not reward_id.is_empty(), "reward id is non-empty at index %d" % i)
		_assert(not seen_ids.has(reward_id), "reward id is unique: %s" % reward_id)
		seen_ids[reward_id] = true
		_assert(expected_counts.has(rarity), "reward rarity is allowed: %s" % rarity)
		_assert(item_type in ["drill", "beacon", "relic"], "reward item_type is allowed: %s" % item_type)
		if item_type == "relic":
			_assert_eq(color, "", "%s relic reward stays colorless" % reward_id)
		else:
			_assert(color in ["red", "blue", "purple", "green"], "reward color is allowed: %s" % color)
		_assert(payload.has("item_type"), "reward payload explicitly declares item_type: %s" % reward_id)
		_assert(_shape_is_valid(payload.get("shape", [])), "reward payload has valid shape: %s" % reward_id)
		if expected_counts.has(rarity):
			counts[rarity] = int(counts[rarity]) + 1
			if item_type != "relic":
				color_counts[rarity][color] = int(color_counts[rarity].get(color, 0)) + 1
	for rarity in expected_counts.keys():
		_assert_eq(int(counts[rarity]), int(expected_counts[rarity]), "%s reward count matches expanded pool" % rarity)
		for color in ["red", "blue", "purple", "green"]:
			_assert_eq(int(color_counts[rarity][color]), int(expected_color_counts[rarity][color]), "%s %s count matches requested distribution" % [rarity, color])
func test_reward_table_includes_launch_relic_slice() -> void:
	var table := _load_reward_table_fixture()
	var expected_launch := {
		"reward_common_relic_breach_seal": {"kind": "Breach Seal", "rarity": "common", "link_mode": "diagonal_1"},
		"reward_common_relic_warning_bell": {"kind": "Warning Bell", "rarity": "common"},
		"reward_common_relic_spare_fuse": {"kind": "Spare Fuse", "rarity": "common"},
		"reward_legendary_relic_brake_coil": {"kind": "Brake Coil", "rarity": "legendary"},
		"reward_common_relic_tool_rack": {"kind": "Tool Rack", "rarity": "common", "link_mode": "diagonal_1"},
		"reward_common_relic_repair_coil": {"kind": "Repair Coil", "rarity": "common", "link_mode": "diagonal_1"},
		"reward_rare_relic_pinbreaker_spring": {"kind": "Pinbreaker Spring", "rarity": "rare", "link_mode": "diagonal_1"},
		"reward_epic_relic_anchor_oathplate": {"kind": "Anchor Oathplate", "rarity": "epic"},
		"reward_rare_relic_sealant_patch": {"kind": "Sealant Patch", "rarity": "rare"},
		"reward_rare_relic_debris_chalk": {"kind": "Debris Chalk", "rarity": "rare"},
		"reward_rare_relic_counterflow_governor": {"kind": "Counterflow Governor", "rarity": "rare"},
		"reward_epic_relic_recovery_winch": {"kind": "Recovery Winch", "rarity": "epic"}
	}
	var found := {}
	for reward in table.get("rewards", []):
		var reward_id := str(reward.get("id", ""))
		if not expected_launch.has(reward_id):
			continue
		found[reward_id] = true
		var payload: Dictionary = reward.get("payload", {})
		var schema: Dictionary = payload.get("effect_schema", {})
		var expected: Dictionary = expected_launch[reward_id]
		_assert_eq(str(reward.get("kind", "")), str(expected.get("kind", "")), "%s launch relic keeps approved name" % reward_id)
		_assert_eq(str(reward.get("rarity", "")).to_lower(), str(expected.get("rarity", "")), "%s launch relic keeps approved rarity" % reward_id)
		_assert_eq(str(payload.get("item_type", "")).to_lower(), "relic", "%s launch reward declares relic item type" % reward_id)
		_assert_eq(str(payload.get("energy_type", "")), "", "%s launch relic stays colorless" % reward_id)
		_assert(_shape_is_valid(payload.get("shape", [])), "%s launch relic keeps a placeable shape" % reward_id)
		_assert_eq(int(schema.get("version", 0)), 1, "%s launch relic schema version" % reward_id)
		if expected.has("link_mode"):
			_assert_eq(str(schema.get("link_mode", "")), str(expected.get("link_mode", "")), "%s launch relic uses approved link mode" % reward_id)
		else:
			_assert_eq(str(schema.get("link_mode", "")), "", "%s launch relic does not require a link mode" % reward_id)
		_assert(str(schema.get("trigger", "")).length() > 0, "%s launch relic schema trigger exists" % reward_id)
		_assert(str(schema.get("type", "")).length() > 0, "%s launch relic schema type exists" % reward_id)
		_assert(_localized_pair_is_valid(reward.get("text", {}).get("name", {})), "%s launch relic has localized name text" % reward_id)
		_assert(_localized_pair_is_valid(reward.get("text", {}).get("description", {})), "%s launch relic has localized description text" % reward_id)
		_assert(_localized_pair_is_valid(schema.get("summary_i18n", {})), "%s launch relic has localized summary text" % reward_id)
	for reward_id in expected_launch.keys():
		_assert(found.has(reward_id), "launch relic is present in reward table: %s" % reward_id)
# 실행: verify hero-or-higher rewards carry explicit special mechanics beyond flat stats.
func test_reward_table_uses_beacon_heavy_type_distribution() -> void:
	var table := _load_reward_table_fixture()
	var expected_type_counts := {
		"common": {"drill": 4, "beacon": 6, "relic": 5},
		"rare": {"drill": 4, "beacon": 6, "relic": 4},
		"epic": {"drill": 8, "beacon": 8, "relic": 2},
		"legendary": {"drill": 4, "beacon": 8, "relic": 1},
		"mythic": {"drill": 4, "beacon": 4, "relic": 0}
	}
	var total_drills := 0
	var total_beacons := 0
	var total_relics := 0
	for rarity in expected_type_counts.keys():
		var drill_count := 0
		var beacon_count := 0
		var relic_count := 0
		for reward in table.get("rewards", []):
			if str(reward.get("rarity", "")).to_lower() != rarity:
				continue
			var item_type := str(reward.get("payload", {}).get("item_type", "drill")).to_lower()
			if item_type == "beacon":
				beacon_count += 1
			elif item_type == "relic":
				relic_count += 1
			else:
				drill_count += 1
		total_drills += drill_count
		total_beacons += beacon_count
		total_relics += relic_count
		_assert_eq(drill_count, int(expected_type_counts[rarity]["drill"]), "%s drill count respects one-drill-per-color pressure" % rarity)
		_assert_eq(beacon_count, int(expected_type_counts[rarity]["beacon"]), "%s beacon count gives combinator depth" % rarity)
		_assert_eq(relic_count, int(expected_type_counts[rarity]["relic"]), "%s relic count matches the approved launch slice" % rarity)
	_assert_eq(total_drills, 24, "expanded pool has 24 drill anchors")
	_assert_eq(total_beacons, 32, "expanded pool has 32 beacon combinators")
	_assert_eq(total_relics, 12, "expanded pool has the approved twelve relics")
	_assert(total_beacons > total_drills, "beacon combinators outnumber one-per-color drill anchors")
func test_common_and_rare_drill_shapes_match_drill_art() -> void:
	var table := _load_reward_table_fixture()
	var expected_shapes := {
		"common": [[1]],
		"rare": [[1], [1]]
	}
	var seen := {"common": 0, "rare": 0}
	for reward in table.get("rewards", []):
		var rarity := str((reward as Dictionary).get("rarity", "")).to_lower()
		if not expected_shapes.has(rarity):
			continue
		var payload: Dictionary = (reward as Dictionary).get("payload", {})
		if str(payload.get("item_type", "drill")).to_lower() != "drill":
			continue
		_assert_eq(_normalized_int_shape(payload.get("shape", [])), expected_shapes[rarity], "%s %s drill shape matches drill art footprint" % [str(reward.get("id", "")), rarity])
		seen[rarity] = int(seen.get(rarity, 0)) + 1
	_assert_eq(int(seen["common"]), 4, "common drill pool keeps one drill per color")
	_assert_eq(int(seen["rare"]), 4, "rare drill pool keeps one drill per color")
func test_requested_epic_and_mythic_drill_shapes_match_backpack_footprints() -> void:
	var table := _load_reward_table_fixture()
	var expected_shapes := {
		"reward_epic_purple_drill_1": [[1], [1], [1]],
		"reward_epic_blue_drill_1": [[1, 0], [1, 1]],
		"reward_epic_green_drill_1": [[1, 1], [1, 0]],
		"reward_mythic_purple_drill_1": [[1, 1, 1], [0, 1, 0]],
		"reward_mythic_red_drill_1": [[1, 1, 0], [0, 1, 1]],
		"reward_mythic_blue_drill_1": [[1, 1, 0], [0, 1, 1]],
		"reward_mythic_green_drill_1": [[1, 1, 1], [0, 1, 0]]
	}
	var found := {}
	for reward in table.get("rewards", []):
		var reward_id := str((reward as Dictionary).get("id", ""))
		if not expected_shapes.has(reward_id):
			continue
		var payload: Dictionary = (reward as Dictionary).get("payload", {})
		found[reward_id] = true
		_assert_eq(_normalized_int_shape(payload.get("shape", [])), expected_shapes[reward_id], "%s uses requested backpack footprint" % reward_id)
	for reward_id in expected_shapes.keys():
		_assert(found.has(reward_id), "requested shape reward exists: %s" % reward_id)
func test_requested_relay_beacons_are_common_single_cell() -> void:
	var table := _load_reward_table_fixture()
	var expected_colors := {
		"진홍 스파크 릴레이": "red",
		"보랏빛 베일 릴레이": "purple"
	}
	var found := {}
	for reward in table.get("rewards", []):
		var text: Dictionary = reward.get("text", {})
		var name: Dictionary = text.get("name", {})
		var ko_name := str(name.get("ko", ""))
		if not expected_colors.has(ko_name):
			continue
		found[ko_name] = true
		var payload: Dictionary = reward.get("payload", {})
		_assert_eq(str(reward.get("rarity", "")).to_lower(), "common", "%s beacon uses requested common rarity" % ko_name)
		_assert_eq(str(payload.get("item_type", "")).to_lower(), "beacon", "%s stays a beacon reward" % ko_name)
		_assert_eq(str(payload.get("energy_type", "")).to_lower(), str(expected_colors[ko_name]), "%s keeps its color identity" % ko_name)
		_assert_eq(_normalized_int_shape(payload.get("shape", [])), [[1]], "%s uses requested 1x1 backpack footprint" % ko_name)
	for ko_name in expected_colors.keys():
		_assert(found.has(ko_name), "requested relay beacon exists: %s" % ko_name)
func test_reward_table_uses_localized_text_contract() -> void:
	var table := _load_reward_table_fixture()
	for reward in table.get("rewards", []):
		var reward_id := str(reward.get("id", ""))
		var text: Dictionary = reward.get("text", {})
		_assert(_localized_pair_is_valid(text.get("name", {})), "%s has localized name text" % reward_id)
		_assert(_localized_pair_is_valid(text.get("description", {})), "%s has localized description text" % reward_id)
		var rarity := str(reward.get("rarity", "")).to_lower()
		if rarity in ["epic", "legendary", "mythic"]:
			var schema: Dictionary = reward.get("payload", {}).get("effect_schema", {})
			_assert(_localized_pair_is_valid(schema.get("summary_i18n", {})), "%s has localized effect summary" % reward_id)
func test_reward_table_korean_localized_text_is_readable() -> void:
	var table := _load_reward_table_fixture()
	for reward in table.get("rewards", []):
		var reward_id := str(reward.get("id", ""))
		var text: Dictionary = reward.get("text", {})
		_assert(_korean_localized_value_is_readable(text.get("name", {}).get("ko", "")), "%s Korean reward name is readable" % reward_id)
		_assert(_korean_localized_value_is_readable(text.get("description", {}).get("ko", "")), "%s Korean reward description is readable" % reward_id)
		var rarity := str(reward.get("rarity", "")).to_lower()
		if rarity in ["epic", "legendary", "mythic"]:
			var schema: Dictionary = reward.get("payload", {}).get("effect_schema", {})
			_assert(_korean_localized_value_is_readable(schema.get("summary_i18n", {}).get("ko", "")), "%s Korean effect summary is readable" % reward_id)
func test_epic_plus_rewards_define_special_effect_schema() -> void:
	var table := _load_reward_table_fixture()
	for reward in table.get("rewards", []):
		var rarity := str(reward.get("rarity", "")).to_lower()
		if not rarity in ["epic", "legendary", "mythic"]:
			continue
		var payload: Dictionary = reward.get("payload", {})
		_assert(payload.has("effect_schema"), "%s reward defines effect_schema" % str(reward.get("id", "")))
		var schema: Dictionary = payload.get("effect_schema", {})
		_assert_eq(int(schema.get("version", 0)), 1, "%s effect_schema version" % str(reward.get("id", "")))
		_assert(str(schema.get("trigger", "")).length() > 0, "%s effect_schema trigger exists" % str(reward.get("id", "")))
		_assert(str(schema.get("type", "")).length() > 0, "%s effect_schema type exists" % str(reward.get("id", "")))
		_assert(schema.has("summary"), "%s effect_schema has player-facing summary" % str(reward.get("id", "")))
# 실행: verify missing-type rarity pools are not patched with unrelated rarity items.
func test_reward_type_mix_does_not_inject_cross_rarity_beacons() -> void:
	var common_drill := {
		"id": "common_drill",
		"kind": "Common Drill",
		"rarity": "common",
		"weight": 10,
		"payload": {"energy_type": "red"},
		"presentation": {},
		"tags": []
	}
	var rare_beacon := {
		"id": "rare_beacon",
		"kind": "Rare Beacon",
		"rarity": "rare",
		"weight": 10,
		"payload": {"item_type": "beacon", "energy_type": "blue"},
		"presentation": {},
		"tags": ["beacon"]
	}
	var mixed = RewardVocabScript._with_reward_type_mix([common_drill], [common_drill, rare_beacon])
	_assert_eq(mixed.size(), 1, "type mix keeps rarity-local candidate count")
	_assert_eq(str(mixed[0].get("id", "")), "common_drill", "type mix does not inject rare beacon into common pool")
func test_reward_type_ratio_prefers_beacons() -> void:
	var beacon_count := 0
	var drill_count := 0
	var relic_count := 0
	for s in range(1, 240):
		var rolls = RewardVocabScript.roll_stage_rewards(s, 1, [], {})
		for reward in rolls:
			var item_type := str(reward.get("payload", {}).get("item_type", "drill")).to_lower()
			if item_type == "beacon":
				beacon_count += 1
			elif item_type == "relic":
				relic_count += 1
			else:
				drill_count += 1
	var total := beacon_count + drill_count + relic_count
	_assert(total > 0, "reward ratio sample has data")
	var active_share_total := beacon_count + drill_count
	_assert(active_share_total > 0, "reward ratio sample has active items")
	var beacon_share := float(beacon_count) / float(active_share_total)
	_assert(beacon_count > drill_count, "beacon rewards outnumber drill rewards")
	_assert(relic_count > 0, "relic rewards appear in rolled offers")
	_assert(beacon_share >= 0.50 and beacon_share <= 0.70, "beacon share remains near 60%%, got %.3f" % beacon_share)
func test_reward_roll_can_offer_mythic() -> void:
	var found_mythic := false
	for s in range(1, 800):
		var rolls = RewardVocabScript.roll_stage_rewards(s, 4, ["red", "blue", "purple", "green"], {})
		for reward in rolls:
			if str(reward.get("rarity", "")).to_lower() == "mythic":
				found_mythic = true
				break
		if found_mythic:
			break
	_assert(found_mythic, "stage 4 reward rolls can offer mythic artifacts")
# 실행: verify reward read model hides private roll metadata but exposes player-facing preview.
func test_reward_read_model_hides_private_offer_metadata() -> void:
	var RewardReadModelScript = load("res://src/ui/read_models/RewardReadModel.gd")
	_assert(RewardReadModelScript != null, "reward read model loads for privacy test")
	if RewardReadModelScript == null:
		return
	var projected = RewardReadModelScript.project({
		"rewardId": "reward_private",
		"kind": "Private Test Reward",
		"rarity": "rare",
		"qty": 1,
		"weight": 999,
		"offer_weights_hash": "secret-hash",
		"next_combat_modifier_preview": {"summary": "다음 전투 피해 +1.0"},
		"payload": {"damage_multiplier": 1.2},
		"presentation": {"badge": "위험 보상", "description": "test", "icon": "x"},
		"tags": ["greed_risk"]
	})
	_assert(not projected.has("weight"), "reward read model hides raw weight")
	_assert(not projected.has("offer_weights_hash"), "reward read model hides offer hash")
	_assert_eq(projected.get("nextCombatModifierPreview", {}).get("summary", ""), "다음 전투 피해 +1.0", "reward read model exposes next combat preview")
# 실행: verify M3 reward telemetry payload builders expose required event fields.
func test_reward_telemetry_payloads() -> void:
	var TelemetryScript = load("res://src/vocabulary/reward/BuildRewardTelemetry.gd")
	_assert(TelemetryScript != null, "reward telemetry vocabulary loads")
	if TelemetryScript == null:
		return
	var rewards = [
		{"rewardId": "reward_a", "kind": "A", "rarity": "rare", "offer_weights_hash": "hash-a", "payload": {"energy_type": "red"}, "next_combat_modifier_preview": {"summary": "red faster"}}
	]
	var offer_payload = TelemetryScript.build_offer_generated({"node_id": "node_1", "node_type": "normal"}, rewards)
	_assert_eq(offer_payload.get("event", ""), "reward_offer_generated", "offer telemetry event name")
	_assert_eq(offer_payload.get("node_id", ""), "node_1", "offer telemetry carries node id")
	_assert_eq(offer_payload.get("offer_ids", []), ["reward_a"], "offer telemetry carries offer ids")
	_assert_eq(offer_payload.get("offer_weights_hash", ""), "hash-a", "offer telemetry carries weights hash")
	var selected_payload = TelemetryScript.build_reward_selected({"node_id": "node_1", "node_type": "normal"}, rewards[0], {"gold_delta": 25, "xp_delta": 10, "inventory_diff": {"added": ["artifact_a"]}})
	_assert_eq(selected_payload.get("event", ""), "reward_selected", "selected telemetry event name")
	_assert_eq(selected_payload.get("selected_reward_id", ""), "reward_a", "selected telemetry carries reward id")
	_assert_eq(selected_payload.get("rarity", ""), "rare", "selected telemetry carries rarity")
	_assert_eq(int(selected_payload.get("gold_delta", 0)), 25, "selected telemetry carries gold delta")
	_assert(selected_payload.has("next_combat_modifier_preview"), "selected telemetry carries next combat preview")
func test_reward_table_authoring_order_matches_codex_contract() -> void:
	var table := _load_reward_table_fixture()
	_assert(table.has("rewards"), "reward table fixture parses as strict JSON before ordering assertions")
	var rewards: Array = table.get("rewards", [])
	_assert(rewards.size() > 0, "reward table fixture exposes reward rows for ordering assertions")
	if rewards.is_empty():
		return
	var order_script = _load_reward_catalog_order_script()
	if order_script == null:
		return
	var sorted_rewards: Array = order_script.sort_rewards(rewards)
	var actual_ids := []
	var expected_ids := []
	for reward in rewards:
		actual_ids.append(str((reward as Dictionary).get("id", "")))
	for reward in sorted_rewards:
		expected_ids.append(str((reward as Dictionary).get("id", "")))
	_assert_eq(actual_ids, expected_ids, "reward-table source order matches the codex ordering contract")
# 실행: verify claiming rewards correctly updates gold/xp and history.
func test_growth_state_updates() -> void:
	var state = {
		"seed": 1,
		"phase": "reward_loot",
		"gold": 10,
		"xp": 0,
		"inventory": {},
		"progress": {"clearedLeviathanIds": []},
		"stageIndex": 0,
		"maxStages": 5,
		"runIndex": 0,
		"runCount": 1,
		"lastNodeLabel": "",
		"runComplete": false,
		"failed": false,
		"growth": {
			"gold": 100,
			"xp": 0,
			"purchasedPassives": {},
			"temporaryModifiers": {},
			"runModifiers": {},
			"rewardHistory": []
		}
	}
	var reward_item = {
		"rewardId": "reward_100_0",
		"kind": "Test Epic Drill Core",
		"rarity": "epic",
		"qty": 1
	}
	var next_state = RewardLootPhaseScript.reduce(state, {
		"type": "claim_reward_effect",
		"reward": reward_item
	})
	var growth = next_state.get("growth", {})
	_assert_eq(int(growth.get("gold", 0)), 150, "epic reward grants 50 gold")
	_assert_eq(int(growth.get("xp", 0)), 30, "epic reward grants 30 xp")
	_assert(growth.get("rewardHistory", []).has("reward_100_0"), "rewardId registered in history")
# ?ㅽ뻾: verify reward data converts into an artifact through vocabulary.
func test_apply_reward_effect_records_artifact_discovery() -> void:
	var growth = RunGrowthStateScript.new({"gold": 0, "xp": 0, "purchasedPassives": {}, "temporaryModifiers": {}, "runModifiers": {}, "rewardHistory": [], "artifactDiscovery": []})
	var result = ApplyRewardEffectScript.apply(growth, {"rewardId": "offer_1", "catalogId": "reward_epic_red_beacon_3", "rarity": "epic"})
	_assert(result["ok"], "apply reward effect succeeds for artifact discovery")
	_assert(growth.artifact_discovery.has("reward_epic_red_beacon_3"), "catalog artifact id recorded for codex discovery")
	ApplyRewardEffectScript.apply(growth, {"rewardId": "offer_2", "catalogId": "reward_epic_red_beacon_3", "rarity": "epic"})
	_assert_eq(growth.artifact_discovery.count("reward_epic_red_beacon_3"), 1, "artifact discovery records each catalog id once")
func test_artifact_codex_projects_discovered_and_debug_entries() -> void:
	var table := _load_reward_table_fixture()
	var rewards: Array = table.get("rewards", [])
	_assert(rewards.size() > 1, "codex fixture has rewards")
	if rewards.size() <= 1:
		return
	var discovered_id := str(rewards[0].get("id", ""))
	var normal_model: Dictionary = _project_artifact_codex(table, {"artifactDiscovery": [discovered_id]}, false, "en")
	var debug_model: Dictionary = _project_artifact_codex(table, {"artifactDiscovery": []}, true, "en")
	_assert_eq(int(normal_model.get("totalCount", 0)), 68, "codex knows full artifact count")
	_assert_eq(int(normal_model.get("discoveredCount", 0)), 1, "normal codex counts discovered artifacts")
	_assert(str(normal_model.get("text", "")).contains(str(rewards[0].get("text", {}).get("name", {}).get("en", ""))), "normal codex reveals discovered artifact name")
	_assert(str(normal_model.get("text", "")).contains("Undiscovered artifact"), "normal codex masks undiscovered artifacts")
	_assert_eq(int(debug_model.get("visibleCount", 0)), 68, "debug codex shows every artifact")
	_assert(not str(debug_model.get("text", "")).contains("Undiscovered artifact"), "debug codex reveals all artifact names")
func test_artifact_codex_projects_book_sections_selection_and_art_descriptors() -> void:
	var table := _load_reward_table_fixture()
	var rewards: Array = table.get("rewards", [])
	_assert(rewards.size() > 2, "codex fixture has enough rewards for section coverage")
	if rewards.size() <= 2:
		return
	var selected_id := str(rewards[1].get("id", ""))
	var model: Dictionary = _project_artifact_codex(table, {"artifactDiscovery": [selected_id]}, false, "en", selected_id, "all")
	var sections: Array = model.get("sections", [])
	_assert(sections.size() >= 4, "codex exposes section tabs")
	_assert_eq(str(model.get("resolvedSelectedEntryId", "")), selected_id, "codex preserves visible selected entry")
	_assert(model.has("leftPage"), "codex exposes left page payload")
	_assert(model.has("rightPage"), "codex exposes right page payload")
	var left_page: Dictionary = model.get("leftPage", {})
	_assert(left_page.has("heroArt"), "codex exposes hero art descriptor")
	var hero_art: Dictionary = left_page.get("heroArt", {})
	_assert(hero_art.has("path"), "hero art descriptor exposes a path field")
	_assert(hero_art.has("placeholderId"), "hero art descriptor exposes placeholder id")
	_assert(hero_art.has("state"), "hero art descriptor exposes state")
	var right_page: Dictionary = model.get("rightPage", {})
	_assert(right_page.has("gridEntries"), "codex exposes grid entries for the right page")
func test_artifact_codex_drill_descriptor_prefers_raw_common_rare_png() -> void:
	var common_desc: Dictionary = ArtifactCodexArtResolverScript.descriptor_for_reward({
		"id": "reward_common_red_drill_test",
		"rarity": "common",
		"payload": {"item_type": "drill", "energy_type": "red"},
		"presentation": {"icon": "missing_common_drill_art"}
	}, "thumb", true)
	_assert_eq(str(common_desc.get("path", "")), "res://resources/items/drill/red_drill_common.png", "common red drill art resolves to raw item PNG")
	_assert((common_desc.get("fallbackChain", []) as Array).has("res://resources/items/drill/red_drill_common.png"), "common drill art path is part of the fallback chain")
	var rare_desc: Dictionary = ArtifactCodexArtResolverScript.descriptor_for_reward({
		"id": "reward_rare_blue_drill_test",
		"rarity": "rare",
		"payload": {"item_type": "drill", "energy_type": "blue"},
		"presentation": {"icon": "missing_rare_drill_art"}
	}, "thumb", true)
	_assert_eq(str(rare_desc.get("path", "")), "res://resources/items/drill/blue_drill_rare.png", "rare blue drill art resolves to raw item PNG")
	var beacon_desc: Dictionary = ArtifactCodexArtResolverScript.descriptor_for_reward({
		"id": "reward_common_blue_beacon_test",
		"rarity": "common",
		"payload": {"item_type": "beacon", "energy_type": "blue"},
		"presentation": {"icon": "missing_common_beacon_art"}
	}, "thumb", true)
	_assert(not str(beacon_desc.get("path", "")).begins_with("res://resources/items/drill/"), "non-drill rewards do not inherit drill item PNG fallbacks")

func test_artifact_codex_beacon_descriptor_prefers_raw_item_png() -> void:
	var common_desc: Dictionary = ArtifactCodexArtResolverScript.descriptor_for_reward({
		"id": "reward_common_blue_beacon_test",
		"rarity": "common",
		"payload": {"item_type": "beacon", "energy_type": "blue"},
		"presentation": {"icon": "beacon_blue_common"}
	}, "thumb", true)
	_assert_eq(str(common_desc.get("path", "")), "res://resources/items/becon/blue_becon_common.png", "common blue beacon art resolves to raw item PNG")
	_assert((common_desc.get("fallbackChain", []) as Array).has("res://resources/items/becon/blue_becon_common.png"), "common beacon item path is part of the fallback chain")
	var start_desc: Dictionary = ArtifactCodexArtResolverScript.descriptor_for_reward({
		"id": "starter_red_beacon",
		"rarity": "basic",
		"payload": {"item_type": "beacon", "energy_type": "red"},
		"presentation": {"icon": "beacon_red_start"}
	}, "thumb", true)
	_assert_eq(str(start_desc.get("path", "")), "res://resources/items/becon/red_becon_start.png", "starter red beacon art resolves to the supplied start PNG")

func test_artifact_codex_drill_descriptor_resolves_new_epic_legendary_item_pngs() -> void:
	var epic_desc: Dictionary = ArtifactCodexArtResolverScript.descriptor_for_reward({
		"id": "reward_epic_blue_drill_test",
		"rarity": "epic",
		"payload": {"item_type": "drill", "energy_type": "blue"},
		"presentation": {"icon": "drill_blue_epic"}
	}, "thumb", true)
	_assert_eq(str(epic_desc.get("path", "")), "res://resources/items/drill/blue_drill_epic.png", "epic blue drill codex art resolves to the newly added item PNG")
	_assert((epic_desc.get("fallbackChain", []) as Array).has("res://resources/items/drill/blue_drill_epic.png"), "epic drill item PNG path is part of the fallback chain")
	var legendary_desc: Dictionary = ArtifactCodexArtResolverScript.descriptor_for_reward({
		"id": "reward_legendary_red_drill_test",
		"rarity": "legendary",
		"payload": {"item_type": "drill", "energy_type": "red"},
		"presentation": {"icon": "drill_red_legendary"}
	}, "hero", true)
	_assert_eq(str(legendary_desc.get("path", "")), "res://resources/items/drill/red_drill_legendary.png", "legendary red drill codex art resolves to the newly added item PNG")
func test_artifact_codex_selection_normalizes_when_filtered_out() -> void:
	var table := _load_reward_table_fixture()
	var rewards: Array = table.get("rewards", [])
	_assert(rewards.size() > 2, "codex fixture has enough rewards for normalization coverage")
	if rewards.size() <= 2:
		return
	var hidden_id := str(rewards[0].get("id", ""))
	var model: Dictionary = _project_artifact_codex(table, {"artifactDiscovery": []}, false, "en", hidden_id, "relic")
	_assert_eq(str(model.get("activeSection", "")), "relic", "codex keeps the requested active section")
	_assert(str(model.get("resolvedSelectedEntryId", "")) != hidden_id, "codex reselects when the requested entry is filtered out")
func test_artifact_codex_sorts_entries_by_rarity_color_type_name() -> void:
	var reward_table := {
		"rewards": [
			{
				"id": "reward_rare_blue_beacon_zeta",
				"kind": "Zeta Relay",
				"rarity": "rare",
				"payload": {"item_type": "beacon", "energy_type": "blue", "shape": [[1]]},
				"text": {"name": {"ko": "zeta", "en": "Zeta Relay"}, "description": {"ko": "desc", "en": "desc"}},
				"presentation": {"icon": "beacon_blue_rare", "description": "desc"}
			},
			{
				"id": "reward_common_relic_archive",
				"kind": "Archive Bell",
				"rarity": "common",
				"payload": {"item_type": "relic", "energy_type": "", "shape": [[1]]},
				"text": {"name": {"ko": "archive", "en": "Archive Bell"}, "description": {"ko": "desc", "en": "desc"}},
				"presentation": {"icon": "relic_common_archive", "description": "desc"}
			},
			{
				"id": "reward_common_green_drill_moss",
				"kind": "Moss Bit",
				"rarity": "common",
				"payload": {"item_type": "drill", "energy_type": "green", "shape": [[1]]},
				"text": {"name": {"ko": "moss", "en": "Moss Bit"}, "description": {"ko": "desc", "en": "desc"}},
				"presentation": {"icon": "drill_green_common", "description": "desc"}
			},
			{
				"id": "reward_common_red_beacon_beta",
				"kind": "Beta Beacon",
				"rarity": "common",
				"payload": {"item_type": "beacon", "energy_type": "red", "shape": [[1]]},
				"text": {"name": {"ko": "beta", "en": "Beta Beacon"}, "description": {"ko": "desc", "en": "desc"}},
				"presentation": {"icon": "beacon_red_common", "description": "desc"}
			},
			{
				"id": "reward_common_red_drill_beta",
				"kind": "Beta Drill",
				"rarity": "common",
				"payload": {"item_type": "drill", "energy_type": "red", "shape": [[1]]},
				"text": {"name": {"ko": "beta", "en": "Beta Drill"}, "description": {"ko": "desc", "en": "desc"}},
				"presentation": {"icon": "drill_red_common", "description": "desc"}
			},
			{
				"id": "reward_common_red_drill_alpha",
				"kind": "Alpha Drill",
				"rarity": "common",
				"payload": {"item_type": "drill", "energy_type": "red", "shape": [[1]]},
				"text": {"name": {"ko": "alpha", "en": "Alpha Drill"}, "description": {"ko": "desc", "en": "desc"}},
				"presentation": {"icon": "drill_red_common", "description": "desc"}
			}
		]
	}
	var model: Dictionary = _project_artifact_codex(reward_table, {"artifactDiscovery": []}, true, "en", "", "all")
	var right_page: Dictionary = model.get("rightPage", {})
	var grid_entries: Array = right_page.get("gridEntries", [])
	var ordered_ids := []
	for entry in grid_entries:
		ordered_ids.append(str((entry as Dictionary).get("id", "")))
	_assert_eq(
		ordered_ids,
		[
			"reward_common_red_drill_alpha",
			"reward_common_red_drill_beta",
			"reward_common_red_beacon_beta",
			"reward_common_green_drill_moss",
			"reward_common_relic_archive",
			"reward_rare_blue_beacon_zeta"
		],
		"codex sorts artifacts by rarity, color, type, and name instead of raw authoring order"
	)
func test_reward_artifact_creation_vocab() -> void:
	var reward_item = {
		"rewardId": "reward_artifact_1",
		"kind": "Azure Beacon",
		"rarity": "rare",
		"payload": {
			"item_type": "beacon",
			"energy_type": "blue",
			"shape": [[1, 1]],
			"base_cooldown_ticks": 44,
			"damage": 1.7,
			"beacon_cooldown_mod": -12,
			"beacon_damage_mod": 0.4
		},
		"presentation": {"description": "test keyword"}
	}
	var growth = RunGrowthStateScript.new({"gold": 0, "xp": 0, "purchasedPassives": {"cooldown_reduction": 1}, "temporaryModifiers": {}, "runModifiers": {}, "rewardHistory": []})
	var result = CreateArtifactFromRewardScript.create(reward_item, growth)
	_assert(result["ok"], "reward artifact creation succeeds")
	var art = result["artifact"]
	_assert_eq(art.item_type, "beacon", "reward artifact preserves item type")
	_assert_eq(art.energy_type, "blue", "reward artifact preserves energy")
	_assert_eq(art.shape, [[1, 1]], "reward artifact uses payload shape")
	_assert_eq(art.base_cooldown_ticks, 20, "reward artifact applies the faster tempo scale before the growth cooldown modifier")
	_assert_eq(art.damage, 1.7, "reward artifact preserves damage")
	_assert_eq(art.beacon_cooldown_mod, -24, "reward artifact doubles beacon cooldown reduction for the faster queue tempo")
	_assert_eq(art.beacon_damage_mod, 0.4, "reward artifact preserves beacon damage modifier")
	var schema_reward = reward_item.duplicate(true)
	schema_reward["payload"]["effect_schema"] = {"version": 1, "type": "echo", "trigger": "on_fire", "summary": "test schema"}
	var schema_result = CreateArtifactFromRewardScript.create(schema_reward)
	_assert(schema_result["ok"], "schema reward artifact creation succeeds")
	_assert_eq(schema_result["artifact"].effect_schema.get("type", ""), "echo", "reward artifact preserves effect schema")
	var tagged_reward = reward_item.duplicate(true)
	tagged_reward["kind"] = "Crimson Drill Core v2 (Red)"
	var tagged_result = CreateArtifactFromRewardScript.create(tagged_reward)
	_assert(tagged_result["ok"], "tagged reward artifact creation succeeds")
	_assert_eq(tagged_result["artifact"].name, "Crimson Drill Core", "reward artifact name strips implementation tags")
	var relic_reward = {
		"rewardId": "reward_relic_1",
		"kind": "Breach Seal",
		"rarity": "common",
		"text": {
			"name": {"ko": "균열 봉인장", "en": "Breach Seal"},
			"description": {"ko": "대각선으로 연결된 드릴의 첫 장애물 타격에 진행도 +1을 더합니다.", "en": "Adds +1 obstacle progress to the first hit from its diagonally linked drill each combat."}
		},
		"payload": {
			"item_type": "relic",
			"shape": [[1]],
			"effect_schema": {
				"version": 1,
				"link_mode": "diagonal_1",
				"trigger": "on_obstacle_hit",
				"type": "obstacle_progress_bonus",
				"summary": "Linked drill gains +1 progress on its first obstacle hit each combat.",
				"summary_i18n": {
					"ko": "연결된 드릴의 첫 장애물 타격은 전투당 진행도 +1을 얻습니다.",
					"en": "Linked drill gains +1 progress on its first obstacle hit each combat."
				}
			}
		},
		"presentation": {"description": "Fallback relic description"}
	}
	var relic_result = CreateArtifactFromRewardScript.create(relic_reward)
	_assert(relic_result["ok"], "relic reward artifact creation succeeds")
	var relic_art = relic_result["artifact"]
	_assert_eq(relic_art.item_type, "relic", "relic reward preserves item type")
	_assert_eq(relic_art.energy_type, "", "relic reward stays colorless when materialized")
	_assert_eq(relic_art.effect_schema.get("link_mode", ""), "diagonal_1", "relic reward preserves link mode schema")
	_assert_eq(relic_art.beacon_cooldown_mod, 0, "relic reward does not inherit beacon cooldown tuning")
	_assert_eq(relic_art.beacon_damage_mod, 0.0, "relic reward does not inherit beacon damage tuning")
# ?ㅽ뻾: verify reward effect vocabulary updates growth.
func test_apply_reward_effect_vocab() -> void:
	var growth = RunGrowthStateScript.new({"gold": 0, "xp": 0, "purchasedPassives": {}, "temporaryModifiers": {}, "runModifiers": {}, "rewardHistory": []})
	var result = ApplyRewardEffectScript.apply(growth, {"rewardId": "legendary_reward", "rarity": "legendary"})
	_assert(result["ok"], "apply reward effect succeeds")
	_assert_eq(growth.gold, 100, "legendary reward grants 100 gold")
	_assert_eq(growth.xp, 60, "legendary reward grants 60 xp")
	_assert(growth.reward_history.has("legendary_reward"), "reward effect records history")
# ?ㅽ뻾: verify growth modifiers vocabulary mutates inventory and tuning.
func test_apply_growth_modifiers_vocab() -> void:
	var inv = InventoryModel.new(2, 2)
	var art = load("res://src/models/Artifact.gd").new({"id": "ruby_drill", "name": "Ruby Drill", "shape": [[1]], "energyType": "red", "baseCooldownTicks": 80, "damage": 1.0})
	inv.place_artifact(art, 0, 0)
	var growth = RunGrowthStateScript.new({"gold": 0, "xp": 0, "purchasedPassives": {"cooldown_reduction": 2, "aim_damage_boost": 3}, "temporaryModifiers": {}, "runModifiers": {}, "rewardHistory": []})
	var tuning := {}
	var result = ApplyGrowthModifiersScript.apply(inv, growth, tuning)
	_assert(result["ok"], "apply growth modifiers succeeds")
	_assert_eq(art.base_cooldown_ticks, 32, "growth modifier applies the faster tempo-scaled cooldown multiplier")
	_assert_eq(float(tuning.get("combat", {}).get("damage_bonus", 0.0)), 3.0, "growth modifier writes damage bonus")
# 실행: verify passive purchases subtract gold and increment level.
func test_passive_purchase() -> void:
	var state = {
		"seed": 1,
		"phase": "reward_loot",
		"gold": 10,
		"xp": 0,
		"inventory": {},
		"progress": {"clearedLeviathanIds": []},
		"stageIndex": 0,
		"maxStages": 5,
		"runIndex": 0,
		"runCount": 1,
		"lastNodeLabel": "",
		"runComplete": false,
		"failed": false,
		"growth": {
			"gold": 100,
			"xp": 0,
			"purchasedPassives": {
				"starting_gold_boost": 0
			},
			"temporaryModifiers": {},
			"runModifiers": {},
			"rewardHistory": []
		}
	}
	# Purchase starting_gold_boost costing 50 gold
	var next_state = RewardLootPhaseScript.reduce(state, {
		"type": "purchase_passive",
		"passiveId": "starting_gold_boost",
		"cost": 50
	})
	var growth = next_state.get("growth", {})
	_assert_eq(int(growth.get("gold", 0)), 50, "gold decremented by purchase")
	_assert_eq(int(growth.get("purchasedPassives", {}).get("starting_gold_boost", 0)), 1, "passive level incremented")
	var growth_obj = RunGrowthStateScript.new(growth)
	_assert_eq(growth_obj.get_starting_gold(), 110, "starting gold boost increases starter gold to 110")
# 실행: verify cooldown and damage multipliers return correct scales.
func test_passive_modifiers() -> void:
	var growth_data = {
		"gold": 100,
		"xp": 0,
		"purchasedPassives": {
			"cooldown_reduction": 2,
			"aim_damage_boost": 3
		},
		"temporaryModifiers": {},
		"runModifiers": {},
		"rewardHistory": []
	}
	var growth = RunGrowthStateScript.new(growth_data)
	_assert_eq(growth.get_cooldown_modifier(), 0.8, "level 2 CDR gives 20% reduction (0.8 multiplier) for the faster queue tempo")
	_assert_eq(growth.get_damage_bonus(), 3.0, "level 3 damage boost gives +3.0 damage")
func _shape_is_valid(shape: Variant) -> bool:
	if not (shape is Array) or shape.is_empty():
		return false
	var width := -1
	var filled := 0
	for row in shape:
		if not (row is Array) or row.is_empty():
			return false
		if width < 0:
			width = row.size()
		elif row.size() != width:
			return false
		for cell in row:
			var value := int(cell)
			if value != 0 and value != 1:
				return false
			if value == 1:
				filled += 1
	return filled > 0 and width <= 8 and shape.size() <= 8
func _normalized_int_shape(shape: Variant) -> Array:
	var normalized: Array = []
	if not shape is Array:
		return normalized
	for row in shape:
		if not row is Array:
			continue
		var normalized_row: Array = []
		for cell in row:
			normalized_row.append(int(cell))
		normalized.append(normalized_row)
	return normalized
func _localized_pair_is_valid(value: Variant) -> bool:
	if not (value is Dictionary):
		return false
	return not str(value.get("ko", "")).strip_edges().is_empty() and not str(value.get("en", "")).strip_edges().is_empty()
func _korean_localized_value_is_readable(value: Variant) -> bool:
	var text := str(value).strip_edges()
	if text.is_empty():
		return false
	if text.contains("?") or text.contains("�"):
		return false
	var regex := RegEx.new()
	if regex.compile("[가-힣ㄱ-ㅎㅏ-ㅣ]") != OK:
		return false
	return regex.search(text) != null
