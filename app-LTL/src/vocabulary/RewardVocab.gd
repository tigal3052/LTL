# 계약:
# - 책임: 전투 클리어 시 획득할 보상 생성에 관한 순수 동사 함수들을 제공한다.
# - 입력: 시드 값, 스테이지 인덱스, 격파된 속성 Array, 튜닝 설정 Dictionary.
# - 출력: 생성된 보상 목록 Array.
# - 금지: SceneTree 접근, 자체 상태 보존 (static func만 가짐).
#
# 실행: define the RewardVocab static entry.
class_name RewardVocab
extends RefCounted
const BuildRewardPreviewScript = preload("res://src/vocabulary/reward/BuildRewardPreview.gd")

# 실행: roll deterministic rewards based on seed and loaded JSON tables.
static func roll_stage_rewards(seed_val: int, stage_index: int, weaknesses: Array, tuning: Dictionary) -> Array:
	var combined_seed := int(seed_val) + int(stage_index) * 0x85ebca6b
	var rng = RandomNumberGenerator.new()
	rng.seed = combined_seed

	# Load tables
	var rewards_data := _load_json("res://src/data/reward-table.json")
	var reward_pool: Array = []
	if not rewards_data.is_empty() and rewards_data.has("rewards"):
		reward_pool = rewards_data.get("rewards", [])
	else:
		reward_pool = _get_default_mock_rewards()

	# 1~5개 아이템 획득 확률 테이블 (1개: 15%, 2개: 30%, 3개: 35%, 4개: 15%, 5개: 5%)
	var count_roll := rng.randf()
	var count := 3
	if count_roll < 0.15:
		count = 2
	elif count_roll < 0.45:
		count = 2
	elif count_roll < 0.80:
		count = 3
	elif count_roll < 0.95:
		count = 4
	else:
		count = 5

	# 유물 등급 확률 테이블 (등급, 스테이지 단계에 따라 달라짐. 높은 스테이지에서 높은 등급 확률 증가. 신화등급 제외 총합 100%)
	var rarity_probs := {
		0: { "common": 0.70, "rare": 0.22, "epic": 0.07, "legendary": 0.01 },
		1: { "common": 0.50, "rare": 0.33, "epic": 0.14, "legendary": 0.03 },
		2: { "common": 0.30, "rare": 0.45, "epic": 0.20, "legendary": 0.05 },
		3: { "common": 0.15, "rare": 0.40, "epic": 0.35, "legendary": 0.10 },
		4: { "common": 0.05, "rare": 0.30, "epic": 0.45, "legendary": 0.20 }
	}

	var stage_key := clampi(stage_index, 0, 4)
	var probs: Dictionary = rarity_probs[stage_key]

	var rolled_rewards = []
	for i in range(count):
		# Roll rarity grade
		var rarity_roll := rng.randf()
		var rolled_rarity := "common"
		var rarity_cumulative := 0.0
		for rarity in ["common", "rare", "epic", "legendary"]:
			rarity_cumulative += probs.get(rarity, 0.0)
			if rarity_roll <= rarity_cumulative:
				rolled_rarity = rarity
				break

		# Filter rewards matching the rolled rarity
		var matched_items := []
		for item in reward_pool:
			if str(item.get("rarity", "common")).to_lower() == rolled_rarity:
				matched_items.append(item)

		# Fallback if no items found in the matching rarity tier
		if matched_items.is_empty() and not reward_pool.is_empty():
			for item in reward_pool:
				matched_items.append(item)
		matched_items = _with_reward_type_mix(matched_items, reward_pool)
		var weighted_entries := _with_type_ratio_weights(matched_items)
		var total_weight := _total_weight(weighted_entries)
		var offer_weights_hash := _stable_offer_weights_hash(weighted_entries)

		var selected_item = null
		if not weighted_entries.is_empty() and total_weight > 0.0:
			var roll = rng.randf_range(0.0, total_weight)
			var item_cumulative := 0.0
			for entry in weighted_entries:
				item_cumulative += entry["weight"]
				if roll <= item_cumulative:
					selected_item = entry["item"]
					break
			if selected_item == null:
				selected_item = weighted_entries.back()["item"]

		if selected_item != null:
			var reward_payload: Dictionary = selected_item.get("payload", {}).duplicate(true)
			var reward_data := {
				"payload": reward_payload
			}
			rolled_rewards.append({
				"rewardId": "reward_%d_%d" % [combined_seed & 0xffff, i],
				"kind": str(selected_item.get("kind", "")),
				"rarity": str(selected_item.get("rarity", "common")),
				"qty": 1,
				"payload": reward_payload,
				"presentation": selected_item.get("presentation", {}).duplicate(true),
				"tags": selected_item.get("tags", []).duplicate(true),
				"offer_weights_hash": offer_weights_hash,
				"next_combat_modifier_preview": BuildRewardPreviewScript.build(reward_data)
			})

	return rolled_rewards

