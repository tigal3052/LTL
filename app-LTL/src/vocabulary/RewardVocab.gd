# 계약:
# - 책임: 전투 클리어 이후 stage reward offer 생성과 fallback reward loading을 제공한다.
# - 입력: seed, stage index, weakness list, tuning dictionary.
# - 출력: reward dictionaries with payload, rarity, presentation, and deterministic offer hashes.
# - 금지: SceneTree 접근, mutable global state, UI node ownership.
#
# 실행: define the RewardVocab static entry.
# 怨꾩빟:
# - 梨낆엫: ?꾪닾 ?대━?????띾뱷??蹂댁긽 ?앹꽦??愿???쒖닔 ?숈궗 ?⑥닔?ㅼ쓣 ?쒓났?쒕떎.
# - ?낅젰: ?쒕뱶 媛? ?ㅽ뀒?댁? ?몃뜳?? 寃⑺뙆???띿꽦 Array, ?쒕떇 ?ㅼ젙 Dictionary.
# - 異쒕젰: ?앹꽦??蹂댁긽 紐⑸줉 Array.
# - 湲덉?: SceneTree ?묎렐, ?먯껜 ?곹깭 蹂댁〈 (static func留?媛吏?.
#
# ?ㅽ뻾: define the RewardVocab static entry.
class_name RewardVocab
extends RefCounted
const BuildRewardPreviewScript = preload("res://src/vocabulary/reward/BuildRewardPreview.gd")
const DefaultMockRewardsScript = preload("res://src/vocabulary/reward/DefaultMockRewards.gd")

# ?ㅽ뻾: roll deterministic rewards based on seed and loaded JSON tables.
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

	# 1~5媛??꾩씠???띾뱷 ?뺣쪧 ?뚯씠釉?(1媛? 15%, 2媛? 30%, 3媛? 35%, 4媛? 15%, 5媛? 5%)
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

	# ?좊Ъ ?깃툒 ?뺣쪧 ?뚯씠釉?(?깃툒, ?ㅽ뀒?댁? ?④퀎???곕씪 ?щ씪吏? ?믪? ?ㅽ뀒?댁??먯꽌 ?믪? ?깃툒 ?뺣쪧 利앷?. ?좏솕?깃툒 ?쒖쇅 珥앺빀 100%)
	var rarity_probs := {
		0: { "common": 0.70, "rare": 0.22, "epic": 0.07, "legendary": 0.01, "mythic": 0.00 },
		1: { "common": 0.50, "rare": 0.33, "epic": 0.14, "legendary": 0.03, "mythic": 0.00 },
		2: { "common": 0.30, "rare": 0.45, "epic": 0.20, "legendary": 0.05, "mythic": 0.00 },
		3: { "common": 0.15, "rare": 0.39, "epic": 0.34, "legendary": 0.10, "mythic": 0.02 },
		4: { "common": 0.05, "rare": 0.27, "epic": 0.42, "legendary": 0.20, "mythic": 0.06 }
	}

	var stage_key := clampi(stage_index, 0, 4)
	var probs: Dictionary = rarity_probs[stage_key]
	var rolled_rarities: Array[String] = []
	for _roll_index in range(count):
		var rarity_roll := rng.randf()
		var rolled_rarity := "common"
		var rarity_cumulative := 0.0
		for rarity in ["common", "rare", "epic", "legendary", "mythic"]:
			rarity_cumulative += probs.get(rarity, 0.0)
			if rarity_roll <= rarity_cumulative:
				rolled_rarity = rarity
				break
		rolled_rarities.append(rolled_rarity)

	var forced_relic_slot := -1
	for slot_index in range(rolled_rarities.size() - 1, -1, -1):
		if _has_reward_type(_rarity_candidates(reward_pool, rolled_rarities[slot_index]), "relic"):
			forced_relic_slot = slot_index
			break

	var rolled_rewards = []
	for i in range(count):
		var rolled_rarity := rolled_rarities[i]
		var matched_items := _rarity_candidates(reward_pool, rolled_rarity)

		# Fallback if no items found in the matching rarity tier
		if matched_items.is_empty() and not reward_pool.is_empty():
			for item in reward_pool:
				matched_items.append(item)
		var selection_pool := matched_items
		var should_force_relic := i == forced_relic_slot and not _rolled_rewards_have_type(rolled_rewards, "relic")
		if should_force_relic:
			var relic_only := _only_reward_type(matched_items, "relic")
			if not relic_only.is_empty():
				selection_pool = relic_only
		selection_pool = _with_reward_type_mix(selection_pool, reward_pool)
		var weighted_entries := _with_type_ratio_weights(selection_pool)
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
				"catalogId": str(selected_item.get("id", "")),
				"kind": str(selected_item.get("kind", "")),
				"rarity": str(selected_item.get("rarity", "common")),
				"qty": 1,
				"payload": reward_payload,
				"text": selected_item.get("text", {}).duplicate(true),
				"presentation": selected_item.get("presentation", {}).duplicate(true),
				"tags": selected_item.get("tags", []).duplicate(true),
				"offer_weights_hash": offer_weights_hash,
				"next_combat_modifier_preview": BuildRewardPreviewScript.build(reward_data)
			})

	return rolled_rewards

