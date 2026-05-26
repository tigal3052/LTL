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

var failures: Array[String] = []

# 실행: run all unit tests for rewards and progression.
func run_all_tests() -> Dictionary:
	failures.clear()
	test_seed_determinism()
	test_validator()
	test_reward_count_tuning()
	test_growth_state_updates()
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

# 실행: verify reward roll count is bounded between 2 and 5.
func test_reward_count_tuning() -> void:
	for s in range(1, 20):
		var rolls = RewardVocabScript.roll_stage_rewards(s, 0, [], {})
		_assert(rolls.size() >= 2 and rolls.size() <= 5, "roll count bound to [2, 5]")

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
