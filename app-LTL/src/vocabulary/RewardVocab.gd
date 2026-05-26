# 계약:
# - 책임: 전투 클리어 시 획득할 보상 생성에 관한 순수 동사 함수들을 제공한다.
# - 입력: 시드 값, 스테이지 인덱스, 격파된 속성 Array, 튜닝 설정 Dictionary.
# - 출력: 생성된 보상 목록 Array.
# - 금지: SceneTree 접근, 자체 상태 보존 (static func만 가짐).
#
# 실행: define the RewardVocab static entry.
class_name RewardVocab
extends RefCounted

# 실행: roll deterministic rewards based on seed and loaded JSON tables.
static func roll_stage_rewards(seed_val: int, stage_index: int, weaknesses: Array, tuning: Dictionary) -> Array:
	var combined_seed := int(seed_val) + int(stage_index) * 0x85ebca6b
	var rng = RandomNumberGenerator.new()
	rng.seed = combined_seed
	
	# Load tables
	var rewards_data := _load_json("res://src/data/reward-table.json")
	var rarities_data := _load_json("res://src/data/rarity-table.json")
	
	# Fallback if JSON table fails to load
	if rewards_data.is_empty() or not rewards_data.has("rewards"):
		return _roll_fallback_rewards(combined_seed, rng)
		
	var reward_pool: Array = rewards_data.get("rewards", [])
	var rarity_pool: Array = rarities_data.get("rarities", [])
	
	# Map rarity weight multipliers
	var rarity_muls := {}
	for r in rarity_pool:
		rarity_muls[str(r.get("id", ""))] = float(r.get("weightMul", 1.0))
		
	# Calculate total weights
	var weighted_pool := []
	var total_weight := 0.0
	for item in reward_pool:
		var rarity_id = str(item.get("rarity", "common"))
		var mul = float(rarity_muls.get(rarity_id, 1.0))
		var w = float(item.get("weight", 10)) * mul
		weighted_pool.append({"item": item, "weight": w})
		total_weight += w
		
	# Roll 2 to 5 rewards deterministically
	var count = rng.randi_range(2, 5)
	var rolled_rewards = []
	for i in range(count):
		if total_weight <= 0.0:
			break
		var roll = rng.randf_range(0.0, total_weight)
		var cumulative = 0.0
		var selected_item = null
		for entry in weighted_pool:
			cumulative += entry["weight"]
			if roll <= cumulative:
				selected_item = entry["item"]
				break
		if selected_item == null and not weighted_pool.is_empty():
			selected_item = weighted_pool.back()["item"]
			
		if selected_item != null:
			rolled_rewards.append({
				"rewardId": "reward_%d_%d" % [combined_seed & 0xffff, i],
				"kind": str(selected_item.get("kind", "")),
				"rarity": str(selected_item.get("rarity", "common")),
				"qty": 1,
				"payload": selected_item.get("payload", {}).duplicate(true),
				"presentation": selected_item.get("presentation", {}).duplicate(true),
				"tags": selected_item.get("tags", []).duplicate(true)
			})
			
	return rolled_rewards

# 실행: load helper for JSON files.
static func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json_text := file.get_as_text()
	var json := JSON.new()
	var err := json.parse(json_text)
	if err == OK:
		var data = json.get_data()
		if data is Dictionary:
			return data
	return {}

# 실행: fallback reward roll in case files are missing.
static func _roll_fallback_rewards(combined_seed: int, rng: RandomNumberGenerator) -> Array:
	var count = rng.randi_range(2, 5)
	var rewards = []
	var colors = ["red", "blue", "purple", "green"]
	var kinds = ["Drill", "Core", "Capacitor", "Lens", "Reactor"]
	var badges = ["다음 전투 즉시 영향", "조합 대기", "안정", "위험 보상"]
	
	for i in range(count):
		var color = colors[rng.randi() % colors.size()]
		var kind_suffix = kinds[rng.randi() % kinds.size()]
		var prefix = "Basic"
		var rarity = "common"
		var badge = badges[rng.randi() % badges.size()]
		if color == "red":
			prefix = "Crimson"
			rarity = "epic"
		elif color == "blue":
			prefix = "Azure"
			rarity = "rare"
		elif color == "purple":
			prefix = "Violet"
			rarity = "legendary"
		elif color == "green":
			prefix = "Verdant"
			rarity = "common"
			
		var kind = "%s %s" % [prefix, kind_suffix]
		
		rewards.append({
			"rewardId": "reward_%d_%d" % [combined_seed & 0xffff, i],
			"kind": kind,
			"rarity": rarity,
			"qty": 1,
			"payload": {"energy_type": color},
			"presentation": {
				"description": "Procedural fallback item.",
				"badge": badge
			},
			"tags": ["fallback"]
		})
	return rewards
