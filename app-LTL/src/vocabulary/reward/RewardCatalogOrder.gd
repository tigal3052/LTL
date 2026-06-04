# 계약:
# - 책임: reward-table과 codex가 공유하는 유물 정렬 기준을 한 곳에서 정의한다.
# - 입력: reward Dictionary 배열 또는 개별 reward Dictionary.
# - 출력: rarity -> color -> type -> name -> id 기준으로 정렬된 reward 배열 또는 비교 결과.
# - 금지: 파일 I/O, UI 의존, locale 기반 가변 정렬.
#
# 실행: define the shared reward catalog ordering policy.
class_name RewardCatalogOrder
extends RefCounted

const RARITY_ORDER := {
	"common": 0,
	"rare": 1,
	"epic": 2,
	"legendary": 3,
	"mythic": 4
}
const COLOR_ORDER := {
	"red": 0,
	"blue": 1,
	"purple": 2,
	"green": 3,
	"": 4,
	"none": 4
}
const ITEM_TYPE_ORDER := {
	"drill": 0,
	"beacon": 1,
	"relic": 2
}

# 실행: return rewards sorted by the shared codex/source ordering contract.
static func sort_rewards(rewards: Array) -> Array:
	var normalized: Array = []
	for reward in rewards:
		if reward is Dictionary:
			normalized.append(reward)
	normalized.sort_custom(func(a: Dictionary, b: Dictionary): return _reward_before(a, b))
	return normalized

# 실행: compare two reward rows using the canonical ordering tuple.
static func _reward_before(a: Dictionary, b: Dictionary) -> bool:
	return _sort_key_before(_reward_sort_key(a), _reward_sort_key(b))

# 실행: build a deterministic ordering tuple from reward metadata.
static func _reward_sort_key(reward: Dictionary) -> Array:
	var payload: Dictionary = reward.get("payload", {})
	var item_type := str(payload.get("item_type", "drill")).to_lower()
	var energy_type := str(payload.get("energy_type", "")).to_lower()
	var text: Dictionary = reward.get("text", {})
	var name_text: Dictionary = text.get("name", {})
	var sort_name := str(name_text.get("en", reward.get("kind", reward.get("id", "")))).to_lower()
	return [
		int(RARITY_ORDER.get(str(reward.get("rarity", "common")).to_lower(), 99)),
		int(COLOR_ORDER.get(energy_type, 98)),
		int(ITEM_TYPE_ORDER.get(item_type, 97)),
		sort_name,
		str(reward.get("id", reward.get("catalogId", ""))).to_lower()
	]

# 실행: compare two tuple-like arrays lexicographically.
static func _sort_key_before(left: Array, right: Array) -> bool:
	var limit := mini(left.size(), right.size())
	for index in range(limit):
		if left[index] == right[index]:
			continue
		return left[index] < right[index]
	return left.size() < right.size()
