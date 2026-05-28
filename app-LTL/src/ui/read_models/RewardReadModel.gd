# 계약:
# - 책임: UI에 보상을 표시하기 위한 퍼블릭 읽기 모델(Read Model) 프로젝션을 제공한다.
# - 입력: raw reward Dictionary 데이터.
# - 출력: 가중치(weight) 정보가 마스킹되고 뱃지 및 설명 정보가 정리된 UI 안전 Dictionary.
# - 금지: 비즈니스 롤 연산, 상태 직접 변형.
#
# 실행: define the RewardReadModel class.
class_name RewardReadModel
extends RefCounted

# 실행: project reward data for UI rendering.
static func project(reward: Dictionary) -> Dictionary:
	return {
		"rewardId": reward.get("rewardId", ""),
		"kind": reward.get("kind", "Unknown Reward"),
		"rarity": reward.get("rarity", "common"),
		"qty": int(reward.get("qty", 1)),
		"presentation": {
			"description": reward.get("presentation", {}).get("description", ""),
			"badge": reward.get("presentation", {}).get("badge", ""),
			"icon": reward.get("presentation", {}).get("icon", "")
		},
		"nextCombatModifierPreview": reward.get("next_combat_modifier_preview", {}).duplicate(true),
		"tags": reward.get("tags", []).duplicate(true)
	}

# ?ㅽ뻾: project the full reward tray into text and discard-zone state.
static func project_tray(pending_rewards: Array, held_reward_index: int = -1, held_artifact: Variant = null, held_from_rewards: bool = false) -> Dictionary:
	var lines: PackedStringArray = []
	if pending_rewards.is_empty():
		lines.append("No pending rewards left. Press 'Claim Rewards' to select your next node.")
	else:
		lines.append("Click an item to hold it, then drop it in the Discard Zone or backpack grid:\n")
		for idx in range(pending_rewards.size()):
			var reward: Dictionary = pending_rewards[idx]
			var presentation: Dictionary = reward.get("presentation", {})
			var badge = presentation.get("badge", "reward")
			var holding = " [HOLDING]" if held_reward_index == idx else ""
			lines.append("> [url=%d]%s x%d (%s)[/url] [color=#e5c07b][%s][/color]%s" % [idx, str(reward.get("kind", "reward")), int(reward.get("qty", 0)), str(reward.get("rarity", "common")).to_upper(), badge, holding])
	var discard_text := "DISCARD ZONE\n[Select reward or backpack item to drop here]"
	var discard_active := false
	if held_artifact != null:
		discard_active = true
		if held_from_rewards and held_reward_index >= 0 and held_reward_index < pending_rewards.size():
			discard_text = "DISCARD ZONE\n[Click here to discard %s]" % str(pending_rewards[held_reward_index].get("kind", ""))
		else:
			discard_text = "DISCARD ZONE\n[Click here to discard %s]" % str(held_artifact.name)
	return {"text": "\n".join(lines), "discardText": discard_text, "discardActive": discard_active}