# ?ㅽ뻾: keep reward type choices available even when a rarity tier lacks beacons.
static func _with_reward_type_mix(items: Array, reward_pool: Array) -> Array:
	return items

static func _rarity_candidates(reward_pool: Array, rarity: String) -> Array:
	var matched_items: Array = []
	for item in reward_pool:
		if str(item.get("rarity", "common")).to_lower() == rarity:
			matched_items.append(item)
	return matched_items

# ?ㅽ뻾: rebalance reward item weights so drill-like items and beacons land near 40:60.
static func _with_type_ratio_weights(items: Array) -> Array:
	var type_totals := {}
	for item in items:
		var reward_type := _reward_item_type(item)
		type_totals[reward_type] = float(type_totals.get(reward_type, 0.0)) + float(item.get("weight", 10.0))
	var target_shares := {"drill": 0.35, "beacon": 0.50, "relic": 0.15}
	var available_types: Array[String] = []
	var total := 0.0
	for reward_type in target_shares.keys():
		var observed_total := float(type_totals.get(reward_type, 0.0))
		if observed_total > 0.0:
			available_types.append(reward_type)
			total += observed_total
	if available_types.size() <= 1 or total <= 0.0:
		var raw_entries := []
		for item in items:
			raw_entries.append({"item": item, "weight": float(item.get("weight", 10.0))})
		return raw_entries
	var target_total := 0.0
	for reward_type in available_types:
		target_total += float(target_shares.get(reward_type, 0.0))
	var multipliers := {}
	for reward_type in available_types:
		var observed_share := float(type_totals.get(reward_type, 0.0)) / total
		var target_share := float(target_shares.get(reward_type, 0.0)) / target_total
		multipliers[reward_type] = target_share / observed_share if observed_share > 0.0 else 1.0
	var entries := []
	for item in items:
		var reward_type := _reward_item_type(item)
		entries.append({"item": item, "weight": float(item.get("weight", 10.0)) * float(multipliers.get(reward_type, 1.0))})
	return entries

# ?ㅽ뻾: infer reward type from payload, tags, and item name.
static func _reward_item_type(item: Dictionary) -> String:
	var payload: Dictionary = item.get("payload", {})
	var payload_item_type := str(payload.get("item_type", payload.get("itemType", ""))).to_lower()
	if payload_item_type in ["beacon", "relic"]:
		return payload_item_type
	for tag in item.get("tags", []):
		var normalized_tag := str(tag).to_lower()
		if normalized_tag in ["beacon", "relic"]:
			return normalized_tag
	var kind_name := str(item.get("kind", "")).to_lower()
	if kind_name.contains("beacon"):
		return "beacon"
	if kind_name.contains("relic"):
		return "relic"
	return "drill"

# ?ㅽ뻾: check if a reward list contains a requested item type.
static func _has_reward_type(items: Array, reward_type: String) -> bool:
	for item in items:
		if _reward_item_type(item) == reward_type:
			return true
	return false

static func _only_reward_type(items: Array, reward_type: String) -> Array:
	var filtered: Array = []
	for item in items:
		if _reward_item_type(item) == reward_type:
			filtered.append(item)
	return filtered

static func _rolled_rewards_have_type(rewards: Array, reward_type: String) -> bool:
	for reward in rewards:
		if not reward is Dictionary:
			continue
		var payload: Dictionary = reward.get("payload", {})
		if str(payload.get("item_type", "drill")).to_lower() == reward_type:
			return true
	return false

# ?ㅽ뻾: sum weighted reward entries.
static func _total_weight(entries: Array) -> float:
	var total := 0.0
	for entry in entries:
		total += float(entry.get("weight", 0.0))
	return total

# ?ㅽ뻾: create a deterministic compact hash from candidate ids and effective weights.
static func _stable_offer_weights_hash(entries: Array) -> String:
	var acc := 2166136261
	for entry in entries:
		var item: Dictionary = entry.get("item", {})
		var token := "%s:%0.3f;" % [str(item.get("id", item.get("kind", ""))), float(entry.get("weight", 0.0))]
		for i in range(token.length()):
			acc = int((acc ^ token.unicode_at(i)) * 16777619) & 0x7fffffff
	return "%08x" % acc

# ?ㅽ뻾: load helper for JSON files.
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

# ?ㅽ뻾: fallback reward roll in case files are missing.
static func _roll_fallback_rewards(combined_seed: int, rng: RandomNumberGenerator) -> Array:
	var count = rng.randi_range(2, 5)
	var rewards = []
	var colors = ["red", "blue", "purple", "green"]
	var kinds = ["Drill", "Core", "Capacitor", "Lens", "Reactor", "Beacon"]
	var badges = ["immediate power", "combo setup", "stability", "risk reward"]

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

# ?ㅽ뻾: provide default mock rewards in case JSON loading fails.
# 실행: delegate default fallback catalog ownership to the reward data helper.
static func _get_default_mock_rewards() -> Array:
	return DefaultMockRewardsScript.items()