# 실행: keep reward type choices available even when a rarity tier lacks beacons.
static func _with_reward_type_mix(items: Array, reward_pool: Array) -> Array:
	return items

# 실행: rebalance reward item weights so drill-like items and beacons land near 40:60.
static func _with_type_ratio_weights(items: Array) -> Array:
	var type_totals := {"drill": 0.0, "beacon": 0.0}
	for item in items:
		var reward_type := _reward_item_type(item)
		type_totals[reward_type] = float(type_totals.get(reward_type, 0.0)) + float(item.get("weight", 10.0))
	if float(type_totals.get("drill", 0.0)) <= 0.0 or float(type_totals.get("beacon", 0.0)) <= 0.0:
		var raw_entries := []
		for item in items:
			raw_entries.append({"item": item, "weight": float(item.get("weight", 10.0))})
		return raw_entries
	var total := float(type_totals["drill"]) + float(type_totals["beacon"])
	var observed_drill := float(type_totals["drill"]) / total
	var observed_beacon := float(type_totals["beacon"]) / total
	var multipliers := {
		"drill": 0.40 / observed_drill,
		"beacon": 0.60 / observed_beacon
	}
	var entries := []
	for item in items:
		var reward_type := _reward_item_type(item)
		entries.append({"item": item, "weight": float(item.get("weight", 10.0)) * float(multipliers.get(reward_type, 1.0))})
	return entries

# 실행: infer reward type from payload, tags, and item name.
static func _reward_item_type(item: Dictionary) -> String:
	var payload: Dictionary = item.get("payload", {})
	if str(payload.get("item_type", payload.get("itemType", ""))).to_lower() == "beacon":
		return "beacon"
	for tag in item.get("tags", []):
		if str(tag).to_lower() == "beacon":
			return "beacon"
	if str(item.get("kind", "")).to_lower().contains("beacon"):
		return "beacon"
	return "drill"

# 실행: check if a reward list contains a requested item type.
static func _has_reward_type(items: Array, reward_type: String) -> bool:
	for item in items:
		if _reward_item_type(item) == reward_type:
			return true
	return false

# 실행: sum weighted reward entries.
static func _total_weight(entries: Array) -> float:
	var total := 0.0
	for entry in entries:
		total += float(entry.get("weight", 0.0))
	return total

# 실행: create a deterministic compact hash from candidate ids and effective weights.
static func _stable_offer_weights_hash(entries: Array) -> String:
	var acc := 2166136261
	for entry in entries:
		var item: Dictionary = entry.get("item", {})
		var token := "%s:%0.3f;" % [str(item.get("id", item.get("kind", ""))), float(entry.get("weight", 0.0))]
		for i in range(token.length()):
			acc = int((acc ^ token.unicode_at(i)) * 16777619) & 0x7fffffff
	return "%08x" % acc

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
	var kinds = ["Drill", "Core", "Capacitor", "Lens", "Reactor", "Beacon"]
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
		var payload := {"energy_type": color}
		if kind_suffix == "Beacon":
			payload["item_type"] = "beacon"

		rewards.append({
			"rewardId": "reward_%d_%d" % [combined_seed & 0xffff, i],
			"kind": kind,
			"rarity": rarity,
			"qty": 1,
			"payload": payload,
			"presentation": {
				"description": "Procedural fallback item.",
				"badge": badge
			},
			"tags": ["fallback"]
		})
	return rewards

