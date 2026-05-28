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

var failures: Array[String] = []

# 실행: run all unit tests for rewards and progression.
func run_all_tests() -> Dictionary:
	failures.clear()
	test_seed_determinism()
	test_validator()
	test_reward_count_tuning()
	test_reward_type_ratio_prefers_beacons()
	test_growth_state_updates()
	test_reward_artifact_creation_vocab()
	test_apply_reward_effect_vocab()
	test_apply_growth_modifiers_vocab()
	test_passive_purchase()
	test_passive_modifiers()
	return {"ok": failures.is_empty(), "errors": failures}

func _assert(condition: bool, msg: String) -> void:
	if not condition:
		failures.append(msg)

func _assert_eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [msg, str(expected), str(actual)])

# 실행: verify seed-based determinism yields exact same rewards.
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

# 실행: verify reward roll count is bounded between 1 and 5.
func test_reward_count_tuning() -> void:
	for s in range(1, 20):
		var rolls = RewardVocabScript.roll_stage_rewards(s, 0, [], {})
		_assert(rolls.size() >= 2 and rolls.size() <= 5, "roll count bound to [2, 5]")

# 실행: verify reward type weighting favors beacons at roughly 40:60 drill/beacon.
func test_reward_type_ratio_prefers_beacons() -> void:
	var beacon_count := 0
	var drill_count := 0
	for s in range(1, 240):
		var rolls = RewardVocabScript.roll_stage_rewards(s, 1, [], {})
		for reward in rolls:
			var item_type := str(reward.get("payload", {}).get("item_type", "drill"))
			if item_type == "beacon":
				beacon_count += 1
			else:
				drill_count += 1
	var total := beacon_count + drill_count
	_assert(total > 0, "reward ratio sample has data")
	var beacon_share := float(beacon_count) / float(total)
	_assert(beacon_count > drill_count, "beacon rewards outnumber drill rewards")
	_assert(beacon_share >= 0.50 and beacon_share <= 0.70, "beacon share remains near 60%%, got %.3f" % beacon_share)

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
	_assert_eq(art.base_cooldown_ticks, 41, "reward artifact applies growth cooldown modifier")
	_assert_eq(art.damage, 1.7, "reward artifact preserves damage")
	_assert_eq(art.beacon_cooldown_mod, -12, "reward artifact preserves beacon cooldown modifier")
	_assert_eq(art.beacon_damage_mod, 0.4, "reward artifact preserves beacon damage modifier")

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
	_assert_eq(art.base_cooldown_ticks, 72, "growth modifier applies cooldown multiplier")
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
	_assert_eq(growth.get_cooldown_modifier(), 0.9, "level 2 CDR gives 10% reduction (0.9 multiplier)")
	_assert_eq(growth.get_damage_bonus(), 3.0, "level 3 damage boost gives +3.0 damage")
