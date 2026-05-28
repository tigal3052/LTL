# 계약:
# - 책임: M3 reward/progression 이벤트를 JSONL로 기록 가능한 telemetry Dictionary로 변환한다.
# - 입력: node context, reward offer, selected reward, growth/inventory delta.
# - 출력: M3 필수 telemetry 필드를 포함한 Dictionary.
# - 금지: 파일 쓰기, print, runtime state mutation.
#
# 실행: define the BuildRewardTelemetry vocabulary capsule.
class_name BuildRewardTelemetry
extends RefCounted

# 실행: build the reward offer generated telemetry payload.
static func build_offer_generated(node_context: Dictionary, rewards: Array) -> Dictionary:
	var offer_ids := []
	var hashes := []
	for reward in rewards:
		if reward is Dictionary:
			offer_ids.append(str(reward.get("rewardId", "")))
			var hash_value := str(reward.get("offer_weights_hash", ""))
			if not hash_value.is_empty() and not hashes.has(hash_value):
				hashes.append(hash_value)
	return {
		"event": "reward_offer_generated",
		"node_id": str(node_context.get("node_id", node_context.get("nodeId", ""))),
		"node_type": str(node_context.get("node_type", node_context.get("nodeType", ""))),
		"offer_ids": offer_ids,
		"offer_weights_hash": "|".join(hashes)
	}

# 실행: build the reward selected telemetry payload.
static func build_reward_selected(node_context: Dictionary, reward: Dictionary, delta: Dictionary = {}) -> Dictionary:
	return {
		"event": "reward_selected",
		"node_id": str(node_context.get("node_id", node_context.get("nodeId", ""))),
		"node_type": str(node_context.get("node_type", node_context.get("nodeType", ""))),
		"selected_reward_id": str(reward.get("rewardId", "")),
		"selected_reward_kind": str(reward.get("kind", "")),
		"rarity": str(reward.get("rarity", "")),
		"inventory_diff": delta.get("inventory_diff", {}),
		"gold_delta": int(delta.get("gold_delta", 0)),
		"xp_delta": int(delta.get("xp_delta", 0)),
		"next_combat_modifier_preview": reward.get("next_combat_modifier_preview", {})
	}

# 실행: build the growth state changed telemetry payload.
static func build_growth_state_changed(reason: String, before_growth: Dictionary, after_growth: Dictionary) -> Dictionary:
	return {
		"event": "growth_state_changed",
		"reason": reason,
		"gold_delta": int(after_growth.get("gold", 0)) - int(before_growth.get("gold", 0)),
		"xp_delta": int(after_growth.get("xp", 0)) - int(before_growth.get("xp", 0)),
		"reward_history_count": after_growth.get("rewardHistory", []).size()
	}