# 실행: provide default mock rewards in case JSON loading fails.
static func _get_default_mock_rewards() -> Array:
	return [
		{
			"id": "reward_crimson_core_red",
			"kind": "Crimson Drill Core v2 (Red)",
			"rarity": "epic",
			"weight": 20,
			"payload": {"cooldown_mod": -10, "energy_type": "red"},
			"presentation": {"icon": "core_red", "description": "Reduces red drill cooldown by 10%.", "badge": "다음 전투 즉시 영향"},
			"tags": ["immediate_power"]
		},
		{
			"id": "reward_crimson_core_blue",
			"kind": "Azure Drill Core v2 (Blue)",
			"rarity": "epic",
			"weight": 20,
			"payload": {"cooldown_mod": -10, "energy_type": "blue"},
			"presentation": {"icon": "core_blue", "description": "Reduces blue drill cooldown by 10%.", "badge": "다음 전투 즉시 영향"},
			"tags": ["immediate_power"]
		},
		{
			"id": "reward_crimson_core_purple",
			"kind": "Violet Drill Core v2 (Purple)",
			"rarity": "epic",
			"weight": 20,
			"payload": {"cooldown_mod": -10, "energy_type": "purple"},
			"presentation": {"icon": "core_purple", "description": "Reduces purple drill cooldown by 10%.", "badge": "다음 전투 즉시 영향"},
			"tags": ["immediate_power"]
		},
		{
			"id": "reward_crimson_core_green",
			"kind": "Verdant Drill Core v2 (Green)",
			"rarity": "epic",
			"weight": 20,
			"payload": {"cooldown_mod": -10, "energy_type": "green"},
			"presentation": {"icon": "core_green", "description": "Reduces green drill cooldown by 10%.", "badge": "다음 전투 즉시 영향"},
			"tags": ["immediate_power"]
		},
		{
			"id": "reward_rapid_condenser_red",
			"kind": "Rapid Fuel Condenser (Red)",
			"rarity": "rare",
			"weight": 40,
			"payload": {"cooldown_mod": -5, "energy_type": "red"},
			"presentation": {"icon": "condenser_red", "description": "Reduces red drill cooldown by 5%.", "badge": "다음 전투 즉시 영향"},
			"tags": ["immediate_power"]
		},
		{
			"id": "reward_rapid_condenser_blue",
			"kind": "Rapid Fuel Condenser (Blue)",
			"rarity": "rare",
			"weight": 40,
			"payload": {"cooldown_mod": -5, "energy_type": "blue"},
			"presentation": {"icon": "condenser_blue", "description": "Reduces blue drill cooldown by 5%.", "badge": "다음 전투 즉시 영향"},
			"tags": ["immediate_power"]
		},
		{
			"id": "reward_rapid_condenser_purple",
			"kind": "Rapid Fuel Condenser (Purple)",
			"rarity": "rare",
			"weight": 40,
			"payload": {"cooldown_mod": -5, "energy_type": "purple"},
			"presentation": {"icon": "condenser_purple", "description": "Reduces purple drill cooldown by 5%.", "badge": "다음 전투 즉시 영향"},
			"tags": ["immediate_power"]
		},
		{
			"id": "reward_rapid_condenser_green",
			"kind": "Rapid Fuel Condenser (Green)",
			"rarity": "rare",
			"weight": 40,
			"payload": {"cooldown_mod": -5, "energy_type": "green"},
			"presentation": {"icon": "condenser_green", "description": "Reduces green drill cooldown by 5%.", "badge": "다음 전투 즉시 영향"},
			"tags": ["immediate_power"]
		},
		{
			"id": "reward_resonance_magnet_red",
			"kind": "Resonance Magnet (Red)",
			"rarity": "rare",
			"weight": 30,
			"payload": {"adjacent_synergy": true, "energy_type": "red"},
			"presentation": {"icon": "magnet_red", "description": "Triggers synergy bonuses when placed next to drills. (Red)", "badge": "조합 대기"},
			"tags": ["future_combo"]
		},
		{
			"id": "reward_resonance_magnet_blue",
			"kind": "Resonance Magnet (Blue)",
			"rarity": "rare",
			"weight": 30,
			"payload": {"adjacent_synergy": true, "energy_type": "blue"},
			"presentation": {"icon": "magnet_blue", "description": "Triggers synergy bonuses when placed next to drills. (Blue)", "badge": "조합 대기"},
			"tags": ["future_combo"]
		},
		{
			"id": "reward_resonance_magnet_purple",
			"kind": "Resonance Magnet (Purple)",
			"rarity": "rare",
			"weight": 30,
			"payload": {"adjacent_synergy": true, "energy_type": "purple"},
			"presentation": {"icon": "magnet_purple", "description": "Triggers synergy bonuses when placed next to drills. (Purple)", "badge": "조합 대기"},
			"tags": ["future_combo"]
		},
		{
			"id": "reward_resonance_magnet_green",
			"kind": "Resonance Magnet (Green)",
			"rarity": "rare",
			"weight": 30,
			"payload": {"adjacent_synergy": true, "energy_type": "green"},
			"presentation": {"icon": "magnet_green", "description": "Triggers synergy bonuses when placed next to drills. (Green)", "badge": "조합 대기"},
			"tags": ["future_combo"]
		},
		{
			"id": "reward_shield_bot_red",
			"kind": "Shield Repair Bot (Red)",
			"rarity": "common",
			"weight": 80,
			"payload": {"shield_repair": 15, "energy_type": "red"},
			"presentation": {"icon": "bot_red", "description": "Increases shield repair efficiency by 15%. (Red)", "badge": "안정"},
			"tags": ["survival_stability"]
		},
		{
			"id": "reward_shield_bot_blue",
			"kind": "Shield Repair Bot (Blue)",
			"rarity": "common",
			"weight": 80,
			"payload": {"shield_repair": 15, "energy_type": "blue"},
			"presentation": {"icon": "bot_blue", "description": "Increases shield repair efficiency by 15%. (Blue)", "badge": "안정"},
			"tags": ["survival_stability"]
		},
		{
			"id": "reward_shield_bot_purple",
			"kind": "Shield Repair Bot (Purple)",
			"rarity": "common",
			"weight": 80,
			"payload": {"shield_repair": 15, "energy_type": "purple"},
			"presentation": {"icon": "bot_purple", "description": "Increases shield repair efficiency by 15%. (Purple)", "badge": "안정"},
			"tags": ["survival_stability"]
		},
		{
			"id": "reward_shield_bot_green",
			"kind": "Shield Repair Bot (Green)",
			"rarity": "common",
			"weight": 80,
			"payload": {"shield_repair": 15, "energy_type": "green"},
			"presentation": {"icon": "bot_green", "description": "Increases shield repair efficiency by 15%. (Green)", "badge": "안정"},
			"tags": ["survival_stability"]
		},
		{
			"id": "reward_cursed_heart_red",
			"kind": "Cursed Leviathan Heart (Red)",
			"rarity": "legendary",
			"weight": 10,
			"payload": {"damage_multiplier": 1.5, "hazard_increase": 10, "energy_type": "red"},
			"presentation": {"icon": "heart_red", "description": "Deals 50% more extraction damage, but increases hazard severity warning rate. (Red)", "badge": "위험 보상"},
			"tags": ["greed_risk"]
		},
		{
			"id": "reward_cursed_heart_blue",
			"kind": "Cursed Leviathan Heart (Blue)",
			"rarity": "legendary",
			"weight": 10,
			"payload": {"damage_multiplier": 1.5, "hazard_increase": 10, "energy_type": "blue"},
			"presentation": {"icon": "heart_blue", "description": "Deals 50% more extraction damage, but increases hazard severity warning rate. (Blue)", "badge": "위험 보상"},
			"tags": ["greed_risk"]
		},
		{
			"id": "reward_cursed_heart_purple",
			"kind": "Cursed Leviathan Heart (Purple)",
			"rarity": "legendary",
			"weight": 10,
			"payload": {"damage_multiplier": 1.5, "hazard_increase": 10, "energy_type": "purple"},
			"presentation": {"icon": "heart_purple", "description": "Deals 50% more extraction damage, but increases hazard severity warning rate. (Purple)", "badge": "위험 보상"},
			"tags": ["greed_risk"]
		},
		{
			"id": "reward_cursed_heart_green",
			"kind": "Cursed Leviathan Heart (Green)",
			"rarity": "legendary",
			"weight": 10,
			"payload": {"damage_multiplier": 1.5, "hazard_increase": 10, "energy_type": "green"},
			"presentation": {"icon": "heart_green", "description": "Deals 50% more extraction damage, but increases hazard severity warning rate. (Green)", "badge": "위험 보상"},
			"tags": ["greed_risk"]
		},
		{
			"id": "reward_special_plasma_red",
			"kind": "Special Plasma Injector (Red)",
			"rarity": "mythic",
			"weight": 5,
			"payload": {"damage_multiplier": 2.0, "energy_type": "red"},
			"presentation": {"icon": "plasma_red", "description": "Doubles extraction damage. (Red)", "badge": "위험 보상"},
			"tags": ["greed_risk", "fusion"]
		},
		{
			"id": "reward_special_plasma_blue",
			"kind": "Special Plasma Injector (Blue)",
			"rarity": "mythic",
			"weight": 5,
			"payload": {"damage_multiplier": 2.0, "energy_type": "blue"},
			"presentation": {"icon": "plasma_blue", "description": "Doubles extraction damage. (Blue)", "badge": "위험 보상"},
			"tags": ["greed_risk", "fusion"]
		},
		{
			"id": "reward_special_plasma_purple",
			"kind": "Special Plasma Injector (Purple)",
			"rarity": "mythic",
			"weight": 5,
			"payload": {"damage_multiplier": 2.0, "energy_type": "purple"},
			"presentation": {"icon": "plasma_purple", "description": "Doubles extraction damage. (Purple)", "badge": "위험 보상"},
			"tags": ["greed_risk", "fusion"]
		},
		{
			"id": "reward_special_plasma_green",
			"kind": "Special Plasma Injector (Green)",
			"rarity": "mythic",
			"weight": 5,
			"payload": {"damage_multiplier": 2.0, "energy_type": "green"},
			"presentation": {"icon": "plasma_green", "description": "Doubles extraction damage. (Green)", "badge": "위험 보상"},
			"tags": ["greed_risk", "fusion"]
		},
		{
			"id": "reward_cooldown_beacon_red",
			"kind": "Amplifying Cooldown Beacon (Red)",
			"rarity": "rare",
			"weight": 35,
			"payload": {"item_type": "beacon", "beacon_cooldown_mod": -20, "beacon_damage_mod": 0.4, "energy_type": "red"},
			"presentation": {"icon": "beacon_red", "description": "Beacon: Decreases adjacent drills' cooldown by 20 ticks and increases their damage by 0.4. (Red)", "badge": "조합 대기"},
			"tags": ["beacon"]
		},
		{
			"id": "reward_cooldown_beacon_blue",
			"kind": "Amplifying Cooldown Beacon (Blue)",
			"rarity": "rare",
			"weight": 35,
			"payload": {"item_type": "beacon", "beacon_cooldown_mod": -20, "beacon_damage_mod": 0.4, "energy_type": "blue"},
			"presentation": {"icon": "beacon_blue", "description": "Beacon: Decreases adjacent drills' cooldown by 20 ticks and increases their damage by 0.4. (Blue)", "badge": "조합 대기"},
			"tags": ["beacon"]
		},
		{
			"id": "reward_cooldown_beacon_purple",
			"kind": "Amplifying Cooldown Beacon (Purple)",
			"rarity": "rare",
			"weight": 35,
			"payload": {"item_type": "beacon", "beacon_cooldown_mod": -20, "beacon_damage_mod": 0.4, "energy_type": "purple"},
			"presentation": {"icon": "beacon_purple", "description": "Beacon: Decreases adjacent drills' cooldown by 20 ticks and increases their damage by 0.4. (Purple)", "badge": "조합 대기"},
			"tags": ["beacon"]
		},
		{
			"id": "reward_cooldown_beacon_green",
			"kind": "Amplifying Cooldown Beacon (Green)",
			"rarity": "rare",
			"weight": 35,
			"payload": {"item_type": "beacon", "beacon_cooldown_mod": -20, "beacon_damage_mod": 0.4, "energy_type": "green"},
			"presentation": {"icon": "beacon_green", "description": "Beacon: Decreases adjacent drills' cooldown by 20 ticks and increases their damage by 0.4. (Green)", "badge": "조합 대기"},
			"tags": ["beacon"]
		},
		{
			"id": "reward_unstable_beacon_red",
			"kind": "Unstable Overcharge Beacon (Red)",
			"rarity": "epic",
			"weight": 25,
			"payload": {"item_type": "beacon", "beacon_cooldown_mod": 15, "beacon_damage_mod": 1.2, "energy_type": "red"},
			"presentation": {"icon": "beacon_red", "description": "Beacon: Increases adjacent drills' damage by 1.2, but increases their cooldown by 15 ticks. (Red)", "badge": "조합 대기"},
			"tags": ["beacon"]
		},
		{
			"id": "reward_unstable_beacon_blue",
			"kind": "Unstable Overcharge Beacon (Blue)",
			"rarity": "epic",
			"weight": 25,
			"payload": {"item_type": "beacon", "beacon_cooldown_mod": 15, "beacon_damage_mod": 1.2, "energy_type": "blue"},
			"presentation": {"icon": "beacon_blue", "description": "Beacon: Increases adjacent drills' damage by 1.2, but increases their cooldown by 15 ticks. (Blue)", "badge": "조합 대기"},
			"tags": ["beacon"]
		},
		{
			"id": "reward_unstable_beacon_purple",
			"kind": "Unstable Overcharge Beacon (Purple)",
			"rarity": "epic",
			"weight": 25,
			"payload": {"item_type": "beacon", "beacon_cooldown_mod": 15, "beacon_damage_mod": 1.2, "energy_type": "purple"},
			"presentation": {"icon": "beacon_purple", "description": "Beacon: Increases adjacent drills' damage by 1.2, but increases their cooldown by 15 ticks. (Purple)", "badge": "조합 대기"},
			"tags": ["beacon"]
		},
		{
			"id": "reward_unstable_beacon_green",
			"kind": "Unstable Overcharge Beacon (Green)",
			"rarity": "epic",
			"weight": 25,
			"payload": {"item_type": "beacon", "beacon_cooldown_mod": 15, "beacon_damage_mod": 1.2, "energy_type": "green"},
			"presentation": {"icon": "beacon_green", "description": "Beacon: Increases adjacent drills' damage by 1.2, but increases their cooldown by 15 ticks. (Green)", "badge": "조합 대기"},
			"tags": ["beacon"]
		}
	]
