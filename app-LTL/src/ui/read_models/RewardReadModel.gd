# 계약:
# - 책임: UI에 보상을 표시하기 위한 readable read model projection을 제공한다.
# - 입력: raw reward Dictionary 데이터.
# - 출력: 가중치 정보가 마스킹되고 배지 및 설명 정보가 정리된 UI 안전 Dictionary.
# - 금지: 비즈니스 로직 계산, 상태 직접 변경.
#
# 실행: define the RewardReadModel class.
class_name RewardReadModel
extends RefCounted

const TextCatalogScript = preload("res://src/ui/TextCatalog.gd")

# 실행: project reward data for UI rendering.
static func project(reward: Dictionary) -> Dictionary:
	return {
		"rewardId": reward.get("rewardId", ""),
		"kind": TextCatalogScript.display_name(str(reward.get("kind", "Unknown Reward"))),
		"rarity": reward.get("rarity", "common"),
		"qty": int(reward.get("qty", 1)),
		"presentation": {
			"description": TextCatalogScript.display_description(str(reward.get("presentation", {}).get("description", ""))),
			"badge": reward.get("presentation", {}).get("badge", ""),
			"icon": reward.get("presentation", {}).get("icon", "")
		},
		"nextCombatModifierPreview": reward.get("next_combat_modifier_preview", {}).duplicate(true),
		"tags": reward.get("tags", []).duplicate(true)
	}

# 실행: project the full reward tray into text and discard-zone state.
static func project_tray(pending_rewards: Array, held_reward_index: int = -1, held_artifact: Variant = null, held_from_rewards: bool = false) -> Dictionary:
	var lines: PackedStringArray = []
	if pending_rewards.is_empty():
		lines.append(TextCatalogScript.t("reward.empty"))
	else:
		for idx in range(pending_rewards.size()):
			var reward: Dictionary = pending_rewards[idx]
			var presentation: Dictionary = reward.get("presentation", {})
			var badge = presentation.get("badge", "reward")
			var holding = TextCatalogScript.t("reward.holding") if held_reward_index == idx else ""
			lines.append("> [url=%d]%s x%d (%s)[/url] [color=#e5c07b][%s][/color]%s" % [idx, TextCatalogScript.display_name(str(reward.get("kind", "reward"))), int(reward.get("qty", 0)), str(reward.get("rarity", "common")).to_upper(), badge, holding])
	var discard_text := TextCatalogScript.t("discard.idle")
	var discard_active := false
	if held_artifact != null:
		discard_active = true
		if held_from_rewards and held_reward_index >= 0 and held_reward_index < pending_rewards.size():
			discard_text = TextCatalogScript.t("discard.active", [TextCatalogScript.display_name(str(pending_rewards[held_reward_index].get("kind", "")))])
		else:
			discard_text = TextCatalogScript.t("discard.active", [TextCatalogScript.display_name(str(held_artifact.name))])
	return {"text": "\n".join(lines), "discardText": discard_text, "discardActive": discard_active}
